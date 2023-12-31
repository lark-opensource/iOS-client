//
//  PreviewEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/7.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting

struct PreviewEntranceOutputParams {
    let previewViewParams: PreviewViewParams
    let vendorType: VideoChatInfo.VendorType?
    let rtcParameterDict: [String: Any]?
    let isE2EeMeeting: Bool
    let tracker: PreviewEntryTracker
}

final class PreviewEntrance: MeetingEntrance<PreviewEntryParams, PreviewEntranceOutputParams> {

    lazy var tracker: PreviewEntryTracker = {
        PreviewEntryTracker(sessionId: context.sessionId, slaTracker: context.slaTracker ?? SLATracks(.default))
    }()

    private var isStartMeetingFromGroup: Bool { params.idType == .groupId }

    override func willBeginPrecheck() {
        if !isStartMeetingFromGroup {
            tracker.start(params, isHost: params.idType == .createMeeting)
        }
    }

    override func precheckSuccess(completion: @escaping (Result<PreviewEntranceOutputParams, Error>) -> Void) {
        if isStartMeetingFromGroup {
            tracker.start(params, isHost: context.info.meetingId == nil)
        }
        if isStartMeetingFromGroup {
            if let meetingId = context.info.meetingId {
                handleWithMeetingId(meetingId, context: context, completion: completion)
            } else {
                handleWithUniqueId(context.info.uniqueId, context: context, completion: completion)
            }
        } else {
            let precheckInfo = context.info
            let entryParams = params
            switch params.idType {
            case .createMeeting:
                let service = context.service

                let accountName = service.accountInfo.userName
                service.httpClient.participantService.participantInfo(pid: service.account, meetingId: "") { ap in
                    let displayName = ap.user?.displayName ?? accountName
                    let topic = I18n.View_G_MeetingTopicUserNameFill(displayName)
                    let isLTR = topic.hasSuffix(I18n.View_G_MeetingTopicUserNameFill(""))
                    let previewViewParams = entryParams.toPreviewViewParams(topic: topic, isLTR: isLTR, isJoinMeeting: false, isWebinarAttendee: precheckInfo.isWebinarAttendee)
                    let output = PreviewEntranceOutputParams(previewViewParams: previewViewParams, vendorType: precheckInfo.vendorType, rtcParameterDict: precheckInfo.rtcParameterDict, isE2EeMeeting: entryParams.isE2EeMeeting, tracker: self.tracker)
                    completion(.success(output))
                }
            default:
                let previewViewParams = entryParams.toPreviewViewParams(topic: params.topic, isJoinMeeting: params.isJoinMeeting, isWebinarAttendee: precheckInfo.isWebinarAttendee)
                let output = PreviewEntranceOutputParams(previewViewParams: previewViewParams, vendorType: precheckInfo.vendorType, rtcParameterDict: precheckInfo.rtcParameterDict, isE2EeMeeting: precheckInfo.isE2EeMeeting, tracker: tracker)
                completion(.success(output))
            }
        }
    }

    // MARK: - 处理来自群组的会议
    private func handleWithMeetingId(_ meetingId: String, context: MeetingPrecheckContext, completion: @escaping (Result<PreviewEntranceOutputParams, Error>) -> Void) {
        JoinTracks.trackMeetingEntry(sessionId: context.sessionId, source: self.params.source.rawValue)
        let precheckInfo = context.info
        let topic = precheckInfo.meetingTopic ?? I18n.View_G_ServerNoTitle
        let isWebinar = precheckInfo.meetingSubtype == .webinar
        let previewViewParams = params.toGroupPreviewViewParams(with: meetingId, topic: topic, isWebinar: isWebinar)
        let output = PreviewEntranceOutputParams(previewViewParams: previewViewParams, vendorType: precheckInfo.vendorType, rtcParameterDict: precheckInfo.rtcParameterDict, isE2EeMeeting: precheckInfo.isE2EeMeeting, tracker: tracker)
        completion(.success(output))
    }

    private func handleWithUniqueId(_ uniqueId: String?, context: MeetingPrecheckContext, completion: @escaping (Result<PreviewEntranceOutputParams, Error>) -> Void) {
        let entryParams = params
        let precheckInfo = context.info
        fetchChatInfo(context: context) { [weak self] result in
            guard let self = self else {
                Logger.precheck.error("PreviewEntrance is released, handleWithUniqueId ignored")
                Self.checkout(context, result: .failure(EntranceError.sessionReleased), completion: completion)
                return
            }
            switch result {
            case .success(let (groupName, isCalendarChat)):
                JoinTracks.trackMeetingEntry(sessionId: context.sessionId, source: self.params.source.rawValue, isHost: true)
                if isCalendarChat {
                    self.handleCalendarChat(uniqueId, groupName: groupName, context: context, completion: completion)
                } else {
                    let topic = I18n.View_G_MeetingTopicChatNameFill(groupName)
                    let isLTR = topic.hasSuffix(I18n.View_G_MeetingTopicChatNameFill(""))
                    let previewViewParams = entryParams.toPreviewViewParams(topic: topic, isLTR: isLTR, isJoinMeeting: false, isWebinarAttendee: false)
                    let output = PreviewEntranceOutputParams(previewViewParams: previewViewParams, vendorType: precheckInfo.vendorType, rtcParameterDict: precheckInfo.rtcParameterDict, isE2EeMeeting: entryParams.isE2EeMeeting, tracker: self.tracker)
                    completion(.success(output))
                }
            case .failure(let error):
                Self.checkout(context, result: .failure(error), completion: completion)
            }
        }
    }

    private func handleCalendarChat(_ uniqueId: String?, groupName: String, context: MeetingPrecheckContext, completion: @escaping (Result<PreviewEntranceOutputParams, Error>) -> Void) {
        let precheckInfo = context.info
        if let uniqueId = uniqueId, !uniqueId.isEmpty {
            let request = GetAssociatedVideoChatRequest(id: uniqueId, idType: .uniqueID, needTopic: true)
            context.httpClient.getResponse(request) { [weak self] result in
                guard let self = self else {
                    Self.checkout(context, result: .failure(EntranceError.sessionReleased), completion: completion)
                    return
                }
                switch result {
                case .success(let info):
                    let topic = info.topic.isEmpty ? I18n.View_G_ServerNoTitle : info.topic
                    let previewViewParams = self.params.toCalendarGroupPreviewViewParams(with: uniqueId, topic: topic, isJoinMeeting: false, isWebinar: false)
                    let output = PreviewEntranceOutputParams(previewViewParams: previewViewParams, vendorType: precheckInfo.vendorType, rtcParameterDict: precheckInfo.rtcParameterDict, isE2EeMeeting: self.params.isE2EeMeeting, tracker: self.tracker)
                    completion(.success(output))
                case .failure(let error):
                    Logger.precheck.error("[\(self.context.sessionId)] getCalendarTopic failied")
                    Self.checkout(context, result: .failure(error), completion: completion)
                }
            }
        } else {
            let topic = groupName.isEmpty ? I18n.View_G_ServerNoTitle : groupName
            let previewViewParams = params.toPreviewViewParams(topic: topic, isJoinMeeting: false, isWebinarAttendee: false)
            let output = PreviewEntranceOutputParams(previewViewParams: previewViewParams, vendorType: precheckInfo.vendorType, rtcParameterDict: precheckInfo.rtcParameterDict, isE2EeMeeting: self.params.isE2EeMeeting, tracker: self.tracker)
            completion(.success(output))
        }
    }

    private func fetchChatInfo(context: MeetingPrecheckContext, completion: @escaping (Result<(String, Bool), Error>) -> Void) {
        context.service.messenger.fetchChatInfo(by: params.id) { result in
            Util.runInMainThread {
                switch result {
                case .success(let (name, isCalendarChat)):
                    completion(.success((name, isCalendarChat)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

final class PreviewEntryTracker {
    let sessionId: String
    let slaTracker: SLATracks
    @RwAtomic var isStarted: Bool = false
    var source: String = ""
    var joinType: EntryIdType = .createMeeting

    init(sessionId: String, slaTracker: SLATracks) {
        self.sessionId = sessionId
        self.slaTracker = slaTracker
        PreviewReciableTracker.startEnterPreview()
        slaTracker.startEnterPreview()
    }

    func start(_ params: PreviewEntryParams, isHost: Bool) {
        self.isStarted = true
        self.source = params.source.rawValue
        self.joinType = params.idType
        JoinTracks.trackMeetingEntry(sessionId: sessionId, source: source, isHost: isHost)
        if joinType == .meetingNumber {
            JoinTracksV2.trackMeetingEntry(sessionId: sessionId, source: source)
        }
    }

    func onError(_ error: Error) {
        PreviewReciableTracker.cancelStartPreview()
        slaTracker.endEnterPreview(success: slaTracker.isSuccess(error: error.toVCError()))
        guard isStarted else { return }
        JoinTracks.trackMeetingEntryFailed(sessionId: sessionId, source: source, error: error)
    }
}
