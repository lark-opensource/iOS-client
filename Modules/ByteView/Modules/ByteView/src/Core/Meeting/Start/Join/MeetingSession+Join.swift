//
//  MeetingSession+Join.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation
import AVFoundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI

struct JoinMeetingResult {
    let info: VideoChatAttachedInfo?
    let bizError: VCError?
}

extension MeetingSession {
    var joinMeetingParams: JoinMeetingParams? {
        get { attr(.joinMeetingParams, type: JoinMeetingParams.self) }
        set { setAttr(newValue, for: .joinMeetingParams) }
    }

    func joinMeeting(_ params: JoinMeetingParams, leaveOnError: Bool, completion: @escaping (Result<JoinMeetingResult, Error>) -> Void) {
        assert(state == .preparing, "joinMeeting failed, current state is \(state)")
        self.setAttr(params, for: .joinMeetingParams)
        self.isE2EeMeeting = params.isE2EeMeeting ?? false
        // 创建VideoChatInfo的请求发送过程中先暂停notifyVideoChat的推送，以防创建多余的session
        JoinMeetingQueue.shared.suspend()
        let logTag = self.description
        let requestType = params.requestType
        self.log("joinMeeting, params = \(params)")
        let httpClient = self.httpClient
        callCoordinator.requestStartCall(action: {
            switch requestType {
            case .default:
                httpClient.meeting.joinMeeting(params: params, completion: $0)
            case .interview:
                httpClient.meeting.joinInterviewMeeting(params: params, completion: $0)
            case .calendar:
                httpClient.meeting.joinCalendarMeeting(params: params, completion: $0)
            }
        }, completion: { [weak self] (result: Result<(VideoChatAttachedInfo?, VCError?), Error>) in
            defer {
                JoinMeetingQueue.shared.resume()
                completion(result.map({ JoinMeetingResult(info: $0, bizError: $1) }))
            }

            guard let self = self else {
                Logger.meeting.error("\(logTag) joinMeeting failed: MeetingSession is nil")
                return
            }
            switch result {
            case .success(let (attachedInfo, vcerror)):
                if let info = attachedInfo {
                    self.localSetting = params.meetSetting
                    self.handleJoinedResponse(info, type: requestType.toJoinMeetingMessageType())
                } else if let error = vcerror {
                    self.loge("joinMeeting failed: bizError = \(error)")
                    if leaveOnError {
                        self.leave()
                    } else {
                        self.forceReportCallKitEndCall()
                    }
                }
            case .failure(let error):
                self.loge("join meeting failed: error = \(error)")
                if leaveOnError {
                    self.leave()
                } else {
                    self.forceReportCallKitEndCall()
                }
            }
        })
    }

    /// 重新入会
    func rejoinMeeting(forceDeblock: Bool, meetingRole: ParticipantMeetingRole, leaveOnError: Bool, completion: @escaping (Result<VideoChatAttachedInfo, VCError>) -> Void) {
        // 创建VideoChatInfo的请求发送过程中先暂停notifyVideoChat的推送，以防创建多余的session
        JoinMeetingQueue.shared.suspend()
        let meetingId = self.meetingId
        let logTag = self.description
        let httpClient = self.httpClient
        let isE2EeMeeting = self.isE2EeMeeting
        if isE2EeMeeting {
            self.e2EeToastUtil = E2EeToastUtil(session: self)
            self.e2EeToastUtil?.showE2EeConnectingIfNeed()
        }
        callCoordinator.requestStartCall(action: {
            httpClient.meeting.rejoinVideoChat(meetingId: meetingId, forceDeblock: forceDeblock, role: meetingRole, isE2EeMeeting: isE2EeMeeting, completion: $0)
        }, completion: { [weak self] result in
            defer {
                JoinMeetingQueue.shared.resume()
                self?.e2EeToastUtil?.removeE2EeConnectingIfNeed()
                self?.e2EeToastUtil = nil
                completion(result.mapError({ $0.toVCError() }))
            }

            guard let self = self else {
                Logger.meeting.warn("\(logTag) rejoinMeeting failed: MeetingSession is nil")
                return
            }

            switch result {
            case .success(let info):
                self.log("rejoinMeeting success")
                self.handleJoinedResponse(info, type: .rejoin)
            case .failure(let error):
                self.loge("rejoinMeeting failed: error = \(error)")
                if leaveOnError {
                    self.leave()
                } else {
                    self.forceReportCallKitEndCall()
                }
            }
        })
    }

    func forceReportCallKitEndCall() {
        // leaveOnError = false 入会失败了，如果不上报 callkit 结束当前的 call，会导致后续一直无法入会
        // https://bytedance.feishu.cn/wiki/wikcn5FMVBLGOGAU1H1WMHbe4OF
        self.loge("joinMeeting failed: force end callkit call. meeting_id:\(meetingId), session:\(sessionId)")
        callCoordinator.reportCallEnded(reason: .failed)
    }
}

extension MeetingSession {
    @discardableResult
    func handleJoinedResponse(_ info: VideoChatInfo, type: JoinMeetingMessageType) -> Bool {
        if !info.checkMyself(self.account) {
            Toast.show(I18n.View_M_FailedToJoinMeeting)
            return false
        }
        return _handleJoinedResponse(info, type: type)
    }

    @discardableResult
    func handleJoinedResponse(_ attachedInfo: VideoChatAttachedInfo, type: JoinMeetingMessageType) -> Bool {
        if !checkMyself(attachedInfo) {
            Toast.show(I18n.View_M_FailedToJoinMeeting)
            self.leave()
            return false
        }

        switch attachedInfo {
        case .info(let videoChatInfo):
            return _handleJoinedResponse(videoChatInfo, type: type)
        case .lobbyInfo(let lobbyInfo):
            if let another = MeetingManager.shared.findAnotherSessionOrSet(meetingId: lobbyInfo.meetingId, current: self) {
                self.loge("checkJoinedResponse with lobbyInfo failed: another session found: \(another)")
                another.sendToMachine(lobbyInfo: lobbyInfo)
                self.leave()
                return false
            }
            self.log("checkJoinedResponse with lobbyInfo success")
            self.sendToMachine(lobbyInfo: lobbyInfo) { [weak self] in
                if let self = self, case .failure = $0 {
                    self.leave()
                    Toast.show(I18n.View_M_FailedToJoinMeeting)
                }
            }
            return true
        }
    }

    @discardableResult
    private func _handleJoinedResponse(_ info: VideoChatInfo, type: JoinMeetingMessageType) -> Bool {
        if let another = MeetingManager.shared.findAnotherSessionOrSet(meetingId: info.id, current: self) {
            self.loge("checkJoinedResponse with info failed: another session found: \(another)")
            JoinMeetingQueue.shared.send(JoinMeetingMessage(info: info, type: type, sessionId: another.sessionId))
            if case .shareToRoom = self.meetingEntry, isShareScreen {
                another.autoShareScreen = true
            }
            return false
        }
        self.log("checkJoinedResponse with info success")
        // heartBeatStopped 客户端离会，后端认为客户端依然在会中，会返回相同的 interactive_id
        MeetingTerminationCache.shared.removeTerminations(by: info.id)
        self.sendToMachine(info: info) {
            if case .failure = $0 {
                Toast.show(I18n.View_M_FailedToJoinMeeting)
            }
        }
        return true
    }


    private func checkMyself(_ attachedInfo: VideoChatAttachedInfo) -> Bool {
        switch attachedInfo {
        case .info(let videoChatInfo):
            return videoChatInfo.checkMyself(self.account)
        case .lobbyInfo(let lobbyInfo):
            let account = self.account
            if let lobby = lobbyInfo.lobbyParticipant, lobby.user == account, lobby.isStatusWait {
                return true
            }
            if let lobby = lobbyInfo.preLobbyParticipant, lobby.user == account, lobby.isStatusWait {
                return true
            }
            self.loge("[\(lobbyInfo.meetingId)] checkMyself failed, account = \(account)")
            return false
        }
    }
}

private extension MeetingManager {
    /// 根据meetingId和当前session的type查询其他的session，如果没找到，则赋值meetingId给当前的session
    /// - returns: 返回找到的另一个session
    func findAnotherSessionOrSet(meetingId: String, current: MeetingSession) -> MeetingSession? {
        if current.meetingId == meetingId {
            return nil
        }
        if let session = findSession(meetingId: meetingId, sessionType: current.sessionType) {
            return session
        } else {
            current.meetingId = meetingId
            return nil
        }
    }
}

private extension JoinMeetingParams.RequestType {
    func toJoinMeetingMessageType() -> JoinMeetingMessageType {
        switch self {
        case .default:
            return .join
        case .calendar:
            return .joinCalendar
        case .interview:
            return .joinInterview
        }
    }
}

private extension MeetingAttributeKey {
    static let joinMeetingParams: MeetingAttributeKey = "vc.joinMeetingParams"
}
