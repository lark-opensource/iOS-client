//
//  ActiveContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2019/1/29.
//

import Foundation

public struct ActiveContent: PushContent {
    public var command: Int

    public init(command: Int) {
        self.command = command
    }

    public init?(dict: [String: Any]) {
        self.command = dict["command"] as? Int ?? -1
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["command"] = self.command
        return dict
    }
}
