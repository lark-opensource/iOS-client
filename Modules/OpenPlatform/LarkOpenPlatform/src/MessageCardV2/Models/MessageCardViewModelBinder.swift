//
//  MessageCardViewModelBinder.swift
//  LarkOpenPlatform
//
//  Created by majiaxin.jx on 2022/11/20.
//

import LarkModel
import Foundation
import EEFlexiable
import EENavigator
import LarkContainer
import AsyncComponent
import LarkMessageBase
import LarkMessageCard
import RustPB
import LKCommonsLogging
import LarkSetting
import ECOProbe

struct MessageCardComponentStyle {
    static let border: Border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
    static let cornerRadius: CGFloat = 10
}

//消息卡片业务配置：这里目前仅用于话题套话题场景的宽度修正
struct MessageCardConfig {
    var preferWidthOffset: CGFloat = 0
}


/*
 * 消息卡片通用 ViewModel binder, 适用场景详见 MessageCardViewModelFactory
 *
 */
final class MessageCardCommonViewModelBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MessageCardViewModelContext>: ComponentBinder<C> {

    let logger = Logger.log(MessageCardCommonViewModelBinder.self, category: "MessageCardCommonViewModelBinder")

    private var context: C?
    private var vmDidSetup: Bool = false
    let config: MessageCardConfig
    private let reuseKey: UUID

    @Injected private var cardContextManager: MessageCardContextManagerProtocol
    //卡片最上层容器
    private var props: MessageCardMaskViewComponent<C>.Props
    private var _component: MessageCardMaskViewComponent<C>
    override var component: MessageCardMaskViewComponent<C> { _component }

    private var contentProps: MessageUniversalCardComponentProps
    private var contentComponent: MessageUniversalCardComponent<C>

    private var cardContentProps2: MessageCardComponentProps2
    private var cardContentComponent2: MessageCardComponent2<C>
    private var useUniversalCard: Bool {
        guard let userResolver = context?.userResolver else {
            logger.error("MessageCardCommonViewModelBinder get useUniversalCard fail because userResolver is nil")
            return false
        }
        do {
            return try userResolver.resolve(assert: MessageCardMigrateControl.self).useUniversalCard
        } catch let error {
            logger.error("MessageCardCommonViewModelBinder get useUniversalCard fail because userResolver resolve with error", error: error)
            return false
        }
    }

    private static func componentStyle(message: Message, context: C?, metaModelDependency: D?, config: MessageCardConfig) -> ASComponentStyle {
        let style = ASComponentStyle()
        if let preferWidth = getPreferWidth(message: message, context: context, metaModelDependency: metaModelDependency, config: config) {
            style.width = CSSValue(cgfloat: preferWidth)
        }
        style.flexWrap = .noWrap
        style.flexDirection = .column
        style.alignItems = .stretch
        style.overflow = .scroll
        return style
    }
    
    static func getPreferWidth(message: Message, context: C?, metaModelDependency: D?, config: MessageCardConfig) -> CGFloat? {
        guard let metaModelDependency = metaModelDependency, let context = context else { return nil }
        let contentPreferMaxWidth = metaModelDependency.getContentPreferMaxWidth(message) - config.preferWidthOffset
        return min(
            contentPreferMaxWidth,
            context.maxCardWidthLimit(message, contentPreferMaxWidth)
        )
    }

    init(
        message: Message,
        chat: @escaping () -> Chat,
        config: MessageCardConfig,
        reuseKey: UUID,
        key: String? = nil,
        context: C,
        metaModelDependency: D? = nil
    ) {
        self.config = config
        self.context = context
        self.reuseKey = reuseKey
        props = MessageCardMaskViewComponent<C>.Props(
            preferWidth: Self.getPreferWidth(message: message, context: context, metaModelDependency: metaModelDependency, config: config) ?? .zero,
            rendertype: getRenderType(message, scene: context.scene),
            message: message,
            isUserInteractionEnabled: context.scene != .pin,
            chat: chat
        )
        _component = MessageCardMaskViewComponent<C>(
            props: props,
            style: Self.componentStyle(message: message, context: context, metaModelDependency: metaModelDependency, config: config),
            context: context
        )
        contentProps = MessageUniversalCardComponentProps(reuseKey: reuseKey)
        contentComponent = MessageUniversalCardComponent<C>(props: contentProps, context: context)
        cardContentProps2 = MessageCardComponentProps2(reuseKey: reuseKey)
        cardContentComponent2 = MessageCardComponent2<C>(
            props: cardContentProps2,
            style: ASComponentStyle(),
            context: context
        )
        if (try? context.userResolver.resolve(assert: MessageCardMigrateControl.self).useUniversalCard) ?? false {
            _component.setContentComponent(contentComponent)
        } else {
            _component.setContentComponent(cardContentComponent2)
        }
        super.init(key: key, context: context)
    }

    func updateSummary(_ vm: MessageCardViewModel<M, D, C>) {
        if useUniversalCard {
            if let actionService = contentProps.cardData?.context.dependency?.actionService as? MessageUniversalCardActionService {
                if let summary = actionService.summary,
                   var content = vm.message.content as? CardContent {
                    content.summary  = summary
                    vm.message.content = content
                }
                if let translateSummary = actionService.translateSummary,
                   var translateContent = vm.message.translateContent as? CardContent {
                    translateContent.summary = translateSummary
                    vm.message.translateContent = translateContent
                }
            }
            return
        }
        
        if let context = cardContextManager.getContext(key: vm.trace.traceId) {
            if var content = vm.message.content as? CardContent,
               let summary = context.getBizContext(key: "summary") as? String {
                content.summary  = summary
                vm.message.content = content
            }
            if var translateContent = vm.message.translateContent as? CardContent,
               let translateSummary = context.getBizContext(key: "translateSummary") as? String {
                translateContent.summary = translateSummary
                vm.message.translateContent = translateContent
            }
        }
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MessageCardViewModel<M, D, C> else {
            assertionFailure("MessageCardCommonViewModelBinder update with wrong type, vm: \(vm.self)")
            return
        }
        if let width = Self.getPreferWidth(message: vm.message, context: vm.context, metaModelDependency: vm.metaModelDependency, config: self.config) {
            props.preferWidth = width
            _component.style.width = CSSValue(cgfloat: width)
            cardContentProps2.identify = MessageCardIdentify(message: vm.message, preferWidth: width)
        } else {
            logger.error("getPreferWidth failed")
        }
        updateMaskViewComponentProps(from: vm)
        updateSummary(vm)

        if useUniversalCard {
            if let cardData = Self.universalCardData(
                fromVM: vm,
                config: self.config,
                userResolver: vm.userResolver
            ) {
                contentProps.cardData = cardData
            } else {
                logger.error("convert universal card data fail", additionalData: ["messageID": vm.message.id, "traceID": vm.trace.traceId])
            }
            contentProps.update(lifeCycleClient: vm)
            contentProps.cardSize = vm.currentSize
            contentProps.maxHeight = vm.preferMaxHeight
            contentProps.updateCardSize = { [weak vm] (size) in
                vm?.currentSize = size
            }
            contentComponent.props = contentProps
        } else {
            //更新卡片数据
            cardContentProps2.cardContainerData = Self.cardContainerData(fromVM: vm, config: self.config)
            
            cardContentProps2.update(lifeCycleClient: vm)

            cardContentProps2.cardSize = vm.currentSize
            cardContentProps2.updateCardSize = { [weak vm] (size) in
                vm?.currentSize = size
            }

            cardContentComponent2.props = cardContentProps2
        }
        if !vmDidSetup {
            vmDidSetup = true
            vm.didFinishSetup()
        }
    }

    func forceRender() {
        if useUniversalCard {
            contentComponent.forceRenderCard()
        } else {
            cardContentComponent2.forceRenderCard()
        }
    }

    func updateMaskViewComponentProps(from vm: MessageCardViewModel<M, D, C>) {
        props.renderType = getRenderType(vm.message, scene: vm.context.scene)
        props.message = vm.message
        props.trace = vm.trace
        _component.props = props
    }
}
