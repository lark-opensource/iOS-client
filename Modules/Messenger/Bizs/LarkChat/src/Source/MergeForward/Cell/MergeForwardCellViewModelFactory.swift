//
//  MergeForwardCellViewModelFactory.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
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

class MergeForwardCellViewModelFactory: CellViewModelFactory<MergeForwardMessageMetaModel, MergeForwardCellMetaModelDependency, MergeForwardContext> {
    override func createMessageCellViewModel(
        with model: MergeForwardMessageMetaModel,
        metaModelDependency: MergeForwardCellMetaModelDependency,
        contentFactory: MergeForwardMessageSubFactory,
        subFactories: [SubType: MergeForwardMessageSubFactory]
    ) -> MergeForwardCellViewModel {
        return MergeForwardMessageCellViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            metaModelDependency: metaModelDependency,
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
    }

    override func createSystemCellViewModel(with model: MergeForwardMessageMetaModel, metaModelDependency: MergeForwardCellMetaModelDependency) -> MergeForwardCellViewModel {
        let viewModel: MergeForwardCellViewModel = MergeForwardSystemCellViewModel(metaModel: model, context: context)
        return viewModel
    }

    func createSign() -> MergeForwardCellViewModel {
        return MergeForwardSignCellViewModel(context: context)
    }

    func createSign(signDate: TimeInterval) -> MergeForwardCellViewModel {
        return MergeForwardSignDateCellViewModel(signDate: signDate, context: context)
    }

    func create(date: TimeInterval) -> MergeForwardCellViewModel {
        return MergeForwardDateCellViewModel(date: date, context: context)
    }

    func create(time: TimeInterval) -> MergeForwardCellViewModel {
        return MergeForwardTimeCellViewModel(time: time, context: context)
    }

    func createPreviewSign() -> MergeForwardCellViewModel {
        return MergeForwardPreviewSignCellViewModel(context: context)
    }

    override func registerServices() {
        context.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }
    }
}

final class ForwardChatPreviewCellViewModelFactory: MergeForwardCellViewModelFactory {
    override func canCreateSystemDirectly(with model: MergeForwardMessageMetaModel, metaModelDependency: MergeForwardCellMetaModelDependency) -> Bool {
        /// Thread in Chat模式在撤回时不需要直接转换成为系统消息
        return context.canCreateSystemRecalledCell(model.message)
    }

    override func createSystemCellViewModel(with model: MergeForwardMessageMetaModel, metaModelDependency: MergeForwardCellMetaModelDependency) -> MergeForwardCellViewModel {
        /// 撤回消息留痕优化，UI表现变成系统消息
        if context.canCreateSystemRecalledCell(model.message) {
            var config = RecallContentConfig()
            config.isShowReedit = true
            return RecalledSystemCellViewModel(metaModel: model, context: context, config: config)
        }
        return super.createSystemCellViewModel(with: model, metaModelDependency: metaModelDependency)
    }
}
