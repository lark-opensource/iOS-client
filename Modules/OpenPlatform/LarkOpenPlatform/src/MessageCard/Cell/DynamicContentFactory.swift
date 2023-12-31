//
//  DynamicContentFactory.swift
//  Action
//
//  Created by qihongye on 2019/6/23.
//

import Foundation
import Swinject
import LarkContainer
import LarkMessageBase
import LarkModel
import NewLarkDynamic
import LarkFeatureGating
import LarkMessageCore
import LarkSetting
import LarkMessageCard

class DynamicContentFactory<C: DynamicContentViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 这个开关逻辑必须与 MessageCardFactory 逻辑保持互斥, 否则会出现两个同时加载的情况 @majiaxin.jx
        guard !MessageCardRenderControl.lynxCardRenderEnable(message: metaModel.message) else {
            return false
        }
        
        guard !metaModel.message.isRecalled,
            let cardType = (metaModel.message.content as? CardContent)?.type else {
                return false
        }

        if metaModel.message.isEphemeral {
            if (self.context as? ChatContext)?.resolver != nil,
                LarkFeatureGating.shared.getFeatureBoolValue(for: .messageCardEphemeral) {
                metaModel.message.isVisible = true
                return true
            } else {
                metaModel.message.isVisible = false
                return false
            }
        }
        return cardType != .vote && cardType != .unknownType && cardType != .openCard
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return DynamicContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: DynamicContentViewModelBinder<M, D, C>(message: metaModel.message, chat: metaModel.getChat, metaModelDependency: metaModelDependency, context: context)
        )
    }

    public override func registerServices(pageContainer: PageContainer) {
        let cardStatusObservable = self.context.pushCardMessageActionObserver
        
        pageContainer.register(ActionService.self) {
            return ActionServiceImpl()
        }
        pageContainer.register(ToastManagerService.self) {
            return ToastManager(
                provider: ToastManagerProvider(
                    cardStatusObservable: cardStatusObservable
                )
            )
        }
        // 进入会话时，根据有无缓存和缓存过期时间按需拉取加号应用数据
        if context.scene == .newChat, let resover = (context as? ChatContext)?.userResolver {
            pageContainer.register(MessageActionDataPreloader.self) {
                return MessageActionDataPreloader(resolver: resover)
            }
        }
    }
}

final class MessageDetailDynamicContentFactory<C: DynamicContentViewModelContext>: DynamicContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return DynamicContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: MessageDetailDynamicContentViewModelBinder<M, D, C>(message: metaModel.message, chat: metaModel.getChat, metaModelDependency: metaModelDependency, context: context)
        )
    }
}
