//
//  SLATracks.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/4/19.
//

import Foundation
import ByteViewTracker
import ByteViewCommon
import ByteViewSetting

final class SLATracks {

    let timeoutDuration: Int

    var previewTimestamp: CFTimeInterval?
    var onthecallTimestamp: CFTimeInterval?
    var rtcTimestamp: CFTimeInterval?

    var previewWorkItem: DispatchWorkItem?
    var onthecallWorkItem: DispatchWorkItem?
    var rtcWorkItem: DispatchWorkItem?

    init(_ config: SLATimeoutConfig) {
        self.timeoutDuration = config.duration
    }

    func startEnterPreview() {
        Queue.tracker.async {
            self.previewTimestamp = CACurrentMediaTime()
            self.previewWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.endEnterPreview(success: false)
            }
            self.previewWorkItem = workItem
            Queue.tracker.asyncAfter(deadline: .now() + .milliseconds(self.timeoutDuration), execute: workItem)
        }
    }

    func endEnterPreview(success: Bool) {
        Queue.tracker.async {
            guard let start = self.previewTimestamp else { return }
            self.previewWorkItem?.cancel()
            let now = CACurrentMediaTime()
            let duration = Int((now - start) * 1000)
            let status = success ? "success" : "fail"
            let reason = duration >= self.timeoutDuration ? "local_timeout" : ""
            VCTracker.post(name: .vc_sla_client_preview_status, params: ["status": status, "cost_time": duration, "failed_reason": reason])
            self.previewTimestamp = nil
        }
    }

    func startEnterOnthecall() {
        Queue.tracker.async {
            self.onthecallTimestamp = CACurrentMediaTime()
            self.onthecallWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.endEnterOnthecall(success: false)
            }
            self.onthecallWorkItem = workItem
            Queue.tracker.asyncAfter(deadline: .now() + .milliseconds(self.timeoutDuration), execute: workItem)
        }
    }

    func endEnterOnthecall(success: Bool) {
        Queue.tracker.async {
            guard let start = self.onthecallTimestamp else { return }
            self.onthecallWorkItem?.cancel()
            let now = CACurrentMediaTime()
            let duration = Int((now - start) * 1000)
            let status = success ? "success" : "fail"
            let reason = duration >= self.timeoutDuration ? "local_timeout" : ""
            VCTracker.post(name: .vc_sla_client_join_status, params: ["status": status, "cost_time": duration, "failed_reason": reason])
            self.onthecallTimestamp = nil
        }
    }

    func resetOnthecall() {
        Queue.tracker.async {
            self.onthecallWorkItem?.cancel()
            self.onthecallTimestamp = nil
        }
    }

    func startJoinChannel() {
        Queue.tracker.async {
            self.rtcTimestamp = CACurrentMediaTime()
            self.rtcWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.endJoinChannel(success: false)
            }
            self.rtcWorkItem = workItem
            Queue.tracker.asyncAfter(deadline: .now() + .milliseconds(self.timeoutDuration), execute: workItem)
        }
    }

    func endJoinChannel(success: Bool) {
        Queue.tracker.async {
            guard let start = self.rtcTimestamp else { return }
            self.rtcWorkItem?.cancel()
            let now = CACurrentMediaTime()
            let duration = Int((now - start) * 1000)
            let status = success ? "success" : "fail"
            let reason = duration >= self.timeoutDuration ? "local_timeout" : ""
            VCTracker.post(name: .vc_sla_rtc_join_status, params: ["rtc_status": status, "rtc_cost_time": duration, "rtc_failed_reason": reason])
            self.rtcTimestamp = nil
        }
    }

    func isSuccess(error: VCError) -> Bool {
        if error == .unknown || error == .badNetwork || error == .badNetworkV2 || error == .serverInternalError {
            return false
        }
        return true
    }
}
