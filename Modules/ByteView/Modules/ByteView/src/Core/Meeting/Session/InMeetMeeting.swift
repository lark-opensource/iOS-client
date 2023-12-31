//
//  InMeetMeeting.swift
//  ByteView
//
//  Created by kiri on 2022/8/8.
//

import Foundation
import ByteViewMeeting
import AVFAudio
import ByteViewTracker
import ByteViewNetwork
import ByteViewSetting
import ByteViewRtcBridge
import LarkShortcut

protocol InMeetMeetingListener: AnyObject {
    func willReleaseInMeetMeeting(_ meeting: InMeetMeeting)
    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting)
}

extension InMeetMeetingListener {
    func willReleaseInMeetMeeting(_ meeting: InMeetMeeting) {}
    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting) {}
}

/// 用于InMeetViewModel的会议上下文，删去可变量和动态resolve的属性以提升性能
final class InMeetMeeting: MeetingBasicServiceProvider {
    private let session: MeetingSession
    /// 会中数据管理，只应在onTheCall的状态下使用
    let data: InMeetDataManager
    /// 会中共享数据管理
    let shareData: InMeetShareDataManager
    /// 面试会议企业招聘信息管理
    let webSpaceData: InMeetWebSpaceDataManager
    /// 会议纪要数据管理
    let notesData: InMeetNotesDataManager
    /// 会中参会人数据管理，只应在onTheCall使用
    let participant: InMeetParticipantManager
    let sessionId: String
    let isCallKit: Bool

    let webinarManager: InMeetWebinarManager?

    /// E2EE会议秘钥管理
    let inMeetKeyManager: InMeetKeyManager?

    /// 进入OnTheCall时的VideoChatInfo
    /// - type和settings不会更新，请使用meeting.meetType和meeting.settings
    let info: VideoChatInfo
    let joinMeetingParams: JoinMeetingParams?

    @RwAtomic
    private(set) var myself: Participant
    let participantDialData = ParticipantDialData()
    let microphone: InMeetMicrophoneManager
    let audioDevice: AudioDeviceManager
    let rtc: InMeetRtcManager
    let camera: InMeetCameraManager
    let pip: PIPManager
    let audioModeManager: InMeetAudioModeManager
    let mediaServiceManager: InMeetMediaServiceManager
    let syncChecker: DeviceSyncChecker

    /// 会中参会人音量信息
    let volumeManager: VolumeManager
    var userId: String { account.id }
    var accountInfo: AccountInfo { service.accountInfo }
    let service: MeetingBasicService
    let effectManger: MeetingEffectManger?

    @RwAtomic
    private(set) var startTime: Date

    private let listeners = Listeners<InMeetMeetingListener>()

    init(session: MeetingSession, service: MeetingBasicService, info: VideoChatInfo, myself: Participant,
         audioDevice: AudioDeviceManager,
         rtcParams: RtcCreateParams) {
        let t0 = CACurrentMediaTime()
        self.session = session
        self.service = service
        self.sessionId = session.sessionId
        self.info = info
        self.myself = myself
        self.isCallKit = session.isCallKit
        self.effectManger = session.effectManger
        let setting = service.setting
        setting.startOnTheCall()
        self.data = InMeetDataManager(session: session, info: info)
        self.shareData = InMeetShareDataManager(info: info, service: service)
        self.webSpaceData = InMeetWebSpaceDataManager()
        self.notesData = InMeetNotesDataManager(session: session, info: info, settings: setting)
        self.participant = InMeetParticipantManager(session: session, service: service, info: info)
        if info.settings.isE2EeMeeting {
            self.inMeetKeyManager = InMeetKeyManager(session: session, e2EeKey: info.e2EeJoinInfo?.keys[0])
        } else {
            self.inMeetKeyManager = nil
        }
        self.joinMeetingParams = session.joinMeetingParams
        self.rtc = InMeetRtcManager(session: session, service: service, participant: participant, rtcParams: rtcParams)
        audioDevice.output.setNoConnect(myself.settings.audioMode != .internet)
        self.audioDevice = audioDevice
        self.microphone = InMeetMicrophoneManager(session: session, isMuted: myself.settings.isMicrophoneMuted, isAvailable: !myself.settings.microphoneStatus.isUnavailable, service: service, audioDevice: audioDevice, participant: participant)
        self.camera = InMeetCameraManager(isMuted: myself.settings.isCameraMuted, isAvailable: !myself.settings.cameraStatus.isUnavailable, service: service, effectManger: effectManger)
        self.volumeManager = VolumeManager(engine: rtc.engine, setting: setting)
        self.pip = PIPManager(session: session, myself: myself, microphone: microphone, rtc: self.rtc.engine)
        self.audioModeManager = InMeetAudioModeManager(session: session, service: service, microphone: microphone, myself: myself, participant: participant)
        self.mediaServiceManager = InMeetMediaServiceManager(session: session)
        self.syncChecker = DeviceSyncChecker(session: session, microphone: microphone, camera: camera, isAutoMuteWhenConflictEnabled: setting.isAutoMuteWhenConflictEnabled)

        if info.startTime > 0 {
            self.startTime = Date(timeIntervalSince1970: Double(info.startTime) / 1000.0)
        } else {
            self.startTime = Date()
        }
        if info.settings.subType == .webinar {
            self.webinarManager = InMeetWebinarManager(session: session)
            self.webinarManager?.setup(meeting: self,
                                       data: data)
        } else {
            self.webinarManager = nil
        }
        session.addMyselfListener(self, fireImmediately: false)
        session.addMyselfListener(syncChecker, fireImmediately: false)
        session.addMyselfListener(microphone, fireImmediately: false)
        session.addMyselfListener(camera, fireImmediately: false)
        rtc.engine.addListener(syncChecker)
        updateStartTime()
        InMeetSettingHolder.shared.setCurrent(session.setting)

        session.inMeetLocalContentSharer = InMeetLocalContentSharer(session: session, data: shareData)

        let duration = CACurrentMediaTime() - t0
        session.log("init InMeetMeeting, duration = \(Util.formatTime(duration))")
    }

    deinit {
        session.log("deinit InMeetMeeting")
    }

    func release() {
        listeners.forEach { $0.willReleaseInMeetMeeting(self) }
        InMeetSettingHolder.shared.setCurrent(nil)
        self.camera.release()
        self.microphone.release()
        self.rtc.release()
        self.audioDevice.release()
        self.participant.release()
        self.setting.release()
        self.syncChecker.release()
        listeners.forEach { $0.didReleaseInMeetMeeting(self) }
        MemoryLeakTracker.addAssociatedItem(self, name: "InMeetMeeting", for: sessionId)
        MemoryLeakTracker.addJob(self, event: .warning(.leak_object).params([.env_id: sessionId, .from_source: "InMeetMeeting"]))
        session.log("release InMeetMeeting")
    }

    func updateStartTime() {
        session.log("adjustMeetingDurationRequest")
        let clientBeginTime = Date()
        httpClient.getResponse(MeetingDurationRequest(meetingId: meetingId)) { [weak self] r in
            if let self = self, let response = r.value {
                let updatedMeetingDuration = response.duration(since: clientBeginTime)
                self.startTime = Date(timeIntervalSinceNow: -updatedMeetingDuration)
            }
        }
    }
}

extension InMeetMeeting {
    var isCalendarMeeting: Bool { info.meetingSource == .vcFromCalendar }
    var isInterviewMeeting: Bool { info.meetingSource == .vcFromInterview }

    var type: MeetingType { setting.meetingType }
    var subType: MeetingSubType { setting.meetingSubType }

    var isHeldByCallkit: Bool { session.isHeldByCallkit }
    var isEnd: Bool { session.isEnd }
    var isActive: Bool { session.isActive }
    var callCoordinator: CallCoordinatorProtocol { session.callCoordinator }
    var audioMode: ParticipantSettings.AudioMode { myself.settings.audioMode }

    var topic: String {
        if isCalendarMeeting, let topic = data.calendarInfo?.topic, !topic.isEmpty {
            return topic
        } else {
            let strategy = data.roleStrategy
            if let topic = data.inMeetingInfo?.meetingSettings.topic, !topic.isEmpty {
                return data.roleStrategy.displayTopic(topic: topic)
            } else {
                return strategy.displayTopic(topic: info.settings.topic)
            }
        }
    }

    var isInterprationGuideShowed: Bool {
        get { session.isInterprationGuideShowed }
        set { session.isInterprationGuideShowed = newValue }
    }

    var canShowAudioToast: Bool {
        get { session.canShowAudioToast }
        set { session.canShowAudioToast = newValue }
    }

    var autoShareScreen: Bool {
        get { session.autoShareScreen }
        set { session.autoShareScreen = newValue }
    }

    /// 判断对端是否成功连接，用于展示连接中。
    /// - call: `rtc.network.isCallConnected(isCalleeNoMicAccess:isCalleePadMicDisabled:)`
    /// - meet: always `true`
    var isCallConnected: Bool {
        guard self.type == .call else { return true }
        if let callee = participant.otherUIdParticipant {
            return rtc.network.isCallConnected(isCalleeNoMicAccess: callee.settings.microphoneStatus == .noPermission,
                                               isCalleePadMicDisabled: Display.pad && callee.settings.isMicrophoneMuted)
        } else {
            return rtc.network.isCallConnected(isCalleeNoMicAccess: false, isCalleePadMicDisabled: false)
        }
    }

    var slaTracker: SLATracks {
        session.slaTracker
    }

    func leave(_ event: MeetingEvent = .userLeave, completion: ((Result<Void, Error>) -> Void)? = nil) {
        session.leave(event, completion: completion)
    }

    func addListener(_ listener: InMeetMeetingListener) {
        listeners.addListener(listener)
    }

    func addMyselfListener(_ listener: MyselfListener, fireImmediately: Bool = true) {
        session.addMyselfListener(listener, fireImmediately: fireImmediately)
    }

    func isCalleeNoMicAccess() -> Bool {
        if self.type == .call, let callee = participant.otherUIdParticipant {
            return callee.settings.microphoneStatus == .noPermission
        }
        return false
    }

    func setChatId(_ id: String) {
        if setting.isUseImChat {
            session.imChatId = id
        }
    }

    /// 当前激活的议程ID
    var lastHintAgendaID: String? {
        get { session.lastHintAgendaID }
        set { session.lastHintAgendaID = newValue }
    }

    /// 是否应显示新议程提示
    var shouldShowNewAgendaHint: Bool {
        get { session.shouldShowNewAgendaHint }
        set { session.shouldShowNewAgendaHint = newValue }
    }

    /// 需要显示外部权限提示
    var shouldShowPermissionHint: Bool {
        get { session.shouldShowPermissionHint }
        set { session.shouldShowPermissionHint = newValue }
    }

    /// 外部权限提示内容
    var permissionHintContent: String? {
        get { session.permissionHintContent }
        set { session.permissionHintContent = newValue }
    }

    /// 需要显示彩色的 Notes 按钮
    var shouldShowColorfulNotesButton: Bool {
        get { session.shouldShowColorfulNotesButton }
        set { session.shouldShowColorfulNotesButton = newValue }
    }

    func beMovedToLobby(_ participant: LobbyParticipant) {
        let meetingId = meetingId
        let interactiveId = myself.interactiveId
        let httpClient = self.httpClient.meeting
        session.sendEvent(.noticeMoveToLobby(participant, subType: subType)) { [weak self] r in
            guard let self = self else { return }
            if case .failure(let e) = r,
                let stateError = e as? MeetingStateError,
                !(stateError == .ignore && session.state == .lobby) {
                // 容错，流转lobby失败，手动离开等候室并同步给后端
                httpClient.updateVideoChat(meetingId: meetingId, action: .leaveLobby, interactiveId: interactiveId,
                                           role: participant.participantMeetingRole)
            }
        }
    }
}

extension InMeetMeeting: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        self.myself = myself
    }
}

protocol InMeetMeetingProvider: MeetingBasicServiceProvider {
    var meeting: InMeetMeeting { get }
}

extension InMeetMeetingProvider {
    var service: MeetingBasicService { meeting.service }
}
