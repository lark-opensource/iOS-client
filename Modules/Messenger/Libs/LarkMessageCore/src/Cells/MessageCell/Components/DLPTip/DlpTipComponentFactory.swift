//
//  DLPTipComponentFactory.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/6/20.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkAccountInterface
import LarkSetting

protocol DlpComponentContext: DlpTipComponentViewModelContext, DLPFeedbackComponentViewModelContext { }

public final class DlpTipComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .dlpTip
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        if message.isRecalled {
            return false
        }
        if message.fromId != self.context.currentUserID {
            return false
        }
        return message.dlpState == .dlpBlock
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {

        if let securityExtra = metaModel.message.securityExtra,
            !securityExtra.tipText.isEmpty {
            return DLPFeedbackComponentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                binder: DLPFeedbackComponentBinder<M, D, C>(context: context)
                )
        }

        return DlpTipComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: MessageDlpTipComponentBinder<M, D, C>(context: context)
            )
    }
}

extension PageContext: DlpComponentContext { }
