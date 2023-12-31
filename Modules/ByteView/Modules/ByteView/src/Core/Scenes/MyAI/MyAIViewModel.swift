//
//  MyAIViewModel.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/7/12.
//

import Foundation
import ByteViewNetwork
import LarkLocalizations
import ByteViewTracker
import ByteViewSetting
import ByteViewUI
import RxSwift

protocol MyAIViewModelListener: AnyObject {
    func myAITitleDidUpdated()
}

extension MyAIViewModelListener {
    func myAITitleDidUpdated() {}
}

final class MyAIViewModel: InMeetMeetingProvider {
    let forbiddenDuration: TimeInterval = 30
    let meeting: InMeetMeeting
    let context: InMeetViewContext

    var chatID: String = ""
    var aiChatModeID: String = ""
    var chatConfig: MyAIChatConfig?

    var isEnabled: Bool { meeting.setting.isMyAIEnabled && service.myAI.isMyAIEnabled() }

    var isDependRecording: Bool { meeting.setting.isMyAIDependRecording }

    lazy var isOn: Bool = !meeting.setting.isChatWithAIOffOrInvalid {
        didSet {
            if oldValue != isOn {
                listeners.forEach { $0.myAITitleDidUpdated() }
                if isOn {
                    showFirstOpenGuideIfNeeded()
                } else {
                    Toast.showOnVCScene(I18n.View_G_HostTurnedOffAIInMeeting_Tooltip)
                    chatConfig?.closeMyAI()
                }
            }
        }
    }

    lazy var name: String = {
        // 取 AI 品牌名称作为兜底，能够取到用户设置昵称就不会走到此处逻辑
        meeting.setting.aiBrandName
    }()

    var displayName: String {
        isShowListening ? (Display.pad ? I18n.View_G_AIIsListeningToMeeting_Desc : I18n.View_G_AIIsListeningToMeeting_Button )  : name
    }

    var isShowListening: Bool { !isDependRecording && isOn }

    @RwAtomic
    var shouldOpenAIChat: Bool = false
    var isParticipentEnabled: Bool = true {
        didSet {
            if isParticipentEnabled {
                participentEnableWorkItem?.cancel()
                participentEnableWorkItem = nil
            }
        }
    }
    var participentEnableWorkItem: DispatchWorkItem?

    let listeners = Listeners<MyAIViewModelListener>()

    let disposeBag = DisposeBag()

    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
        meeting.addListener(self)
        meeting.router.addListener(self)
        meeting.setting.addListener(self, for: .isMyAIEnabled)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.push.notice.addObserver(self)
        observeMyAIName()
    }

    deinit {
        if let config = chatConfig {
            config.closeMyAI()
            config.clear()
            if !VCScene.supportsMultipleScenes {
                meeting.router.setWindowFloating(false)
            }
        }
    }

    func addListener(_ listener: MyAIViewModelListener) {
        listeners.addListener(listener)
    }

    func observeMyAIName() {
        service.myAI.observeName(with: disposeBag) { [weak self] name in
            if name.isEmpty { return }
            self?.name = name
            Util.runInMainThread {
                self?.listeners.forEach { $0.myAITitleDidUpdated() }
            }
        }
    }

    func open() {
        shouldOpenAIChat = true
        if isDependRecording || isOn {
            openAIChat()
        } else {
            if meeting.type == .meet {
                if meeting.myself.isHost {
                    showHostOpenAlert()
                } else if checkParticipantRequestIsEnabled() {
                    showParticipantOpenAlert()
                }
            }
            if meeting.type == .call, checkParticipantRequestIsEnabled() {
                capabilityControlRequest(with: .participantRequestStart, requester: meeting.myself.user)
                show1v1RequestToast()
            }
        }
    }

    /// 主持人开启弹窗
    private func showHostOpenAlert() {
        ByteViewDialog.Builder()
            .id(.hostOpenMyAI)
            .title(I18n.View_G_EnableAIDuringMeeting_Title)
            .message(I18n.View_G_EnableAIDuringMeeting_Desc)
            .leftTitle(I18n.View_G_DontEnableAIInMeeting_Button)
            .leftHandler({ _ in
                self.shouldOpenAIChat = false
            })
            .rightTitle(I18n.View_G_EnableAIInMeeting_Button)
            .rightHandler { _ in
                self.hostOpenRequest()
            }
            .show()
    }

    private func showParticipantOpenAlert() {
        ByteViewDialog.Builder()
            .id(.participantOpenMyAI)
            .title(I18n.View_G_AskHostToUseAIInMeeting_Title)
            .message(I18n.View_G_AskHostToUseAIInMeeting_Desc)
            .leftTitle(I18n.View_G_CancelAskForAI_Button)
            .leftHandler({ _ in
                self.shouldOpenAIChat = false
            })
            .rightTitle(I18n.View_G_ConfirmAskForAI_Button)
            .rightHandler { _ in
                self.capabilityControlRequest(with: .participantRequestStart, requester: self.meeting.myself.user)
            }
            .show()
    }

    private func showConfirmAlert(with user: ByteviewUser) {
        httpClient.participantService.participantInfo(pid: user.participantId, meetingId: meetingId) { info in
            Util.runInMainThread {
                ByteViewDialog.Builder()
                    .id(.confirmOpenMyAI)
                    .title(I18n.View_G_SomeoneAskedForAI_Title(info.name))
                    .message(I18n.View_G_SomeoneAskedForAI_Desc)
                    .leftTitle(I18n.View_G_DontGiveThemAI_Button)
                    .leftHandler({ _ in
                        self.capabilityControlRequest(with: .hostRefuse, requester: user)
                    })
                    .rightTitle(I18n.View_G_OKGiveThemAI_Button)
                    .rightHandler { _ in
                        self.capabilityControlRequest(with: .hostAccept, requester: user)
                    }
                    .show()
            }
        }
    }

    private func show1v1RequestToast() {
        let name = self.meeting.participant.another?.userInfo?.name ?? ""
        let toast = I18n.View_G_AfterTheyAgreeUseAI_Desc(name)
        Toast.showOnVCScene(toast)
    }

    private func showFirstOpenGuideIfNeeded() {
        if meeting.storage.bool(forKey: .myAiOpenGuide) { return }
        meeting.storage.set(true, forKey: .myAiOpenGuide)
        let guide = GuideDescriptor(type: .myai, title: nil, desc: I18n.View_G_AIIsHelpingYouSecretly_Tooltip)
        guide.style = .darkPlain
        guide.duration = 6
        GuideManager.shared.request(guide: guide)
    }

    private func showStartFailureGuide() {
        let guide = GuideDescriptor(type: .security, title: nil, desc: I18n.View_G_AINotWorkingInMeetingItsTurnedOff_Desc)
        guide.style = .darkPlain
        guide.duration = 6
        GuideManager.shared.request(guide: guide)
    }

    private func checkParticipantRequestIsEnabled() -> Bool {
        if !isParticipentEnabled {
            Toast.showOnVCScene(I18n.View_G_RequestSentShort)
        }
        return isParticipentEnabled
    }

    private func hostOpenRequest() {
        Logger.myAI.info("HostManageRequest start")
        var request = HostManageRequest(action: .intelligentMeetingSetting, meetingId: meetingId, breakoutRoomId: meeting.breakoutRoomId)
        var intelligentMeetingSetting = meeting.setting.intelligentMeetingSetting
        intelligentMeetingSetting.chatWithAiInMeeting = .featureStatusOn
        request.intelligentMeetingSetting = intelligentMeetingSetting
        httpClient.send(request) { res in
            if case .failure(let error) = res {
                Logger.myAI.error("HostManageRequest failure: \(error)")
                self.shouldOpenAIChat = false
            }
        }
    }

    private func capabilityControlRequest(with action: MeetingAICapabilityAction, requester: ByteviewUser) {
        Logger.myAI.info("capabilityControlRequest, action: \(action)")
        let permData = AICapabilityPermData(action: action, capability: .aiChat, requester: requester)
        let request = MeetingAICapabilityControlRequest(meetingId: meetingId, permData: permData)
        httpClient.send(request) { res in
            if case .failure(let error) = res {
                Logger.myAI.error("MeetingAICapabilityControlRequest failure: \(error), action: \(action)")
                self.shouldOpenAIChat = false
            }
        }
        if action == .participantRequestStart {
            isParticipentEnabled = false
            let workItem = DispatchWorkItem { [weak self] in
                self?.isParticipentEnabled = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + forbiddenDuration, execute: workItem)
        }
    }


    private func openAIChat() {
        shouldOpenAIChat = false
        if service.myAI.isMyAINeedOnboarding() {
            openOnboarding()
        } else {
            Logger.myAI.info("do not need onboarding")
            checkMyAIInfo()
        }
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "my_ai", .target: "vc_ai_chat_view"])
    }

    private func checkMyAIInfo() {
        if chatID.isEmpty || aiChatModeID.isEmpty {
            getMyAIInfo { [weak self] success in
                if success {
                    self?.openMyAI()
                } else {
                    Toast.show(I18n.View_VM_ErrorTryAgain)
                }
            }
        } else {
            openMyAI()
        }
    }

    private func openOnboarding() {
        meeting.larkRouter.activeWithTopMost { [weak self] vc in
            let from = self?.meeting.router.topMost ?? vc
            self?.service.myAI.openMyAIOnboarding(from: from) { success in
                if success {
                    Logger.myAI.info("onboarding success")
                    self?.checkMyAIInfo()
                } else {
                    Logger.myAI.info("onboarding failed")
                }
            }
        }
    }

    private  func openMyAI() {
        guard let cid = Int64(chatID), let aid = Int64(aiChatModeID) else { return }
        let meetingId = meeting.meetingId
        let config = MyAIChatConfig(chatId: cid, aiChatModeId: aid, objectId: meeting.meetingId, toolIds: meeting.setting.myAIToolIdConfig.meetingToolIds)
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let applink = meeting.setting.applinkDomain
        let recordStatus = meeting.setting.showsRecord ? 1 : 0
        let featureConfig: [String: Int] = ["recording_status": recordStatus]
        var jsonString = ""
        if let jsonData = try? JSONEncoder().encode(featureConfig), let str = String(data: jsonData, encoding: .utf8) {
            jsonString = str
        }
        config.appContextDataProvider = {
            ["vc_meeting_id": meetingId,
             "vc_locale": LanguageManager.currentLanguage.identifier,
             "vc_applink_host": applink,
             "vc_app_version": appVersion,
             "vc_feature_config": jsonString]
        }
        config.quickActionsParamsProvider = {
            ["vc_meeting_id": meetingId,
             "vc_locale": LanguageManager.currentLanguage.identifier,
             "vc_applink_host": applink,
             "vc_app_version": appVersion,
             "vc_feature_config": jsonString]
        }
        config.activeBlock = { [weak self] isActive in
            Util.runInMainThread {
                self?.activeStatusDidChanged(isActive)
            }
        }
        if !VCScene.supportsMultipleScenes {
            meeting.router.setWindowFloating(true)
        }
        meeting.larkRouter.activeWithTopMost { vc in
            self.service.myAI.openMyAIChat(with: config, from: vc)
        }
        chatConfig = config
        Logger.myAI.info("open my ai")
    }

    private func getMyAIInfo(success: @escaping ((Bool) -> Void)) {
        func getInfo(linkURL: String) {
            meeting.httpClient.getResponse(GetVCMyAIInitInfoRequest(meetingID: meeting.meetingId, linkURL: linkURL)) { [weak self] result in
                switch result {
                case .success(let res):
                    Util.runInMainThread {
                        self?.chatID = res.chatID
                        self?.aiChatModeID = res.aiChatModeID
                        success(true)
                        Logger.myAI.info("get my ai info success")
                    }
                case .failure(let error):
                    Util.runInMainThread {
                        success(false)
                        Logger.myAI.info("get my ai info failed: \(error)")
                    }
                }
            }
        }

        func getURL(with linkURL: String) -> String {
            "\(linkURL)?meetingId=\(meeting.meetingId)&source=vc_myai"
        }

        if let url = meeting.data.inMeetingInfo?.meetingURL, !url.isEmpty {
            getInfo(linkURL: getURL(with: url))
        } else {
            meeting.httpClient.getResponse(GetMeetingURLInfoRequest(meetingId: meeting.meetingId)) { result in
                switch result {
                case .success(let info):
                    getInfo(linkURL: getURL(with: info.meetingURL))
                case .failure(let error):
                    Util.runInMainThread {
                        success(false)
                        Logger.myAI.info("get meeting url failed: \(error)")
                    }
                }
            }
        }
    }

    private func activeStatusDidChanged(_ isActive: Bool) {
        if !isActive {
            if !VCScene.supportsMultipleScenes {
                meeting.router.setWindowFloating(false)
            }
            DispatchQueue.main.async {
                self.chatConfig?.clear()
                self.chatConfig = nil
            }
        }
        Logger.myAI.info("my ai is active: \(isActive)")
    }
}

extension MyAIViewModel: InMeetMeetingListener {
    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.chatConfig?.closeMyAI()
        }
    }
}

extension MyAIViewModel: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if !isFloating, !VCScene.supportsMultipleScenes {
            chatConfig?.closeMyAI()
        }
    }
}

extension MyAIViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if !isEnabled {
            Util.runInMainThread {
                self.chatConfig?.closeMyAI()
            }
        }
    }
}

extension MyAIViewModel: InMeetingChangedInfoPushObserver {
    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        guard data.type == .intelligentMeetingSetting else { return }
        Logger.myAI.info("didReceiveInMeetingChangedInfo, action: \(data.intelligentMeetingSetting?.permData.action)")
        Util.runInMainThread {
            self.isOn = !self.meeting.setting.isChatWithAIOffOrInvalid

            if let permData = data.intelligentMeetingSetting?.permData {
                switch permData.action {
                case .participantRequestStart:
                    self.shouldOpenAIChat = false
                    self.showConfirmAlert(with: permData.requester)
                case .hostAccept:
                    self.shouldOpenAIChat = true
                    self.isParticipentEnabled = true
                case .hostRefuse:
                    self.isParticipentEnabled = true
                    self.shouldOpenAIChat = false
                    let toast = self.meeting.type == .meet ? I18n.View_G_HostDidntWantAI_Toast : I18n.View_G_TheyRejectedYourRequestToUseAI_Toast
                    Toast.showOnVCScene(toast)
                case .unknow:
                    break
                @unknown default:
                    break
                }
            }
            if self.isOn, self.shouldOpenAIChat {
                self.openAIChat()
            }
        }
    }
}

extension MyAIViewModel: VideoChatNoticePushObserver {
    func didReceiveNotice(_ notice: VideoChatNotice) {
        if notice.type == .tips, notice.meetingID == meeting.meetingId, notice.popupType == .popupAiChatAutoTurnOnFailed {
            showStartFailureGuide()
        }
    }
}
