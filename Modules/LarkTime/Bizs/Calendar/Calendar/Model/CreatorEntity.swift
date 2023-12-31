//
//  CreatorEntity.swift
//  Calendar
//
//  Created by harry zou on 2019/4/22.
//

import Foundation
import CalendarFoundation

struct CreatorEntity: Avatar {
    var avatarKey: String
    var userName: String
    var chatId: String
    var identifier: String {
        return chatId
    }
}
