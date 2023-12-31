//
//  MeegoPushService.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation

public protocol MeegoPushServiceAbility {
    static func registerPush(topic: Topic, listener: MeegoPushDataListener)

    static func batchRegisterPush(_ topicListenerList: [(Topic, MeegoPushDataListener)])

    static func unregisterPush(topic: Topic)

    static func batchUnregisterPush(topicList: [Topic])

    static func unregisterAllPush()
}
