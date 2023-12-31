//
//  CountDownInfo.swift
//  ByteViewNetwork
//
//  Created by wulv on 2022/4/26.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// - Videoconference_V1_CountDownInfo
public struct CountDownInfo: Equatable {

    public var lastAction: Action

    /// 倒计时结时间戳,毫秒级
    public var countDownEndTime: Int64

    /// 自然结束时，是否播放提示音
    public var needPlayAudioEnd: Bool

    public var `operator`: ByteviewUser

    /// 倒计时提醒 相对倒计结束时间戳前x秒
    public var remindersInSeconds: [Int64]? = []

    public init(lastAction: Action, countDownEndTime: Int64, needPlayAudioEnd: Bool, `operator`: ByteviewUser, remindersInSeconds: [Int64]?) {
        self.lastAction = lastAction
        self.countDownEndTime = countDownEndTime
        self.needPlayAudioEnd = needPlayAudioEnd
        self.operator = `operator`
        self.remindersInSeconds = remindersInSeconds
    }

    public enum Action: Int, Hashable {
        case unknown // = 0
        /// 设定新倒计时
        case set // = 1
        /// 提前结束
        case endinadvance // = 2
        /// 倒计时界面关闭
        case close // = 3
        /// 延长
        case prolong // = 4
        /// 自然结束
        case end // = 5
        ///PAUSE
//        case pause // = 6  预留暂停
        /// 剩余时间提醒
        case remind = 7
    }
}

extension CountDownInfo: CustomStringConvertible {
    public var description: String {
        String(
            indent: "CountDownInfo",
            "lastAction: \(lastAction)",
            "countDownEndTime: \(countDownEndTime)",
            "needPlayAudioEnd: \(needPlayAudioEnd)",
            "operator: \(`operator`)",
            "remindersInSeconds: \(remindersInSeconds)"
        )
    }
}
