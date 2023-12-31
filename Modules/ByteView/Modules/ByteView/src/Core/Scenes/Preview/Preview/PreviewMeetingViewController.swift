//
//  PreviewMeetingViewController.swift
//  ByteView
//
//  Created by ford on 2019/5/20.
//

import UIKit
import Action
import AVFoundation
import AVKit
import VolcEngineRTC
import LarkMedia
import LarkKeyCommandKit
import UniverseDesignIcon
import UniverseDesignTheme
import UniverseDesignToast
import ByteViewUI
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import ByteViewTracker
import ByteViewMeeting

class PreviewMeetingViewController: VMViewController<PreviewMeetingViewModel>, AVRoutePickerViewDelegate, UINavigationControllerDelegate {
    let labIconSize: CGFloat = 22

    var textViewWidth: CGFloat = 0
    weak var guideView: GuideView?

    private var isShowKeyboard: Bool = false

    lazy var participantsPopover = ParticipantsPopover(service: self.viewModel.service)

    lazy var tapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(didTapOverlay(_:)))
    }()

    lazy var panGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(didTapOverlay(_:)))
    }()


    lazy var previewView: PreviewMeetingView = {
        let view = PreviewMeetingView(model: viewModel.previewViewModel)
        view.deviceView.micView.bindMeetingSetting(viewModel.setting)
        view.footerView.replaceJoinView.delegate = self
        return view
    }()

    var closeBtn: UIButton { previewView.closeBtn }
    var connectRoomBtn: PreviewConnectRoomButton { previewView.connectRoomBtn }

    var meetingNumberHeaderView: PreviewMeetingNumberHeaderView { previewView.meetingNumberHeaderView }
    var topicHeaderView: PreviewTopicHeaderView { previewView.topicHeaderView }
    var meetingNumberField: MeetingNumberField { previewView.meetingNumberHeaderView.textField }
    var errorLabel: UILabel { previewView.meetingNumberHeaderView.errorLabel }

    var contentView: PreviewContentView { previewView.contentView }
    var labButton: UIButton { contentView.labButton }
    var avatarImageView: AvatarView { contentView.avatarImageView }
    var assistLabel: PaddingLabel { contentView.assistLabel }

    var footerView: PreviewFooterView { previewView.footerView }
    var deviceView: PreviewDeviceView { previewView.deviceView }
    var micView: PreviewMicrophoneView { deviceView.micView }
    var cameraView: PreviewCameraView { deviceView.cameraView }
    var speakerView: PreviewSpeakerView { deviceView.speakerView }
    var commitBtn: UIButton { footerView.commitBtn }

    static var lastPreviewViewControllerId: String = ""

    deinit {
        if Self.lastPreviewViewControllerId == self.logDescription {
            self.viewModel.handleDeinit()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Keyboard.reset()
    }

    override func setupViews() {
        Self.lastPreviewViewControllerId = self.logDescription
        isNavigationBarHidden = true
        view.backgroundColor = .clear
        view.addSubview(previewView)
        previewView.addGestureRecognizer(tapGesture)
        previewView.addGestureRecognizer(panGesture)

        accessibilityLabel = "PreviewMeetingViewController.accessibilityLabel"
        previewView.connectRoomBtn.isHidden = !viewModel.isJoinRoomEnabled
        setupLayout()
    }

    override func bindViewModel() {
        bindNotification()
        bindTarget()
        bindClosure()

        viewModel.delegate = self
        topicHeaderView.delegate = self
        if let audioOutput = viewModel.session.audioDevice?.output {
            deviceView.speakerView.bindAudioOutput(audioOutput)
        }
        initialData()
    }

    private func initialData() {
        commitBtn.isEnabled = viewModel.isCommitEnabled
        requestCameraAccess()
        updateDefaultTopic()
        updateMicState()
        updateCameraState()
        handleAvatar()
        if viewModel.isWebinarAttendee {
            handleWebinarAttendee()
        }
        if viewModel.isJoinByNumber {
            meetingNumberField.underlineColor = isShowKeyboard ? UIColor.ud.primaryContentDefault : UIColor.ud.lineBorderComponent
            lastJoinRoomMeetingNumber = viewModel.meetingNumber
            meetingNumberField.setText(viewModel.meetingNumber)
        } else {
            topicHeaderView.participants = viewModel.participants
            topicHeaderView.textField.placeholder = viewModel.placeholderText
        }
        didChangeLabButtonHidden(viewModel.isHiddenLabButton)
        didChangeExtraBgDownloadStatus(status: viewModel.bgDownloadStatus)
        didChangeJoinedDeviceInfos()
    }

    override func viewWillFirstAppear(_ animated: Bool) {
        if let navi = self.navigationController as? NavigationController {
            navi.view.backgroundColor = UIColor.clear
            navi.interactivePopDisabled = true
        }
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        PreviewReciableTracker.endEnterPreview()
        PreviewReciableTracker.endEnterPreviewForPure()
        viewModel.session.slaTracker.endEnterPreview(success: true)
        trackPreview()
        #if DEBUG
        Util.observeDeinit(Util.findRootVc(self))
        #endif

        // 放在viewDidFirstAppear的原因是，唤起键盘在viewWillAppear时机过早，弹出键盘样式可能为横屏
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let hasPermissions = Privacy.audioAuthorized && Privacy.videoAuthorized
            if self.viewModel.isJoinByNumber && hasPermissions {
                if self.meetingNumberField.text?.count ?? 0 < 9 {
                    self.logger.info("PreviewMeetingViewController meetingNumberField become first responder")
                    self.meetingNumberField.becomeFirstResponder()
                }
            }
        }

        if self.viewModel.canAutoScanJoinRoom() {
            self.autoscanJoinRoom()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewView.updateToastOffset(in: view)
        if viewModel.isCameraOn {
            viewModel.camera.setMuted(false)
        }
        MeetingTracksV2.trackShowPreviewVC(isInWaitingRoom: false, isCamOn: viewModel.isCameraOn, isMicOn: viewModel.isMicOn)
    }

    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
        super.viewWillDisappear(animated)
        previewView.resetToastContext()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if Display.pad {
            let newCollection = newContext.layoutType.isRegular
            if oldContext.layoutType != newContext.layoutType {
                resetParticipantsTile()
            }
            updateLayout(isRegular: newCollection)
        }
    }

    override func viewLayoutContextDidChanged() {
        self.previewView.updateToastOffset(in: self.view)
    }

    // MARK: - Layout
    func setupLayout() {
        previewView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        updateLayout(isRegular: currentLayoutContext.layoutType.isRegular)
    }

    func updateLayout(isRegular: Bool) {
        logger.info("updateLayout: isRegular = \(isRegular)")
        deviceView.isLongMic = viewModel.previewAudios.count > 1
        previewView.updateLayout(isRegular)
    }


    // MARK: - bind
    private func bindNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_: )),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_: )),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(_:)),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func requestCameraAccess() {
        Privacy.requestCameraAccess { [weak self] status in
            switch status {
            case .denied, .deniedOfAsk:
                self?.viewModel.isCameraOn = false
            default:
                break
            }
        }
    }

    @RwAtomic private var lastJoinRoomMeetingNumber = ""

    func bindTarget() {
        closeBtn.addTarget(self, action: #selector(closePreview), for: .touchUpInside)
        connectRoomBtn.addTarget(self, action: #selector(didClickConnectRoom), for: .touchUpInside)
        labButton.addTarget(self, action: #selector(labAction), for: .touchUpInside)
        commitBtn.addTarget(self, action: #selector(commitAction), for: .touchUpInside)
    }

    private func bindClosure() {
        bindClickHandler()
        bindHeaderView()
        viewModel.showToast = { [weak self] toastType in
            self?.showToast(toastType: toastType)
        }

        footerView.updateLayoutClosure = { [weak self] in
            guard let self = self else { return }
            self.previewView.bottomDeviceMinHeight = self.footerView.deviceMinHeight
        }
    }

    func bindHeaderView() {
        let trackClosure = { VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "insert_title", .target: "none"]) }
        if viewModel.isJoinByNumber {
            meetingNumberHeaderView.textField.returnkeyAction = { [weak self] text in
                self?.returnKeyAction(text: text)
            }
            meetingNumberField.editingDidChange = { [weak self] text in
                guard let self = self else { return }
                let text = text ?? ""
                if self.lastJoinRoomMeetingNumber != text, let current = self.viewModel.joinTogetherRoomer, self.viewModel.joinRoom.connectionState == .automatic {
                    self.logger.info("autoscanJoinRoom finished: disconnect room \(current)")
                    self.viewModel.joinRoom.disconnectRoom()
                    self.onDisconnectRoom()
                }
                if PreviewMeetingViewModel.isMeetingNumberValid(text) {
                    self.viewModel.meetingNumber = text
                    if self.viewModel.canAutoScanJoinRoom() {
                        self.lastJoinRoomMeetingNumber = text
                        self.autoscanJoinRoom()
                    }
                } else {
                    self.viewModel.meetingNumber = ""
                }
                self.meetingNumberField.placeHolderLabel.isHidden = !text.isEmpty
            }
            meetingNumberField.trackClosure = trackClosure
        } else {
            topicHeaderView.textView.textDidChangedClosure = { [weak self] textField in
                self?.updateTopicHeaderViewWidth(with: textField.intrinsicContentSize.width)
            }
            topicHeaderView.textField.trackClosure = trackClosure
        }
    }

    func bindClickHandler() {
        cameraView.clickHandler = { [weak self] _ in
            self?.didClickCameraView()
        }

        micView.clickHandler = { [weak self] _ in
            guard let self = self else { return }
            switch self.viewModel.selectedAudioType {
            case .noConnect:
                self.didClickSwitchAudio()
            default:
                self.didClickMicView()
            }
        }

        speakerView.clickHandler = { [weak self] view in
            guard let self = self else { return }
            self.didClickSpeakerView(view)
        }

        micView.switchAudioClick = { [weak self] in
            self?.didClickSwitchAudio()
        }
    }

    @RwAtomic private var autoscanJoinRoomToken = ""
    private func autoscanJoinRoom() {
        let token = UUID().uuidString
        self.autoscanJoinRoomToken = token
        self.viewModel.autoscanJoinRoom { [weak self] in
            Util.runInMainThread {
                guard let self = self, self.autoscanJoinRoomToken == token, !self.hasJoinRoomViewController else { return }
                self.autoscanJoinRoomToken = ""
                let joinRoom = self.viewModel.joinRoom
                if joinRoom.canAutoConnect, let room = joinRoom.room {
                    self.logger.info("autoscanJoinRoom finished: autoConnect room \(room)")
                    joinRoom.connectRoom(isFromAutoScan: true)
                    self.onConnectRoom(room: room)
                    self.showJoinRoomTogether()
                } else if joinRoom.isSuggestedRoom {
                    self.logger.info("autoscanJoinRoom finished: showJoinRoomTogether")
                    self.onDisconnectRoom(showToast: false)
                    self.showJoinRoomTogether(isAutoScan: true)
                }
            }
        }
    }

    private func returnKeyAction(text: String?) {
        if let topicText = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !topicText.isEmpty {
            self.commitAction(nil)
        }
    }

    func updateTopicHeaderViewWidth(with textFieldWidth: CGFloat) {
        let textViewWidth = max(textFieldWidth + 32, self.viewModel.placeholderWidth())
        self.textViewWidth = self.textViewWidth < textViewWidth ? textViewWidth : self.textViewWidth
        self.topicHeaderView.textView.snp.updateConstraints { (maker) in
            maker.width.greaterThanOrEqualTo(self.textViewWidth)
        }
    }

    func showToast(toastType: ToastType) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            let v = self.previewView
            switch toastType {
            case .mic(let content):
                guard !self.viewModel.setting.isMicSpeakerDisabled else { return }
                Toast.showOnVCScene(content, in: v)
            case .audio:
                self.viewModel.session.audioDevice?.output.showToast(in: v)
            case .camera(let content):
                Toast.showOnVCScene(content.localizedDescription, in: v)
            case .allowLab(let content):
                Toast.showOnVCScene(content, in: v)
            case .resident(let content, let duration):
                Toast.showOnVCScene(content, in: v, duration: duration)
            }
        }
    }

    func showOnboardingIfNeeded() {
        guard self.viewModel.service.shouldShowGuide(.labEffectGuidekEY) else {
            return
        }
        let guideView = self.guideView ?? GuideView(frame: view.bounds)
        self.guideView = guideView
        if guideView.superview == nil {
            previewView.addSubview(guideView)
            guideView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        guideView.layer.ud.setShadowColor(UIColor.ud.primaryFillHover.withAlphaComponent(0.3))
        guideView.layer.shadowOffset = CGSize(width: 0.0, height: 12.0)
        guideView.layer.shadowRadius = 24.0
        guideView.layer.shadowOpacity = 1.0

        guideView.setStyle(.plain(content: !viewModel.service.setting.packageIsLark ? I18n.View_G_EffectsOnboardingMobile : I18n.View_G_EffectsOnboardingMobileLark),
                           on: .left,
                           of: self.labButton,
                           forcesSingleLine: false,
                           distance: 4)
        guideView.sureAction = { [weak self] _ in
            self?.viewModel.service.didShowGuide(.labEffectGuidekEY)
            self?.guideView?.removeFromSuperview()
            self?.guideView = nil
        }
    }

    func handleAvatar() {
        let size: CGFloat = 300
        guard let avatarInfo = viewModel.avatarInfo else { return }
        if Privacy.videoDenied {
            avatarImageView.setAvatarInfo(.asset(UDIcon.getIconByKey(.videoOffOutlined, iconColor: UIColor.ud.N400, size: CGSize(width: size, height: size))))
            avatarImageView.updateStyle(.square)
            contentView.updateAvatarImageSize(isDenied: true)
        } else {
            avatarImageView.setAvatarInfo(avatarInfo, size: .large)
            avatarImageView.updateStyle(.circle)
            contentView.updateAvatarImageSize(isDenied: false)
        }
    }

    func handleWebinarAttendee() {
        guard viewModel.isWebinarAttendee else { return }
        commitBtn.setTitle(I18n.View_G_JoinMeeting, for: .normal)
        deviceView.style = .webinarAttendee
    }

    func showLoading(_ isLoading: Bool, isFailed: Bool = false) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.footerView.showLoading(isLoading, isFailed: isFailed)
        }
    }

    private func disconnectRoom() {
        VCTracker.post(name: .vc_ultrasonic_popover_click, params: [.click: "disconnect", "is_popup_from": "preview"])
        guard let room = self.viewModel.joinTogetherRoomer else {
            Logger.ui.warn("didClickDisconnect ignored, room is nil")
            return
        }
        Logger.ui.info("didClickDisconnect")
        viewModel.joinRoom.disconnectRoom()
        didDisconnectRoom(nil, room: room)
    }

    private func trackPreview() {
        var params: TrackParams = [.action_name: "display", .env_id: viewModel.session.sessionId]
        let joinParams = viewModel.params
        let voucher = joinParams.voucher
        switch joinParams.idType {
        case .meetingId, .meetingIdWithGroupId:
            params[.conference_id] = voucher
        case .groupId, .createMeeting:
            params["group_id"] = EncryptoIdKit.encryptoId(voucher)
        case .uniqueId, .groupIdWithUniqueId:
            params["unique_id"] = voucher
        case .meetingNumber:
            params["meeting_num"] = EncryptoIdKit.encryptoId(joinParams.id)
        case .interviewUid:
            params["interview_unique_id"] = voucher
        default:
            break
        }
        VCTracker.post(name: .vc_meeting_page_preview, params: params)
    }


    private func updateMicState() {
        let isMicOn = viewModel.isMicOn
        micView.isAuthorized = Privacy.audioAuthorized
        micView.isOn = isMicOn
        if isMicOn {
            self.viewModel.session.audioDevice?.output.setMuted(false)
        }
    }

    private func updateCameraState() {
        let isOn = viewModel.isCameraOn
        cameraView.isAuthorized = Privacy.videoAuthorized
        cameraView.isOn = isOn
        contentView.updateCameraOn(isOn)
    }

    private func updateDefaultTopic() {
        if viewModel.shouldShowUnderline {
            topicHeaderView.textField.text = viewModel.isJoiningMeeting || viewModel.isJoinByCalendar ? viewModel.defaultTopic : nil
        } else {
            topicHeaderView.topicView.updateTitle(viewModel.defaultTopic, isWebinar: viewModel.isWebinar)
            topicHeaderView.setNeedsLayout()
        }
    }


    // MARK: - click
    func didClickMicView() {
        muteOrUnmuteMic(track: true)
    }

    func muteOrUnmuteMic(track: Bool) {
        if track {
            VCTracker.post(name: .vc_meeting_pre_click,
                           params: [.click: "mic",
                                    .is_starting_auth: false,
                                    .option: self.viewModel.isMicOn ? "close" : "open"])
        }
        if viewModel.isMuteOnEntry {
            Toast.show(I18n.View_M_MutedOnEntryPreview)
            return
        }
        self.viewModel.muteMic()
    }

    func didClickCameraView() {
        muteOrUnmuteCamera(track: true)
    }

    func muteOrUnmuteCamera(track: Bool) {
        if track {
            VCTracker.post(name: .vc_meeting_pre_click,
                           params: [.click: "camera",
                                    .is_starting_auth: false,
                                    .option: self.viewModel.isCameraOn ? "close" : "open"])
        }
        self.viewModel.muteCamera()
    }

    func didClickSpeakerView(_ view: UIView, directions: UIPopoverArrowDirection? = .down) {
        if self.viewModel.joinTogetherRoomer != nil {
            VCTracker.post(name: .vc_toast_status, params: ["toast_name": "ultrasonic_sync_join_success", "connect_type": "preview"])
            Toast.show(I18n.View_G_WowPairedRoomAudio, in: self.previewView)
            return
        }
        self.viewModel.shouldShowAudioToast = true
        VCTracker.post(name: .vc_meeting_page_preview, params: [.action_name: LarkAudioSession.shared.currentOutput.trackText])

        let config = AudioOutputActionSheet.Config(offset: directions == .down ? -3 : 3, cellWidth: 280, cellMaxWidth: 360, directions: directions, margins: .init(top: 0, left: 0, bottom: 0, right: 12))
        self.viewModel.session.audioDevice?.output.showPicker(scene: .preview, from: self, anchorView: view, config: config)

        DispatchQueue.global().async {
            /// 新埋点
            let target = LarkAudioSession.shared.isHeadsetConnected ? nil : TrackEventName.vc_meeting_loudspeaker_view
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "speaker", .is_starting_auth: false, .target: target])
        }
    }

    @objc
    func didClickConnectRoom() {
        if !self.viewModel.setting.isUltrawaveEnabled {
            Toast.show(I18n.View_UltraOnToUseThis_Note, in: self.previewView)
            return
        }
        let hasRoom = self.viewModel.joinTogetherRoomer != nil
        VCTracker.post(name: .vc_meeting_pre_click,
                       params: [.click: "ultrasonic_room_button",
                                "ultrasonic_room_button_status": hasRoom ? "connect" : "normal"])
        self.logger.info("showJoinRoomTogether from didClickConnectRoom")
        self.showJoinRoomTogether()
    }

    private var hasJoinRoomViewController = false

    private func updateJoinTogetherRoom(_ roomer: ByteviewUser?) {
        viewModel.joinTogetherRoomer = roomer
        let hasRoom = roomer != nil && !viewModel.isWebinarAttendee
        connectRoomBtn.updateConnectState(hasRoom, roomName: viewModel.joinRoom.roomNameAbbr)
        viewModel.session.audioDevice?.output.setNoConnect(hasRoom)
        if hasRoom {
            viewModel.selectedAudioType = .room
        }
        didSelectedAudio(at: viewModel.selectedAudioType)
        refreshView(roomConnected: hasRoom)
    }

    private func refreshView(roomConnected: Bool) {
        micView.isHidden = roomConnected
        speakerView.isHidden = roomConnected
        assistLabel.isHidden = !roomConnected
    }

    private func showJoinRoomTogether(isAutoScan: Bool = false) {
        hasJoinRoomViewController = true
        self.viewModel.joinRoom.fromAutoScan = isAutoScan
        let vc = JoinRoomTogetherViewController(viewModel: self.viewModel.joinRoom)
        vc.delegate = self
        let popoverConfig = DynamicModalPopoverConfig(sourceView: self.connectRoomBtn,
                                                      sourceRect: self.connectRoomBtn.bounds.offsetBy(dx: 0, dy: 4),
                                                      backgroundColor: .ud.bgFloat,
                                                      popoverLayoutMargins: UIEdgeInsets(top: 0, left: 10, bottom: -4, right: 10),
                                                      permittedArrowDirections: .up)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                               popoverConfig: popoverConfig,
                                               backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        viewModel.router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: compactConfig)
    }

    func didClickSwitchAudio(audioList: [PreviewAudioType] = []) {
        let list = audioList.isEmpty ? viewModel.previewAudios : audioList
        let isRoomConnected = viewModel.selectedAudioType == .room
        let audioType = isRoomConnected ? nil : viewModel.selectedAudioType.audioMode
        let vc = AudioSelectViewController(scene: .preview(viewModel.setting.callmePhoneNumber), audioType: audioType, audioList: list.map({ $0.audioMode}), isRoomConnected: isRoomConnected)
        vc.delegate = self
        let sourceView = micView.switchAudioButton.isHidden ? micView : micView.switchAudioButton
        let size: CGSize = .init(width: 360, height: vc.contentHeight)
        let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                      sourceRect: sourceView.bounds.offsetBy(dx: 0, dy: -3),
                                                      backgroundColor: .clear,
                                                      popoverSize: size,
                                                      popoverLayoutMargins: .zero,
                                                      permittedArrowDirections: .down)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                               popoverConfig: popoverConfig,
                                               backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        viewModel.router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: compactConfig)
    }

    private func updateLabButton(_ isVirtualBgEnabled: Bool) {
        let image = UDIcon.getIconByKey(isVirtualBgEnabled ? .virtualBgOutlined : .effectsOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: labIconSize, height: self.labIconSize))
        labButton.setImage(image, for: .normal)
        labButton.setImage(image, for: .highlighted)

        if labButton.titleLabel?.text != nil {
            let text = isVirtualBgEnabled ? I18n.View_VM_VirtualBackground : I18n.View_G_Effects
            labButton.setTitle(text, for: .normal)
        }
    }


    // MARK: - @objc
    @objc func didTapOverlay(_ sender: Any) {
        view.endEditing(true)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        logger.info("PreviewMeetingViewController keyboard will show")
        isShowKeyboard = true
        meetingNumberField.underlineColor = errorLabel.isHidden ? UIColor.ud.primaryContentDefault : UIColor.ud.functionDangerContentDefault
        topicHeaderView.textField.underlineColor = UIColor.ud.primaryContentDefault
        previewView.footerView.isBlurHidden = false
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        logger.info("PreviewMeetingViewController keyboard will hide")
        isShowKeyboard = false
        meetingNumberField.underlineColor = UIColor.ud.lineBorderComponent
        topicHeaderView.textField.underlineColor = viewModel.shouldShowUnderline ? UIColor.ud.lineBorderComponent : UIColor.clear
        previewView.footerView.isBlurHidden = true
    }

    @objc private func willEnterForeground(_ notification: Notification) {
        handleAvatar()
    }

    @objc private func didEnterBackground(_ notification: Notification) {
        if viewModel.isJoinByNumber {
            meetingNumberField.resignFirstResponder()
        } else {
            topicHeaderView.textField.resignFirstResponder()
        }
    }

    @objc
    func closePreview() {
        if #available(iOS 13, *) {
            self.dismiss(animated: true) { [weak self] in
                self?.viewModel.closePreview()
            }
        } else {
            viewModel.closePreview()
        }
        VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "close", .target: "none", .is_starting_auth: false])
    }

    @objc
    func labAction() {
        guard let effect = viewModel.session.effectManger else { return }

        VCTracker.post(name: .vc_meeting_page_preview, params: [.action_name: "effect"])
        VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "labs_setting", .target: "vc_meeting_setting_view", .is_starting_auth: false])

        let isInterview: Bool = viewModel.interviewRole == .interviewer
        let viewModel = InMeetingLabViewModel(service: self.viewModel.service, effectManger: effect, fromSource: .preview, isInterviewer: isInterview)
        Logger.lab.info("lab bg: labViewModel from preview isInterview: \(isInterview)")

        let viewController = InMeetingLabViewController(viewModel: viewModel)
        self.navigationController?.delegate = self
        if Display.pad {
            viewModel.router.presentDynamicModal(viewController,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        } else {
            viewModel.router.push(viewController, animated: true)
        }
    }

    @objc
    func commitAction(_ sender: UIButton?) {
        Logger.callme.info("preview commit type \(viewModel.audioType)")
        doCommit()
    }

    func doCommit() {
        if viewModel.audioType == .pstn {
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "call_me"])
        } else if viewModel.audioType == .noConnect, viewModel.joinTogetherRoomer == nil {
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "unconnected_audio"])
        } else {
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "other_ways"])
        }
        OnthecallReciableTracker.startEnterOnthecall()
        viewModel.session.slaTracker.startEnterOnthecall()
        self.showLoading(true)
        // 停止检测超声波
        self.viewModel.stopUltrawaveAndPrepareForMeeting()

        let topic: String

        if viewModel.shouldShowUnderline, let text = topicHeaderView.textView.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !text.isEmpty {
            topic = text
        } else if !viewModel.shouldShowUnderline, let text = topicHeaderView.topicView.title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !text.isEmpty {
            topic = text
        } else {
            topic = viewModel.defaultTopic
        }
        let replaceJoin = viewModel.replaceJoinEnabled ? !previewView.footerView.replaceJoinView.isSelected : nil

        viewModel.livePrecheck { [weak self] r in
            switch r {
            case .success(let granted):
                if granted {
                    self?.viewModel.joinMeeting(topic: topic, replaceJoin: replaceJoin) { [weak self] result in
                        switch result {
                        case .success:
                            self?.showLoading(false)
                            self?.updateReplaceJoinSetting()
                        case .failure(let error):
                            self?.showLoading(false, isFailed: true)
                            OnthecallReciableTracker.cancelStartOnthecall()
                                self?.viewModel.session.slaTracker.endEnterOnthecall(success: self?.viewModel.session.slaTracker.isSuccess(error: error.toVCError()) ?? false)
                            if error.toVCError() == .replaceJoinUnsupported && replaceJoin == true {
                                self?.handleReplaceUnsupportedError()
                            }
                        }
                    }
                } else {
                    self?.showLoading(false)
                    OnthecallReciableTracker.cancelStartOnthecall()
                    self?.viewModel.session.slaTracker.endEnterOnthecall(success: false)
                }
            case .failure(let error):
                self?.showLoading(false, isFailed: true)
                OnthecallReciableTracker.cancelStartOnthecall()
                    self?.viewModel.session.slaTracker.endEnterOnthecall(success: self?.viewModel.session.slaTracker.isSuccess(error: error.toVCError()) ?? false)
            }
        }
        viewModel.trackPreviewCommit()
    }

    // MARK: - KeyCommand
    override func keyBindings() -> [KeyBindingWraper] {
        let muteMicOrCamKeyBindings = [
            KeyCommandBaseInfo(
                input: "D",
                modifierFlags: [.command, .shift],
                discoverabilityTitle: I18n.View_G_MuteOrUnmuteCut_Text
            ).binding(
                target: self,
                selector: #selector(switchAudioMuteStatus)
            ).wraper,
            KeyCommandBaseInfo(
                input: "V",
                modifierFlags: [.command, .shift],
                discoverabilityTitle: I18n.View_G_StartOrStopCamCut_Text
            ).binding(
                target: self,
                selector: #selector(switchVideoMuteStatus)
            ).wraper
        ]
        return super.keyBindings() + muteMicOrCamKeyBindings
    }

    @objc private func switchAudioMuteStatus() {
        guard Display.pad, !viewModel.isWebinarAttendee else { return }
        let isMicOn = viewModel.isMicOn
        Logger.ui.info("switch audio mute status to by keyboard shortcut, new isMicMuted = \(isMicOn), location: .preview")
        viewModel.muteMic()
        KeyboardTrack.trackClickShortcut(with: .muteMicrophone, to: !isMicOn, from: .preview)
    }

    @objc private func switchVideoMuteStatus() {
        guard Display.pad, !viewModel.isWebinarAttendee else { return }
        let isCamOn = viewModel.isCameraOn
        Logger.ui.info("switch video mute status to by keyboard shortcut, new isCamMuted = \(isCamOn), location: .preview")
        viewModel.muteCamera()
        KeyboardTrack.trackClickShortcut(with: .muteCamera, to: !isCamOn, from: .preview)
    }
}

extension PreviewMeetingViewController: PreviewTopicHeaderViewDelegate {
    // 重置参会人列表视图: 由于regular采用present、compact采用push方式弹出，因此在两者间切换时需要先dismiss再展示新视图
    func resetParticipantsTile() {
        if participantsPopover.resetParticipantsPopover() {
            showPreviewParticipants(animated: false)
        }
    }

    func didTapParticipantsInHeaderView(_ view: PreviewTopicHeaderView) {
        showPreviewParticipants(animated: true)
    }

    private func showPreviewParticipants(animated: Bool = true, offset: CGFloat = 10) {
        let participants = topicHeaderView.participants
        participantsPopover.showParticipantsList(participants: participants,
                                                 isInterview: viewModel.videoChatInfo?.meetingSource == .vcFromInterview,
                                                 isWebinar: viewModel.params.isWebinar,
                                                 sourceView: topicHeaderView.participantsView,
                                                 offset: offset, from: self, animated: animated)
    }

    func didRefreshLayout() {
        self.previewView.bottomDeviceMinHeight = self.footerView.deviceMinHeight
    }
}

extension PreviewMeetingViewController: JoinRoomTogetherViewControllerDelegate {
    func didConnectRoom(_ controller: UIViewController, room: ByteviewUser) {
        self.onConnectRoom(room: room)
    }

    func didDisconnectRoom(_ controller: UIViewController?, room: ByteviewUser) {
        self.onDisconnectRoom()
    }

    private func onConnectRoom(room: ByteviewUser) {
        if viewModel.joinTogetherRoomer != room {
            updateJoinTogetherRoom(room)
        }
    }

    private func onDisconnectRoom(showToast: Bool = true) {
        if !viewModel.isSwitchAudioFromRoom {
            viewModel.selectedAudioType = .system
        }
        if viewModel.joinTogetherRoomer != nil {
            updateJoinTogetherRoom(nil)
        }
        if showToast {
            Util.runInMainThread {
                Toast.show(I18n.View_G_UsingSystemAudio_Toast, in: self.previewView)
            }
        }
        viewModel.session.audioDevice?.output.setPadMicSpeakerDisabled(viewModel.setting.isMicSpeakerDisabled)
    }

    func joinRoomViewControllerDidAppear(_ controller: JoinRoomTogetherViewController) {
        hasJoinRoomViewController = true
        previewView.connectRoomBtn.isSelected = controller.style == .popover && !self.viewModel.joinRoom.fromAutoScan
    }

    func joinRoomViewControllerDidChangeStyle(_ controller: JoinRoomTogetherViewController, style: JoinRoomViewStyle) {
        previewView.connectRoomBtn.isSelected = controller.style == .popover && !self.viewModel.joinRoom.fromAutoScan
    }

    func joinRoomViewControllerWillDisappear(_ controller: JoinRoomTogetherViewController) {
        hasJoinRoomViewController = false
        previewView.connectRoomBtn.isSelected = false
    }
}


extension PreviewMeetingViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        updateLayout(isRegular: isRegular)
    }
}

extension PreviewMeetingViewController: PreviewMeetingViewModelDelegate {
    func speakerViewWillAppear() {
        speakerView.isHighlighted = VCScene.isRegular
    }

    func speakerViewWillDisappear() {
        speakerView.isHighlighted = false
    }

    func didChangePreviewParticipants(_ participants: [PreviewParticipant]) {
        guard !viewModel.isJoinByNumber else { return }
        Util.runInMainThread {
            self.topicHeaderView.participants = participants
        }
    }

    func didChangeAvatarInfo(_ avatarInfo: AvatarInfo) {
        handleAvatar()
    }

    func didChangeTopic(_ topic: String) {
        Util.runInMainThread {
            self.updateDefaultTopic()
        }
    }

    func didChangeCommitEnabled(_ isEnabled: Bool) {
        Util.runInMainThread {
            self.commitBtn.isEnabled = isEnabled
        }
    }

    func didChangeShowErrorText(_ isShow: Bool) {
        guard viewModel.isJoinByNumber else { return }
        errorLabel.isHidden = !isShow
        meetingNumberField.underlineColor = isShow ? UIColor.ud.functionDangerContentDefault : isShowKeyboard ? UIColor.ud.primaryContentDefault : UIColor.ud.lineBorderComponent
    }

    func didChangeMicStatus(_ isOn: Bool) {
        Util.runInMainThread {
            self.updateMicState()
        }
    }

    func didChangeCameraStatus(_ isOn: Bool) {
        Util.runInMainThread {
            self.updateCameraState()
            self.handleAvatar()
        }
    }

    func didChangeLabButtonHidden(_ isHidden: Bool) {
        Logger.preview.info("bindLabButton \(self.viewModel.setting.isVirtualBgEnabled), \(isHidden)")
        labButton.isHidden = isHidden
        let isVirtualBgEnabled = self.viewModel.setting.isVirtualBgEnabled
        updateLabButton(isVirtualBgEnabled)
        if !isHidden {
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showOnboardingIfNeeded()
            }
        }
    }

    func didChangeVirtualBgEnabled(_ isOn: Bool) {
        Util.runInMainThread {
            self.updateLabButton(isOn)
        }
    }

    func didChangeExtraBgDownloadStatus(status: ExtraBgDownLoadStatus) {
        guard viewModel.virtualBgService?.calendarMeetingVirtual?.hasExtraBg == true, viewModel.virtualBgService?.calendarMeetingVirtual?.hasShowedExtraBgToast == false else {
            return
        }
        Logger.ui.info("ExtraBgDownloadStatus \(status)")
        if status == .done, !self.labButton.isHidden {
            let anchorToastView = AnchorToastView()
            self.previewView.addSubview(anchorToastView)
            anchorToastView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            anchorToastView.setStyle(I18n.View_G_UniSetYouCanChange, on: .bottom, of: self.labButton, distance: 4, defaultEnoughInset: 8)
            self.viewModel.virtualBgService?.calendarMeetingVirtual?.hasShowedExtraBgToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                anchorToastView.removeFromSuperview()
            }
        }
    }

    func didChangeJoinedDeviceInfos() {
        Util.runInMainThread {
            let replaceJoinView = self.previewView.footerView.replaceJoinView
            if self.viewModel.replaceJoinEnabled {
                let replaceJoin = self.viewModel.setting.replaceJoinedDevice
                replaceJoinView.isSelected = !replaceJoin
                replaceJoinView.isHidden = false
                replaceJoinView.updateDeviceNames(self.viewModel.joinedDeviceInfos?.map { $0.defaultDeviceName } ?? [])
                if replaceJoin {
                    // 同步麦摄状态
                    self.syncJoinedDeviceSetting(willReplace: true)
                }
            } else {
                replaceJoinView.isHidden = true
            }
            self.previewView.updateLayout(VCScene.isRegular)
        }
    }
}

extension PreviewMeetingViewController: AudioSelectViewControllerDelegate {
    func didSelectedAudio(at type: PreviewAudioType) {
        if type != .room, self.viewModel.joinTogetherRoomer != nil {
            viewModel.selectedAudioType = type
            viewModel.isSwitchAudioFromRoom = true
            self.disconnectRoom()
            return
        }
        viewModel.isSwitchAudioFromRoom = false
        viewModel.selectedAudioType = type
        viewModel.audioType = type.audioMode
        micView.audioType = type
        deviceView.style = type.toDeviceStyle
        var callMeTipText: String = ""
        if type == .pstn {
            let phoneNumber = viewModel.service.setting.callmePhoneNumber
            callMeTipText = I18n.View_G_CallNumberOnceJoin(phoneNumber)
        }
        footerView.updateCallMeTip(callMeTipText)
    }

    func viewWillAppear() {
        viewDidAppear()
    }

    func viewWillDisppear() {
        viewDidDisappear()
    }

    func viewDidAppear() {
        micView.isArrowDown = VCScene.isRegular
        micView.isHighlighted = VCScene.isRegular
    }

    func viewDidDisappear() {
        micView.isArrowDown = false
        micView.isHighlighted = false
    }
}

extension PreviewMeetingViewController: PreviewReplaceJoinViewDelegate {
    func replaceJoinCheckboxTapped(_ isSelected: Bool) {
        syncJoinedDeviceSetting(willReplace: !isSelected)
        VCTracker.post(name: .vc_meeting_pre_click,
                       params: [.click: "leave_conference_device", "is_check": isSelected])
    }

    private func syncJoinedDeviceSetting(willReplace: Bool) {
        if !willReplace {
            // 关闭替代入会，需关闭麦摄以避免啸叫
            if viewModel.isMicOn {
                muteOrUnmuteMic(track: false)
            }
            if viewModel.isCameraOn {
                muteOrUnmuteCamera(track: false)
            }
            // output静音
            if let audioOutput = viewModel.session.audioDevice?.output, !audioOutput.isDisabled, !audioOutput.isMuted {
                audioOutput.setMuted(true)
            }
        } else if !viewModel.isWebinarAttendee, let setting = viewModel.joinedDeviceSetting {
            // 开启替代入会，需同步会中设备的麦摄状态
            if viewModel.isMicOn != !setting.isMicrophoneMuted {
                muteOrUnmuteMic(track: false)
            }
            if viewModel.isCameraOn != !setting.isCameraMuted {
                muteOrUnmuteCamera(track: false)
            }
        }
    }

    private func updateReplaceJoinSetting() {
        Util.runInMainThread {
            guard self.viewModel.replaceJoinEnabled else { return }
            let replaceJoin = !self.previewView.footerView.replaceJoinView.isSelected
            self.viewModel.setting.replaceJoinedDevice = replaceJoin
        }
    }

    // 不支持替代入会时（joinMeeting接口报指定错误），需要弹窗引导用户直接入会
    private func handleReplaceUnsupportedError() {
        ByteViewDialog.Builder()
            .id(.replaceJoinUnsupported)
            .title(I18n.View_G_NoCantSwitch_Desc)
            .message(I18n.View_G_CanJoinMeet_Desc)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ [weak self] _ in
                self?.showLoading(false)
                self?.commitBtn.isEnabled = true
            })
            .rightTitle(I18n.View_G_JoinMeeting)
            .rightHandler({ [weak self] _ in
                self?.previewView.footerView.replaceJoinView.isSelected = true
                self?.doCommit()
            })
            .show()
    }
}
