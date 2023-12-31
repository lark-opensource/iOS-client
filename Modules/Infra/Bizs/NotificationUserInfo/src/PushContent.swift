//
//  PushContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public protocol PushContent: JSONCodable {
    var url: String { get set }
}

public extension PushContent {
    public var url: String {
        get {
            return ""
        }
        set{
        
        }
    }
}

public enum PushType: Int {
    // 0
    case unknow = 0
    // 1, 2, 3, 4
    case message
    case badge
    case reaction
    case active
    case chatApply
    // 101, 102, 103, 104
    case call = 101
    case video
    case calendar
    case docs
    case mail
    case todo
    // 201, 202
    case urgent = 201
    case urgentAck
    // 301
    case chatApplication = 301
    // 401, 402
    case openApp = 401
    case openAppChat
    case openMicroApp
}

public enum PushAction: Int {
    // 立即覆盖
    case noticeImmediatly = 0

    // 删除后再发送通知, Notification Service Extension中为了确保remove成功，会有一定时间的延时
    case removeThenNotice = 1
}
