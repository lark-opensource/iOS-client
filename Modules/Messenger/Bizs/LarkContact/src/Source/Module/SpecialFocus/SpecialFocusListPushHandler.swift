//
//  SpecialFocusListPushHandler.swift
//  LarkContact
//
//  Created by panbinghua on 2021/11/3.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer
import LarkModel

final class PushFocusChatterHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Contact_V1_PushFocusChatter) throws {
        let deleteChatterIds = message.deleteChatterIds.map { String($0) }
        let addChatters = message.addChatters.map { Chatter.transform(pb: $0) }
        let msg = PushFocusChatterMessage(deleteChatterIds: deleteChatterIds, addChatters: addChatters)
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(msg)
    }
}
