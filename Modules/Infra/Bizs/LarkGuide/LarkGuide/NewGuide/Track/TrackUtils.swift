//
//  TrackUtils.swift
//  LarkGuide
//
//  Created by zhenning on 2020/09/01.
//

import UIKit
import Foundation
import LKCommonsTracker
import Homeric
import AppReciableSDK

typealias LarkGuideTrackError = Tracer.TrackError

final class Tracer {

    struct TrackError {
        let errorCode: Int
        let errorMsg: String?
        init(errorCode: Int32? = nil,
             errorMsg: String? = nil) {
            self.errorCode = Int(errorCode ?? 0)
            self.errorMsg = errorMsg
        }
    }

    /// 拉取引导配置
    static func trackGuideFetchInfo(succeed: Bool,
                                    cost: Int64? = nil,
                                    trackError: TrackError? = nil) {
        let cost = Int(cost ?? 0)
        var metric: [String: Any] = [:]
        metric["cost"] = cost

        var category: [String: Any] = ["succeed": succeed]
        var extra: [String: Any] = [:]

        if let trackError = trackError {
            let errorMsg = trackError.errorMsg ?? ""
            let errorCode = trackError.errorCode

            category["error_code"] = errorCode
            extra["error_msg"] = errorMsg

            AppReciableSDK.shared.error(params: ErrorParams(biz: .UserGrowth,
                                                            scene: .UGCenter,
                                                            event: .ug_get_user_guide,
                                                            errorType: .Other,
                                                            errorLevel: .Fatal,
                                                            errorCode: errorCode,
                                                            userAction: "",
                                                            page: nil,
                                                            errorMessage: errorMsg))
        } else {
            AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .UserGrowth,
                                                                  scene: .UGCenter,
                                                                  event: .ug_get_user_guide,
                                                                  cost: cost,
                                                                  page: nil))
        }
        Tracker.post(SlardarEvent(name: Homeric.UG_GET_USER_GUIDE,
                                  metric: metric,
                                  category: category,
                                  extra: extra))
    }

    /// 上报引导key消费
    static func trackGuidePostConsuming(succeed: Bool,
                                        guideKeys: [String],
                                        cost: Int64? = nil,
                                        trackError: TrackError? = nil) {
        let cost = Int(cost ?? 0)
        var metric: [String: Any] = [:]
        metric["cost"] = cost

        var category: [String: Any] = ["succeed": succeed]
        category["guide_key"] = guideKeys

        var extra: [String: Any] = [:]

        if let trackError = trackError {
            let errorMsg = trackError.errorMsg ?? ""
            let errorCode = trackError.errorCode

            category["error_code"] = errorCode
            extra["error_msg"] = errorMsg

            AppReciableSDK.shared.error(params: ErrorParams(biz: .UserGrowth,
                                                            scene: .UGCenter,
                                                            event: .ugPostUserConsumingGuide,
                                                            errorType: .Other,
                                                            errorLevel: .Fatal,
                                                            errorCode: errorCode,
                                                            userAction: "",
                                                            page: nil,
                                                            errorMessage: errorMsg))
        } else {
            AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .UserGrowth,
                                                                  scene: .UGCenter,
                                                                  event: .ugPostUserConsumingGuide,
                                                                  cost: cost,
                                                                  page: nil))
        }
        Tracker.post(SlardarEvent(name: Homeric.UG_POST_USER_CONSUMING_GUIDE,
                                  metric: metric,
                                  category: category,
                                  extra: extra))
    }

    /// 对引导加锁
    static func trackGuideTryLock(succeed: Bool,
                                  lockExceptKeys: [String],
                                  trackError: TrackError? = nil) {
        let cost = 0
        let metric: [String: Any] = [:]
        var category: [String: Any] = ["succeed": succeed]
        category["lock_except_keys"] = lockExceptKeys

        var extra: [String: Any] = [:]

        if let trackError = trackError {
            let errorMsg = trackError.errorMsg ?? ""
            let errorCode = trackError.errorCode

            category["error_code"] = errorCode
            extra["error_msg"] = errorMsg

            AppReciableSDK.shared.error(params: ErrorParams(biz: .UserGrowth,
                                                            scene: .UGCenter,
                                                            event: .ugGuideTryLock,
                                                            errorType: .Other,
                                                            errorLevel: .Fatal,
                                                            errorCode: errorCode,
                                                            userAction: "",
                                                            page: nil,
                                                            errorMessage: errorMsg))
        } else {
            AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .UserGrowth,
                                                                  scene: .UGCenter,
                                                                  event: .ugGuideTryLock,
                                                                  cost: cost,
                                                                  page: nil))
        }
        Tracker.post(SlardarEvent(name: Homeric.UG_GUIDE_TRY_LOCK,
                                  metric: metric,
                                  category: category,
                                  extra: extra))
    }
}

/// Utils
extension Tracer {
    static func calculateCostTime(startTime: CFTimeInterval) -> Int64 {
        return Int64((CACurrentMediaTime() - startTime) * 1000)
    }
}
