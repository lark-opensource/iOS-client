//
//  RtcInternalListener.swift
//  ByteView
//
//  Created by kiri on 2022/9/29.
//

import Foundation
import ByteViewCommon

final class RtcInternalListeners {
    private init() {}
    static let listeners = Listeners<RtcInternalListener>()
    static let streamStatsListeners = Listeners<RtcStreamStatsListener>()

    static func addListener(_ listener: RtcInternalListener) {
        listeners.addListener(listener)
    }

    static func removeListener(_ listener: RtcInternalListener) {
        listeners.removeListener(listener)
    }

    static func forEach(_ action: (RtcInternalListener) -> Void) {
        listeners.forEach(action)
    }

    static func addStreamStatsListener(_ listener: RtcStreamStatsListener) {
        streamStatsListeners.addListener(listener)
    }

    static func removeStreamStatsListener(_ listener: RtcStreamStatsListener) {
        streamStatsListeners.removeListener(listener)
    }
}

protocol RtcInternalListener {
    func onCreateInstance(_ rtc: RtcInstance)
    func onDestroyInstance(_ rtc: RtcInstance)

    func didStartVideoCapture(_ rtc: RtcInstance)
    func didStopVideoCapture(_ rtc: RtcInstance)

    func onStreamAdd(_ rtc: RtcInstance, streamId: String, key: RtcStreamKey, stream: RtcStreamInfo)
    func onStreamRemove(_ rtc: RtcInstance, streamId: String, key: RtcStreamKey)
    func onUserMuteVideo(_ rtc: RtcInstance, muted: Bool, key: RtcStreamKey)

    func onMediaDeviceStateChanged(_ rtc: RtcInstance, deviceType: RtcMediaDeviceType, deviceId: String,
                                   deviceState: RtcMediaDeviceState, deviceError: RtcMediaDeviceError)

    func onEffectStatusChanged(_ status: RtcCameraEffectStatus, oldValue: RtcCameraEffectStatus)
}

protocol RtcStreamStatsListener: AnyObject {
    func onRemoteStreamStats(_ streamStats: RtcRemoteStreamStats)
    func onLocalStreamStats(_ streamStats: RtcLocalStreamStats)
}

/// Real Time Messaging
protocol RtmListener: AnyObject {
    /// rtm登录回调
    func rtmDidLogin()
    /// rtm登录成功后setServerParams回调
    func rtmDidSetServerParams()
    /// rtm logout回调
    func rtmDidLogout()
    /// rtm发送数据回调
    /// - parameter error: ByteRTCUserMessageSendResult
    func rtmDidSendServerMessage(_ msgId: Int64, error: Int)

    /// 实时消息通信
    func rtmDidReceiveMessage(_ message: Data, from uid: RtcUID)
}

extension RtcInternalListener {
    func onCreateInstance(_ rtc: RtcInstance) {}
    func onDestroyInstance(_ rtc: RtcInstance) {}

    func didStartVideoCapture(_ rtc: RtcInstance) {}
    func didStopVideoCapture(_ rtc: RtcInstance) {}

    func onStreamAdd(_ rtc: RtcInstance, streamId: String, key: RtcStreamKey, stream: RtcStreamInfo) {}
    func onStreamRemove(_ rtc: RtcInstance, streamId: String, key: RtcStreamKey) {}
    func onUserMuteVideo(_ rtc: RtcInstance, muted: Bool, key: RtcStreamKey) {}

    func onMediaDeviceStateChanged(_ rtc: RtcInstance, deviceType: RtcMediaDeviceType, deviceId: String,
                                   deviceState: RtcMediaDeviceState, deviceError: RtcMediaDeviceError) {}

    func onEffectStatusChanged(_ status: RtcCameraEffectStatus, oldValue: RtcCameraEffectStatus) {}
}
