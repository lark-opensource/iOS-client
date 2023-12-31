//
//  ReplyThreadInfoComponentFactory.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/4/25.
//

import Foundation
import LarkModel
import RxSwift
import LarkMessageBase
import LarkSetting
import LarkMessengerInterface
import LarkContainer

// 消息thread提示信息, 并包含openThread/createThread menu
public final class ReplyThreadInfoComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .replyThreadInfo
    }

    // https://bytedance.feishu.cn/docx/doxcnAijkQVHZDEodrehSxqFxrb
    private lazy var replyInThreadConfig: ReplyInThreadConfigService? = {
        return try? self.context.resolver.resolve(assert: ReplyInThreadConfigService.self)
    }()

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        // 会话、合并转发详情页交给RevealReplyInTreadComponentFactory渲染话题评论
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            return false
        }
        return message.replyInThreadCount > 0 && message.threadMessageType == .threadRootMessage
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ReplyThreadInfoComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ReplyThreadInfoComponentBinder<M, D, C>(context: context)
        )
    }
}
