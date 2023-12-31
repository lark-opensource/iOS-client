//
//  InMeetAutoEndViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ServerPB
import UIKit
import ByteViewNetwork
import ByteViewUI

final class InMeetAutoEndViewModel {

    @RwAtomic
    private var shouldStartAutoEndCountdown: Bool = false
    @RwAtomic
    private var autoEndCountdownTime: Int64?
    @RwAtomic
    private var lastNoticeTime: Int64?
    @RwAtomic
    private var participantsCount: (Int, Int) = (0, 0) {
        didSet {
            let oldCnt: Int = oldValue.0 + oldValue.1
            let newCnt: Int = participantsCount.0 + participantsCount.1
            if oldCnt == 1, newCnt > 1 {
                shouldStartAutoEndCountdown = false
                cancelCountdownRelay.accept(())
            } else if oldCnt > 1, newCnt == 1 {
                shouldStartAutoEndCountdown = true
            }
        }
    }

    private var canShowAutoEndCountdown: Bool {
        shouldStartAutoEndCountdown &&
        meeting.type == .meet && !meeting.isInterviewMeeting && !meeting.data.isLiving && !meeting.router.isFloating &&
        UIApplication.shared.applicationState == .active
    }

    private var calculatedCountDownDuration: UInt? {
        guard let autoEndCountdownTime = autoEndCountdownTime else {
            return nil
        }
        let currentTime: Int64 = Int64(Date().timeIntervalSince1970)
        var duration: Int64 = autoEndCountdownTime - currentTime
        // 1.计算服务端下发时间
        if duration >= 0 && duration <= 60 { return UInt(duration) }
        // 2.若服务端时间错误则计算客户端时间
        if let lastNoticeTime = lastNoticeTime {
            duration = 60 - currentTime + lastNoticeTime
            if duration >= 0 && duration <= 60 { return UInt(duration) }
            if duration < 0 { return 0 }
        }
        return nil
    }

    private let cancelCountdownRelay = PublishRelay<Void>()
    private lazy var logDescription = metadataDescription(of: self)

    private let meeting: InMeetMeeting
    private let lobby: InMeetLobbyViewModel?

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.lobby = resolver.resolve(InMeetLobbyViewModel.self)
        Logger.ui.debug("init \(logDescription)")
        participantsCount = (meeting.participant.currentRoom.count, lobby?.participants.count ?? 0)
        startObserve()
    }

    deinit {
        Logger.ui.debug("deinit \(logDescription)")
        NotificationCenter.default.removeObserver(self)
    }

    private func startObserve() {
        lobby?.addObserver(self)
        meeting.participant.addListener(self)
        meeting.push.notice.addObserver(self)
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.showAutoEndCountdown()
        }
        meeting.router.addListener(self)
    }

    private func showAutoEndCountdown() {
        guard var duration = calculatedCountDownDuration else { return }
        guard duration != 0 else { // 时长计算为0直接结束
            endMeeting(isAuto: true)
            return
        }
        Util.runInMainThread { [weak self] in
            guard let self = self, self.canShowAutoEndCountdown else { return }
            self.reset()
            ByteViewDialog.Builder()
                .id(.autoEnd)
                .colorTheme(.redLight)
                .title(I18n.View_MV_MeetingEndSingleMember_PopUpTitle)
                .message(I18n.View_MV_SingleMemberSetEnd_PopUpExplain)
                .leftTitle(I18n.View_MV_StayMeeting_PopUpButton)
                .leftHandler({ _ in self.keepMeeting() })
                .rightTitle(I18n.View_MV_EndMeetingTimer_PopUpButton(duration))
                .rightHandler({ _ in self.endMeeting(isAuto: duration <= 1) })
                .rightType(.autoCountDown(
                    duration: duration,
                    updator: {
                        duration = $0
                        return I18n.View_MV_EndMeetingTimer_PopUpButton(duration)
                    }
                ))
                .needAutoDismiss(true)
                .show { [weak self] alert in
                    if let self = self {
                        self.cancelCountdownRelay.take(1).subscribe(onNext: { [weak alert] in
                            alert?.dismiss()
                        }).disposed(by: alert.rx.disposeBag)
                    }
                }
        }
    }

    private func keepMeeting() {
        meeting.httpClient.send(KeepMeetingRequest(meetingId: meeting.meetingId))
    }

    private func endMeeting(isAuto: Bool) {
        if isAuto {
            meeting.leave(.autoEnd)
        } else {
            InMeetLeaveAction.endMeeting(meeting: meeting)
        }
    }

    private func reset() {
        autoEndCountdownTime = nil
        lastNoticeTime = nil
        shouldStartAutoEndCountdown = false
    }
}

extension InMeetAutoEndViewModel: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        showAutoEndCountdown()
    }
}

extension InMeetAutoEndViewModel: InMeetParticipantListener, InMeetLobbyViewModelObserver {

    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        participantsCount.0 = output.sumCount
    }

    func didChangeLobbyParticipants(_ participants: [LobbyParticipant]) {
        participantsCount.1 = participants.count
    }
}

extension InMeetAutoEndViewModel: VideoChatNoticePushObserver {
    func didReceiveNotice(_ notice: VideoChatNotice) {
        guard notice.type == .popup,
              notice.meetingID == meeting.meetingId,
              notice.popupType == .popupMeetingEndConfirm else { return }
        autoEndCountdownTime = notice.meetingEndTime
        lastNoticeTime = Int64(Date().timeIntervalSince1970)
        showAutoEndCountdown()
    }
}
