//
//  FlagListMessageViewModelFactory.swift
//  LarkFlag
//
//  Created by ByteDance on 2022/10/17.
//

import Foundation
import LarkMessageBase
import LarkMessageCore

final class FlagListMessageViewModelFactory: CellViewModelFactory<FlagListMessageMetaModel, FlagListMessageCellMetaModelDependencyImpl, FlagListMessageContext> {
    var getCellDependency: (() -> FlagListMessageCellMetaModelDependencyImpl)?

    public override func createMessageCellViewModel(
        with model: FlagListMessageMetaModel,
        metaModelDependency: FlagListMessageCellMetaModelDependencyImpl,
        contentFactory: FlagListMessageSubFactory,
        subFactories: [SubType: FlagListMessageSubFactory]
    ) -> FlagListMessageComponentViewModel {
        return FlagListMessageComponentViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            metaModelDependency: metaModelDependency
        )
    }

    override func registerServices() {
        context.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }
    }
}
