//
//  ShareContentAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/23.
//

import LarkMessengerInterface

final class ShareContentAlertConfig: ForwardAlertConfig {
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareContentAlertContent != nil {
            return true
        }
        return false
    }
}
