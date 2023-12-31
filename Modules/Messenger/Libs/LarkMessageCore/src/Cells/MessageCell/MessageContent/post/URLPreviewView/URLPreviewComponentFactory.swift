//
//  URLPreviewComponentFactory.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/23.
//

import Foundation
import LarkMessageBase
import LarkModel
import LarkSDKInterface
import DynamicURLComponent

protocol URLPreviewContext: URLPreviewComponentViewModelContext { }

public final class URLPreviewComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .urlPreview
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        if !message.hasUrlPreview {
            return false
        }
        if message.isRecalled || message.isDecryptoFail {
            return false
        }
        if TCPreviewContainerComponentFactory.canHandle(entities: message.urlPreviewEntities, hangPoints: message.urlPreviewHangPointMap) {
            return false
        }
        //code_block_end
        return true
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        switch context.scene {
        case .newChat, .mergeForwardDetail,
                .threadChat, .threadDetail, .replyInThread, .messageDetail, .threadPostForwardDetail:
            return URLPreviewComponentViewModel(metaModel: metaModel,
                                                metaModelDependency: metaModelDependency,
                                                context: context,
                                                binder: URLPreviewComponentBinder<M, D, C>(context: context))
        case .pin:
            return URLPreviewComponentViewModel(metaModel: metaModel,
                                                metaModelDependency: metaModelDependency,
                                                context: context,
                                                binder: PinUrlPreviewComponentBinder<M, D, C>(context: context))
        @unknown default:
            fatalError("new value")
        }
    }
}

extension PageContext: URLPreviewContext {
}
