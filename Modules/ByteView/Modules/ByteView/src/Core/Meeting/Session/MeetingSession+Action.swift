//
//  MeetingSessionActions.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting

extension MeetingSession {
    var meetingAcceptTime: CFTimeInterval? { attr(.meetingAcceptTime) }
    var isAcceptRinging: Bool { attr(.isAcceptRinging, false) }

    func leaveAndWaitServerResponse(_ event: MeetingEvent = .userLeave,
                                    file: String = #fileID, function: String = #function, line: Int = #line,
                                    completion: ((Result<Void, Error>) -> Void)? = nil) {
        let event = event.handleMeetingEndManually()
        sendEvent(event, file: file, function: function, line: line) { r in
            switch r {
            case .success(let (from, to)):
                assert(to == .end, "leave event is wrong, \(event.name)")
                self.handleMeetingEnd(from: from, event: event, completion: completion)
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func leave(_ event: MeetingEvent = .userLeave,
               file: String = #fileID, function: String = #function, line: Int = #line,
               completion: ((Result<Void, Error>) -> Void)? = nil) {
        sendEvent(event, file: file, function: function, line: line) { r in
            switch r {
            case .success(let (_, to)):
                assert(to == .end, "leave event is wrong, \(event.name)")
                completion?(.success(Void()))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    /// 处理JoinMeeting/UpdateVideoChat回调
    func sendToMachine(attachedInfo: VideoChatAttachedInfo, file: String = #fileID, function: String = #function, line: Int = #line,
                       completion: ((Result<Void, Error>) -> Void)? = nil) {
        switch attachedInfo {
        case .info(let videoChatInfo):
            sendToMachine(info: videoChatInfo, file: file, function: function, line: line, completion: completion)
        case .lobbyInfo(let lobbyInfo):
            sendToMachine(lobbyInfo: lobbyInfo, file: file, function: function, line: line, completion: completion)
        }
    }

    /// 当lobbyInfo变化时，调用该方法驱动状态机
    func sendToMachine(lobbyInfo: LobbyInfo, file: String = #fileID, function: String = #function, line: Int = #line,
                       completion: ((Result<Void, Error>) -> Void)? = nil) {
        assert(state != .start, "state should greaterThanOrEqualTo premeeting")
        log("didReceiveLobbyInfo", file: file, function: function, line: line)
        if state == .end {
            completion?(.failure(MeetingStateError.ignore))
            return
        }

        let wrapper: (Result<(MeetingState, MeetingState), Error>) -> Void = { completion?($0.map({ _ in Void() })) }
        if let lobbyParticipant = lobbyInfo.lobbyParticipant, lobbyParticipant.user == self.account, lobbyParticipant.isStatusWait {
            log("handle with lobby info", file: file, function: function, line: line)
            sendEvent(.noticeLobby(lobbyInfo), completion: wrapper)
            return
        }

        if let preLobbyParticipant = lobbyInfo.preLobbyParticipant, preLobbyParticipant.user == self.account, preLobbyParticipant.isStatusWait {
            log("handle with prelobby info", file: file, function: function, line: line)
            sendEvent(.noticePreLobby(lobbyInfo), completion: wrapper)
            return
        }

        completion?(.failure(MeetingStateError.invalidInfo))
    }

    /// 当videoChatInfo变化时，调用该方法驱动状态机
    func sendToMachine(info: VideoChatInfo, file: String = #fileID, function: String = #function, line: Int = #line,
                       completion: ((Result<Void, Error>) -> Void)? = nil) {
        assert(state != .start, "state should greaterThanOrEqualTo premeeting")
        log("didReceiveVideoChatInfo", file: file, function: function, line: line)
        if state == .end {
            completion?(.failure(MeetingStateError.ignore))
            return
        }

        guard let myself = info.participant(byUser: self.account) else {
            loge("context is missing, handleVideoChatInfo ignored", file: file, function: function, line: line)
            completion?(.failure(MeetingStateError.missingContext))
            return
        }

        log("handle with info: status = \(myself.status)", file: file, function: function, line: line)
        let wrapper: (Result<(MeetingState, MeetingState), Error>) -> Void = { completion?($0.map({ _ in Void() })) }
        switch myself.status {
        case .calling: // = 1
            sendEvent(.noticeCalling(info), completion: wrapper) // should failed when start
        case .onTheCall: // = 2
            sendEvent(.noticeOnTheCall(info), completion: wrapper)
        case .ringing: // = 3
            sendEvent(.noticeRinging(info), completion: wrapper)
        case .idle: // = 4
            sendEvent(.noticeTerminated(info), completion: wrapper)
        default:
            loge("unexpected status \(myself.status)", file: file, function: function, line: line)
            completion?(.failure(MeetingStateError.unexpectedStatus))
        }
    }

    func acceptRinging(setting: MicCameraSetting, file: String = #fileID, function: String = #function, line: Int = #line,
                       completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.setAttr(CACurrentMediaTime(), for: .meetingAcceptTime)
        self.setAttr(true, for: .isAcceptRinging)
        log("acceptRinging: setting = \(setting)", file: file, function: function, line: line)
        executeInQueue(source: "acceptRinging") {
            if self.state == .ringing {
                self._acceptRinging(setting: setting, myself: self.myself, completion: completion)
            } else if self.state == .preparing, case let .voipPush(pushInfo) = self.meetingEntry {
                self.log("acceptRinging in voipPush preparing: setting = \(setting)", file: file, function: function, line: line)
                self.dualChannelPollVideoChatInfo(pushInfo) { [weak self] r2 in
                    guard let self = self else {
                        completion?(.failure(VCError.unknown))
                        return
                    }
                    self.executeInQueue(source: "acceptRinging.voip") {
                        if self.state == .ringing {
                            self._acceptRinging(setting: setting, myself: self.myself, completion: completion)
                        } else if self.state == .preparing, case let .success(info) = r2 {
                            self._acceptRinging(setting: setting, myself: info.participant(byUser: self.account), completion: completion)
                        } else {
                            completion?(.failure(MeetingStateError.unexpectedStatus))
                        }
                    }
                }
            } else {
                completion?(.failure(MeetingStateError.unexpectedStatus))
            }
        }
        trackUserAccept(setting: setting, file: file, function: function, line: line)
        MeetingTracksV2.startTrack1v1ConnectionDuration()
    }

    private func _acceptRinging(setting: MicCameraSetting, myself: Participant?,
                                file: String = #fileID, function: String = #function, line: Int = #line,
                                completion: ((Result<Void, Error>) -> Void)?) {
        self.localSetting = setting
        if self.isCallKit {
            service?.router.startRoot(CallKitAnsweringBody(session: self, meetSetting: setting))
        }
        var actionSettings = UpdatingParticipantSettings()
        actionSettings.isMicrophoneMuted = !setting.isMicrophoneEnabled
        actionSettings.isCameraMuted = !setting.isCameraEnabled
        actionSettings.cameraStatus = Privacy.videoAuthorized ? .normal : .noPermission
        actionSettings.microphoneStatus = Privacy.audioAuthorized ? .normal : .noPermission
        let action: UpdateVideoChatAction = .accept(actionSettings, isE2EeMeeting)
        self.log("updateVideoChat: \(action)", file: file, function: function, line: line)
        let meetingId = self.meetingId
        let interactiveId = myself?.interactiveId
        let role = myself?.meetingRole
        if isE2EeMeeting {
            self.e2EeToastUtil = E2EeToastUtil(session: self)
            self.e2EeToastUtil?.showE2EeConnectingIfNeed()
        }
        httpClient.meeting.updateVideoChat(meetingId: meetingId, action: action, interactiveId: interactiveId, role: role) { [weak self] result in
            self?.e2EeToastUtil?.removeE2EeConnectingIfNeed()
            self?.e2EeToastUtil = nil
            guard let self = self else {
                completion?(result.map({ _ in Void() }))
                return
            }
            switch result {
            case .success(let info):
                if let info = info {
                    self.log("acceptRinging success: \(action), info = \(info)", file: file, function: function, line: line)
                    self.leavePending()
                    self.sendToMachine(attachedInfo: info, completion: completion)
                } else {
                    self.loge("acceptRinging success: \(action), info is nil", file: file, function: function, line: line)
                    completion?(.success(Void()))
                }
            case .failure(let error):
                self.loge("acceptRinging error: \(action), \(error)", file: file, function: function, line: line)
                self.reportAcceptRingingFailed(error)
                completion?(.failure(error))
            }
        }
    }

    func reportCallingTimeout(file: String = #fileID, function: String = #function, line: Int = #line) {
        log("reportCallingTimeout", file: file, function: function, line: line)
        trackCallingTimeout(file: file, function: function, line: line)
        leave(.callingTimeOut, file: file, function: function, line: line)
    }

    func declineRinging(file: String = #fileID, function: String = #function, line: Int = #line, completion: ((Result<Void, Error>) -> Void)? = nil) {
        log("declineRinging", file: file, function: function, line: line)
        trackUserReject(file: file, function: function, line: line)
        leave(file: file, function: function, line: line, completion: completion)
    }

    /// （非用户原因）接受响铃失败
    func reportAcceptRingingFailed(_ error: Error, file: String = #fileID, function: String = #function, line: Int = #line) {
        log("reportAcceptRingingFailed: \(error)", file: file, function: function, line: line)
        OnthecallReciableTracker.cancelStartOnthecall()
        slaTracker.endEnterOnthecall(success: slaTracker.isSuccess(error: error.toVCError()))
        leave(.serverError(.acceptError(error.toVCError())), file: file, function: function, line: line)
        if let acceptTime = self.meetingAcceptTime, meetType == .meet {
            let timestamp = acceptTime - CACurrentMediaTime() + Date().timeIntervalSince1970
            JoinTracks.trackJoinMeetingFailed(placeholderId: sessionId, error: error, timestamp: timestamp, isFromCallKitRinging: self.isCallKit)
        }
    }

    private func trackUserAccept(setting: MicCameraSetting, file: String = #fileID, function: String = #function, line: Int = #line) {
        let fromSouce = self.isCallKit ? "call_kit" : nil
        switch self.meetType {
        case .call:
            JoinTracks.mergeParamsForKey(.vc_call_accept,
                                         params: [.env_id: sessionId, "accept_type": setting.isCameraEnabled ? "video" : "voice",
                                                  .from_source: fromSouce])
        case .meet:
            JoinTracks.mergeParamsForKey(.vc_meeting_attend,
                                         params: [.env_id: sessionId, .action_name: setting.trackName, "user_type": "attendee",
                                                  .from_source: fromSouce])
        default:
            break
        }
        VCTracker.post(name: .vc_monitor_callee_accept, params: [.env_id: sessionId, .from_source: fromSouce],
                       file: file, function: function, line: line)
    }

    private func trackUserReject(file: String = #fileID, function: String = #function, line: Int = #line) {
        let name: TrackEventName
        switch self.meetType {
        case .call:
            name = .vc_call_page_ringing
        case .meet:
            name = .vc_meeting_page_ringing
        default:
            return
        }
        var params: TrackParams = [.env_id: sessionId, .action_name: "refuse"]
        if self.isPending {
            params[.extend_value] = ["reason": "in_meeting"]
        }
        if self.isCallKit {
            params[.from_source] = "call_kit"
        }
        VCTracker.post(name: name, params: params, file: file, function: function, line: line)
    }

    private func trackCallingTimeout(file: String = #fileID, function: String = #function, line: Int = #line) {
        VCTracker.post(name: .vcex_calling_client_timeout, params: [.env_id: sessionId, "sid": videoChatInfo?.sid], platforms: [.tea, .slardar],
                       file: file, function: function, line: line)
    }
}

extension MeetingSession {
    /// 会议结束后的处理，普通离会时不会block下次入会。
    ///
    /// 若需等待处理完成再进入下一次会议，则需要调用leaveAndWaitServerResponse。
    /// 若要替换为其他处理，则在离会的event传入参数isHandleMeetingEndManually = true，可参考leaveAndWaitServerResponse。
    /// - 通知会议结束到后端
    /// - 更新lastUncompletedMeetingId
    func handleMeetingEnd(from: MeetingState, event: MeetingEvent, completion: ((Result<Void, Error>) -> Void)?) {
        if myself?.status == .idle {
            completion?(.success(Void()))
            return
        }

        // CallKit 被系统拦截，不更新
        if event.name == .filteredByCallKit {
            log("skip updateVideoChatEnd by \(event.name)")
            completion?(.success(Void()))
            return
        }

        /// callback after UpdateVideoChat finished.
        var interactiveId = self.myself?.interactiveId
        var role = self.myself?.meetingRole
        let updateAction: UpdateVideoChatAction
        switch from {
        case .preparing:
            if case .voipPush(let voipInfo) = self.meetingEntry,
               event.name == .userLeave {
                // VoIP 推送响铃，用户点击挂断时状态机可能还在 preparing 状态，需要向后端发送 refuse action
                log("callkit refuse preparing call \(self.meetingId) interactiveID \(voipInfo.interactiveID)")
                interactiveId = voipInfo.interactiveID
                role = voipInfo.role
                updateAction = .refuse
            } else {
                completion?(.success(Void()))
                return
            }
        case .calling:
            updateAction = .cancel
        case .ringing:
            if case .serverBad(.acceptError) = endReason {
                completion?(.success(Void()))
                return
            }
            updateAction = .refuse
        case .lobby, .prelobby:
            updateAction = .leaveLobby
            interactiveId = lobbyInfo?.lobbyParticipant?.interactiveId
        case .onTheCall:
            switch endReason {
            case .streamingSDKBad:
                updateAction = .sdkException
            case .userEnd, .meetingHasFinished:
                updateAction = .end
            case .trialTimeout:
                updateAction = .trialTimeout
            case .autoEnd:
                updateAction = .autoEnd
            case .hangUp(_, let isHoldPstn), .beInterrupted(let isHoldPstn):
                updateAction = isHoldPstn ? .leaveWithoutCallme : .leave
            case .leaveBecauseUnsafe:
                updateAction = .leaveBecauseUnsafe
            default:
                updateAction = .leave
            }
        default:
            completion?(.success(Void()))
            return
        }
        log("updateVideoChatEnd: update = \(updateAction)")
        let meetingId = self.meetingId
        let httpClient = self.httpClient

        // 低端机 CallKit 后台响铃挂断时可能会被系统挂起，导致请求没有发出去
        var bgTaskID: UIBackgroundTaskIdentifier?
        bgTaskID = UIApplication.shared.beginBackgroundTask {
            if let taskID = bgTaskID {
                UIApplication.shared.endBackgroundTask(taskID)
                bgTaskID = nil
            }
        }
        if bgTaskID == .invalid {
            self.log("failed acquiring bgtask")
        }
        let executeBlock: () -> Void = {
            httpClient.meeting.updateVideoChat(meetingId: meetingId, action: updateAction, interactiveId: interactiveId, role: role, roomId: event.roomId, roomInteractiveId: event.roomInteractiveID, completion: {
                completion?($0.map({ _ in Void() }))
                DispatchQueue.main.async {
                    if let taskID = bgTaskID {
                        UIApplication.shared.endBackgroundTask(taskID)
                    }
                }
            })
        }
        if event.shouldDeferRemote {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2), execute: executeBlock)
        } else {
            executeBlock()
        }
    }
}

private extension MeetingAttributeKey {
    static let meetingAcceptTime: MeetingAttributeKey = "vc.meetingAcceptTime"
    static let isAcceptRinging: MeetingAttributeKey = "vc.isAcceptRinging"
}
