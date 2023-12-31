//
//  DeleteContentFactory.swift
//  Action
//
//  Created by 赵冬 on 2019/8/3.
//

import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase

public protocol DeletedContentContext: ViewModelContext {
}

public final class ReplyInThreadDeletedContentFactory<C: DeletedContentContext>: DeletedContentFactory<C> {
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.isDeleted
    }
}

public class DeletedContentFactory<C: DeletedContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.isDeleted && metaModel.message.rootMessage == nil
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return DeletedContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }
}

extension PageContext: DeletedContentContext {}
