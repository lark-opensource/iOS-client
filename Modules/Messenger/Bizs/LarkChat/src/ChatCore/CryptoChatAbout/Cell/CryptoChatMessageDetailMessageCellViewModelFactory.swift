//
//  CryptoChatMessageDetailMessageCellViewModelFactory.swift
//  LarkChat
//
//  Created by zc09v on 2021/12/1.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import Swinject
import EEFlexiable
import LarkMessageCore
import LarkContainer
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkFeatureGating

final class CryptoChatMessageDetailMessageCellViewModelFactory: MessageDetailMessageCellViewModelFactory {
    override func createMessageCellViewModel(
        with model: MessageDetailMetaModel,
        metaModelDependency: MessageDetailCellModelDependency,
        contentFactory: MessageDetailMessageSubFactory,
        subFactories: [SubType: MessageDetailMessageSubFactory]
    ) -> MessageDetailMessageCellViewModel {
        return CryptoChatMessageDetailCellViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            metaModelDependency: metaModelDependency,
            subFactories: subFactories
        )
    }

    override func registerServices() {
        let r = context.resolver
        context.pageContainer.register(DeleteMessageService.self) { [unowned self] in
            return DeleteMessageServiceImpl(
                controller: self.context.pageAPI ?? UIViewController(),
                messageAPI: try? r.resolve(assert: MessageAPI.self),
                nav: self.context.navigator
            )
        }
        context.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }
    }
}
