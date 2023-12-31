//
//  InMeetStatusManager.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/16.
//

import Foundation
import RxSwift
import ByteViewUI
import ByteViewTracker
import ByteViewNetwork
import UniverseDesignIcon
import ByteViewSetting

protocol InMeetStatusManagerListener: AnyObject {
    func statusDidChange(type: InMeetStatusType)
}

struct InMeetStatusCountDownData: Equatable {
    var isEnabled: Bool
    var time: TimeInterval
    var timeInHMS: (hour: Int, minute: Int, second: Int)
    var stage: CountDown.Stage
    var state: CountDown.State
    var isBoardOpened: Bool

    static func == (lhs: InMeetStatusCountDownData, rhs: InMeetStatusCountDownData) -> Bool {
        lhs.isEnabled == rhs.isEnabled && lhs.time == rhs.time && lhs.state == rhs.state && lhs.stage == rhs.stage && lhs.isBoardOpened == rhs.isBoardOpened
    }
}

private enum RecordingState {
    case remote
    case local
    case none
}

final class InMeetStatusManager: InMeetMeetingProvider {
    private(set) var thumbnails: [InMeetStatusType: InMeetStatusThumbnailItem] = [:]
    private(set) var statuses: [InMeetStatusType: InMeetStatusItem] = [:]

    private static let logger = Logger.ui
    private static let thumbnailIconSize = CGSize(width: 12, height: 12)
    private static let listIconSize = CGSize(width: 16, height: 16)

    private struct ImageCache {
        static let recordingThumbnail = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.functionDangerFillDefault, size: thumbnailIconSize)
        static let recordingStatus = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.functionDangerFillDefault, size: listIconSize)
        static let liveThumbnail = UDIcon.getIconByKey(.livestreamFilled, iconColor: UIColor.ud.functionDangerFillDefault, size: thumbnailIconSize)
        static let liveStatus = UDIcon.getIconByKey(.livestreamFilled, iconColor: UIColor.ud.functionDangerFillDefault, size: listIconSize)
        static let transcribeThumbnail = UDIcon.getIconByKey(.transcribeFilled, iconColor: UIColor.ud.functionInfoContentDefault, size: thumbnailIconSize)
        static let transcribeStatus = UDIcon.getIconByKey(.transcribeFilled, iconColor: UIColor.ud.functionInfoContentDefault, size: listIconSize)
        static let transcribeStartingThumbnail = UDIcon.getIconByKey(.transcribeFilled, iconColor: UIColor.ud.iconN2, size: thumbnailIconSize)
        static let transcribeStartingStatus = UDIcon.getIconByKey(.transcribeFilled, iconColor: UIColor.ud.iconN2, size: listIconSize)
        static let lockThumbnail = UDIcon.getIconByKey(.lockFilled, iconColor: UIColor.ud.iconN3, size: thumbnailIconSize)
        static let lockStatus = UDIcon.getIconByKey(.lockFilled, iconColor: UIColor.ud.iconN3, size: listIconSize)
        static let interpreterThumbnail = UDIcon.getIconByKey(.languageFilled, iconColor: UIColor.ud.iconN3, size: thumbnailIconSize)
        static let interpreterStatus = UDIcon.getIconByKey(.languageFilled, iconColor: UIColor.ud.iconN3, size: listIconSize)
        static let interviewThumbnail = UDIcon.getIconByKey(.voice2textFilled, iconColor: UIColor.ud.iconN3, size: thumbnailIconSize)
        static let interviewStatus = UDIcon.getIconByKey(.voice2textFilled, iconColor: UIColor.ud.iconN3, size: listIconSize)
        static let countdownEndedThumbnail = UDIcon.getIconByKey(.burnlifeNotimeFilled, iconColor: UIColor.ud.iconN3, size: thumbnailIconSize)
        static let countdownEndedStatus = UDIcon.getIconByKey(.burnlifeNotimeFilled, iconColor: UIColor.ud.iconN3, size: listIconSize)
        static let countdownStartedThumbnail = UDIcon.getIconByKey(.burnlifeNotimeFilled, iconColor: UIColor.ud.colorfulBlue, size: thumbnailIconSize)
        static let countdownStartedStatus = UDIcon.getIconByKey(.burnlifeNotimeFilled, iconColor: UIColor.ud.colorfulBlue, size: thumbnailIconSize)
    }

    private var canOperateCountDown: Bool {
        didSet {
            if oldValue != canOperateCountDown {
                updateCountDown()
            }
        }
    }
    private var countDownData: InMeetStatusCountDownData {
        didSet {
            if oldValue != countDownData {
                updateCountDown()
            }
        }
    }
    // (isOpened: Bool, seqID: Int)
    private var peopleMinutesInfo: (Bool, Int) {
        didSet {
            if oldValue != peopleMinutesInfo {
                updatePeopleMinutes()
            }
        }
    }
    private var currentChannel: LanguageType {
        didSet {
            if oldValue != currentChannel {
                updateInterpretation()
            }
        }
    }
    private var isOpenInterpretation: Bool {
        didSet {
            if oldValue != isOpenInterpretation {
                updateInterpretation()
            }
        }
    }
    private var canOperateLock: Bool {
        didSet {
            if oldValue != canOperateLock {
                updateLock()
            }
        }
    }
    private var isLocked: Bool {
        didSet {
            if oldValue != isLocked {
                updateLock()
            }
        }
    }
    private var canOperateRecording: Bool {
        didSet {
            if oldValue != canOperateRecording {
                updateRecording()
            }
        }
    }
    private var recordingState: RecordingState {
        didSet {
            if oldValue != recordingState {
                updateRecording()
            }
        }
    }
    private var recordingOwner: ByteviewUser? {
        didSet {
            if oldValue != recordingOwner {
                updateRecording()
            }
        }
    }

    private var isTranscribing: Bool {
        didSet {
            if oldValue != isTranscribing {
                updateTranscribe()
            }
        }
    }

    private var shouldShowTranscribeState: Bool {
        didSet {
            if oldValue != shouldShowTranscribeState {
                updateTranscribe()
            }
        }
    }

    private var canOperateTranscribe: Bool {
        didSet {
            if oldValue != canOperateTranscribe {
                updateTranscribe()
            }
        }
    }

    private var canOperateLive: Bool {
        didSet {
            if oldValue != canOperateLive {
                updateLive()
            }
        }
    }
    private var isLiving: Bool {
        didSet {
            if oldValue != isLiving {
                updateLive()
            }
        }
    }
    private var liveUserCount: Int {
        didSet {
            if oldValue != liveUserCount {
                updateLive()
            }
        }
    }
    private var isInBreakoutRoom: Bool {
        didSet {
            if oldValue != isInBreakoutRoom {
                updateRecording()
                updateLive()
            }
        }
    }

    var isWebinar: Bool {
        meeting.subType == .webinar
    }

    private var isRecordLaunching: Bool {
        meeting.data.inMeetingInfo?.recordingData?.recordingStatus == .meetingRecordInitializing && record.isLaunching
    }

    private var isTranscribeLaunching: Bool {
        return transcribe.isLaunching && meeting.data.isTranscribeInitializing
    }

    let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let interpretation: InMeetInterpreterViewModel
    private let record: InMeetRecordViewModel
    private let transcribe: InMeetTranscribeViewModel
    private let countDown: CountDownManager
    private let live: InMeetLiveViewModel
    private let breakoutRoom: BreakoutRoomManager
    private var interpretationTaskID = 0
    private var recordingTaskID = 0
    private let bag = DisposeBag()

    private let listeners = Listeners<InMeetStatusManagerListener>()

    init(meeting: InMeetMeeting, context: InMeetViewContext, resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.context = context
        self.interpretation = resolver.resolve()!
        self.record = resolver.resolve()!
        self.transcribe = resolver.resolve()!
        self.countDown = resolver.resolve()!
        self.live = resolver.resolve()!
        self.breakoutRoom = resolver.resolve()!

        self.peopleMinutesInfo = (meeting.data.isPeopleMinutesOpened, Int(meeting.data.peopleMinutesSeq))
        self.currentChannel = interpretation.selectedChannel
        self.isOpenInterpretation = meeting.setting.isMeetingOpenInterpretation
        self.canOperateLock = meeting.setting.hasCohostAuthority
        self.isLocked = meeting.type == .meet && meeting.setting.isMeetingLocked
        self.recordingState = Self.recordingState(from: meeting)
        self.canOperateRecording = meeting.setting.hasCohostAuthority
        self.canOperateLive = meeting.setting.hasHostAuthority
        self.isLiving = meeting.data.isLiving
        self.liveUserCount = self.live.liveUsersCount
        self.canOperateCountDown = self.countDown.canOperate.0
        self.isInBreakoutRoom = meeting.data.isInBreakoutRoom
        self.countDownData = InMeetStatusCountDownData(isEnabled: self.countDown.enabled, time: 0, timeInHMS: (0, 0, 0), stage: .end, state: self.countDown.state, isBoardOpened: !self.countDown.boardFolded)

        self.canOperateTranscribe = meeting.setting.hasCohostAuthority
        self.shouldShowTranscribeState = self.meeting.data.isTranscribing && !self.meeting.data.isInBreakoutRoom
        self.isTranscribing = meeting.data.isTranscribing

        meeting.data.addListener(self)
        meeting.push.extraInfo.addObserver(self)
        meeting.push.combinedInfo.addObserver(self)
        meeting.setting.addListener(self, for: [.hasHostAuthority, .hasCohostAuthority])
        self.breakoutRoom.addObserver(self)
        self.interpretation.addObserver(self)
        self.countDown.addObserver(self)
        record.addListener(self)
        transcribe.addListener(self)

        updateRecording()
        updateLive()
        updateLock()
        updateInterpretation()
        updatePeopleMinutes()
        updateCountDown()
        updateTranscribe()
    }

    func addListener(_ listener: InMeetStatusManagerListener) {
        listeners.addListener(listener)
    }

    private func liveUserCountDescription(_ count: Int) -> String {
        // disable-lint: magic number
        if !meeting.setting.isFeishuBrand {
            if count < 1_000 {
                return "\(count)"
            } else if count < 1_000_000 {
                return "\(String(format: "%.1fK", Double(count) / 1_000))"
            } else {
                return "\(String(format: "%.1fM", Double(count) / 1_000_000))"
            }
        } else {
            if count < 10000 {
                return "\(count)"
            } else {
                return "\(String(format: "%.1fw", Double(count) / 10000))"
            }
        }
        // enable-lint: magic number
    }

    private func remove(_ type: InMeetStatusType) {
        guard thumbnails[type] != nil || statuses[type] != nil else { return }
        thumbnails.removeValue(forKey: type)
        statuses.removeValue(forKey: type)
        listeners.forEach { $0.statusDidChange(type: type) }
    }

    private func update(_ type: InMeetStatusType, thumbnail: InMeetStatusThumbnailItem, status: InMeetStatusItem?) {
        thumbnails[type] = thumbnail
        if let status = status {
            statuses[type] = status
        }
        listeners.forEach { $0.statusDidChange(type: type) }
    }

    private func updateRecording() {
        Self.logger.info("Status bar update recording, recordingState = \(recordingState), isInBreakoutRoom = \(isInBreakoutRoom), canOperate = \(canOperateRecording), recordingOwner = \(recordingOwner)")
        recordingTaskID = (recordingTaskID + 1) % Int.max
        let taskID = recordingTaskID
        if recordingState == .none {
            remove(.record)
            return
        }

        let addAction: (InMeetStatusItem) -> Void = { [weak self] status in
            if self?.canOperateRecording == true && self?.recordingState == .remote {
                status.actions = [InMeetStatusItem.Action(title: I18n.View_MV_StopButton, action: { completion in
                    self?.record.requestStopRecording(onConfirm: completion)
                    VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "stop_record", "status_type": "record", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                })]
            } else {
                status.actions = []
            }
        }
        if isRecordLaunching {
            let thumbnail = InMeetStatusThumbnailItem(type: .record, title: I18n.View_G_RecordingStarting, icon: ImageCache.recordingThumbnail, data: true)
            update(.record, thumbnail: thumbnail, status: nil)
            record.resetLaunchingStatusIfNeeded()
        } else {
            guard let owner = recordingOwner ?? meeting.info.meetingOwner else { return }

            httpClient.participantService.participantInfo(pid: owner, meetingId: meeting.meetingId) { [weak self] info in
                guard let self = self, taskID == self.recordingTaskID else { return }
                let desc = self.recordingState == .local ? I18n.View_G_CurrentlyLocalRecording : I18n.View_MV_FileSendToName(info.name)
                if let existedStatus = self.statuses[.record], let existedThumbnail = self.thumbnails[.record] {
                    existedStatus.desc = desc
                    addAction(existedStatus)
                    self.update(.record, thumbnail: existedThumbnail, status: existedStatus)
                } else {
                    let thumbnail = InMeetStatusThumbnailItem(type: .record, title: I18n.View_MV_Recording, icon: ImageCache.recordingThumbnail, data: false)
                    let title = self.isWebinar ? I18n.View_MV_WebinarRecording : I18n.View_MV_MeetingRecording
                    let status = InMeetStatusItem(type: .record, title: title, desc: desc, icon: ImageCache.recordingStatus)
                    addAction(status)

                    self.update(.record, thumbnail: thumbnail, status: status)

                }
            }
        }
    }

    private func updateLive() {
        Self.logger.info("Status bar update living, isLiving = \(isLiving), isInBreakoutRoom = \(isInBreakoutRoom), canOperate = \(canOperateLive), liveUserCount = \(liveUserCount)")
        if !isLiving {
            remove(.live)
            return
        }

        let addAction: (InMeetStatusItem) -> Void = { [weak self] status in
            if self?.canOperateLive == true {
                status.clickAction = {
                    self?.showLiveSettings()
                    VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "live", "status_type": "live", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                }
            } else {
                status.clickAction = nil
            }
        }

        let liveCountDesc = liveUserCountDescription(liveUserCount)
        if let existedThumbnail = self.thumbnails[.live], let existedStatus = self.statuses[.live] {
            existedThumbnail.title = liveCountDesc
            existedStatus.desc = I18n.View_MV_NumWatching(liveCountDesc)
            addAction(existedStatus)
            update(.live, thumbnail: existedThumbnail, status: existedStatus)
        } else {
            let thumbnail = InMeetStatusThumbnailItem(type: .live, title: liveCountDesc, icon: ImageCache.liveThumbnail, data: nil)
            let status = InMeetStatusItem(type: .live, title: isWebinar ? I18n.View_MV_WebinarLivestreaming : I18n.View_MV_MeetingLivestreaming, desc: I18n.View_MV_NumWatching(liveCountDesc), icon: ImageCache.liveStatus)
            addAction(status)

            update(.live, thumbnail: thumbnail, status: status)
        }
    }

    private func showLiveSettings() {
        live.getLiveProviderAvailableStatus()
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                if self.live.shouldShowLiveUnavailableView {
                    guard let response = status.response else { return }
                    LiveSettingUnavailableAlert
                        .unavailableAlert(type: status.byteLiveUnAvailableType, role: response.userInfo.role)
                        .rightHandler({ _ in
                            self.live.showByteLiveAppIfNeeded()
                            self.live.showByteLiveBotAndSendMessageIfNeeded()
                        })
                        .show()
                } else {
                    let vm = LiveSettingsViewModel(meeting: self.meeting, live: self.live, liveProviderStatus: status, liveSource: .host)
                    let viewController = LiveSettingsViewController(viewModel: vm)
                    self.router.presentDynamicModal(viewController,
                                                    regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                    compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
                }
            }).disposed(by: self.bag)
    }

    private func updateLock() {
        Self.logger.info("Status bar update locking, isLocked = \(isLocked), canOperate = \(canOperateLock)")
        if !isLocked {
            remove(.lock)
            return
        }

        let addAction: (InMeetStatusItem) -> Void = { [weak self] status in
            if self?.canOperateLock == true {
                status.actions = [InMeetStatusItem.Action(title: I18n.View_MV_UnlockButton, action: { completion in
                    VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "unlock_meeting", "status_type": "host_panel", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                    self?.meeting.setting.updateLockMeeting(false)
                    completion()
                })]
            } else {
                status.actions = []
            }
        }

        if let existedThumbnail = self.thumbnails[.lock], let existedStatus = self.statuses[.lock] {
            addAction(existedStatus)
            update(.lock, thumbnail: existedThumbnail, status: existedStatus)
        } else {
            let thumbnail = InMeetStatusThumbnailItem(type: .lock, title: I18n.View_MV_Locked, icon: ImageCache.lockThumbnail, data: nil)
            let status = InMeetStatusItem(type: .lock, title: isWebinar ? I18n.View_MV_WebinarLocked : I18n.View_MV_MeetingLocked, desc: I18n.View_MV_OnlyHostInviteCanJoin, icon: ImageCache.lockStatus)
            addAction(status)

            update(.lock, thumbnail: thumbnail, status: status)
        }
    }

    private func updateTranscribe() {
        Self.logger.info("Status bar update transcribe, isTranscribeLaunching: \(isTranscribing), shouldShowTranscribeState: \(shouldShowTranscribeState), canOperate: \(canOperateTranscribe)")
        if !shouldShowTranscribeState {
            remove(.transcribe)
            return
        }

        let addAction: (InMeetStatusItem) -> Void = { [weak self] status in
            if self?.canOperateTranscribe == true {
                status.actions = [InMeetStatusItem.Action(title: I18n.View_G_ViewClick, action: { completion in
                    self?.transcribe.showTranscribeContent()
                    completion()
                }), InMeetStatusItem.Action(title: I18n.View_G_StopButton, action: { completion in
                    self?.transcribe.transcribeAction()
                    completion()
                })]
            } else {
                status.actions = [InMeetStatusItem.Action(title: I18n.View_G_ViewClick, action: { completion in
                    self?.transcribe.showTranscribeContent()
                    completion()
                })]
            }
        }

        let title = isTranscribing ? I18n.View_G_TranscribingShort : I18n.View_G_Transcribe_Starting
        let thumbnailImage = isTranscribing ? ImageCache.transcribeThumbnail : ImageCache.transcribeStartingThumbnail
        let statusImage = isTranscribing ? ImageCache.transcribeStatus : ImageCache.transcribeStartingStatus
        if let existedThumbnail = self.thumbnails[.transcribe], let existedStatus = self.statuses[.transcribe] {
            addAction(existedStatus)
            existedThumbnail.icon = thumbnailImage
            existedThumbnail.title = title
            existedThumbnail.data = isTranscribing
            existedStatus.icon = statusImage
            existedStatus.title = title
            existedStatus.data = isTranscribing
            update(.transcribe, thumbnail: existedThumbnail, status: existedStatus)
        } else {
            let thumbnail = InMeetStatusThumbnailItem(type: .transcribe, title: title, icon: thumbnailImage, data: isTranscribing)
            let status = InMeetStatusItem(type: .transcribe, title: title, desc: nil, icon: statusImage)
            addAction(status)
            update(.transcribe, thumbnail: thumbnail, status: status)
        }
    }

    private func updateInterpretation() {
        Self.logger.info("Status bar update interpretation, isOpen = \(isOpenInterpretation), currentChannel = \(currentChannel)")
        interpretationTaskID = (interpretationTaskID + 1) % Int.max
        let taskID = interpretationTaskID
        if !isOpenInterpretation {
            remove(.interpreter)
            return
        }

        let thumbnailImage: UIImage?
        let statusImage: UIImage?
        let isMainOrEmpty = currentChannel.isMain || currentChannel.isEmpty
        if isMainOrEmpty {
            thumbnailImage = ImageCache.interpreterThumbnail
            statusImage = ImageCache.interpreterStatus
        } else {
            thumbnailImage = LanguageIconManager.get(by: currentChannel, font: UIFont.systemFont(ofSize: 8, weight: .medium), backgroundColor: UIColor.ud.iconN3, size: Self.thumbnailIconSize)
            statusImage = LanguageIconManager.get(by: currentChannel, backgroundColor: UIColor.ud.iconN3, size: Self.listIconSize)
        }
        httpClient.i18n.get(currentChannel.despI18NKey) { [weak self] result in
            Util.runInMainThread { [weak self] in
                guard let self = self, case .success(let channelName) = result, taskID == self.interpretationTaskID else { return }
                if let existedThumbnail = self.thumbnails[.interpreter], let existedStatus = self.statuses[.interpreter] {
                    existedThumbnail.icon = thumbnailImage
                    existedThumbnail.title = isMainOrEmpty ? I18n.View_MV_Interpretation : channelName
                    existedStatus.icon = statusImage
                    existedStatus.desc = channelName
                    self.update(.interpreter, thumbnail: existedThumbnail, status: existedStatus)
                } else {
                    let thumbnail = InMeetStatusThumbnailItem(type: .interpreter, title: isMainOrEmpty ? I18n.View_MV_Interpretation : channelName, icon: thumbnailImage, data: nil)
                    let status = InMeetStatusItem(type: .interpreter, title: I18n.View_MV_InterpretationInProgress, desc: channelName, icon: statusImage)
                    status.clickAction = { [weak self] in
                        guard let self = self else { return }
                        let viewModel = SelectInterpreterChannelViewModel(meeting: self.meeting, interpretation: self.interpretation)
                        let viewController = SelectInterpreterChannelViewController(viewModel: viewModel)
                        self.router.presentDynamicModal(viewController,
                                                        regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                        compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
                        VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "switch_language", "status_type": "interpretation", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                    }
                    self.update(.interpreter, thumbnail: thumbnail, status: status)
                }
            }
        }
    }

    private func updatePeopleMinutes() {
        let (isOpened, seqID) = peopleMinutesInfo
        Self.logger.info("Status bar update interview, isOpened = \(isOpened), seqID = \(seqID)")
        if !isOpened {
            remove(.interviewRecord)
            return
        }

        if let existedThumbnail = self.thumbnails[.interpreter], let existedStatus = self.statuses[.interpreter] {
            existedThumbnail.data = seqID
            existedStatus.data = seqID
            self.update(.interviewRecord, thumbnail: existedThumbnail, status: existedStatus)
        } else {
            let thumbnail = InMeetStatusThumbnailItem(type: .interviewRecord, title: I18n.View_MV_WrittenRecord, icon: ImageCache.interviewThumbnail, data: nil)
            thumbnail.data = seqID
            let status = InMeetStatusItem(type: .interviewRecord, title: I18n.View_MV_WrittenRecord, desc: I18n.View_MV_WrittenRecordForFair, icon: ImageCache.interviewStatus)
            status.data = seqID
            status.actions = [InMeetStatusItem.Action(title: I18n.View_MV_StopButton, action: { [weak self] completion  in
                guard let self = self else { return }
                // 停止面试记录
                PeopleMinutesViewModel.stopPeopleMinutes(meeting: self.meeting, isShareing: self.context.meetingContent.isShareContent, onConfirm: completion)
                completion()
                VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "stop_dictation", "status_type": "interview_dictation", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
            })]
            update(.interviewRecord, thumbnail: thumbnail, status: status)
        }
    }

    private func updateCountDown() {
        if !countDownData.isEnabled || countDownData.state == .close {
            remove(.countDown)
            return
        }

        let thumbnailImage: UIImage
        let statusImage: UIImage
        let timeDesc = DateUtil.formatDuration(countDownData.time, concise: true)

        switch countDownData.state {
        case .end:
            thumbnailImage = ImageCache.countdownEndedThumbnail
            statusImage = ImageCache.countdownEndedStatus
        default:
            thumbnailImage = ImageCache.countdownStartedThumbnail
            statusImage = ImageCache.countdownStartedStatus
        }

        let thumbnail = thumbnails[.countDown]
        thumbnail?.title = timeDesc
        thumbnail?.icon = thumbnailImage
        thumbnail?.data = countDownData
        thumbnails[.countDown] = thumbnail ?? InMeetStatusThumbnailItem(type: .countDown, title: timeDesc, icon: thumbnailImage, data: countDownData)

        let handleOperateFailed = { [weak self] in
            if let message = self?.countDown.canOperate.1?.message { Toast.show(message) }
        }

        let addAction: (InMeetStatusItem) -> Void = { [weak self] status in
            if self?.countDownData.state == .start {
                let prolong = InMeetStatusItem.Action(title: I18n.View_MV_ExtendButton) { [weak self] completion in
                    guard let self = self else { return }
                    guard self.canOperateCountDown else {
                        handleOperateFailed()
                        return
                    }
                    completion()
                    self.showPickerViewController(style: .prolong, source: .prolong)
                    VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "prolong", "status_type": "countdown", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                }
                let preEnd = InMeetStatusItem.Action(title: I18n.View_MV_EndButton) { [weak self] completion in
                    guard let self = self else { return }
                    guard self.canOperateCountDown else {
                        handleOperateFailed()
                        return
                    }
                    self.showPreEndComfirmAlert(completion: completion)
                    VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "close_ahead_of_time", "status_type": "countdown", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                }
                status.actions = [prolong, preEnd]
            } else {
                let reset = InMeetStatusItem.Action(title: I18n.View_MV_ResetButton) { [weak self] completion in
                    guard let self = self else { return }
                    guard self.canOperateCountDown else {
                        handleOperateFailed()
                        return
                    }
                    completion()
                    self.showPickerViewController(style: .start, source: .reset)
                    VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "reset", "status_type": "countdown", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                }
                let close = InMeetStatusItem.Action(title: I18n.View_MV_CloseButton) { [weak self] completion in
                    guard let self = self else { return }
                    guard self.canOperateCountDown else {
                        handleOperateFailed()
                        return
                    }
                    self.showCloseConfirmAlert(completion: completion)
                    VCTracker.post(name: .vc_mobile_status_bar_click, params: [.click: "close", "status_type": "countdown", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": VCScene.isLandscape ? "true" : "false"])
                }
                status.actions = [reset, close]
            }
        }

        if countDownData.isBoardOpened {
            statuses.removeValue(forKey: .countDown)
        } else {
            let status = statuses[.countDown]
            if case .end = countDownData.state {
                status?.desc = I18n.View_MV_EndedState
            } else {
                status?.desc = timeDesc
            }
            status?.icon = statusImage
            let finalStatus = status ?? InMeetStatusItem(type: .countDown, title: I18n.View_MV_CountdownButton, desc: timeDesc, icon: statusImage)
            addAction(finalStatus)
            statuses[.countDown] = finalStatus
        }

        listeners.forEach { $0.statusDidChange(type: .countDown) }
    }

    // copied from InMeetCountDownComponent
    private func showPickerViewController(style: CountDownPickerViewController.Style, source: CountDownPickerViewModel.PageSource) {
        let vm = CountDownPickerViewModel(meeting: meeting, manager: countDown)
        vm.pageSource = source
        vm.style = style
        let viewController = CountDownPickerViewController(viewModel: vm)
        self.router.presentDynamicModal(viewController,
                                        regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                        compactConfig: .init(presentationStyle: .pan, needNavigation: true))
    }

    private func showPreEndComfirmAlert(completion: @escaping () -> Void) {
        ByteViewDialog.Builder()
            .id(.preEndCountDown)
            .needAutoDismiss(true)
            .title(I18n.View_G_ConfirmEndCountdown_Pop)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_ahead_of_time", "sub_click_type": "cancel"])
            })
            .rightTitle(I18n.View_G_EndButton)
            .rightHandler({ [weak countDown] _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_ahead_of_time", "sub_click_type": "confirm"])
                countDown?.requestPreEnd()
                completion()
            })
            .show()
    }

    private func showCloseConfirmAlert(completion: @escaping () -> Void) {
        ByteViewDialog.Builder()
            .id(.closeCountDown)
            .needAutoDismiss(true)
            .title(I18n.View_G_OffCountdownForAllPop)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_double_check", "is_check": false])
            })
            .rightTitle(I18n.View_G_StopCountdown_Button)
            .rightHandler({ [weak countDown] _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_double_check", "is_check": true])
                countDown?.requestClose()
                completion()
            })
            .show()
    }

    private static func recordingState(from meeting: InMeetMeeting, isLaunching: Bool = false) -> RecordingState {
        if isLaunching {
            return .remote
        }
        if !meeting.data.isRecording {
            return .none
        } else if meeting.data.inMeetingInfo?.recordingData?.recordingStatus == .localRecording {
            return .local
        } else {
            return .remote
        }
    }

    private func updateStatusInfo() {
        let inMeetingInfo = meeting.data.inMeetingInfo
        let isLaunching = isRecordLaunching
        let isTranscribeLaunching = isTranscribeLaunching

        Util.runInMainThread {
            self.isLocked = self.meeting.type == .meet && self.meeting.setting.isMeetingLocked
            self.isLiving = self.meeting.data.isLiving
            if isTranscribeLaunching {
                self.shouldShowTranscribeState = !self.meeting.data.isInBreakoutRoom
            } else {
                self.shouldShowTranscribeState = self.meeting.data.isTranscribing && !self.meeting.data.isInBreakoutRoom
            }
            self.isTranscribing = self.meeting.data.isTranscribing
            self.recordingState = Self.recordingState(from: self.meeting, isLaunching: isLaunching)
            self.isOpenInterpretation = inMeetingInfo?.meetingSettings.isMeetingOpenInterpretation ?? false
            self.peopleMinutesInfo = (self.meeting.data.isPeopleMinutesOpened, Int(self.meeting.data.peopleMinutesSeq))
        }
        Self.logger.info("record launching status, recordingStatus: \(inMeetingInfo?.recordingData?.recordingStatus), isLaunching: \(isLaunching)")
    }
}

extension InMeetStatusManager: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        Util.runInMainThread {
            switch key {
            case .hasHostAuthority:
                self.canOperateLive = isOn
            case .hasCohostAuthority:
                self.canOperateLock = isOn
                self.canOperateRecording = isOn
                self.canOperateTranscribe = isOn
            default:
                break
            }
        }
    }
}

extension InMeetStatusManager: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        updateStatusInfo()
    }
}

extension InMeetStatusManager: VideoChatCombinedInfoPushObserver {
    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?) {
        guard inMeetingInfo.id == meeting.meetingId else { return }
        Util.runInMainThread {
            self.recordingOwner = inMeetingInfo.recordingData?.recordingStopV2?.msgI18NKey?.i18NParams.pid?.pid
        }
    }
}

extension InMeetStatusManager: VideoChatExtraInfoPushObserver {
    func didReceiveExtraInfo(_ message: VideoChatExtraInfo) {
        if message.type == .updateLiveExtraInfo, let info = message.liveExtraInfo {
            Util.runInMainThread {
                self.liveUserCount = Int(info.onlineUsersCount)
            }
        }
    }
}

extension InMeetStatusManager: BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        Util.runInMainThread {
            self.isInBreakoutRoom = self.meeting.data.isInBreakoutRoom
        }
    }
}

extension InMeetStatusManager: InMeetInterpreterViewModelObserver {
    func interprationDidChangeSelectedChannel(_ channel: LanguageType, oldValue: LanguageType) {
        Util.runInMainThread {
            self.currentChannel = channel
        }
    }
}

// count down 每秒钟会回调一次状态表示时间更新，为了防止日志打印过于频繁，只分别打印关键变更信息
extension InMeetStatusManager: CountDownManagerObserver {
    func countDownStateChanged(_ state: CountDown.State, by user: ByteviewUser?, countDown: CountDown) {
        Util.runInMainThread {
            if state != self.countDownData.state {
                Self.logger.info("Status bar update count down, state = \(state)")
            }
            var data = self.countDownData
            data.state = state
            self.countDownData = data
        }
    }

    func countDownTimeChanged(_ time: Int, in24HR: (Int, Int, Int), stage: CountDown.Stage) {
        Util.runInMainThread {
            if stage != self.countDownData.stage {
                Self.logger.info("Status bar update count down, stage = \(stage)")
            }
            var data = self.countDownData
            data.time = TimeInterval(time)
            data.timeInHMS = (hour: in24HR.0, minute: in24HR.1, second: in24HR.2)
            data.stage = stage
            self.countDownData = data
        }
    }

    func countDownStyleChanged(style: CountDownManager.Style) {
        Util.runInMainThread {
            Self.logger.info("Status bar update count down, style = \(style)")
            var data = self.countDownData
            data.isBoardOpened = style == .board
            self.countDownData = data
        }
    }

    func countDownOperateAuthorityChanged(_ canOperate: Bool) {
        Util.runInMainThread {
            if self.canOperateCountDown != canOperate {
                Self.logger.info("Status bar update count down, canOperate = \(canOperate)")
            }
            self.canOperateCountDown = canOperate
        }
    }

    func countDownEnableChanged(_ enabled: Bool) {
        Util.runInMainThread {
            if self.countDownData.isEnabled != enabled {
                Self.logger.info("Status bar update count down, enabled = \(enabled)")
            }
            var data = self.countDownData
            data.isEnabled = enabled
            self.countDownData = data
        }
    }
}

extension InMeetStatusManager: InMeetRecordViewModelListener, InMeetTranscribeViewModelListener {
    func launchingStatusDidChanged() {
        updateStatusInfo()
    }
}
