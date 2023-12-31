//
//  UserStreamState.swift
//  ByteView
//
//  Created by liujianlong on 2021/3/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import VolcEngineRTC
import ByteViewCommon

protocol UserStreamStateDelegate: AnyObject {
    func didCleanupUserStreamState(key: RtcStreamKey)
}

final class UserStreamState {
    static let dateFormatter: ISO8601DateFormatter = {
        let ret = ISO8601DateFormatter()
        ret.timeZone = TimeZone.current
        return ret
    }()

    let key: RtcStreamKey
    private let queue: DispatchQueue
    let renderConfig: RtcRenderConfig
    private let listeners: VideoStreamListeners
    private let statsCollector: StreamStatsCollector
    weak var delegate: UserStreamStateDelegate?

    private(set) var streamId: String?
    private(set) var subscribeCount: Int = 0
    private(set) var stream: RtcStreamInfo?
    private(set) var muted: Bool = false
    private var lastSDKSubCall: String?

    private var renderer: MultiTargetRenderer?
    private var subscribeConfig: VideoSubscribeConfig?

    private var shouldSubscribeVideo: Bool {
        stream != nil && !muted && renderer != nil
    }

    init(key: RtcStreamKey, queue: DispatchQueue, listeners: VideoStreamListeners, config: RtcRenderConfig,
         statsCollector: StreamStatsCollector) {
        self.key = key
        self.queue = queue
        self.listeners = listeners
        self.renderConfig = config
        self.statsCollector = statsCollector
        Logger.streamManager.info("init UserStreamState \(key)")
    }

    deinit {
        Logger.streamManager.info("deinit UserStreamState \(key)")
    }

    func setPriority(_ priority: RtcRemoteUserPriority) {
        Logger.streamManager.info("setRemoteUser: \(key.uid), Priority: \(priority)")
        VideoStreamRtcExecutor.setRemoteUserPriority(priority, for: key)
    }

    func subscribe(renderer: StreamRenderProtocol) {
        if let mtRenderer = self.renderer {
            mtRenderer.addChild(renderer: renderer)
            return
        }
        let mtActor = RemoteMultiTargetActor(proxy: self.renderConfig.proxy)
        let mtRenderer = MultiTargetRenderer(key: self.key, queue: self.queue, actor: mtActor,
                                             subscribeConfig: renderer.subscribeConfig, listeners: self.listeners)
        mtRenderer.delegate = self
        mtRenderer.addChild(renderer: renderer)

        Logger.streamManager.info("handleSetRenderer(\(renderer)), \(self.key)")
        let subscribeConfig = renderer.subscribeConfig
        assert(self.renderer == nil)
        self.renderer = mtRenderer
        self.subscribeConfig = subscribeConfig
        if self.shouldSubscribeVideo, let streamId = self.streamId, let stream = self.stream {
            self.lastConfigChangeTime = CACurrentMediaTime()
            self.subscribeCount += 1
            mtRenderer.onRenderResumed()
            let videoIndex = self.computeVideoIndex(stream: stream, resolution: subscribeConfig.res)
            self.subscribeRtcStream(streamId: streamId, stream: stream, res: subscribeConfig, index: videoIndex)
            self.setRtcRenderer(renderer: mtRenderer)
            self.statsCollector.onSubscribeStream(key: self.key)
        }
    }

    func unsubscribe(renderer: StreamRenderProtocol, delay: TimeInterval?, reason: String) {
        Logger.streamManager.info("handleRemoveRenderer(\(renderer), reason: \(reason)), delay: \(delay), \(self.key)")
        guard let mtRenderer = self.renderer else {
            return
        }
        let action = mtRenderer.removeChild(renderer: renderer)
        let delayUnsubscribeConfig = renderConfig.unsubscribeDelay
        switch action {
        case .delayRemove(let token):
            let streamCnt = self.statsCollector.subscriptionCount
            if streamCnt < delayUnsubscribeConfig.maxStreamCount {
                let unsubscribeDelay: DispatchTimeInterval
                if let delay {
                    unsubscribeDelay = .milliseconds(Int(delay * 1000))
                } else if self.key.isScreen {
                    unsubscribeDelay = .milliseconds(Int(delayUnsubscribeConfig.screen * 1000))
                } else {
                    unsubscribeDelay = .milliseconds(Int(delayUnsubscribeConfig.video * 1000))
                }

                self.queue.asyncAfter(deadline: .now() + unsubscribeDelay) { [weak self] in
                    guard let self = self, let renderer = self.renderer else { return }
                    if renderer.shouldRemove(token: token) {
                        self.removeRenderer(renderer: renderer, reason: reason)
                    } else {
                        Logger.streamManager.info("skip remove renderer \(self.key)")
                    }
                }
            } else {
                self.removeRenderer(renderer: mtRenderer, reason: reason)
            }
        case .skip:
            break
        }
    }

    func onStreamAdd(streamId: String, stream: RtcStreamInfo) {
        Logger.streamManager.info("handleStreamAdded(stream: \(streamId), hasVideo: \(stream.hasVideo)), key = \(self.key)")
        guard self.stream == nil else {
            let msg = "repeated streamAdd old: \(self.streamId) new: \(streamId)"
            assertionFailure(msg)
            Logger.streamManager.error(msg)
            return
        }

        self.streamId = streamId
        self.stream = stream
        self.muted = !stream.hasVideo && !self.key.isScreen
        if self.shouldSubscribeVideo, let renderer = self.renderer {
            self.subscribeCount += 1
            renderer.onRenderResumed()
            let resolution = self.subscribeConfig ?? renderer.subscribeConfig
            self.subscribeRtcStream(streamId: streamId, stream: stream, res: resolution,
                                    index: self.computeVideoIndex(stream: stream, resolution: resolution.res))
            self.setRtcRenderer(renderer: renderer)
            self.statsCollector.onSubscribeStream(key: self.key)
        }
    }

    func onStreamRemove(streamId: String) {
        Logger.streamManager.info("handleStreamRemoved(\(streamId)), \(self.key)")
        guard self.streamId == streamId else {
            let msg = "streamRemoved streamID changed \(self.streamId) -> \(streamId)"
            assertionFailure(msg)
            Logger.streamManager.error(msg)
            return
        }
        let prevShouldSubscribe = self.shouldSubscribeVideo
        self.streamId = nil
        self.stream = nil
        let curShouldSubscribe = self.shouldSubscribeVideo
        self.subscribeCount = 0
        if let renderer = self.renderer, prevShouldSubscribe != curShouldSubscribe {
            renderer.onRenderPaused()
            self.statsCollector.onUnsubscribeStream(key: self.key)
        }
        self.cleanupIfNeeded()
    }

    private func removeRenderer(renderer: MultiTargetRenderer, reason: String) {
        Logger.streamManager.info("do remove renderer(\(renderer), reason: \(reason)), \(key)")
        assert(self.renderer === renderer)
        let prevShouldSubscribe = self.shouldSubscribeVideo
        renderer.delegate = nil
        self.renderer = nil
        self.subscribeConfig = nil
        let curShouldSubscribe = self.shouldSubscribeVideo
        if let streamId = self.streamId, prevShouldSubscribe != curShouldSubscribe {
            setRtcRenderer(renderer: nil)
            unsubscribeRtcStream(streamId: streamId, reason: reason)
            renderer.onRenderPaused()
            statsCollector.onUnsubscribeStream(key: self.key)
        }
        self.cleanupIfNeeded()
    }

    private func cleanupIfNeeded(from: String = #function) {
        if stream == nil && renderer == nil {
            Logger.streamManager.info("cleanup UserStreamState(\(self.key)), from \(from)")
            delegate?.didCleanupUserStreamState(key: self.key)
        }
    }

    func onUserMuteVideo(_ muted: Bool) {
        Logger.streamManager.info("handleVideoMuted(muted: \(muted)), \(self.key)")
        guard self.muted != muted else {
            return
        }
        let prevShouldSubscribe = self.shouldSubscribeVideo
        self.muted = muted
        let curShouldSubscribe = self.shouldSubscribeVideo
        guard let renderer = self.renderer, let streamId = self.streamId, let stream = self.stream,
              prevShouldSubscribe != curShouldSubscribe else {
            return
        }

        if !curShouldSubscribe {
            self.setRtcRenderer(renderer: nil)
            self.unsubscribeRtcStream(streamId: streamId, reason: "sdkVideoMuted")
            renderer.onRenderPaused()
            self.statsCollector.onUnsubscribeStream(key: self.key)
        } else {
            self.subscribeCount += 1
            renderer.onRenderResumed()
            let resolution = self.subscribeConfig ?? renderer.subscribeConfig
            self.subscribeRtcStream(streamId: streamId, stream: stream, res: resolution,
                                    index: self.computeVideoIndex(stream: stream, resolution: resolution.res))
            self.setRtcRenderer(renderer: renderer)
            self.statsCollector.onSubscribeStream(key: self.key)
        }
    }

    func setSubscribeConfig(_ config: VideoSubscribeConfig, renderer: AnyObject) {
        self.renderer?.setSubscribeConfig(config, renderer: renderer)
    }

    func destroy() {
        self.renderer?.onRenderPaused()
        if let streamId = self.streamId {
            onStreamRemove(streamId: streamId)
        }
    }

    // MARK: - simulcast
    @RwAtomic
    private var lastConfigChangeTime: CFTimeInterval = 0
    private func handleSubscribeConfigChange(_ newConfig: VideoSubscribeConfig) {
        Logger.streamManager.info("handleSubscribeConfigChange: \(newConfig), \(key)")
        guard self.subscribeConfig?.res != newConfig.res || self.subscribeConfig?.fps != newConfig.fps else {
            self.subscribeConfig = newConfig
            return
        }
        let oldSize = self.subscribeConfig
        self.subscribeConfig = newConfig
        guard shouldSubscribeVideo, let streamId = self.streamId, let stream = self.stream else {
            return
        }

        let index = self.computeVideoIndex(stream: stream, resolution: newConfig.res)
        if oldSize != newConfig {
            Logger.streamManager.info("simulcast switch config \(oldSize) -> \(newConfig), \(key)")
            subscribeRtcStream(streamId: streamId, stream: stream, res: newConfig, index: index)
        }
    }

    // MARK: - diagnose
    func checkStatus() -> StreamStatus {
        let hasRenderer = self.renderer != nil
        let hasStream = self.stream != nil
        let muted = self.muted
        let streamID = self.streamId
        Logger.streamManager.info("\(key), hasRenderer: \(hasRenderer), hasStream: \(hasStream), isMuted: \(muted)")
        return StreamStatus(streamKey: self.key, streamID: streamID, hasRenderer: hasRenderer, streamAdded: hasStream,
                            muted: muted, lastSDKCall: self.lastSDKSubCall)
    }

    // MARK: - RTC Action
    private func setRtcRenderer(renderer: ByteRTCVideoSinkProtocol?) {
        Logger.streamManager.info("setRtcRenderer(\(renderer)), \(self.key)")
        VideoStreamRtcExecutor.setRemoteRenderer(renderer, for: self.key)
    }

    private(set) var rtcSubscribeConfig: RtcSubscribeConfig?
    private func subscribeRtcStream(streamId: String, stream: RtcStreamInfo, res: VideoSubscribeConfig, index: Int) {
        let call: String
        let desc = index < stream.videoStreamDescriptions.count ? stream.videoStreamDescriptions[index] : nil
        let config = RtcSubscribeConfig(res: res, index: index, streamDescription: desc)
        if let videoSize = desc?.videoSize, videoSize.width > 0 && videoSize.height > 0 {
            call = "subscribeRtcStream(\(streamId), desc: (\(desc)), width: \(config.width), height: \(config.height), \(key), videoBaseline: \(config.videoBaseline), framerate: \(config.framerate)"
        } else {
            call = "subscribeRtcStream(\(streamId), desc: (\(desc)), index: \(index)), \(key), videoBaseline: \(config.videoBaseline)"
        }
        self.lastSDKSubCall = "[\(Self.dateFormatter.string(from: Date()))]\(call)"
        Logger.streamManager.info(call)
        self.rtcSubscribeConfig = config
        VideoStreamRtcExecutor.subscribeStream(streamId, key: key, config: config)
    }

    private func unsubscribeRtcStream(streamId: String, reason: String) {
        let call = "unsubscribeRtcStream(\(streamId), reason: \(reason)), \(key)"
        self.lastSDKSubCall = "[\(Self.dateFormatter.string(from: Date()))]\(call)"
        Logger.streamManager.info(call)
        let config = self.rtcSubscribeConfig
        self.rtcSubscribeConfig = nil
        VideoStreamRtcExecutor.unsubscribeStream(streamId, key: key, config: config)
    }

}

private extension UserStreamState {
    func computeVideoIndex(stream: RtcStreamInfo, resolution: Int?) -> Int {
        guard let resolution = resolution else {
            return 0
        }
        return checkVideoStreamIndex(descriptions: stream.videoStreamDescriptions, current: resolution)
    }

    /** 找分辨率, 相等直接返回,
     * 1. 找到相等直接返回
     * 2. 如果都小于current返回最大的
     * 3. 如果都大于current返回最小的
     * 4. 如果大于小于都有返回小于里面最接近的
     */
    func findNearIndex(resolutions: [CGFloat], current: CGFloat) -> Int {
        var nearMinIndex: Int = 0
        var nearMinDifference: CGFloat = 100000.0

        var nearMaxIndex: Int = 0
        var nearMaxDifference: CGFloat = 100000.0

        let nearDefaultDifference: CGFloat = 100000.0

        for (index, element) in resolutions.enumerated() {
            guard element != current else {
                return index
            }

            let difference = abs(element - current)

            if element < current, difference < nearMinDifference {
                nearMinDifference = difference
                nearMinIndex = index
            }

            if element > current, difference < nearMaxDifference {
                nearMaxDifference = difference
                nearMaxIndex = index
            }
        }

        return nearMinDifference.isEqual(to: nearDefaultDifference) ? nearMaxIndex : nearMinIndex
    }

    func checkVideoStreamIndex(descriptions: [RtcVideoStreamDescription], current: Int) -> Int {
        let resolutions: [CGFloat] = descriptions.map {
            $0.videoSize.width < $0.videoSize.height ? $0.videoSize.width : $0.videoSize.height
        }
        return findNearIndex(resolutions: resolutions, current: CGFloat(current))
    }
}

extension ByteRTCSubscribeVideoBaseline {
    var baselineDesc: String {
        "goodRes: \(self.acceptableGoodVideoPixelBaseline), goodFps: \(self.acceptableGoodVideoFpsBaseline), badRes: \(self.acceptableBadVideoPixelBaseline), badFps: \(self.acceptableBadVideoFpsBaseline)"
    }
}

extension UserStreamState: MultiTargetRendererDelegate {
    // already in queue
    func didChangeSubscribeConfig(renderer: MultiTargetRenderer, config: VideoSubscribeConfig) {
        self.lastConfigChangeTime = CACurrentMediaTime()
        let debounce = self.renderConfig.viewSizeDebounce
        self.queue.asyncAfter(deadline: .now() + .milliseconds(Int(debounce * 1000))) { [weak self] in
            guard let self = self, CACurrentMediaTime() - self.lastConfigChangeTime > debounce else { return }
            self.handleSubscribeConfigChange(config)
        }
    }
}

private extension VideoStreamRtcExecutor {
    static func setRemoteRenderer(_ renderer: ByteRTCVideoSinkProtocol?, for key: RtcStreamKey) {
        executeInCurrentContext { [weak renderer] rtc in
            if let renderer = renderer, rtc.sessionId == key.sessionId, !key.isLocal {
                let streamKey = ByteRTCRemoteStreamKey()
                streamKey.userId = key.uid.id
                streamKey.streamIndex = key.isScreen ? .screen : .main
                rtc.setRemoteVideoSink(streamKey, withSink: renderer, with: .NV12)
            }
        }
    }

    static func subscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig) {
        executeInCurrentContext { rtc in
            if rtc.sessionId == key.sessionId {
                rtc.subscribeStream(streamId, key: key, subscribeConfig: config)
            }
        }
    }

    static func unsubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig?) {
        executeInCurrentContext { rtc in
            if rtc.sessionId == key.sessionId {
                rtc.unsubscribeStream(streamId, key: key, subscribeConfig: config)
            }
        }
    }

    static func setRemoteUserPriority(_ priority: RtcRemoteUserPriority, for key: RtcStreamKey) {
        executeInCurrentContext { rtc in
            if rtc.sessionId == key.sessionId {
                rtc.setRemoteUserPriority(key.uid, priority: priority)
            }
        }
    }
}
