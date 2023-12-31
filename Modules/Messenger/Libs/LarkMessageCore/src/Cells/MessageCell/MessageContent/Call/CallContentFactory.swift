//
//  CallContentFactory.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/18.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkMessengerInterface

/// 回拨/重拨消息上下文
public protocol CallContentContext: ViewModelContext, ColorConfigContext {
    /// 拨打电话
    func callContacts(_ chatterId: String)
    /// 是不是自己
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterId: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
}

/// 回拨/重拨消息
public final class CallContentFactory<C: CallContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        /// 回拨/重拨消息气泡在新版本上不展示
        /// 仅展示普通系统消息样式
        return false
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return CallContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CallContentComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: CallContentContext {
    public func callContacts(_ chatterId: String) {
        guard let from = self.pageAPI else {
            assertionFailure()
            return
        }
        let callRequestService = try? self.resolver.resolve(assert: CallRequestService.self, cache: true)
        callRequestService?.callChatter(chatterId: chatterId, chatId: "", deniedAlertDisplayName: "", from: from, errorBlock: nil, actionBlock: nil)
    }
}
