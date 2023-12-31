//
//  MinutesDetailReciableTracker.swift
//  ByteView
//
//  Created by panzaofeng on 2021/4/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppReciableSDK

final class MinutesDetailReciableTracker: MinutesLatencyDetailReciableTracker {

    lazy var slardarTracker: SlardarTracker = {
        let tracker = SlardarTracker()
        return tracker
    }()
    
    static let shared = MinutesDetailReciableTracker()

    func startEnterDetail() {
        MinutesReciableTracker.shared.start(biz: .VideoConference, scene: .MinutesDetail, event: Event.minutes_enter_detail_time, extra: nil)
        reset()
    }

    func endEnterDetail() {
        finishRender()
        let extra = Extra(isNeedNet: true, latencyDetail: latencyDetail)
        MinutesReciableTracker.shared.end(event: Event.minutes_enter_detail_time, extra: extra)
        let category = ["type" : "detail"]
        slardarTracker.tracker(service: "meeting_minutes_monitor", metric: latencyDetail, category: category)
    }

    func cancelEnterDetail() {
        MinutesReciableTracker.shared.cancelStart(event: Event.minutes_enter_detail_time)
    }
}
