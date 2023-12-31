//
//  ChatApplyContent.swift
//  Pods
//
//  Created by 孔凯凯 on 2019/6/26.
//

import Foundation

public struct ChatApplyContent: PushContent {
    public var url: String

    public init(url: String) {
        self.url = url
    }

    public init?(dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        return dict
    }

    public static func getIdentifier(chatID: String) -> String {
        return "ChatApply_\(chatID)"
    }
}
