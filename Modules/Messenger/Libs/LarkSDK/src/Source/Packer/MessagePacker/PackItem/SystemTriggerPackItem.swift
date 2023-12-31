//
//  SystemTriggerPackItem.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel

final class SystemTriggerPackItem: PackItem<Message> {
    let packerTypeSet: [SystemContent.SystemType] = [
        .userCheckOthersTelephone,
        .addEmailMembers,
        .removeEmailMembers,
        .modifyEmailMembers,
        .userModifyEmailSubject,
        .userCallE2EeVoiceOnCancell,
        .userCallE2EeVoiceOnMissing,
        .userCallE2EeVoiceDuration,
        .userCallE2EeVoiceWhenRefused,
        .userCallE2EeVoiceWhenOccupy,
        .vcCallHostCancel,
        .vcCallPartiNoAnswer,
        .vcCallPartiCancel,
        .vcCallHostBusy,
        .vcCallPartiBusy,
        .vcCallFinishNotice,
        .vcCallDuration,
        .vcCallConnectFail,
        .vcCallDisconnect
    ]

    override func collect(model: Message) -> CollectItem {
        if let content = model.content as? SystemContent,
            content.triggerUser == nil,
            let triggerId = content.triggerId,
            self.packerTypeSet.contains(content.systemType) {
            let chatId = model.channel.type == .chat ? model.channel.id : ""
            return CollectItem(data: [.chatChatter: [triggerId]], extraInfo: [.chatId: chatId])
        }
        return .default
    }

    override func pack(model: Message, data: PackData) -> Message {
        let chatters: [String: Chatter] = data.getData(for: .chatChatter)
        if var content = model.content as? SystemContent,
            let triggerId = content.triggerId,
            let chatter = chatters[triggerId] {
            content.triggerUser = chatter
            model.content = content
        }
        return model
    }
}
