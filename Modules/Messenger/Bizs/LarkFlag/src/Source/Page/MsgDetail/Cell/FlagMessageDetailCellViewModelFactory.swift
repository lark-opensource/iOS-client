//
//  FlagMessageDetailCellViewModelFactory.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import Foundation
import LarkMessageCore
import LarkModel
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkKAFeatureSwitch
import LarkFeatureSwitch
import LarkAppConfig
import LarkFeatureGating

final class FlagMessageDetailCellViewModelFactory: CellViewModelFactory<FlagMessageDetailMetaModel, FlagMessageDetailCellMetaModelDependency, FlagMessageDetailContext> {

    override func canCreateSystemDirectly(with model: FlagMessageDetailMetaModel, metaModelDependency: FlagMessageDetailCellMetaModelDependency) -> Bool {
        return context.canCreateSystemRecalledCell(model.message)
    }

    override func createSystemCellViewModel(with model: FlagMessageDetailMetaModel, metaModelDependency: FlagMessageDetailCellMetaModelDependency) -> FlagMessageDetailCellViewModel {
        /// 撤回消息留痕优化，UI表现变成系统消息
        if context.canCreateSystemRecalledCell(model.message) {
            var config = RecallContentConfig()
            config.isShowReedit = true
            return RecalledSystemCellViewModel(metaModel: model, context: context, config: config)
        }
        return super.createSystemCellViewModel(with: model, metaModelDependency: metaModelDependency)
    }

    override func createMessageCellViewModel(
        with model: FlagMessageDetailMetaModel,
        metaModelDependency: FlagMessageDetailCellMetaModelDependency,
        contentFactory: FlagMessageDetailSubFactory,
        subFactories: [SubType: FlagMessageDetailSubFactory]
    ) -> FlagMessageDetailCellViewModel {
        return FlagMessageDetailComponentViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            metaModelDependency: metaModelDependency,
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
    }

    override func registerServices() {
        context.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }
    }
}
