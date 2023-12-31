//
//  ReferenceListComponentFactory.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import RustPB
import LarkModel
import Foundation
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface

public protocol ReferenceListFactoryContext: ReferenceListBinderContext {}

public final class ReferenceListComponentFactory<C: ReferenceListFactoryContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .referenceList
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 必须是和MyAI的主分会场才展示
        guard metaModel.getChat().isP2PAi else { return false }
        // MyAI回复的才展示
        guard metaModel.message.fromChatter?.type == .ai else { return false }
        // 存在引用链接才展示，文本消息才展示
        var contentReferences: [Basic_V1_Content.Reference] = []
        if metaModel.message.type == .text, let content = metaModel.message.content as? TextContent {
            contentReferences = content.contentReferences
        } else if metaModel.message.type == .post, let content = metaModel.message.content as? PostContent {
            contentReferences = content.contentReferences
        }
        guard !contentReferences.isEmpty else { return false }
        // 撤回的消息不展示
        guard !metaModel.message.isRecalled else { return false }
        // 流式中不展示
        guard metaModel.message.streamStatus != .streamTransport, metaModel.message.streamStatus != .streamPrepare else { return false }
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ReferenceListComponentBinder(
            viewModel: ReferenceListComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            actionHandler: ReferenceListComponentActionHandler(context: context)
        )
    }
}

extension PageContext: ReferenceListFactoryContext {}
