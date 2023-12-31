//
//  URLPreviewPinCardCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RxCocoa
import LarkOpenChat
import LKCommonsLogging
import ByteWebImage
import RustPB
import LarkModel
import EENavigator
import TangramService
import LarkMessageCore
import LarkContainer
import LarkCore
import TangramComponent
import TangramUIComponent
import AsyncComponent
import DynamicURLComponent
import LarkMessageBase
import LarkSDKInterface
import UniverseDesignFont
import LarkMessengerInterface

public class URLPreviewBasePinCardCellViewModel: ChatPinCardCellViewModel,
                                             ChatPinCardCellLifeCycle, ChatPinCardActionProvider, ChatPinCardRenderAbility {
    static let logger = Logger.log(URLPreviewBasePinCardCellViewModel.self, category: "Module.IM.ChatPin")

    public override class func canInitialize(context: ChatPinCardContext) -> Bool {
        return true
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

    public var entity: URLPreviewEntity? {
        assertionFailure("need override")
        return nil
    }

    private var urlCardService: URLCardService? {
        return try? self.userResolver.resolve(assert: URLCardService.self)
    }
    private var _cardViewModel = Atomic<URLCardViewModel>()
    var cardViewModel: URLCardViewModel? {
        get { return _cardViewModel.wrappedValue }
        set { _cardViewModel.wrappedValue = newValue }
    }
    let urlCardConfig = URLCardConfig(hideHeader: true, hideTitle: true)

    public required init(context: ChatPinCardContext) {
        super.init(context: context)
    }

    var metaModel: ChatPinCardCellMetaModel? {
        didSet {
            if let entity = self.entity {
                if let cardViewModel = self.cardViewModel {
                    cardViewModel.update(entity: entity)
                } else {
                    self.cardViewModel = urlCardService?.createCard(entity: entity, cardDependency: self, config: urlCardConfig)
                }
                let cardURL = self.cardViewModel?.getCardURL()
                onTap = { [weak self] in self?.onCardTapped(cardURL: cardURL) }
            }
        }
    }
    public override func modelDidChange(model: ChatPinCardCellMetaModel) {
        self.metaModel = model
    }

    public func onCardTapped(cardURL: Basic_V1_URL?) {
        assertionFailure("need override")
    }

    func update() {
        if let pinId = self.metaModel?.pin.id {
            self.context.calculateSizeAndUpateView { pinID, _ in return pinID == pinId }
        }
    }

    // MARK: - ChatPinCardCellLifeCycle
    public func willDisplay() {
        cardViewModel?.willDisplay()
    }
    public func didEndDisplay() {
        cardViewModel?.didEndDisplay()
    }
    public func onResize() {
        cardViewModel?.onResize()
    }

    // MARK: - ChatPinCardActionProvider
    public func getActionItems() -> [ChatPinActionItemType] {
        assertionFailure("need override")
        return []
    }

    // MARK: - ChatPinCardRenderAbility
    public class var reuseIdentifier: String? {
        return "ChatPinCardTCPreviewContainer"
    }

    public func createTitleView() -> UILabel {
        assertionFailure("need override")
        return UILabel()
    }

    public func updateTitletView(_ view: UILabel) {
        assertionFailure("need override")
    }

    public func getTitleSize() -> CGSize {
        assertionFailure("need override")
        return .zero
    }

    public func createContentView() -> TCPreviewWrapperView {
        let view = TCPreviewWrapperView(frame: CGRect(origin: .zero, size: .zero))
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        let renderer = self.cardViewModel?.renderer
        renderer?.bind(to: view.tcContainer)
        renderer?.render()
        return view
    }

    public func updateContentView(_ view: TCPreviewWrapperView) {
        let renderer = self.cardViewModel?.renderer
        renderer?.bind(to: view.tcContainer)
        renderer?.render()
        view.onTap = self.onTap
    }

    public func getContentSize() -> CGSize {
        return self.cardViewModel?.renderer.boundingRect.size ?? .zero
    }

    public func getIconConfig() -> ChatPinIconConfig? {
        assertionFailure("need override")
        let iconResource = ChatPinIconResource.image(.just(UIImage()))
        return ChatPinIconConfig(iconResource: iconResource, size: CGSize(width: 16, height: 16))
    }

    public var showCardFooter: Bool {
        return true
    }
}

extension URLPreviewBasePinCardCellViewModel: URLCardDependency {

    public func getCardLinkScene() -> DynamicURLComponent.URLCardLinkSceneType? {
        guard let chat = metaModel?.chat else {
            Self.logger.error("getCardLinkScene fail because chat is nil")
            return nil
        }
        if chat.chatMode == .threadV2 { return .topic }
        switch chat.type {
        case .group, .topicGroup: return .multi
        case .p2P: return .single
        @unknown default: return nil
        }
    }

    public func getChatID() -> String? {
        return metaModel?.chat.id
    }

    public func openProfile(chatterID: String, from: UIViewController) {
        guard let chat = metaModel?.chat else {
            Self.logger.error("openProfile fail because chat is nil")
            return
        }
        let body = PersonCardBody(chatterId: chatterID, chatId: chat.id, source: .chat)
        Navigator.shared.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    public func showImagePreview(
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    ) {
        guard let chat = metaModel?.chat else {
            Self.logger.error("showImagePreview fail because chat is nil")
            return
        }
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

    public var templateService: TangramService.URLTemplateService? {
        return try? self.resolver.resolve(assert: URLTemplateChatPinService.self).templateService
    }

    public func getColor(for key: ColorKey, type: Type) -> UIColor {
        return self.chatColorConfig.getColor(for: key, type: type)
    }

    public var targetVC: UIViewController? {
        return self.context.targetViewController
    }

    public var senderID: String {
        return ""
    }

    public var contentMaxWidth: CGFloat {
        return self.context.contentAvailableMaxWidth
    }

    public var extraTrackParams: [AnyHashable: Any] {
        [:]
    }

    public var supportClosePreview: Bool {
        return true
    }

    public func reloadRow(animation: UITableView.RowAnimation, updateVM: Bool) {
        self.update()
    }

    public func getOriginURL(previewID: String) -> String {
        return self.entity?.url.url ?? ""
    }

    public func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage> {
        return (try? self.resolver.resolve(assert: DocPreviewViewModelContextDependency.self))?.downloadThumbnail(url: url,
                                                                                                                  fileType: fileType,
                                                                                                                  thumbnailInfo: thumbnailInfo,
                                                                                                                  imageViewSize: viewSize) ?? .empty()
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

public final class URLPreviewPinCardCellViewModel: URLPreviewBasePinCardCellViewModel {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .urlPin
    }

    private let limitedToNumberOfLines: Int = 0
    private let iconSize: CGFloat = 16
    private let iconCornerRadius: CGFloat = 2

    @ScopedInjectedLazy private var auditService: ChatSecurityAuditService?

    private var attributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        return [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.ud.textTitle,
                .paragraphStyle: paragraphStyle]
    }()

    public override var entity: URLPreviewEntity? {
        return (self.metaModel?.pin.payload as? URLPreviewChatPinPayload)?.urlPreviewEntity
    }

    public override func getIconConfig() -> ChatPinIconConfig? {
        let iconResourceSize = CGSize(width: iconSize, height: iconSize)
        let defaultIcon = UDIcon.getIconByKey(.globalLinkOutlined, size: iconResourceSize).ud.withTintColor(UIColor.ud.B500)
        guard let urlPreviewPayload = self.metaModel?.pin.payload as? URLPreviewChatPinPayload else {
            let iconResource = ChatPinIconResource.image(.just(defaultIcon))
            return ChatPinIconConfig(iconResource: iconResource, size: iconResourceSize, cornerRadius: iconCornerRadius)
        }

        let iconResource = URLPreviewPinIconTransformer.transform(urlPreviewPayload.displayIcon,
                                                                  iconSize: iconResourceSize,
                                                                  defaultIcon: defaultIcon,
                                                                  placeholder: defaultIcon)
        return ChatPinIconConfig(iconResource: iconResource, size: iconResourceSize, cornerRadius: iconCornerRadius)
    }

    public override func createTitleView() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = limitedToNumberOfLines
        return label
    }

    public override func updateTitletView(_ view: UILabel) {
        view.attributedText = NSAttributedString(string: (self.metaModel?.pin.payload as? URLPreviewChatPinPayload)?.displayTitle ?? "", attributes: attributes)
        view.gestureRecognizers?.forEach({ view.removeGestureRecognizer($0) })
        view.isUserInteractionEnabled = true
        _ = view.lu.addTapGestureRecognizer(action: #selector(onClickTitle), target: self)
    }

    @objc
    private func onClickTitle() {
        guard let metaModel = self.metaModel,
              let urlPreviewPayload = metaModel.pin.payload as? URLPreviewChatPinPayload,
              let targetVC = self.targetVC else {
            return
        }
        if !urlPreviewPayload.url.isEmpty,
           let url = try? URL.forceCreateURL(string: urlPreviewPayload.url) {
            if let httpUrl = url.lf.toHttpUrl() {
                self.context.nav.open(httpUrl, from: targetVC)
            } else {
                self.context.nav.open(url, from: targetVC)
            }
        } else {
            Self.logger.error("chatPinCardTrace [URLPreview] url create failed chat: \(metaModel.chat.id) pinId: \(metaModel.pin.id)")
        }
        self.auditService?.auditEvent(.chatPin(type: .clickOpenUrl(chatId: metaModel.chat.id,
                                                                   pinId: metaModel.pin.id)),
                                      isSecretChat: false)
    }

    private var titleAvailableMaxWidth: CGFloat {
        return self.context.headerAvailableMaxWidth - iconSize
    }

    public override func getTitleSize() -> CGSize {
        let attrStr = NSAttributedString(string: (self.metaModel?.pin.payload as? URLPreviewChatPinPayload)?.displayTitle ?? "", attributes: attributes)
        let titileSize = attrStr.componentTextSize(for: CGSize(width: titleAvailableMaxWidth, height: .infinity), limitedToNumberOfLines: limitedToNumberOfLines)
        /// + 5 让多行文本首行对齐 icon
        return CGSize(width: titleAvailableMaxWidth, height: titileSize.height + 5)
    }

    public override func getActionItems() -> [ChatPinActionItemType] {
        return [.item(ChatPinActionItem(title: BundleI18n.LarkChat.Lark_IM_NewPin_CopyLink_Button,
                                        image: UDIcon.getIconByKey(.linkCopyOutlined, size: CGSize(width: 20, height: 20)),
                                        handler: CopyURLPinCardActionHandler(targetVC: self.targetVC,
                                                                             auditService: self.auditService))),
                .item(ChatPinActionItem(title: BundleI18n.LarkChat.Lark_IM_NewPin_EditName_Button,
                                        image: UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 20, height: 20)),
                                        handler: self.updateURLTitlePinCardActionHandler)),
                .commonType(.stickToTop),
                .commonType(.unSticktoTop),
                .commonType(.unPin)]
    }

    private lazy var updateURLTitlePinCardActionHandler: UpdateURLTitlePinCardActionHandler = {
            return UpdateURLTitlePinCardActionHandler(targetVC: targetVC,
                                                      chatAPI: try? self.context.userResolver.resolve(assert: ChatAPI.self),
                                                      currentChatterId: self.context.userResolver.userID,
                                                      nav: self.context.userResolver.navigator,
                                                      featureGatingService: self.context.userResolver.fg)
    }()

    public override func onCardTapped(cardURL: Basic_V1_URL?) {
        guard let metaModel = self.metaModel,
              let payload = metaModel.pin.payload as? URLPreviewChatPinPayload,
              let targetVC = self.targetVC else { return }
        if let urlStr = cardURL?.tcURL, !urlStr.isEmpty, let url = try? URL.forceCreateURL(string: urlStr) {
            if let httpUrl = url.lf.toHttpUrl() {
                self.context.nav.open(httpUrl, context: [:], from: targetVC)
            } else {
                self.context.nav.open(url, context: [:], from: targetVC)
            }
        } else if !payload.url.isEmpty, let url = try? URL.forceCreateURL(string: payload.url) {
            if let httpUrl = url.lf.toHttpUrl() {
                self.context.nav.open(httpUrl, context: [:], from: targetVC)
            } else {
                self.context.nav.open(url, context: [:], from: targetVC)
            }
        } else {
            Self.logger.error("chatPinCardTrace [URLPreview] url create failed chat: \(metaModel.chat.id) pinId: \(metaModel.pin.id)")
        }
        IMTracker.Chat.Sidebar.Click.open(metaModel.chat, topId: metaModel.pin.id, messageId: nil, type: .url)
        self.auditService?.auditEvent(.chatPin(type: .clickOpenUrl(chatId: metaModel.chat.id,
                                                                   pinId: metaModel.pin.id)),
                                      isSecretChat: false)
    }
}
