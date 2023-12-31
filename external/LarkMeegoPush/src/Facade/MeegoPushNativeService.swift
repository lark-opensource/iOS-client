//
//  MeegoPushNativeService.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import LarkMeegoNetClient
import LarkMeegoLogger

/// iOS LarkMeegoPush SDK 说明文档
/// https://bytedance.feishu.cn/wiki/wikcnLQF4xZYSYhbNlS9s6Eufxe
public final class MeegoPushNativeService: MeegoPushServiceAbility {
    public static func registerPush(topic: Topic, listener: MeegoPushDataListener) {
        MeegoLogger.info("[MeegoPushNativeService][registerPush] TopicName:\(topic.topicName)")

        let topicListenerList = [(topic, listener)]
        MeegoPushManager.shared.batchRegisterPush(topicListenerList: topicListenerList,
                                                  serviceType: .native)
    }

    public static func batchRegisterPush(_ topicListenerList: [(Topic, MeegoPushDataListener)]) {
        MeegoLogger.info("[MeegoPushNativeService][batchRegisterPush] with \(topicListenerList.count) topics")

        MeegoPushManager.shared.batchRegisterPush(topicListenerList: topicListenerList, serviceType: .native)
    }

    public static func unregisterPush(topic: Topic) {
        MeegoLogger.info("[MeegoPushNativeService][unregisterPush] TopicName:\(topic.topicName)")

        MeegoPushManager.shared.batchUnregisterPush(topicList: [topic], serviceType: .native)
    }

    public static func batchUnregisterPush(topicList: [Topic]) {
        MeegoLogger.info("[MeegoPushNativeService][batchUnregisterPush] with \(topicList.count) topics")

        MeegoPushManager.shared.batchUnregisterPush(topicList: topicList, serviceType: .native)
    }

    public static func unregisterAllPush() {
        MeegoLogger.info("[MeegoPushNativeService] unregisterAllPush")

        MeegoPushManager.shared.unregisterAllPush(serviceType: .native)
    }

    public static func stopPushService() {
        MeegoLogger.info("[MeegoPushNativeService] stopPushService")
        // 停止业务侧长链接心跳续命
        HeartBeatManager.shared.stopHeartBeat()
        // 清除MeegoPushManager中用户态内存数据。
        MeegoPushManager.shared.unregisterAllPush(serviceType: .flutter)
        MeegoPushManager.shared.unregisterAllPush(serviceType: .native)
        // 清除SubscribeManager中用户态内存数据。
        SubscribeManager.shared.cleanupTopicMap()
    }

    /// 长链接推送消息分发，负责从宿主App承接推送消息的分发。
    ///
    /// @note: 宿主App接入此方法后，LarkMeegoPush方可用。
    ///
    /// 长链接推送消息分发路径如下:
    ///                                                  Native Push Listener with decoded meegoPushMsg
    ///  App   >   MeegoPushNativeService  >    MeegoPushManager   <
    ///                                                  Flutter Push Listener with original pb payload
    /// - Parameters:
    ///   - meegoPushMsg: pb解析后的消息。
    ///   - payload: 原始推送数据，pb格式。
    @inlinable
    public static func dispatchPush(meegoPushMsg: Meego_MeegoPushMessage, payload: Data) {
        MeegoPushManager.shared.dispatchPush(meegoPushMsg: meegoPushMsg, payload: payload)
    }
}
