//
//  OpenMicroAppContent.swift
//  NotificationUserInfo
//
//  Created by bytedancer on 2022/6/14.
//

import Foundation
public struct OpenMicroAppContent: PushContent {
    public var url: String

    public init(url: String) {
        self.url = url
    }

    public init(dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        return dict
    }
}
