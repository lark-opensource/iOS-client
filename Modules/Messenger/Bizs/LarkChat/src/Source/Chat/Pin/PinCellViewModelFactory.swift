//
//  PinCellViewModelFactory.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/22.
//

import Foundation
import LarkMessageBase
import LarkModel
import LarkMessageCore
import LarkMessengerInterface
import LarkFeatureGating

struct PinMetaModel: CellMetaModel {
    let message: Message
    let chat: Chat
    var getChat: () -> Chat {
        return { self.chat }
    }

    init(message: Message, chat: Chat) {
        self.message = message
        self.chat = chat
    }
}

protocol PinCellMetaModelDependency: CellMetaModelDependency {
    var config: PinCellConfig { get }
}

struct PinCellMetaModelDependencyImp: PinCellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    let config: PinCellConfig
    init(
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        config: PinCellConfig = .default
    ) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.config = config
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

struct PinCellConfig {
    // 默认
    static let `default` = PinCellConfig()

    /// 是否显示来自xxx群
    var showFromChat: Bool

    init(showFromChat: Bool = false) {
        self.showFromChat = showFromChat
    }
}

final class PinCellViewModelFactory: CellViewModelFactory<PinMetaModel, PinCellMetaModelDependencyImp, PinContext> {
    override func createMessageCellViewModel(
        with model: PinMetaModel,
        metaModelDependency: PinCellMetaModelDependencyImp,
        contentFactory: PinMessageSubFactory,
        subFactories: [SubType: PinMessageSubFactory]
        ) -> PinCellViewModel {
        return PinMessageCellViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            metaModelDependency: metaModelDependency,
            cellLifeCycleObseverRegister: self.cellLifeCycleObseverRegister
        )
    }

    override func createSystemCellViewModel(with model: PinMetaModel, metaModelDependency: PinCellMetaModelDependencyImp) -> PinCellViewModel {
        return SystemCellViewModel(metaModel: model, context: context)
    }

    override func registerServices() {
        context.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }
    }

}
