//
//  InMeetTranscribeViewModel.swift
//  ByteView
//
//  Created by yangyao on 2023/6/17.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import ByteViewTracker

protocol InMeetTranscribeViewModelListener: AnyObject {
    func launchingStatusDidChanged()
    func clickTranscribeButton()
}

extension InMeetTranscribeViewModelListener {
    func launchingStatusDidChanged() {}
    func clickTranscribeButton() {}
}

struct InMeetTranscribeDefine {
    static func generateSceneInfo(with meetingId: String) -> SceneInfo {
        return SceneInfo(key: SceneKey.vcSideBar, id: "TranscriptViewController_\(meetingId)")
    }
}

final class InMeetTranscribeViewModel: VideoChatNoticePushObserver, VideoChatNoticeUpdatePushObserver, InMeetingChangedInfoPushObserver, InMeetParticipantListener, BreakoutRoomManagerObserver {

    static let logger = Logger.ui
    private let player: RtcAudioPlayer
    let meeting: InMeetMeeting

    lazy var sceneInfo: SceneInfo = {
        var sceneInfo = InMeetTranscribeDefine.generateSceneInfo(with: meeting.meetingId)
        sceneInfo.title = I18n.View_G_Transcribe_Title
        return sceneInfo
    }()

    weak var controller: TranscriptViewController?
    weak var sceneNaviVC: UINavigationController?

    let breakoutRoom: BreakoutRoomManager?
    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.player = RtcAudioPlayer(meeting: self.meeting)
        self.breakoutRoom = resolver.resolve()
        bindTranscribing()
        resolver.viewContext.addListener(self, for: [.containerWillAppear, .containerDidDisappear])
        meeting.push.notice.addObserver(self)
        meeting.push.noticeUpdate.addObserver(self)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        self.breakoutRoom?.addObserver(self)
        if #available(iOS 13.0, *) {
            VCSideBarSceneService.addProvider(self, for: self.sceneInfo)
        }
    }

    deinit {
        askHostTranscribeAlert?.dismiss()
        transcribingConfirmAlert?.dismiss()
        if #available(iOS 13.0, *) {
            VCSideBarSceneService.removeProvider(for: self.sceneInfo)
        }
    }
    // 默认false
    let requestedButBeforeTranscribing = BehaviorRelay<Bool>(value: false)
    let cancelDelayEnableRequestTranscribeSubject = PublishSubject<Void>()
    func enableRequestTranscribing() {
        requestedButBeforeTranscribing.accept(false)
        cancelDelayEnableRequestTranscribeSubject.onNext(Void())
    }

    // 参会人转录合规Alert
    private weak var transcribingConfirmAlert: ByteViewDialog?
    private var transcribingConfirmAlertShowing = false
    /// 是否应显示Alert，默认为true；如服务端推送了需要显示则为true；如服务端推送了dismiss则为false
    private var shouldShowAlert: Bool = true
    private weak var askHostTranscribeAlert: ByteViewDialog?

    private lazy var transcribingConfirmInfoSubject = PublishSubject<TranscribingConfirmInfo>()

    var transcribingStopTitle: String { transcribingStopMessageRelay.value.0 }
    var transcribingStopMessage: String { transcribingStopMessageRelay.value.1 }
    var meetingId: String { meeting.meetingId }
    var isShowingTranscribeRequest: Bool = false
    @RwAtomic
    private(set) var isTranscribing: Bool = false

    private var trackSign: Int = 0
    private let transcribingStopMessageRelay = BehaviorRelay<(String, String)>(value: ("", ""))
    let disposeBag = DisposeBag()
    let isViewControllerAppearSubject = PublishSubject<Bool>()
    private let askTranscribingUserSubject = PublishSubject<ByteviewUser>()
    private lazy var askTranscribingUserObservable: Observable<ByteviewUser> = askTranscribingUserSubject.asObservable()
    private var httpClient: HttpClient { meeting.httpClient }
    private let listeners = Listeners<InMeetTranscribeViewModelListener>()

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

    func addListener(_ listener: InMeetTranscribeViewModelListener) {
        listeners.addListener(listener)
    }

    private lazy var clientDynamicLink = meeting.setting.clientDynamicLink

    func didReceiveNotice(_ notice: VideoChatNotice) {
        if notice.type == .popup, notice.meetingID == meeting.meetingId, notice.popupType == .popupTranscribingConfirm {
            NoticeService.shared.updateI18NContent(notice.msgI18NKey, httpClient: httpClient) { [weak self] message in
                self?.shouldShowAlert = true
                if let msgI18NKey = notice.msgI18NKey {
                    self?.transcribingConfirmInfoSubject.onNext(TranscribingConfirmInfo(content: message ?? notice.message, scheme: msgI18NKey.jumpScheme))
                } else {
                    self?.transcribingConfirmInfoSubject.onNext(TranscribingConfirmInfo(content: ""))
                }
            }
        }

        // 播报转录语音提醒
        if notice.type == .voice, notice.meetingID == meeting.meetingId, !notice.extra.isEmpty {
            let extraInfo = notice.extra
            let languageString = BundleI18n.getCurrentLanguageString()
            Self.logger.info("start play transcribe voice by \(languageString)")
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
            Self.logger.info("Parse transcribe dict failed: \(voiceResourceString.hash)")
            return
        }
        let req = PullVcStaticResourceRequest(downloadURL: downloadURL, resourceName: resourceName, version: version)
        httpClient.getResponse(req) { [weak self] result in
            switch result {
            case .success(let response):
                // rust返回的是绝对路径，因此需要转换一下变为相对路径，且做一下文件校验
                let resultPath = response.localPath
                guard let splitResult = resultPath.components(separatedBy: "Documents").last else { Self.logger.info("transcribe voice file path error")
                    return
                }
                guard let transcribeVoicePath = self?.meeting.storage.getAbsPath(root: .document, relativePath: splitResult).absoluteString else {
                    return
                }
                if FileManager.default.fileExists(atPath: transcribeVoicePath) {
                    self?.player.play(.transcribeVoice(filePath: transcribeVoicePath)) { isSuccess in
                        if !isSuccess {
                            Self.logger.info("mixPlay transcribe voice failed")
                        }
                    }
                } else {
                    Self.logger.info("transcribe voice file not exist")
                }
            case .failure:
                Self.logger.info("pull transcribe static resource failed")
            }
        }
    }

    func didReceiveNoticeUpdate(_ message: VideoChatNoticeUpdate) {
        if message.type == .popup, message.meetingID == meeting.meetingId, message.key == "View_M_RecordingConsentTitle" {
            // 收起转录合规的Alert
            Util.runInMainThread { [weak self] in
                self?.transcribingConfirmAlertShowing = false
                self?.transcribingConfirmAlert?.dismiss()
                self?.transcribingConfirmAlert = nil
                self?.shouldShowAlert = false
            }
        }
    }

    func didReceiveInMeetingChangedInfo(_ message: InMeetingData) {
        guard message.meetingID == meetingId, message.type == .transcript, let data = message.transcriptInfo else {
            return
        }

        switch data.type {
        case .participantRequest:
            // 只关心参会人请求Start Transcribe
            let user = data.requester
            let policyURL: String = data.policyURL
            let participantService = httpClient.participantService
            participantService.participantInfo(pid: user, meetingId: meeting.meetingId) { [weak self] (ap) in
                Util.runInMainThread {
                    // 主持人收到转录请求弹窗
                    self?.showAskHostTranscribeAlert(request: .init(requester: user, name: ap.name, policyURL: policyURL))
                }
            }
        case .statusChange:
            if isTranscribing != true && data.isTranscribing {
                if !meeting.myself.isHost, !self.isTranscriptViewOpened {
                    self.showGuide()
                }
            }
            isTranscribing = data.isTranscribing

            if !meeting.router.isFloating {
                enableRequestTranscribing()
                if !data.isTranscribing, data.transcriptStatus != .initializing {
                    Toast.showOnVCScene(I18n.View_G_StopTranscriptionToast)
                }
            }
        case .hostResponse:
            // 当我是参会人，我的Transcribe请求被主持人(1v1对方)refuse or accept
            if !data.isTranscribing {
                if self.meeting.type == .meet {
                    Toast.showOnVCScene(I18n.View_G_HostDeclineTranscribe)
                } else {
                    let name = self.meeting.participant.another?.userInfo?.name ?? ""
                    Toast.showOnVCScene(I18n.View_G_Transcribe_DeclineNote(name))
                }
            }
            self.requestedButBeforeTranscribing.accept(false)
        default:
            break
        }
    }

    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        updateStopI18n()
    }

    private func containerWillAppear() {
        guard let request = requireReopenRequest else { return }
        // 如主持人未确认是否开启转录，（点隐私政策后）再回到会中页面时恢复AlertController
        showAskHostTranscribeAlert(request: request)
    }

    private func containerDidDisappear() {
        guard requireReopenRequest != nil else { return }
        askHostTranscribeAlert?.dismiss()
        askHostTranscribeAlert = nil
    }

    private let notificationID = UUID().uuidString
    // 当我是主持人，收到参会人Transcibe请求逻辑
    private var requireReopenRequest: AskHostTranscribeRequest?
    /// 主持人收到转录请求弹窗
    private func showAskHostTranscribeAlert(request: AskHostTranscribeRequest) {
        if self.isShowingTranscribeRequest { return }
        let name = request.name
        let message: String
        let title: String
        if self.meeting.type == .meet {
            title = I18n.View_G_Transcribe_RequestTitle
            message = I18n.View_G_Transcribe_WhatHappensAnother(name)
        } else {
            title = I18n.View_G_Transcribe_RequestTitle
            message = I18n.View_G_Transcribe_WhatHappens(name)
        }
        self.isShowingTranscribeRequest = true
        let meetType = meeting.type

        ByteViewDialog.Builder()
            .id(.requestTranscribe)
            .title(title)
            .linkText(LinkTextParser.parsedLinkText(from: message), alignment: .center, handler: { [weak self] (_, _) in
                guard let self = self else { return }
                self.isShowingTranscribeRequest = false
                self.askHostTranscribeAlert?.dismiss()
                self.askHostTranscribeAlert = nil
                self.requireReopenRequest = request
                self.meeting.router.setWindowFloating(true)
                self.meeting.larkRouter.goto(scheme: request.policyURL)
            })
            .leftTitle(I18n.View_G_DeclineButton)
            .leftHandler({ [weak self] _ in
                self?.isShowingTranscribeRequest = false
                self?.refuseTranscribeRequest(from: request.requester)
                self?.requireReopenRequest = nil
            })
            .rightTitle(I18n.View_G_ApproveButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                self.isShowingTranscribeRequest = false
                // 接受转录请求
                self.acceptTranscribeRequest(from: request.requester, contextIdCallback: { _ in
                }, { result in
                    switch result {
                    case .success:
                        self.isLaunching = meetType == .meet
                    case .failure:
                        break
                    }
                })

                self.requireReopenRequest = nil
            })
            .show { [weak self] alert in
                if let self = self {
                    self.askHostTranscribeAlert = alert
                } else {
                    alert.dismiss()
                }
            }

        let showsDetail = meeting.setting.shouldShowDetails
        if UIApplication.shared.applicationState != .active {
            let body: String
            if showsDetail && self.meeting.type == .meet {
                body = I18n.View_G_NameRequestTranscribeMeeting(name)
            } else if showsDetail && self.meeting.type == .call {
                body = I18n.View_G_NameRequestTranscribeCall(name)
            } else {
                body = I18n.View_G_YouReceivedRequest
            }
            UNUserNotificationCenter.current().addLocalNotification(withIdentifier: notificationID, body: body)
        }
    }

    func bindTranscribing() {
        Observable.combineLatest(transcribingConfirmInfoSubject.asObservable(), isViewControllerAppearSubject.asObservable())
            .filter { [weak self] _ in
                guard let self = self else {
                    return false
                }
                return self.shouldShowAlert
            }
            .subscribe(onNext: { [weak self] (info: TranscribingConfirmInfo, isVCAppear: Bool) in
                guard let self = self else { return }
                if !self.transcribingConfirmAlertShowing && isVCAppear {
                    self.transcribingConfirmAlertShowing = true
                    ByteViewDialog.Builder()
                        .id(.transcribingConfirm)
                        .colorTheme(.tendencyConfirm)
                        .title(I18n.View_G_Transcribe_Ing)
                        .linkText(LinkTextParser.parsedLinkText(from: info.content), alignment: .center, handler: { [weak self] (_, _) in
                            guard let self = self, let scheme = info.scheme else { return }
                            self.meeting.router.setWindowFloating(true)
                            self.meeting.larkRouter.goto(scheme: scheme)
                        })
                        .leftTitle(I18n.View_M_LeaveMeetingShort)
                        .leftHandler({ [weak self] _ in
                            guard let self = self else { return }
                            self.leaveMeeting()
                            self.transcribingConfirmAlertShowing = false
                            self.shouldShowAlert = false
                        })
                        .rightTitle(I18n.View_M_StayInMeetingShort)
                        .rightHandler({ [weak self] _ in
                            guard let self = self else { return }
                            self.transcribingConfirmAlertShowing = false
                            self.shouldShowAlert = false
                        })
                        .show { [weak self] alert in
                            if let self = self {
                                self.transcribingConfirmAlert = alert
                            } else {
                                alert.dismiss()
                            }
                        }
                } else if self.transcribingConfirmAlertShowing && !isVCAppear {
                    self.transcribingConfirmAlertShowing = false
                    self.transcribingConfirmAlert?.dismiss()
                    self.transcribingConfirmAlert = nil
                }
            })
            .disposed(by: disposeBag)
    }

    /// 点击停止转录按钮
    func requestStopTranscribing(onConfirm: (() -> Void)?) {
        let meetType = meeting.type
        let title: String
        let transcribingStopMessageTitle = transcribingStopTitle
        if !transcribingStopMessageTitle.isEmpty {
            title = transcribingStopMessageTitle
        } else if meetType == .meet {
            title = I18n.View_G_Transcript_StopPop
        } else {
            title = I18n.View_G_Transcript_StopPop
        }
        let transcribingStopMessage = transcribingStopMessage

        MeetSettingTracks.trackStopTranscribing()

        ByteViewDialog.Builder()
            .id(.requestStopTranscribe)
            .colorTheme(.redLight)
            .title(title)
            .message(transcribingStopMessage)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .transcribeStop, action: "cancel")
            })
            .rightTitle(I18n.View_G_StopButton)
            .rightHandler({ [weak self] _ in
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .transcribeStop, action: "stop")

                guard let self = self else { return }
                onConfirm?()

                self.stopTranscribing()
            })
            .show()
    }

    /// 主持人开始转录请求
    func startTranscribing(contextIdCallback: ((String) -> Void)? = nil, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        if trackSign == 0 {
            MeetSettingTracks.trackStartTranscribing()
            trackSign = 1
        }
        let request = MeetingTranscribeRequest(meetingId: self.meeting.meetingId, action: .start)
        var options = NetworkRequestOptions()
        options.contextIdCallback = contextIdCallback
        httpClient.send(request, options: options, completion: completion)
    }

    /// 参会人/单人请求转录请求
    func requestTranscribing(_ completion: ((Result<Void, Error>) -> Void)? = nil) {
        let request = MeetingTranscribeRequest(meetingId: meeting.meetingId, action: .participantRequestStart)
        httpClient.send(request, completion: completion)
    }

    /// 主持人停止转录请求
    private func stopTranscribing(contextIdCallback: ((String) -> Void)? = nil, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        let request = MeetingTranscribeRequest(meetingId: self.meeting.meetingId, action: .stop)
        httpClient.send(request, completion: completion)
    }

    /// 接受转录请求
    private func acceptTranscribeRequest(from requester: ByteviewUser, contextIdCallback: ((String) -> Void)? = nil, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        let request = MeetingTranscribeRequest(meetingId: self.meetingId, action: .hostAccept, requester: requester)
        var options = NetworkRequestOptions()
        options.contextIdCallback = contextIdCallback
        httpClient.send(request, options: options, completion: completion)
    }

    /// 拒绝转录请求
    private func refuseTranscribeRequest(from requester: ByteviewUser, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        let request = MeetingTranscribeRequest(meetingId: self.meetingId, action: .hostRefuse, requester: requester)
        httpClient.send(request, completion: completion)
    }

    private var transcribingStop: MsgInfo?
    private func requestStopI18n(_ msgInfo: MsgInfo, force: Bool = false) {
        guard let titleKey = msgInfo.msgTitleI18NKey, let messageKey = msgInfo.msgI18NKey else { return }
        if !force {
            if msgInfo == transcribingStop { return }
            self.transcribingStop = msgInfo
        }
        NoticeService.shared.updateI18NContents([titleKey, messageKey], httpClient: httpClient) { [weak self] contents in
            guard contents.count == 2 else { return }
            if let title = contents[0],
               let message = contents[1],
               let self = self,
               (title, message) != self.transcribingStopMessageRelay.value {
                self.transcribingStopMessageRelay.accept((title, message))
            }
            Self.logger.info("requestStopI18N success")
        }
    }

    private func updateStopI18n() {
        if let transcribingStop = transcribingStop {
            requestStopI18n(transcribingStop, force: true)
        }
    }

    private func leaveMeeting() {
        InMeetLeaveAction.leaveMeeting(meeting: meeting)
    }

    private struct AskHostTranscribeRequest {
        let requester: ByteviewUser
        let name: String
        let policyURL: String
    }

    func resetLaunchingStatusIfNeeded() {
        launchingShowCount -= 1
        if launchingShowCount == 0 {
            isLaunching = false
        }
    }
}

extension InMeetTranscribeViewModel {
    func showGuide() {
        let guide = GuideDescriptor(type: .transcribe, title: nil, desc: I18n.View_G_Transcribe_StartedNote)
        guide.style = .darkPlain
        guide.duration = 3
        GuideManager.shared.request(guide: guide)
    }

    func showTranscribeContent() {
        Util.runInMainThread { [weak self] in
            self?.openTranscriptView()
        }
    }

    func closeTranscribeContent() {
        Util.runInMainThread { [weak self] in
            self?.closeTranscriptView()
        }
    }

    /// 点击了转录/停止转录按钮
    func transcribeAction() {
        listeners.forEach { $0.clickTranscribeButton() }
    }
}

extension InMeetTranscribeViewModel: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        let isTranscribing = inMeetingInfo.isTranscribing
        if isTranscribing != oldValue?.isTranscribing {
            // 转录状态变更
            Logger.meeting.info("Transcribe status changed: \(isTranscribing)")
        }

        if let data = inMeetingInfo.transcriptInfo, let v2 = data.transcriptStopV2, data.type == .statusChange {
            // 请求文案
            requestStopI18n(v2)
        }
    }
}

extension InMeetTranscribeViewModel: InMeetViewChangeListener {
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

extension InMeetTranscribeViewModel {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        closeTranscribeContent()
    }
}

extension InMeetTranscribeViewModel: VCSideBarSceneProvider {

    var isTranscriptViewOpened: Bool {
        if #available(iOS 13, *), VCScene.supportsMultipleScenes, let scene = VCScene.connectedScene(scene: self.sceneInfo) {
            return scene.activationState == .foregroundActive
        } else {
            return controller != nil
        }
    }

    private func createTranscriptVCIfNeeded() -> UINavigationController {
        let naviVC: UINavigationController
        if let nvc = sceneNaviVC {
            naviVC = nvc
        } else {
            let transcriptViewModel = TranscriptViewModel(meeting: meeting, transcribeViewModel: self)
            let transcriptViewController = TranscriptViewController(viewModel: transcriptViewModel)
            naviVC = NavigationController(rootViewController: transcriptViewController)
            sceneNaviVC = naviVC
            controller = transcriptViewController
        }
        return naviVC
    }

    @available(iOS 13.0, *)
    func createViewController(scene: UIScene,
                              session: UISceneSession,
                              options: UIScene.ConnectionOptions,
                              sceneInfo: SceneInfo,
                              localContext: AnyObject?) -> UIViewController?
    {
        if sceneInfo != self.sceneInfo {
            return nil
        }
        return createTranscriptVCIfNeeded()
    }
}

// MARK: - open & close
extension InMeetTranscribeViewModel {

    func openTranscriptView() {
        if #available(iOS 13, *), VCScene.supportsMultipleScenes {
            meeting.router.openByteViewScene(sceneInfo: sceneInfo, keepOpenForActivated: true, completion: { [weak self] _, _ in
                self?.controller?.isScene = true
            })
        } else {
            let naviVC = createTranscriptVCIfNeeded()
            meeting.router.setWindowFloating(true)
            naviVC.modalPresentationStyle = .fullScreen
            meeting.larkRouter.present(naviVC, animated: true)
        }
    }

    func closeTranscriptView() {
        controller?.close()
    }
}

private class TranscribingConfirmInfo {
    let content: String
    let scheme: String?
    init(content: String,
         scheme: String? = nil) {
        self.content = content
        self.scheme = scheme
    }
}
