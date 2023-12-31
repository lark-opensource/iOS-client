//
//  MeetingEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/7.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting

protocol PrecheckEntrance {}


class MeetingEntrance<Input: EntryParams, Output>: PrecheckEntrance {
    let params: Input
    let log: Logger = Logger.precheck

    var context: MeetingPrecheckContext

    private lazy var checkBuilder: PrecheckBuilder = {
        var builder = PrecheckBuilder()
        switch params.entryType {
        case .push:
            return builder
        case .rejoin:
            if let p = params as? RejoinParams, p.type == .registerClientInfo {
                builder
                    .checkIdleMeeting(identifier: p.id, isJoin: p.isJoinMeeting, type: p.isCall ? .call : .meet, isRejoin: true)
                    .checkReachConnection()
                    .checkMediaResourcePermission(isNeedAlert: p.isCall, isNeedCamera: false)
            }
            return builder
        case .preview, .noPreview, .call:
            let isVoiceCall = (params as? CallEntryParams)?.isVoiceCall ?? false
            builder
                .checkMediaResourceOccupancy(isJoinMeeting: params.isJoinMeeting)
                .checkIdleMeeting(identifier: params.id, isJoin: params.isJoinMeeting, type: params.isCall ? .call : .meet, isRejoin: false)
                .checkMediaResourcePermission(isNeedAlert: params.isCall, isNeedCamera: !isVoiceCall)
            if let p = params as? PreviewEntryParams, p.idType == .meetingNumber {} else {
                builder
                    .checkServer(entryParams: params)
            }
            if let p = params as? PreviewEntryParams, p.isWebinar, p.isAllowGetWebinarRole {
                builder
                    .checkWebinarRole(params: p)
            }
            return builder
        case .shareToRoom:
            builder
                .checkNoOtherPreview()
            return builder
        }
    }()

    init(params: Input, context: MeetingPrecheckContext) {
        self.params = params
        self.context = context
    }

    func willBeginPrecheck() {}

    func precheck(context: MeetingPrecheckContext, completion: @escaping (Result<Output, Error>) -> Void) {
        self.context = context
        willBeginPrecheck()
        checkBuilder.execute(context) { [weak self] in
            guard let self = self else {
                Self.checkout(context, result: .failure(EntranceError.sessionReleased), completion: completion)
                return
            }
            switch $0 {
            case .success:
                self.precheckSuccess { result in
                    Self.checkout(context, result: result, completion: completion)
                }
            case .failure(let error):
                self.log.info("precheck failed: \(error)")
                self.precheckFailure(error: error)
                Self.checkout(context, result: .failure(error), completion: completion)
            }
        }
    }

    func precheckSuccess(completion: @escaping (Result<Output, Error>) -> Void) {}

    func precheckFailure(error: Error) {}

    /// MeetingEntrance的最终输出口，保证过程中出现的failure一定走此处输出
    static func checkout(_ context: MeetingPrecheckContext, result: Result<Output, Error>, completion: @escaping (Result<Output, Error>) -> Void) {
        if case .failure(let error) = result {
            guard shouldHandleError(error: error) else { return }
            Logger.precheck.error("MeetingEntrance handleFailure error: \(error)")
            JoinMeetingUtil.handleJoinMeetingBizError(service: context.service, error.toVCError())
        }
        completion(result)
    }

    private static func shouldHandleError(error: Error) -> Bool {
        let vcerror = error.toVCError()
        switch vcerror {
        case .hostIsInVC, .userCancelOperation, .hostIsInRinging, .hostBusy, .badNetwork, .micDenied:
            return false
        default:
            if let e = error as? EntranceError, e == .sessionReleased { return false }
            return true
        }
    }
}


final class MeetingPrecheckContext {
    let service: MeetingBasicService
    let slaTracker: SLATracks?

    @RwAtomic
    var info: PrecheckInfo = PrecheckInfo()
    @RwAtomic
    var isCheckFailure: Bool = false
    @RwAtomic
    var isNoOtherChecking: Bool = false

    var sessionId: String { service.sessionId}
    var httpClient: HttpClient { service.httpClient }
    var setting: MeetingSettingManager { service.setting }

    init(service: MeetingBasicService, slaTracker: SLATracks? = nil) {
        self.service = service
        self.slaTracker = slaTracker
    }
}

extension MeetingPrecheckContext {
    var description: String {
        "MeetingPrecheckContext((\(sessionId)))"
    }
}

enum EntranceError: Error {
    case sessionReleased
}
