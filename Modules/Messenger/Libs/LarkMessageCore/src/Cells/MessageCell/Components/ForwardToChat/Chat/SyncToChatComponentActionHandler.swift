//
//  File.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/16.
//

import UIKit
import Foundation
import LarkCore
import LarkUIKit
import LarkModel
import LarkMessageBase
import LKCommonsLogging
import LarkSetting
import LarkMessengerInterface

public class SyncToChatComponentActionHandler<Context: ReplyViewModelContext>: ComponentActionHandler<Context>, CellTopReplyInlinePreviewTappable {
    public func replyViewTapped(replyMessage rootMessage: Message?, chat: Chat) {
        guard let message = rootMessage else {
            return
        }
        let body = ReplyInThreadByModelBody(message: message,
                                            chat: chat)
        context.navigator(type: .push, body: body, params: nil)
    }
}

final class MergeForwardDetailSyncToChatComponentActionHandler<Context: ReplyViewModelContext>: SyncToChatComponentActionHandler<Context> {
    override func replyViewTapped(replyMessage rootMessage: Message?, chat: Chat) {
    }
}
