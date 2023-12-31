//
//  FeedListTrace.swift
//  LarkFeedBase
//
//  Created by xiaruzhen on 2023/5/20.
//

import Foundation

public struct FeedListTrace {
    public let traceId: String
    public let dataFrom: FeedDataFrom

    public init(traceId: String, dataFrom: FeedDataFrom) {
        self.traceId = traceId
        self.dataFrom = dataFrom
    }

    public static func genId() -> String {
        return UUID().uuidString
    }

    public static func genDefault() -> FeedListTrace {
        return FeedListTrace(traceId: "", dataFrom: .unknown)
    }

    public var description: String {
        return "traceId: \(traceId), dataFrom: \(dataFrom)"
    }
}

public enum FeedDataFrom: String {
    // 目前仅作为log使用，记录data来源
    case unknown,
         updateCache,
         deleteCache,
         preload,
         refresh,
         loadMore,
         getDiscontinuous,
         push,
         pushUpdate,
         pushRemove,
         pushTempUpdate,
         pushUpdateByTemp,
         pushRemoveByTemp,
         reset,
         getUnread,
         switchGroup,
         badgeStyle,
         threadAvatar,
         viewWillTransitionForPad,
         handleIs24HourTime,
         markForDone,
         selected,
         screenshot
}
