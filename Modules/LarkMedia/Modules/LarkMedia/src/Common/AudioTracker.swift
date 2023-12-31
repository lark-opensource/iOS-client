//
//  AudioTracker.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/2/21.
//

import Foundation

enum AudioTrackKey: String {
    case overrideOutputAudioPortFailed = "override_output_auidio_port_failed"
    case routeChange = "route_change"
    case interruption = "interruption"
    case silenceSecondaryAudio = "silence_secondary_audio"
    case mediaServicesLost = "media_services_lost"
    case mediaServicesReset = "media_services_reset"
    case setActiveFailed = "set_active_failed"
    case setCategoryFailed = "set_category_failed"
    case setModeFailed = "set_mode_failed"
    case audioUnitStartFailed = "audio_unit_start_failed"
    case audioUnitStopFailed = "audio_unit_stop_failed"
    case microphoneMutedFailed = "microphone_muted_failed"
    case microphoneMutedUnexpected = "microphone_muted_unexpected"

    case mediaLockLeak = "media_lock_leak"
    case audioSessionScenarioLeak = "audio_session_scenario_leak"
}

class AudioTracker: NSObject {

    static let shared = AudioTracker()

    let selectors = [
        NSSelectorFromString("trackAudioEventWithEvent:params:"),
        NSSelectorFromString("trackAudioBusinessEventWithEvent:params:"),
    ]

    func trackAudioEvent(key: AudioTrackKey, params: [AnyHashable: Any]) {
        DispatchQueue.global(qos: .default).async {
            for selector in self.selectors {
                if self.responds(to: selector) {
                    self.perform(selector, with: key.rawValue, with: params)
                }
            }
        }
    }
}
