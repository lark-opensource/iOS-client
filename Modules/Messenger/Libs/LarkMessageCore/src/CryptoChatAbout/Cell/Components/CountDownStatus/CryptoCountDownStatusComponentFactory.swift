//
//  CryptoCountDownStatusComponentFactory.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/2/17.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface

public final class CryptoCountDownStatusComponentFactory<C: CountDownContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .countDown
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return !context.isBurned(message: metaModel.message) && metaModel.message.localStatus == .success
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        if case .messageDetail = self.context.scene {
            return CryptoCountDownStatusViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                binder: MessageDetailCountDownStatusComponentBinder<M, D, C>(context: context)
            )
        }
        return CryptoCountDownStatusViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CountDownStatusComponentBinder<M, D, C>(context: context)
        )
    }
}
