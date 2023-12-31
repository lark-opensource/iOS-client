//
//  AladdinTracks.swift
//  ByteView
//
//  Created by liujianlong on 2022/1/17.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

extension Float {
    var roundStr: String {
        // nolint-next-line: magic number
        String(format: "%.4f", roundf(10_000.0 * self) / 10_000)
    }
}

enum AladdinTracks {

    // https://bytedance.feishu.cn/sheets/shtcn7ZGRiHIsJOIJ8bKFeiSmHU
    static func trackThreadUsages(appCPU: Float,
                                  rtcCPU: Float?,
                                  threadUsages: [ByteViewThreadCPUUsage],
                                  source: String?) -> TrackParams? {
        let usages = threadUsages.map { t -> [String: Any] in
            var obj: [String: Any] = [
                "id": String(t.threadID, radix: 16, uppercase: true),
                "cpu": String(format: "%.3f", t.cpuUsage)
            ]
            if let tn = t.threadName,
               !tn.isEmpty {
                obj["name"] = tn
            }
            if let qn = t.queueName,
               !qn.isEmpty {
                obj["queue_name"] = qn
            }
            if t.bizScope != ByteViewThreadBizScope_Unknown {
                obj["biz"] = t.bizScope.description
            }
            return obj
        }
        if let data = try? JSONSerialization.data(withJSONObject: usages),
           let des = String(data: data, encoding: .utf8) {
            var params: TrackParams = [
                "process_cpu": appCPU,
                "threads": des
            ]
            if let rtcCPU = rtcCPU {
                params["rtc_cpu"] = rtcCPU
            }
            VCTracker.post(name: .vc_perf_cpu_state_mobile_dev, params: params)
            if let source {
                params["source"] = source
            }
            return params
        }
        return nil
    }

    static func trackCoreUsages(_ usages: [CPUCoreAggregatedRecord]) -> [AggregateSubEvent] {
        let coreNum = usages.count
        var aggEvents: [AggregateSubEvent] = []
        let time = TrackCommonParams.clientNtpTime
        for (idx, coreUsage) in usages.enumerated() {
            let params: TrackParams = [
                "core_num": coreNum,
                "core_index": idx,
                "is_main": coreUsage.isMain,
                "avg_core_cpu": coreUsage.avg,
                "min_core_cpu": coreUsage.minVal,
                "max_core_cpu": coreUsage.maxVal,
                "pct50_core_cpu": coreUsage.p50,
                "pct75_core_cpu": coreUsage.p75
            ]
            let aggParams: TrackParams = [
                "core_num": coreNum,
                "core_index": idx,
                "is_main": coreUsage.isMain,
                "avg": coreUsage.avg.roundStr,
                "min": coreUsage.minVal.roundStr,
                "max": coreUsage.maxVal.roundStr,
                "pct50": coreUsage.p50.roundStr,
                "pct75": coreUsage.p75.roundStr
            ]
            VCTracker.post(name: .vc_perf_cpu_cores_state_dev, params: params)
            let aggEvent = AggregateSubEvent(name: .vc_perf_cpu_cores_state_dev, params: aggParams, time: time)
            aggEvents.append(aggEvent)
        }
        return aggEvents
    }

    static func trackPower(_ params: TrackParams) {
        VCTracker.post(name: .vc_power_remain_one_minute_dev, params: params)
    }

    static func trackThermalState(_ state: ProcessInfo.ThermalState) {
        VCTracker.post(name: .vc_ios_temperature_change_dev, params: [ "thermal_state": state.rawValue])
    }

    static func trackNetwork(_ network: NetworkConnectionType) {
        VCTracker.post(name: .vc_network_change_dev, params: [.network_type: network.description])
    }

    static func trackSnapshotDiagnosticLog(_ log: String) {
        VCTracker.post(name: .vc_snapshot_report_dev, params: ["log": log])
    }

    static func trackJoinCamMic(isFront: Bool, micName: String) {
        VCTracker.post(name: .vc_cam_mic_selected_dev, params: [
            "cam_name": isFront ? "front_camera" : "back_camera",
            "mic_name": micName,
            "is_joinroom": 1
        ])
    }

    static func trackCamSelected(isFront: Bool) {
        VCTracker.post(name: .vc_cam_mic_selected_dev, params: [
            "cam_name": isFront ? "front_camera" : "back_camera",
            "is_joinroom": 0
        ])
    }

    static func trackMicSelected(micName: String) {
        VCTracker.post(name: .vc_cam_mic_selected_dev, params: [
            "mic_name": micName,
            "is_joinroom": 0
        ])
    }

    static func trackOnthecallCPU(appCPUAvg: Float, appCPUMax: Float) {
        VCTracker.post(name: .vc_perf_cpu_onthecall_dev, params: [
            "avg_app_cpu": appCPUAvg,
            "max_app_cpu": appCPUMax
        ])
    }

}
