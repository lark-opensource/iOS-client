//
//  StreamRenderTicker.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/30.
//

import Foundation
import ByteViewCommon
import ByteViewRTCRenderer

final class StreamRenderTicker {
    private(set) static var current: ByteViewRenderTicker?

    static func setSharedDisplayLinkConfig(_ cfg: RtcRenderConfig.SharedDisplayLinkConfig?) {
        assert(Thread.isMainThread)
        if let cfg = cfg, cfg.enabled {
            Logger.renderView.info("update renderConfig: \(cfg)")
            cfg.fpsList.withUnsafeBufferPointer { ptr in
                guard let baseAddr = ptr.baseAddress else {
                    return
                }
                if self.current == nil {
                    self.current = ByteViewRenderTicker(fpsList: baseAddr, fpsCount: ptr.count, maxFPS: cfg.maxFps)
                } else {
                    self.current?.updateFPSList(baseAddr, fpsCount: ptr.count, maxFPS: cfg.maxFps)
                }
            }
        } else {
            Logger.renderView.info("update renderConfig: <nil>")
            self.current = nil
        }
    }
}
