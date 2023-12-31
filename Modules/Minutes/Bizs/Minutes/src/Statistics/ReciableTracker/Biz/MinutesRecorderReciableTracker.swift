//
//  MinutesRecorderReciableTracker.swift
//  ByteView
//
//  Created by panzaofeng on 2021/4/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppReciableSDK

final class MinutesRecorderReciableTracker: MinutesLatencyDetailReciableTracker {

    public static let shared = MinutesRecorderReciableTracker()

    func startEnterRecorder() {
        MinutesReciableTracker.shared.start(biz: .VideoConference, scene: .MinutesRecorder, event: Event.minutes_enter_recorder_time, extra: nil)
        reset()
    }

    func endEnterRecorder() {
        finishRender()
        let extra = Extra(isNeedNet: true, latencyDetail: latencyDetail)
        MinutesReciableTracker.shared.end(event: Event.minutes_enter_recorder_time, extra: extra)
    }

    func cancelEnterRecorder() {
        MinutesReciableTracker.shared.cancelStart(event: Event.minutes_enter_recorder_time)
    }
}
