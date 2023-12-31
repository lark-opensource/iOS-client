//
//  RtcVideoStream.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/30.
//

import Foundation

protocol RtcVideoStream {
    func subscribe(key: RtcStreamKey, renderer: StreamRenderProtocol)
    func unsubscribe(key: RtcStreamKey,
                     delay: TimeInterval?,
                     renderer: StreamRenderProtocol,
                     reason: String)
    func setPriority(_ priority: RtcRemoteUserPriority, for key: RtcStreamKey)
    func setSubscribeConfig(_ config: VideoSubscribeConfig, for key: RtcStreamKey, renderer: AnyObject)
    func diagnoseSubscribeTimeout(for key: RtcStreamKey)
}
