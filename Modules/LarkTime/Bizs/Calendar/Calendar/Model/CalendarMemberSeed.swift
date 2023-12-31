//
//  CalendarMemberSeed.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/19.
//

import Foundation

// 日历协作者种子信息
public enum CalendarMemberSeed {
    case user(chatterId: String, avatarKey: String)        // 用户（lark）
    case group(chatId: String, avatarKey: String)          // 普通群组
}

extension Array where Element == CalendarMemberSeed {
    var userIds: [String] {
        var chatterIds: [String] = []
        forEach { seed in
            switch seed {
            case .user(let chatterId, _):
                chatterIds.append(chatterId)
            default:
                break
            }
        }
        return chatterIds
    }

    var groupIds: [String] {
        var chatIds: [String] = []
        forEach { seed in
            switch seed {
            case .group(let chatId, _):
                chatIds.append(chatId)
            default:
                break
            }
        }
        return chatIds
    }

}
