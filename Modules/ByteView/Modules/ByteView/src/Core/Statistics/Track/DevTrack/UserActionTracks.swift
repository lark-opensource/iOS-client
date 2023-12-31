//
//  UserActionTracks.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/3/1.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewCommon

final class UserActionTracks {
    private init() {
        // Cannot initialize this class
    }

    enum FromSource: String {
        case grid
        case participant_cell
    }

    enum Subcategory: String {
        // 更改自己的设备状态
        case change_self
        // 更改他人的设备状态
        case change_others
    }

    // MARK: - Microphone Actions

    static func trackChangeMicAction(isOn: Bool, source: MicrophoneActionSource, requestID: String?, result: MicrophoneActionResult) {
        var params: TrackParams = [
            .is_on: isOn,
            .from_source: source.rawValue,
            "result": result.rawValue
        ]
        if let requestID = requestID {
            params.updateParams(["request_id": requestID])
        }
        DevTracker.post(.userAction(.change_inmeeting_microphone)
                            .category(.microphone_operation)
                            .subcategory(rawValue: Subcategory.change_self.rawValue)
                            .params(params))
    }

    static func trackMicrophonePush(isOn: Bool) {
        DevTracker.post(.userAction(.microphone_push)
                            .category(.microphone_operation)
                            .subcategory(rawValue: Subcategory.change_self.rawValue)
                            .params([
                                .is_on: isOn
                            ]))
    }

    // 记录失败事件时，requestID 是必传参数
    static func trackUnmuteMicRequestFailure(requestID: String?, error: Error) {
        DevTracker.post(.userAction(.change_microphone_failed)
                            .category(.microphone_operation)
                            .subcategory(rawValue: Subcategory.change_self.rawValue)
                            .params([
                                .request_id: requestID ?? "",
                                .error_code: error.toErrorCode(),
                                .error_msg: error.localizedDescription
                            ]))
    }

    static func trackRequestMicAction(isOn: Bool, targetUserID: String, isHandsUp: Bool, fromSource: FromSource) {
        DevTracker.post(.userAction(.request_mic_mute)
                            .category(.microphone_operation)
                            .subcategory(rawValue: Subcategory.change_others.rawValue)
                            .params([
                                .is_on: isOn,
                                "target_user_id": targetUserID,
                                "is_hands_up": isHandsUp,
                                .from_source: fromSource
                            ]))
    }

    static func trackRequestAllMicAction(isOn: Bool) {
        DevTracker.post(.userAction(.request_mic_mute_all)
                            .category(.microphone_operation)
                            .subcategory(rawValue: Subcategory.change_others.rawValue)
                            .params([
                                .is_on: isOn
                            ]))
    }

    static func trackHandsDownMicAction() {
        DevTracker.post(.userAction(.mic_hands_down)
                            .category(.microphone_operation)
                            .subcategory(rawValue: Subcategory.change_self.rawValue))
    }

    // MARK: - Camera Actions

    static func trackChangeCameraAction(isOn: Bool, source: CameraActionSource, requestID: String?, result: CameraActionResult) {
        var params: TrackParams = [
            .is_on: isOn,
            .from_source: source.rawValue,
            "result": result.rawValue
        ]
        if let requestID = requestID {
            params.updateParams(["request_id": requestID])
        }
        DevTracker.post(.userAction(.change_inmeeting_camera)
                            .category(.camera_operation)
                            .subcategory(rawValue: Subcategory.change_self.rawValue)
                            .params(params))
    }

    static func trackCameraPush(isOn: Bool) {
        DevTracker.post(.userAction(.camera_push)
                            .category(.camera_operation)
                            .subcategory(rawValue: Subcategory.change_self.rawValue)
                            .params([
                                .is_on: isOn
                            ]))
    }

    // 记录失败事件时，requestID 是必传参数
    static func trackUnmuteCameraRequestFailure(requestID: String?, error: Error) {
        DevTracker.post(.userAction(.change_camera_failed)
                            .category(.camera_operation)
                            .subcategory(rawValue: Subcategory.change_self.rawValue)
                            .params([
                                .request_id: requestID,
                                .error_code: error.toErrorCode(),
                                .error_msg: error.localizedDescription
                            ]))
    }

    static func trackRequestCameraAction(isOn: Bool, targetUserID: String, fromSource: FromSource) {
        DevTracker.post(.userAction(.request_camera_mute)
                            .category(.camera_operation)
                            .subcategory(rawValue: Subcategory.change_others.rawValue)
                            .params([
                                .is_on: isOn,
                                "target_user_id": targetUserID,
                                .from_source: fromSource
                            ]))
    }
}
