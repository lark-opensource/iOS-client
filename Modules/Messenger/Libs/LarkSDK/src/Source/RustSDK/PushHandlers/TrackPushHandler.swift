//
//  TrackPushHandler.swift
//  Lark
//
//  Created by 李凌峰 on 2018/12/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsTracker

typealias Track = RustPB.Statistics_V1_Track

final class TrackPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    func process(push message: Track) {
        let event = message.key

        switch message.type {
        case .tea:
            var teaParam: Track.TeaParam?
            if let params = message.params,
                case let .teaParam(theParam) = params {
                teaParam = theParam
            }
            let params = teaParam?.params.dictValue ?? [:]
            Tracker.post(TeaEvent(event, params: params))
        case .slardar:
            var slardarParam: Track.SlardarParam?
            if let params = message.params,
                case let .slardarParam(theParam) = params {
                slardarParam = theParam
            }

            let status = (slardarParam?.status).map { Int($0) } ?? 0
            var category = slardarParam?.category.dictValue ?? [:]
            category["status"] = status // 手动塞入category
            let metrics = slardarParam?.metric.dictValue ?? [:]
            Tracker.post(
                SlardarEvent(
                    name: event,
                    metric: metrics,
                    category: category,
                    extra: [:]
                )
            )
        @unknown default:
            assert(false, "new value")
            break
        }

    }
}

private extension Track.TrackParams {

    var dictValue: [String: Any] {
        var dict: [String: Any] = [:]
        dict.merge(intParam) { (_, new) in new }
        dict.merge(stringParam) { (_, new) in new }
        return dict
    }

}
