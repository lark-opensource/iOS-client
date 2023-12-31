//
//  CryptoChatCellViewModelFactory.swift
//  LarkChat
//
//  Created by zc09v on 2021/11/24.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkModel
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkContainer

final class CryptoChatCellViewModelFactory: ChatCellViewModelFactory {

    override func createMessageCellViewModel(
        with model: ChatMessageMetaModel,
        metaModelDependency: ChatCellMetaModelDependency,
        contentFactory: ChatMessageSubFactory,
        subFactories: [SubType: ChatMessageSubFactory]
    ) -> ChatCellViewModel {
        return CryptoChatMessageCellViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subfactories: subFactories,
            metaModelDependency: metaModelDependency
        )
    }

    override func canCreateSystemDirectly(with model: ChatMessageMetaModel, metaModelDependency: ChatCellMetaModelDependency) -> Bool {
        /// Thread in Chat模式在撤回时不需要直接转换成为系统消息
        /// 尽管密聊没有这个模式，考虑后面迁移的话不留坑，直接过滤了。
        return context.canCreateSystemRecalledCell(model.message)
    }

    override func createSystemCellViewModel(with model: ChatMessageMetaModel, metaModelDependency: ChatCellMetaModelDependency) -> ChatCellViewModel {
        if context.canCreateSystemRecalledCell(model.message) {
            var config = RecallContentConfig()
            config.isShowReedit = true
            return CryptoRecalledSystemCellViewModel(metaModel: model, context: context, config: config)
        }
        let viewModel: ChatCellViewModel = ChatSystemCellViewModel(metaModel: model, context: context)
        return viewModel
    }

    override func registerServices() {
        let r = context.resolver
        context.pageContainer.register(DeleteMessageService.self) { [unowned self] in
            return DeleteMessageServiceImpl(
                controller: self.context.pageAPI ?? UIViewController(),
                messageAPI: try? r.resolve(assert: MessageAPI.self, cache: true),
                nav: self.context.navigator
            )
        }
        context.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }
    }
}
