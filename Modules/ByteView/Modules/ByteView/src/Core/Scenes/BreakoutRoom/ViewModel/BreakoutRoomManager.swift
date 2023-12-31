//
//  BreakoutRoomManager.swift
//  ByteView
//
//  Created by wulv on 2021/4/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import RxSwift
import ByteViewUI

protocol BreakoutRoomManagerObserver: AnyObject {
    /// - Parameter info: 用户所在的讨论组，如果为nil表示主会场，或者未开启分组讨论
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?)
    /// 是否开启分组讨论
    func breakoutRoomIsOpenChanged(_ open: Bool)
}

extension BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {}

    func breakoutRoomIsOpenChanged(_ open: Bool) {}
}

final class BreakoutRoomManager {
    let timer: BreakoutRoomTimer
    let transition: TransitionManager
    let broadcast: BroadcastManager
    let hostControl: BreakoutRoomHostControlViewModel
    let meeting: InMeetMeeting
    private(set) var roomInfo: BreakoutRoomInfo?
    @RwAtomic
    private var isOpen: Bool
    private weak var countDownAlert: ByteViewDialog?
    private var lastRTCChannel: String?
    private var shouldToast: Bool = false
    private var hasShownRemainingTimeToast: Bool = false
    private var prevRemainingSeconds: Int = 0
    private var settings: VideoChatSettings.BreakoutRoomSettings? {
        meeting.data.inMeetingInfo?.meetingSettings.breakoutRoomSettings
    }
    private var allBreakoutRooms: [BreakoutRoomInfo] {
        meeting.data.inMeetingInfo?.breakoutRoomInfos ?? []
    }

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.timer = BreakoutRoomTimer(meeting: meeting)
        self.transition = TransitionManager(meeting: meeting)
        self.broadcast = BroadcastManager(meeting: meeting, transition: transition)
        self.hostControl = BreakoutRoomHostControlViewModel(meeting: meeting)
        self.roomInfo = meeting.data.breakoutRoomInfo
        self.isOpen = meeting.data.isOpenBreakoutRoom
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.addMyselfListener(self)
        meeting.push.vcManageResult.addObserver(self)
        meeting.syncChecker.transition = self.transition
        self.transition.addObserver(self)
        self.transition.addObserver(meeting.syncChecker)
        self.timer.addObserver(self)
        if self.isOpen {
            shouldshowToast()
        }
        Logger.breakoutRoom.debug("user first roomInfo: \(self.roomInfo), isOpen: \(self.isOpen)")

        self.addObserver(self.timer)
        self.addObserver(self.broadcast)
    }

    private let observers = Listeners<BreakoutRoomManagerObserver>()

    func addObserver(_ observer: BreakoutRoomManagerObserver, fireImmediately: Bool = true) {
        observers.addListener(observer)
        if fireImmediately {
            observer.breakoutRoomInfoChanged(roomInfo)
            observer.breakoutRoomIsOpenChanged(isOpen)
        }
    }

    func leave() {
        let meetingId = meeting.meetingId
        Logger.breakoutRoom.info("leave breakout room, meetingID = \(meetingId)")
        let request = BreakoutRoomJoinRequest(meetingId: meetingId, toBreakoutRoomId: BreakoutRoom.mainID)
        meeting.httpClient.send(request) { [weak self] in
            if $0.isSuccess {
                Logger.breakoutRoom.info("leave breakout room success, meetingID = \(meetingId)")
                self?.transition.needTransition(.userLeave)
                self?.timer.invalid()
            }
        }
    }

    func join(breakoutRoomID: String) {
        let meetingId = meeting.meetingId
        Logger.breakoutRoom.info("join breakout room, meetingID = \(meetingId), breakoutRoomID = \(breakoutRoomID)")
        let request = BreakoutRoomJoinRequest(meetingId: meetingId, toBreakoutRoomId: breakoutRoomID)
        meeting.httpClient.send(request) { [weak self] in
            if $0.isSuccess {
                Logger.breakoutRoom.info("join breakout room success, meetingID = \(meetingId), breakoutRoomID = \(breakoutRoomID)")
                self?.transition.needTransition(.roomIdChanged(roomId: breakoutRoomID))
            }
        }
    }

    func end() {
        let meetingId = meeting.meetingId
        Logger.breakoutRoom.info("end breakout room, meetingID = \(meetingId)")
        let request = HostManageRequest(action: .breakoutRoomEnd, meetingId: meetingId)
        meeting.httpClient.send(request) {
            if $0.isSuccess {
                Logger.breakoutRoom.info("end breakout room success, meetingID = \(meetingId)")
            }
        }
    }
}

extension BreakoutRoomManager {

    func showAlert(title: String) {
        BreakoutRoomTracks.willStopPopupShow(self.meeting)
        BreakoutRoomTracksV2.willStopPopupShow(self.meeting)
        ByteViewDialog.Builder()
            .id(.breakoutRoomWillEnd)
            .colorTheme(.firstButtonBlue)
            .needAutoDismiss(true)
            .title(title)
            .message(nil)
            .buttonsAxis(.vertical)
            .leftTitle(I18n.View_G_BackToMainRoom)
            .leftHandler({ [weak self] _ in
                guard let self = self else { return }
                BreakoutRoomTracks.willStopPopupLeave(self.meeting)
                BreakoutRoomTracksV2.willStopPopupLeave(self.meeting)
                self.leave()
                self.countDownAlert = nil
            })
            .rightTitle(I18n.View_G_OkButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                self.countDownAlert = nil
                BreakoutRoomTracks.willStopPopupKnow(self.meeting)
                BreakoutRoomTracksV2.willStopPopupKnow(self.meeting)
            })
            .show { [weak self] alert in
                self?.countDownAlert = alert
            }
    }

    private func removeAlert() {
        Util.runInMainThread {
            self.countDownAlert?.dismiss()
            self.countDownAlert = nil
        }
    }

    private func removeAlertIfNeeded() {
        let need = BreakoutRoomUtil.isMainRoom(meeting.myself.breakoutRoomId)
        if need {
            removeAlert()
        }
    }

    private func showInfoToast(_ info: BreakoutRoomInfo) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            var content = I18n.View_G_YouAreInRoomName(info.topic)
            if let remainingTime = self.timer.remainingTime, !self.hasShownRemainingTimeToast {
                self.hasShownRemainingTimeToast = true
                let remainingTimeMinutes = Int(remainingTime) / 60
                if remainingTimeMinutes < 1 {
                    content = I18n.View_G_InRoomTimeRemainLessOne(info.topic)
                } else if remainingTimeMinutes <= 60 {
                    content = I18n.View_G_InRoomTimeRemainMin(info.topic, remainingTimeMinutes)
                } else {
                    content = I18n.View_G_InRoomTimeRemainHrMin(info.topic, remainingTimeMinutes / 60, remainingTimeMinutes % 60)
                }
            }
            Toast.showOnVCScene(content, style: .emphasizePadding(0, keyboard: 0, numberOfLines: 2))
        }
    }

    private func showMainRoomToast() {
        Util.runInMainThread {
            Toast.showOnVCScene(I18n.View_G_YouAreInMainRoom, style: .emphasizePadding(0, keyboard: 0, numberOfLines: 2))
        }
    }

    private func showOpenToast() {
        Util.runInMainThread {
            Toast.show(I18n.View_G_HostOpenedRooms)
        }
    }

    private func shouldshowToast() {
        showOpenToast()
        if !meeting.data.isInBreakoutRoom {
            showMainRoomToast()
        } else if let info = meeting.data.breakoutRoomInfo {
            showInfoToast(info)
        } else {
            shouldToast = true
        }
    }

    private func showToastIfNeeded() {
        guard shouldToast else { return }
        if let info = meeting.data.breakoutRoomInfo {
            showInfoToast(info)
            shouldToast = false
        }
    }

    private func showRejectHelpToast(_ message: VCManageResult) {
        guard message.meetingID == meeting.meetingId, message.type == .breakoutRoomNeedHelp, message.action == .hostreject else { return }
        Util.runInMainThread {
            Toast.show(I18n.View_G_HostBusy)
        }
    }

    private func showHostJoinToast(inserts: [ByteviewUser: Participant]) {
        guard isOpen else { return }
        guard let info = meeting.data.breakoutRoomInfo else { return }
        if !meeting.setting.hasHostAuthority,
           inserts.first(where: { $0.value.meetingRole == .host }) != nil {
            Util.runInMainThread {
                Toast.show(I18n.View_G_HostJoinedRoom(info.topic), style: .normalPadding(0, keyboard: 0, numberOfLines: 2))
            }
        }
    }

    private func updateRTCChannel() {
        if let info = meeting.data.breakoutRoomInfo {
            let channelId = info.channelId
            guard channelId != lastRTCChannel else { return }
            guard !channelId.isEmpty else {
                Logger.breakoutRoom.error("channelID is empty, info = \(info)")
                return
            }
            lastRTCChannel = channelId
            meeting.rtc.engine.joinBreakoutRoom(channelId)
        } else {
            guard lastRTCChannel != nil else { return }
            lastRTCChannel = nil
            meeting.rtc.engine.leaveBreakoutRoom()
        }
    }

    private func updateRoomInfo() {
        if meeting.data.isOpenBreakoutRoom != isOpen {
            isOpen = meeting.data.isOpenBreakoutRoom
            observers.forEach { $0.breakoutRoomIsOpenChanged(isOpen) }
            Logger.breakoutRoom.debug("room isOpen changed: \(isOpen)")
        }
        if meeting.data.breakoutRoomInfo != roomInfo {
            roomInfo = meeting.data.breakoutRoomInfo
            observers.forEach { $0.breakoutRoomInfoChanged(roomInfo) }
            Logger.breakoutRoom.debug("user roomInfo changed: \(roomInfo)")
        }
    }
}

// MARK: - vcManageResult
extension BreakoutRoomManager: VCManageResultPushObserver {

    func didReceiveManageResult(_ result: VCManageResult) {
        showRejectHelpToast(result)
    }
}

// MARK: - InMeetDataListener
extension BreakoutRoomManager: InMeetDataListener {

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        updateRTCChannel()
        showToastIfNeeded()
        updateRoomInfo()
        if !meeting.data.isOpenBreakoutRoom {
            self.hasShownRemainingTimeToast = false
        }
    }
}

extension BreakoutRoomManager: InMeetParticipantListener {
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        let inserts: [ByteviewUser: Participant] = output.modify.nonRinging.inserts
        if !inserts.isEmpty {
            showHostJoinToast(inserts: inserts)
        }
    }
}

extension BreakoutRoomManager: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        updateRTCChannel()
        removeAlertIfNeeded()
        updateRoomInfo()
    }
}

// MARK: - TransitionManagerObserver
extension BreakoutRoomManager: TransitionManagerObserver {

    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        guard !isTransition else { return }
        if let info = info {
            showInfoToast(info)
        } else if isOpen {
            showMainRoomToast()
        }
    }
}

// MARK: - BreakoutRoomTimerObsesrver
extension BreakoutRoomManager: BreakoutRoomTimerObsesrver {
    private func alertTitle(time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason) -> String {
        closeReason == .earlyClose && self.meeting.myself.meetingRole != .host
            ? I18n.View_G_EndBreakOutEarly_Toast(Int(time))
            : I18n.View_G_YouWillLeaveRoomAutomatically(Int(time))
    }

    func breakoutRoomWillEnd(total time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason) {
        Logger.breakoutRoom.info("breakout room will end, closReason = \(closeReason)")
        if let id = meeting.data.breakoutRoomId, !BreakoutRoomUtil.isMainRoom(id) {
            if countDownAlert != nil {
                removeAlert()
            }
            showAlert(title: self.alertTitle(time: time, closeReason: closeReason))
        }
    }

    func breakoutRoomEndTimeDuration(_ time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason) {
        if time <= 0 {
            removeAlert()
            transition.needTransition(.timerEnd)
        } else if let alert = countDownAlert {
            alert.setTitle(text: self.alertTitle(time: time, closeReason: closeReason))
        }
    }

    func breakoutRoomRemainingTime(_ time: TimeInterval?) {
        guard let time = time else { return }
        let remainingSeconds = Int(time)
        defer { prevRemainingSeconds = remainingSeconds }
        // 剩余5分钟弹Toast提示
        if remainingSeconds == 5 * 60 {
            Toast.show(I18n.View_G_FiveEndDiscuss_Toast)
            return
        }
        let isBreakoutRoomOnTheCall = self.allBreakoutRooms.first(where: { $0.status == .onTheCall }) != nil
        if remainingSeconds == 0 && prevRemainingSeconds > 0 && meeting.setting.hasHostAuthority && isBreakoutRoomOnTheCall {
            let showConfirm = self.settings?.notifyHostBeforeFinish ?? false
            if showConfirm {
                self.confirmEnd()
            }
        }
    }

    private func confirmEnd() {
        ByteViewDialog.Builder()
            .id(.breakoutRoomAutoFinish)
            .colorTheme(.followSystem)
            .needAutoDismiss(true)
            .title(I18n.View_G_RoomReachedTimePop)
            .leftTitle(I18n.View_G_ContinueBreakOut_PopUpWindow)
            .leftHandler({ [weak self] _ in
                guard let self = self else { return }
                BreakoutRoomTracksV2.trackAutoFinishConfirmClick(self.meeting, .continue_)
            })
            .rightTitle(I18n.View_G_EndNowBreakout)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                BreakoutRoomTracksV2.trackAutoFinishConfirmClick(self.meeting, .end)
                self.end()
            })
            .show()
    }
}
