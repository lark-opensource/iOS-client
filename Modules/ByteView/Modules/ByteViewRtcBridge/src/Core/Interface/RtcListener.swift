//
//  RtcListener.swift
//  ByteView
//
//  Created by kiri on 2022/8/9.
//

import Foundation
import ByteViewCommon

final class RtcListeners {
    let listeners = Listeners<RtcListener>()
    let asListeners = Listeners<RtcActiveSpeakerListener>()
    let metadataListeners = Listeners<RtcMetadataListener>()
    let rtmListeners = Listeners<RtmListener>()
    let roomMessageListeners = Listeners<RtcRoomMessageListener>()
}

public protocol RtcListener: AnyObject {
    /// 调用subscribeStream后回调
    func didSubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig)
    func didUnsubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig?)

    func onJoinChannelSuccess()
    func onRejoinChannelSuccess()
    func onUserJoined(uid: RtcUID)

    func onRtcError(_ error: RtcError)

    func onFirstRemoteAudioFrame(uid: RtcUID)

    func onMediaDeviceWarning(warnCode: RtcMediaDeviceWarnCode)

    func onFirstLocalVideoFrameCaptured(streamIndex: RtcStreamIndex)
    func onFirstRemoteVideoFrameDecoded(streamKey: RtcRemoteStreamKey)

    func reportSysStats(_ stats: RtcSysStats)
    func onRoomStats(_ roomStats: RtcRoomStats)

    func onConnectionStateChanged(state: RtcConnectionState)
    func onNetworkTypeChanged(type: RtcNetworkType)
    func onNetworkQuality(localQuality: RtcNetworkQualityInfo, remoteQualities: [RtcNetworkQualityInfo])
    func onNetworkBandwidthEstimation(_ estimation: RtcNetworkBandwidthEstimation)

    func onConnectionTypeUpdated(isP2P: Bool)
}

public protocol RtcActiveSpeakerListener: AnyObject {
    func didReceiveRtcVolumeInfos(_ infos: [RtcAudioVolumeInfo])
}

public protocol RtcMetadataListener: AnyObject {
    /// 标注新旧方案，每帧都会给
    func didReceiveScreenMetadata(_ data: Data, uid: RtcUID)
}

public protocol RtcVideoRendererListener: AnyObject {
    func didRenderVideoFrame(key: RtcStreamKey)
    func onSubscribeFirstTimeout(key: RtcStreamKey, streamId: String)
}

public protocol RtcRoomMessageListener: AnyObject {
    func didReceiveRoomBinaryMessage(_ message: Data)
}

public protocol RtcCameraListener: AnyObject {
    func didFailedToStartVideoCapture(scene: RtcCameraScene, error: Error)
    func didSwitchFrontCamera(_ isFront: Bool)
    func didChangeEffectStatus(_ status: RtcCameraEffectStatus, oldStatus: RtcCameraEffectStatus)
    func cameraWillBeInterrupted(reason: RtcCameraInterruptionReason)
    func cameraWasInterrupted(reason: RtcCameraInterruptionReason)
    func cameraInterruptionWillEnd(oldIsInterrupted: Bool)
    func cameraInterruptionEnded()
}

public extension RtcListener {
    func didSubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig) {}
    func didUnsubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig?) {}

    func onJoinChannelSuccess() {}
    func onRejoinChannelSuccess() {}
    func onUserJoined(uid: RtcUID) {}
    func onRtcError(_ error: RtcError) {}

    func onFirstRemoteAudioFrame(uid: RtcUID) {}

    func onMediaDeviceWarning(warnCode: RtcMediaDeviceWarnCode) {}

    func onFirstLocalVideoFrameCaptured(streamIndex: RtcStreamIndex) {}
    func onFirstRemoteVideoFrameDecoded(streamKey: RtcRemoteStreamKey) {}

    func reportSysStats(_ stats: RtcSysStats) {}
    func onRoomStats(_ roomStats: RtcRoomStats) {}

    func onConnectionStateChanged(state: RtcConnectionState) {}
    func onNetworkTypeChanged(type: RtcNetworkType) {}
    func onNetworkQuality(localQuality: RtcNetworkQualityInfo, remoteQualities: [RtcNetworkQualityInfo]) {}
    func onNetworkBandwidthEstimation(_ estimation: RtcNetworkBandwidthEstimation) {}

    func onConnectionTypeUpdated(isP2P: Bool) {}
}

public extension RtcCameraListener {
    func didFailedToStartVideoCapture(scene: RtcCameraScene, error: Error) {}
    func didSwitchFrontCamera(_ isFront: Bool) {}
    func didChangeEffectStatus(_ status: RtcCameraEffectStatus, oldStatus: RtcCameraEffectStatus) {}
    func cameraWillBeInterrupted(reason: RtcCameraInterruptionReason) {}
    func cameraWasInterrupted(reason: RtcCameraInterruptionReason) {}
    func cameraInterruptionWillEnd(oldIsInterrupted: Bool) {}
    func cameraInterruptionEnded() {}
}

public extension RtcVideoRendererListener {
    func didRenderVideoFrame(key: RtcStreamKey) {}
    func onSubscribeFirstTimeout(key: RtcStreamKey, streamId: String) {}
}
