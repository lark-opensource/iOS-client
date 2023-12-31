//
//  NewVoteContentFactory.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/4/10.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkRustClient
import RxSwift
import RustPB
import LKCommonsLogging
import UniverseDesignToast
import LarkSDKInterface
import UIKit

public protocol NewVoteContentContext: NewVoteContentViewModelContext & ComponentContext {
    var scene: ContextScene { get }
}

private let logger = Logger.log(NewVoteContentContext.self, category: "NewVoteContentContext")

public class NewVoteContentFactory<C: NewVoteContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return ((metaModel.message.content as? LarkModel.VoteContent) != nil)
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return NewVoteContentViewModel(metaModel: metaModel,
                                    metaModelDependency: metaModelDependency,
                                    context: context,
                                    binder: NewVoteContentComponentBinder<M, D, C>(context: context))
    }
}

public class ChatPinVoteContentFactory<C: NewVoteContentContext>: NewVoteContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return NewVoteContentViewModel(metaModel: metaModel,
                                       metaModelDependency: metaModelDependency,
                                       context: context,
                                       binder: NewVoteContentComponentBinder<M, D, C>(context: context),
                                       foldEnable: false)
    }
}

public final class MessageDetailNewVoteContentFactory<C: NewVoteContentContext>: NewVoteContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return MessageDetailNewVoteContentViewModel(metaModel: metaModel,
                                                 metaModelDependency: metaModelDependency,
                                                 context: context,
                                                 binder: MessageDetailNewVoteContentComponentBinder<M, D, C>(context: context))
    }
}

public final class PinNewVoteContentFactory<C: NewVoteContentContext>: NewVoteContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return PinNewVoteContentViewModel(metaModel: metaModel,
                                    metaModelDependency: metaModelDependency,
                                    context: context,
                                    binder: PinNewVoteContentComponentBinder<M, D, C>(context: context))
    }
}

public final class MergeForwardNewVoteContentFactory<C: NewVoteContentContext>: NewVoteContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return MergeForwardNewVoteContentViewModel(metaModel: metaModel,
                                          metaModelDependency: metaModelDependency,
                                          context: context,
                                          binder: MergeForwardNewVoteContentComponentBinder<M, D, C>(context: context))
    }
}

extension PageContext: NewVoteContentContext {

    public func getContentPreferMaxHeight(_ message: Message) -> CGFloat {
        return self.dataSourceAPI?.hostUIConfig.size.height ?? 800
    }
}
