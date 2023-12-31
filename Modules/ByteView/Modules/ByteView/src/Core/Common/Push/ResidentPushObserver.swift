//
//  ResidentPushObserver.swift
//  ByteView
//
//  Created by kiri on 2021/6/21.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewMeeting

/// 常驻的Push接收器，用来主动驱动其他服务
public final class ResidentPushObserver {
    public static let shared = ResidentPushObserver()

    private init() {}

    public func didReceiveNotice(_ notice: VideoChatNotice, httpClient: HttpClient) {
        NoticeService.shared.handlePushMessage(notice, httpClient: httpClient)
    }

    public func didReceiveInterviewQuestionnaire(_ info: InterviewQuestionnaireInfo, dependency: InterviewQuestionnaireDependency) {
        Logger.push.info("didReceiveInterviewQuestionnaire : info = \(info)")
        if info.meetingID == "" || info.expireTime <= 0 {
            InterviewQuestionnaireWindow.show(info, dependency: dependency)
            return
        }
        if Date().timeIntervalSince1970 > info.expireTime {
            Logger.push.info("interview questionnaire expired. ignore it")
            return
        }
        if let meeting = MeetingManager.shared.currentSession, meeting.userId == dependency.userId, meeting.state != .end {
            if meeting.meetingId != info.meetingID {
                Logger.push.info("interview questionnaire doest not belong to current meeting, ignore it")
                return
            }
            Logger.push.info("ongoing meeting found, delay displaying interview questionnaire")
            meeting.interviewQuestionnaireInfo = info
            return
        }
        InterviewQuestionnaireWindow.show(info, dependency: dependency)
    }
}
