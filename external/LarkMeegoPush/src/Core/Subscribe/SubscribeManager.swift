//
//  SubscribeManager.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation
import LarkMeegoNetClient
import LKCommonsTracker
import LarkMeegoLogger
import LarkContainer

class SubscribeManager {
    static let shared = SubscribeManager()

    private var subscribedTopicMap: [String: Topic] = [:]
    private var topicCacheMap: [String: Topic] = [:]

    private let semaphore = DispatchSemaphore(value: 1)

    // 单条订阅
    func subscribe(_ topic: Topic) {
        batchSubscribe([topic])
    }

    // 批量订阅
    func batchSubscribe(_ topicList: [Topic]) {
        if topicList.isEmpty {
            return
        }
        // identification有效
        if HeartBeatManager.shared.isIdentificationValid() {
            var topicMap: [String: Topic] = [:]
            for topic in topicList {
                topicMap[topic.topicName] = topic
            }
            composeSubscribeTopics(topicMap)
        } else {
            self.semaphore.wait()
            for topic in topicList {
                topicCacheMap[topic.topicName] = topic
            }
            self.semaphore.signal()
            HeartBeatManager.shared.checkHeartBeatIdentityIfNeed()
        }
    }

    // 组装本地未上报列表
    func composeSubscribeTopics(_ topicMap: [String: Topic], stopRetry: Bool = false) {
        guard let currentDeviceIdentification = HeartBeatManager.shared.currentDeviceIdentification else {
            return
        }
        var tmpTopicMap = topicMap
        semaphore.wait()
        if !topicCacheMap.isEmpty {
            tmpTopicMap.merge(topicCacheMap) { $1 }
            topicCacheMap.removeAll()
        }
        semaphore.signal()

        if !tmpTopicMap.isEmpty {
            batchSubscribeReal(tmpTopicMap, deviceIdentification: currentDeviceIdentification, stopRetry: stopRetry)
        }
    }

    // 上报UnSubscribe
    func unSubscribe(_ topic: Topic) {
        batchUnSubscribe([topic])
    }

    // 批量上报UnSubscribe
    func batchUnSubscribe(_ topicList: [Topic]) {
        if topicList.isEmpty {
            return
        }

        var ssbIds: [Int] = []
        // 获取需要取消订阅Topic的 ssbIds
        semaphore.wait()
        for topic in topicList {
            if let subscribedTopic = subscribedTopicMap[topic.topicName] {
                ssbIds.append(subscribedTopic.ssbId)
            }
            topicCacheMap.removeValue(forKey: topic.topicName)
            subscribedTopicMap.removeValue(forKey: topic.topicName)
        }
        semaphore.signal()

        // 如果本地没有订阅的Topic，停止心跳检测。
        if isSubscribedTopicMapEmpty() {
            HeartBeatManager.shared.stopHeartBeat()
        }
        unSubscribeReal(ssbIds)
    }

    // 重新订阅
    func afreshSubscribe(with stopRetry: Bool = false) {
        semaphore.wait()
        let topicMap = subscribedTopicMap
        subscribedTopicMap.removeAll()
        semaphore.signal()

        composeSubscribeTopics(topicMap, stopRetry: stopRetry)
    }

    func cleanupTopicMap() {
        semaphore.wait()
        subscribedTopicMap.removeAll()
        topicCacheMap.removeAll()
        semaphore.signal()
    }
}

private extension SubscribeManager {
    func batchSubscribeReal(_ topicMap: [String: Topic], deviceIdentification: String, stopRetry: Bool = false) {
        guard let netClient = try? Container.shared.getCurrentUserResolver().resolve(type: MeegoNetClient.self),
           !topicMap.isEmpty && !deviceIdentification.isEmpty else {
            return
        }

        var topicInfoList = getTopicInfoList(with: topicMap)
        let request = SubscribeRequest(catchError: true,
                                       topics: topicInfoList,
                                       deviceIdentification: deviceIdentification)

        netClient.sendRequest(request) { [weak self] result in
            switch result {
            case .success(let response):
                if response.code != 0 {
                    MeegoLogger.warn("SubscribeRequest with biz err code: \(response.code). \(response.msg)")
                    // 业务错误码 404 表示deviceIdentification失效 => Retry
                    if response.code == 404 && !stopRetry {
                        self?.handleSubscribeError(topicMap, deviceIdentification: deviceIdentification)
                    }
                    self?.trackSubscribeResult(false, traceId: "", errMsg: response.msg)
                    return
                }

                if let ssbIdsMap = response.data?.ssbIds {
                    var mutableTopicMap = topicMap

                    self?.semaphore.wait()
                    ssbIdsMap.keys.forEach { key in
                        // 将订阅成功后从服务端获取的ssbId 赋值 给对应的Topic
                        mutableTopicMap[key]?.ssbId = ssbIdsMap[key] ?? 0
                        // 将订阅成功的Topic记录在subscribedTopicMap中
                        self?.subscribedTopicMap[key] = mutableTopicMap[key]
                    }
                    self?.semaphore.signal()
                }

                // 返回当前topic的最新序号和更新时间
                if let topicSeqIdsMap = response.data?.topicSeqIdsMap {
                    topicSeqIdsMap.keys.forEach { topicName in
                        MeegoPushManager.shared.notifyTopicVersionChanged(topicName: topicName,
                                                                          seqId: topicSeqIdsMap[topicName]?.seqId ?? -1,
                                                                          updateTime: topicSeqIdsMap[topicName]?.updateTime ?? -1)
                    }
                }

                self?.heartBeatDetectIfNeed()
                self?.trackSubscribeResult(true)
            case .failure(let error):
                self?.trackSubscribeResult(false, traceId: "", errMsg: error.localizedDescription)
            }
        }
    }

    func getTopicInfoList(with topicMap: [String: Topic]) -> [[String: Any]] {
        var topicInfoList: [[String: Any]] = []
        topicMap.values.forEach { topic in
            var topicInfo: [String: Any] = [:]
            topicInfo["topic_type"] = topic.topicType
            topicInfo["topic_name"] = topic.topicName
            topicInfoList.append(topicInfo)
        }
        return topicInfoList
    }

    func handleSubscribeError(_ topicMap: [String: Topic], deviceIdentification: String) {
        // 本地currentDeviceIdentification已经更新，直接返回业务重试
        if deviceIdentification != HeartBeatManager.shared.currentDeviceIdentification {
            // 避免触发循环请求
            composeSubscribeTopics(topicMap, stopRetry: true)
        } else {
            self.semaphore.wait()
            topicCacheMap.merge(topicMap) { $1 }
            self.semaphore.signal()
            HeartBeatManager.shared.checkHeartBeatIdentityIfNeed(stopRetry: true)
        }
    }

    func heartBeatDetectIfNeed() {
        // 本地订阅者不为空，心跳处于停止状态 => 开启心跳
        if !isSubscribedTopicMapEmpty() && !HeartBeatManager.shared.isHeartBeatRunning {
            HeartBeatManager.shared.startHeartBeat()
            return
        }
        // 本地订阅者为空，心跳处于运行状态 => 停止心跳
        if isSubscribedTopicMapEmpty() && HeartBeatManager.shared.isHeartBeatRunning {
            HeartBeatManager.shared.stopHeartBeat()
        }
    }

    func unSubscribeReal(_ ssbIds: [Int]) {
        guard let netClient = try? Container.shared.getCurrentUserResolver().resolve(type: MeegoNetClient.self),
           !ssbIds.isEmpty else {
            return
        }

        let request = UnsubscribeRequest(catchError: true,
                                         ssbIds: ssbIds,
                                        deviceIdentification: HeartBeatManager.shared.currentDeviceIdentification ?? "")

        netClient.sendRequest(request) { [weak self] result in
            switch result {
            case .success(let response):
                MeegoLogger.info("Unsubscribe request success.")
                self?.trackUnsubscribeResult(true)
            case .failure(let error):
                MeegoLogger.warn("Unsubscribe request fail.")
                self?.trackUnsubscribeResult(false, traceId: "", errMsg: error.localizedDescription)
            }
        }
    }
}

private extension SubscribeManager {
    func isSubscribedTopicMapEmpty() -> Bool {
        var bRet = false
        self.semaphore.wait()
        bRet = subscribedTopicMap.isEmpty
        self.semaphore.signal()
        return bRet
    }
}

// 埋点
private extension SubscribeManager {
    func trackSubscribeResult(_ success: Bool, traceId: String? = nil, errMsg: String? = nil) {
        let slardarEvent = SlardarEvent(
            name: "meego_push_subscribe",
            metric: [:],
            category: ["op": "subscribe",
                       "success": success],
            extra: success ? [:] : ["trace_id": traceId ?? "", "error_msg": errMsg ?? ""]
        )
        Tracker.post(slardarEvent)
    }

    func trackUnsubscribeResult(_ success: Bool, traceId: String? = nil, errMsg: String? = nil) {
        let slardarEvent = SlardarEvent(
            name: "meego_push_subscribe",
            metric: [:],
            category: ["op": "unsubscribe",
                       "success": success],
            extra: success ? [:] : ["trace_id": traceId ?? "", "error_msg": errMsg ?? ""]
        )
        Tracker.post(slardarEvent)
    }
}
