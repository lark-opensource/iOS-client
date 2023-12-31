//
//  ServerPrechecker.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/7/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting
import ByteViewTracker

struct PrecheckInfo {
    var meetingId: String?
    var meetingTopic: String?
    var uniqueId: String?
    var vendorType: VideoChatInfo.VendorType?
    var meetingSubtype: MeetingSubType?
    // 入会前precheck时返回的rtc runtime参数，会直接透传给RTC
    var rtcParameter: String?

    var isWebinarAttendee: Bool = false
    var isE2EeMeeting: Bool = false

    var rtcParameterDict: [String: Any]? {
        guard let data = rtcParameter?.data(using: String.Encoding.utf8),
              let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                  return nil
              }
        return dict
    }
}

extension PrecheckBuilder {
    @discardableResult
    func checkServer(entryParams: EntryParams) -> Self {
        checker(ServerPrechecker(entryParams: entryParams))
        return self
    }
}

final class ServerPrechecker: MeetingPrecheckable {
    let entryParams: EntryParams
    var nextChecker: MeetingPrecheckable?

    init(entryParams: EntryParams) {
        self.entryParams = entryParams
    }

    /// precheck接口拦截入会
    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        guard ReachabilityUtil.isConnected else {
            Toast.show(I18n.View_G_NoConnection)
            return
        }
        if idType == .callTargetUser && context.setting.isOnewayRelationshipEnabled == false {
            checkNextIfNeeded(context, completion: completion)
            return
        }

        Toast.hideAllToasts()
        var hud: LarkToast?
        if entryParams.source != .calendarDetails {
            hud = context.service.larkRouter.showLoading(with: I18n.View_VM_Loading, disableUserInteraction: false)
        }
        serverPrecheck(context, hud: hud, completion: completion)
    }

    private func serverPrecheck(_ context: MeetingPrecheckContext, hud: LarkToast?, completion: @escaping PrecheckHandler) {
        Logger.precheck.info("serverPrecheck id: \(isPhoneNumberId ? String(id.hash) : id), idType: \(idType), needInfo: \(needInfo), interviewRole: \(interviewRole)")
        context.httpClient.meeting.precheckJoinMeeting(id: id, idType: idType, needInfo: needInfo,
                                                       interviewRole: interviewRole) { [weak self, weak context] result in
            guard let self = self, let context = context else {
                hud?.remove()
                completion(.failure(EntranceError.sessionReleased))
                return
            }
            switch result {
            case .success(let response):
                if let vcerror = response.checkType.transformedVCError {
                    self.handleFailure(error: vcerror, context: context, hud: hud, completion: completion)
                } else {
                    if self.needInfo {
                        if let videoChatInfo = response.associatedVcInfo.vcInfos.first {
                            context.info.meetingId = videoChatInfo.id
                            context.info.meetingTopic = videoChatInfo.settings.topic
                            context.info.meetingSubtype = videoChatInfo.settings.subType
                        }
                        if let uniqueId = response.associatedVcInfo.uniqueId {
                            context.info.uniqueId = uniqueId
                        }
                    }
                    context.info.vendorType = response.vendorType
                    context.info.rtcParameter = response.rtcParameter
                    context.info.isE2EeMeeting = response.isE2Ee

                    self.handlePrecheckResult(context, hud: hud, completion: completion)
                }
            case .failure(let error):
                // 群入会，如果 precheck 接口报错（网络问题、服务端错误等），走 getAssociatedActiveMeetingID 接口，
                // 查 rust 缓存，尝试找到正在进行中的会议 id，完成入会逻辑
                if self.needInfo && self.idType == .groupid {
                    self.fetchAssociatedMeetingInfo(context, hud: hud, completion: completion)
                } else {
                    self.handleFailure(error: error, context: context, hud: hud, completion: completion)
                }
            }
        }
    }

    private func fetchAssociatedMeetingInfo(_ context: MeetingPrecheckContext, hud: LarkToast?, completion: @escaping PrecheckHandler) {
        let request = GetAssociatedVideoChatStatusRequest(id: id, idType: .groupID)
        context.httpClient.getResponse(request) { [weak self, weak context] result in
            guard let self = self, let context = context else {
                hud?.remove()
                completion(.failure(EntranceError.sessionReleased))
                return
            }
            if let meetingID = result.value?.activeMeetingId {
                context.info.meetingId = meetingID
            }
            self.handlePrecheckResult(context, hud: hud, completion: completion)
        }
    }

    private func handlePrecheckResult(_ context: MeetingPrecheckContext, hud: LarkToast?, completion: @escaping PrecheckHandler) {
        let precheckInfo = context.info
        if idType == .callTargetUser {
            handleSuccess(context, hud: hud, completion: completion)
        } else {
            let isJoinMeeting = precheckInfo.meetingId?.isEmpty == false
            checkNoOtherMeeting(context, isJoinMeeting: isJoinMeeting, hud: hud, completion: completion)
        }
    }

    private func checkNoOtherMeeting(_ context: MeetingPrecheckContext, isJoinMeeting: Bool, hud: LarkToast?,
                                     completion: @escaping PrecheckHandler) {
        if context.isCheckFailure || context.isNoOtherChecking {
            handleSuccess(context, hud: hud, completion: completion)
        } else {
            let idleMeetingChecker = IdleMeetingChecker(identifier: id, isJoin: isJoinMeeting, type: isCall ? .call : .meet, isRejoin: false)
            DispatchQueue.main.async {
                idleMeetingChecker.check(context) { [weak self, weak context] result in
                    guard let self = self, let context = context else {
                        hud?.remove()
                        completion(.failure(EntranceError.sessionReleased))
                        return
                    }
                    switch result {
                    case .success:
                        self.handleSuccess(context, hud: hud, completion: completion)
                    case .failure(let error):
                        self.handleFailure(error: error, context: context, hud: hud, completion: completion)
                    }
                }
            }
        }
    }

    private func handleSuccess(_ context: MeetingPrecheckContext, hud: LarkToast?, completion: @escaping PrecheckHandler) {
        DispatchQueue.main.async {
            hud?.remove()
            self.checkNextIfNeeded(context, completion: completion)
        }
    }

    private func handleFailure(error: Error, context: MeetingPrecheckContext, hud: LarkToast?, completion: @escaping PrecheckHandler) {
        // 会议事件的结束会议报错，须同步rust兜底
        if error.toVCError() == .meetingHasFinished, idType == .meetingid, entryParams.source == MeetingEntrySource(rawValue: "event_card") {
            context.service.httpClient.send(SyncMeetingStatusRequest(meetingID: id))
        }
        DispatchQueue.main.async {
            hud?.remove()
            completion(.failure(error))
        }
    }
}

extension ServerPrechecker {
    private var id: String { entryParams.id }
    private var idType: JoinMeetingPrecheckRequest.IDType {
        if let params = entryParams as? PreviewEntryParams {
            return params.idType.toPrecheckIdType()
        } else if let params = entryParams as? StartCallParams {
            return params.idType == .userId ? .callTargetUser : .reservationID
        } else {
            return .callTargetUser
        }
    }

    private var needInfo: Bool {
        if let params = entryParams as? PreviewEntryParams {
            switch params.idType {
            case .meetingId, .createMeeting:
                return false
            default:
                return true
            }
        } else if let params = entryParams as? StartCallParams {
            return params.idType == .reservationId
        } else {
            return false
        }
    }

    private var interviewRole: ParticipantRole? {
        if let params = entryParams as? PreviewEntryParams, case .interviewUid(let role, _) = params.idType {
            return role
        }
        return nil
    }

    private var isPhoneNumberId: Bool {
        if let params = entryParams as? EnterpriseCallParams {
            return params.idType.isPhoneNumber
        }
        return false
    }

    private var isCall: Bool {
        entryParams is CallEntryParams
    }
}
