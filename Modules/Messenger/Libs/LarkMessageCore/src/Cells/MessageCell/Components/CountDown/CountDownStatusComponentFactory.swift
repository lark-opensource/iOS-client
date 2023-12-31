//
//  CountDownStatusComponentFactory.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2021/5/18.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface

public protocol CountDownContext: CountDownViewModelContext {}

public final class CountDownStatusComponentFactory<C: CountDownContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .countDown
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.burnLife > 0 && !context.isBurned(message: metaModel.message) && metaModel.message.localStatus == .success
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        if case .messageDetail = self.context.scene {
            return NormalCountDownStatusViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                binder: MessageDetailCountDownStatusComponentBinder<M, D, C>(context: context)
            )
        }
        return NormalCountDownStatusViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CountDownStatusComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: CountDownContext {
    public var burnTimer: Observable<Int64> {
        return (try? resolver.resolve(assert: ServerNTPTimeService.self, cache: true).burnTimer) ?? .empty()
    }

    public var serverTime: Int64 {
        return (try? resolver.resolve(assert: ServerNTPTimeService.self, cache: true).serverTime) ?? 0
    }
}
