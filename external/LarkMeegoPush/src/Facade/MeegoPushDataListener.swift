//
//  MeegoPushDataListener.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation

public protocol MeegoPushDataListener {
    /**
     * 订阅成功后，通知业务该订阅的Topic上一次push版本和时间戳
     * 用于本地判断是否需要处理数据同步
     */
    func onTopicVersionAtLastPush(topicName: String, currentVersion: Int, currentTimestamp: Int)

    // 原始推送payload数据，透传到flutter侧。
    func onPushPayload(_ payload: Data)

    // 原始推送payload数据decode后的content等数据，分发到Native侧的订阅者。
    func onPushContentData(_ content: Data, seqID: Int64, timestamp: Int64)
}
