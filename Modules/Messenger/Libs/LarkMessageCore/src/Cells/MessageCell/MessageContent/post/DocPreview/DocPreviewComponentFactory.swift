//
//  DocPreviewComponentFactory.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/19.
//

import Foundation
import LarkModel
import LKCommonsLogging
import LarkMessageBase
import DynamicURLComponent
import LarkSetting

protocol DocPreviewContext: DocPreviewViewModelContext & DocPreviewComponentContext { }

public final class DocPreviewComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .docsPreview
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        if !message.hasDocsPreview(currentChatterId: self.context.currentUserID) {
            return false
        }
        if message.isRecalled || message.isDecryptoFail {
            return false
        }
        // 旧的Doc预览优先级比URL中台预览高
        if TCPreviewContainerComponentFactory.canHandle(entities: message.urlPreviewEntities, hangPoints: message.urlPreviewHangPointMap) {
            return false
        }
        //code_block_end
        return true
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        switch context.scene {
        case .pin:
            return PinDocPreviewComponentViewModel(metaModel: metaModel,
                                                metaModelDependency: metaModelDependency,
                                                context: context,
                                                binder: PinDocPreviewComponentBinder<M, D, C>(context: context))
        default:
            return DocPreviewComponentViewModel(metaModel: metaModel,
                                                metaModelDependency: metaModelDependency,
                                                context: context,
                                                binder: DocPreviewComponentBinder<M, D, C>(context: context))
        }
    }
}

extension PageContext: DocPreviewContext {
    public var docPreviewdependency: DocPreviewViewModelContextDependency? {
        return try? resolver.resolve(assert: DocPreviewViewModelContextDependency.self)
    }
}
