//
//  CalendarAvatar.swift
//  Calendar
//
//  Created by Rico on 2021/8/16.
//

import UIKit
import Foundation

enum CalendarAvatar {
    /// 主日历，头像固定为个人头像
    case primary(avatarKey: String, identifier: String)
    /// 非主日历，头像为用户设置
    case normal(avatar: UIImage?, key: String = "")
}
