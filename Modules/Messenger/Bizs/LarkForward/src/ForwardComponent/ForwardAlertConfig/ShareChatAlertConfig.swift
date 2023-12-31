//
//  ShareChatAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/23.
//

import LarkMessengerInterface

final class ShareChatAlertConfig: ForwardAlertConfig {
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareChatAlertContent != nil {
            return true
        }
        return false
    }
}
