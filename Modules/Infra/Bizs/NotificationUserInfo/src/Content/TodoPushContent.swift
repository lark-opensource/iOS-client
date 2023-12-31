//
//  TodoPushContent.swift
//  NotificationUserInfo
//
//  Created by 白言韬 on 2021/1/5.
//

import Foundation

public struct TodoPushContent: PushContent {
    public var url: String
    public var guid: String

    public init(guid: String) {
        self.url = "//client/todo/detail?guid=\(guid)"
        self.guid = guid
    }

    public init?(dict: [String: Any]) {
        guard let url = dict["url"] as? String,
            let guid = dict["GUID"] as? String  else {
            return nil
        }

        self.url = url
        self.guid = guid
    }

    public func toDict() -> [String: Any] {
        let result: [String: Any] = ["url": url,
                                     "GUID": guid]
        return result
    }
}

