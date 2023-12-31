//
//  MinutesEditDetailReciableTracker.swift
//  Minutes
//
//  Created by lvdaqian on 2021/7/4.
//

import Foundation
import AppReciableSDK

final class MinutesEditDetailReciableTracker: MinutesLatencyDetailReciableTracker {

    static let shared = MinutesEditDetailReciableTracker()

    func startEnterEditMode() {
        MinutesReciableTracker.shared.start(biz: .VideoConference, scene: .MinutesDetail, event: Event.minutes_enter_edit_mode_time, extra: nil)
        reset()
    }

    func endEnterEditMode() {
        finishRender()
        let extra = Extra(isNeedNet: true, latencyDetail: latencyDetail)
        MinutesReciableTracker.shared.end(event: Event.minutes_enter_edit_mode_time, extra: extra)
    }

    func cancelEnterEditMode() {
        MinutesReciableTracker.shared.cancelStart(event: Event.minutes_enter_edit_mode_time)
    }
}
