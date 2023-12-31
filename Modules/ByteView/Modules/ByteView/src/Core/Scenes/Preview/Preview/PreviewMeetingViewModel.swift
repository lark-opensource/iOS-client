//
//  PreviewMeetingViewModel.swift
//  ByteView
//
//  Created by ford on 2019/5/20.
//

import Foundation
import AVFoundation
import LarkMedia
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import ByteViewUI
import ByteViewSetting
import ByteViewRtcBridge

enum ToastType {
    case mic(String)
    case audio
    case camera(PreviewCameraManager.ToastContent)
    case allowLab(String)
    case resident(String, TimeInterval)
}

protocol PreviewMeetingViewModelDelegate: AnyObject {
    /// 保证在主线程
    func didChangeShowErrorText(_ isShow: Bool)
    func didChangeLabButtonHidden(_ isHidden: Bool)
    func didChangeExtraBgDownloadStatus(status: ExtraBgDownLoadStatus)

    /// 不保证在主线程
    func didChangeTopic(_ topic: String)
    func didChangeCommitEnabled(_ isEnabled: Bool)
    func didChangeMicStatus(_ isOn: Bool)
    func didChangeCameraStatus(_ isOn: Bool)
    func didChangeAudioOutput(_ output: AudioOutputManager)
    func speakerViewWillAppear()
    func speakerViewWillDisappear()
    func didChangePreviewParticipants(_ participants: [PreviewParticipant])
    func didChangeAvatarInfo(_ avatarInfo: AvatarInfo)
    func didChangeVirtualBgEnabled(_ isOn: Bool)
    func didChangeJoinedDeviceInfos()
}

extension PreviewMeetingViewModelDelegate {
    func didChangeAudioOutput(_ output: AudioOutputManager) {}
    func speakerViewWillAppear() {}
    func speakerViewWillDisappear() {}
}

final class PreviewMeetingViewModel: MeetingBasicServiceProvider {

    static let logger = Logger.preview
    let params: PreviewViewParams
    let isJoiningMeeting: Bool
    let isWebinarAttendee: Bool
    let camera: PreviewCameraManager
    let isHiddenCamMic: Bool
    let session: MeetingSession
    let service: MeetingBasicService
    let effectManger: MeetingEffectManger?
    private let placeholderId: String
    private let isLeftToRight: Bool     //判断placeholder使用的语言语序是否是从左往右
    private let audioSessionFixer = LarkAudioSession.shared.fixAudioSession([.activeOnForeground, .activeOnAlarmEnd])

    // MARK: - memory attribute
    var liveCheckClosure: ((String?) -> Void)?
    var showToast: ((ToastType) -> Void)?
    var joinTogetherRoomer: ByteviewUser?
    @RwAtomic private(set) var avatarInfo: AvatarInfo?
    @RwAtomic private(set) var videoChatInfo: VideoChatInfo?
    @RwAtomic private(set) var interviewRole: ParticipantRole?
    private var nearbyRoomID: String?
    weak var delegate: PreviewMeetingViewModelDelegate?
    private weak var livePolicyAlert: ByteViewDialog?

    var shouldShowAudioToast = false
    var isSwitchAudioFromRoom: Bool = false
    var audioType: ParticipantSettings.AudioMode = .internet  // 入会音频模式
    @RwAtomic private(set) var participants: [PreviewParticipant] = []
    @RwAtomic private(set) var bgDownloadStatus: ExtraBgDownLoadStatus = .unStart
    private var isHandleEffectForCalendar = false
    private var isCommitBtnJoining: Bool = false
    private var isPreviewClosed = false
    private var hasVideoChatInfoReponse = false // 是否收到VideoChatInfoReponse

    private(set) var joinedDeviceInfos: [JoinedDeviceInfo]?
    private(set) var joinedDeviceSetting: ParticipantSettings?
    var replaceJoinFgEnabled: Bool {
        session.setting?.isReplaceJoinedDeviceEnabled ?? false
    }
    var replaceJoinEnabled: Bool {
        replaceJoinFgEnabled && joinedDeviceInfos?.isEmpty == false
    }

    var meetingNumber: String = "" {
        didSet {
            showErrorText = false
            if meetingNumber != oldValue {
                isCommitEnabled = Self.isMeetingNumberValid(meetingNumber)
            }
        }
    }

    var selectedAudioType: PreviewAudioType = .system {
        didSet {
            if selectedAudioType == .noConnect {
                isMicOn = false
            }
        }
    }

    var isMicOn: Bool {
        didSet {
            guard isMicOn != oldValue else { return }
            delegate?.didChangeMicStatus(self.isMicOn)
        }
    }

    private(set) var isCommitEnabled: Bool = true {
        didSet {
            guard isCommitEnabled != oldValue else { return }
            delegate?.didChangeCommitEnabled(self.isCommitEnabled)
        }
    }

    private(set) var isHiddenLabButton: Bool {
        didSet {
            guard isHiddenLabButton != oldValue else { return }
            Util.runInMainThread {
                self.delegate?.didChangeLabButtonHidden(self.isHiddenLabButton)
            }
        }
    }

    private(set) var defaultTopic: String {
        didSet {
            guard !defaultTopic.isEmpty, defaultTopic != oldValue else { return }
            delegate?.didChangeTopic(self.defaultTopic)
        }
    }

    private(set) var showErrorText: Bool = false {
        didSet {
            guard showErrorText != oldValue else { return }
            Util.runInMainThread {
                self.delegate?.didChangeShowErrorText(self.showErrorText)
            }
        }
    }

    private(set) var isMuteOnEntry: Bool = false {
        didSet {
            if isMuteOnEntry {
                isMicOn = false
            }
        }
    }

    private var _isCameraOn: Bool {
        didSet {
            guard _isCameraOn != oldValue else { return }
            delegate?.didChangeCameraStatus(_isCameraOn)
        }
    }

    private(set) lazy var joinRoom = JoinRoomTogetherViewModel(service: service, provider: PreviewJoinRoomProvider(viewModel: self), audioOutputManager: session.audioDevice?.output)
    private(set) lazy var previewAudios: [PreviewAudioType] = {
        var audioTypes: [PreviewAudioType] = [.system]
        if isE2EeMeeting || Display.pad {
            audioTypes.append(.noConnect)
        } else if self.setting.isCallMeEnabled, !isWebinarAttendee {
            audioTypes.append(contentsOf: [.pstn, .noConnect])
        }
        return audioTypes
    }()

    private(set) lazy var previewViewModel: PreviewViewModel = {
        return PreviewViewModel(session: session, service: service, isJoinByNumber: isJoinByNumber, isJoiningMeeting: isJoiningMeeting, isJoinRoomEnabled: isJoinRoomEnabled, shouldShowUnderline: shouldShowUnderline, isLeftToRight: isLeftToRight, isWebinar: params.isWebinar, topic: params.topic, isCameraOn: isCameraOn, camera: camera)
    }()

    private lazy var calendarInstance: CalendarInstanceIdentifier? = {
        if case .uniqueId(let instance) = params.idType {
            return instance
        }
        return nil
    }()

    private lazy var sourceDetails: GetAssociatedVideoChatRequest.SourceDetails? = {
        guard params.isJoinByMeetingId else { return nil }
        var sourceDetails: GetAssociatedVideoChatRequest.SourceDetails?
        switch params.idType {
        case .meetingId(let chatId, let messageId):
            let sourceType: GetAssociatedVideoChatRequest.SourceDetails.SourceType
            switch params.source.toJoinSource() {
            case .card: sourceType = .card
            case .tab: sourceType = .tab
            case .calendarNotice: sourceType = .calendarNotice
            case .chat: sourceType = .chat
            default: sourceType = .unknownSource
            }
            sourceDetails = .init(sourceType: sourceType, messageID: messageId, chatID: chatId)
        case .meetingIdWithGroupId(let groupId):
            sourceDetails = .init(sourceType: .chat, messageID: nil, chatID: groupId)
        default:
            sourceDetails = nil
        }
        return sourceDetails
    }()

    // MARK: - computation attribute
    var virtualBgService: EffectVirtualBgService? { effectManger?.virtualBgService }
    var pretendService: EffectPretendService? { effectManger?.pretendService }
    var isWebinar: Bool { params.isWebinar }
    var isE2EeMeeting: Bool { session.isE2EeMeeting }
    var isJoinRoomEnabled: Bool { setting.isJoinRoomTogetherEnabled && !isWebinar && !isE2EeMeeting && !params.isInterview }
    var placeholderText: String? { isJoiningMeeting || isJoinByCalendar ? nil : params.topic }
    var isPadMicSpeakerDisabled: Bool { Display.pad && setting.isMicSpeakerDisabled && audioType == .internet }
    var isJoinByNumber: Bool { params.idType == .meetingNumber }
    private var isCreateOrNumberMeeting: Bool { params.idType == .createMeeting || params.idType == .meetingNumber }
    var isJoinByCalendar: Bool {
        switch params.idType {
        case .uniqueId, .groupIdWithUniqueId:
            return true
        default:
            return false
        }
    }

    var shouldShowUnderline: Bool {
        switch params.idType {
        case .meetingId, .meetingIdWithGroupId:
            return false
        case .meetingNumber:
            return true
        case .groupId, .createMeeting:
            return true
        case .uniqueId, .groupIdWithUniqueId:
            return false
        case .interviewUid:
            return false
        case .reservationId:
            return false
        }
    }

    var isCameraOn: Bool {
        get { _isCameraOn }
        set {
            guard _isCameraOn != newValue else { return }
            camera.setMuted(!newValue)
            let isOn = !camera.isMuted
            if _isCameraOn != isOn {
                _isCameraOn = isOn
            }
        }
    }

    // MARK: - init
    init?(session: MeetingSession, joinParams: PreviewViewParams) {
        guard let service = session.service else { return nil }
        self.session = session
        self.service = service
        self.placeholderId = session.sessionId
        self.params = joinParams
        self.isJoiningMeeting = joinParams.isJoinMeeting
        self.isLeftToRight = joinParams.isLTR
        self.camera = PreviewCameraManager(scene: .preview, service: service, effectManger: session.effectManger)
        self.effectManger = session.effectManger

        if let topic = params.topic, !topic.isEmpty {
            self.defaultTopic = topic
        } else {
            self.defaultTopic = I18n.View_G_ServerNoTitle
        }
        let lastSetting = service.setting.micCameraSetting
        self.isMicOn = Privacy.audioAuthorized && lastSetting.isMicrophoneEnabled && !service.setting.isMicSpeakerDisabled && !params.isWebinarAttendee
        self._isCameraOn = Privacy.videoAuthorized && lastSetting.isCameraEnabled && !params.isWebinarAttendee
        self.isHiddenCamMic = params.isWebinarAttendee
        self.isWebinarAttendee = params.isWebinarAttendee
        self.isHiddenLabButton = !service.setting.showsEffects || params.isWebinarAttendee
        if params.idType == .meetingNumber {
            self.meetingNumber = params.id
            self.isCommitEnabled = PreviewMeetingViewModel.isMeetingNumberValid(meetingNumber)
        } else {
            self.meetingNumber = ""
            self.isCommitEnabled = true
        }
        camera.delegate = self
        handleEffectForCalendar()
        getVideoChatInfo()
        getAvatarInfo()
        setupUltrawaveRecognition()
        setupAudioOutput()
        setting.addListener(self, for: [.showsEffects, .isVirtualBgEnabled, .isAnimojiEnabled])
        NetworkErrorHandlerImpl.shared.addListener(self)
        Logger.preview.info("init PreviewMeetingViewModel(\(session.sessionId)), idType: \(joinParams.idType)")
    }

    deinit {
        Logger.ui.info("deinit PreviewMeetingViewModel(\(session.sessionId))")
        livePolicyAlert?.dismiss()
    }

    func handleDeinit() {
        guard Display.pad, !isPreviewClosed else { return }
        // iPad formsheet时用户点击阴影区目前没有合适的回调，所以在deinit时调用一次关闭
        session.executeInQueue(source: "deinitPreview") {
            if self.session.state == .preparing {
                self.session.log("closePreview when deinit")
                self.closePreview()
            }
        }
    }

    func closePreview() {
        if isPreviewClosed { return }
        isPreviewClosed = true
        shouldShowAudioToast = false
        UltrawaveManager.shared.stopRecv()
        if !isCommitBtnJoining { session.leave() }
        camera.releaseCamera()
    }

    func muteMic() {
        Privacy.requestMicrophoneAccessAlert { [weak self] result in
            Util.runInMainThread {
                guard let self = self, case .success = result else {
                    return
                }
                let micOn = self.isMicOn
                self.isMicOn = !micOn
                let tip = micOn ? I18n.View_VM_MicOff : I18n.View_VM_MicOn
                self.showToast?(.mic(tip))
            }
        }
    }

    func muteCamera() {
        if !isCameraOn, !CameraSncWrapper.getCheckResult(by: .preview) {
            Toast.show(I18n.View_VM_CameraNotWorking)
            return
        }

        Privacy.requestCameraAccessAlert { [weak self] in
            guard let self = self, $0.isSuccess else {
                VCTracker.post(name: .vc_meeting_pre_popup_view, params: [.content: "cam_no_permission"])
                return
            }
            self.isCameraOn = !self.isCameraOn
            PreviewReciableTracker.startOpenCamera()
        }
    }

    func joinMeeting(topic: String, replaceJoin: Bool?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard ReachabilityUtil.isConnected else {
            Toast.show(I18n.View_G_NoConnection)
            self.session.leave()
            completion(.failure(VCError.badNetwork))
            return
        }

        let placeholderId = session.sessionId
        let startTime = Date().timeIntervalSince1970

        if isE2EeMeeting && params.isJoinMeeting {
            self.session.e2EeToastUtil = E2EeToastUtil(session: self.session)
            self.session.e2EeToastUtil?.showE2EeConnectingIfNeed(showToast)
        }
        isCommitBtnJoining = true
        let tempSession = session
        session.joinMeeting(joinMeetingParams(topic: topic, replaceJoin: replaceJoin), leaveOnError: false) { [weak self] in
            guard let self = self else {
                Logger.preview.info("PreviewMeetingVC is deinit")
                tempSession.leave()
                return
            }
            self.isCommitBtnJoining = false
            self.session.e2EeToastUtil?.removeE2EeConnectingIfNeed()
            self.session.e2EeToastUtil = nil
            switch $0 {
            case .success(let result):
                self.shouldShowAudioToast = false
                if let error = result.bizError {
                    JoinTracks.trackJoinMeetingFailed(placeholderId: placeholderId, error: error, timestamp: startTime)
                    if self.isJoinByNumber {
                        self.handleJoinMeetingError(error)
                        completion(.failure(error))
                        return
                    }
                    self.session.handleJoinMeetingBizError(error)
                    self.session.leave()
                }
                completion(.success(Void()))
            case .failure(let e):
                JoinTracks.trackJoinMeetingFailed(placeholderId: placeholderId, error: e, timestamp: startTime)
                if e.toVCError() == .currentIsE2EeMeeting, !self.isE2EeMeeting {
                    self.session.isE2EeMeeting = true
                    self.session.callCoordinator.checkPendingTransactions { [weak self] pending in
                        Logger.preview.info("callCoordinator checkPendingTransactions \(pending)")
                        // nolint-next-line: magic number
                        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(pending ? 500 : 0)) {
                            self?.joinMeeting(topic: topic, replaceJoin: replaceJoin, completion: completion)
                        }
                    }
                } else {
                    self.handleJoinMeetingError(e.toVCError())
                    completion(.failure(e))
                }
            }
        }
    }

    func livePrecheck(completion: @escaping (Result<Bool, Error>) -> Void) {
        // 当前无网络则直接绕过，之后会被拦截
        guard ReachabilityUtil.isConnected, setting.isLiveLegalEnabled else {
            completion(.success(true))
            return
        }

        if isJoinByNumber {
            livePrecheck(meetingId: nil, meetingNumber: meetingNumber, completion: completion)
        } else if params.idType != .createMeeting {
            if hasVideoChatInfoReponse {
                if let meetingId = videoChatInfo?.id {
                    livePrecheck(meetingId: meetingId, meetingNumber: nil, completion: completion)
                } else {
                    completion(.success(true))
                }
            } else {
                liveCheckClosure = { [weak self] id in
                    guard let self = self, let meetingId = id else {
                        completion(.success(true))
                        return
                    }
                    self.livePrecheck(meetingId: meetingId, meetingNumber: nil, completion: completion)
                }
            }
        } else {
            completion(.success(true))
        }
    }

    func placeholderWidth() -> CGFloat {
        let topic = isJoiningMeeting ? "" : params.topic
        let font = UIFont.systemFont(ofSize: 20, weight: .medium)
        let lineHight: CGFloat = 32
        let sideInsets: CGFloat = 32
        let width = topic?.vc.boundingWidth(height: lineHight, font: font) ?? 0.0
        return width + (shouldShowUnderline ? sideInsets : 0)
    }

    func trackPreviewCommit() {
        var status = "no_background"
        var type = ""
        if let virtualBg = virtualBgService?.currentVirtualBgsModel, virtualBg.bgType != .setNone {
            let trackName = LabTrack.virtualBgNameType(model: virtualBg)
            status = trackName.0
            type = trackName.1
        }

        var animoji = "close"
        if let animojiModel = pretendService?.currentAnimojiModel, animojiModel.bgType != .none {
            animoji = animojiModel.resourceId
        }

        var filter = "close"
        var filterValue: Int = 0
        if let filterModel = pretendService?.currentFilterModel, filterModel.bgType != .none {
            filter = filterModel.title
            filterValue = filterModel.currentValue ?? 0
        }

        var beauty = "close"
        var customDic = [String: Any]()
        let applyType = pretendService?.beautyCurrentStatus ?? .customize
        if let beautys = pretendService?.retuschierenArray, pretendService?.isBeautyOn() == true, !beautys.isEmpty {
            beauty = "default"
            for index in 1...beautys.count {
                let item = beautys[index - 1]
                let currentValue = item.applyValue(for: applyType)
                if currentValue != item.defaultValue, beauty != "custom" {
                    beauty = "custom"
                }
                customDic["id\(index)"] = item.resourceId
                customDic["value\(index)"] = currentValue ?? 0
                customDic["is_default\(index)"] = currentValue == item.defaultValue ? 1 : 0
            }
        }
        var customJson: String?
        if !customDic.isEmpty {
            do {
                let customData = try JSONSerialization.data(withJSONObject: customDic, options: [])
                customJson = String(data: customData, encoding: String.Encoding.ascii)
            } catch {
                Logger.tracker.debug("VC_MEETING_PRE_CLICK JSONSerialization fail")
            }
        }

        var params: TrackParams = [.click: "attend",
                                   .target: TrackEventName.vc_meeting_onthecall_view,
                                   "background_status": status,
                                   "background_type": type,
                                   "avatar_status": animoji,
                                   "touch_up_status": beauty,
                                   "filter_status": filter,
                                   "filter_value": filterValue,
                                   "is_cam_on": isCameraOn]

        if isJoinRoomEnabled {
            let ultrasonicRoomStatus: String
            if !self.setting.isUltrawaveEnabled {
                ultrasonicRoomStatus = "ultrasonic_off"
            } else if joinTogetherRoomer != nil {
                ultrasonicRoomStatus = "ultrasonic_room_found"
            } else {
                ultrasonicRoomStatus = "ultrasonic_room_not_found"
            }
            params["room_scan_status"] = ultrasonicRoomStatus
            if let room = joinTogetherRoomer {
                params["room_id"] = room.id
                let verifyCode = joinRoom.verifyCode
                if verifyCode.isEmpty {
                    params["connect_room_status"] = "connect_ready"
                } else {
                    params["connect_room_status"] = "input_share_code_success"
                    params["share_code"] = verifyCode
                }
            }
        }
        if let customJson = customJson {
            params["touch_up_custom_value"] = customJson
        }
        VCTracker.post(name: .vc_meeting_pre_click, params: params)
    }

    // MARK: - private func
    private func livePrecheck(meetingId: String?, meetingNumber: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        let placeholderId = self.placeholderId
        let policyURL = service.setting.policyURL
        session.httpClient.meeting.livePreCheck(meetingId: meetingId, meetingNumber: meetingNumber) { shouldShow in
            if shouldShow {
                Util.runInMainThread {
                    Policy.showJoinLivestreamedMeetingAlert(placeholderId: placeholderId, policyUrl: policyURL, handler: { granted in
                        completion(.success(granted))
                    }, completion: { [weak self] alert in
                        if let self = self {
                            self.livePolicyAlert = alert
                        } else {
                            alert.dismiss()
                        }
                    })
                }
            } else {
                completion(.success(true))
            }
        }
    }

    private func setupAudioOutput() {
        session.audioDevice?.output.setPadMicSpeakerDisabledIfNeeded()
        session.audioDevice?.output.addListener(self)
    }

    private func getVideoChatInfo() {
        guard !isCreateOrNumberMeeting else { return }
        let voucher = params.voucher
        let voucherType = params.voucherType
        let isLink = params.fromLink

        let request = GetAssociatedVideoChatRequest(id: voucher, idType: voucherType, needTopic: isLink, sourceDetails: sourceDetails, calendarInstanceIdentifier: calendarInstance)
        self.session.httpClient.getResponse(request, completion: {[weak self] res in
            self?.hasVideoChatInfoReponse = true
            switch res {
            case .success(let response):
                Logger.preview.info("getAssociatedVideoChat success")
                self?.videoChatInfo = response.videoChatInfo
                self?.interviewRole = response.interviewRole
                self?.isMuteOnEntry = response.videoChatInfo?.settings.isMuteOnEntry ?? false
                self?.getJoinedDevices()
                self?.updateAssociatedVideoChatInfo(response)
            case .failure(let error):
                self?.liveCheckClosure?(nil)
                Logger.preview.info("getAssociatedVideoChat error \(error)")
            }
        })
    }

    private func updateAssociatedVideoChatInfo(_ resp: GetAssociatedVideoChatResponse) {
        operateInterviewVirtualBgImage()
        if isJoiningMeeting && !isJoinByNumber {
            updateTopic(by: resp)
            updatePreviewParticipants()
        }
        liveCheckClosure?(videoChatInfo?.id)
    }

    private func operateInterviewVirtualBgImage() {
        Logger.preview.info("operateInterviewVirtualBgImage meetingSource: \(videoChatInfo?.meetingSource),  isVirtualBgEnabled : \(setting.isVirtualBgEnabled)")
        self.handleEffectForCalendar()
        if interviewRole == .interviewer {
            virtualBgService?.addJob(type: .people)
        }
    }

    private func updatePreviewParticipants() {
        if !params.isInterview {
            if let info = videoChatInfo {
                requestPreviewParticipants(info)
            } else {
                delegate?.didChangePreviewParticipants([])
            }
        }
    }

    private func handleJoinMeetingError(_ error: VCError) {
        if self.isJoinByNumber, error == .meetingNumberInvalid {
            // 会议号输入错误,不能关闭页面
            showErrorText = true
        } else {
            self.session.handleJoinMeetingBizError(error)
            // 遇到服务端问题(500等) || 监测到主持人版本低 || 不支持替代入会时，不主动关闭Preview页面，在上面的handBizError()中弹出提示
            // 其余走通用错误处理或统一兜底弹 toast
            if error != .unknown && error != .hostVersionLow && error != .replaceJoinUnsupported {
                self.session.leave()
            }
        }
    }

    private func getAvatarInfo() {
        let participantService = session.httpClient.participantService
        participantService.participantInfo(pid: .init(id: session.userId, type: .larkUser), meetingId: "") { ap in
            self.avatarInfo = ap.avatarInfo
            self.delegate?.didChangeAvatarInfo(ap.avatarInfo)
        }
    }

    private func updateTopic(by resp: GetAssociatedVideoChatResponse) {
        var topic = params.topic

        if params.fromLink {
            topic = params.isInterview ? I18n.View_M_VideoInterviewNameBraces(resp.topic) : resp.topic
        } else {
            topic = topic ?? videoChatInfo?.settings.topic
        }
        defaultTopic = topic ?? I18n.View_G_ServerNoTitle
    }

    private func handleEffectForCalendar() {
        guard !isHandleEffectForCalendar, (self.videoChatInfo?.meetingSource == .vcFromCalendar || params.calendarId != nil), (setting.isVirtualBgEnabled || setting.isAnimojiEnabled) else {
            Logger.preview.info("preview handleEffectForCalendar failed")
            return
        }
        isHandleEffectForCalendar = true

        handleEffectSetBg() //统一虚拟背景
        handleEffectAllow() //虚拟背景和Animoji权限管控
    }

    private func handleEffectSetBg() {
        Logger.preview.info("handleEffectForCalendar source: \(videoChatInfo?.meetingSource), \(session.meetingId) \(params.calendarId) \(virtualBgService?.extrabgDownloadStatus)")
        effectManger?.getForCalendarSetting(meetingId: self.videoChatInfo?.id, uniqueId: params.calendarId, isWebinar: params.isWebinar, isUnWebinarAttendee: nil)
        virtualBgService?.addCalendarListener(self, fireImmediately: true)
    }

    private func handleEffectAllow() {
        pretendService?.addCalendarListener(self, fireImmediately: true)
    }

    // disable-lint: duplicated code
    private func requestPreviewParticipants(_ info: VideoChatInfo) {
        let participants = info.participants
        if participants.isEmpty {
            delegate?.didChangePreviewParticipants([])
            return
        }
        let ids = participants.map({ $0.user.id })
        let duplicatedParticipantIds = Set(ids.reduce(into: [String: Int]()) { $0[$1] = ($0[$1] ?? 0) + 1 }
                                            .filter { $0.1 > 1 }.map { $0.key })
        var alreadyHasSponsor = false
        let sponsorId = info.sponsor.id
        let participantService = session.httpClient.participantService
        participantService.participantInfo(pids: participants, meetingId: info.id, completion: { [weak self] aps in
            guard let self = self else { return }
            var previewParticipants: [PreviewParticipant] = []
            zip(participants, aps).forEach { (participant, ap) in
                let showDevice = duplicatedParticipantIds.contains(participant.user.id)
                    && (participant.deviceType == .mobile || participant.deviceType == .web)
                let isSponsor: Bool
                if alreadyHasSponsor {
                    isSponsor = false
                } else {
                    isSponsor = sponsorId == participant.user.id
                    alreadyHasSponsor = isSponsor
                }
                let previewedParticipant = PreviewParticipant(userId: participant.user.id,
                                                              userName: ap.name,
                                                              avatarInfo: ap.avatarInfo,
                                                              participantType: participant.type,
                                                              isLarkGuest: participant.isLarkGuest,
                                                              isSponsor: isSponsor,
                                                              deviceType: participant.deviceType,
                                                              showDevice: showDevice,
                                                              tenantId: participant.tenantId,
                                                              tenantTag: participant.tenantTag,
                                                              bindId: participant.pstnInfo?.bindId ?? "",
                                                              bindType: participant.pstnInfo?.bindType ?? .unknown,
                                                              showCallme: participant.settings.audioMode == .pstn)
                previewParticipants.append(previewedParticipant)
            }
            self.participants = previewParticipants
            self.delegate?.didChangePreviewParticipants(previewParticipants)
        })
    }
    // enable-lint: duplicated code
    private func joinMeetingParams(topic: String, replaceJoin: Bool?) -> JoinMeetingParams {
        let setting = MicCameraSetting(isMicrophoneEnabled: isMicOn, isCameraEnabled: isCameraOn)
        let id = params.id
        var joinMeetingParams: JoinMeetingParams
        switch params.idType {
        case .createMeeting, .groupId, .groupIdWithUniqueId:
            let topicInfo = JoinMeetingRequest.TopicInfo(topic: topic, isCustomized: params.topic != topic)
            joinMeetingParams = JoinMeetingParams(joinType: .groupId(id), meetSetting: setting, topicInfo: topicInfo, replaceJoin: replaceJoin)
        case .meetingNumber:
            joinMeetingParams = JoinMeetingParams(joinType: .meetingNumber(meetingNumber), meetSetting: setting, replaceJoin: replaceJoin)
        case .meetingId, .meetingIdWithGroupId:
            joinMeetingParams = JoinMeetingParams(joinType: .meetingId(id, params.joinSource), meetSetting: setting, replaceJoin: replaceJoin)
        case .uniqueId:
            joinMeetingParams = JoinMeetingParams(joinType: .uniqueId(id), meetSetting: setting, requestType: .calendar,
                                       calendarSource: params.source.toCalendarSource(),
                                       calendarInstance: calendarInstance, replaceJoin: replaceJoin)
        case .interviewUid(let role):
            joinMeetingParams = JoinMeetingParams(joinType: .interviewId(id), meetSetting: setting, requestType: .interview, role: role, replaceJoin: replaceJoin)
        case .reservationId:
            joinMeetingParams = JoinMeetingParams(joinType: .reserveId(id), meetSetting: setting, replaceJoin: replaceJoin)
        }
        joinMeetingParams.audioMode = audioType
        joinMeetingParams.nearbyRoomID = nearbyRoomID
        joinMeetingParams.isE2EeMeeting = isE2EeMeeting
        if !isWebinarAttendee {
            joinMeetingParams.targetToJoinTogether = joinTogetherRoomer
        }
        return joinMeetingParams
    }

    fileprivate func roomBinderFilter() -> GetShareCodeInfoRequest.RoomBindFilter {
        let id = params.id
        switch params.idType {
        case .meetingNumber:
            return .generic(.meetingNumber(meetingNumber))
        case .meetingId, .meetingIdWithGroupId:
            return .generic(.meetingId(id, params.joinSource))
        case .groupId, .groupIdWithUniqueId:
            return .generic(.groupId(id))
        case .reservationId:
            return .generic(.reserveId(id))
        case .uniqueId:
            return .calendar(id)
        case .interviewUid:
            return .interview(id)
        case .createMeeting:
            // none代表不过滤，适用于会中投屏等场景
            // 会议室同步入会，需传generic过滤已被占用的会议室，约定groupId传0
            return .generic(.groupId("0"))
        }
    }

    // 获取会中同账号其它设备信息，需在getAssociatedVideoChat返回后调用
    private func getJoinedDevices() {
        guard self.replaceJoinFgEnabled, let videoChatInfo = self.videoChatInfo else { return }
        self.session.httpClient.getResponse(GetJoinedDeviceInfoRequest(), completion: { [weak self] res in
            if case .success(let response) = res {
                guard let self = self else { return }
                let devices = response.devices
                    .filter { $0.meetingID == videoChatInfo.id }
                    .sorted(by: { $0.joinTime < $1.joinTime })
                if let lastInfo = devices.last {
                    if let joinedSetting = videoChatInfo.participants.first(where: { $0.user.id == lastInfo.userID && $0.user.deviceId == lastInfo.deviceID })?.settings {
                        self.joinedDeviceSetting = joinedSetting
                    }
                    self.joinedDeviceInfos = devices
                    self.delegate?.didChangeJoinedDeviceInfos()
                }
                Logger.preview.info("getJoinedDevices success, total:\(response.devices.count), currentMeeting:\(devices.count)")
            }
        })
    }
}

// MARK: - Ultrawave
extension PreviewMeetingViewModel {
    private func isUltrawaveEnabled(function: String = #function, completion: @escaping (Bool) -> Void) {
        // 新建会议或连接蓝牙时不检测超声波
        guard setting.isAutoMuteWhenRoomInMeetingEnabled && isJoiningMeeting else {
            completion(false)
            return
        }
        DispatchQueue.global().async {
            let isBluetoothConnected = LarkAudioSession.shared.isBluetoothConnected
            DispatchQueue.main.async {
                completion(!isBluetoothConnected)
            }
        }
    }

    private func setupUltrawaveRecognition() {
        self.isUltrawaveEnabled { [weak self] isEnabled in
            if isEnabled {
                self?.startRecvingUltrawave()
            }
        }
    }

    private func startRecvingUltrawave() {
        if self.setting.isUltrawaveEnabled {
            var isSpeakerOn: Bool?
            if let audio = session.audioDevice?.output.currentOutput {
                isSpeakerOn = audio == .speaker
            }
            UltrawaveManager.shared.startRecv(config: setting.nfdScanConfig, usageType: .preview_auto, isSpeakerOn: isSpeakerOn) { [weak self] result in
                if case .success(let key) = result {
                    self?.fetchRoomID(by: key)
                }
            }
        }
    }

    func stopUltrawaveAndPrepareForMeeting() {
        UltrawaveManager.shared.stopRecv()
    }

    func canAutoScanJoinRoom() -> Bool {
        return self.params.idType != .createMeeting && self.isJoinRoomEnabled
        && self.joinRoom.isUltrasonicEnabled && self.joinRoom.connectionState != .manual
    }

    func autoscanJoinRoom(onRoomFound: @escaping () -> Void) {
        self.joinRoom.autoscan(onRoomFound: onRoomFound)
    }

    private func fetchRoomID(by shareCode: String) {
        session.httpClient.getResponse(GetRoomStatusByShareCodeRequest(shareCode: shareCode)) { [weak self] r in
            if let id = r.value?.roomId, !id.isEmpty {
                self?.nearbyRoomID = id
            }
        }
    }
}

// MARK: - protocol implementation
extension PreviewMeetingViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if virtualBgService?.calendarMeetingVirtual == nil {  // 防止admin数据比associate来的晚
            self.handleEffectForCalendar()
        }
        if key == .showsEffects {
            Logger.preview.info("did change lab setting showsEffects: \(isOn)")
            isHiddenLabButton = !isOn || isWebinarAttendee
        }
        if key == .isVirtualBgEnabled {
            Logger.preview.info("did change lab setting isVirtualBgEnabled: \(isOn)")
            delegate?.didChangeVirtualBgEnabled(isOn)
        }
    }
}

extension PreviewMeetingViewModel: EffectVirtualBgCalendarListener, EffectPretendCalendarListener {
    func didChangeExtrabgDownloadStatus(status: ExtraBgDownLoadStatus) {
        guard bgDownloadStatus != status else { return }
        bgDownloadStatus = status
        Util.runInMainThread {
            self.delegate?.didChangeExtraBgDownloadStatus(status: status)
        }
    }

    func didChangeVirtualBgAllow(allowInfo: AllowVirtualBgRelayInfo) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            Logger.preview.info("preview handle bg Allow \(allowInfo)")
            if !allowInfo.allow {
                self.camera.effect.enableBackgroundBlur(false)
                self.camera.effect.setBackgroundImage("")
                if let hasUsedBgInAllow = allowInfo.hasUsedBgInAllow, hasUsedBgInAllow {
                    // nolint-next-line: magic number
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 防止被初始化的麦克风顶掉
                        self.showToast?(.allowLab(I18n.View_G_HostNotAllowBackUse))
                        self.virtualBgService?.hasShowedNotAllowToast = true
                    }
                }
            }
        }
    }

    func didChangeAnimojAllow(isAllow: Bool) {
        Util.runInMainThread { [weak self] in
            Logger.effectPretend.info("preview handle animoji isAllow \(isAllow), \(self?.pretendService?.isAnimojiOn())")
            if !isAllow, self?.pretendService?.isAnimojiOn() == true {
                self?.pretendService?.cancelAnimoji()
            }
        }
    }
}

extension PreviewMeetingViewModel: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        if output.isDisabled || output.isMuted, isMicOn {
            isMicOn = false
        }
        if UltrawaveManager.shared.isRecvingUltrawave { return }
        if reason == .mute, output.isMuted {
            showToast?(.audio)
        } else if reason == .route, !output.isMuted, !output.isDisabled {
            showToast?(.audio)
        }
        delegate?.didChangeAudioOutput(output)
    }

    func audioOutputPickerWillAppear() {
        delegate?.speakerViewWillAppear()
    }

    func audioOutputPickerWillDisappear() {
        delegate?.speakerViewWillDisappear()
    }

    func audioOutputPickerDidAppear() {
        delegate?.speakerViewWillAppear()
    }

    func audioOutputPickerDidDisappear() {
        delegate?.speakerViewWillDisappear()
    }
}

extension PreviewMeetingViewModel: PreviewCameraDelegate {
    func cameraNeedShowToast(_ camera: PreviewCameraManager, content: PreviewCameraManager.ToastContent) {
        self.showToast?(.camera(content))
    }

    func cameraWasInterrupted(_ camera: PreviewCameraManager) {
        _isCameraOn = false
    }

    func cameraInterruptionEnded(_ camera: PreviewCameraManager) {
        _isCameraOn = !camera.isMuted
    }

    func didFailedToStartVideoCapture(error: Error) {
        isCameraOn = false
    }
}

extension PreviewMeetingViewModel: CommonErrorHandlerListener {
    private func complianceErrorParam() -> (Int, String) {
        let joinType: Int
        var source = "none"
        switch params.idType {
        case .createMeeting, .groupId, .groupIdWithUniqueId:
            joinType = 3
        case .meetingNumber:
            joinType = 5
        case .meetingId, .meetingIdWithGroupId:
            joinType = 2
            source = "\(params.joinSource?.sourceType.rawValue ?? 0)"
        default:
            joinType = 10
        }
        return (joinType, source)
    }

    func errorPopupWillShow(_ msgInfo: MsgInfo) {
        guard let monitor = msgInfo.monitor else { return }
        let joinParams = complianceErrorParam()
        VCTracker.post(name: .vc_tns_actively_join_cross_border_view, params: [
            "join_type": joinParams.0,
            "source": joinParams.1,
            "owner_tenant_id": monitor.ownerTenantID,
            "block_type": monitor.blockType.trackParam,
            .request_id: monitor.logID
        ])
    }

    func errorPopupDidClickLeftButton(_ msgInfo: MsgInfo) {
        guard let monitor = msgInfo.monitor else { return }
        let joinParams = complianceErrorParam()
        VCTracker.post(name: .vc_tns_actively_join_cross_border_click, params: [
            "join_type": joinParams.0,
            "source": joinParams.1,
            "owner_tenant_id": monitor.ownerTenantID,
            "block_type": monitor.blockType.trackParam,
            .request_id: monitor.logID,
            .click: "main_button",
            .target: "none"
        ])
    }
}

// MARK: - other class or extension
private class PreviewJoinRoomProvider: JoinRoomTogetherViewModelProvider {
    var initialRoom: ByteviewUser? { viewModel?.joinTogetherRoomer }
    var shareCodeFilter: GetShareCodeInfoRequest.RoomBindFilter { viewModel?.roomBinderFilter() ?? .none }
    var meetingId: String { viewModel?.videoChatInfo?.id ?? "" }
    let httpClient: HttpClient
    let isInMeet: Bool = false

    private weak var viewModel: PreviewMeetingViewModel?

    init(viewModel: PreviewMeetingViewModel) {
        self.httpClient = viewModel.session.httpClient
        self.viewModel = viewModel
    }

    func prepareScan(completion: @escaping () -> Void) {
        completion()
    }

    func resetAfterScan() { }

    func connectRoom(_ room: ByteviewUser, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(Void()))
    }

    func disconnectRoom(_ room: ByteviewUser?, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(Void()))
    }

    func fetchRoomInfo(_ room: ByteviewUser, completion: @escaping (ParticipantUserInfo) -> Void) {
        httpClient.participantService.participantInfo(pid: room, meetingId: meetingId, completion: completion)
    }

    var shouldDoubleCheckDisconnection: Bool { false }
    var popoverFrom: JoinRoomPopoverFrom { .preview }
    var isSharingContent: Bool { false }
    var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}

extension PreviewViewParams {
    // 入会凭证
    var voucher: String {
        switch idType {
        case .meetingNumber:
            return ""
        case .groupIdWithUniqueId(let uniqueId):
            return uniqueId
        default:
            return id
        }
    }

    fileprivate var voucherType: VideoChatIdType {
        switch self.idType {
        case .meetingId, .meetingIdWithGroupId:
            return .meetingID
        case .groupId, .createMeeting:
            return .groupID
        case .uniqueId, .groupIdWithUniqueId:
            return .uniqueID
        case .interviewUid:
            return .interviewUid
        case .meetingNumber:
            return .meetingID
        case .reservationId:
            return .reservationID
        }
    }

    fileprivate var isInterview: Bool {
        // handoff转移会议拿不到interviewUid，因此需要显式表明是否为面试会议
        if entryParams.isInterview {
            return true
        }
        switch self.idType {
        case .interviewUid:
            return true
        default:
            return false
        }
    }

    fileprivate var calendarId: String? {
       switch idType {
       case .uniqueId:
           return id
       case .groupIdWithUniqueId(let uid):
           return uid
       default:
           return nil
       }
    }

    fileprivate var isJoinByMeetingId: Bool {
        switch idType {
        case .meetingId, .meetingIdWithGroupId:
            return true
        default:
            return false
        }
    }

    fileprivate var joinSource: JoinMeetingRequest.JoinSource? {
        var joinSource: JoinMeetingRequest.JoinSource?
        switch idType {
        case .meetingId(let chatId, let messageId):
            let sourceType = source.toJoinSource()
            joinSource = .init(sourceType: sourceType, messageID: messageId, chatID: chatId)
        case .meetingIdWithGroupId(let groupId):
            joinSource = .init(sourceType: .chat, messageID: nil, chatID: groupId)
        default:
            joinSource = nil
        }
        return joinSource
    }
}

private extension MeetingEntrySource {
    func toCalendarSource() -> JoinCalendarMeetingRequest.EntrySource {
        switch self {
        case .calendarDetails, .calendarPrompt, "upcoming_join_room":
            return .fromCalendarDetail
        case "chat_window_banner", "meeting_space_banner":
            return .fromGroup
        case "card":
            return .fromCard
        default:
            return .fromUnknown
        }
    }

    func toJoinSource() -> JoinMeetingRequest.JoinSourceType {
        switch self {
        case "meeting_tab", "im_notice", "event_card", "handoff":
            return .tab
        case .calendarPrompt:
            return .calendarNotice
        default:
            return .card
        }
    }
}
