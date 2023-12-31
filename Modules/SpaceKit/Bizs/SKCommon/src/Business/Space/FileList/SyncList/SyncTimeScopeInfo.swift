//
//  SyncTimeScopeInfo.swift
//  SKCommon
//
//  Created by guoqp on 2020/7/1.
//

import Foundation

public struct SyncTimeScopeInfo: Equatable {
    public var requestStarTime = Date.distantPast.timeIntervalSince1970
    public var requestEndTime = Date.distantFuture.timeIntervalSince1970
    public var fromNet = false
    public var hasMore = false
    public var responseItemsStartTime: TimeInterval!
    public var responseItemsEndTime: TimeInterval!
    public var isEmpty: Bool {
        return responseItemsStartTime == Date.distantPast.timeIntervalSince1970 && responseItemsEndTime == Date.distantFuture.timeIntervalSince1970
    }

    public init() {

    }

    public static func == (lhs: SyncTimeScopeInfo, rhs: SyncTimeScopeInfo) -> Bool {
        return lhs.requestStarTime == rhs.requestStarTime &&
            lhs.requestEndTime == rhs.requestEndTime &&
            lhs.fromNet == rhs.fromNet &&
            lhs.hasMore == rhs.hasMore &&
            lhs.responseItemsStartTime == rhs.responseItemsStartTime &&
            lhs.responseItemsEndTime == rhs.responseItemsEndTime
    }

//    public mutating func initReponseTime() {
//        fromNet = true
//        let isRequestStartDistant = requestStarTime == Date.distantPast.timeIntervalSince1970
//        let isRequestEndDistant = requestEndTime == Date.distantFuture.timeIntervalSince1970
//        switch (isRequestStartDistant, isRequestEndDistant) {
//        case (true, true):
//            responseItemsStartTime = requestStarTime
//            responseItemsEndTime = requestEndTime
//        case (true, false):
//            responseItemsStartTime = requestEndTime
//            responseItemsEndTime = requestEndTime
//        case (false, true):
//            responseItemsStartTime = requestStarTime
//            responseItemsEndTime = requestStarTime
//        case (false, false):
//            responseItemsStartTime = requestStarTime
//            responseItemsEndTime = requestEndTime
//        }
//    }

    /// 已经和后台同步好的时间范围
    public var resultRange: ClosedRange<TimeInterval> {
        let maxEndTime = (requestEndTime == Date.distantFuture.timeIntervalSince1970) ? responseItemsEndTime : requestEndTime
        let minStartTime = (requestStarTime == Date.distantPast.timeIntervalSince1970) ? responseItemsStartTime : requestStarTime

        if hasMore {
            return responseItemsStartTime...maxEndTime!
        } else {
            return minStartTime!...maxEndTime!
        }
    }

    public var isSyncBottom: Bool {
        return requestStarTime == Date.distantPast.timeIntervalSince1970 && fromNet
    }
}
