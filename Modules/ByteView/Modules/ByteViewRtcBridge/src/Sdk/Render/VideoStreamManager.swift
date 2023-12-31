//
//  VideoStreamManager.swift
//  ByteView
//
//  Created by liujianlong on 2021/1/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import VolcEngineRTC
import ByteViewCommon

final class VideoStreamListeners {
    let rendererListenerers = Listeners<RtcVideoRendererListener>()
}

final class VideoStreamManager {
    static let shared = VideoStreamManager()
    let logger = Logger.streamManager

    private let queue = DispatchQueue(label: "lark.byteview.streammanager")
    private var userStreamStateMap: [RtcStreamKey: UserStreamState] = [:]
    private let localStreamState: LocalStreamState

    private let statsCollector = StreamStatsCollector()
    let listeners = VideoStreamListeners()
    private var renderConfig = RtcRenderConfig.default

    init() {
        self.logger.info("init VideoStreamManager")
        self.localStreamState = LocalStreamState(queue: queue, listeners: listeners)
        RtcInternalListeners.addListener(self)
    }

    private func ensureState(key: RtcStreamKey) -> UserStreamState {
        let state: UserStreamState
        if let existState = self.userStreamStateMap[key] {
            state = existState
        } else {
            state = UserStreamState(key: key, queue: queue, listeners: listeners, config: self.renderConfig, statsCollector: self.statsCollector)
            state.delegate = self
            self.userStreamStateMap[key] = state
        }
        return state
    }
}

extension VideoStreamManager: RtcVideoStream {
    func subscribe(key: RtcStreamKey, renderer: StreamRenderProtocol) {
        self.queue.async {
            self.logger.info("subscribe(\(key), render: \(renderer))")
            if key.isLocal {
                self.localStreamState.subscribe(renderer: renderer)
            } else {
                self.ensureState(key: key).subscribe(renderer: renderer)
            }
        }
    }

    func unsubscribe(key: RtcStreamKey,
                     delay: TimeInterval?,
                     renderer: StreamRenderProtocol,
                     reason: String) {
        self.queue.async {
            self.logger.info("unsubscribe(\(key), render: \(renderer))")
            if key.isLocal {
                self.localStreamState.unsubscribe(renderer: renderer)
            } else {
                self.userStreamStateMap[key]?.unsubscribe(renderer: renderer, delay: delay, reason: reason)
            }
        }
    }

    func setPriority(_ priority: RtcRemoteUserPriority, for key: RtcStreamKey) {
        if key.isLocal { return }
        self.queue.async {
            if !key.isScreen {
                // 同一个user的screen和video优先级一致，以screen为准
                if self.userStreamStateMap.keys.contains(where: {
                    $0.isScreen && $0.uid == key.uid && $0.sessionId == key.sessionId
                }) {
                    self.logger.info("setRemoteUser Prority failed due to \(key) is sharing screen")
                    return
                }
            }
            self.ensureState(key: key).setPriority(priority)
        }
    }

    func setSubscribeConfig(_ config: VideoSubscribeConfig, for key: RtcStreamKey, renderer: AnyObject) {
        self.queue.async { [weak renderer] in
            guard let renderer = renderer else { return }
            if key.isLocal {
                self.localStreamState.setSubscribeConfig(config, renderer: renderer)
            } else {
                self.userStreamStateMap[key]?.setSubscribeConfig(config, renderer: renderer)
            }
        }
    }

    func diagnoseSubscribeTimeout(for key: RtcStreamKey) {
        if key.isLocal {
            return
        }
        queue.async {
            guard let state = self.userStreamStateMap[key] else { return }
            // StreamRenderView 无法感知 Participant 是否 Mute，需要检查 Stream 状态
            if let streamId = state.streamId, state.subscribeCount == 1, state.checkStatus().isOK {
                // 上报首次订阅流超时
                self.listeners.rendererListenerers.forEach { $0.onSubscribeFirstTimeout(key: key, streamId: streamId) }
                self.logger.warn("[diagnostic] \(key) is not rendering")
            }
        }
    }
}

extension VideoStreamManager: UserStreamStateDelegate {
    func didCleanupUserStreamState(key: RtcStreamKey) {
        self.userStreamStateMap.removeValue(forKey: key)
    }
}

// MARK: - Status
extension VideoStreamManager {
    func fetchStreamInfo(sessionId: String, completion: @escaping (RtcVideoStreamInfo) -> Void) {
        queue.async {
            var hasScreenShare = false
            var hasSubscribeCameraStream = false
            for (key, value) in self.userStreamStateMap where key.sessionId == sessionId {
                if key.isScreen {
                    hasScreenShare = true
                } else if !value.muted {
                    hasSubscribeCameraStream = true
                }
                if hasScreenShare && hasSubscribeCameraStream {
                    break
                }
            }
            completion(.init(hasScreenShare: hasScreenShare, hasSubscribeCameraStream: hasSubscribeCameraStream))
        }
    }

    func tryGetAllStreamStatus(sessionId: String) -> [StreamStatus] {
        queue.sync {
            var ret: [StreamStatus] = [self.localStreamState.checkStatus()]
            ret.append(contentsOf: self.userStreamStateMap.filter({ $0.key.sessionId == sessionId }).map({
                $0.value.checkStatus()
            }))
            return ret
        }
    }

    func tryGetStreamStatus(key: RtcStreamKey) -> StreamStatus? {
        queue.sync {
            if key.isLocal {
                return self.localStreamState.checkStatus()
            } else if let state = self.userStreamStateMap[key] {
                return state.checkStatus()
            } else {
                self.logger.warn("\(key) not exists")
                return nil
            }
        }
    }

    func fetchRemoteDiagnoseInfo(key: RtcStreamKey, completion: @escaping (RemoteVideoDiagnoseInfo?) -> Void) {
        if key.isLocal {
            completion(nil)
            return
        }

        queue.async {
            if let state = self.userStreamStateMap[key] {
                completion(RemoteVideoDiagnoseInfo(streamId: state.streamId, subscribeCount: state.subscribeCount, status: state.checkStatus()))
            } else {
                completion(nil)
            }
        }
    }

    struct RemoteVideoDiagnoseInfo {
        let streamId: String?
        let subscribeCount: Int
        let status: StreamStatus
    }
}

// MARK: - RtcListener
extension VideoStreamManager: RtcInternalListener {

    func onStreamAdd(_ rtc: RtcInstance, streamId: String, key: RtcStreamKey, stream: RtcStreamInfo) {
        self.queue.async {
            self.logger.info("onStreamAdd(\(key), streamId: \(streamId))")
            self.ensureState(key: key).onStreamAdd(streamId: streamId, stream: stream)
        }
    }

    func onStreamRemove(_ rtc: RtcInstance, streamId: String, key: RtcStreamKey) {
        self.queue.async {
            self.logger.info("onStreamRemoved(\(key), streamID: \(streamId))")
            if let state = self.userStreamStateMap[key] {
                state.onStreamRemove(streamId: streamId)
            } else {
                self.logger.error("missing stream, streamId: \(streamId)")
            }
        }
    }

    func onUserMuteVideo(_ rtc: RtcInstance, muted: Bool, key: RtcStreamKey) {
        self.queue.async {
            self.logger.info("onUserMuteVideo(rtcUid: \(key.uid), muted: \(muted))")
            self.ensureState(key: key).onUserMuteVideo(muted)
        }
    }

    func didStartVideoCapture(_ rtc: RtcInstance) {
        self.queue.async {
            self.localStreamState.startCapture()
        }
    }

    func didStopVideoCapture(_ rtc: RtcInstance) {
        self.queue.async {
            self.localStreamState.stopCapture()
        }
    }

    func onCreateInstance(_ rtc: RtcInstance) {
        let renderConfig = rtc.renderConfig
        let sessionId = rtc.sessionId
        let rtcTag = "[Rtc(\(rtc.instanceId))][\(sessionId)]"
        self.queue.async {
            self.logger.info("\(rtcTag) onCreateInstance: setup VideoStreamManager")
            self.renderConfig = renderConfig
            self.localStreamState.renderConfig = renderConfig
            self.userStreamStateMap = self.userStreamStateMap.filter({ $0.key.sessionId == sessionId })
        }
        DispatchQueue.main.async {
            StreamRenderTicker.setSharedDisplayLinkConfig(renderConfig.sharedDisplayLink)
        }
    }

    func onDestroyInstance(_ rtc: RtcInstance) {
        let sessionId = rtc.sessionId
        let rtcTag = "[Rtc(\(rtc.instanceId))][\(sessionId)]"
        self.queue.async {
            self.logger.info("\(rtcTag) onDestroyInstance: destroy VideoStreamManager")
            self.localStreamState.destroy()
            self.renderConfig = .default
            self.userStreamStateMap.forEach {
                if $0.key.sessionId == sessionId {
                    $0.value.destroy()
                }
            }
            self.statsCollector.reset()
            self.userStreamStateMap = self.userStreamStateMap.filter({ $0.key.sessionId != sessionId })
        }
    }
}

extension Logger {
    static let streamManager = getLogger("StreamManager")
}
