//
//  InMeetFloatingViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import RxRelay
import ByteViewRtcBridge
import ByteViewSetting

protocol InMeetFloatingViewModelDelegate: AnyObject {
    func didChangeLiving(_ vm: InMeetFloatingViewModel)
    func didChangeRecording(_ vm: InMeetFloatingViewModel)
    func didChangeGridInfo(_ vm: InMeetFloatingViewModel)
    func didChangeTranscribing(_ vm: InMeetFloatingViewModel)
}


struct InMeetFloatingGridInfo: Equatable {
    enum InMeetGridInfoType {
        case video
        case sharedScreen
        case sharedDocument
        case focusVideo
        case whiteBoard
    }

    let sessionId: String
    // 不可直接修改
    let contentParticipant: Participant
    let speakingParticipant: Participant?
    let avatarInfo: AvatarInfo
    let contentName: String
    let speakingName: String?
    let gridType: InMeetGridInfoType
    let sharingDocumentInfo: FollowInfo?    // 当前正在共享的文档信息
    let isMe: Bool
    var isPortraitMode: Bool
    var isConnected: Bool
    var localNetworkStatus: RtcNetworkStatus?  // 本地网络状态
    var remoteNetworkStatus: RtcNetworkStatus?  // 1V1时对端网络状态
    var is1V1: Bool = false
    var isCalling: Bool = false

    var streamKey: RtcStreamKey? {
        switch gridType {
        case .sharedScreen:
            return .screen(uid: rtcUid, sessionId: sessionId)
        case .sharedDocument, .whiteBoard:
            return nil
        case .video, .focusVideo:
            if isMe {
                return .local
            }
            return isPortraitMode ? nil : .stream(uid: rtcUid, sessionId: sessionId)
        }
    }

    var rtcUid: RtcUID {
        contentParticipant.rtcUid
    }


    init(sessionId: String,
         gridType: InMeetGridInfoType,
         contentParticipant: Participant,
         speakingParticipant: Participant?,
         avatarInfo: AvatarInfo,
         contentName: String,
         speakingName: String?,
         isPortraitMode: Bool,
         sharingDocumentInfo: FollowInfo?,
         isConnected: Bool,
         localNetworkStatus: RtcNetworkStatus? = nil,
         remoteNetworkStatus: RtcNetworkStatus? = nil,
         is1V1: Bool = false,
         isMe: Bool,
         isCalling: Bool = false) {
        self.sessionId = sessionId
        self.gridType = gridType
        self.contentParticipant = contentParticipant
        self.speakingParticipant = speakingParticipant
        self.avatarInfo = avatarInfo
        self.contentName = contentName
        self.speakingName = speakingName
        self.isPortraitMode = isPortraitMode
        self.sharingDocumentInfo = sharingDocumentInfo
        self.isConnected = isConnected
        self.localNetworkStatus = localNetworkStatus
        self.remoteNetworkStatus = remoteNetworkStatus
        self.isMe = isMe
        self.is1V1 = is1V1
        self.isCalling = isCalling
    }
}

extension InMeetFloatingGridInfo: CustomStringConvertible {
    var description: String {
        return """
            gridType:\(gridType),
            contentParticipant:\(contentParticipant),
            speakingParticipant:\(speakingParticipant),
            isConnected:\(isConnected),
            localNetworkStatus:\(localNetworkStatus),
            remoteNetworkStatus:\(remoteNetworkStatus),
            isMe:\(isMe),
            is1V1:\(is1V1),
            isCalling:\(isCalling)
            """
    }
}

final class InMeetFloatingViewModel: InMeetDataListener, InMeetActiveSpeakerListener, InMeetRtcNetworkListener, InMeetShareDataListener, InMeetParticipantListener {
    static let logger = Logger.ui
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    let context: InMeetViewContext
    private var isCallConnected = false

    @RwAtomic
    private var lastActiveSpeakers: [RtcUID] = []
    @RwAtomic
    private(set) var gridInfo: InMeetFloatingGridInfo?
    @RwAtomic
    private(set) var isLiving: Bool = false
    @RwAtomic
    private(set) var isTranscribing: Bool = false
    @RwAtomic
    private(set) var isRecording: Bool = false
    private(set) var remoteNetworkStatuses: [RtcUID: RtcNetworkStatus] = [:]
    private var userId: String { meeting.userId }

    @RwAtomic
    var enableSelfAsActiveSpeaker: Bool {
        didSet {
            guard self.enableSelfAsActiveSpeaker != oldValue else {
                return
            }
            updateMeetGridInfo()
        }
    }

    weak var delegate: InMeetFloatingViewModelDelegate?

    let shareWatermark: ShareWatermarkManager
    let miniWindowShareDisabled: Bool

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.resolver = resolver
        self.shareWatermark = resolver.resolve()!
        if meeting.type == .call {
            isCallConnected = meeting.isCallConnected
        }
        self.remoteNetworkStatuses = meeting.rtc.network.remoteNetworkStatuses
        self.enableSelfAsActiveSpeaker = meeting.setting.enableSelfAsActiveSpeaker
        self.miniWindowShareDisabled = meeting.setting.miniWindowShareDisabled

        meeting.rtc.network.addListener(self)
        resolver.resolve(InMeetActiveSpeakerViewModel.self)?.addListener(self)
        meeting.data.addListener(self)
        meeting.shareData.addListener(self)
        meeting.participant.addListener(self)
        meeting.setting.addListener(self, for: .enableSelfAsActiveSpeaker)
    }

    var meetingId: String { meeting.meetingId }
    var breakoutRoom: BreakoutRoomManager? { resolver.resolve(BreakoutRoomManager.self) }

    func resetChatMessage() {
        resolver.resolve(ChatMessageViewModel.self)?.reset()
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if self.isRecording != meeting.data.isRecording {
            self.isRecording = !isRecording
            delegate?.didChangeRecording(self)
        }
        if self.isLiving != meeting.data.isLiving {
            self.isLiving = !isLiving
            delegate?.didChangeLiving(self)
        }
        if self.isTranscribing != meeting.data.isTranscribing {
            self.isTranscribing = !isTranscribing
            delegate?.didChangeTranscribing(self)
        }
        if oldValue == nil {
            /// first receive inMeetingInfo
            switch meeting.type {
            case .meet, .call:
                updateMeetGridInfo()
            default:
                break
            }
        }
    }

    func didUpgradeMeeting(_ type: MeetingType, oldValue: MeetingType) {
        if type == .meet {
            updateMeetGridInfo()
        }
    }

    func didChangeLastActiveSpeaker(_ rtcUid: RtcUID, oldValue: RtcUID?) {
        Util.runInMainThread {
            if self.lastActiveSpeakers.count > 1 {
                self.lastActiveSpeakers.removeLast()
            }
            self.lastActiveSpeakers.insert(rtcUid, at: 0)
            if self.meeting.type == .meet {
                self.updateMeetGridInfo()
            }
        }
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        if meeting.type == .meet {
            updateMeetGridInfo()
        }

        if meeting.isCalleeNoMicAccess() ||
            meeting.participant.otherUIdParticipant?.settings.isMicrophoneMuted == true {
            onUserConnected()
        }
    }

    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput) {
        guard meeting.type == .meet,
              meeting.subType == .webinar,
              meeting.myself.meetingRole != .webinarAttendee else {
            return
        }
        updateMeetGridInfo()
    }

    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {
        guard meeting.type == .meet,
              meeting.isWebinarAttendee else {
            return
        }
        updateMeetGridInfo()
    }

    func didChangeAnotherParticipant(_ participant: Participant?) {
        updateMeetGridInfo()
    }

    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        if status.networkType != .disconnected, status.networkShowStatus == .disconnected {
            return
        }
        updateMeetGridInfo()
    }

    func didChangeRemoteNetworkStatus(_ status: [RtcUID: RtcNetworkStatus], upsertValues: [RtcUID: RtcNetworkStatus], removedValues: [RtcUID: RtcNetworkStatus], reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        self.remoteNetworkStatuses = status
        updateMeetGridInfo()
    }

    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?) {
        if meeting.type == .meet {
            updateMeetGridInfo()
        }
    }

    func onUserConnected() {
        guard !isCallConnected else { return }
        isCallConnected = true
        if meeting.type == .call {
            updateMeetGridInfo()
        }
    }

    private func updateMeetGridInfo() {
        guard let info = meeting.data.inMeetingInfo else {
            Self.logger.error("InMeetingInfo is nil")
            assertionFailure("inMeetingInfo is nil")
            return
        }

        let isConnected = meeting.type != .call || self.isCallConnected
        var speakingParticipant: Participant?

        if meeting.type == .call {
            speakingParticipant = meeting.participant.another
        } else if (context.isHideSelf || !self.enableSelfAsActiveSpeaker) && meeting.myself.settings.isMicrophoneMutedOrUnavailable {
            // 如果『最近的as是自己 && 麦克风mute && 需要隐藏自己』，则nickname也不能是自己
            speakingParticipant = getActiveParticipant(hideSelf: true)
        } else {
            speakingParticipant = getActiveParticipant(hideSelf: false)
        }

        let contentParticipant: Participant?
        var gridType = InMeetFloatingGridInfo.InMeetGridInfoType.video
        var documentInfo: FollowInfo?
        let showShareContent = !context.isShowSpeakerOnMainScreen && !miniWindowShareDisabled
        if showShareContent,
           let shareUser = meeting.shareData.shareContentScene.shareScreenData?.participant,
           shareUser != meeting.account {
            // 如果正在共享屏幕，视频流使用共享屏幕的流
            gridType = .sharedScreen
            documentInfo = nil
            contentParticipant = meeting.participant.find(user: shareUser, in: .activePanels)
            Self.logger.info("floating type is shareScreen, rtcUid = \(contentParticipant?.rtcUid)")
        } else if showShareContent, meeting.shareData.isSharingDocument, let shareUser = meeting.shareData.shareContentScene.magicShareDocument?.user {
            // 小窗共享文档时不显示视频流仅显示文档截图
            gridType = .sharedDocument
            documentInfo = info.followInfo
            contentParticipant = meeting.participant.find(user: shareUser, in: .activePanels)
            Self.logger.info("floating type is shareDocument, shareUser:\(shareUser)")
        } else if let focusingParticipant = meeting.participant.focusing {
            // 如果正在观看焦点视频，则使用焦点视频的流、nickname
            gridType = .focusVideo
            contentParticipant = meeting.participant.find(user: focusingParticipant.user, in: .activePanels)
            if contentParticipant != nil {
                speakingParticipant = nil
            }
            Self.logger.info("floating type is focusVideo, user:\(focusingParticipant.user)")
        } else if showShareContent, meeting.shareData.isSharingWhiteboard, let shareUser = meeting.shareData.shareContentScene.whiteboardData?.sharer {
            gridType = .whiteBoard
            contentParticipant = meeting.participant.find(user: shareUser, in: .activePanels)
            Self.logger.info("floating type is whiteboard, identifer:\(shareUser)")
        } else if context.isHideSelf || !enableSelfAsActiveSpeaker {
            // 隐藏自己时，小窗不能显示自己
            contentParticipant = getActiveParticipant(hideSelf: true)
        } else {
            contentParticipant = speakingParticipant
        }
        guard let contentParticipant = contentParticipant else {
            Self.logger.error("cannot find participant")
            return
        }
        if speakingParticipant?.settings.isMicrophoneMutedOrUnavailable ?? false {
            speakingParticipant = nil
        }

        /// 分组会议以全部参会人为准
        let is1V1 = meeting.participant.global.nonRingingCount == 2
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: [speakingParticipant ?? contentParticipant, contentParticipant],
                                           meetingId: meeting.meetingId) { [weak self] aps in
            guard aps.count >= 2 else { return }
            self?.createGridInfo(gridType: gridType,
                                 contentParticipant: contentParticipant,
                                 speakingParticipant: speakingParticipant,
                                 avatarInfo: aps[1].avatarInfo, //contentParticipant
                                 contentName: aps[1].name, // contentParticipant
                                 speakingName: speakingParticipant != nil ? aps[0].name : nil, // speakingParticipant
                                 documentInfo: documentInfo,
                                 isConnected: isConnected,
                                 is1V1: is1V1,
                                 isCalling: contentParticipant.settings.mobileCallingStatus == .busy)
        }
    }

    // 获取活跃参会人：
    //    - 优先选取当前AS（无人发言时，选取上一个AS）
    //    - 其次选取最早入会者
    //    - 若需要【隐藏自己 && 会中人数大于1】，不会选取自己
    private func getActiveParticipant(hideSelf: Bool) -> Participant? {
        var candidates = meeting.participant.activePanel.nonRingingDict
        let asUID: RtcUID?
        if hideSelf {
            asUID = self.lastActiveSpeakers.first(where: { $0 != meeting.myself.rtcUid })
        } else {
            asUID = self.lastActiveSpeakers.first
        }
        // 会中仅剩自己时，即使隐藏了自己、小窗也需要兜底为自己
        if hideSelf && candidates.count > 1 {
            let myselfUser = meeting.account
            candidates.removeValue(forKey: myselfUser)
        }
        if let uid = asUID,
           let p = candidates.first(where: { $0.value.isSameWith(rtcUid: uid) })?.value {
            return p
        } else {
            let activeParticipant = candidates.min(by: { p0, p1 in p0.value.joinTime < p1.value.joinTime })?.value
            Self.logger.info("participantsInfosCount:\(candidates.count)")
            if let p = activeParticipant {
                Self.logger.info("firstParticipantID:\(p.identifier)")
            }
            return activeParticipant
        }
    }

    private func createGridInfo(gridType: InMeetFloatingGridInfo.InMeetGridInfoType = .video,
                                contentParticipant: Participant,
                                speakingParticipant: Participant?,
                                avatarInfo: AvatarInfo,
                                contentName: String,
                                speakingName: String?,
                                documentInfo: FollowInfo? = nil,
                                isConnected: Bool,
                                is1V1: Bool,
                                isCalling: Bool) {
        let isMe = contentParticipant.user == meeting.account
        let localNetworkStatus = meeting.rtc.network.localNetworkStatus
        var remoteNetworkStatus: RtcNetworkStatus?
        if is1V1 {
            /// 1V1时远端用户状态
            if let user = meeting.participant.otherParticipant {
                remoteNetworkStatus = self.remoteNetworkStatuses[user.rtcUid]
            }
        }

        let gridInfo = InMeetFloatingGridInfo(sessionId: meeting.sessionId,
                                              gridType: gridType,
                                              contentParticipant: contentParticipant,
                                              speakingParticipant: speakingParticipant,
                                              avatarInfo: avatarInfo,
                                              contentName: contentName,
                                              speakingName: speakingName,
                                              isPortraitMode: false,
                                              sharingDocumentInfo: documentInfo,
                                              isConnected: isConnected,
                                              localNetworkStatus: localNetworkStatus,
                                              remoteNetworkStatus: remoteNetworkStatus,
                                              is1V1: is1V1,
                                              isMe: isMe,
                                              isCalling: isCalling)
        changeGridInfo(gridInfo)
    }

    private func changeGridInfo(_ gridInfo: InMeetFloatingGridInfo) {
        if gridInfo != self.gridInfo {
            self.gridInfo = gridInfo
            delegate?.didChangeGridInfo(self)
        }
    }

    lazy var shareScreenVM: InMeetShareScreenVM? = {
        return meeting.shareData.isSharingScreen ? resolver.resolve(InMeetShareScreenVM.self) : nil
    }()

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        Util.runInMainThread { [weak self] in
            self?.context.whiteboardID = newScene.whiteboardData?.whiteboardID
            self?.context.magicShareUrl = newScene.magicShareDocument?.rawUrl
            self?.context.screenShareID = newScene.shareScreenData?.shareScreenID
        }
        updateMeetGridInfo()
    }

}

extension InMeetFloatingViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .enableSelfAsActiveSpeaker {
            Util.runInMainThread {
                self.enableSelfAsActiveSpeaker = isOn
            }
        }
    }
}
