//
//  RtcWrapper.swift
//  ByteView
//
//  Created by kiri on 2022/8/12.
//

import Foundation
import ByteViewCommon

/// 封装ByteRtcMeetingEngineKit，隐藏VolcEngineRTC
final class MockRtcVideoStream: RtcVideoStream {
    func subscribe(key: RtcStreamKey, renderer: StreamRenderProtocol) {
    }

    func unsubscribe(key: RtcStreamKey, renderer: StreamRenderProtocol, reason: String) {
    }

    func setPriority(_ priority: RtcRemoteUserPriority, for key: RtcStreamKey) {
    }

    func setSubscribeConfig(_ config: VideoSubscribeConfig, for key: RtcStreamKey, renderer: AnyObject) {
    }

    func diagnoseSubscribeTimeout(for key: RtcStreamKey) {
    }
}
