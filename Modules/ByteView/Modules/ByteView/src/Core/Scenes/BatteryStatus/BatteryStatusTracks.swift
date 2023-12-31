//
//  BatteryStatusTracks.swift
//  ByteView
//
//  Created by ZhangJi on 2022/6/6.
//

import ByteViewTracker
import Foundation

final class BatteryStatusTracks {
    static func trackBatteryToastShow(toastType: BatteryToastType) {
        var params: TrackParams = [.content: toastType.trackContent]
        if case .voiceMode(.thermal(let state)) = toastType {
            params[.thermalState] = state.trackContent
        }
        if case .ecoMode(let rate) = toastType {
            params["power_consumption_rate"] = rate
            params["battery_level"] = UIDevice.current.batteryLevel
        }
        VCTracker.post(name: .vc_meeting_popup_view,
                       params: params)
    }

    static func trackBatteryToastClick(toastType: BatteryToastType) {
        var params: TrackParams = [.content: toastType.trackContent]
        if case .voiceMode(let voiceModeReason) = toastType {
            params[.click] = "stop_camera"
            if case .thermal(let state) = voiceModeReason {
                params[.thermalState] = state.trackContent
            }
        }
        VCTracker.post(name: .vc_meeting_popup_click,
                       params: params)
    }
}

extension BatteryToastType {
    var trackContent: String {
        switch self {
        case .voiceMode(let reason):
            switch reason {
            case .performance:
                return "audio_mode_perf"
            case .battery:
                return "audio_mode_battery"
            case .thermal:
                return "audio_mode_temperature"
            }
        case .ecoMode:
            return "eco_mode"
        }
    }
}

extension ProcessInfo.ThermalState {
    var trackContent: String {
        switch self {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        @unknown default:
            return ""
        }
    }
}
