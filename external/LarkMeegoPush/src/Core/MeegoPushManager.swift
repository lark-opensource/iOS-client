//
//  File.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation
import ThreadSafeDataStructure
import LarkMeegoLogger

public enum MeegoPushServiceType {
    case native
    case flutter
}

public class MeegoPushManager {
    public static let shared = MeegoPushManager()

    private var nativeTopicListenerMap: SafeDictionary<String, (Topic, MeegoPushDataListener)> = [:] + .readWriteLock
    private var flutterTopicListenerMap: SafeDictionary<String, (Topic, MeegoPushDataListener)> = [:] + .readWriteLock

    // 消息分发
    public func dispatchPush(meegoPushMsg: Meego_MeegoPushMessage, payload: Data) {
        // Native侧推送数据分发
        if let (_, nativeTopicListener) = nativeTopicListenerMap[meegoPushMsg.topicName] {
            MeegoLogger.info("[dispatchPush] to native.TopicName: \(meegoPushMsg.topicName) seqID: \(meegoPushMsg.seqID)")
            nativeTopicListener.onPushContentData(meegoPushMsg.content,
                                                  seqID: meegoPushMsg.seqID,
                                                  timestamp: meegoPushMsg.timestamp)
        }
        // Flutter侧推送数据分发
        if let (_, flutterTopicListener) = flutterTopicListenerMap[meegoPushMsg.topicName] {
            DispatchQueue.main.async {
                MeegoLogger.info("[dispatchPush] to flutter.TopicName: \(meegoPushMsg.topicName) seqID: \(meegoPushMsg.seqID)")
                flutterTopicListener.onPushPayload(payload)
            }
        }
    }

    public func notifyTopicVersionChanged(topicName: String, seqId: Int, updateTime: Int) {
        // Native侧推送数据分发
        if let (_, nativeTopicListener) = nativeTopicListenerMap[topicName] {
            MeegoLogger.info("[notifyTopicVersionChanged] to Native with topicName:\(topicName) seqId:\(seqId)")
            nativeTopicListener.onTopicVersionAtLastPush(topicName: topicName, currentVersion: seqId, currentTimestamp: updateTime)
        }
        // Flutter侧推送数据分发
        if let (_, flutterTopicListener) = flutterTopicListenerMap[topicName] {
            DispatchQueue.main.async {
                MeegoLogger.info("[notifyTopicVersionChanged] to Flutter with topicName:\(topicName) seqId:\(seqId)")
                flutterTopicListener.onTopicVersionAtLastPush(topicName: topicName, currentVersion: seqId, currentTimestamp: updateTime)
            }
        }
    }

    func batchRegisterPush(topicListenerList: [(Topic, MeegoPushDataListener)],
                           serviceType: MeegoPushServiceType) {
        MeegoLogger.info("[batchRegisterPush] \(topicListenerList.count) topics with serviceType:\(serviceType)")

        if topicListenerList.isEmpty {
            MeegoLogger.error("[batchRegisterPush] listeners is empty")
            return
        }

        var topicList: [Topic] = []

        switch serviceType {
        case .native:
            topicListenerList.forEach { (topic, listener) in
                topicList.append(topic)
                nativeTopicListenerMap[topic.topicName] = (topic, listener)
            }
        case .flutter:
            topicListenerList.forEach { (topic, listener) in
                topicList.append(topic)
                flutterTopicListenerMap[topic.topicName] = (topic, listener)
            }
        }

        // 批量订阅Topic
        SubscribeManager.shared.batchSubscribe(topicList)
    }

    func batchUnregisterPush(topicList: [Topic],
                             serviceType: MeegoPushServiceType) {
        MeegoLogger.info("[batchUnregisterPush] \(topicList.count) topics with serviceType:\(serviceType)")

        if topicList.isEmpty {
            return
        }

        switch serviceType {
        case .native:
            batchUnregisterCurrentListener(topicList: topicList,
                                            currentTopicListenerMap: &nativeTopicListenerMap,
                                            otherTopicListenerMap: flutterTopicListenerMap)
        case .flutter:
            batchUnregisterCurrentListener(topicList: topicList,
                                            currentTopicListenerMap: &flutterTopicListenerMap,
                                            otherTopicListenerMap: nativeTopicListenerMap)
        }
    }

    func unregisterAllPush(serviceType: MeegoPushServiceType) {
        MeegoLogger.info("[unregisterAllPush] with serviceType:\(serviceType)")

        var topicList: [Topic] = []

        switch serviceType {
        case .native:
            nativeTopicListenerMap.values.forEach { (topic, _) in
                topicList.append(topic)
            }
        case .flutter:
            flutterTopicListenerMap.values.forEach { (topic, _) in
                topicList.append(topic)
            }
        }

        batchUnregisterPush(topicList: topicList, serviceType: serviceType)
    }
}

// MARK: - Extension for MeegoPushManager's Private Func

private extension MeegoPushManager {
    func batchUnregisterCurrentListener(topicList: [Topic],
                                        currentTopicListenerMap: inout SafeDictionary<String, (Topic, MeegoPushDataListener)>,
                                        otherTopicListenerMap: SafeDictionary<String, (Topic, MeegoPushDataListener)>) {
        if topicList.isEmpty {
            MeegoLogger.warn("[batchUnregisterCurrentListener] topicList is empty then return")
            return
        }

        var needUnregisterTopicList: [Topic] = []

        for topic in topicList {
            currentTopicListenerMap.removeValue(forKey: topic.topicName)
            // 过滤其他侧包含的订阅，当Native和Flutter两侧都没订阅此Topic时，方可取消订阅此Topic。
            if !otherTopicListenerMap.keys.contains(topic.topicName) {
                needUnregisterTopicList.append(topic)
            }
        }

        MeegoLogger.info("[batchUnregisterCurrentListener] \(needUnregisterTopicList.count) topics")
        SubscribeManager.shared.batchUnSubscribe(needUnregisterTopicList)
    }
}
