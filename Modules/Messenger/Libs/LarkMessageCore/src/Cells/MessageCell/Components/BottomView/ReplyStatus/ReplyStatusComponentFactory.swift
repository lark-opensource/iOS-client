//
//  ReplyStatusComponentFactory.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/3.
//

import Foundation
import LarkModel
import RxSwift
import LarkMessageBase
import LarkSetting
import LarkMessengerInterface
import LarkContainer

protocol ReplyStatusComponentContext: ReplyStatusComponentViewModelContext { }

extension PageContext: ReplyStatusComponentContext {
    public func hitABTest(chat: LarkModel.Chat) -> Bool {
        let testService = try? self.resolver.resolve(assert: MenuInteractionABTestService.self, cache: true)
        return testService?.hitABTest(chat: chat) ?? false
    }

    public var pageSupportReply: Bool {
        return self.pageAPI?.pageSupportReply ?? false
    }
}

public final class ReplyStatusComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .replyStatus
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if metaModel.message.threadMessageType != .unknownThreadMessage {
            return false
        }
        return metaModel.message.replyCount > 0
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        var config = ReplyStatusConfig()
        if context.scene == .messageDetail {
            config.replyCanTap = false
        }
        return ReplyStatusComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ReplyStatusComponentBinder<M, D, C>(context: context),
            config: config,
            hitABTest: context.hitABTest(chat: metaModel.getChat())
        )
    }

}
