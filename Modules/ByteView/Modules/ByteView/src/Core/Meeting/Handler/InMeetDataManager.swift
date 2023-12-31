//
//  InMeetDataManager.swift
//  ByteView
//
//  Created by kiri on 2021/3/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting

protocol InMeetDataListener: AnyObject {
    /// 日程会议信息变化，由CombinedInfo触发
    func didChangeCalenderInfo(_ calendarInfo: CalendarInfo?, oldValue: CalendarInfo?)
    /// inMeetingInfo变化，会中主要变化都在这里，由CombinedInfo的推送触发
    /// - note: 该回调覆盖了didUpgradeMeeting，并间接触发didChangeSuggestedParticipants；与共享相关的内容不要直接取inMeetingInfo，要从didChangeShareContent获取
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?)
    /// meetType改变，由inMeetingInfo变化触发，目前只有1v1升meet这一种case
    func didUpgradeMeeting(_ type: MeetingType, oldValue: MeetingType)
}

/// handle inMeetingInfo & participants
final class InMeetDataManager: VideoChatCombinedInfoPushObserver {
    private let logger = Logger.meeting
    private let session: MeetingSession
    private let account: ByteviewUser
    private let httpClient: HttpClient
    private var hasCalendarInfo = false

    private let info: VideoChatInfo
    private let myselfNotifier: MyselfNotifier?
    private var meetingId: String { info.id }
    @RwAtomic
    private(set) var calendarInfo: CalendarInfo?
    @RwAtomic
    private(set) var inMeetingInfo: VideoChatInMeetingInfo?

    private let isCalendarMeeting: Bool

    private var meetType: MeetingType { inMeetingInfo?.vcType ?? info.type }

    private var myself: Participant? { myselfNotifier?.myself }

    private lazy var logDescription = "[InMeetDataManager][\(meetingId)]"
    init(session: MeetingSession, info: VideoChatInfo) {
        self.session = session
        self.account = session.account
        self.info = info
        self.httpClient = HttpClient(userId: account.id)
        self.myselfNotifier = session.component(for: MyselfNotifier.self)
        self.isCalendarMeeting = info.meetingSource == .vcFromCalendar
        session.push?.combinedInfo.addObserver(self)
        fetchCalendarInfoIfNeeded()
        Logger.meeting.info("init \(logDescription)")
    }

    func willReleaseComponent(session: MeetingSession) {
    }

    deinit {
        Logger.meeting.info("deinit \(logDescription)")
    }

    func fetchCalendarInfoIfNeeded() {
        if isCalendarMeeting {
            let request = GetCalendarInfoRequest(meetingID: info.id, includeSipBindRoom: true)
            httpClient.getResponse(request) { [weak self] (result) in
                if let self = self, let calendarInfo = result.value?.calendarInfo {
                    if calendarInfo != self.calendarInfo {
                        self.didChangeCalendarInfo(calendarInfo)
                    }
                }
            }
        }
    }

    func triggerInMeetingInfo() {
        httpClient.send(TrigPushFullMeetingInfoRequest(), options: .retry(3, owner: self)) { [weak self] result in
            switch result {
            case .success:
                self?.logger.info("triggle push full meeting info success")
            case .failure(let error):
                self?.logger.info("triggle push full meeting info error:\(error)")
            }
        }
    }

    // MARK: - combined info
    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?) {
        guard inMeetingInfo.id == meetingId else { return }
        Logger.meeting.info("didReceiveCombinedInfo, meetingId = \(meetingId)")
        Logger.phoneCall.info("didReceiveCombinedInfo, meetingId = \(meetingId)")
        if isCalendarMeeting {
            if calendarInfo != self.calendarInfo {
                didChangeCalendarInfo(calendarInfo)
            }
        }
        if inMeetingInfo != self.inMeetingInfo {
            session.setAttr(inMeetingInfo, for: .inMeetingInfo)
            didChangeInMeetingInfo(inMeetingInfo)
        }
    }

    private func didChangeInMeetingInfo(_ info: VideoChatInMeetingInfo) {
        Logger.meeting.info("inMeetingInfo changed")
        guard !needfilt(info) else {
            Logger.meeting.warn("inMeetingInfo changed filter by seq: \(info.minutesStatusData?.seq)")
            return
        }

        let oldValue = self.inMeetingInfo
        let oldType = self.meetType
        self.inMeetingInfo = info
        let isTypeChanged = oldType != info.vcType

        listeners.forEach { $0.didChangeInMeetingInfo(info, oldValue: oldValue) }
        if isTypeChanged {
            listeners.forEach { $0.didUpgradeMeeting(info.vcType, oldValue: oldType) }
        }
    }

    private func needfilt(_ info: VideoChatInMeetingInfo) -> Bool {
        var filt = false
        if let oldValue = inMeetingInfo?.minutesStatusData, let newValue = info.minutesStatusData {
            if oldValue.seq > newValue.seq {
                Logger.meeting.warn("update info error: minutesStatusData.seq illegal, old: \(oldValue), new: \(newValue)")
                filt = true
            }
        }
        return filt
    }

    private func didChangeCalendarInfo(_ calendarInfo: CalendarInfo?) {
        Logger.meeting.info("calendarInfo changed: \(calendarInfo)")
        hasCalendarInfo = true
        let oldValue = self.calendarInfo
        self.calendarInfo = calendarInfo
        listeners.forEach { $0.didChangeCalenderInfo(calendarInfo, oldValue: oldValue) }
    }

    // MARK: - listeners
    private let listeners = Listeners<InMeetDataListener>()

    func addListener(_ listener: InMeetDataListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: InMeetDataListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: InMeetDataListener) {
        if hasCalendarInfo {
            listener.didChangeCalenderInfo(calendarInfo, oldValue: nil)
        }
        if let info = inMeetingInfo {
            listener.didChangeInMeetingInfo(info, oldValue: nil)
        }
    }
}

extension InMeetDataListener {
    func didChangeCalenderInfo(_ calendarInfo: CalendarInfo?, oldValue: CalendarInfo?) {}
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {}
    func didUpgradeMeeting(_ type: MeetingType, oldValue: MeetingType) {}
}

extension InMeetDataManager {

    var roleStrategy: MeetingRoleStrategy {
        meetingRoleStrategyWith(meetingSource: info.meetingSource, selfRole: myself?.role ?? .unknown)
    }

    var isLobbyOpened: Bool {
        if let settings = inMeetingInfo?.meetingSettings.securitySetting {
            return settings.isOpenLobby
        } else {
            return false
        }
    }

    var recordingStatus: RecordMeetingData.RecordingStatus? {
        var recordingStatus = inMeetingInfo?.recordingData?.recordingStatus
        if isInBreakoutRoom { // 用户在讨论组（不含主会场）
            recordingStatus = breakoutRoomInfo?.recordingStatus
        }
        return recordingStatus
    }

    var isRecording: Bool {
        recordingStatus == .meetingRecording
            || recordingStatus == .localRecording
            || recordingStatus == .multiRecording
    }

    var isRemoteRecording: Bool {
        recordingStatus == .meetingRecording
            || recordingStatus == .multiRecording
    }

    var isLocalRecording: Bool {
        recordingStatus == .localRecording
    }

    var isLiving: Bool {
        return inMeetingInfo?.liveInfo?.isLiving ?? false
    }

    /// 转录启动中
    var isTranscribeInitializing: Bool {
        return transcribeStatus == .initializing
    }

    /// 是否正在转录
    var isTranscribing: Bool {
        return transcribeStatus == .ing
    }

    var transcribeStatus: TranscriptInfo.TranscriptStatus? {
        return inMeetingInfo?.transcriptInfo?.transcriptStatus
    }

    /// 是否展示面试速记提醒
    var isPeopleMinutesOpened: Bool {
        inMeetingInfo?.minutesStatusData?.status == .open &&
        info.meetingSource == .vcFromInterview && myself?.role == .interviewee
    }

    var peopleMinutesSeq: Int64 {
        inMeetingInfo?.minutesStatusData?.seq ?? 0
    }
}

// MARK: - BreakoutRoom
extension InMeetDataManager {
    // IM等场景下使用的请求Id
    var meetingIdForRequest: String {
        if let id = breakoutRoomId, !BreakoutRoomUtil.isMainRoom(id) {
            return id
        } else {
            return meetingId
        }
    }

    // 是否开启分组讨论
    var isOpenBreakoutRoom: Bool {
        inMeetingInfo?.meetingSettings.isOpenBreakoutRoom ?? info.settings.isOpenBreakoutRoom
    }

    // 讨论组是否开启自动结束
    var isBreakoutRoomAutoFinishEnabled: Bool {
        isOpenBreakoutRoom && (inMeetingInfo?.meetingSettings.breakoutRoomSettings?.autoFinishEnabled ?? false)
    }

    // 当前讨论组ID
    var breakoutRoomId: String? {
        guard isOpenBreakoutRoom else { return nil }
        return myself?.breakoutRoomId
    }

    // 是否是主会场
    var isMainBreakoutRoom: Bool {
        guard let id = breakoutRoomId else { return false }
        return BreakoutRoomUtil.isMainRoom(id)
    }

    // 用户是否在讨论组（不含主会场）
    var isInBreakoutRoom: Bool {
        isOpenBreakoutRoom && !isMainBreakoutRoom
    }

    /// 当前讨论组数据(主会场拿到的是nil)
    var breakoutRoomInfo: BreakoutRoomInfo? {
        guard let info = inMeetingInfo, let id = breakoutRoomId, !BreakoutRoomUtil.isMainRoom(id) else { return nil }
        return info.breakoutRoomInfos.first { $0.status != .idle && $0.breakoutRoomId == id }
    }
}

private extension MeetingAttributeKey {
    static let inMeetingInfo: MeetingAttributeKey = "vc.inMeetingInfo"
    static let isExternalMeeting: MeetingAttributeKey = "vc.isExternalMeeting"
}
