//
//  InMeetBillingViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewSetting

final class InMeetBillingViewModel: MeetingComplexSettingListener {
    static let logger = Logger.ui
    let meeting: InMeetMeeting
    private let tips: InMeetTipViewModel?
    private var setting: BillingSetting

    // 计费相关的数据绑定
    init(meeting: InMeetMeeting, tips: InMeetTipViewModel?) {
        self.meeting = meeting
        self.tips = tips
        self.setting = meeting.setting.billingSetting
        updateBillingSetting(setting)
        meeting.setting.addComplexListener(self, for: .billingSetting)

        // 每秒执行一次倒计时tips显示/隐藏/更新逻辑
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] (t) in
            if let self = self {
                self.updateBillingTimer(t)
            } else {
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
    }

    private static let startCountDownDuration: Int = 10 * 60 // 还剩十分钟时开始倒计时（单位秒）
    var meetingId: String { meeting.meetingId }

    private let billingInfo = BillingTimeOutInfo()
    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        guard key == .billingSetting, let setting = value as? BillingSetting else { return }
        updateBillingSetting(setting)
    }

    private func updateBillingSetting(_ setting: BillingSetting) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            // 更新会议倒计时数据
            if let countdown = setting.countdownDuration {
                let duration = Int(countdown) * 60
                if self.billingInfo.countDownDuration != duration {
                    self.billingInfo.countDownDuration = duration
                    Self.logger.info("[Billing] countDownDuration changed to \(duration)")
                }
            }
            self.setting = setting
        }
    }

    private class BillingTimeOutInfo {
        // 用于启动和维护会议倒计时提示
        var countDownDuration: Int = 24 * 60 * 60
        var shouldHandleTimeout: Bool = true
    }

    // 超时提醒tipsInfo
    var timeoutNoticeTipInfo: TipInfo?

    private func updateBillingTimer(_ timer: Timer) {
        // 1v1不需要提示
        guard !meeting.isEnd else { return }
        if setting.isInsufficientOfRemainingTime {
            // 计算会议剩余时间
            let timeLeft = billingInfo.countDownDuration - Int(Date().timeIntervalSince(meeting.startTime)) + 1
            if timeLeft >= 0 {
                billingInfo.shouldHandleTimeout = true
            }
            if timeLeft < 0 {
                if billingInfo.shouldHandleTimeout {
                    // countDownDuration控制倒计时，maxVideochatDuration控制会议结束时间，两个值可能不一样。如果倒计时归零了
                    // maxVideochatDuration还没到，那就弹toast “好消息已为你解除时长上限”
                    // maxVideochatDuration到了，就直接结束会议
                    // 会议超时的那一刻，主持人“toast提醒”或者“结束会议”
                    if billingInfo.countDownDuration < setting.maxVideochatDuration * 60 {
                        Toast.show(I18n.View_G_TimeLimitRemoved, type: .warning, duration: 3)
                        // 保证仅弹一次toast
                        billingInfo.shouldHandleTimeout = false
                    } else {
                        self.meeting.leave(.trialTimeout(planType: setting.planType, isFree: true))
                    }
                }
            } else if timeLeft <= Self.startCountDownDuration {
                // 在倒计时范围内，显示/更新倒计时tips
                // 之前手动关闭过，则不再展示
                if self.timeoutNoticeTipInfo?.hasBeenClosedManually == true {
                    return
                }
                // 构造倒计时tips
                let info = self.createTimeoutTipInfo(timeLeft: timeLeft)
                // 如果被其它tips覆盖，则不再展示倒计时tips、直到当前tips被关闭
                if let tips = self.tips {
                    tips.showTipInfo(info)
                }
                self.timeoutNoticeTipInfo = info
                return
            }
        }

        // 其余情况，尝试关闭会议超时提醒tips
        self.tips?.closeTipFor(type: .maxDurationLimit)
        self.timeoutNoticeTipInfo = nil
    }

    private func createTimeoutTipInfo(timeLeft: Int) -> TipInfo {
        let minute = timeLeft / 60
        let second = timeLeft % 60
        let timeLeftString = String(format: "%02d:%02d", minute, second)
        let (content, range) = self.getTimeoutTipsContent(timeLeft: timeLeftString)
        let digitRange = (content as NSString).range(of: timeLeftString)
        let info = TipInfo(content: content,
                           iconType: .warning,
                           type: .maxDurationLimit,
                           isFromNotice: false,
                           highLightRange: range,
                           scheme: meeting.setting.billingLinkConfig.upgradeLink,
                           digitRange: digitRange)
        return info
    }

    private func getTimeoutTipsContent(timeLeft: String) -> (String, NSRange?) {
        // 自己是管理员，并且会议是自己所租户发起
        if meeting.setting.isSuperAdministrator, meeting.info.tenantId == meeting.myself.tenantId {
            var content = I18n.View_G_UpgradePlanToExtendLimit(timeLeft)
            let array = content.components(separatedBy: "@@")
            var range: NSRange?
            if array.count >= 3 {
                content = content.replacingOccurrences(of: "@@\(array[1])@@", with: array[1])
                range = NSRange(location: array[0].count, length: array[1].count)
            }
            return (content, range)
        } else if meeting.myself.isHost {
            return (I18n.View_M_EndInTimeBraces(timeLeft), nil)
        } else {
            //非主持人支持提示 “会议即将到达免费时长上限，将于 {{time}} 后结束”
            return (I18n.View_G_MeetingEndingNoMoreFree(timeLeft), nil)
        }
    }
}
