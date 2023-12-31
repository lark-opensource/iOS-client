//
//  MailBaseRustPushHandler.swift
//  LarkMail
//
//  Created by Bytedance on 2022/1/12.
//

import Foundation
import LarkRustClient
import MailSDK
import SwiftProtobuf

protocol AccountBasePushHandler: PushHandlerType {
    func checkAccount(push: PushType) -> Bool
}

extension AccountBasePushHandler {
    func checkAccount<T>(push: PushType) -> Bool where PushType == RustPushPacket<T> {
        if let currentAccount = MailSettingManagerInterface.getCachedCurrentAccount(fetchNet: false),
           !currentAccount.mailAccountID.isEmpty,
           !push.packet.mailAccountID.isEmpty,
            currentAccount.mailAccountID != push.packet.mailAccountID {
            LarkMailApplicationDelegate.logger.error("[UserContainer] [mail_client_push] mail account dont't match, cacheID=\(currentAccount.mailAccountID),pushID=\(push.packet.mailAccountID), cmd=\(push.cmd),contextId=\(push.contextID)")
            return false
        }
        return true
    }
}
