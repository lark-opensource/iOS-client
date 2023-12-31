//
//  DetailInterface.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import EENavigator

/// 查看 Todo 详情

public struct TodoDetailBody: CodablePlainBody {
    public static let pattern = "//client/todo/detail"

    public let guid: String

    public let source: SourceType

    public init(guid: String, source: SourceType) {
        self.guid = guid
        self.source = source
    }

    public enum SourceType: Int, Codable {
        /// 应用内通知卡片
        case appAlert
        case apns
        // 日历视图页场景
        case calendar
    }
}
