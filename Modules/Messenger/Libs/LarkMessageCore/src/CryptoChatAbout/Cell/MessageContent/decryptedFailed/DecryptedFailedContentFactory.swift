//
//  DecryptedFailedContentFactory.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/4/12.
//

import UIKit
import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase

public protocol DecryptedFailedContentContext: ViewModelContext, ColorConfigContext {
}

public final class DecryptedFailedContentFactory<C: DecryptedFailedContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override var priority: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.isSecretChatDecryptedFailed
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return DecryptedFailedContentViewModel(metaModel: metaModel,
                                               metaModelDependency: metaModelDependency,
                                               context: context,
                                               binder: DecryptedFailedContentComponentBinder<M, D, C>(context: context))
    }
}

extension PageContext: DecryptedFailedContentContext {
}
