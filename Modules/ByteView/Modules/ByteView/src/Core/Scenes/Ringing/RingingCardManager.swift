//
//  RingingCardManager.swift
//  ByteView
//
//  Created by wangpeiran on 2022/9/16.
//

import Foundation
import ByteViewMeeting
import ByteViewTracker
import ByteViewUI

enum RingingCardType {
    case callInRing       // 1v1响铃
    case callInBusyRing   // 1v1忙线响铃
    case inviteInRing     // 会议邀请响铃
    case inviteBusyRing   // 会议邀请忙线响铃
}

class RingingCardManager {
    static let shared = RingingCardManager()

    static let BusyExtraParamKey = "VCIsBusy"  // pushcard里面extraParams字典里面的key,不可以改变！！
    static let RingingKeyStr = "VC|RingCard|"  // 每个pushcard id的前缀
    static func vcRingingKey(id: String) -> String {
        return Self.RingingKeyStr.appending(id)
    }

    private init() {}

    deinit {}

    func post(meetingId: String, type: RingingCardType) {
        Util.runInMainThread {
            guard let meeting = MeetingManager.shared.findSession(meetingId: meetingId, sessionType: .vc), meeting.videoChatInfo != nil else {
                Logger.ring.error("post failed meetingid: \(meetingId)")
                return
            }
            if self.findSession(meetingId: meeting.meetingId) != nil {
                Logger.ring.error("post card id \(meetingId) is Exist")
                assertionFailure("post card id \(meetingId) is Exist")
                return
            }
            Logger.ring.info("post meeting id: \(meeting.meetingId)")
            self.pushCard(type: type, meeting: meeting)
        }
    }

    func remove(meetingId: String, changeToStack: Bool = false) {
        Util.runInMainThread {
            guard self.findSession(meetingId: meetingId) != nil else {
                Logger.ring.error("remove failed meetingid: \(meetingId)")
                return
            }
            Logger.ring.info("remove meeting id: \(meetingId)")
            RingPlayer.shared.stop()
            PushCardCenter.shared.remove(with: Self.vcRingingKey(id: meetingId), changeToStack: changeToStack)
        }
    }

    func findSession(meetingId: String, isBusy: Bool? = nil) -> String? {
        if let id = PushCardCenter.shared.findPushCard(id: Self.vcRingingKey(id: meetingId), isBusy: isBusy) {
            return id.replacingOccurrences(of: Self.RingingKeyStr, with: "")
        }
        return nil
    }
}

extension RingingCardManager {
    private func pushCard(type: RingingCardType, meeting: MeetingSession) {
        var isBusy = false
        var isFromMeet: Bool = false
        var callViewModel: CallInViewModel?
        var meetViewModel: MeetInViewModel?
        switch type {
        case .callInRing:
            isBusy = false
            isFromMeet = false
            callViewModel = CallInViewModel(meeting: meeting, isBusyRinging: false, viewType: .banner)
        case .callInBusyRing:
            isBusy = true
            isFromMeet = false
            callViewModel = CallInBusyViewModel(meeting: meeting, isBusyRinging: true, viewType: .banner)
        case .inviteInRing:
            isBusy = false
            isFromMeet = true
            meetViewModel = MeetInViewModel(meeting: meeting, isBusyRinging: false, viewType: .banner)
        case .inviteBusyRing:
            isBusy = true
            isFromMeet = true
            meetViewModel = MeetInBusyViewModel(meeting: meeting, isBusyRinging: true, viewType: .banner)
        }
        Logger.ring.info("createCard type: \(type)")

        if !isBusy { // 原来是放在callinVM的init和deinit，但是来2个响铃的时候，会有时序问题，导致第二个的init在第一个的deinit之前
            let pushRingtone = meeting.videoChatInfo?.ringtone
            let ringtone: String?
            if let pushRingtone, !pushRingtone.isEmpty {
                ringtone = pushRingtone
            } else {
                ringtone = meeting.setting?.customRingtone
            }
            RingPlayer.shared.play(.ringing(ringtone))
        }

        //        let callCardView = isFromMeet ? RingingMeetCardView(viewModel: meetViewModel!) : RingingCallCardView(viewModel: callViewModel!)
        var callCardView: UIView
        if isFromMeet {
            if let meetVM = meetViewModel {
                callCardView = RingingMeetCardView(viewModel: meetVM)
            } else { return }
        } else {
            if let callVM = callViewModel {
                callCardView = RingingCallCardView(viewModel: callVM)
            } else { return }
        }

        callViewModel?.doPageTrack()
        meetViewModel?.doPageTrack()

        PushCardCenter.shared.postCard(id: Self.vcRingingKey(id: meeting.meetingId), isHighPriority: true, extraParams: [Self.BusyExtraParamKey: isBusy], view: callCardView) { [weak self] cardable in
            let meetingId = cardable.replacingOccurrences(of: Self.RingingKeyStr, with: "")
            guard self != nil, let session = MeetingManager.shared.findSession(meetingId: meetingId, sessionType: .vc), let info = session.videoChatInfo, session.meetType == .call, session.state == .ringing else {  // 1v1才可以点击全屏
                Logger.ring.info("goto full ringing page failed: \(meeting.meetingId)")
                return
            }
            // 横屏情况下不能放大banner, 因为忙线响铃逻辑当前实现是window add view，不能根据系统控制设备方向,ios 16以后强制转屏方法已失效)
            if VCScene.isPhoneLandscape { // !meeting.setting.canOrientationManually
                Logger.ring.info("goto full ringing page failed isLandscape: \(session.meetingId)")
                return
            }

            RingingCardManager.shared.remove(meetingId: meetingId, changeToStack: true) //进入全屏的时候remove卡片
            Logger.ring.info("goto full ringing page: \(session.meetingId)")
            VCTracker.post(name: .vc_meeting_callee_click, params: [.click: "full_card", "is_callkit": false])

            if type == .callInRing {
                meeting.service?.router.startRoot(CallInBody(session: session, callInType: info.callInType(accountId: session.userId)), animated: true)
            } else if type == .callInBusyRing {
                let vm = CallInBusyViewModel(meeting: session, isBusyRinging: true, viewType: .fullScreen)!
                PromptWindowControllerV2.shared.showVC(vc: CallInViewController(viewModel: vm))
            }
        }
    }
}
