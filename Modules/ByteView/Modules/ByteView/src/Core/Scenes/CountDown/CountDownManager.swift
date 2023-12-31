//
//  CountDownManager.swift
//  ByteView
//
//  Created by wulv on 2022/4/26.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting
import ByteViewUI

final class CountDownManager {
    typealias NoPermissonReason = CountdownSetting.NoPermissonReason
    enum Style {
        case tag
        case board
    }
    private(set) var style: Style = .tag
    private(set) var countDown = CountDown()
    private var timer: Timer?
    private(set) var info: CountDownInfo?
    private let player: RtcAudioPlayer
    /// 同一次倒计时，结束音频是否播放过
    private var isEndAudioPlayed: Bool = false
    /// 是否为初始状态（初始状态为自然结束时，不播放音频）
    private var isDefaultState: Bool?
    /// 同一次倒计时，剩余提醒音频是否播放过
    private var isRemindAudioPlayed: Bool = false
    /// 是否有操作倒计时的权限
    @RwAtomic private(set) var canOperate: (Bool, NoPermissonReason?) = (false, nil)
    /// 操作权限生效条件：参会人个数超过阈值
    private(set) var operateLimitCount: Int32 = 0
    /// 是否有倒计时功能
    private(set) var enabled: Bool

    let observers = Listeners<CountDownManagerObserver>()

    private var nonRingingCount: Int
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    var httpClient: HttpClient { meeting.httpClient }
    private lazy var db = CountDownDatabase(storage: meeting.storage)
    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.info = meeting.data.inMeetingInfo?.countDownInfo
        self.player = RtcAudioPlayer(meeting: meeting)
        self.enabled = meeting.setting.isCountdownEnabled
        self.nonRingingCount = meeting.participant.global.nonRingingCount
        self.canOperate = hasOperateAuthority()
        updateCountDownIfNeeded()
        updateStyleIfNeeded()
        meeting.data.addListener(self, fireImmediately: false)
        meeting.shareData.addListener(self, fireImmediately: false)
        meeting.participant.addListener(self, fireImmediately: false)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.setting.addListener(self, for: .isCountdownEnabled)
        meeting.setting.addComplexListener(self, for: .countdownSetting)
        context.addListener(self, for: .horizontalSizeClass)
    }

    deinit {
        invalidTimer()
    }

    /// 倒计时状态
    var state: CountDown.State {
        countDown.state
    }

    /// 倒计时面板展示时的状态(展开 or 收起）
    var boardFolded: Bool {
        if Display.phone {
            return true
        }
        return db.foldBoard
    }

    /// 展开 or 收起倒计时面板
    func foldBoard(_ fold: Bool) {
        VCTracker.post(name: .vc_countdown_click, params: [.click: "change_type", "target_type": fold ? "tag" : "panel"])
        db.foldBoard = fold
        updateStyleIfNeeded()
        showFoldGuide(fold)
    }
}

extension CountDownManager {

    private func updateCountDownIfNeeded() {
        guard let info = info else {
            Logger.countDown.debug("info is nil")
            return
        }

        if isDefaultState == nil {
            isDefaultState = true
        } else {
            isDefaultState = false
        }

        switch info.lastAction {
        case .unknown:
            // 向前兼容，跳过未知事件
            return
        case .set: // 设置 or 重设
            if let time = caculateLastTime(countDownEnd: info.countDownEndTime) {
                isEndAudioPlayed = false
                isRemindAudioPlayed = false
                invalidTimer()
                updateEverHasHourIfNeeded(time > 60 * 60)
                updateLastTimeIfNeeded(time)
                updateStateIfNeeded(.start)
                setupTimer()
            }
        case .prolong: // 延长
            if let time = caculateProlongedTime(info.countDownEndTime) {
                isRemindAudioPlayed = false
                invalidTimer()
                updateEverHasHourIfNeeded(time > 60 * 60)
                updateLastTimeIfNeeded(time)
                updateStateIfNeeded(.start)
                setupTimer()
            }
        case .remind: // 剩余时间提醒
            playRemindAudioIfNeeded()
        case .endinadvance: // 提前结束
            invalidTimer()
            updateLastTimeIfNeeded(0)
            updateStateIfNeeded(.end(isPre: true))
        case .end: // 自然结束
            invalidTimer()
            updateLastTimeIfNeeded(0)
            updateStateIfNeeded(.end(isPre: false))
            if isDefaultState == false {
                playEndAudioIfNeeded()
            }
        case .close: // 关闭
            invalidTimer()
            updateLastTimeIfNeeded(0)
            updateStateIfNeeded(.close)
        }
    }

    private func updateStateIfNeeded(_ state: CountDown.State) {
        if state != countDown.state {
            countDown.state = state
            notifyStateChanged(with: info?.operator)
        }
    }

    private func updateLastTimeIfNeeded(_ time: Int) {
        guard time != countDown.time else {
            Logger.countDown.debug("ignore same last time update")
            return
        }
        Logger.countDown.debug("update last time: \(time)")
        countDown.time = time
        notifyTimeChanged()
    }

    private func updateEverHasHourIfNeeded(_ everHasHour: Bool) {
        if everHasHour != countDown.everHasHour {
            countDown.everHasHour = everHasHour
        }
    }

    private func caculateLastTime(countDownEnd: Int64) -> Int? {
        // 倒计时剩余时长 = 倒计时结束时间戳 - 会议开始时间戳(原始) - 会议时长
        // 会议时长 = 当前时间 - 会议开始时间戳（已校准）
        let serverMeetingStart = meeting.info.startTime // 原始
        let localMeetingStart = meeting.startTime // 已校准
        guard serverMeetingStart > 0, countDownEnd > serverMeetingStart else {
            Logger.countDown.debug("caculate last time error, serverMeetingStart: \(serverMeetingStart), localMeetingStart: \(localMeetingStart), countDownEnd: \(countDownEnd)")
            return nil
        }
        let meetingDuration = Date().timeIntervalSince(localMeetingStart) // s
        let gap = countDownEnd - serverMeetingStart // ms
        let last = ceil(TimeInterval(gap / 1000) - meetingDuration)
        return Int(last)
    }

    private func caculateProlongedTime(_ newEnd: Int64) -> Int? {
        let newTime = caculateLastTime(countDownEnd: newEnd)
        let lastTime = countDown.time
        if newTime == lastTime {
            Logger.countDown.debug("ignore same prolong time update")
            return nil
        }
        if let lastTime = lastTime {
            if let newTime = newTime, newTime < lastTime {
                Logger.countDown.debug("update prolong error, newEnd: \(newEnd), lastTime: \(lastTime), newTime: \(newTime)")
                return nil
            }
        }
        return newTime
    }

    private func setupTimer() {
        Util.runInMainThread {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] t in
                guard let self = self, let time = self.countDown.time else {
                    t.invalidate()
                    return
                }

                if time > 0 {
                    self.countDown.time = time - 1
                    self.notifyTimeChanged()

                    if let last = self.info?.remindersInSeconds?.first, time == Int(last) {
                        Logger.countDown.debug("timer remind")
                        self.playRemindAudioIfNeeded()
                    }
                } else {
                    Logger.countDown.debug("timer end natural")
                    t.invalidate()
                    self.updateStateIfNeeded(.end(isPre: false))
                    self.playEndAudioIfNeeded()
                }
            })
        }
    }

    private func invalidTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func playEndAudioIfNeeded() {
        // 「端上倒计时结束」或「服务端推end」，任一事件先到需播放，后到的不播放
        if info?.needPlayAudioEnd == true, !isEndAudioPlayed {
            isEndAudioPlayed = true
            guard enabled else {
                Logger.countDown.debug("ignore play end audio by enabled(false)")
                return
            }
            guard !meeting.audioDevice.output.isMuted else {
                Logger.countDown.debug("ignore play end audio by audio output is muted")
                return
            }
            player.play(.countDownEnd) { isSuccess in
                if !isSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        Toast.show(I18n.View_G_PlayChimeNoCountdown)
                    }
                }
            }
        }
    }

    private func playRemindAudioIfNeeded() {
        // 「端上倒计时剩余X分钟」或「服务端推remind」，任一事件先到需播放，后到的不播放
        if !isRemindAudioPlayed {
            isRemindAudioPlayed = true
            guard enabled else {
                Logger.countDown.debug("ignore play remind audio by enabled(false)")
                return
            }
            if let last = self.info?.remindersInSeconds?.first {
                Toast.show(I18n.View_G_CountdownRemainNum(last / Int64(60)))
            }
            guard !meeting.audioDevice.output.isMuted else {
                Logger.countDown.debug("ignore play remind audio by audio output is muted")
                return
            }
            player.play(.countDownRemind) { isSuccess in
                if !isSuccess {
                    Logger.countDown.info("play remind audio fail")
                }
            }
        }
    }

    private func hasOperateAuthority() -> (Bool, NoPermissonReason?) {
        let setting = meeting.setting.counddownSetting
        self.operateLimitCount = setting.permissionThreshold
        return meeting.setting.counddownSetting.canOperate(participantCount: nonRingingCount,
                                                           isSharer: meeting.shareData.isSelfSharingContent)
    }

    private func ifOperateAuthorityChange() {
        let old = canOperate
        let new = hasOperateAuthority()
        canOperate = new
        if old.0 != new.0 { notifyCanOperate(new.0) }
    }

    private func showFoldGuide(_ fold: Bool) {
        guard fold, meeting.service.shouldShowGuide(.countDownUnfold) else { return }
        let guide = GuideDescriptor(type: .countDownFold, title: nil, desc: I18n.View_G_CountdownHere_Hover)
        guide.style = .plain
        guide.sureAction = { [weak self] in
            self?.meeting.service.didShowGuide(.countDownUnfold)
        }
        GuideManager.shared.request(guide: guide)
    }

    private func updateStyleIfNeeded() {
        let newStyle: Style
        if Display.phone
            || VCScene.rootTraitCollection?.horizontalSizeClass == .compact
            || boardFolded {
            newStyle = .tag
        } else {
            newStyle = .board
        }
        if newStyle != style {
            style = newStyle
            notifyStyleChanged(newStyle)
        }
    }
}

extension CountDownManager: InMeetParticipantListener {
    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        nonRingingCount = output.counts.nonRinging
        ifOperateAuthorityChange()
    }
}

extension CountDownManager: InMeetDataListener {

    /// inMeetingInfo变化，由CombinedInfo的推送触发
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if inMeetingInfo.countDownInfo != info {
            info = inMeetingInfo.countDownInfo
            updateCountDownIfNeeded()
        } else {
            Logger.countDown.debug("ignore same combinedInfo changed")
        }
    }
}

extension CountDownManager: InMeetShareDataListener {

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        ifOperateAuthorityChange()
    }

}

extension CountDownManager: InMeetingChangedInfoPushObserver {

    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        guard data.meetingID == meeting.meetingId else { return }
        if data.type == .inMeetingCountdown, data.countDownInfo?.lastAction == .prolong {
            notifyProlong()
        }
    }
}

extension CountDownManager: MeetingSettingListener, MeetingComplexSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isCountdownEnabled {
            self.enabled = isOn
            notifyEnabled(isOn)
        }
    }

    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        if key == .countdownSetting {
            ifOperateAuthorityChange()
        }
    }
}

extension CountDownManager: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .horizontalSizeClass {
            updateStyleIfNeeded()
        }
    }
}

extension CountdownSetting.NoPermissonReason {
    var message: String {
        switch self {
        case .webinarAttendee: return I18n.View_G_AttendeesNoThisOperate
        case .overCount(let n): return I18n.View_G_ManyPeopleCountdownSet(n)
        }
    }
}
