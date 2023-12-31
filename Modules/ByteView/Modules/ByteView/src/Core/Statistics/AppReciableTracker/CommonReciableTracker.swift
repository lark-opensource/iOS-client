//
//  ReciableErrorTracker.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/3/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

struct CommonReciableTracker {
    static func trackRtcError(errorCode: Int) {
        AppreciableTracker.shared.trackError(.vc_perf_rtc_error, params: ["code": errorCode])
    }

    static func trackRtcSubTimeout(streamID: String = "", joinID: String = "", streamType: String = "") {
        AppreciableTracker.shared.trackError(.vc_perf_rtc_sub_timeout, params: ["stream_id": streamID,
                                                                                "join_id": joinID,
                                                                                "stream_type": streamType])
    }

    static func trackThirdHttpError(thirdType: String, errorUrl: String, errorMsg: String, code: Int) {
        AppreciableTracker.shared.trackError(.vc_perf_third_http_error, params: ["third_type": thirdType,
                                                                                 "error_url": errorUrl,
                                                                                 "error_msg": errorMsg,
                                                                                 "code": code])
    }

    static func trackPowerConsume(startLevel: Float, endLevel: Float, duration: Int) {
        // 连续超过10分钟的统计才上报
        guard startLevel >= endLevel, duration >= 10 * 60 else {
            return
        }
        AppreciableTracker.shared.trackAB(.vc_perf_power_consume, params: ["start_level": startLevel,
                                                                           "end_level": endLevel,
                                                                           "duration": duration])
    }

    static func trackRealtimePower(level: Float, isPlugging: Bool) {
        AppreciableTracker.shared.trackAB(.vc_perf_power_realtime, params: ["power_level": level, "is_plugging": isPlugging])
    }

    static func trackThermalState(_ state: ProcessInfo.ThermalState) {
        AppreciableTracker.shared.trackAB(.vc_perf_thermal_state, params: ["thermal_state": state.rawValue])
    }

    static func trackUltrawaveRecognize(success: Bool, duration: Double) {
        AppreciableTracker.shared.track(.vc_ultrawave_recognize, params: ["success": success, "duration": duration])
    }


    static func trackMetricMeeting(event: AppreciableEvent, appMemory: Int64, systemMemory: Int64, availableMemory: Int64) {
        AppreciableTracker.shared.trackAB(event, params: ["app_memory": appMemory, "system_memory": systemMemory, "available_memory": availableMemory])
    }

    static func trackMagicShareDidNewPageShow(pageNum: Int, type: String) {
        let usage = ByteViewMemoryUsage.getCurrentMemoryUsage()
        AppreciableTracker.shared.track(.vc_magic_share_pagenum_mem_dev,
                                        params: ["app_mem": usage.appUsageBytes,
                                                 "sys_mem": usage.systemUsageBytes,
                                                 "available_mem": usage.availableUsageBytes,
                                                 "page_num": pageNum,
                                                 "file_type": type])
    }

    static func trackMemoryPressure(pressureType: Int32, inBackground: Int) {
        AppreciableTracker.shared.track(.vc_perf_memory_pressure,
                                        params: ["pressure_type": pressureType, "in_background": inBackground],
                                        platforms: [.slardar, .tea])
    }
}
