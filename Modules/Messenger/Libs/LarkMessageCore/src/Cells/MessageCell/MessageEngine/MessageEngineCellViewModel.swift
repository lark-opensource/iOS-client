//
//  MessageEngineCellViewModel.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/3/28.
//

import LarkTag
import LarkUIKit
import LarkModel
import Foundation
import EEFlexiable
import EENavigator
import AsyncComponent
import LarkMessageBase
import LarkMessengerInterface

public struct MessageEngineMetaModel: CellMetaModel {
    public let message: Message
    public var getChat: () -> Chat

    public init(message: Message, getChat: @escaping () -> Chat) {
        self.message = message
        self.getChat = getChat
    }
}

public struct MessageEngineAvatarConfig {
    public var showAvatar: Bool
    public var avatarSize: CGFloat

    public init(
        showAvatar: Bool = true,
        avatarSize: CGFloat = 30.auto()
    ) {
        self.showAvatar = showAvatar
        self.avatarSize = avatarSize
    }
}

public struct MessageEngineHeaderConfig {
    public var showHeader: Bool

    public init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
}

public struct MessageEngineContentConfig {
    public init() {}
}

public struct MessageEngineCellMetaModelDependency: CellMetaModelDependency {
    // 卡片上渲染多条消息时，Renderer需要外部注入
    // renderer需要weak持有，否则开放平台卡片会造成引用循环（https://meego.feishu.cn/larksuite/issue/detail/13001704）
    public weak var renderer: ASComponentRenderer?
    public let contentPadding: CGFloat
    public var contentPreferMaxWidth: (Message) -> CGFloat
    public var maxCellWidth: (Message) -> CGFloat
    // Renderer外部注入时，updateRootComponent也需要外部决定
    public var updateRootComponent: (() -> Void)?
    public var avatarConfig: MessageEngineAvatarConfig
    public var headerConfig: MessageEngineHeaderConfig

    public init(
        renderer: ASComponentRenderer?,
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        maxCellWidth: @escaping (Message) -> CGFloat,
        updateRootComponent: (() -> Void)? = nil,
        avatarConfig: MessageEngineAvatarConfig = MessageEngineAvatarConfig(),
        headerConfig: MessageEngineHeaderConfig = MessageEngineHeaderConfig()
    ) {
        self.renderer = renderer
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.maxCellWidth = maxCellWidth
        self.updateRootComponent = updateRootComponent
        self.avatarConfig = avatarConfig
        self.headerConfig = headerConfig
    }

    public func getContentPreferMaxWidth(_ message: LarkModel.Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

open class MessageEngineCellViewModel<C: PageContext>: MessageCellViewModel<MessageEngineMetaModel, MessageEngineCellMetaModelDependency, C> {
    private lazy var _identifier: String = {
        return [content.identifier, "message_engine"].joined(separator: "-")
    }()
    open override var identifier: String {
        return _identifier
    }

    open var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.pageAPI?.getChatThemeScene() ?? .defaultScene
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    open var allSubComponents: [SubType: ComponentWithContext<C>] {
        if message.isFoldRootMessage {
            return [:]
        }
        return getSubComponents()
    }

    open var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    open var maxCellWidth: CGFloat {
        return metaModelDependency.maxCellWidth(message)
    }

    // MARK: - Avatar
    open var avatarConfig: MessageEngineAvatarConfig {
        return metaModelDependency.avatarConfig
    }

    /// 针对系统消息，fromChatter需要特殊处理
    open var fromChatter: Chatter? {
        return (message.content as? SystemContent)?.triggerUser ?? message.fromChatter
    }

    // MARK: - Header
    open var headerConfig: MessageEngineHeaderConfig {
        return metaModelDependency.headerConfig
    }

    public var nameTag: [Tag] = []

    open var formatTime: String {
        // 消息链接化场景暂时不漏出二次编辑时间
        return formatCreateTime
    }

    private var formatCreateTime: String {
        return message.createTime.lf.cacheFormat("message", formater: {
            $0.lf.formatedTime_v2(accurateToSecond: true)
        })
    }

    // MARK: - Content
    open var isFromMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    // 是否是文件卡片（文件消息且渲染出了卡片）
    open var isFileCard: Bool {
        return message.type == .file && getSubComponent(subType: .tcPreview) != nil
    }

    open var bubbleStyle: BubbleStyle {
        if self.message.showInThreadModeStyle {
            return .thread
        }
        return .normal
    }

    open var bubbleConfig: BubbleViewConfig {
        return BubbleViewConfig(
            changeTopCorner: false,
            changeBottomCorner: false,
            changeRaiusReverse: false,
            supportHighlight: false,
            bubbleStyle: bubbleStyle,
            strokeColor: bubbleStrokeColor,
            fillColor: bubbleFillColor,
            strokeWidth: bubbleStrokeWidth
        )
    }

    private var bubbleStrokeColor: UIColor {
        if bubbleStyle == .normal {
            let contentConfig = content.contentConfig
            if contentConfig?.hasBorder ?? false {
                let borderStyle = contentConfig?.borderStyle ?? .card
                switch borderStyle {
                case .card: return UDMessageColorTheme.imMessageCardBorder
                case .custom(let strokeColor, _): return strokeColor
                case .image, .other: return UIColor.ud.lineBorderCard
                }
            } else {
                return UIColor.clear
            }
        } else if message.showInThreadModeStyle {
            return UIColor.ud.lineBorderCard
        } else {
            return UIColor.clear
        }
    }

    private var bubbleFillColor: UIColor {
        if message.showInThreadModeStyle {
            return UIColor.ud.bgBody
        }
        return UIColor.clear
    }

    private var bubbleStrokeWidth: CGFloat {
        let contentConfig = content.contentConfig
        if bubbleStyle == .normal, (contentConfig?.hasBorder ?? false), contentConfig?.borderStyle == .image {
            return 1 / UIScreen.main.scale
        }
        return 1
    }

    public func oneOfSubComponentsDisplay(_ types: [SubType]) -> Bool {
        // 折叠消息没有子组件
        guard !message.isFoldRootMessage else { return false }
        return types.contains(where: { getSubComponent(subType: $0)?._style.display == .flex })
    }

    public override init(
        metaModel: MessageEngineMetaModel,
        metaModelDependency: MessageEngineCellMetaModelDependency,
        context: C,
        contentFactory: MessageSubFactory<C>,
        getContentFactory: @escaping (MessageEngineMetaModel, MessageEngineCellMetaModelDependency) -> MessageSubFactory<C>,
        subFactories: [SubType: MessageSubFactory<C>],
        initBinder: (ComponentWithContext<C>) -> ComponentBinder<C>,
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?,
        renderer: ASComponentRenderer? = nil
    ) {
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: initBinder,
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister,
            renderer: renderer
        )
        self.nameTag = nameTags(for: self.fromChatter)
        // 解决消息被删除/撤回时，进群无法展示
        updateDeletedOrRecalled(message: metaModel.message)
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.initialized(metaModel: self.metaModel, context: self.context)
        }
        super.calculateRenderer()
    }

    open override func willDisplay() {
        super.willDisplay()
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.willDisplay(metaModel: self.metaModel, context: self.context)
        }
    }

    open override func updateRootComponent() {
        // 当Renderer外部注入，updateRootComponent也需要外部决定
        if let updateRootComponent = metaModelDependency.updateRootComponent {
            updateRootComponent()
        } else {
            super.updateRootComponent()
        }
    }

    open override func update(metaModel: MessageEngineMetaModel, metaModelDependency: MessageEngineCellMetaModelDependency?) {
        // super.update()没有触发content.update，需要额外触发
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if !updateDeletedOrRecalled(message: metaModel.message) {
            self.updateContent(metaModel: metaModel, metaModelDependency: metaModelDependency)
        }
        self.nameTag = nameTags(for: message.fromChatter)
        calculateRenderer()
    }

    public func nameTags(for chatter: Chatter?) -> [Tag] {
        guard let chatter = chatter else { return [] }
        var result: [TagType] = []
        // 对齐PC，只展示bot tag
        if chatter.type == .bot, !chatter.withBotTag.isEmpty {
            result = [.robot]
        }
        let resultTags = result.map({ Tag(type: $0) })
        return resultTags
    }

    open func onAvatarTapped() {
        guard let chatter = fromChatter,
              chatter.profileEnabled,
              let targetVC = self.context.pageAPI else { return }
        let body = PersonCardBody(chatterId: chatter.id,
                                  chatId: metaModel.getChat().id,
                                  fromWhere: .chat,
                                  source: .chat)
        context.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            }
        )
    }

    @discardableResult
    private func updateDeletedOrRecalled(message: Message) -> Bool {
        if message.isRecalled, !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel(
                    metaModel: metaModel, metaModelDependency: self.metaModelDependency, context: context
                ),
                actionHandler: RecalledMessageActionHandler(context: context)
            ))
            return true
        }
        if message.isDeleted && !(content is DeletedContentViewModel) {
            self.updateContent(content: DeletedContentViewModel(
                metaModel: metaModel,
                metaModelDependency: self.metaModelDependency,
                context: context
            ))
            return true
        }
        return false
    }
}
