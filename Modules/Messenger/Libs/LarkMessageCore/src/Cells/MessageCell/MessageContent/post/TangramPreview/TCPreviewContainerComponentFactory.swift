//
//  TCPreviewContainerComponentFactory.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2022/6/29.
//

import UIKit
import RustPB
import RxSwift
import LarkCore
import LarkModel
import LarkUIKit
import Foundation
import LarkSetting
import LarkStorage
import EENavigator
import LarkContainer
import TangramService
import LarkMessageBase
import DynamicURLComponent
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface

public protocol TCPreviewContainerContext: ViewModelContext, ColorConfigContext, URLCardContext {
    var urlCardService: URLCardService { get }
    var contextScene: ContextScene { get }
    var scene: ContextScene { get }
    // 卡片点击所需携带的额外参数: meego卡片点击时需要
    var cardRouterContext: [String: Any] { get }
    var templateService: URLTemplateService? { get }

    var fileUtilService: FileUtilService? { get }

    var navigator: Navigatable { get }

    var userID: String { get }

    var userResolver: UserResolver { get }

    func isBurned(message: Message) -> Bool

    func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage>

    func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState

    func auditEvent(event: ChatSecurityAuditEventType, isSecretChat: Bool)

    func getStaticFeatureGating(_ key: FeatureGatingManager.Key) -> Bool
}

extension PageContext: TCPreviewContainerContext {
    public var urlCardService: URLCardService {
        guard let service = pageContainer.resolve(URLCardService.self) else {
            assertionFailure("URLCardService not registered")
            return URLCardService(userID: userID)
        }
        return service
    }

    public var cardRouterContext: [String: Any] {
        return ["from": "message", "url_click_type": "card"]
    }

    public var templateService: URLTemplateService? {
        return pageContainer.resolve(MessageURLTemplateService.self)?.templateService
    }

    public func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage> {
        return docPreviewdependency?.downloadThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageViewSize: viewSize) ?? .empty()
    }

    public func canCreateEngine(property: Basic_V1_URLPreviewComponent.EngineProperty, style: Basic_V1_URLPreviewComponent.Style) -> Bool {
        switch property.type {
        case .message: return getStaticFeatureGating("im.messenger.link.preview")
        @unknown default: return false
        }
    }

    public func auditEvent(event: ChatSecurityAuditEventType, isSecretChat: Bool) {
        try? resolver.resolve(assert: ChatSecurityAuditService.self, cache: true).auditEvent(event, isSecretChat: isSecretChat)
    }
}

public final class TCPreviewContainerComponentFactory<C: TCPreviewContainerContext & PageContext>: MessageSubFactory<C> {
    private let messageLinkFactory: MessageLinkEngineCellViewModelFactory<PageContext>

    public override class var subType: SubType {
        return .tcPreview
    }
    private let renderTrack = TCPreviewRenderTracker()

    public override var canCreateBinder: Bool {
        return true
    }

    public required init(context: C) {
        self.messageLinkFactory = MessageLinkEngineCellViewModelFactory(
            context: context,
            registery: MessageLinkSubFactoryRegistery(
                context: context, defaultFactory: MessageEngineUnknownContentFactory(context: context)
            ),
            initBinder: { [unowned context] contentComponent in
                return MessageLinkEngineCellBinder<PageContext>(
                    context: context,
                    contentComponent: contentComponent
                )
            }
        )
        super.init(context: context)
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        renderTrack.startTrack(message: metaModel.message)
        return Self.canCreatePreview(message: metaModel.message, chat: metaModel.getChat(), context: context)
    }

    public override func registerServices(pageContainer: PageContainer) {
        let userID = context.userID
        pageContainer.register(URLCardService.self) {
            return URLCardService(userID: userID)
        }
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        trackURLPreview(message: metaModel.message, chat: metaModel.getChat())
        return TCPreviewContainerComponentBinder(
            tcPreviewViewModel: TCPreviewContainerComponentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                messageLinkFactory: messageLinkFactory,
                renderTrack: renderTrack
            ),
            actionHandler: nil
        )
    }

    private func trackURLPreview(message: Message, chat: Chat) {
        if message.type == .file {
            IMTracker.Chat.imChatExcelShowClick(chat)
        }
    }
}

extension TCPreviewContainerComponentFactory {
    static func canCreatePreview(message: Message, chat: Chat, context: PageContext) -> Bool {
        if message.isRecalled || message.isDecryptoFail {
            return false
        }
        let sceneSupported = context.scene == .newChat ||
        context.scene == .messageDetail ||
        context.scene == .replyInThread ||
        ((context.scene == .threadChat || context.scene == .threadDetail) && message.type == .file) //话题群特化：支持文件卡片，但不支持其他（云文档等）卡片
        if !sceneSupported {
            return false
        }
        if message.type == .file, !canFilePreviewByCard(message: message, chat: chat, context: context) {
            return false
        }
        // 多URL预览卡片，PM怕出现负反馈，FG关闭时多URL预览不出卡片
        if !context.getStaticFeatureGating("im.messenger.url_preview.multiple_urls"), message.urlPreviewHangPointMap.count > 1 {
            return false
        }
        return message.urlPreviewEntities.values.contains(where: { context.urlCardService.canCreate(entity: $0, context: context) })
    }

    private static func canFilePreviewByCard(message: Message, chat: Chat, context: PageContext) -> Bool {
        guard context.getDynamicFeatureGating("messenger.message.online_edit_excel"),
              let fileContent = message.content as? FileContent,
              context.checkPreviewAndReceiveAuthority(chat: chat, message: message) == .allow else {
            return false
        }
        //仅unknownSupportState不渲染卡片；
        //notSupportPreview也会渲染卡片（渲染一个兜底图）
        return fileContent.fileAbility != .unknownSupportState
    }

    /// canHandle用于判断URLPreview是否交给URL中台处理
    public static func canHandle(entities: [String: URLPreviewEntity], hangPoints: [String: Basic_V1_UrlPreviewHangPoint]) -> Bool {
        // 为了解决老的URL预览先出来的情况，当有hangPoints时仍由中台处理(表示URL接入中台，不显示老预览)
        // 未接入URL中台的URL也会复用中台的卡片，但是没有hangPoints
        return !hangPoints.isEmpty || !entities.isEmpty
    }

    // 是否独立卡片
    public static func canCreateSinglePreview(message: Message, chat: Chat, context: PageContext) -> Bool {
        // 独立卡片FG：关闭时不支持创建独立卡片
        if !context.getDynamicFeatureGating("im.messenger.url_card") {
            return false
        }
        if !TCPreviewContainerComponentFactory.canCreatePreview(message: message, chat: chat, context: context) {
            return false
        }
        // 是否是未接入URL中台的旧爬虫预览
        var isOldPreview = false
        if message.urlPreviewEntities.count == 1, let entity = message.urlPreviewEntities.first?.value, entity.isOldPreview {
            isOldPreview = true
        }
        let hangPoints = message.urlPreviewHangPointMap
        // 多URL
        if hangPoints.count != 1, !isOldPreview {
            return false
        }
        // 被二次编辑过
        if message.isMultiEdited {
            return false
        }
        var richText: Basic_V1_RichText?
        if message.type == .text, let content = message.content as? TextContent {
            richText = content.richText
        } else if message.type == .post, let content = message.content as? PostContent {
            richText = content.richText
        }
        guard let richText = richText else { return false }
        // 正常通过输入框发送的链接只有一个anchor节点，但机器人等通过OpenAPI发送的RichText可能有特殊情况，比如
        // p节点下嵌套anchor的情况，在视觉上也是展示成单URL，此处对这种特殊情况做个兜底；这里取「5」的意思是超过5个节点
        // 数量就不再兜底了，比如10层p节点最终套一个anchor的case，视为异常。
        if richText.elements.count > 5 {
            return false
        }
        // 通过输入框发送的单链接：只有一个anchor节点，且非自定义链接，且无Style（加粗下划线等），且有previewID
        if richText.elements.count == 1,
           let (elementID, element) = richText.elements.first,
           element.tag == .a,
           !element.property.anchor.isCustom,
           element.style.isEmpty,
           (hangPoints[elementID] != nil || isOldPreview) {
            return true
        }
        // 通过OpenAPI发送的单链接
        var elementIDs = richText.elementIds
        // 按顺序收集叶子结点
        var leafNodes: [Basic_V1_RichTextElement] = []
        while !elementIDs.isEmpty {
            let id = elementIDs.removeFirst()
            guard let element = richText.elements[id] else { return false }
            if element.childIds.isEmpty {
                // 叶子结点只能是anchor/p/docs/figure，末尾的p/docs/figure会被trim，视觉上也是单链接
                if (element.tag == .a && !element.property.anchor.isCustom && element.style.isEmpty && (hangPoints[id] != nil || isOldPreview))
                    || element.tag == .p || element.tag == .docs || element.tag == .figure {
                    leafNodes.append(element)
                } else {
                    return false
                }
            } else if element.tag == .p || element.tag == .docs || element.tag == .figure { // 嵌套的p/docs/figure
                elementIDs.insert(contentsOf: element.childIds, at: 0)
            } else { // 有其他节点表示非单链接
                return false
            }
        }
        // 首元素需要是anchor，末尾的p/docs/figure会被trim，视觉上也是单链接
        return leafNodes.first?.tag == .a && leafNodes.filter({ $0.tag == .a }).count == 1
    }

    // 独立卡片是否带气泡样式
    public static func isSinglePreviewWithBubble(message: Message, scene: ContextScene) -> Bool {
        // 会话中才有气泡样式
        if scene != .newChat {
            return false
        }
        if message.parentMessage != nil {
            return true
        }
        if message.showInThreadModeStyle, !message.displayInThreadMode {
            return true
        }
        return false
    }
}
