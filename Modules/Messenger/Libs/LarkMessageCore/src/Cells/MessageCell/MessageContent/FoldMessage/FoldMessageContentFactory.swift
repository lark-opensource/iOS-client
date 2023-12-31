//
//  FoldMessageContentFactory.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/9/16.
//

import Foundation
import RxSwift
import LarkModel
import LarkMessageBase
import EENavigator

public final class FoldMessageContentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.isFoldRootMessage
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return FoldMessageContentViewModel(metaModel: metaModel,
                                    metaModelDependency: metaModelDependency,
                                    context: context)
    }
}

extension PageContext: FoldMessageContentViewModelContext {
     public func getCurrentChatterId() -> String {
         return currentUserID
     }
     public func getDisplayName(chatter: Chatter, chat: Chat) -> String {
         return getDisplayName(chatter: chatter, chat: chat, scene: .head)
     }
}
