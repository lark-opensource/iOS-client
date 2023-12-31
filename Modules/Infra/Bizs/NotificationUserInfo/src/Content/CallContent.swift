//
//  CallContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct CallContent: PushContent {
    public var url: String
    public var extraStr: String

    public init(url: String, extraStr: String) {
        self.url = url
        self.extraStr = extraStr
    }

    public init?(dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
        self.extraStr = dict["extraStr"] as? String ?? ""
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        dict["extraStr"] = self.extraStr
        return dict
    }
}
