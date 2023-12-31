//
//  StartCallEntry.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/7/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewMeeting

extension MeetingPrechecker {
    func handleStartCallEntry(_ session: MeetingSession, params: StartCallParams, completion: @escaping PrecheckOutput) {
        guard let service = session.service else { return }
        log.info("handleStartCallEntry start, params = \(params)")
        let context = MeetingPrecheckContext(service: service, slaTracker: session.slaTracker)
        let entrance = StartCallEntrance(params: params, context: context)  // CallEntrance<StartCallParams>
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success(let params):
                completion(.success(.call(params)))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }

    func handleEnterpriseCallEntry(_ session: MeetingSession, params: EnterpriseCallParams, completion: @escaping PrecheckOutput) {
        guard let service = session.service else { return }
        log.info("handleEnterpriseCallEntry start, params = \(params)")
        let context = MeetingPrecheckContext(service: service, slaTracker: session.slaTracker)
        let entrance = EnterpriseCallEntrance(params: params, context: context)
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success(let params):
                completion(.success(.enterpriseCall(params)))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
}

extension MeetingSession {
    func startCall(_ entryParams: CallEntryParams, extraInfo: CallEntranceOutputParams) {
        self.log("startCall success, info = \(entryParams)")
        self.sendEvent(.userStartCall(params: entryParams)) { [weak self] r2 in
            guard let self = self, r2.isSuccess else { return }
            self.isE2EeMeeting = extraInfo.isE2EeMeeting
            self.createCall(entryParams)
        }
    }

    private func createCall(_ params: CallEntryParams) {
        // 创建VideoChatInfo的请求发送过程中先暂停notifyVideoChat的推送，以防创建多余的session
        JoinMeetingQueue.shared.suspend()
        let sessionId = self.sessionId
        let account = self.account
        let logger = Logger.meeting.withContext(sessionId).withTag(self.description)
        self.log("createCall, callEntryParams = \(params)")
        let httpClient = self.httpClient
        callCoordinator.requestStartCall(action: {
            httpClient.meeting.createVideoChat(params, completion: $0)
        }, completion: { [weak self] result in
            switch result {
            case .success(let info):
                if let self = self {
                    // 先赋值meetingId，以防通过推送创建新的session
                    self.meetingId = info.id
                    if self.state == .dialing {
                        // 正常情况下都应该走到这里
                        self.log("createCall success")
                        self.sendToMachine(info: info)
                        MeetingManager.shared.sessions.forEach { session in
                            if session.meetingId == info.id && session.sessionId != self.sessionId {
                                // 有其他的session，比如同时接到了对方的ringing，此时应该结束这些session
                                self.log("leave duplicated session by createCall: \(session)")
                                session.leave(.forceExit.handleMeetingEndManually())
                            }
                        }
                    } else {
                        self.loge("createCall success, but session is invalid")
                        info.cancelCallOnCreate(sessionId: sessionId, account: account, logger: logger)
                        assertionFailure("unexpectedState after createCall")
                    }
                } else {
                    logger.error("createCall failed: session is released")
                    info.cancelCallOnCreate(sessionId: sessionId, account: account, logger: logger)
                }
            case .failure(let e):
                let error = e.toVCError()
                logger.error("createCall failed: error = \(error)")
                MeetingTracks.trackCreateVideoChatFailed(placeholderId: sessionId, error: error, isVoiceCall: params.isVoiceCall)
                if let self = self {
                    self.leave(.serverError(.createVCError(error)))
                }
            }
            JoinMeetingQueue.shared.resume()
        })
    }
}

private enum CallPrecheckError: Error {
    case missingPrecheckInfo
}

private extension VideoChatInfo {
    /// 用于CreateCall请求返回时，session就被释放的场景或校验出错的场景
    func cancelCallOnCreate(sessionId: String, account: ByteviewUser, logger: Logger,
                            file: String = #fileID, function: String = #function, line: Int = #line) {
        // 会议已经因为其它原因结束了，不再调用leave
        // 更新结束标记
        MeetingTerminationCache.shared.updatePlaceholder(sessionId, info: self, account: account)
        // 补发取消请求
        let interactiveId = participants.first(where: { $0.user == account })?.interactiveId
        logger.warn("[\(id)] cancelCallOnCreate, interactiveId = \(interactiveId ?? "<nil>")", file: file, function: function, line: line)
        let role = self.participants.first(withUser: account)?.meetingRole
        let httpClient = HttpClient(userId: account.id)
        httpClient.meeting.updateVideoChat(meetingId: self.id, action: .cancel, interactiveId: interactiveId, role: role) { result in
            if let info = result.value??.videoChatInfo {
                JoinMeetingQueue.shared.send(JoinMeetingMessage(info: info, type: .join, sessionId: sessionId))
            }
        }
    }
}
