//
//  ToolBarRecordItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import RxSwift
import ByteViewUI
import ByteViewSetting
import ByteViewNetwork
import ByteViewTracker
import UniverseDesignIcon
import LarkShortcut

final class ToolBarRecordItem: ToolBarItem {
    override var itemType: ToolBarItemType { .record }

    override var title: String {
        if isLaunching {
            return I18n.View_G_StartingIcon
        } else if meeting.type == .meet, !selfCanStartRecording {
            return isRemoteRecording ? I18n.View_M_Recording : I18n.View_G_Record
        } else {
            return isRemoteRecording ? I18n.View_M_StopRecording : I18n.View_G_Record
        }
    }

    override var showTitle: Bool {
        let isRecording = isRemoteRecording || isLocalRecording
        let isHost = meeting.myself.isHost
        return isHost && isRecording
    }

    override var filledIcon: ToolBarIconType {
        let key: UDIconType
        if isLaunching {
            key = .recordFilled
        } else if meeting.type == .meet, !selfCanStartRecording {
            key = .recordFilled
        } else {
            key = isRemoteRecording ? .stopRecordFilled : .recordFilled
        }
        return isLocalRecording || isRemoteRecording ?
            .customColoredIcon(key: key, color: UIColor.ud.functionDangerFillDefault) :
            .icon(key: key)
    }

    override var outlinedIcon: ToolBarIconType {
        let key: UDIconType
        if isLaunching {
            key = .recordOutlined
        } else if meeting.type == .meet, !selfCanStartRecording {
            key = .recordOutlined
        } else {
            key = isRemoteRecording ? .stopOutlined : .recordOutlined
        }
        return isLocalRecording || isRemoteRecording ?
            .customColoredIcon(key: key, color: UIColor.ud.functionDangerFillDefault) :
            .icon(key: key)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsRecord ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsRecord ? (meeting.setting.hasCohostAuthority ? .center : .more) : .none
    }

    let trackExtraParams: TrackParams = [.recordType: "cloud_record"]
    private let recordViewModel: InMeetRecordViewModel

    var httpClient: HttpClient { meeting.httpClient }

    var isLaunching: Bool {
        recordViewModel.isLaunching && meeting.data.inMeetingInfo?.recordingData?.recordingStatus == .meetingRecordInitializing
    }

    var isLocalRecording: Bool {
        meeting.data.isLocalRecording
    }

    var isRemoteRecording: Bool {
        meeting.data.isRemoteRecording
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.recordViewModel = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.data.addListener(self, fireImmediately: false)
        meeting.addMyselfListener(self, fireImmediately: false)
        meeting.setting.addListener(self, for: [.showsRecord, .hasCohostAuthority])
        recordViewModel.addListener(self)

        meeting.shortcut?.registerHandler(self, for: .vc.startRecord, isWeakReference: true)
    }

    func trackMeetingClickOperation(_ contextId: String? = nil, isFromNotes: Bool = false) {
        MeetingTracksV2.trackMeetingClickOperation(action: .clickRecord,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true,
                                                   isFromNotes: isFromNotes,
                                                   contextId: contextId)
    }

    func notesClickAction() {
        clickActionWithParams(isFromNotes: true)
    }

    override func clickAction() {
        clickActionWithParams(isFromNotes: false)
    }

    private func clickActionWithParams(isFromNotes: Bool) {
        guard provider != nil || !isLaunching else { return }
        // 目前服务端 FeatureConfig.recoreEnable 同时代表 "admin 后端是否开启录制功能"以及"面试会议是否允许开启录制"
        // 该值为 false 时，如果是因为 admin 关闭，则依然显示录制按钮，点击弹 toast
        // 如果是因为面试会议或其他原因，则在 showldShow 中过滤，直接隐藏该按钮
        if !meeting.setting.isRecordEnabled {
            if meeting.setting.recordCloseReason == .admin {
                Toast.show(I18n.View_MV_FeatureNotOnYet_Hover)
            }
            return
        }
        switch meeting.type {
        case .meet:
            handleMeetClick(isFromNotes: isFromNotes)
        case .call:
            handleCallClick(isFromNotes: isFromNotes)
        case .unknown:
            break
        }
    }

    private func handleMeetClick(isFromNotes: Bool = false) {
        if meeting.webinarManager?.isRehearsing ?? false {
            Toast.show(I18n.View_G_NoRecordingRehearsal, type: .warning)
            return
        }
        let isMyselfOnlyParticipant: Bool = meeting.participant.global.count == 1
        let isMyAudioMuted: Bool = meeting.microphone.isMuted
        let requestedButBeforeRecording = recordViewModel.requestedButBeforeRecording.value

        if selfCanStartRecording {
            if isRemoteRecording {
                trackMeetingClickOperation(isFromNotes: isFromNotes)
                stopRecording()
            } else {
                MeetSettingTracks.trackTapRecording(onRecordingStatus: false)
                if isMyselfOnlyParticipant {
                    let userType = ThemeAlertTrackerV2.getUserType(meetingType: meeting.type, meetingRole: meeting.myself.meetingRole)
                    startRecording(contextIdCallback: { [weak self] contextId in
                        self?.trackMeetingClickOperation(contextId, isFromNotes: isFromNotes)
                    }, { [weak self] result in
                        // 单人会议录制
                        switch result {
                        case .success:
                            if isMyAudioMuted {
                                self?.showTurnOnMicAlert()
                            }
                            ThemeAlertTrackerV2.trackStartRecordDev(isError: false, userType: userType)
                        case .failure(let error):
                            ThemeAlertTrackerV2.trackStartRecordDev(isError: true, errorCode: error.toErrorCode(), userType: userType)
                        }
                    })
                } else {
                    trackMeetingClickOperation(isFromNotes: isFromNotes)
                    showStartRecordAlert()
                }
            }
        } else if !isRemoteRecording, !meeting.setting.allowRequestRecord {
            shrinkToolBar {
                Toast.show(I18n.View_G_HostDisallowRecord)
            }
        } else if !isRemoteRecording, !requestedButBeforeRecording {
            trackMeetingClickOperation(isFromNotes: isFromNotes)
            MeetSettingTracks.trackTapRecording(onRecordingStatus: false)
            showRequestConfirmAlert(for: .meet)
        } else if isRemoteRecording {
            trackMeetingClickOperation(isFromNotes: isFromNotes)
            shrinkToolBar {
                MeetSettingTracks.trackTapRecording(onRecordingStatus: true)
                Toast.show(I18n.View_M_CurrentlyRecording)
            }
        } else {
            // 发出的请求录制消息尚未被主持人处理时
            trackMeetingClickOperation(isFromNotes: isFromNotes)
            shrinkToolBar {
                MeetSettingTracks.trackTapRecording(onRecordingStatus: false)
                Toast.show(I18n.View_G_RequestSentShort)
            }
        }
    }

    private func handleCallClick(isFromNotes: Bool = false) {
        let hasRecorded = meeting.data.inMeetingInfo?.hasRecorded ?? false
        let requestedButBeforeRecording = recordViewModel.requestedButBeforeRecording.value

        trackMeetingClickOperation(isFromNotes: isFromNotes)
        if isRemoteRecording {
            stopRecording()
        } else if hasRecorded {
            MeetSettingTracks.trackTapRecording(onRecordingStatus: false)
            startRecording()
        } else if !requestedButBeforeRecording {
            MeetSettingTracks.trackTapRecording(onRecordingStatus: false)
            let userType = ThemeAlertTrackerV2.getUserType(meetingType: meeting.type, meetingRole: meeting.myself.meetingRole)
            requestRecording(for: .call, { result in
                // 1v1通话，开始录制
                switch result {
                case .success:
                    ThemeAlertTrackerV2.trackRequestRecordDev(isError: false, userType: userType)
                case .failure(let error):
                    ThemeAlertTrackerV2.trackRequestRecordDev(isError: true, errorCode: error.toErrorCode(), userType: userType)
                }
            })
        }
    }

    private func updateRecordInfos() {
        if isLaunching {
            recordViewModel.resetLaunchingStatusIfNeeded()
        }
        notifyListeners()
    }

    private var selfCanStartRecording: Bool {
        meeting.setting.canStartRecord
    }

    // MARK: - Alert

    private func stopRecording() {
        recordViewModel.requestStopRecording(onConfirm: { [weak self] in
            self?.shrinkToolBar(completion: nil)
        })
    }

    /// 单人会中且静音时开启录制的提示
    private func showTurnOnMicAlert() {
        let curMeeting = meeting
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .recordUnmute)
        ByteViewDialog.Builder()
            .id(.confirmBeforeRecord)
            .colorTheme(.firstButtonBlue)
            .title(I18n.View_G_NoAudioWillBeRecorded)
            .message(I18n.View_G_Muted)
            .buttonsAxis(.vertical)
            .leftTitle(I18n.View_G_UnmuteMyself)
            .leftHandler({ _ in
                // 解除静音，并开始录制
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordUnmute,
                                                         action: "self_unmute")
                curMeeting.microphone.muteMyself(false, source: .record, completion: nil)
            })
            .rightTitle(I18n.View_G_RecordWithoutAudio)
            .rightHandler({ _ in
                // 保持静音，并开始录制
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordUnmute,
                                                         action: "record_without_audio")
            })
            .needAutoDismiss(true)
            .show()
    }

    // disable-lint: duplicated code
    private func showStartRecordAlert() {
        var title = I18n.View_VM_StartRecordingQuestion
        let meetType = meeting.type
        let meetRole = meeting.myself.meetingRole
        var trackExtraParams = trackExtraParams
        if meeting.data.isOpenBreakoutRoom {
            trackExtraParams["location"] = meeting.data.isMainBreakoutRoom ? "main" : "branch"
        }
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .recordReconfirm, params: trackExtraParams)

        var message: String?
        if meeting.data.isOpenBreakoutRoom {
            title = I18n.View_G_ConfirmStartCloudPop
            message = I18n.View_G_MainBreakoutAllRecord
        }

        ByteViewDialog.Builder()
            .id(.confirmBeforeRecord)
            .title(title)
            .message(message)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                MeetSettingTracks.trackStartRecordingReConfrim(canceled: true)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordReconfirm, action: "cancel", params: trackExtraParams)
            })
            .rightTitle(I18n.View_G_Record)
            .rightHandler({ [weak self] _ in
                MeetSettingTracks.trackStartRecordingReConfrim(canceled: false)
                if let self = self {
                    let userType = ThemeAlertTrackerV2.getUserType(meetingType: meetType, meetingRole: meetRole)
                    self.startRecording(contextIdCallback: { contextId in
                        ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordReconfirm, action: "confirm", contextId: contextId, params: trackExtraParams)
                    }, { result in
                        // 会议主持人/联席主持人开始录制
                        switch result {
                        case .success:
                            ThemeAlertTrackerV2.trackStartRecordDev(isError: false, userType: userType)
                        case .failure(let error):
                            ThemeAlertTrackerV2.trackStartRecordDev(isError: true, errorCode: error.toErrorCode(), userType: userType)
                        }
                    })
                } else {
                    ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordReconfirm, action: "confirm", params: trackExtraParams)
                }
            })
            .needAutoDismiss(true)
            .show()
    }
    // enable-lint: duplicated code

    private func showRequestConfirmAlert(for meetType: MeetingType) {
        var title = I18n.View_G_AskHostToRecordQuestion
        var message: String
        if meeting.setting.isSupportNoHost {
            message = I18n.View_MV_HostsBothCanRecord
        } else {
            message = I18n.View_G_AskHostToRecordInfo
        }
        if meeting.data.isOpenBreakoutRoom {
            title = I18n.View_G_AskHostStartCloud
            message = I18n.View_G_HostCloudMainBreakoutAll
        }
        let meetRole = meeting.myself.meetingRole
        var trackExtraParams = trackExtraParams
        if meeting.data.isOpenBreakoutRoom {
            trackExtraParams["location"] = meeting.data.isMainBreakoutRoom ? "main" : "branch"
        }
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .recordRequest, params: trackExtraParams)
        ByteViewDialog.Builder()
            .id(.conformRequestRecording)
            .title(title)
            .message(message)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                MeetSettingTracks.trackConfirmRequstRecording(false)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordRequest, action: "cancel", params: trackExtraParams)
            })
            .rightTitle(I18n.View_M_SendRequest)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                MeetSettingTracks.trackConfirmRequstRecording(true)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordRequest, action: "confirm", params: trackExtraParams)
                if self.selfCanStartRecording {
                    Toast.show(I18n.View_G_CouldNotSendRequest)
                } else {
                    let userType = ThemeAlertTrackerV2.getUserType(meetingType: meetType, meetingRole: meetRole)
                    self.requestRecording(for: meetType, { result in
                        // 参会人请求录制
                        switch result {
                        case .success:
                            ThemeAlertTrackerV2.trackRequestRecordDev(isError: false, userType: userType)
                        case .failure(let error):
                            ThemeAlertTrackerV2.trackRequestRecordDev(isError: true, errorCode: error.toErrorCode(), userType: userType)
                        }
                    })
                }
            })
            .needAutoDismiss(true)
            .show()
    }

    // MARK: - Recording

    private func startRecording(contextIdCallback: ((String) -> Void)? = nil, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            MeetSettingTracks.trackStartRecording()
            let request = RecordMeetingRequest(meetingId: self.meeting.meetingId, action: .start)
            var options = NetworkRequestOptions()
            options.contextIdCallback = contextIdCallback
            self.httpClient.send(request, options: options) { [weak self] res in
                self?.recordViewModel.isLaunching = true
                completion?(res)
            }
        }
    }

    private func requestRecording(for meetType: MeetingType, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        VCTracker.post(name: meetType.trackName, params: [.action_name: "request_record"])
        let request = RecordMeetingRequest(meetingId: meeting.meetingId, action: .participantRequestStart)
        httpClient.send(request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.recordViewModel.isLaunching = meetType == .call
                let toast: String
                if meetType == .meet {
                    toast = I18n.View_G_RequestSent
                } else {
                    let name = self.meeting.participant.another?.userInfo?.name ?? ""
                    toast = I18n.View_AV_RecordingStartIfApprovalNameBraces(name)
                }
                Toast.showOnVCScene(toast)
            case .failure:
                if self.recordViewModel.requestedButBeforeRecording.value {
                    self.recordViewModel.enableRequestRecording()
                }
            }
            completion?(result)
        }
        disableRequestRecording()
        shrinkToolBar(completion: nil)
    }

    private func disableRequestRecording() {
        recordViewModel.requestedButBeforeRecording.accept(true)
        // 30秒后恢复可点击
        let recoveryTimeConstant: Int = 30
        let autoEnableRecordRequest = recordViewModel.requestedButBeforeRecording
        let cancelDelayEnableRequestRecordSubject = recordViewModel.cancelDelayEnableRequestRecordSubject
        _ = Observable<Void>.just(Void())
            .delay(.seconds(recoveryTimeConstant), scheduler: MainScheduler.instance)
            .map { _ in false }
            .catchError { _ in .empty() }
            .takeUntil(cancelDelayEnableRequestRecordSubject)
            .bind(to: autoEnableRecordRequest)
        //这里不能加DisposeBag
    }
}

extension ToolBarRecordItem: InMeetDataListener, MyselfListener, InMeetingChangedInfoPushObserver {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        Util.runInMainThread {
            self.updateRecordInfos()
        }
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        Util.runInMainThread {
            self.updateRecordInfos()
        }
    }

    func didReceiveInMeetingChangedInfo(_ message: InMeetingData) {
        Util.runInMainThread {
            self.updateRecordInfos()
        }
    }
}

extension ToolBarRecordItem: MeetingSettingListener {

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}

extension ToolBarRecordItem: InMeetRecordViewModelListener {
    func launchingStatusDidChanged() {
        Util.runInMainThread {
            self.updateRecordInfos()
        }
    }

    func notesRequestStartRecording() {
        self.notesClickAction()
    }
}

extension ToolBarRecordItem: ShortcutHandler {
    func canHandleShortcutAction(context: ShortcutActionContext) -> Bool {
        context.isValid(for: meeting)
    }

    func handleShortcutAction(context: ShortcutActionContext, completion: @escaping (Result<Any, Error>) -> Void) {
        let status = meeting.data.recordingStatus ?? .none
        if status == .none {
            let isFromNotes = context.bool("isFromNotes")
            Util.runInMainThread { [weak self] in
                self?.clickActionWithParams(isFromNotes: isFromNotes)
                completion(.success(Void()))
            }
        } else {
            Toast.show(I18n.View_MV_MeetingRecording)
            completion(.success(Void()))
        }
    }
}
