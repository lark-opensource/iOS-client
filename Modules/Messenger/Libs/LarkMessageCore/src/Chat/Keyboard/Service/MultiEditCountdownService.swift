//
//  MultiEditCountdownService.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/8/17.
//

import Foundation
import LarkModel
import LarkMessengerInterface

public final class MultiEditCountdownServiceImpl: MultiEditCountdownService {

    var messageCreateTime: TimeInterval = 0
    var multiEditTimer: Timer?
    var effectiveTime: TimeInterval = 0
    var onNeedToShowTip: (() -> Void)?
    var onNeedToBeDisable: (() -> Void)?
    public func stopMultiEditTimer() {
        multiEditTimer?.invalidate()
        multiEditTimer = nil
    }
    public func startMultiEditTimer(messageCreateTime: TimeInterval,
                             effectiveTime: TimeInterval,
                             onNeedToShowTip: (() -> Void)?,
                             onNeedToBeDisable: (() -> Void)?) {
        self.messageCreateTime = messageCreateTime
        self.onNeedToShowTip = onNeedToShowTip
        self.onNeedToBeDisable = onNeedToBeDisable
        self.effectiveTime = effectiveTime
        self.multiEditTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0,
                                   target: self,
                                   selector: #selector(updateMultiEditCountdown),
                                   userInfo: nil,
                                   repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        timer.fireDate = Date(timeIntervalSince1970: messageCreateTime + effectiveTime - 60)
        self.multiEditTimer = timer
    }

    @objc
    private func updateMultiEditCountdown() {
        //剩余时间
        let timeRemaining = Date(timeIntervalSince1970: .init(messageCreateTime + effectiveTime)).timeIntervalSince(Date())
        if timeRemaining > 60 { return }
        onNeedToShowTip?()
        if timeRemaining < 0 {
            onNeedToBeDisable?()
            multiEditTimer?.invalidate()
            multiEditTimer = nil
        }
    }
}
