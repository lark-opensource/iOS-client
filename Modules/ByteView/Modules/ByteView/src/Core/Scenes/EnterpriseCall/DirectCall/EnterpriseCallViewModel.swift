//
//  EnterpriseCallViewModel.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/7/1.
//

import Foundation
import RxSwift
import ByteViewTracker
import ByteViewNetwork
import LarkMedia
import ByteViewCommon
import ByteViewMeeting
import ByteViewUI
import ByteViewSetting
import UniverseDesignIcon

protocol EnterpriseCallViewModelDelegate: AnyObject {
    func statusTextDidChange(_ text: String)
    func meetingStateDidChange(_ state: MeetingState)
    func directItemsDidChange()
    func didTapDiaPad()
    func didUpdateMeeting()
    func didChangeMuteBeforeOntheCall(isMute: Bool)
    func didChangeAudioput(audioOutput: AudioOutput)
}

enum PhoneCallHandle {
    case enterprisePhoneNumber(String)
    case ipPhone(String)
    case ipPhoneBindLark(ParticipantId?)
    case recruitmentPhoneNumber(String)
    case userID(String)
    case candidateID(String)
}


final class EnterpriseCallViewModel: MeetingBasicServiceProvider {
    static let callingText = I18n.View_MV_Calling_Phone
    static let noResponseInterval: TimeInterval = 15
    static let callingTimeoutInterval: TimeInterval = 60
    static let noResponseToastDuration: TimeInterval = 10

    static let micMutedIcon: UDIconType = .micOffFilled
    static let micOnIcon: UDIconType = .micFilled

    let session: MeetingSession
    let service: MeetingBasicService
    var handle: PhoneCallHandle
    var avatarKey: String?
    var userName: String?

    let micItem = EnterpriseCallItem(title: I18n.View_MV_Mic_CallComes, icon: EnterpriseCallViewModel.micOnIcon)
    let numberPadItem = EnterpriseCallItem(title: I18n.View_G_DialPad, icon: .dialpadFilled)
    let speakerItem = EnterpriseCallItem(title: I18n.View_G_Receiver, icon: .earFilled)
    let recordItem = EnterpriseCallItem(title: I18n.View_G_Record, icon: .recordFilled)
    let meetingItem = EnterpriseCallItem(title: I18n.View_G_MeetingIcon, icon: .videoFilled)
    // 文案 key 定义如此，非 bug
    let minimizeItem = EnterpriseCallItem(title: I18n.View_M_SpeakerName, icon: .minimizeFilled)
    lazy var items: [EnterpriseCallItem] = [micItem, numberPadItem, speakerItem, recordItem, meetingItem, minimizeItem]

    private var inMeetViewModel: InMeetViewModel?

    var updateInfo: (() -> Void)?

    var avatarInfo: AvatarInfo {
        if let avatarKey = avatarKey, !avatarKey.isEmpty {
            return .remote(key: avatarKey, entityId: "")
        } else {
            return .asset(ByteViewCommon.BundleResources.ByteViewCommon.Avatar.unknown)
        }
    }

    var calledParticpant: Participant? {
        meeting?.participant.find(status: .all) { $0.user.id != session.account.id }
    }

    var isFromFloating = false
    var shouldChangeSpeakerIcon = false {
        didSet {
            if shouldChangeSpeakerIcon != oldValue, shouldChangeSpeakerIcon {
                Util.runInMainThread { [weak self] in
                    if let self = self, let audioOutput = self.session.audioDevice?.output {
                        self.didChangeAudioOutput(audioOutput, reason: .route)
                    }
                }
            }
        }
    }
    private var lastAudioOutput: AudioOutput?
    private var isCallKitAudioSessionReady = false
    private var isSoundPlaying = false
    private var isRingingReceivedDataProcessed: Bool = false
    private var extraInfo: VideoChatExtraInfo.RingingReceivedData?
    private var info: VideoChatInfo?

    private var player: RtcAudioPlayer?

    weak var delegate: EnterpriseCallViewModelDelegate?

    private let disposeBag = DisposeBag()
    var statusText = ""
    private var statusTimer: Timer?
    private(set) var isMuted: Bool {
        didSet {
            micItem.isHighlighted = isMuted
            micItem.icon = isMuted ? Self.micMutedIcon : Self.micOnIcon
            delegate?.directItemsDidChange()
        }
    }
    private var meetingSettings: MicCameraSetting

    private var callingTime: CFTimeInterval?
    private var invitationReceivedTime: CFTimeInterval?
    private(set) var meeting: InMeetMeeting?
    var httpClient: HttpClient { session.httpClient }

    init?(session: MeetingSession, meeting: InMeetMeeting?, handle: PhoneCallHandle,
          avatarKey: String? = nil, userName: String? = nil) {
        guard let service = session.service else { return nil }
        self.service = service
        self.session = session
        self.meeting = meeting
        self.handle = handle
        self.avatarKey = avatarKey
        self.userName = userName
        self.isMuted = session.state == .onTheCall ? (meeting?.microphone.isMuted ?? false) : false
        self.meetingSettings = MicCameraSetting.onlyAudio
        self.shouldChangeSpeakerIcon = isFromFloating
        self.player = RtcAudioPlayer(session: session)
        if let audioOutput = session.audioDevice?.output {
            didChangeAudioOutput(audioOutput, reason: .route)
            audioOutput.addListener(self)
        }
        setupAudioSession()
        setupItems()
        setupMeetingStatusListener()
        session.addListener(self)
        session.push?.extraInfo.addObserver(self)

        if session.state == .onTheCall {
            didEnterOnTheCall()
        }

        switch handle {
        case .ipPhoneBindLark(let pid):
            if let pid = pid {
                let participantService = httpClient.participantService
                participantService.participantInfo(pid: pid, meetingId: session.meetingId) { ap in
                    self.userName = ap.name
                    if case .remote(let key, _) = ap.avatarInfo {
                        self.avatarKey = key
                    } else {
                        self.avatarKey = ""
                    }
                    self.updateInfo?()
                }
            }
        default:
            break
        }
        doPageTrack()
    }

    deinit {
        if isSoundPlaying {
            player?.stop(.dialing(ringtone: session.setting?.customRingtone))
        }
    }

    // MARK: - Public

    func hangup() {
        session.leave()
        shouldChangeSpeakerIcon = false
    }

    // MARK: - Private
    private var isCallingOrDialing: Bool {
        session.state == .dialing || session.state == .calling
    }

    private func setupAudioSession() {
        session.callCoordinator.waitAudioSessionActivated { [weak self] result in
            if let self = self, result.isSuccess {
                self.isCallKitAudioSessionReady = true
                self.playSound()
            }
        }
    }

    private func setupItems() {
        micItem.action = { [weak self] in
            self?.toggleMicrophone()
        }

        numberPadItem.action = { [weak self] in
            self?.showNumberPad()
        }

        recordItem.isEnabled = session.state == .onTheCall
        recordItem.action = { [weak self] in
            self?.recordMeeting()
        }

        meetingItem.isEnabled = session.state == .onTheCall
        meetingItem.action = { [weak self] in
            self?.upgradeMeeting()
        }

        minimizeItem.action = { [weak self] in
            self?.minimize()
        }
    }

    private func setupMeetingStatusListener() {
        if session.state == .calling {
            updateStatusText(Self.callingText)
        } else if session.state == .onTheCall {
            setupStatusTimer()
        }
    }

    private func updateStatusText(_ text: String) {
        Util.runInMainThread {
            self.statusText = text
            self.delegate?.statusTextDidChange(text)
        }
    }

    private func setupStatusTimer() {
        statusTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] (t) in
            if let self = self {
                self.updateDuration()
            } else {
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        statusTimer = timer
    }

    private func updateDuration() {
        guard let startTime = meeting?.startTime else { return }
        let time = Int(Date().timeIntervalSince(startTime))
        guard time >= 0 else {
            updateStatusText("")
            return
        }
        // disable-lint: magic number
        let hour = time / 3600
        let minute = (time % 3600) / 60
        let second = time % 60
        // enable-lint: magic number
        let s = hour > 0 ? String(format: "%02d:%02d:%02d", hour, minute, second) : String(format: "%02d:%02d", minute, second)
        updateStatusText(s)
    }

    private func playSound() {
        if !isSoundPlaying && isCallingOrDialing {
            isSoundPlaying = true
            player?.play(.dialing(ringtone: session.setting?.customRingtone), playCount: -1)
        }
    }

    private func didEnterOnTheCall() {
        [recordItem, meetingItem].forEach { $0.isEnabled = true }
        player?.stop(.dialing(ringtone: session.setting?.customRingtone))
        VCTracker.post(name: .vc_business_phone_call_status, params: ["process": "end",
                                                                      "status": "success",
                                                                      "action_match_id": session.enterpriseCallParams?.enterpriseCallMatchID ?? "",
                                                                      "is_two_way_call": "false",
                                                                      "initial_tab": session.enterpriseCallParams?.enterpriseCallStartType])
        Util.runInMainThread {
            self.isSoundPlaying = false
            if let meeting = self.findMeeting() {
                self.inMeetViewModel = InMeetViewModel(meeting: meeting)
                meeting.data.addListener(self)
                meeting.microphone.addListener(self)
            }
        }
    }

    private func updateSettings() {
        var request = ParticipantChangeSettingsRequest(session: session)
        request.participantSettings.isMicrophoneMuted = !meetingSettings.isMicrophoneEnabled
        request.participantSettings.isCameraMuted = !meetingSettings.isCameraEnabled
        httpClient.send(request)
    }

    private func handleRingingReceivedData() {
        guard !isRingingReceivedDataProcessed, let info = info, let extra = extraInfo else {
            return
        }

        Logger.meeting.info("[\(info.id)]: handleRingingReceivedData, extra = \(extra)")
        isRingingReceivedDataProcessed = true
        let isInvitationReceived = extra.meetingID == info.id && extra.participant.user.id != info.host.id
        if isInvitationReceived {
            let receiveTime = CACurrentMediaTime()
            if let callingTime = self.callingTime {
                /// 拨号成功
                VCTracker.post(name: .vc_call_dialingduration, params: ["call_duration": Int64((receiveTime - callingTime) * 1000)])
            }
        }
    }

    private func startCallingTimer() {
        let noResponseTimer = Timer(timeInterval: Self.noResponseInterval, repeats: false) { [weak self] (_) in
            if let self = self, !self.router.isFloating, self.session.state == .calling {
                Toast.show(I18n.View_VM_NoResponseTryAgain, duration: Self.noResponseToastDuration)
            }
        }
        RunLoop.main.add(noResponseTimer, forMode: .common)

        let timeoutTimer = Timer(timeInterval: Self.callingTimeoutInterval, repeats: false) { [weak self] (_) in
            self?.handleCallingTimeout()
        }
        RunLoop.main.add(timeoutTimer, forMode: .common)
    }

    private func handleCallingNoResponse() {
        guard isCallingOrDialing else { return }
        if !router.isFloating {
            Toast.show(I18n.View_VM_NoResponseTryAgain, duration: Self.noResponseToastDuration)
        }
    }

    private func handleCallingTimeout() {
        guard isCallingOrDialing else { return }
        session.reportCallingTimeout()
    }

    private func requestRecording(for meetType: MeetingType) {
        Toast.showLoading(I18n.View_G_SwitchingToMeeting, completion: nil)
        let request = RecordMeetingRequest(meetingId: session.meetingId, action: .participantRequestStart)
        httpClient.send(request) { [weak self] result in
            guard let self = self else { return }
            if result.isSuccess {
                Logger.enterpriseCall.info("requestRecording success")
                self.session.canShowAudioToast = false ///保证录制中的toast不被audio toast覆盖掉
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {  [weak self] in
                    self?.session.canShowAudioToast = true
                }
            } else {
                Logger.enterpriseCall.info("requestRecording error")
            }
        }
    }

    private func requestUpgradeMeeting() {
        Toast.showLoading(I18n.View_G_SwitchingToMeeting, completion: nil)
        httpClient.send(UpgradeSingleToMeetingRequest(meetingId: session.meetingId, topic: nil)) { result in
            switch result {
            case .success:
                Logger.enterpriseCall.info("upgradeSingleToMeeting request success")
            case .failure(let error):
                Toast.show(I18n.View_G_FailSwitchMeeting, type: .error)
                Logger.enterpriseCall.info("upgradeSingleToMeeting error: \(error)")
            }
        }
    }

    private func findMeeting() -> InMeetMeeting? {
        if self.meeting == nil, session.state == .onTheCall {
            self.meeting = session.component(for: OnTheCallState.self)?.meeting
        }
        return self.meeting
    }

    // MARK: - Actions

    private func toggleMicrophone() {
        if let mic = meeting?.microphone {
            mic.muteMyself(!isMuted, source: .direct_call, completion: nil)
        } else {
            let oldValue = isMuted
            meetingSettings.isMicrophoneEnabled = oldValue
            isMuted = !oldValue
            updateSettings()
            delegate?.didChangeMuteBeforeOntheCall(isMute: isMuted)
        }
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_click,
                       params: [.click: "mic", "option": isMuted ? "close" : "open", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
    }

    private func showNumberPad() {
        delegate?.didTapDiaPad()
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_click,
                       params: [.click: "dial", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
    }

    private func recordMeeting() {
        Util.runInMainThread {
            ByteViewDialog.Builder()
                .id(.requestRecord)
                .title(I18n.View_G_RecordNeedMeeting)
                .leftTitle(I18n.View_G_CancelTurnOff)
                .leftHandler({ _ in
                    VCTracker.post(name: .vc_office_phone_calling_popup_click,
                                   params: [.click: "cancel", "content": "start_record"])
                })
                .rightTitle(I18n.View_G_Record)
                .rightHandler({ [weak self] _ in
                    self?.requestRecording(for: .call)
                    VCTracker.post(name: .vc_office_phone_calling_popup_click,
                                   params: [.click: "confirm", "content": "start_record"])
                })
                .show()
        }
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_click,
                       params: [.click: "record", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
    }

    private func upgradeMeeting() {
        self.requestUpgradeMeeting()
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_click,
                       params: [.click: "start_conference", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
    }

    private func minimize() {
        router.setWindowFloating(true)
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_click,
                       params: [.click: "minimize", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
    }

    private func getCallParamsTrack() -> (String, String) {
        let userType = session.videoChatInfo?.inviterId == session.userId ? "caller" : "callee"
        switch handle {
        case .enterprisePhoneNumber, .recruitmentPhoneNumber, .userID, .candidateID:
            return (userType, "office_call")
        case .ipPhone, .ipPhoneBindLark:
            return (userType, "ip_phone")
        }
    }

    private func doPageTrack() {
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_view, params: ["user_type": callParams.0, "call_source": callParams.1])

    }
}

extension EnterpriseCallViewModel: MeetingSessionListener {
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        Logger.enterpriseCall.info("didEnterState type:\(state), from:\(from)")
        if state == .onTheCall {
            didEnterOnTheCall()
        } else if state == .calling {
            info = event.videoChatInfo
            self.callingTime = CACurrentMediaTime()
            updateSettings()
            handleRingingReceivedData()
            startCallingTimer()
        }
        setupMeetingStatusListener()

        Util.runInMainThread {
            self.delegate?.meetingStateDidChange(state)
        }
    }
}

extension EnterpriseCallViewModel: InMeetMicrophoneListener {
    func didChangeMicrophoneMuted(_ microphone: InMeetMicrophoneManager) {
        Util.runInMainThread {
            self.isMuted = microphone.isMuted
            if !microphone.isMuted {
                self.session.audioDevice?.output.setMuted(false)
            }
        }
    }
}

extension EnterpriseCallViewModel: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        let audioOutput = output.currentOutput
        Logger.audio.info("phoneCall audio: \(audioOutput), last: \(lastAudioOutput), reasion: \(reason)")
        guard lastAudioOutput != audioOutput else { return }
        if output.lastRouteChangeReason.isDeviceChanged {
            self.shouldChangeSpeakerIcon = true
        }
        lastAudioOutput = audioOutput
        switch audioOutput {
        case .speaker:
            speakerItem.icon = .speakerFilled
            speakerItem.title = I18n.View_VM_Speaker
            speakerItem.isHighlighted = true
            let callParams = getCallParamsTrack()
            VCTracker.post(name: .vc_office_phone_calling_click,
                           params: [.click: "speaker", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
        case .receiver:
            speakerItem.icon = .earFilled
            speakerItem.title = I18n.View_G_Receiver
            speakerItem.isHighlighted = false
            let callParams = getCallParamsTrack()
            VCTracker.post(name: .vc_office_phone_calling_click,
                           params: [.click: "receiver", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
        case .bluetooth:
            speakerItem.icon = .bluetoothFilled
            speakerItem.title = I18n.View_G_Bluetooth
            speakerItem.isHighlighted = true
            let callParams = getCallParamsTrack()
            VCTracker.post(name: .vc_office_phone_calling_click,
                           params: [.click: "bluetooth", "status": trackParam().0, "is_link_bluetooth": trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
        case .headphones:
            speakerItem.icon = .headphoneFilled
            speakerItem.title = I18n.View_G_Headphones
            speakerItem.isHighlighted = true
        default:
            break
        }
        ProximityMonitor.updateAudioOutput(route: audioOutput, isMuted: output.isMuted)
        delegate?.directItemsDidChange()
        delegate?.didChangeAudioput(audioOutput: audioOutput)
    }
}

extension EnterpriseCallViewModel: VideoChatExtraInfoPushObserver {
    func didReceiveExtraInfo(_ extraInfo: VideoChatExtraInfo) {
        if extraInfo.type == .ringingReceived, let data = extraInfo.ringingReceivedData {
            self.extraInfo = data
            handleRingingReceivedData()
        }
    }
}

extension EnterpriseCallViewModel: InMeetDataListener {
    func didUpgradeMeeting(_ type: MeetingType, oldValue: MeetingType) {
        Toast.hideAllToasts()
        Logger.enterpriseCall.info("didUpgradeMeeting type:\(type), old:\(oldValue)")
        if type == .meet, let meeting = self.meeting {
            delegate?.didUpdateMeeting()
            router.startRoot(InMeetBody(meeting: meeting))
        }
    }
}

extension EnterpriseCallViewModel {
    func trackParam() -> (String, String) {
        var status = ""
        if session.state == .calling {
            status = "calling"
        } else if session.state == .onTheCall {
            status = "in_the_call"
        }
        return (status, (LarkAudioSession.shared.currentOutput == .bluetooth ? "true" : "false"))
    }
}
