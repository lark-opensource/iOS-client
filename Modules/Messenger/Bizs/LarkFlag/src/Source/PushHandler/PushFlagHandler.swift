//
//  PushFlagHandler.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/18.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel

public struct PushFlagMessage: PushMessage {
    // 更新的列表
    var updateFlags: [Feed_V1_FlagItem]
    // 删除的列表
    let deleteFlags: [Feed_V1_FlagItem]
    // 标记的feed用到的数据
    var flagFeeds: Feed_V1_FeedFlags
    // 标记的消息用到的数据
    var flagMessages: Feed_V1_MessageFlags
    // 标记消息的来源发生变化：只有消息flag用到，V2添加消息所属的chatter
    var source: Feed_V1_SourceV2

    init(updateFlags: [Feed_V1_FlagItem],
         deleteFlags: [Feed_V1_FlagItem],
         flagFeeds: Feed_V1_FeedFlags,
         flagMessages: Feed_V1_MessageFlags,
         source: Feed_V1_SourceV2) {
        self.updateFlags = updateFlags
        self.deleteFlags = deleteFlags
        self.flagFeeds = flagFeeds
        self.flagMessages = flagMessages
        self.source = source
    }

    var description: String {
        let info = "updateFlags: count \(updateFlags.count), " + "deleteFlags: count \(deleteFlags.count)"
        return info
    }
}

final class PushFlagHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? {
        return try? userResolver.userPushCenter
    }
    func process(push message: Feed_V1_PushFlags) throws {
        guard let pushCenter = self.pushCenter else { return }
        let updateFlags: [Feed_V1_FlagItem] = message.updateFlags
        let deleteFlags: [Feed_V1_FlagItem] = message.deleteFlags
        let flagFeeds: Feed_V1_FeedFlags = message.flagFeeds
        let flagMessages: Feed_V1_MessageFlags = message.flagMessages
        let source: Feed_V1_SourceV2 = message.sourceV2

        let pushFlagMessage = PushFlagMessage(updateFlags: updateFlags,
                                              deleteFlags: deleteFlags,
                                              flagFeeds: flagFeeds,
                                              flagMessages: flagMessages,
                                              source: source)
        pushCenter.post(pushFlagMessage)
    }
}
