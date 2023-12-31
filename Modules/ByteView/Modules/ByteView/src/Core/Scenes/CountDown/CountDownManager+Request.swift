//
//  CountDownManager+Request.swift
//  ByteView
//
//  Created by wulv on 2022/5/6.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

extension CountDownManager {

    /// 开启/重设倒计时
    func requestStart(with duration: Int64, remindersInSeconds: [Int64]?, playEndAudio: Bool, callback: ((Bool) -> Void)? = nil) {
        Logger.countDown.debug("request start, duration: \(duration), remindersInSeconds: \(remindersInSeconds), playEndAudio: \(playEndAudio)")
        let request = OperateMeetingCountDownRequest(meetingID: meeting.meetingId, action: .set, playEndAudio: playEndAudio, duration: duration, remindersInSeconds: remindersInSeconds)
        httpClient.send(request) { result in
            switch result {
            case .success:
                callback?(true)
                Logger.countDown.debug("request start success")
            case .failure(let error):
                callback?(false)
                Logger.countDown.warn("request start error: \(error)")
            }
        }
    }

    /// 延长倒计时
    func requestProlong(with duration: Int64) {
        Logger.countDown.debug("request prolong, duration: \(duration)")
        let request = OperateMeetingCountDownRequest(meetingID: meeting.meetingId, action: .prolong, duration: duration)
        httpClient.send(request) { result in
            switch result {
            case .success:
                Logger.countDown.debug("request prolong success")
            case .failure(let error):
                Logger.countDown.warn("request prolong error: \(error)")
            }
        }
    }

    /// 提前结束倒计时
    func requestPreEnd() {
        Logger.countDown.debug("request preEnd")
        let request = OperateMeetingCountDownRequest(meetingID: meeting.meetingId, action: .endInAdvance)
        httpClient.send(request) { result in
            switch result {
            case .success:
                Logger.countDown.debug("request preEnd success")
            case .failure(let error):
                Logger.countDown.warn("request preEnd error: \(error)")
            }
        }
    }

    /// 关闭倒计时
    func requestClose() {
        Logger.countDown.debug("request close")
        let request = OperateMeetingCountDownRequest(meetingID: meeting.meetingId, action: .close)
        httpClient.send(request) { result in
            switch result {
            case .success:
                Logger.countDown.debug("request close success")
            case .failure(let error):
                Logger.countDown.warn("request close error: \(error)")
            }
        }
    }
}
