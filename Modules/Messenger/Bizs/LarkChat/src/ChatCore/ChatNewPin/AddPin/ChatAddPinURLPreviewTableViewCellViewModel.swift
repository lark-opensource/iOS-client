//
//  ChatAddPinURLPreviewTableViewCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/6.
//

import Foundation
import LKCommonsLogging
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkContainer
import LarkModel
import RustPB
import LarkMessageCore
import TangramService
import TangramComponent
import TangramUIComponent
import AsyncComponent
import DynamicURLComponent
import LarkMessageBase
import EENavigator
import LarkUIKit
import LarkCore
import LarkMessengerInterface
import LarkAccountInterface

final class ChatAddPinURLPreviewTableViewCellViewModel: URLPreviewChatPinModel {
    private static let logger = Logger.log(ChatAddPinURLPreviewTableViewCellViewModel.self, category: "Module.IM.ChatPin")

    let userResolver: UserResolver
    var isSelected: Bool = false
    let previewInfo: RustPB.Im_V1_UrlChatPinPreviewInfo
    var navigator: Navigatable {
        return self.userResolver.navigator
    }

    var urlPreviewEntity: URLPreviewEntity? {
        didSet {
            self.updatePreview()
        }
    }

    private(set) var inlineEntity: InlinePreviewEntity? {
        didSet {
            if !isModified, let inlineTitle = inlineEntity?.title, !inlineTitle.isEmpty {
                /// 限制 title 最多60个字符
                self.title = String(inlineTitle.prefix(ChatPinUpdateTitleViewController.textMaxLength))
            }
        }
    }
    /// 是否展示 loading
    private(set) var isSkeleton: Bool = true
    private(set) var title: String {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _title
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _title = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }
    private var _title: String = ""
    private let getChat: () -> Chat
    private let updateHandler: () -> Void
    /// 是否被用户主动修改过
    private var isModified: Bool = false
    /// 是否隐藏 card 预览区域
    private var hideContent: Bool = false
    private var contentSize: CGSize = .zero
    private let getAvailableMaxWidth: () -> CGFloat
    private var templateChatPinService: URLTemplateChatPinService?
    private var getTargetVC: () -> UIViewController?

    private let chatColorConfig = ChatColorConfig()
    private var unfairLock = os_unfair_lock_s()

    private var _onTap: TCPreviewWrapperView.OnTap?
    private var onTap: TCPreviewWrapperView.OnTap? {
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

    private var renderer: ComponentRenderer? {
        return cardViewModel?.renderer
    }
    private var _cardViewModel = Atomic<URLCardViewModel>()
    var cardViewModel: URLCardViewModel? {
        get { return _cardViewModel.wrappedValue }
        set { _cardViewModel.wrappedValue = newValue }
    }
    let urlCardService: URLCardService?
    let urlCardConfig = URLCardConfig(hideHeader: true, hideTitle: true)

    init(userResolver: UserResolver,
         urlCardService: URLCardService?,
         templateService: URLTemplateChatPinService?,
         isSelected: Bool,
         previewInfo: RustPB.Im_V1_UrlChatPinPreviewInfo,
         title: String,
         getAvailableMaxWidth: @escaping () -> CGFloat,
         getChat: @escaping () -> Chat,
         updateHandler: @escaping () -> Void,
         getTargetVC: @escaping () -> UIViewController?) {
        self.userResolver = userResolver
        self.urlCardService = urlCardService
        self.templateChatPinService = templateService
        self.isSelected = isSelected
        self.previewInfo = previewInfo
        self._title = String(title.prefix(ChatPinUpdateTitleViewController.textMaxLength))
        self.getAvailableMaxWidth = {
            getAvailableMaxWidth() - ChatAddPinURLPreviewCellUIConfig.contentHorizontalMargin
        }
        self.getChat = getChat
        self.updateHandler = updateHandler
        self.getTargetVC = getTargetVC
    }

    private func update() {
        self.contentSize = self.renderer?.boundingRect.size ?? .zero
        self.updateHandler()
    }

    private func onCardTapped(cardURL: Basic_V1_URL?) {
        guard let targetVC = self.targetVC else { return }

        if let urlStr = cardURL?.tcURL, !urlStr.isEmpty, let url = try? URL.forceCreateURL(string: urlStr) {
            self.navigator.open(url, context: [:], from: targetVC)
        } else if !hangPoint.url.isEmpty, let url = try? URL.forceCreateURL(string: hangPoint.url) {
            self.navigator.open(url, context: [:], from: targetVC)
            Self.logger.info("chatAddPinTrace onCardTapped use hangPoint url \(hangPoint.previewID) \(self.getChat().id)")
        } else {
            Self.logger.error("chatAddPinTrace onCardTapped fail \(hangPoint.previewID) \(self.getChat().id)")
        }
    }

    private var willDisplaySetup: Bool = false
    func willDisplay() {
        cardViewModel?.willDisplay()

        guard !willDisplaySetup else {
            return
        }
        willDisplaySetup = true
        if isSkeleton {
            /// 第一次上屏时如果展示 loading（数据还未 ready
            /// 开始计时，超过 10s 则永远不再展示 Card 预览
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self = self else { return }
                if self.isSkeleton {
                    self.isSkeleton = false
                    self.hideContent = true
                    self.updateHandler()
                }
            }
        }
    }

    func didEndDisplay() {
        cardViewModel?.didEndDisplay()
    }

    func onResize() {
        cardViewModel?.onResize()
        self.contentSize = self.renderer?.boundingRect.size ?? .zero
    }

    func getCellHeight() -> CGFloat {
        /// titleHeight(64)  contentBottomMargin(20)
        if isSkeleton {
            return ChatAddPinURLPreviewCellUIConfig.skeletonHieght + 64 + 20
        } else if hideContent {
            return 64
        }
        return contentSize.height + 64 + 20
    }

    func renderContent(_ contentContainer: UIView) {
        if hideContent {
            contentContainer.isHidden = true
            return
        }
        contentContainer.isHidden = false
        contentContainer.snp.updateConstraints { (make) in
            make.height.equalTo(self.contentSize.height)
        }

        /// 找到可更新的视图
        if let targetView = contentContainer.subviews.first {
            guard let targetView = targetView as? TCPreviewWrapperView else {
                return
            }
            targetView.frame = CGRect(origin: .zero, size: self.contentSize)
            renderer?.bind(to: targetView.tcContainer)
            renderer?.render()
            targetView.onTap = self.onTap
            return
        }

        let targetView = TCPreviewWrapperView(frame: CGRect(origin: .zero, size: .zero))
        targetView.layer.borderWidth = 1
        targetView.layer.cornerRadius = 8
        targetView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        targetView.frame = CGRect(origin: .zero, size: self.contentSize)
        contentContainer.addSubview(targetView)
        renderer?.bind(to: targetView.tcContainer)
        renderer?.render()
        targetView.onTap = self.onTap
    }

    var hangPoint: RustPB.Basic_V1_PreviewHangPoint {
        return self.previewInfo.urlPreviewHangPoint
    }

    func updateEntity(newUrlPreviewEntity: URLPreviewEntity?, newInlineEntity: InlinePreviewEntity?) -> Bool {
        var needUpdate: Bool = false

        if let newUrlPreviewEntity = newUrlPreviewEntity {
            if let oldEntity = self.urlPreviewEntity {
                if newUrlPreviewEntity.version >= oldEntity.version {
                    self.urlPreviewEntity = newUrlPreviewEntity
                    needUpdate = true
                }
            } else {
                self.urlPreviewEntity = newUrlPreviewEntity
                needUpdate = true
            }
        }

        if let newInlineEntity = newInlineEntity {
            if let oldEntity = self.inlineEntity {
                if newInlineEntity.version >= oldEntity.version {
                    self.inlineEntity = newInlineEntity
                    needUpdate = true
                }
            } else {
                self.inlineEntity = newInlineEntity
                needUpdate = true
            }
        }

        if needUpdate {
            self.contentSize = self.renderer?.boundingRect.size ?? .zero
            self.handleSkeleton()
        }
        return needUpdate
    }

    func handleSkeleton() {
        guard self.isSkeleton, let entity = self.urlPreviewEntity else { return }
        if urlCardService?.canCreate(entity: entity, context: self) ?? false {
            self.isSkeleton = false
        }
    }

    func updatePreview() {
        if let entity = self.urlPreviewEntity {
            if let cardViewModel = self.cardViewModel {
                cardViewModel.update(entity: entity)
            } else {
                self.cardViewModel = urlCardService?.createCard(entity: entity, cardDependency: self, config: urlCardConfig)
            }
            let cardURL = self.cardViewModel?.getCardURL()
            onTap = { [weak self] in self?.onCardTapped(cardURL: cardURL) }
            self.update()
        }
    }

    func updateTitle(_ title: String) {
        self.title = title
        self.isModified = true
        self.updateHandler()
    }
}

extension ChatAddPinURLPreviewTableViewCellViewModel: URLCardDependency, URLCardContext {

    func getCardLinkScene() -> DynamicURLComponent.URLCardLinkSceneType? {
        if getChat().chatMode == .threadV2 { return .topic }
        switch getChat().type {
        case .group, .topicGroup: return .multi
        case .p2P: return .single
        @unknown default: return nil
        }
    }

    func getChatID() -> String? {
        return getChat().id
    }

    func openProfile(chatterID: String, from: UIViewController) {
        let body = PersonCardBody(chatterId: chatterID, chatId: getChat().id, source: .chat)
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
        let chat = getChat()
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
        return templateChatPinService?.templateService
    }

    func getColor(for key: ColorKey, type: Type) -> UIColor {
        return self.chatColorConfig.getColor(for: key, type: type)
    }

    var targetVC: UIViewController? {
        return self.getTargetVC()
    }

    var senderID: String {
        return ""
    }

    var contentMaxWidth: CGFloat {
        return self.getAvailableMaxWidth()
    }

    var extraTrackParams: [AnyHashable: Any] {
        [:]
    }

    var supportClosePreview: Bool {
        return true
    }

    func reloadRow(animation: UITableView.RowAnimation, updateVM: Bool) {
        self.update()
    }

    func getOriginURL(previewID: String) -> String {
        return self.urlPreviewEntity?.url.url ?? ""
    }

    func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage> {
        return (try? self.userResolver.resolve(assert: DocPreviewViewModelContextDependency.self))?.downloadThumbnail(url: url,
                                                                                                                      fileType: fileType,
                                                                                                                      thumbnailInfo: thumbnailInfo,
                                                                                                                      imageViewSize: viewSize) ?? .empty()
    }

    func canCreateEngine(
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style
    ) -> Bool {
        return false
    }

    func createEngine(
        entity: URLPreviewEntity,
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style,
        renderStyle: RenderComponentStyle
    ) -> URLEngineAbility? {
        return nil
    }
}
