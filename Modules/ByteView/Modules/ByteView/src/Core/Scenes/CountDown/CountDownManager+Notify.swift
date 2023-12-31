//
//  CountDownManager+Notify.swift
//  ByteView
//
//  Created by wulv on 2022/5/6.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

protocol CountDownManagerObserver: AnyObject {
    /// 倒计时状态变更，时序: countDownTimeChanged > countDownStateChanged
    ///  - state: 状态
    ///  - user: 操作人
    ///  - countDown: 倒计时对象
    func countDownStateChanged(_ state: CountDown.State, by user: ByteviewUser?, countDown: CountDown)
    /// 倒计时剩余时长变更，仅当 state = start 时回调
    ///  - time: 秒，倒数至 0
    ///  - in24HR: 时，分，秒
    ///  - stage: 阶段
    func countDownTimeChanged(_ time: Int, in24HR: (Int, Int, Int), stage: CountDown.Stage)
    /// 倒计时被延长
    ///  - user: 操作人
    func countDownTimeProlonged(by user: ByteviewUser)
    /// 倒计时样式切换(tag/board)
    func countDownStyleChanged(style: CountDownManager.Style)
    /// 倒计时操作权限变更
    /// - canOperate: 可操作
    func countDownOperateAuthorityChanged(_ canOperate: Bool)
    /// 倒计时功能权限变更（是否有倒计时功能、是否展示倒计时入口等）
    /// - enabled: 倒计时可用
    func countDownEnableChanged(_ enabled: Bool)
}

extension CountDownManagerObserver {
    func countDownStateChanged(_ state: CountDown.State, by user: ByteviewUser?, countDown: CountDown) {}
    func countDownTimeChanged(_ time: Int, in24HR: (Int, Int, Int), stage: CountDown.Stage) {}
    func countDownTimeProlonged(by user: ByteviewUser) {}
    func countDownStyleChanged(style: CountDownManager.Style) {}
    func countDownOperateAuthorityChanged(_ canOperate: Bool) {}
    func countDownEnableChanged(_ enabled: Bool) {}
}

extension CountDownManager {

    func addObserver(_ observer: CountDownManagerObserver, fireImmediately: Bool = true) {
        observers.addListener(observer)
        if fireImmediately {
            observer.countDownStateChanged(countDown.state, by: info?.operator, countDown: countDown)
            if let time = countDown.time, let in24HR = countDown.in24HR {
                observer.countDownTimeChanged(time, in24HR: in24HR, stage: countDown.timeStage)
            }
            observer.countDownStyleChanged(style: style)
        }
    }

    func notifyStateChanged(with `operator`: ByteviewUser? = nil) {
        Logger.countDown.debug("notify state: \(countDown.state), user: \(`operator`)")
        observers.forEach {
            $0.countDownStateChanged(countDown.state, by: `operator`, countDown: countDown)
        }
    }

    func notifyTimeChanged() {
        guard let time = countDown.time, let in24HR = countDown.in24HR else {
            Logger.countDown.debug("notify time error, time is nil")
            return
        }
        observers.forEach {
            $0.countDownTimeChanged(time, in24HR: in24HR, stage: countDown.timeStage)
        }
    }

    func notifyProlong() {
        guard let user = info?.operator else {
            Logger.countDown.debug("notify prolong error, operator is nil")
            return
        }
        Logger.countDown.debug("notify prolong by user: \(user)")
        observers.forEach {
            $0.countDownTimeProlonged(by: user)
        }
    }

    func notifyStyleChanged(_ s: CountDownManager.Style) {
        Logger.countDown.debug("notify style changed: \(s)")
        observers.forEach {
            $0.countDownStyleChanged(style: s)
        }
    }

    func notifyCanOperate(_ can: Bool) {
        Logger.countDown.debug("notify can operate: \(can)")
        observers.forEach {
            $0.countDownOperateAuthorityChanged(can)
        }
    }

    func notifyEnabled(_ e: Bool) {
        Logger.countDown.debug("notify enable: \(e)")
        observers.forEach {
            $0.countDownEnableChanged(e)
        }
    }
}
