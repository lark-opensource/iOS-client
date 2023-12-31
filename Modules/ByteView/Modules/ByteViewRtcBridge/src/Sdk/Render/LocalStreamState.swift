//
//  LocalStreamState.swift
//  ByteView
//
//  Created by liujianlong on 2021/3/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import VolcEngineRTC
import ByteViewCommon
import ByteViewRTCRenderer

final class LocalStreamState {
    private var renderer: MultiTargetRenderer?
    private var isCapturing: Bool = false
    @RwAtomic var renderConfig: RtcRenderConfig = .default {
        didSet {
            self.renderActor.proxy = renderConfig.proxy
        }
    }

    private var deviceDegree: Int = 0
    private var statusBarDegree: Int = 0
    private let listeners: VideoStreamListeners
    private let queue: DispatchQueue
    private let renderActor = LocalMultiTargetActor(proxy: DefaultRtcActionProxy())
    init(queue: DispatchQueue, listeners: VideoStreamListeners) {
        self.queue = queue
        self.listeners = listeners
    }

    func subscribe(renderer: StreamRenderProtocol) {
        if let mtRenderer = self.renderer {
            mtRenderer.addChild(renderer: renderer)
            return
        }
        let mtRenderer = MultiTargetRenderer(key: .local, queue: self.queue, actor: self.renderActor,
                                             subscribeConfig: renderer.subscribeConfig, listeners: listeners)
        mtRenderer.delegate = self
        mtRenderer.addChild(renderer: renderer)

        Logger.streamManager.info("handleSetLocalRenderer(\(renderer))")
        assert(self.renderer == nil)
        self.renderer = mtRenderer
        if !self.isCapturing {
            return
        }

        mtRenderer.onRenderResumed()
        VideoStreamRtcExecutor.setLocalRenderer(renderer: mtRenderer)
    }

    func unsubscribe(renderer: StreamRenderProtocol) {
        Logger.streamManager.info("handleRemoveLocalRenderer(\(renderer)")
        guard let mtRenderer = self.renderer else {
            return
        }
        let action = mtRenderer.removeChild(renderer: renderer)
        switch action {
        case .delayRemove:
            self.renderer = nil
            if self.isCapturing {
                VideoStreamRtcExecutor.unsetLocalRenderer()
                renderer.onRenderPaused()
            }
        case .skip:
            break
        }
    }

    func startCapture() {
        Logger.streamManager.info("handleStartCapture, isCapturing = \(isCapturing), hasRenderer = \(self.renderer != nil)")
        guard !self.isCapturing else {
            return
        }
        self.isCapturing = true
        guard let renderer = self.renderer else {
            return
        }
        renderer.onRenderResumed()
        VideoStreamRtcExecutor.setLocalRenderer(renderer: renderer)
    }

    func stopCapture() {
        Logger.streamManager.info("handleStopCapture, isCapturing = \(isCapturing)")
        guard self.isCapturing else {
            return
        }
        self.isCapturing = false
        self.renderer?.onRenderPaused()
    }

    func setSubscribeConfig(_ config: VideoSubscribeConfig, renderer: AnyObject) {
        self.renderer?.setSubscribeConfig(config, renderer: renderer)
    }

    func checkStatus() -> StreamStatus {
        let hasRenderer = self.renderer != nil
        let isCapturing = self.isCapturing
        Logger.streamManager.info("localStreamState, hasRenderer: \(hasRenderer), isCapturing: \(isCapturing)")
        return StreamStatus(streamKey: .local, streamID: nil, hasRenderer: hasRenderer, streamAdded: true, muted: !isCapturing, lastSDKCall: nil)
    }

    func destroy() {
        stopCapture()
        self.renderConfig = .default
    }
}

extension LocalStreamState: MultiTargetRendererDelegate {
    func didChangeSubscribeConfig(renderer: MultiTargetRenderer, config: VideoSubscribeConfig) {
        VideoStreamRtcExecutor.updateLocalVideoRes(config.res)
    }
}

private extension VideoStreamRtcExecutor {
    static func setLocalRenderer(renderer: ByteRTCVideoSinkProtocol) {
        Logger.streamManager.info("setRtcLocalRenderer(\(renderer))")
        executeInCurrentContext { [weak renderer] rtc in
            if let renderer = renderer {
                rtc.setLocalVideoSink(.main, withSink: renderer, with: .NV12)
            }
        }
    }

    static func unsetLocalRenderer() {
        Logger.streamManager.info("unsetRtcLocalRenderer")
        executeInCurrentContext { rtc in
            rtc.setLocalVideoSink(.main, withSink: nil, with: .NV12)
        }
    }

    static func updateLocalVideoRes(_ res: Int) {
        executeInCurrentContext { rtc in
            rtc.updateLocalVideoRes(res)
        }
    }
}
