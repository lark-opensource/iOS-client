//
//  StreamBillingTracker.swift
//  ByteView
//
//  Created by panzaofeng on 2023/2/293.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewRtcBridge

final class StreamBillingTracker {
    private var heartBeater: Timer?
    private var globalVideoCount: Int = 0
    private var subscribeVideoCount: Int = 0

    private var trackInterval: Int = 60
    init(trackInterval: Int) {
        self.trackInterval = trackInterval
    }

    deinit {
        stopHeartBeat()
    }

    @RwAtomic
    private var subscribedStreams: [RtcStreamKey: BillingSubscribeInfo] = [:]
    func subscribe(streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig) {
        let info = BillingSubscribeInfo(streamId: streamId, config: config)
        if let oldInfo = subscribedStreams.updateValue(info, forKey: key) {
            unsubscribe(key: key, info: oldInfo)
        }
        subscribe(key: key, info: info)
    }

    func unsubscribe(key: RtcStreamKey) {
        if let oldInfo = subscribedStreams.removeValue(forKey: key) {
            unsubscribe(key: key, info: oldInfo)
        }
    }

    private func subscribe(key: RtcStreamKey, info: BillingSubscribeInfo) {
        subscribeVideoCount += 1
        let params: TrackParams = [
            "event_time": Date().timeIntervalSince1970,
            "billing_product_type": "client",
            "action_name": "subscribe",
            "stream_id": info.streamId,
            "stream_device_id": key.uid,
            "width": info.width,
            "height": info.height,
            "action_match_id": subscribeVideoCount
        ]
        VCTracker.post(name: .vc_billing_video_recv_resolution_status, params: params)
        self.startHeartBeatIfNeeded()
    }

    private func unsubscribe(key: RtcStreamKey, info: BillingSubscribeInfo) {
        let params: TrackParams = [
            "event_time": Date().timeIntervalSince1970,
            "billing_product_type": "client",
            "action_name": "cancel",
            "stream_id": info.streamId,
            "stream_device_id": key.uid,
            "width": info.width,
            "height": info.height,
            "action_match_id": subscribeVideoCount
        ]
        VCTracker.post(name: .vc_billing_video_recv_resolution_status, params: params)
        self.stopHeartBeatIfNeeded()
    }

    private func startHeartBeatIfNeeded() {
        if self.heartBeater == nil {
            startHeartBeat()
            globalVideoSubscribe()
        }
    }

    private func stopHeartBeatIfNeeded() {
        if self.heartBeater == nil {
            return
        }
        if subscribedStreams.isEmpty {
            stopHeartBeat()
        }
    }

    private func globalVideoSubscribe() {
        globalVideoCount += 1
        let params: TrackParams = [
            "event_time": Date().timeIntervalSince1970,
            "billing_product_type": "client",
            "action_name": "start_global_subscribe",
            "action_match_id": globalVideoCount
        ]
        VCTracker.post(name: .vc_billing_global_video_recv_status, params: params)
    }

    private func globalVideoUnsubscribe() {
        let params: TrackParams = [
            "event_time": Date().timeIntervalSince1970,
            "billing_product_type": "client",
            "action_name": "end_global_subscribe",
            "action_match_id": globalVideoCount
        ]
        VCTracker.post(name: .vc_billing_global_video_recv_status, params: params)
    }

    private func doBillingHeartBeat() {
        var subscribeList: String = ""
        self.subscribedStreams.forEach { (key, info) in
            if !subscribeList.isEmpty {
                subscribeList += "#"
            }
            subscribeList += "stream_id:\(info.streamId),stream_device_id:\(key.uid),width:\(info.width),height:\(info.height)"
        }
        if subscribeList.isEmpty {
            stopHeartBeat()
            return
        }
        let params: TrackParams = [
            "event_time": Date().timeIntervalSince1970,
            "billing_product_type": "client",
            "video_subscribe_list": subscribeList
        ]
        VCTracker.post(name: .vc_billing_heartbeat_status, params: params)
    }

    private func startHeartBeat() {
        if self.heartBeater != nil {
            stopHeartBeat()
        }
        let timer = Timer(timeInterval: TimeInterval(trackInterval), repeats: true, block: { [weak self] _ in
            self?.doBillingHeartBeat()
        })
        self.heartBeater = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopHeartBeat() {
        if self.heartBeater != nil {
            globalVideoUnsubscribe()
            self.heartBeater?.invalidate()
            self.heartBeater = nil
        }
    }

    private struct BillingSubscribeInfo {
        let streamId: String
        let config: RtcSubscribeConfig
        let width: Int
        let height: Int

        init(streamId: String, config: RtcSubscribeConfig) {
            self.streamId = streamId
            self.config = config
            if config.width > 0, config.height > 0 {
                self.width = config.width
                self.height = config.height
            } else {
                let res = config.preferredConfig.res
                self.width = res
                self.height = res
            }
        }
    }
}
