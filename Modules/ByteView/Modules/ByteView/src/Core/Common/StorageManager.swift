//
//  StorageManager.default
//
//  Created by lutingting on 2022/11/16.
//

import Foundation
import ByteViewCommon

/// StorageManager存储KV值所需的key
/// 用户维度的用UserDim；设备维度的用DeviceDim
enum UserStorageKey: String, LocalStorageKey {
    case presenterAllowFree
    case doubleTapToFree
    case lastlyMeetingId
    case rtcFG
    case adminMediaServer
    case callmeAdmin
    case micCameraSetting
    /// 上次「最新」的浏览位置，指用户最远曾经看到哪一条消息，用来计算未读消息
    case readMessage
    /// 上次的浏览位置，指用户当前的浏览停留在哪一条消息上，用来定位到上次浏览位置
    case scanningMessage
    /// 自最新一条已读消息后(readMessage)，本设备已发送且未读的消息位置
    case sentPositions
    /// 是否收起倒计时面板
    case dbFoldBoard
    case isFlowShrunken
    case lastCalledPhoneNumber
    /// 响铃自定义铃声
    case customizeRingtoneForRing
    /// 会议纪要上线引导
    case notesOnboarding

    case meetingWindow

    case userKilled
    case appLaunch
    case appEnterBackground
    case tapToolbarForBreakoutRoom
    case labRed
    case switchAudioGuide

    /// 上次剩余时间提醒设置的时间（分）
    case dbLastRemind
    /// 上次设置倒计时时间 (分)
    case dbLastSetMinute
    /// 倒计时结束是否有提示音
    case dbEndAudio
    // 音频1v1音频设备
    case voiceAudioDevice
    // 视频1v1音频设备
    case videoAudioDevice

    case shareScene
    case breakoutRoomGuide
    case safeModeRtcCache

    case howlingDate
    case howlingCount
    case lastBatteryToastTime

    // 6.10是否合并过Key
    case bizMigrateV6v10

    case ultrawaveTip

    case myAiOpenGuide

    var domain: LocalStorageDomain {
        switch self {
        case .meetingWindow:
            return .child("ByteViewDebug")
        default:
            return .child("Core")
        }
    }
}

private enum DeviceStorageKey: String, LocalStorageKey {
    case userKilled
    case appLaunch
    case appEnterBackground
    case tapToolbarForBreakoutRoom
    case labRed
    case switchAudioGuide

    /// 上次剩余时间提醒设置的时间（分）
    case dbLastRemind
    /// 上次设置倒计时时间 (分)
    case dbLastSetMinute
    /// 倒计时结束是否有提示音
    case dbEndAudio
    // 音频1v1音频设备
    case voiceAudioDevice
    // 视频1v1音频设备
    case videoAudioDevice

    case shareScene
    case breakoutRoomGuide
    case safeModeRtcCache

    case howlingDate
    case howlingCount
    case lastBatteryToastTime

    var domain: LocalStorageDomain {
        return .child("Core")
    }
}

extension MeetingDependency {
    func migrateStorageToUser() {
        let storage = storage.toStorage(UserStorageKey.self)
        let old = globalStorage.toStorage(DeviceStorageKey.self)
        if storage.bool(forKey: .bizMigrateV6v10) { return }
        storage.set(true, forKey: .bizMigrateV6v10)

        let boolKeys: [DeviceStorageKey] = [
            .userKilled, .appLaunch, .appEnterBackground,
            .tapToolbarForBreakoutRoom, .labRed, .switchAudioGuide
        ]
        let intKeys: [DeviceStorageKey] = [
            .dbLastRemind, .dbLastSetMinute, .dbEndAudio, .voiceAudioDevice, .videoAudioDevice
        ]
        let stringKeys: [DeviceStorageKey] = [
            .shareScene, .breakoutRoomGuide, .safeModeRtcCache
        ]
        boolKeys.forEach {
            if let key = UserStorageKey(rawValue: $0.rawValue), let value = old.value(forKey: $0, type: Bool.self) {
                storage.set(value, forKey: key)
            }
        }
        intKeys.forEach {
            if let key = UserStorageKey(rawValue: $0.rawValue), let value = old.value(forKey: $0, type: Int.self) {
                storage.set(value, forKey: key)
            }
        }
        stringKeys.forEach {
            if let key = UserStorageKey(rawValue: $0.rawValue), let value = old.string(forKey: $0) {
                storage.set(value, forKey: key)
            }
        }
        if let dict: [String: TimeInterval] = old.value(forKey: .howlingDate) {
            storage.setValue(dict, forKey: .howlingDate)
        }
        if let dict: [String: UInt] = old.value(forKey: .howlingCount) {
            storage.setValue(dict, forKey: .howlingCount)
        }
        if let obj: TimeInterval = old.value(forKey: .lastBatteryToastTime) {
            storage.setValue(obj, forKey: .lastBatteryToastTime)
        }
    }
}
