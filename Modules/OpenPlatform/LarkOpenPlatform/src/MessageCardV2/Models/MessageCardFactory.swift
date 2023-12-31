//
//  MessageCardFactory.swift
//  LarkOpenPlatform
//
//  Created by majiaxin on 2022/12/9.
//

import Foundation
import Swinject
import LarkContainer
import LarkMessageBase
import LarkModel
import NewLarkDynamic
import LarkMessageCard
import ECOProbe
import LarkMessageCore
import LarkSetting
import UniversalCardInterface
import UniversalCard

class MessageCardFactory<C: MessageCardViewModelContext>: MessageSubFactory<C> {
    
    public override class var subType: SubType {
        return .content
    }
    
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 这个开关逻辑必须与 DynamicContentFactory 逻辑保持互斥, 否则会出现两个同时加载的情况 @majiaxin.jx
        guard MessageCardRenderControl.lynxCardRenderEnable(message: metaModel.message) else {
            return false
        }
        guard !metaModel.message.isRecalled else {
            return false
        }
        guard (metaModel.message.content as? CardContent)?.type == .text else {
            return false
        }
        guard !(metaModel.message.isEphemeral && !metaModel.message.isVisible) else {
            return false
        }
        return true
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let trace = OPTraceService.default().generateTrace()
        let reuseKey = UUID()
        reportStart(message: metaModel.message, trace: trace)
        let config = MessageCardConfig()
        return MessageCardViewModel(
            trace: trace,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: MessageCardCommonViewModelBinder<M, D, C>(
                message: metaModel.message,
                chat: metaModel.getChat,
                config: config,
                reuseKey: reuseKey,
                context: context,
                metaModelDependency: metaModelDependency
            ), 
            reuseKey: reuseKey
        )
    }

    public override func registerServices(pageContainer: PageContainer) {
        let userResolver = context.userResolver
        if (try? userResolver.resolve(assert: MessageCardMigrateControl.self).useUniversalCard) ?? false {
            pageContainer.register(UniversalCardLayoutServiceProtocol.self) {
                return UniversalCardLayoutService(resolver: userResolver)
            }
            pageContainer.register(UniversalCardSharePoolProtocol.self) {
                return UniversalCardSharePool(resolver: userResolver)
            }
            if context.userResolver.fg.staticFeatureGatingValue(with: "universalcard.async_render.enable") {
                pageContainer.register(MessageCardPageService.self) { [weak pageContainer] in
                    return MessageCardPageService(pageContainer: pageContainer)
                }
            }

        } else {
            let cardStatusObservable = self.context.pushCardMessageActionObserver
            pageContainer.register(ActionService.self) {
                return ActionServiceImpl()
            }
            pageContainer.register(ToastManagerService.self) {
                return ToastManager(provider: ToastManagerProvider(cardStatusObservable: cardStatusObservable)
                )
            }
            pageContainer.register(MessageCardContainerSharePoolService.self) {
                return MessageCardContainerSharePool()
            }
            //消息卡片统一的进会话时机，可以做一些更新/初始化事情
            pageContainer.register(MessageCardEnterPageInitializer.self) {
                return MessageCardEnterPageInitializer()
            }
        }
        // 加号菜单FG打开，且进入会话时，根据有无缓存和缓存过期时间按需拉取加号应用数据
        if context.scene == .newChat,
            let resover = (context as? ChatContext)?.userResolver {
            pageContainer.register(MessageActionDataPreloader.self) {
                return MessageActionDataPreloader(resolver: resover)
            }
        }
    }
}

//话题套话题时卡片专用factory
final class MessageCardThreadFactory<C: MessageCardViewModelContext>: MessageCardFactory<C> {
    @FeatureGatingValue(key: "messagecard.renderoptimization.enable")
    var enableRenderOptimization: Bool

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return enableRenderOptimization && super.canCreate(with: metaModel)
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let trace = OPTraceService.default().generateTrace()
        let reuseKey = UUID()
        reportStart(message: metaModel.message, trace: trace)
        let threadPaddingOffset = metaModelDependency.contentPadding * 2
        let config = MessageCardConfig(preferWidthOffset: threadPaddingOffset)
        return MessageCardViewModel(
            trace: trace,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: MessageCardCommonViewModelBinder<M, D, C>(
                message: metaModel.message,
                chat: metaModel.getChat,
                config: config,
                reuseKey: reuseKey,
                context: context,
                metaModelDependency: metaModelDependency
            ),
            reuseKey: reuseKey
        )
    }
}
