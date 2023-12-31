//
//  CollectionInfo.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/6/3.
//

import Foundation
import ServerPB

/// Videoconference_V1_CollectionInfo
public struct CollectionInfo: Equatable {
    public init(collectionID: String, collectionTitle: String, totalCount: Int,
                collectionType: CollectionType, items: [TabListItem], calendarEventRrule: String) {
        self.collectionID = collectionID
        self.collectionTitle = collectionTitle
        self.totalCount = totalCount
        self.collectionType = collectionType
        self.items = items
        self.calendarEventRrule = calendarEventRrule
    }

    /// 合集 ID
    public var collectionID: String

    /// 合集名称
    public var collectionTitle: String

    /// 合集包含会议记录数量
    public var totalCount: Int

    /// 合集类型
    public var collectionType: CollectionType

    /// 合集包含的会议
    public var items: [TabListItem]

    /// 日程会议循环相关信息，如果为重复日程合集则展示
    public var calendarEventRrule: String

    public enum CollectionType: Int, Hashable {
        case unknown    // 0
        /// 日程合集
        case calendar   // 1
        /// 智能合集
        case ai         // 2
    }
}

extension CollectionInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "CollectionInfo",
            "collectionID: \(collectionID)",
            "totalCount: \(totalCount)",
            "collectionType: \(collectionType)",
            "items: \(items)",
            "calendarEventRrule: \(calendarEventRrule)"
        )
    }
}
