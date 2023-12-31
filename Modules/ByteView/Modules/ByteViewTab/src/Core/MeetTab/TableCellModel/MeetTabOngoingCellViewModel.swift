//
//  MeetTabOngoingCellViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Action
import RxSwift
import RxCocoa
import ByteViewNetwork

class MeetTabOngoingCellViewModel: MeetTabMeetCellViewModel {

    var joinedDeviceNames: [String] = []

    lazy var meetingObserver = viewModel.dependency.createMeetingObserver()

    override var sortKey: Int64 {
        if isJoined {
            return Int64.max
        } else if let sortKey = Int64(vcInfo.sortKey) {
            return sortKey
        } else {
            Logger.tab.error("read error sortTime: \(vcInfo.sortTime)")
            return 0
        }
    }

    override var cellIdentifier: String {
        return MeetTabHistoryDataSource.ongoingCellIdentifier
    }

    var timingDriver: Driver<String> {
        let startTime: Int64 = Int64(vcInfo.meetingStartTime) ?? vcInfo.sortTime
        return Self.timer.map { _ in
            DateUtil.formatDuration(Date().timeIntervalSince1970 - TimeInterval(startTime), concise: true)
        }
    }

    var meetingNumber: String {
        return "\(I18n.View_MV_IdentificationNo): \(Util.formatMeetingNumber(vcInfo.meetingNumber))"
    }

    var isCurrentMeeting: Bool {
        guard let currentMeetingID = meetingObserver.currentMeeting?.id else { return false }
        return currentMeetingID == vcInfo.meetingID
    }

    var isJoined: Bool {
        guard let meeting = meetingObserver.currentMeeting else { return false }
        return meeting.isOnTheCall && isCurrentMeeting
    }

    var isInLobby: Bool {
        return meetingObserver.currentMeeting?.isInLobby == true && isCurrentMeeting
    }

    /// 正在彩排中
    var isRehearsing: Bool {
        return vcInfo.meetingSubType == .webinar && vcInfo.rehearsalStatus == .on
    }

    private var joinButtonTitle: String {
        if isCurrentMeeting {
            if isInLobby {
                return I18n.View_MV_WaitingRightNow
            } else if isJoined {
                return isRehearsing ? I18n.View_G_Rehearsing : I18n.View_MV_JoinedAlready
            } else {
                return isRehearsing ? I18n.View_G_JoinRehearsal_Button : I18n.View_MV_JoinRightNow
            }
        } else {
            // V5.11 无论是否锁定、是否开启等候室，都展示加入
            return isRehearsing ? I18n.View_G_JoinRehearsal_Button : I18n.View_MV_JoinRightNow
        }
    }

    var joinButtonTitleDriver: Driver<String> {
        meetingObserver.currentMeetingRelay.asDriver()
            .compactMap { [weak self] _ in
                return self?.joinButtonTitle
            }.startWith(joinButtonTitle)
    }

//    var meetingService: MeetingService? { self.viewModel.meetingService }

    func getJoinAction(from: UIViewController) -> CocoaAction {
        CocoaAction { [weak self, weak from] _ in
            guard let self = self, let from = from else { return Observable<()>.empty() }
            if self.isCurrentMeeting {
                MeetTabTracks.trackMeetTabOperation(.clickOngoingJoined)
            } else {
                MeetTabTracks.trackMeetTabOperation(.clickOngoingJoin)
            }
            self.viewModel.router?.joinMeetingById(self.vcInfo.meetingID, topic: self.topic, subtype: self.vcInfo.meetingSubType, from: from)
            return .empty()
        }
    }
}

private extension TabListItem {
    /// 增加位数避免被过滤掉
    var sortKey: String {
        let sortTime = String(sortTime)
        let len = historyID.count - sortTime.count - 1
        guard len > 0 else {
            Logger.tab.error("sortTime is logger than historyID.")
            return "0"
        }
        var result = "9" + sortTime
        for _ in 0..<len {
            result.append("0")
        }
        return result
    }
}
