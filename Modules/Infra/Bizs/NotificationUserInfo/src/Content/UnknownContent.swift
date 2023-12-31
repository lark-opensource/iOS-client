//
//  UnknownContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct UnknowContent: PushContent {
    public init() {}

    public init?(dict: [String: Any]) {}

    public func toDict() -> [String: Any] {
        return [:]
    }
}
