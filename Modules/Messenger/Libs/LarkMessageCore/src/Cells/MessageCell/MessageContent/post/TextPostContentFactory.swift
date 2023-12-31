//
//  TextPostContentFactory.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/18.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import EENavigator
import LarkSetting
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkInteraction
import LarkZoomable
import RichLabel
import LarkCore
import LKRichView
import LKCommonsLogging
import UIKit
import LarkRichTextCore

open class TextPostContentFactory<C: PageContext>: MessageSubFactory<C> {
    private var logger = Logger.log(TextPostContentFactory.self, category: "LarkMessage.TextPostContentFactory")

    open override class var subType: SubType {
        return .content
    }

    open override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is PostContent || metaModel.message.content is TextContent
    }

    open override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let config = getTextPostConfig(with: metaModel, metaModelDependency: metaModelDependency)
        return ChatTextPostContentViewModel(
            content: metaModel.message.content,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: TextPostContentComponentBinder(context: context),
            config: config
        )
    }

    open func getTextPostConfig<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> TextPostConfig {
        var config = TextPostConfig()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 24
        paragraphStyle.maximumLineHeight = UIFont.ud.title3.rowHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        config.titleRichAttributes = [
            .foregroundColor: UIColor.ud.N900,
            .font: UIFont.ud.title3,
            .paragraphStyle: paragraphStyle
        ]

        config.contentLineSpacing = 2
        config.attacmentImageCornerRadius = 0

        // code_next_line tag CryptChat
        // 初始时是流式消息，不进行折叠
        config.isAutoExpand = metaModel.message.streamStatus == .streamTransport || metaModel.message.streamStatus == .streamPrepare
        config.translateIsAutoExpand = config.isAutoExpand
        // 初始时是流式消息，强制同步绘制
        config.syncDisplayMode = metaModel.message.streamStatus == .streamTransport || metaModel.message.streamStatus == .streamPrepare
        // MyAI不进MessageDetail
        config.needPostViewTapHandler = (metaModel.message.type == .post && context.contextScene != .pin && !metaModel.getChat().isP2PAi) ? true : false
        config.supportVideoInPost = true
        if context.contextScene == .pin {
            config.groupAnnouncementPadding = 2 * metaModelDependency.contentPadding
        }
        if let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode {
            config.supportImageAndVideoViewInChat = false
        }
        return config
    }

    open override func registerDragHandler<M: CellMetaModel, D: CellMetaModelDependency>(with dargManager: DragInteractionManager, metaModel: M, metaModelDependency: D) {
        let handler = MessageContentDragHandler(modelService: self.context.modelService)
        let translateHandler = MessageTranslateDragHandler(modelService: self.context.modelService)
        dargManager.register(handler)
        dargManager.register(translateHandler)
    }

    open override func registerServices(pageContainer: PageContainer) {
        pageContainer.register(LarkRichTextCore.PhoneNumberAndLinkParser.self) {
            PhoneNumberAndLinkParser()
        }
    }
}

// 会话场景，支持独立卡片：独立卡片时内容会隐藏，需要搭配TCPreviewContainerComponentFactory使用
public final class ChatTextPostContentFactory<C: PageContext>: TextPostContentFactory<C> {
    public override func getTextPostConfig<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> TextPostConfig {
        var config = super.getTextPostConfig(with: metaModel, metaModelDependency: metaModelDependency)
        config.supportSinglePreview = true
        return config
    }
}

public final class MergeForwardTextPostContentFactory<C: PageContext>: TextPostContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let config = getTextPostConfig(with: metaModel, metaModelDependency: metaModelDependency)
        return MergeForwardDetailTextPostContentViewModel(
            content: metaModel.message.content,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: TextPostContentComponentBinder(context: context),
            config: config
        )
    }
}

// 话题转发卡片场景
public class ForwardThreadTextPostContentFactory<C: PageContext>: TextPostContentFactory<C> {
    public override func getTextPostConfig<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> TextPostConfig {
        var config = super.getTextPostConfig(with: metaModel, metaModelDependency: metaModelDependency)
        // 话题转发卡片等场景不需要高亮
        config.highlightAt = false
        // 不显示已读未读红点
        config.isShowReadStatus = false
        config.groupAnnouncementPadding = 2 * metaModelDependency.contentPadding
        config.supportShowMoreMaskColor = false
        config.supportImageAndVideoFlip = false
        config.supportImageAndVideoViewInChat = false
        config.showSaveToCloud = false
        config.showAddToSticker = false
        return config
    }
}

// 群置顶场景
public class ChatPinTextPostContentFactory<C: PageContext>: TextPostContentFactory<C> {
    public override func getTextPostConfig<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> TextPostConfig {
        var config = super.getTextPostConfig(with: metaModel, metaModelDependency: metaModelDependency)
        config.isShowReadStatus = false
        config.groupAnnouncementPadding = 2 * metaModelDependency.contentPadding
        config.groupAnnouncementNeedBorder = true
        config.groupAnnouncementBorderColor = UIColor.ud.lineBorderCard
        config.supportShowMoreMaskColor = false
        config.supportImageAndVideoFlip = false
        config.supportImageAndVideoViewInChat = false
        config.isAutoExpand = true
        config.translateIsAutoExpand = true
        return config
    }
}

// 消息链接化场景
public final class MessageLinkTextPostContentFactory<C: PageContext>: ForwardThreadTextPostContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let config = getTextPostConfig(with: metaModel, metaModelDependency: metaModelDependency)
        return ChatTextPostContentViewModel(
            content: metaModel.message.content,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: TextPostContentComponentBinder(context: context),
            config: config
        )
    }
}

extension PageContext: TextPostContentContext {
    public var phoneNumberAndLinkParser: LarkRichTextCore.PhoneNumberAndLinkParser? {
        return pageContainer.resolve(LarkRichTextCore.PhoneNumberAndLinkParser.self)
    }

    public var heightWithoutSafeArea: CGFloat {
        /// https://bytedance.feishu.cn/docx/doxcnGAkQNqxZTxkY8U7kE24Isf
        /// H = 屏幕高度-输入区高度-标题栏-状态栏-HomeIndicator
        ///  - 输入区高度=102（固定）
        ///  - 标题栏=44（固定）
        ///  - 状态栏、HomeIndicator 动态计算
        var height = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 146 // 102 + 44
        let safeArea = dataSourceAPI?.hostUIConfig.safeAreaInsets ?? .zero
        if UIDevice.current.orientation.isPortrait {
            height -= safeArea.top + safeArea.bottom
        } else {
            height -= safeArea.left + safeArea.right
        }
        return height
    }

    public var translateService: NormalTranslateService? {
        return try? resolver.resolve(assert: NormalTranslateService.self, cache: true)
    }

    public var feedbackService: TranslateFeedbackService? {
        return try? resolver.resolve(assert: TranslateFeedbackService.self)
    }

    public var contextScene: ContextScene {
        return dataSourceAPI?.scene ?? .newChat
    }

    public var modelService: ModelService? {
        return try? resolver.resolve(assert: ModelService.self, cache: true)
    }

    public var abbreviationEnable: Bool {
        let enterpriseEntityService = try? resolver.resolve(assert: EnterpriseEntityWordService.self)
        return enterpriseEntityService?.abbreviationHighlightEnabled() ?? false
    }

    public func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return pageAPI?.getSelectionLabelDelegate()
    }
}

struct MessageContentDragHandler: DragInteractionHandler {
    private var modelService: ModelService?
    init(modelService: ModelService?) {
        self.modelService = modelService
    }

    func dragInteractionHandleViewTag() -> String {
        return PostViewComponentConstant.contentKey
    }

    func dragInteractionCanHandle(context: DragContext) -> Bool {
        return false
    }

    func dragInteractionHandle(info: DragInteractionViewInfo, context: DragContext) -> [DragItem]? {
        guard let message = context.getValue(key: DragContextKey.message)as? Message,
            let view = info.view else {
            return nil
        }
        let content = modelService?.copyMessageSummerize(message, selectType: .all, copyType: .origin) ?? ""
        let itemProvider = NSItemProvider(object: content as NSString)

        var item = DragItem(dragItem: UIDragItem(itemProvider: itemProvider))
        let previewParams = UIDragPreviewParameters()
        previewParams.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        previewParams.visiblePath = UIBezierPath(
            roundedRect: CGRect(x: -12, y: -10, width: view.bounds.width + 24, height: view.bounds.height + 20),
            cornerRadius: 8
        )
        item.params.targetDragPreviewParameters = previewParams
        return [item]
    }
}

struct MessageTranslateDragHandler: DragInteractionHandler {

    private var modelService: ModelService?
    init(modelService: ModelService?) {
        self.modelService = modelService
    }

    func dragInteractionHandleViewTag() -> String {
        return PostViewComponentConstant.translateContentKey
    }

    func dragInteractionCanHandle(context: DragContext) -> Bool {
        return false
    }

    func dragInteractionHandle(info: DragInteractionViewInfo, context: DragContext) -> [DragItem]? {
        guard let message = context.getValue(key: DragContextKey.message)as? Message,
            let view = info.view else {
            return nil
        }
        let content = modelService?.copyMessageSummerize(message, selectType: .all, copyType: .translate) ?? ""
        let itemProvider = NSItemProvider(object: content as NSString)
        var item = DragItem(dragItem: UIDragItem(itemProvider: itemProvider))
        let previewParams = UIDragPreviewParameters()
        previewParams.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        previewParams.visiblePath = UIBezierPath(
            roundedRect: CGRect(x: -12, y: -10, width: view.bounds.width + 24, height: view.bounds.height + 20),
            cornerRadius: 8
        )
        item.params.targetDragPreviewParameters = previewParams
        return [item]
    }
}
