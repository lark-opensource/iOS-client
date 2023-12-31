//
//  ChatWidgetURLPreviewViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/12.
//

import UIKit
import Foundation
import RustPB
import TangramService
import LKCommonsLogging
import LarkOpenChat
import LarkSDKInterface
import LarkModel
import RxSwift
import RxCocoa
import LarkContainer
import LarkCore
import LarkMessageCore
import TangramComponent
import TangramUIComponent
import AsyncComponent
import DynamicURLComponent
import EENavigator
import LarkUIKit
import LarkMessageBase
import LarkMessengerInterface
import LarkAccountInterface

final class ChatWidgetURLPreviewViewModel: ChatWidgetViewModel<TCPreviewWrapperView> {
    static let logger = Logger.log(ChatWidgetURLPreviewViewModel.self, category: "ChatWidgetURLPreviewViewModel")

    override var identifier: String {
        return "ChatWidgetTCPreviewContainer"
    }

    var content: ChatWidgetURLPreviewContent {
        guard let previewContent = self.metaModel.widget.content as? ChatWidgetURLPreviewContent else {
            assertionFailure("can not transform ChatWidgetURLPreviewContent")
            return ChatWidgetURLPreviewContent(hangPoint: Basic_V1_PreviewHangPoint())
        }
        return previewContent
    }

    var previewEntity: URLPreviewEntity? {
        guard let urlPreviewEntity = self.content.urlPreviewEntity else {
            return nil
        }
        return urlPreviewEntity
    }

    private let chatColorConfig = ChatColorConfig()

    private var unfairLock = os_unfair_lock_s()
    private var _onTap: TCPreviewWrapperView.OnTap?
    public var onTap: TCPreviewWrapperView.OnTap? {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _onTap
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _onTap = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }

    let urlCardConfig = URLCardConfig()
    private var _cardViewModel = Atomic<URLCardViewModel>()
    var cardViewModel: URLCardViewModel? {
        get { return _cardViewModel.wrappedValue }
        set { _cardViewModel.wrappedValue = newValue }
    }
    private var urlCardService: URLCardService? {
        return try? self.context.userResolver.resolve(assert: URLCardService.self)
    }

    override init(metaModel: ChatWidgetCellMetaModel, context: ChatWidgetContext) {
        super.init(metaModel: metaModel, context: context)
        if let previewEntity = self.previewEntity,
           let cardViewModel = urlCardService?.createCard(entity: previewEntity, cardDependency: self, config: urlCardConfig) {
            self.cardViewModel = cardViewModel
            let cardURL = cardViewModel.getCardURL()
            onTap = { [weak self] in self?.onCardTapped(cardURL: cardURL) }
            self.update()
        }
    }

    override func update(metaModel: ChatWidgetCellMetaModel) {
        super.update(metaModel: metaModel)
        if let previewEntity = self.previewEntity {
            if self.cardViewModel == nil {
                self.cardViewModel = urlCardService?.createCard(entity: previewEntity, cardDependency: self, config: urlCardConfig)
            } else {
                self.cardViewModel?.update(entity: previewEntity)
            }
            let cardURL = self.cardViewModel?.getCardURL()
            onTap = { [weak self] in self?.onCardTapped(cardURL: cardURL) }
            self.update()
        }
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return self.cardViewModel?.renderer.boundingRect.size ?? .zero
    }

    override func create(_ size: CGSize) -> TCPreviewWrapperView {
        let view = super.create(size)
        if let renderer = self.cardViewModel?.renderer {
            renderer.bind(to: view.tcContainer)
            renderer.render()
        }
        return view
    }

    override func update(view: TCPreviewWrapperView) {
        super.update(view: view)
        if let renderer = self.cardViewModel?.renderer {
            // view可能被复用而不会走create，此处需要重新bind & render
            renderer.bind(to: view.tcContainer)
            renderer.render()
        }
        view.onTap = self.onTap
    }

    override func willDisplay() {
        self.cardViewModel?.willDisplay()
    }

    override func didEndDisplay() {
        self.cardViewModel?.didEndDisplay()
    }

    override func onResize() {
        self.cardViewModel?.onResize()
    }

    private func onCardTapped(cardURL: Basic_V1_URL?) {
        guard let urlStr = cardURL?.tcURL,
              let targetVC = self.targetVC else { return }
        guard !urlStr.isEmpty, let url = try? URL.forceCreateURL(string: urlStr) else {
            Self.logger.error("widgetsTrace [URLPreview] url create failed: \(urlStr)")
            return
        }
        context.userResolver.navigator.open(url, context: [:], from: targetVC)
    }
}

extension ChatWidgetURLPreviewViewModel: URLCardDependency {

    func getCardLinkScene() -> DynamicURLComponent.URLCardLinkSceneType? {
        if metaModel.chat.chatMode == .threadV2 { return .topic }
        switch metaModel.chat.type {
        case .group, .topicGroup: return .multi
        case .p2P: return .single
        @unknown default: return nil
        }
    }

    func getChatID() -> String? {
        return metaModel.chat.id
    }

    func openProfile(chatterID: String, from: UIViewController) {
        let body = PersonCardBody(chatterId: chatterID, chatId: metaModel.chat.id, source: .chat)
        Navigator.shared.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func showImagePreview(
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    ) {
        let chat = metaModel.chat
        let assets = properties.map {
            LKDisplayAsset.createAsset(postImageProperty: $0, isTranslated: false, isAutoLoadOrigin: true)
        }
        let assetResult = CreateAssetsResult(assets: assets, selectIndex: index, assetPositionMap: [:])
        let body = PreviewImagesBody(assets: assetResult.assets.map { $0.transform() },
                                     pageIndex: index,
                                     scene: .normal(assetPositionMap: assetResult.assetPositionMap, chatId: nil),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     canTranslate: false,
                                     translateEntityContext: (nil, .other))
        Navigator.shared.present(body: body, from: from)
    }

    var templateService: URLTemplateService? {
        return try? self.context.resolver.resolve(assert: ChatWidgetURLTemplateService.self).templateService
    }

    var userResolver: UserResolver {
        return context.userResolver
    }

    func getColor(for key: ColorKey, type: Type) -> UIColor {
        return self.chatColorConfig.getColor(for: key, type: type)
    }

    public var targetVC: UIViewController? {
        return try? self.context.resolver.resolve(assert: ChatOpenService.self).chatVC()
    }

    public var senderID: String {
        return ""
    }

    public var contentMaxWidth: CGFloat {
        return self.context.containerSize.width
    }

    public var extraTrackParams: [AnyHashable: Any] {
        [:]
    }

    public var supportClosePreview: Bool {
        return true
    }

    func reloadRow(animation: UITableView.RowAnimation, updateVM: Bool) {
        self.update()
    }

    func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage> {
        return (try? self.context.resolver.resolve(assert: DocPreviewViewModelContextDependency.self))?.downloadThumbnail(url: url,
                                                                                                    fileType: fileType,
                                                                                                    thumbnailInfo: thumbnailInfo,
                                                                                                    imageViewSize: viewSize) ?? .empty()
    }

    public func getOriginURL(previewID: String) -> String {
        return self.previewEntity?.url.url ?? ""
    }

    public func createEngine(
        entity: URLPreviewEntity,
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style,
        renderStyle: RenderComponentStyle
    ) -> URLEngineAbility? {
        return nil
    }
}
