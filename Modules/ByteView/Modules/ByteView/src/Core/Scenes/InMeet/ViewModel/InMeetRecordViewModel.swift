//
//  InMeetRecordViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import ByteViewTracker
import LarkShortcut

protocol InMeetRecordViewModelListener: AnyObject {
    func launchingStatusDidChanged()
    func notesRequestStartRecording()
}

extension InMeetRecordViewModelListener {
    func launchingStatusDidChanged() {}
    func notesRequestStartRecording() {}
}

final class InMeetRecordViewModel: VideoChatNoticePushObserver, VideoChatNoticeUpdatePushObserver, InMeetingChangedInfoPushObserver, InMeetParticipantListener {
    static let logger = Logger.ui
    private let player: RtcAudioPlayer
    let meeting: InMeetMeeting
    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.player = RtcAudioPlayer(meeting: self.meeting)
        bindRecording()
        resolver.viewContext.addListener(self, for: [.containerWillAppear, .containerDidDisappear])
        meeting.push.notice.addObserver(self)
        meeting.push.noticeUpdate.addObserver(self)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
    }

    deinit {
        askHostRecordAlert?.dismiss()
        recordingConfirmAlert?.dismiss()
    }

    let requestedButBeforeRecording = BehaviorRelay<Bool>(value: false)
    let cancelDelayEnableRequestRecordSubject = PublishSubject<Void>()
    func enableRequestRecording() {
        requestedButBeforeRecording.accept(false)
        cancelDelayEnableRequestRecordSubject.onNext(Void())
    }

    // 参会人录制合规Alert
    private weak var recordingConfirmAlert: ByteViewDialog?
    private var recordingConfirmAlertShowing = false
    /// 是否应显示Alert，默认为true；如服务端推送了需要显示则为true；如服务端推送了dismiss则为false
    private var shouldShowAlert: Bool = true

    private weak var askHostRecordAlert: ByteViewDialog?

    private lazy var recordingConfirmInfoSubject = PublishSubject<RecordingConfirmInfo>()

    var recordingStopTitle: String { recordingStopMessageRelay.value.0 }
    var recordingStopMessage: String { recordingStopMessageRelay.value.1 }
    var meetingId: String { meeting.meetingId }
    var isShowingRecordRequest: Bool = false
    // 会中录制提示文案优化: https://bytedance.feishu.cn/docs/doccngJEXSKtYYh8ezJdYjywTye#
    private let recordingStopMessageRelay = BehaviorRelay<(String, String)>(value: ("", ""))
    let disposeBag = DisposeBag()
    let isViewControllerAppearSubject = PublishSubject<Bool>()
    private let askRecordingUserSubject = PublishSubject<ByteviewUser>()
    private lazy var askRecordingUserObservable: Observable<ByteviewUser> = askRecordingUserSubject.asObservable()
    private var httpClient: HttpClient { meeting.httpClient }
    private let listeners = Listeners<InMeetRecordViewModelListener>()

    @RwAtomic
    var isLaunching: Bool = false {
        didSet {
            if isLaunching {
                launchingShowCount = 2
                listeners.forEach { $0.launchingStatusDidChanged() }
            }
        }
    }

    @RwAtomic
    var launchingShowCount: Int = 2

    func addListener(_ listener: InMeetRecordViewModelListener) {
        listeners.addListener(listener)
    }

    private lazy var clientDynamicLink = meeting.setting.clientDynamicLink

    func didReceiveNotice(_ notice: VideoChatNotice) {
        if notice.type == .popup, notice.meetingID == meeting.meetingId, notice.popupType == .popupRecordingConfirm {
            NoticeService.shared.updateI18NContent(notice.msgI18NKey, httpClient: httpClient) { [weak self] message in
                self?.shouldShowAlert = true
                if let msgI18NKey = notice.msgI18NKey {
                    self?.recordingConfirmInfoSubject.onNext(RecordingConfirmInfo(content: message ?? notice.message, scheme: msgI18NKey.jumpScheme))
                } else {
                    self?.recordingConfirmInfoSubject.onNext(RecordingConfirmInfo(content: ""))
                }
            }
        }

        if notice.type == .popup, notice.meetingID == meeting.meetingId, notice.popupType == .popupRecordingUpgradePlan {
            NoticeService.shared.updateI18NContent(notice.msgI18NKey, httpClient: httpClient) { [weak self] message in
                if let message = message, let scheme = notice.extra["upgrade_plan_url"] {
                    self?.showUpgradeAlert(withContent: message, scheme: scheme)
                }
            }
        }
        // 播报录制语音提醒
        if notice.type == .voice, notice.meetingID == meeting.meetingId, !notice.extra.isEmpty {
            let extraInfo = notice.extra
            let languageString = BundleI18n.getCurrentLanguageString()
            Self.logger.info("start play record voice by \(languageString)")
            guard let voiceString = extraInfo[languageString] else {
                Self.logger.info("get \(languageString) voice info failed, try play default english voice")
                guard let englishVoice = extraInfo["en_us"] else {
                    Self.logger.info("get en_US voice info failed")
                    return
                }
                pullVoiceSourceAndPlay(voiceResourceString: englishVoice)
                return
            }
            pullVoiceSourceAndPlay(voiceResourceString: voiceString)
            meeting.push.notice.cleanCache() // 防止webinar会议嘉宾切换为观众时重复推送
        }
    }

    private func pullVoiceSourceAndPlay(voiceResourceString: String) {
        guard let voiceDict = Util.stringValueDic(voiceResourceString), let resourceName = voiceDict["resource_name"] as? String, let downloadURL = voiceDict["download_url"] as? String, let version = voiceDict["version"] as? Int64 else {
            Self.logger.info("Parse record dict failed: \(voiceResourceString.hash)")
            return
        }
        let req = PullVcStaticResourceRequest(downloadURL: downloadURL, resourceName: resourceName, version: version)
        let storage = meeting.storage
        httpClient.getResponse(req) { [weak self] result in
            switch result {
            case .success(let response):
                // rust返回的是绝对路径，因此需要转换一下变为相对路径，且做一下文件校验
                let resultPath = response.localPath
                guard let splitResult = resultPath.components(separatedBy: "Documents").last else { Self.logger.info("record voice file path error")
                    return
                }
                let recordVoicePath = storage.getAbsPath(root: .document, relativePath: splitResult)
                if recordVoicePath.fileExists() {
                    self?.player.play(.recordVoice(filePath: recordVoicePath.absoluteString)) { isSuccess in
                        if !isSuccess {
                            Self.logger.info("mixPlay record voice failed")
                        }
                    }
                } else {
                    Self.logger.info("record voice file not exist")
                }
            case .failure:
                Self.logger.info("pull record static resource failed")
            }
        }
    }

    func didReceiveNoticeUpdate(_ message: VideoChatNoticeUpdate) {
        if message.type == .popup, message.meetingID == meeting.meetingId, message.key == "View_M_RecordingConsentTitle" {
            // 收起录制合规的Alert
            Util.runInMainThread { [weak self] in
                self?.recordingConfirmAlertShowing = false
                self?.recordingConfirmAlert?.dismiss()
                self?.recordingConfirmAlert = nil
                self?.shouldShowAlert = false
            }
        }
    }

    func didReceiveInMeetingChangedInfo(_ message: InMeetingData) {
        guard message.meetingID == meetingId, message.type == .recordMeeting, let data = message.recordingData else {
            return
        }
        // 向服务端上报时区
        if data.needUploadTimezone {
            httpClient.send(SendClientInfoRequest(meetingID: message.meetingID)) { (result) in
                if case let .failure(error) = result {
                    Self.logger.warn("send the time zone of client info request error: \(error)")
                } else {
                    Self.logger.debug("send the time zone of client info request success")
                }
            }
        }
        switch data.type {
        case .participantRequest, .requestLocal:
            if data.isRecording {
                // 只关心参会人请求Start Record
                let user = data.requester
                let isLocalRecord = data.type == .requestLocal
                let policyURL: String
                if !clientDynamicLink.recordPolicyUrl.isEmpty {
                    policyURL = clientDynamicLink.recordPolicyUrl
                } else {
                    policyURL = data.policyURL
                }
                let participantService = httpClient.participantService
                participantService.participantInfo(pid: user, meetingId: meeting.meetingId) { [weak self] (ap) in
                    Util.runInMainThread {
                        self?.showAskHostRecordAlert(request: .init(requester: user, name: ap.name, policyURL: policyURL, isLocalRecord: isLocalRecord))
                    }
                }
            }
        case .recordingStatusChange:
            // 开始和结束录制 toast
            if !meeting.router.isFloating {
                enableRequestRecording()
                if !data.isRecording, data.recordingStatus != .meetingRecordInitializing {
                    Toast.showOnVCScene(I18n.View_M_RecordingStopped)
                }
            }
        case .hostResponse:
            // 当我是参会人，我的Record请求被主持人(1v1对方)refuse or accept
            if !data.isRecording {
                if self.meeting.type == .meet {
                    Toast.showOnVCScene(I18n.View_M_HostDeclinedToRecord)
                } else {
                    let name = self.meeting.participant.another?.userInfo?.name ?? ""
                    Toast.showOnVCScene(I18n.View_AV_DeclinedToRecordNameBraces(name))
                }
            }
            self.requestedButBeforeRecording.accept(false)
        default:
            break
        }
    }

    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        updateStopI18n()
    }

    private func containerWillAppear() {
        guard let request = requireReopenRequest else { return }
        // 如主持人未确认是否开启录制，（点隐私政策后）再回到会中页面时恢复AlertController
        showAskHostRecordAlert(request: request)
    }

    private func containerDidDisappear() {
        guard requireReopenRequest != nil else { return }
        askHostRecordAlert?.dismiss()
        askHostRecordAlert = nil
    }

    private let notificationID = UUID().uuidString
    // 当我是主持人，收到参会人Record请求逻辑
    private var requireReopenRequest: AskHostRecordRequest?
    private func showAskHostRecordAlert(request: AskHostRecordRequest) {
        if self.isShowingRecordRequest { return }
        let name = request.name
        let message: String
        let title: String
        if self.meeting.data.isInBreakoutRoom {
            title = I18n.View_M_RequestToRecord
            message = I18n.View_G_NameAskRecordSeeMore(name)
        } else if self.meeting.type == .meet {
            title = I18n.View_M_RequestToRecord
            message = I18n.View_M_RequestToRecordInfoNew(name)
        } else {
            title = I18n.View_AV_RequestToRecord
            message = I18n.View_AV_RequestToRecordInfoNew(name)
        }
        self.isShowingRecordRequest = true
        var trackExtraParams: TrackParams = [.recordType: request.isLocalRecord ? "local_record" : "cloud_record"]
        if self.meeting.data.isOpenBreakoutRoom {
            trackExtraParams["location"] = self.meeting.data.isMainBreakoutRoom ? "main" : "branch"
        }
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .recordRequestConfirm, params: trackExtraParams)

        let meetType = meeting.type
        let meetRole = meeting.myself.meetingRole

        ByteViewDialog.Builder()
            .id(.requestRecord)
            .title(title)
            .linkText(LinkTextParser.parsedLinkText(from: message), alignment: .center, handler: { [weak self] (_, _) in
                guard let self = self else { return }
                self.isShowingRecordRequest = false
                self.askHostRecordAlert?.dismiss()
                self.askHostRecordAlert = nil
                self.requireReopenRequest = request
                self.meeting.router.setWindowFloating(true)
                self.meeting.larkRouter.goto(scheme: request.policyURL)
            })
            .leftTitle(I18n.View_G_DeclineButton)
            .leftHandler({ [weak self] _ in
                MeetSettingTracks.trackConfirmRecordInviteHint(false, isMeet: self?.meeting.type == .meet)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordRequestConfirm, action: "cancel", params: trackExtraParams)
                self?.isShowingRecordRequest = false
                let userType = ThemeAlertTrackerV2.getUserType(meetingType: meetType, meetingRole: meetRole)
                self?.refuseRecordRequest(from: request.requester, isLocalRecord: request.isLocalRecord, { result in
                    switch result {
                    case .success:
                        ThemeAlertTrackerV2.trackRefuseRecordDev(isError: false, userType: userType)
                    case .failure(let error):
                        let errorCode = error.toErrorCode()
                        ThemeAlertTrackerV2.trackRefuseRecordDev(isError: true, errorCode: errorCode, userType: userType)
                    }
                })
                self?.requireReopenRequest = nil
            })
            .rightTitle(I18n.View_G_ApproveButton)
            .rightHandler({ [weak self] _ in
                MeetSettingTracks.trackConfirmRecordInviteHint(true, isMeet: self?.meeting.type == .meet)
                guard let self = self else {
                    ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordRequestConfirm, action: "confirm", params: trackExtraParams)
                    return
                }
                self.isShowingRecordRequest = false
                let userType = ThemeAlertTrackerV2.getUserType(meetingType: meetType, meetingRole: meetRole)
                self.acceptRecordRequest(from: request.requester, isLocalRecord: request.isLocalRecord, contextIdCallback: { contextId in
                    ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordRequestConfirm, action: "confirm", contextId: contextId, params: trackExtraParams)
                }, { result in
                    switch result {
                    case .success:
                        self.isLaunching =  meetType == .meet
                        ThemeAlertTrackerV2.trackAcceptRecordDev(isError: false, userType: userType)
                    case .failure(let error):
                        let errorCode = error.toErrorCode()
                        ThemeAlertTrackerV2.trackAcceptRecordDev(isError: true, errorCode: errorCode, userType: userType)
                    }
                })

                self.requireReopenRequest = nil
            })
            .show { [weak self] alert in
                if let self = self {
                    self.askHostRecordAlert = alert
                } else {
                    alert.dismiss()
                }
            }

        let showsDetail = meeting.setting.shouldShowDetails
        if UIApplication.shared.applicationState != .active {
            let body: String
            if showsDetail && self.meeting.type == .meet {
                body = I18n.View_M_RequestToRecordNameBraces(name)
            } else if showsDetail && self.meeting.type == .call {
                body = I18n.View_AV_RequestToRecordNameBraces(name)
            } else {
                body = I18n.View_G_YouReceivedRequest
            }
            UNUserNotificationCenter.current().addLocalNotification(withIdentifier: notificationID, body: body)
        }
    }

    func bindRecording() {
        // 参会人录制合规Alert
        Observable.combineLatest(recordingConfirmInfoSubject.asObservable(), isViewControllerAppearSubject.asObservable())
            .filter { [weak self] _ in
                guard let self = self else {
                    return false
                }
                return self.shouldShowAlert
            }
            .subscribe(onNext: { [weak self] (info: RecordingConfirmInfo, isVCAppear: Bool) in
                guard let self = self else { return }
                if !self.recordingConfirmAlertShowing && isVCAppear {
                    self.recordingConfirmAlertShowing = true
                    ByteViewDialog.Builder()
                        .id(.recordingConfirm)
                        .colorTheme(.tendencyConfirm)
                        .title(I18n.View_M_RecordingConsentTitle)
                        .linkText(LinkTextParser.parsedLinkText(from: info.content), alignment: .center, handler: { [weak self] (_, _) in
                            guard let self = self, let scheme = info.scheme else { return }
                            self.meeting.router.setWindowFloating(true)
                            self.meeting.larkRouter.goto(scheme: scheme)
                        })
                        .leftTitle(I18n.View_M_LeaveMeetingShort)
                        .leftHandler({ [weak self] _ in
                            guard let self = self else { return }
                            MeetSettingTracks.trackConfirmRecordPopup(false)
                            let request = RecordMeetingRequest(meetingId: self.meetingId, action: .participantConsentLeave)
                            self.httpClient.send(request)
                            self.leaveMeeting()
                            self.recordingConfirmAlertShowing = false
                            self.shouldShowAlert = false
                        })
                        .rightTitle(I18n.View_M_StayInMeetingShort)
                        .rightHandler({ [weak self] _ in
                            guard let self = self else { return }
                            MeetSettingTracks.trackConfirmRecordPopup(true)
                            self.recordingConfirmAlertShowing = false
                            self.shouldShowAlert = false
                        })
                        .show { [weak self] alert in
                            if let self = self {
                                self.recordingConfirmAlert = alert
                            } else {
                                alert.dismiss()
                            }
                        }
                } else if self.recordingConfirmAlertShowing && !isVCAppear {
                    self.recordingConfirmAlertShowing = false
                    self.recordingConfirmAlert?.dismiss()
                    self.recordingConfirmAlert = nil
                }
            })
            .disposed(by: disposeBag)
    }

    func requestStopRecording(onConfirm: (() -> Void)?) {
        let meetType = meeting.type
        let title: String
        let recordingStopMessageTitle = recordingStopTitle
        if !recordingStopMessageTitle.isEmpty {
            title = recordingStopMessageTitle
        } else if meetType == .meet {
            title = I18n.View_M_StopRecordingQuestion
        } else {
            title = I18n.View_AV_StopRecordingQuestion
        }
        var recordingStopMessage = recordingStopMessage
        if meeting.data.isOpenBreakoutRoom {
            recordingStopMessage = I18n.View_G_StopMainBreakoutTogether
        }
        MeetSettingTracks.trackStopRecording()
        let isMeetingOwner = meeting.info.meetingOwner?.id == meeting.userId // 判断自身是否是会议的组织者
        let meetRole = meeting.myself.meetingRole

        var trackExtraParams: TrackParams = [:]
        if meeting.data.isOpenBreakoutRoom {
            trackExtraParams["location"] = meeting.data.isMainBreakoutRoom ? "main" : "branch"
        }
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .recordStop, params: trackExtraParams)
        ByteViewDialog.Builder()
            .id(.requestStopRecord)
            .colorTheme(.redLight)
            .title(title)
            .message(recordingStopMessage)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                MeetSettingTracks.trackConfirmStopRecording(false, isOwner: isMeetingOwner)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordStop, action: "cancel", params: trackExtraParams)
            })
            .rightTitle(I18n.View_G_StopButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                onConfirm?()

                MeetSettingTracks.trackConfirmStopRecording(true, isOwner: isMeetingOwner)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .recordStop, action: "confirm", params: trackExtraParams)
                let userType = ThemeAlertTrackerV2.getUserType(meetingType: meetType, meetingRole: meetRole)
                let request = RecordMeetingRequest(meetingId: self.meeting.meetingId, action: .stop)
                self.httpClient.send(request) { result in
                    // 停止录制
                    switch result {
                    case .success:
                        ThemeAlertTrackerV2.trackStopRecordDev(isError: false, userType: userType)
                    case .failure(let error):
                        ThemeAlertTrackerV2.trackStopRecordDev(isError: true, errorCode: error.toErrorCode(), userType: userType)
                    }
                }
            })
            .show()
    }

    private func acceptRecordRequest(from requester: ByteviewUser, isLocalRecord: Bool, contextIdCallback: ((String) -> Void)? = nil, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        var request = RecordMeetingRequest(meetingId: meetingId, action: isLocalRecord ? .manageApproveLocalRecord : .hostAccept)
        if isLocalRecord {
            request.targetParticipant = requester
        } else {
            request.requester = requester
        }
        var options = NetworkRequestOptions()
        options.contextIdCallback = contextIdCallback
        httpClient.send(request, options: options, completion: completion)
    }

    private func refuseRecordRequest(from requester: ByteviewUser, isLocalRecord: Bool, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        var request = RecordMeetingRequest(meetingId: meetingId, action: isLocalRecord ? .manageRejectLocalRecord : .hostRefuse)
        if isLocalRecord {
            request.targetParticipant = requester
        } else {
            request.requester = requester
        }
        httpClient.send(request, completion: completion)
    }

    // 会中录制提示文案优化: https://bytedance.feishu.cn/docs/doccngJEXSKtYYh8ezJdYjywTye#
    private var recordingStop: MsgInfo?
    private func requestStopI18n(_ msgInfo: MsgInfo, force: Bool = false) {
        guard let titleKey = msgInfo.msgTitleI18NKey, let messageKey = msgInfo.msgI18NKey else { return }
        if !force {
            if msgInfo == recordingStop { return }
            self.recordingStop = msgInfo
        }
        NoticeService.shared.updateI18NContents([titleKey, messageKey], httpClient: httpClient) { [weak self] contents in
            guard contents.count == 2 else { return }
            if let title = contents[0],
               let message = contents[1],
               let self = self,
               (title, message) != self.recordingStopMessageRelay.value {
                self.recordingStopMessageRelay.accept((title, message))
            }
            Self.logger.info("requestStopI18N success")
        }
    }

    private func updateStopI18n() {
        if let recordingStop = recordingStop {
            requestStopI18n(recordingStop, force: true)
        }
    }

    private func leaveMeeting() {
        InMeetLeaveAction.leaveMeeting(meeting: meeting)
    }

    private struct AskHostRecordRequest {
        let requester: ByteviewUser
        let name: String
        let policyURL: String
        let isLocalRecord: Bool
    }

    /// 升级套餐alert
    private func showUpgradeAlert(withContent content: String, scheme: String) {
        ByteViewDialog.Builder()
            .id(.upgradePlan)
            .title(content)
            .leftTitle(I18n.View_G_OkButton)
            .rightTitle(I18n.View_G_UpgradePlanButton)
            .rightHandler { [weak self] _ in
                self?.meeting.router.setWindowFloating(true)
                self?.meeting.larkRouter.goto(scheme: scheme)
            }
            .show()
    }

    func resetLaunchingStatusIfNeeded() {
        launchingShowCount -= 1
        if launchingShowCount == 0 {
            isLaunching = false
        }
    }

    func notesStartRecord() {
        listeners.forEach { $0.notesRequestStartRecording() }
    }
}

extension InMeetRecordViewModel: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        let isRecording = inMeetingInfo.isRecording
        if isRecording != oldValue?.isRecording {
            // 录制状态变更
            Logger.meeting.info("Record status changed: \(isRecording)")
        }
        if let data = inMeetingInfo.recordingData, let v2 = data.recordingStopV2,
           data.type == .recordingInfo || data.type == .recordingStatusChange {
            requestStopI18n(v2)
        }
    }
}

extension InMeetRecordViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .containerWillAppear:
            containerWillAppear()
            isViewControllerAppearSubject.onNext(true)
        case .containerDidDisappear:
            containerDidDisappear()
            isViewControllerAppearSubject.onNext(false)
        default:
            break
        }
    }
}

private class RecordingConfirmInfo {
    let content: String
    let scheme: String?
    init(content: String,
         scheme: String? = nil) {
        self.content = content
        self.scheme = scheme
    }
}
