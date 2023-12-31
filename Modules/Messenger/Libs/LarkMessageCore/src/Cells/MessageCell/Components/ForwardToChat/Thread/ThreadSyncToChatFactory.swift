//
//  ThreadSyncToChatFactory.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/26.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkAccountInterface

public protocol ThreadSyncToChatComponentContext: ThreadSyncToChatComponentViewModelContext { }

extension PageContext: ThreadSyncToChatComponentContext { }

public final class ThreadSyncToChatComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .syncToChat
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        return message.syncToChatMessageType == .syncToChatSourceMessage
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ThreadSyncToChatComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ThreadSyncToChatComponentBinder<M, D, C>(context: context)
        )
    }
}
