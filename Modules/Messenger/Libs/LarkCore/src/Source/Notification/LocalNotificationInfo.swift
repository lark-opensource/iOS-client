//
//  LocalNotificationInfo.swift
//  Lark
//
//  Created by zc09v on 2017/10/19.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum NotificationUserInfoType: String {
    //跳转会话相关信息
    case forChat
    //好友申请相关信息
    case forApplication

    /// 日历跳转相关信息
    case forCalendar

    public static var key: String {
        return "userInfoType"
    }
}

protocol NotificationUserInfo {
    var userInfoType: NotificationUserInfoType { get }

    func toDict() -> [String: Any]?
}
