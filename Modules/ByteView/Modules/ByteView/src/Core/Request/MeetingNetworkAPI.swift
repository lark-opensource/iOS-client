// swiftlint:disable line_length file_length
//
//  MeetingRequestor.swift
//  ByteView
//
//  Created by kiri on 2020/9/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewCommon
import ByteViewNetwork
import ByteViewMeeting

extension HttpClient {
    var meeting: MeetingNetworkAPI {
        MeetingNetworkAPI(self)
    }
}

final class MeetingNetworkAPI {
    let logger = Logger.network
    let httpClient: HttpClient
    fileprivate init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func livePreCheck(meetingId: String?, meetingNumber: String? = nil, completion: @escaping (Bool) -> Void) {
        httpClient.getResponse(LivePreCheckRequest(meetingId: meetingId, meetingNumber: meetingNumber)) { result in
            switch result {
            case .success(let resp):
                self.logger.info("get live pre check response: \(resp)")
                completion(resp.showPrivacyPolicy)
            case .failure(let error):
                self.logger.info("get live pre check error: \(error)")
                completion(true)
            }
        }
    }

    func precheckJoinMeeting(id: String, idType: JoinMeetingPrecheckRequest.IDType, needInfo: Bool, interviewRole: ParticipantRole?, completion: @escaping (Result<JoinMeetingPrecheckResponse, Error>) -> Void) {
        logger.info("precheck join meeting idType: \(idType)")
        let request = JoinMeetingPrecheckRequest(id: id, idType: idType, needInfo: needInfo, interviewRole: interviewRole)
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let response):
                if response.checkType == .success {
                    self.logger.info("can join meeting \(id.hash) successful")
                } else {
                    self.logger.error("can not join meeting \(id.hash), error = \(response.checkType)")
                }
                completion(.success(response))
            case .failure(let error):
                self.logger.error("precheck join meeting error = \(error)")
                completion(.failure(error))
            }
        }
    }

    func rejoinVideoChat(meetingId: String, forceDeblock: Bool, role: Participant.MeetingRole, isE2EeMeeting: Bool, completion: @escaping (Result<VideoChatAttachedInfo, Error>) -> Void) {
        logger.info("rejoin video chat meetingId: \(meetingId), role: \(role), force: \(forceDeblock)")
        let request = RejoinVideoChatRequest(meetingId: meetingId, force: forceDeblock, role: role, isE2EeMeeting: isE2EeMeeting)
        httpClient.getResponse(request, options: .contextIdCallback({
            JoinTracks.trackRejoinMeetingRequest(contextId: $0, meetingId: meetingId)
        }), completion: { result in
            let r2 = result.flatMap { res -> Result<VideoChatAttachedInfo, Error> in
                switch res.status {
                case .success:
                    if let lobbyInfo = res.lobbyInfo {
                        return .success(.lobbyInfo(lobbyInfo))
                    } else if let info = res.videoChatInfo {
                        return .success(.info(info))
                    } else {
                        return .failure(VCError.unknown)
                    }
                case .vcBusyError:
                    return .failure(VCError.hostIsInVC)
                case .voIpBusyError:
                    return .failure(VCError.hostIsInVOIP)
                case .meetingEndError:
                    return .failure(VCError.meetingHasFinished)
                case .participantLimitExceedError:
                    return .failure(VCError.participantsOverload)
                default:
                    return .failure(VCError.unknown)
                }
            }
            switch r2 {
            case .success(let info):
                self.logger.info("rejoin video chat success, info: \(info)")
            case .failure(let error):
                self.logger.error("rejoin video chat \(meetingId) failed, error: \(error).")
            }
            completion(r2)
        })
    }

    func createVideoChat(_ params: CallEntryParams, completion: @escaping (Result<VideoChatInfo, Error>) -> Void) {
        let id = params.id
        let isVoiceCall = params.isVoiceCall
        let secureChatId: String
        let isE2EeMeeting: Bool
        let reqIdType: CreateCallRequest.IdType

        MeetingTracks.trackCreateVideoChat()

        if let p = params as? StartCallParams {
            secureChatId = p.secureChatId
            isE2EeMeeting = p.isE2EeMeeting
            switch p.idType {
            case .userId:
                reqIdType = .userId
            case .reservationId:
                reqIdType = .reservationId
            }
            logger.info("createVideoChat: params = \(p)")
        } else if let p = params as? EnterpriseCallParams {
            secureChatId = ""
            isE2EeMeeting = false
            switch p.idType {
            case .calleeUserId:
                reqIdType = .directCallUserID
            case .enterprisePhoneNumber:
                reqIdType = .directCallPhoneNumber
            case .ipPhoneNumber:
                reqIdType = .callByIpPhone
            case .recruitmentPhoneNumber:
                reqIdType = .recruitmentPhone
            case .candidateId:
                reqIdType = .directCallCandidate
            }
            logger.info("createVideoChat: params = \(p)")
        } else {
            logger.error("createVideoChat params is error")
            completion(.failure(VCError.unknown))
            return
        }

        let request = CreateCallRequest(id: id, idType: reqIdType, secureChatId: secureChatId, isVoiceCall: isVoiceCall, isE2EeMeeting: isE2EeMeeting)
        httpClient.getResponse(request, options: .contextIdCallback({
            JoinTracks.trackStartCallRequest(contextId: $0, startCallParams: params)
        }), completion: { result in
            switch result {
            case .success(let info):
                self.logger.info("createVideoChat success, info: \(info)")
            case .failure(let error):
                self.logger.error("createVideoChat failed, error: \(error)")
            }
            completion(result)
        })
    }

    func joinInterviewMeeting(params: JoinMeetingParams, completion: @escaping (Result<(VideoChatAttachedInfo?, VCError?), Error>) -> Void) {
        let uniqueId = params.joinType.value
        let request = JoinInterviewMeetingRequest(uniqueId: uniqueId, participantSettings: params.toParticipantSettings(),
                                                  role: params.role, joinedDevicesLeaveInMeeting: params.replaceJoin)
        httpClient.getResponse(request, options: .contextIdCallback({
            JoinTracks.trackJoinMeetingRequest(contextId: $0, params: params)
        }), completion: { result in
            switch result {
            case .success(let res):
                if let lobbyInfo = res.lobbyInfo {
                    self.logger.info("Join interview group meeting success, interviewID: \(uniqueId), role: \(params.role), meetSettings:\(params.meetSetting) success, meetingId: \(lobbyInfo.meetingId), lobby info:\(lobbyInfo).")
                    completion(.success((.lobbyInfo(lobbyInfo), nil)))
                } else if let info = res.videoChatInfo {
                    self.logger.info("Join interview group meeting success, interviewID: \(uniqueId), role: \(params.role), meetSettings:\(params.meetSetting) success, meetingId: \(info.id).")
                    completion(.success((.info(info), nil)))
                } else {
                    self.logger.info("Join interview group meeting  interviewID: \(uniqueId), role: \(params.role), meetSettings:\(params.meetSetting) failed, error: videoChatInfo && lobbyInfo is nil.")
                    completion(.failure(VCError.unknown))
                }
            case .failure(let error):
                self.logger.info("Join interview group meeting  interviewID: \(uniqueId), role: \(params.role), meetSettings:\(params.meetSetting) failed, error: \(error).")
                completion(.failure(error))
            }
        })
    }

    func joinCalendarMeeting(params: JoinMeetingParams, completion: @escaping (Result<(VideoChatAttachedInfo?, VCError?), Error>) -> Void) {
        let uniqueId = params.joinType.value
        logger.debug("join meeting by calendar unique id: \(uniqueId), meetSetting: \(params.meetSetting), instance:\(params.calendarInstance), source: \(params.calendarSource), replace: \(params.replaceJoin)")
        let request = JoinCalendarMeetingRequest(uniqueId: uniqueId, entrySource: params.calendarSource,
                                                 participantSettings: params.toParticipantSettings(),
                                                 targetToJoinTogether: params.targetToJoinTogether,
                                                 calendarInstanceIdentifier: params.calendarInstance,
                                                 joinedDevicesLeaveInMeeting: params.replaceJoin)
        httpClient.getResponse(request, options: .contextIdCallback({
            JoinTracks.trackJoinMeetingRequest(contextId: $0, params: params)
        }), completion: { result in
            switch result {
            case .success(let res):
                if let error = res.type.transformedVCError {
                    self.logger.error("join meeting by calendar unique id: \(uniqueId), biz error: \(error)")
                    completion(.success((nil, error)))
                } else if let info = res.lobbyInfo {
                    self.logger.debug("join meeting by calendar unique id : \(uniqueId), and success lobbyInfo: \(info)")
                    completion(.success((.lobbyInfo(info), nil)))
                } else if let info = res.videoChatInfo {
                    self.logger.debug("join meeting by calendar unique id : \(uniqueId), and success info: \(info)")
                    completion(.success((.info(info), nil)))
                } else {
                    self.logger.error("join meeting by calendar unique id: \(uniqueId), info is nil, type = \(res.type)")
                    completion(.success((nil, VCError.unknown)))
                }
            case .failure(let error):
                self.logger.error("join meeting by calendar unique id: \(uniqueId), error: \(error)")
                completion(.failure(error))
            }
        })
    }

    // join meeting 入会统一接口(针对多人 meetingId meetingNum groupId)
    // https://bytedance.feishu.cn/space/doc/doccnuENDmhTJdou9SGM10#
    // 非 Lobby 调用 joinMeeting, idle -> onthecall,
    // 需要使用 CallCoordinator.requestStartCall, 同步 CallKit 状态
    func joinMeeting(params: JoinMeetingParams, completion: @escaping (Result<(VideoChatAttachedInfo?, VCError?), Error>) -> Void) {
        logger.debug("joinMeeting start, params = \(params)")
        let selfParticipant = JoinMeetingRequest.SelfParticipantInfo(participantType: params.participantType,
                                                                     participantSettings: params.toParticipantSettings())
        let request = JoinMeetingRequest(joinType: params.joinType, selfParticipantInfo: selfParticipant,
                                         topicInfo: params.topicInfo, targetToJoinTogether: params.targetToJoinTogether,
                                         webinarBecomeParticipantOffer: params.webinarAttendeeBecomeParticipant,
                                         isE2EeMeeting: params.isE2EeMeeting, joinedDevicesLeaveInMeeting: params.replaceJoin)
        httpClient.getResponse(request, options: .contextIdCallback({
            JoinTracks.trackJoinMeetingRequest(contextId: $0, params: params)
        }), completion: { result in
            switch result {
            case .success(let res):
                if let vcerror = res.type.transformedVCError {
                    self.logger.error("joinMeeting failed, bizError: \(vcerror)")
                    completion(.success((nil, vcerror)))
                } else if let info = res.lobbyInfo {
                    self.logger.debug("joinMeeting success, lobbyInfo: \(info)")
                    completion(.success((.lobbyInfo(info), nil)))
                } else if let info = res.videoChatInfo {
                    self.logger.debug("joinMeeting success, info: \(info)")
                    completion(.success((.info(info), nil)))
                } else {
                    self.logger.error("joinMeeting failed, info is nil, type = \(res.type)")
                    completion(.success((nil, VCError.unknown)))
                }
            case .failure(let error):
                let vcerror = error.toVCError()
                self.logger.error("joinMeeting failed, joinType: \(params.joinType), error: \(vcerror)")
                completion(.failure(vcerror))
            }
        })
    }

    func updateVideoChat(meetingId: String, action: UpdateVideoChatAction, interactiveId: String?, role: Participant.MeetingRole?,
                         roomId: String? = nil, roomInteractiveId: String? = nil,
                         completion: ((Result<VideoChatAttachedInfo?, Error>) -> Void)? = nil) {
        let logKey = "updateVideoChat(\(meetingId)|\(action))"
        logger.info("\(logKey) start, interactiveID = \(interactiveId ?? ""), roomId = \(roomId ?? ""), roomInteractiveId = \(roomInteractiveId ?? "")")
        var params: LeaveWithSyncRoomParams?
        if let roomId = roomId, !roomId.isEmpty, let roomInteractiveId = roomInteractiveId, !roomInteractiveId.isEmpty {
            params = LeaveWithSyncRoomParams(roomID: roomId, roomInteractiveID: roomInteractiveId)
        }
        let request = UpdateVideoChatRequest(meetingId: meetingId, action: action, interactiveId: interactiveId ?? "", role: role, leaveWithSyncRoom: params)
        httpClient.getResponse(request, options: .contextIdCallback({
            if case .accept = action {
                JoinTracks.trackAcceptCallRequest(contextId: $0)
            }
        }), completion: { (result) in
            switch result {
            case .success(let resp):
                if let info = resp.lobbyInfo {
                    self.logger.info("\(logKey) success, lobbyInfo = \(info).")
                    completion?(.success(.lobbyInfo(info)))
                } else if let info = resp.videoChatInfo {
                    self.logger.info("\(logKey) success, info = \(info).")
                    completion?(.success(.info(info)))
                } else {
                    self.logger.info("\(logKey) success, info = nil.")
                    completion?(.success(nil))
                }
            case .failure(let error):
                self.logger.error("\(logKey) failed, error = \(error).")
                completion?(.failure(error))
            }
        })
    }

    func cancelInviteUser(_ user: ByteviewUser, meetingId: String, role: Participant.MeetingRole) {
        logger.info("cancelInvite video chat, id = \(meetingId), action = cancel, user: \(user)")
        var request = UpdateVideoChatRequest(meetingId: meetingId, action: .cancel, interactiveId: nil, role: role, leaveWithSyncRoom: nil)
        if user.type == .room {
            request.roomIds = [user.id]
        } else if user.type == .sipUser {
            request.pstnIds = [user.id]
        } else {
            request.larkUserIds = [user.id]
        }
        request.users = [ByteviewUser(id: user.id, type: user.type, deviceId: "0")]
        httpClient.send(request) { result in
            self.logger.info("cancelInvite video chat, id = \(meetingId), isSuccess = \(result.isSuccess)")
        }
    }
}

extension ParticipantChangeSettingsRequest {
    init(session: MeetingSession) {
        self.init(meetingId: session.meetingId, breakoutRoomId: session.breakoutRoomId, role: session.myself?.meetingRole ?? .participant)
    }

    init(meeting: InMeetMeeting) {
        self.init(meetingId: meeting.meetingId, breakoutRoomId: meeting.setting.breakoutRoomId, role: meeting.myself.meetingRole)
    }
}
// swiftlint:enable line_length type_body_length file_length
