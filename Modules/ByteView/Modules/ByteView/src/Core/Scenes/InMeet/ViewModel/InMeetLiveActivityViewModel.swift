//
//  InMeetLiveActivityViewModel.swift
//  ByteView
//
//  Created by shin on 2023/2/16.
//
#if swift(>=5.7.1)
import ByteViewCommon
import ByteViewNetwork
import ByteViewWidget
import ByteViewWidgetService
import Foundation

/// 灵动岛和 Live Activity 使用
@available(iOS 16.1, *)
final class InMeetLiveActivityViewModel {
    static let logger = Logger.getLogger("LiveActivity")
    static let maxRetryCount = 3

    let resolver: InMeetViewModelResolver
    let context: InMeetViewContext
    private let meeting: InMeetMeeting
    private var meetingType: ByteViewNetwork.MeetingType
    private var liveActivityID: String?
    private var speaker: String?
    private var networkStatus: RtcNetworkStatus.NetworkShowStatus?
    private lazy var remoteNetworkStatuses: [String: RtcNetworkStatus] = [:]
    private var lastActiveSpeaker: String?
    private var avatarURL: URL?
    private var avatarInfo: AvatarInfo?
    private var meetingTopic: String?

    @RwAtomic
    private var participantRetryCnt: Int = 0 {
        didSet {
            Self.logger.warn("fetch participant info failed \(participantRetryCnt)")
            if participantRetryCnt < Self.maxRetryCount {
                // nolint-next-line: magic number
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                    self?.update1v1Participant()
                }
            } else {
                updateLiveActivity()
            }
        }
    }

    var widgetMeetingType: ByteViewWidget.MeetingType {
        var widgetMeetingType: ByteViewWidget.MeetingType
        switch meetingType {
        case .unknown:
            widgetMeetingType = .unknown
        case .call:
            widgetMeetingType = meeting.info.isVoiceCall ? .vocie : .video
        case .meet:
            widgetMeetingType = .meet
        @unknown default:
            widgetMeetingType = .unknown
        }
        return widgetMeetingType
    }

    var widgetTopic: String {
        var topic: String
        switch meetingType {
        case .call:
            topic = meeting.info.isVoiceCall ? I18n.View_G_VoiceCalling : I18n.View_G_VideoCalling
        case .unknown, .meet:
            topic = currentMeetingTopic
        @unknown default:
            topic = currentMeetingTopic
        }
        return topic
    }

    var widgetSpeaker: String {
        var speakingName: String = speaker ?? ""
        if meetingType == .meet {
            speakingName = I18n.View_VM_SpeakingColonName(speakingName)
        }
        if participantRetryCnt >= Self.maxRetryCount && meetingType == .call && (speaker?.isEmpty ?? true) {
            speakingName = currentMeetingTopic
        }
        return speakingName
    }

    var currentMeetingTopic: String {
        var topic = meeting.topic
        if topic.isEmpty {
            topic = I18n.View_G_ServerNoTitle
        }
        return topic
    }

    var widgetNetworkStatus: ByteViewWidget.MeetingNetworkStatus {
        guard let networkStatus = networkStatus else {
            return .normal
        }
        var status: ByteViewWidget.MeetingNetworkStatus = .normal
        switch networkStatus {
        case .disconnected:
            status = .disconnected
        case .connected:
            status = .normal
        case .iceDisconnected, .bad:
            status = .bad
        case .weak:
            status = .weak
        }
        return status
    }

    var widgetAvatarURL: URL? {
        if meetingType == .call {
            return avatarURL
        }
        return nil
    }

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.meetingType = meeting.info.type
        self.meetingTopic = meeting.topic

        // meeting.rtc.network.addListener(self)
        // resolver.resolve(InMeetActiveSpeakerViewModel.self)?.addListener(self)
        meeting.data.addListener(self)

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(50)) { [weak self] in
            self?.startLiveActivity()
        }
    }

    deinit {
        endActivity()
    }
}

@available(iOS 16.1, *)
extension InMeetLiveActivityViewModel {
    private func startLiveActivity() {
        // 非 callkit 模式才会发起 Live Activity 和灵动岛
        ByteViewWidgetService.forceEndAllActivities("JoinMeeting")
        if meeting.isCallKit {
            return
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterForeground),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        _startLiveActivity()
        if meetingType == .call {
            update1v1Participant()
        }
    }

    private func _startLiveActivity() {
        if meeting.isCallKit {
            return
        }
        let data = MeetingWidgetData(meetingID: meeting.meetingId)
        let state = MeetingContentState(
            topic: widgetTopic,
            tips: I18n.View_MV_OngoingNow,
            meetingType: widgetMeetingType,
            speaker: widgetSpeaker,
            networkStatus: widgetNetworkStatus,
            avatarURL: widgetAvatarURL,
            isMeetOngoing: true
        )
        liveActivityID = ByteViewWidgetService.request(data: data, state: state)
    }

    private func updateLiveActivity(needAlert: Bool = false) {
        // 非 callkit 模式才会更新 Live Activity 和灵动岛
        guard !meeting.isCallKit, let activityID = liveActivityID else {
            return
        }

        let state = MeetingContentState(
            topic: widgetTopic,
            tips: I18n.View_MV_OngoingNow,
            meetingType: widgetMeetingType,
            speaker: widgetSpeaker,
            networkStatus: widgetNetworkStatus,
            avatarURL: widgetAvatarURL,
            isMeetOngoing: true
        )

        var alert: AlertConfig?
        if needAlert {
            alert = AlertConfig(title: "", body: "", sound: "silence.m4a")
        }
        ByteViewWidgetService.update(activityID, state: state, alert: alert)
    }

    private func endActivity() {
        guard let activityID = liveActivityID else {
            return
        }

        ByteViewWidgetService.end(activityID: activityID)
        cleanAppGroupAvatar()
    }

    @objc private func enterForeground() {
        // 16.1 系统后台完全无法更新，回到前台强制更新
        updateLiveActivity()
    }
}

@available(iOS 16.1, *)
extension InMeetLiveActivityViewModel {
    private func update1v1Participant() {
        guard liveActivityID != nil, meetingType == .call else {
            Self.logger.info("not fetch participant avatar")
            return
        }

        var another: Participant? = meeting.participant.another
        if another == nil {
            let mySelf = meeting.myself
            another = meeting.participant.otherUIdParticipant
        }

        Self.logger.info("another uid: \(another?.rtcUid)")
        guard let another = another else {
            speaker = nil
            participantRetryCnt += 1
            return
        }

        let avatarUid = another.user.id
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: [another],
                                           meetingId: meeting.meetingId) { [weak self] aps in
            guard aps.count >= 1 else {
                self?.speaker = nil
                self?.avatarInfo = nil
                self?.avatarURL = nil
                self?.participantRetryCnt += 1
                return
            }
            self?.speaker = aps[0].name
            self?.avatarInfo = aps[0].avatarInfo
            self?.get1v1AvatarPath(uid: avatarUid)
            self?.updateLiveActivity()
        }
    }

    private func get1v1AvatarPath(uid: String) {
        Self.logger.info("get 1v1 avatar info: \(avatarInfo?.description)")
        guard let avatarInfo = avatarInfo else {
            avatarURL = nil
            participantRetryCnt += 1
            return
        }

        let participantService = meeting.httpClient.participantService
        participantService.participantAvatarPath(avatarInfo) { [weak self] url in
            Self.logger.info("avatar url: \(url)")
            self?.generateAppGroupAvatar(url, uid: uid)
        }
    }

    private func generateAppGroupAvatar(_ url: URL?, uid: String) {
        #if targetEnvironment(simulator)
        self.avatarURL = url
        #else
        let groupID = meeting.setting.appGroupId
        var avatarURL: URL?
        if let url = url, var containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            containerURL.appendPathComponent("vc_avatar", isDirectory: true)
            // 如果在头像复制期间出错，vc_avatar 文件夹需要删除
            let avatarContainerURL = containerURL
            do {
                if !FileManager.default.fileExists(atPath: containerURL.path()) {
                    try FileManager.default.createDirectory(atPath: containerURL.path(), withIntermediateDirectories: true)
                }
                containerURL.appendPathComponent(uid, isDirectory: false)
                // 先移除旧的头像，再复制新的头像
                let toPath = containerURL.path()
                if FileManager.default.fileExists(atPath: toPath) {
                    try FileManager.default.removeItem(atPath: toPath)
                }
                try FileManager.default.copyItem(atPath: url.path(), toPath: toPath)
                avatarURL = containerURL
            } catch let err {
                Self.logger.warn("copy avatar to group err: \(err), remove container...")
                removeAvatarContainer(avatarContainerURL)
            }
        }
        Self.logger.info("group avatar url: \(avatarURL)")
        self.avatarURL = avatarURL
        #endif
        if self.avatarURL == nil {
            participantRetryCnt += 1
        } else {
            updateLiveActivity()
        }
    }

    private func removeAvatarContainer(_ url: URL) {
#if !targetEnvironment(simulator)
        // 清理掉 vc_avatar 文件夹
        do {
            let avatarFolder = url.path()
            if FileManager.default.fileExists(atPath: avatarFolder) {
                try FileManager.default.removeItem(atPath: avatarFolder)
            }
        } catch let err {
            Self.logger.warn("remove avatar container err: \(err)")
        }
#endif
    }

    private func cleanAppGroupAvatar() {
#if !targetEnvironment(simulator)
        // 清理掉 group 里的头像文件
        if let avatarURL = avatarURL {
            do {
                let avatarFolder = avatarURL.deletingLastPathComponent().path()
                try FileManager.default.removeItem(atPath: avatarFolder)
            } catch let err {
                Self.logger.warn("remove group avatar err: \(err)")
            }
        }
#endif
    }
}

@available(iOS 16.1, *)
extension InMeetLiveActivityViewModel: InMeetDataListener {
    func didUpgradeMeeting(_ type: ByteViewNetwork.MeetingType, oldValue: ByteViewNetwork.MeetingType) {
        Self.logger.info("didUpgradeMeeting, \(oldValue) -> \(type)")
        meetingType = type
        speaker = nil
        // updateActiveSpeaker()
        updateLiveActivity()
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if meetingTopic != meeting.topic {
            Self.logger.info("meeting topic changed")
            meetingTopic = meeting.topic
            updateLiveActivity()
        }
    }
}

/*
extension InMeetLiveActivityViewModel {
    // 获取活跃参会人：
    //    - 优先选取当前AS（无人发言时，选取上一个AS）
    //    - 其次选取最早入会者
    //    - 若需要【隐藏自己 && 会中人数大于1】，不会选取自己
    private func getActiveParticipant(hideSelf: Bool = false) -> Participant? {
        var candidates = meeting.data.panelParticipants.onTheCall
        // 会中仅剩自己时，即使隐藏了自己、小窗也需要兜底为自己
        if hideSelf && candidates.count > 1 {
            let myselfUser = meeting.account
            candidates.removeAll(where: { $0.user == myselfUser })
        }
        if let uid = lastActiveSpeaker,
           let p = candidates.first(where: { $0.isSameWith(rtcUid: uid) })
        {
            return p
        } else {
            return nil
        }
    }

    private func getNicknameParticipant() -> Participant? {
        var nicknameParticipant = getActiveParticipant()
        // 如果『最近的as是自己 && 麦克风mute && 需要隐藏自己』，则nickname也不能是自己
        if let p = nicknameParticipant, p.user == meeting.account, p.settings.isMicrophoneMutedOrUnavailable, context.isHideSelf {
            nicknameParticipant = getActiveParticipant(hideSelf: true)
        }
        return nicknameParticipant
    }
}

@available(iOS 16.1, *)
extension InMeetLiveActivityViewModel: InMeetActiveSpeakerListener {
    func didChangeActiveSpeaker(_ rtcUid: RtcUID?, oldValue: RtcUID?) {
        lastActiveSpeaker = rtcUid
        if meetingType == .meet {
            updateActiveSpeaker()
        }
    }

    private func updateActiveSpeaker() {
        guard liveActivityID != nil, meetingType == .meet else {
            return
        }

        guard let nicknameParticipant = getNicknameParticipant() else {
            Self.logger.warn("not found nickname participant, \(meeting.meetingId), \(meetingType)")
            speaker = nil
            updateLiveActivity()
            return
        }
        /// 分组会议以全部参会人为准
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: [nicknameParticipant],
                                           meetingId: meeting.meetingId) { [weak self] aps in
            guard aps.count >= 1 else {
                self?.speaker = nil
                self?.updateLiveActivity()
                return
            }
            self?.speaker = aps[0].name
            self?.updateLiveActivity()
        }
    }
}

@available(iOS 16.1, *)
extension InMeetLiveActivityViewModel: InMeetRtcNetworkListener {
    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        Self.logger.info("network changed: \(networkStatus) -> \(status.networkShowStatus)")
        if networkStatus != status.networkShowStatus {
            networkStatus = status.networkShowStatus
            updateLiveActivity()
        }
    }

    func didChangeRemoteNetworkStatus(_ status: [RtcUID: RtcNetworkStatus], upsertValues: [RtcUID: RtcNetworkStatus], removedValues: [RtcUID: RtcNetworkStatus], reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        remoteNetworkStatuses = status
        updateRemoteNetworkStatus()
    }

    private func updateRemoteNetworkStatus() {
        var nicknameUid: String?
        if meeting.meetType == .meet {
            if let nicknameParticipant = getNicknameParticipant() {
                nicknameUid = nicknameParticipant.rtcUid
            }
        } else {
            nicknameUid = meeting.data.anotherParticipant?.rtcUid
        }
        guard let uid = nicknameUid else {
            Self.logger.warn("not found nickname participant, \(meeting.meetingId), \(meetingType)")
            networkStatus = nil
            updateLiveActivity()
            return
        }

        networkStatus = remoteNetworkStatuses[uid]
        updateLiveActivity()
    }
}
*/
#endif
