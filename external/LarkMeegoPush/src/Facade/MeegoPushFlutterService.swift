//
//  MeegoPushFlutterService.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import LarkMeegoLogger

/// LarkMeegoPush面向Flutter侧提供的服务.
/// 通过meego_infra下meego_push插件，向Flutter侧提供Native的能力.
/// 详细可见iOS LarkMeegoPush SDK 说明文档:
/// https://bytedance.feishu.cn/wiki/wikcnLQF4xZYSYhbNlS9s6Eufxe
public final class MeegoPushFlutterService: MeegoPushServiceAbility {

    public static func registerPush(topic: Topic, listener: MeegoPushDataListener) {
        if MeegoPushFlutterService.isFlutterServiceDisable() {
            return
        }

        MeegoLogger.info("[MeegoPushFlutterService][registerPush] TopicName:\(topic.topicName)")

        let topicListenerList = [(topic, listener)]
        MeegoPushManager.shared.batchRegisterPush(topicListenerList: topicListenerList,
                                                  serviceType: .flutter)
    }

    public static func batchRegisterPush(_ topicListenerList: [(Topic, MeegoPushDataListener)]) {
        if MeegoPushFlutterService.isFlutterServiceDisable() {
            return
        }

        MeegoLogger.info("[MeegoPushFlutterService][batchRegisterPush] with \(topicListenerList.count) topics")
        MeegoPushManager.shared.batchRegisterPush(topicListenerList: topicListenerList, serviceType: .flutter)
    }

    public static func unregisterPush(topic: Topic) {
        if MeegoPushFlutterService.isFlutterServiceDisable() {
            return
        }

        MeegoLogger.info("[MeegoPushFlutterService][unregisterPush] TopicName:\(topic.topicName)")
        MeegoPushManager.shared.batchUnregisterPush(topicList: [topic], serviceType: .flutter)
    }

    public static func batchUnregisterPush(topicList: [Topic]) {
        if MeegoPushFlutterService.isFlutterServiceDisable() {
            return
        }

        MeegoLogger.info("[MeegoPushFlutterService][batchUnregisterPush] with \(topicList.count) topics")
        MeegoPushManager.shared.batchUnregisterPush(topicList: topicList, serviceType: .flutter)
    }

    public static func unregisterAllPush() {
        if MeegoPushFlutterService.isFlutterServiceDisable() {
            return
        }

        MeegoLogger.info("[MeegoPushFlutterService] unregisterAllPush")
        MeegoPushManager.shared.unregisterAllPush(serviceType: .flutter)
    }
}

private extension MeegoPushFlutterService {
    static func isFlutterServiceDisable() -> Bool {
        var isServiceDisable = false
        #if DISABLE_LARK_MEEGO_PUSH
        isServiceDisable = true
        MeegoLogger.warn("[MeegoPushFlutterService] is disable for pod subspec config.")
        #endif
        return isServiceDisable
    }
}
