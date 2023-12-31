//
//  AvatarSeed.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/12.
//

import Foundation

enum AvatarSeed {
    case lark(identifier: String, avatarKey: String)// 服务端图片。identifier 用来同步不同实体 avatar 的变更。avatarKey 映射 avatarURL
    case local(title: String) // 本地生成图片。取前两个字符生成图片
}

// 支持 avatarSeed 转换的数据在此扩展
extension AvatarSeed {
    static func seed(with calendarMember: Rust.CalendarMember) -> AvatarSeed {
        let identifier: String
        if calendarMember.memberType == .group {
            identifier = calendarMember.chatID
        } else {
            identifier = calendarMember.userID
        }
        return .lark(identifier: identifier, avatarKey: calendarMember.avatarKey)
    }
}
