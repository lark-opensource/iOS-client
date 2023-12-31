//
//  FloatingInMeetingViewController.swift
//  ByteView
//
//  Created by chentao on 2019/5/26.
//

import UIKit
import RxSwift
import ByteViewCommon
import ByteViewNetwork
import Whiteboard
import ByteViewSetting
import ByteViewRtcBridge
import UniverseDesignColor
import ByteViewUI

extension FloatingMaskView {
    func setupWith(networkState: RtcNetworkStatus) {
        switch networkState.networkShowStatus {
        case .disconnected:
            self.infoStatus = I18n.View_G_Disconnected_StatusShow
        case .iceDisconnected:
            self.infoStatus = I18n.View_G_ConnectionError_StatusShow
        default:
            self.infoStatus = ""
        }
    }
}

// 最小化浮窗
final class FloatingInMeetingViewController: BaseViewController,
                                       InMeetFloatingViewModelDelegate {

    private var watermarkView: UIView?

    private let contentView = UIView()
    let floatingView = FloatingSkeletonView()

    private(set) lazy var subscribeConfig: MultiResSubscribeConfig = {
        let cfgs = viewModel.meeting.setting.multiResolutionConfig
        let normalCfg: ByteViewSetting.MultiResSubscribeResolution
        let sipCfg: ByteViewSetting.MultiResSubscribeResolution
        if Display.pad {
           let cfg = cfgs.pad.subscribe
            normalCfg = cfg.gridFloat
            sipCfg = cfg.gridFloatSip
        } else {
            let cfg = cfgs.phone.subscribe
            normalCfg = cfg.gridFloat
            sipCfg = cfg.gridFloatSip
        }
        return MultiResSubscribeConfig(normal: normalCfg.toRtc(),
                                       priority: .low,
                                       sipOrRoom: sipCfg.toRtc())
    }()

    let isPIPFloatingVC: Bool
    let viewModel: InMeetFloatingViewModel

    var participantView: FloatingParticipantView?
    var shareScreenVideoVC: InMeetShareScreenVideoVC?
    var msThumbVC: InMeetFollowThumbnailVC?
    var whiteboardViewController: UIViewController?
    lazy var syncCheckId = "\(Self.syncCheckId)_\(address(of: self))"

    private lazy var floatingInMeetMaskView = FloatingMaskView()
    private lazy var systemCallingStatusView: InMeetSystemCallingStatusView = {
        let view = InMeetSystemCallingStatusView()
        view.userInfoStatus = .busy
        view.isHidden = true
        if Display.phone {
            view.displayParams = .systemCallingSmallPhone
        } else {
            view.displayParams = .systemCallingSmallPad
        }
        return view
    }()

    private var transitionVC: TransitionFloatingViewController?

    private let connectingStates: Set<InMeetRtcReachableState> = [.interrupted, .timeout, .lost]
    private var connectingVC: InMeetReconnectingFloatingViewController?
    private var isConnectingVisible = false

    required init?(coder: NSCoder) {
        return nil
    }

    init(viewModel: InMeetFloatingViewModel, isPIPFloatingVC: Bool = false) {
        self.viewModel = viewModel
        self.isPIPFloatingVC = isPIPFloatingVC
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        viewModel.meeting.syncChecker.unregisterCamera(self, for: syncCheckId)
        viewModel.meeting.syncChecker.unregisterMicrophone(self, for: syncCheckId)
    }

    private var isFloatingLandspace: Bool = false {
        didSet {
            guard isFloatingLandspace != oldValue else { return }
            if let gridInfo = self.viewModel.gridInfo {
                updateGridInfo(gridInfo)
            }
        }
    }

    private var context: InMeetViewContext {
        viewModel.context
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.bindViewModel()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        isFloatingLandspace = view.frame.width > view.frame.height
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MeetingTracksV2.trackDisplayOnTheCallPage(true, isSharing: viewModel.context.meetingContent.isShareContent,
                                                  meeting: viewModel.meeting)
        context.post(.inMeetFloatingDidAppear)
    }

    private func setupViews() {
        self.view.backgroundColor = nil

        self.view.addSubview(contentView)
        contentView.addSubview(floatingView)

        contentView.applyFloatingBGAndBorder()

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        floatingView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(floatingInMeetMaskView)
        floatingInMeetMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(systemCallingStatusView)
        systemCallingStatusView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupTraitCollection()
        if let manager = viewModel.breakoutRoom {
            manager.transition.addObserver(self)
            updateTransitioning(manager.transition.isTransitioning, info: manager.transition.transitionInfo)
        }
    }

    func bindViewModel() {
        var topIcons: FloatingTopStatusView.TopIcons = []
        if viewModel.isLiving {
            topIcons.insert(.live)
        }
        if viewModel.isRecording {
            topIcons.insert(.recording)
        }
        if viewModel.isTranscribing {
            topIcons.insert(.transcribe)
        }
        self.floatingView.topStatusView.icons = topIcons
        if let gridInfo = viewModel.gridInfo {
            updateGridInfo(gridInfo)
        }
        viewModel.delegate = self
        if !isPIPFloatingVC {
//            viewModel.shareScreenVM?.delegate = self
        }
        setupWatermark()

        let network = viewModel.meeting.rtc.network
        showConnectingIfNeeded(network.reachableState)
        network.addListener(self)
    }

    func didChangeRecording(_ vm: InMeetFloatingViewModel) {
        Util.runInMainThread { [weak self] in
            if let self = self {
                if self.viewModel.isRecording {
                    self.floatingView.topStatusView.icons.insert(.recording)
                } else {
                    self.floatingView.topStatusView.icons.remove(.recording)
                }
            }
        }
    }

    func didChangeLiving(_ vm: InMeetFloatingViewModel) {
        Util.runInMainThread { [weak self] in
            if let self = self {
                if self.viewModel.isLiving {
                    self.floatingView.topStatusView.icons.insert(.live)
                } else {
                    self.floatingView.topStatusView.icons.remove(.live)
                }
            }
        }
    }

    func didChangeTranscribing(_ vm: InMeetFloatingViewModel) {
        Util.runInMainThread { [weak self] in
            if let self = self {
                if self.viewModel.isTranscribing {
                    self.floatingView.topStatusView.icons.insert(.transcribe)
                } else {
                    self.floatingView.topStatusView.icons.remove(.transcribe)
                }
            }
        }
    }

    func didChangeGridInfo(_ vm: InMeetFloatingViewModel) {
        Util.runInMainThread { [weak self] in
            if let self = self, let info = self.viewModel.gridInfo {
                self.updateGridInfo(info)
            }
        }
    }

    private func updateUserInfo(_ gridInfo: InMeetFloatingGridInfo, userInfoView: InMeetUserInfoView) {
        let userInfoParticipant = isFloatingLandspace ? (gridInfo.speakingParticipant ?? gridInfo.contentParticipant) : gridInfo.contentParticipant
        let name = isFloatingLandspace ? (gridInfo.speakingName ?? gridInfo.contentName) : gridInfo.contentName
        let settings = userInfoParticipant.settings
        let isMe = userInfoParticipant.user == viewModel.meeting.account
        let isMicDenied = isMe && Privacy.audioDenied
        let isMuted = isMicDenied || settings.isMicrophoneMutedOrUnavailable

        let displayName = self.getDisplayName(isFocusVideo: gridInfo.gridType == .focusVideo,
                                              isSpeaking: gridInfo.speakingParticipant != nil,
                                              name: name)


        let userInfo = ParticipantUserInfoStatus(hasRoleTag: false,
                                                 meetingRole: userInfoParticipant.meetingRole,
                                                 isSharing: false,
                                                 isFocusing: false,
                                                 isMute: isMuted,
                                                 isLarkGuest: false,
                                                 name: displayName.1 ?? "",
                                                 attributedName: displayName.0,
                                                 isRinging: false,
                                                 isMe: isMe,
                                                 audioMode: settings.audioMode,
                                                 is1v1: gridInfo.is1V1,
                                                 meetingSource: nil,
                                                 isRoomConnected: false,
                                                 isLocalRecord: false)
        userInfoView.userInfoStatus = userInfo
    }

    private func updateGridInfo(_ info: InMeetFloatingGridInfo) {
        Logger.ui.info("set floating grid info")

        if let localNetworkStatus = info.localNetworkStatus,
           (localNetworkStatus.networkShowStatus == .disconnected || localNetworkStatus.networkShowStatus == .iceDisconnected) {
            self.floatingInMeetMaskView.setupWith(networkState: localNetworkStatus)
        } else if info.is1V1,
                  let remoteNetworkStatus = info.remoteNetworkStatus {
            self.floatingInMeetMaskView.setupWith(networkState: remoteNetworkStatus)
        } else {
            self.floatingInMeetMaskView.infoStatus = ""
        }

        var shouldBind = false
        switch info.gridType {
        case .video, .focusVideo:
            self.displayParticipant()
            if info.isMe {
                shouldBind = true
            }
            self.participantView?.setFloatingInfo(info)
        case .sharedScreen:
            self.displayShareScreen()
        case .sharedDocument:
            self.displayMSThumbnail()
        case .whiteBoard:
            self.displayWhiteboard()
        }

        let networkIcon = info.localNetworkStatus?.networkIcon() ?? (nil, false)
        self.floatingView.topStatusView.networkImg = networkIcon.1 ? networkIcon.0 : nil
        self.updateUserInfo(info, userInfoView: self.floatingView.userInfoView)
        self.systemCallingStatusView.isHidden = !(info.isCalling && !info.isMe && self.floatingInMeetMaskView.isHidden)

        if shouldBind {
            viewModel.meeting.syncChecker.registerCamera(self, for: syncCheckId)
            viewModel.meeting.syncChecker.registerMicrophone(self, for: syncCheckId)
        } else {
            viewModel.meeting.syncChecker.unregisterCamera(self, for: syncCheckId)
            viewModel.meeting.syncChecker.unregisterMicrophone(self, for: syncCheckId)
        }
    }

    private func setupTraitCollection() {
        guard Display.pad else {
            return
        }

        self.handleRootTraitCollectionChanged(VCScene.rootTraitCollection ?? traitCollection)
        self.view.vc.windowSceneLayoutContextObservable.addObserver(self) { [weak self] _, context in
            self?.handleRootTraitCollectionChanged(context.traitCollection)
        }
    }

    private func handleRootTraitCollectionChanged(_ traitCollection: UITraitCollection) {
        if traitCollection.horizontalSizeClass == .regular {
            self.floatingView.userInfoView.displayParams = .floatingLarge
            self.floatingInMeetMaskView.updateDisplayStyle(isPad: true)
        } else {
            self.floatingView.userInfoView.displayParams = .floating
            self.floatingInMeetMaskView.updateDisplayStyle(isPad: false)
        }
    }

    private func getDisplayName(isFocusVideo: Bool,
                                isSpeaking: Bool,
                                name: String) -> (NSAttributedString?, String?) {
        if !isFloatingLandspace {
            return (nil, name)
        }
        var displayName: String?
        if isFocusVideo {
            displayName = I18n.View_MV_FocusVideoName_Icon(name)
        } else if isSpeaking {
            displayName = I18n.View_VM_SpeakingColonName(name)
        }
        if let displayName = displayName {
            let attributedText = NSMutableAttributedString(string: displayName, config: .tiniestAssist)
            attributedText.addAttribute(.foregroundColor,
                                        value: UIColor.ud.N600,
                                        range: NSRange(location: 0, length: displayName.count - name.count))
            attributedText.addAttribute(.foregroundColor,
                                        value: UIColor.ud.N900,
                                        range: NSRange(location: displayName.count - name.count, length: name.count))
            return (attributedText, nil)
        } else {
            return (nil, name)
        }
    }
}

// MARK: - BreakoutRoom Transition
extension FloatingInMeetingViewController: TransitionManagerObserver {

    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        updateTransitioning(isTransition, info: info)
    }

    private func updateTransitioning(_ isTransitioning: Bool, info: BreakoutRoomInfo?) {
        if isTransitioning, transitionVC == nil {
            BreakoutRoomTracksV2.beginTransition(viewModel.meeting)
            let vm = TransitionViewModel(meeting: viewModel.meeting, firstInfo: info, roomManager: viewModel.resolver.resolve())
            transitionVC = TransitionFloatingViewController(viewModel: vm)
            Util.runInMainThread {
                guard let vc = self.transitionVC else { return }
                self.contentView.addSubview(vc.view)
                vc.view.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
            }
        } else if !isTransitioning, let vc = transitionVC {
            viewModel.resetChatMessage()
            transitionVC = nil
            Util.runInMainThread {
                vc.view.removeFromSuperview()
            }
        }
    }
}

extension FloatingInMeetingViewController: InMeetRtcNetworkListener {

    func didChangeRtcReachableState(_ state: InMeetRtcReachableState) {
        DispatchQueue.main.async { [weak self] in
            self?.showConnectingIfNeeded(state)
        }
    }

    private func showConnectingIfNeeded(_ state: InMeetRtcReachableState) {
        let isConnecting = connectingStates.contains(state)
        guard isConnecting != isConnectingVisible else { return }
        isConnectingVisible = isConnecting
        if isConnecting {
            let vc = InMeetReconnectingFloatingViewController()
            view.addSubview(vc.view)
            vc.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            connectingVC = vc
        } else if let vc = connectingVC {
            vc.view.removeFromSuperview()
            connectingVC = nil
        }
    }
}

extension FloatingInMeetingViewController {
    func setupWatermark() {
        let combined = Observable.combineLatest(
            viewModel.meeting.service.larkUtil.getVCShareZoneWatermarkView(),
            viewModel.shareWatermark.showWatermarkRelay.asObservable().distinctUntilChanged())
        combined.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, showWatermark) in
                guard let self = self else { return }
                self.watermarkView?.removeFromSuperview()
                guard showWatermark, let view = view else {
                    self.watermarkView = nil
                    return
                }
                view.frame = self.view.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.contentView.addSubview(view)
                view.layer.zPosition = .greatestFiniteMagnitude
                self.watermarkView = view
            }).disposed(by: rx.disposeBag)
    }
}

extension FloatingInMeetingViewController: MicrophoneStateRepresentable, CameraStateRepresentable {
    static let syncCheckId = "FloatingWindowGrid"

    var micIdentifier: String { Self.syncCheckId }

    var isMicMuted: Bool? {
        floatingView.userInfoView.isMicMuted
    }

    var cameraIdentifier: String { Self.syncCheckId }

    var isCameraMuted: Bool? {
        // 仅检测用户rust摄像头状态为关闭且宫格流可见时，视频不能处于渲染状态
        if isVisible && viewModel.gridInfo?.contentParticipant.settings.isCameraMutedOrUnavailable == true {
            return participantView?.isRendering == false
        }
        // 其他情况一律绕过检测
        return nil
    }

    private var isVisible: Bool {
        let isAttachedToWindow = participantView?.window != nil
        // PIP app 在后台也要检测，普通小窗只检测前台状态
        let isActive = isPIPFloatingVC || UIApplication.shared.applicationState != .background
        return isAttachedToWindow && isActive
    }
}


extension FloatingParticipantView {
    func setFloatingInfo(_ gridInfo: InMeetFloatingGridInfo) {
        self.isMe = gridInfo.isMe

        let streamKey: RtcStreamKey?
        if gridInfo.contentParticipant.settings.isCameraMutedOrUnavailable {
            streamKey = nil
        } else if gridInfo.isMe {
            streamKey = .local
        } else {
            if gridInfo.isPortraitMode {
                streamKey = nil
            } else {
                streamKey = .stream(uid: gridInfo.rtcUid, sessionId: gridInfo.sessionId)
            }
        }

        self.streamRenderView.setStreamKey(streamKey, isSipOrRoom: gridInfo.contentParticipant.user.isSipOrRoom)
        self.avatar.setAvatarInfo(gridInfo.avatarInfo, size: .large)
        if !gridInfo.isConnected {
            self.avatarDesc = I18n.View_G_Connecting
        } else {
            self.avatarDesc = ""
        }
        self.updateRenderMode()
    }
}
