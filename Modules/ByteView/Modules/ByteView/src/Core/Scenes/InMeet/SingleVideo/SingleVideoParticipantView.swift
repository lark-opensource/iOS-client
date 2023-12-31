//
//  SingleVideoParticipantView.swift
//  ByteView
//
//  Created by liujianlong on 2022/6/22.
//

import UIKit
import RxSwift
import RxRelay
import Action
import UniverseDesignTheme
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting
import ByteViewRtcBridge

class SingleVideoParticipantView: UIView {

    enum FromSource {
        case singleVideoVC // 单流放大
        case thumbnailContentVC // 缩略图视图的主视图
        case speechContentVC // 演讲者视图的主视图
    }

    static let logger = Logger.grid

    var disposeBag = DisposeBag()
    var cellViewModel: InMeetGridCellViewModel?

    let bottomBarLayoutGuide = UILayoutGuide()
    let topBarLayoutGuide = UILayoutGuide()

    var isLandscapeMode: Bool = false {
        didSet {
            guard self.isLandscapeMode != oldValue else {
                return
            }
            resetFullScreenSafeAreaLayoutGuide()
        }
    }

    var isRendering: Bool {
        return streamRenderView.isRendering
    }

    // 圆角半径
    var cornerRadius: CGFloat {
        didSet {
            configureCornerAndBorder()
        }
    }

    // 边框的颜色
    private var borderColor: UIColor = UIColor.ud.lineDividerDefault

    // 边框线条宽度
    var borderWidth: CGFloat = 0.5

    var emojiViewSize: CGFloat = 32

    private func configureCornerAndBorder() {
        contentView.layer.cornerRadius = cornerRadius
    }

    var layoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard oldValue != layoutStyle else {
                return
            }
            userInfoView.alpha = self.layoutStyle == .fullscreen ? 0.8 : 1.0
        }
    }

    var contentBackgroundColor: UIColor {
        return UIColor.ud.vcTokenMeetingBgVideoOff
    }

    var userInfoParams: UserInfoDisplayStyleParams {
        switch fromSource {
        case .singleVideoVC:
            return .fillScreen
        case .thumbnailContentVC, .speechContentVC:
            return .inMeetingGrid
        }
    }

    let isZoomEnabled: Bool
    let fromSource: FromSource

    init(isZoomEnabled: Bool, cornerRadius: CGFloat, fromSource: FromSource) {
        self.isZoomEnabled = isZoomEnabled
        self.cornerRadius = cornerRadius
        self.fromSource = fromSource
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        if Display.pad {
            updateStatusEmojiView()
        }
    }

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    let streamRenderView = StreamRenderView()
    var zoomView: ZoomView?
    let isRenderingRelay = BehaviorRelay<Bool>(value: false)
    var systemCallingStatusValue: ParticipantSettings.MobileCallingStatus? {
        didSet {
            guard systemCallingStatusValue != oldValue else { return }
            updateSystemCallingInfo(mobileCallingStatus: systemCallingStatusValue)
        }
    }

    private var autoHideToolbarConfig: AutoHideToolbarConfig? {
        didSet {
            self.zoomView?.autoHideToolbarConfig = autoHideToolbarConfig
        }
    }
    private func setupRenderView() {
        let renderView = self.streamRenderView
        self.isRenderingRelay.accept(renderView.isRendering)
        renderView.renderMode = .renderModeFit
        renderView.clipsToBounds = true
        contentView.insertSubview(renderView, at: 0)
        renderView.frame = self.contentView.bounds
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderView.addListener(self)
    }

    func resetFullScreenSafeAreaLayoutGuide() {
        userInfoView.snp.remakeConstraints { (make) in
            if Display.pad, (fromSource == .thumbnailContentVC || fromSource == .speechContentVC) {
                make.left.equalToSuperview().inset(2)
                make.right.lessThanOrEqualToSuperview().inset(2)
                make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-2).priority(.veryHigh)
                make.bottom.lessThanOrEqualTo(self.safeAreaLayoutGuide).offset(-2)
                make.bottom.equalTo(self.bottomBarLayoutGuide.snp.top).offset(-2).priority(.veryHigh)
                make.bottom.lessThanOrEqualTo(self.bottomBarLayoutGuide.snp.top).offset(-2)
            } else {
                if self.isLandscapeMode {
                    make.bottom.equalTo(self.safeAreaLayoutGuide)
                } else {
                    make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-4).priority(.veryHigh)
                    make.bottom.lessThanOrEqualTo(self.safeAreaLayoutGuide).offset(-4)
                    make.bottom.equalTo(self.bottomBarLayoutGuide.snp.top).offset(-6).priority(.veryHigh)
                    make.bottom.lessThanOrEqualTo(self.bottomBarLayoutGuide.snp.top).offset(-6)
                }
                make.left.right.equalToSuperview().inset(6)
            }
        }
        updateLeftOperationContainerLayout()
    }

    let cameraHaveNoAccessImageView: UIImageView = {
        let image = UDIcon.getIconByKey(.videoOffOutlined, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 144.0, height: 144.0))
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()

    let avatar = AvatarView()

    lazy var leftOperationContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .leading
        return stackView
    }()

    lazy var removeFocusButton: SingleVideoRemoveFocusButton = {
        let button = SingleVideoRemoveFocusButton()
        button.isHiddenInStackView = true
        button.addTarget(self, action: #selector(removeFocus(_:)), for: .touchUpInside)
        return button
    }()

    let systemCallingStatusView: InMeetSystemCallingStatusView = {
        let view = InMeetSystemCallingStatusView()
        view.isHidden = true
        return view
    }()

    var shouldShowRomoveFocusButton = false {
        didSet {
            Util.runInMainThread {
                UIView.performWithoutAnimation {
                    self.removeFocusButton.isHiddenInStackView = !self.shouldShowRomoveFocusButton
                }
            }
        }
    }

    static let switchCamNormalImg = UDIcon.getIconByKey(.cameraFlipOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 24.0, height: 24.0))
    static let switchCamHighlightImg = UDIcon.getIconByKey(.cameraFlipOutlined, iconColor: .ud.primaryOnPrimaryFill.withAlphaComponent(0.5), size: CGSize(width: 24.0, height: 24.0))

    lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.baselineAdjustment = .alignBaselines
        label.text = I18n.View_VM_Loading
        label.contentMode = .left
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    lazy var statusEmojiView: BVImageView = {
        let emoji = BVImageView()
        emoji.edgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        emoji.backgroundColor = .ud.vcTokenMeetingBgFloat.withAlphaComponent(0.7)
        emoji.layer.masksToBounds = true
        emoji.layer.cornerRadius = 6
        emoji.isHidden = true
        return emoji
    }()

    let userInfoView = InMeetUserInfoView()

    private(set) var floatingInfo: InMeetFloatingGridInfo?

    var imageInfo: AvatarInfo = .asset(AvatarResources.unknown) {
        didSet {
            guard imageInfo != oldValue else {
                return
            }
            avatar.setAvatarInfo(imageInfo, size: .large)
        }
    }

    var didTapUserName: ((Participant) -> Void)?
    var didTapRemoveFocus: (() -> Void)?

    private func setUpUI() {
        self.addLayoutGuide(bottomBarLayoutGuide)
        self.addLayoutGuide(topBarLayoutGuide)
        addSubview(contentView)
        configureCornerAndBorder()
        contentView.addSubview(cameraHaveNoAccessImageView)
        contentView.addSubview(avatar)
        contentView.addSubview(systemCallingStatusView)
        contentView.addSubview(userInfoView)
        contentView.addSubview(leftOperationContainer)
        contentView.addSubview(statusEmojiView)

        leftOperationContainer.addArrangedSubview(removeFocusButton)

        setupRenderView()
        makeConstraints()
    }

    private func makeConstraints() {
        bottomBarLayoutGuide.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.0)
        }
        topBarLayoutGuide.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0.0)
        }
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        resetFullScreenSafeAreaLayoutGuide()
        contentView.backgroundColor = contentBackgroundColor
        contentView.clipsToBounds = true
        self.layer.shadowOpacity = 0.0
        avatar.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(avatar.snp.height)
            make.width.equalToSuperview().multipliedBy(0.5).priority(.veryHigh)
            make.height.equalToSuperview().multipliedBy(0.5).priority(.veryHigh)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.5)
        }
        cameraHaveNoAccessImageView.snp.remakeConstraints { (make) in
            let sizeMultiplier = InMeetFlowComponent.isNewLayoutEnabled ? 0.38 : 0.4
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(cameraHaveNoAccessImageView.snp.height)
            make.width.equalToSuperview().multipliedBy(sizeMultiplier).priority(.veryHigh)
            make.height.equalToSuperview().multipliedBy(sizeMultiplier).priority(.veryHigh)
            make.width.lessThanOrEqualToSuperview().multipliedBy(sizeMultiplier)
            make.height.lessThanOrEqualToSuperview().multipliedBy(sizeMultiplier)
        }
        removeFocusButton.snp.remakeConstraints { make in
            make.left.equalToSuperview()
        }
        leftOperationContainer.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(8).priority(.veryHigh)
            make.left.equalToSuperview().inset(10)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(8).priority(.veryHigh)
            make.top.greaterThanOrEqualTo(self.safeAreaLayoutGuide).offset(8)
            make.top.equalTo(self.topBarLayoutGuide.snp.bottom).offset(12).priority(.veryHigh)
            make.top.greaterThanOrEqualTo(self.topBarLayoutGuide.snp.bottom).offset(12)
        }
        statusEmojiView.snp.remakeConstraints { make in
            make.centerX.equalTo(userInfoView)
            make.bottom.equalTo(userInfoView.snp.top).offset(-8)
            make.size.equalTo(emojiViewSize)
        }
        systemCallingStatusView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
        // config userInfoView
        userInfoView.displayParams = userInfoParams
    }

    private func updateStatusEmojiView() {
        let minLength = min(bounds.width, bounds.height)
        // disable-lint: magic number
        if fromSource == .singleVideoVC {
            emojiViewSize = Display.pad ? 52 : 32
        } else if minLength > 360 {
            emojiViewSize = 52
        } else if minLength >= 240 {
            emojiViewSize = 44
        } else if minLength >= 120 {
            emojiViewSize = 36
        } else {
            emojiViewSize = 28
        }
        let padding: CGFloat = emojiViewSize >= 44 ? 5 : 3
        let radius: CGFloat = emojiViewSize >= 44 ? 8 : 6
        statusEmojiView.edgeInsets = .init(top: padding, left: padding, bottom: padding, right: padding)
        statusEmojiView.layer.cornerRadius = radius
        statusEmojiView.snp.updateConstraints { make in
            make.size.equalTo(emojiViewSize)
        }
        // enable-lint: magic number
    }
}

extension SingleVideoParticipantView: StreamRenderViewListener {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        self.isRenderingRelay.accept(isRendering)
    }

    func streamRenderViewDidChangeVideoFrameSize(_ renderView: StreamRenderView, size: CGSize?) {
        self.updateVideoFrameSize(size)
    }

    private func updateVideoFrameSize(_ size: CGSize?) {
        guard isZoomEnabled, let size = size, size.width > 1.0 && size.height > 1.0 else {
            return
        }

        Logger.renderView.info("single view video size \(size)")
        if let zoomView = self.zoomView,
           (zoomView.contentSize.width > zoomView.contentSize.height) == (size.width > size.height) {
            zoomView.updateContentSize(size)
            return
        }
        self.streamRenderView.removeFromSuperview()
        let zoomView = ZoomView(contentView: self.streamRenderView,
                                contentSize: size,
                                fullScreenIfNeeded: true,
                                doubleTapEnable: false)
        zoomView.autoHideToolbarConfig = self.autoHideToolbarConfig
        self.contentView.insertSubview(zoomView, at: 0)
        zoomView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.zoomView?.removeFromSuperview()
        self.zoomView = zoomView
        self.layoutIfNeeded()
    }
}

// nolint: long_function
extension SingleVideoParticipantView {
    func bind(viewModel: InMeetGridCellViewModel, layoutType: String) {
        let bag = DisposeBag()
        self.disposeBag = bag
        self.cellViewModel = viewModel
        streamRenderView.bindMeetingSetting(viewModel.meeting.setting)
        if viewModel.meeting.setting.canShowRtcDefinition {
            streamRenderView.addDefinitionViewIfNeeded()
        }
        self.autoHideToolbarConfig = viewModel.meeting.setting.autoHideToolbarConfig

        let cfgs = viewModel.meeting.setting.multiResolutionConfig
        if Display.pad {
            let cfg = cfgs.pad.subscribe
            self.streamRenderView.multiResSubscribeConfig = MultiResSubscribeConfig(normal: cfg.gridFull.toRtc(), priority: .high)
        } else {
            let cfg = cfgs.phone.subscribe
            self.streamRenderView.multiResSubscribeConfig = MultiResSubscribeConfig(normal: cfg.gridFull.toRtc(), priority: .high)
        }

        Self.logger.info("bind participant view \(viewModel.pid)")
        self.streamRenderView.layoutType = layoutType

        if viewModel.pid == viewModel.meeting.account {
            Self.logger.info("ParticipantView is showing local video")
            self.streamRenderView.setStreamKey(.local)
        } else {
            viewModel.isPortraitMode
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isPortrait in
                    guard let self = self else {
                        return
                    }
                    if isPortrait {
                        Self.logger.info("ParticipantView is in portrait mode when sharing screen")
                        self.streamRenderView.setStreamKey(nil)
                    } else {
                        Self.logger.info("ParticipantView is showing remote video")
                        self.streamRenderView.setStreamKey(.stream(uid: viewModel.rtcUid,
                                                                   sessionId: viewModel.meeting.sessionId),
                                                           isSipOrRoom: viewModel.pid.isSipOrRoom)
                    }
                })
                .disposed(by: bag)
        }

        viewModel.participantInfo
            .map { $0.1.avatarInfo }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] avatarInfo in
                guard let self = self else { return }
                self.imageInfo = avatarInfo
            })
            .disposed(by: bag)

        viewModel.meetingLayoutStyle
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] layoutStyle in
                self?.layoutStyle = layoutStyle
            })
            .disposed(by: bag)

        viewModel.participantInfo
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] userInfo in
                guard let self = self else {
                    return
                }
                self.systemCallingStatusValue = userInfo.0.settings.mobileCallingStatus
            })
            .disposed(by: bag)

        userInfoView.isHidden = true

        let isMe = viewModel.isMe
        let is1V1 = viewModel.meeting.participant.currentRoom.nonRingingCount == 2

        Observable.combineLatest(viewModel.sharingUserIdentifiers,
                                 viewModel.focusingUser,
                                 viewModel.participantInfo,
                                 viewModel.hasRoleTag,
                                 viewModel.rtcNetworkStatus,
                                 InMeetOrientationToolComponent.isLandscapeModeRelay.asObservable())
        .map({ (sharingUsers: Set<ByteviewUser>, focusingUser: ByteviewUser?, participantInfo: (Participant, ParticipantUserInfo), hasRoleTag: Bool, rtcNetworkStatus: RtcNetworkStatus?, isLandscapeMode: Bool) in
            // 其他别名显示收敛在InMeetParticipantService中。此处用户名展示异化为：当参会人在“呼叫中”时，仅显示原名或别名
            let anotherName = viewModel.meeting.setting.isShowAnotherNameEnabled ? participantInfo.1.user?.anotherName ?? participantInfo.1.originalName : participantInfo.1.originalName
            return Self.makeUserInfoStatus(sharingUsers: sharingUsers,
                                    focusingUser: focusingUser,
                                    name: participantInfo.1.name,
                                    originalName: anotherName,
                                    participant: participantInfo.0,
                                    hasRoleTag: hasRoleTag,
                                    rtcNetworkStatus: rtcNetworkStatus,
                                    isMe: isMe,
                                    isLandscapeMode: isLandscapeMode,
                                    is1V1: is1V1,
                                    meetingSource: viewModel.meeting.info.meetingSource)
            })
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] userInfo in
                guard let self = self else {
                    return
                }
                self.userInfoView.isHidden = false
                self.userInfoView.displayParams = self.userInfoParams
                self.reloadUserStatusInfoView2(userInfo: userInfo)
                self.updateStatusEmojiInfo(statusEmojiInfo: userInfo.conditionEmoji)
            })
            .disposed(by: bag)

        if viewModel.isMe {
            // 宫格视图刚创建时，userInfoView 的状态可能未更新，直到上面的 subscribe 方法执行前存在一段真空期，
            // 此时userInfoView 的麦克风图标可能跟实际状态不符，因此这里延迟一段时间注册监控
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                guard let self = self, self.cellViewModel?.isMe == true else { return }
                viewModel.meeting.syncChecker.registerCamera(self)
                viewModel.meeting.syncChecker.registerMicrophone(self)
            })
        } else {
            viewModel.meeting.syncChecker.unregisterCamera(self)
            viewModel.meeting.syncChecker.unregisterMicrophone(self)
        }

        userInfoView.didTapUserName = { [weak self] in
            guard let self = self, let participant = self.cellViewModel?.participant.value else { return }
            self.didTapUserName?(participant)
        }

        self.avatar.isHidden = false
        self.cameraHaveNoAccessImageView.isHidden = true
        self.streamRenderView.isHidden = true
        Observable.combineLatest(viewModel.participant,
                                 viewModel.isPortraitMode,
                                 self.isRenderingRelay)
        .distinctUntilChanged({ $0 == $1 })
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] participant, isPortraitMode, isRendering in
            guard let self = self else {
                return
            }
            self.updateAvatarVisibility2(participant: participant,
                                         isMe: isMe,
                                         isPortraitMode: isPortraitMode,
                                         isRendering: isRendering)
        })
        .disposed(by: bag)
    }

    private func updateLeftOperationContainerLayout() {
        leftOperationContainer.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(8).priority(.veryHigh)
            make.left.equalToSuperview().inset(10)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(8).priority(.veryHigh)
            make.top.greaterThanOrEqualTo(self.safeAreaLayoutGuide).offset(8)
            make.top.equalTo(self.topBarLayoutGuide.snp.bottom).offset(10).priority(.veryHigh)
            make.top.greaterThanOrEqualTo(self.topBarLayoutGuide.snp.bottom).offset(10)
        }
    }

    private static func makeUserInfoStatus(sharingUsers: Set<ByteviewUser>,
                                           focusingUser: ByteviewUser?,
                                           name: String,
                                           originalName: String,
                                           participant: Participant,
                                           hasRoleTag: Bool,
                                           rtcNetworkStatus: RtcNetworkStatus?,
                                           isMe: Bool,
                                           isLandscapeMode: Bool,
                                           is1V1: Bool,
                                           meetingSource: VideoChatInfo.MeetingSource) -> ParticipantUserInfoStatus {
        let isSharingContent = sharingUsers.contains(participant.user)
        let isFocusing = focusingUser == participant.user
        let meetingRole: ParticipantMeetingRole = participant.meetingRole
        let isMute = participant.settings.isMicrophoneMutedOrUnavailable
        let isLarkGuest = participant.isLarkGuest
        let name = name
        let isRinging = participant.status == .ringing
        let userInfoStatus = ParticipantUserInfoStatus(
            hasRoleTag: hasRoleTag,
            meetingRole: meetingRole,
            isSharing: isSharingContent,
            isFocusing: isFocusing,
            isMute: isMute,
            isLarkGuest: isLarkGuest,
            name: isRinging ? originalName : name,
            isRinging: isRinging,
            isMe: isMe,
//            showNameAndMicOnly: false,
            rtcNetworkStatus: rtcNetworkStatus,
            audioMode: participant.settings.audioMode,
            is1v1: is1V1,
            conditionEmoji: participant.settings.conditionEmojiInfo,
            meetingSource: meetingSource,
            isRoomConnected: participant.settings.targetToJoinTogether != nil,
            isLocalRecord: participant.settings.localRecordSettings?.isLocalRecording == true)
        return userInfoStatus
    }

    func updateSystemCallingInfo(mobileCallingStatus: ParticipantSettings.MobileCallingStatus?) {
        if let isMe = cellViewModel?.isMe, !isMe, mobileCallingStatus == .busy {
            systemCallingStatusView.isHidden = false
            if Display.phone {
                systemCallingStatusView.displayParams = .systemCallingBigPhone
            } else {
                systemCallingStatusView.displayParams = .systemCallingBigPad
            }
        } else {
            systemCallingStatusView.isHidden = true
        }
    }

    private func reloadUserStatusInfoView2(userInfo: ParticipantUserInfoStatus) {
        Self.logger.info("\(self.cellViewModel?.pid.deviceId), reloadUserInfo \(userInfo)")
        userInfoView.userInfoStatus = userInfo
    }

    func updateStatusEmojiInfo(statusEmojiInfo: ParticipantSettings.ConditionEmojiInfo?) {
        var image: UIImage?
        if statusEmojiInfo?.isHandsUp ?? false {
            image = EmojiResources.getEmojiSkin(by: statusEmojiInfo?.handsUpEmojiKey)
        } else if statusEmojiInfo?.isStepUp ?? false {
            image = EmojiResources.emoji_quickleave
        }

        if image != nil {
            statusEmojiView.isHiddenInStackView = false
            statusEmojiView.image = image
            statusEmojiView.removeFromSuperview()
            switch fromSource {
            case .singleVideoVC:
                contentView.addSubview(statusEmojiView)
                statusEmojiView.snp.remakeConstraints { make in
                    make.centerX.equalTo(userInfoView)
                    make.bottom.equalTo(userInfoView.snp.top).offset(-8)
                    make.size.equalTo(emojiViewSize)
                }
            case .thumbnailContentVC, .speechContentVC:
                leftOperationContainer.addArrangedSubview(statusEmojiView)
                statusEmojiView.snp.remakeConstraints { make in
                    make.left.equalToSuperview()
                    make.size.equalTo(emojiViewSize)
                }
            }
        } else {
            statusEmojiView.isHiddenInStackView = true
            statusEmojiView.image = nil
        }
    }

    private func updateAvatarVisibility2(participant: Participant,
                                         isMe: Bool,
                                         isPortraitMode: Bool,
                                         isRendering: Bool) {
        let settings = participant.settings

        Self.logger.info("\(participant.rtcUid) isMe: \(isMe), isMuted: \(settings.isCameraMutedOrUnavailable), status: \(settings.cameraStatus), isRendering: \(isRendering)")

        if isMe && !Privacy.cameraAccess.value.isAuthorized {
            Self.logger.info("\(participant.rtcUid) show cameraHaveNoAccessImageView")
            avatar.isHidden = true
            cameraHaveNoAccessImageView.isHidden = false
            self.streamRenderView.isHidden = true
            self.zoomView?.isHidden = true
        } else if !settings.isCameraMutedOrUnavailable && isRendering && !isPortraitMode {
            Self.logger.info("\(participant.rtcUid) show streamRenderView")
            avatar.isHidden = true
            cameraHaveNoAccessImageView.isHidden = true
            self.streamRenderView.isHidden = false
            self.zoomView?.isHidden = false
        } else {
            Self.logger.info("\(participant.rtcUid) show avatar")
            avatar.isHidden = false
            cameraHaveNoAccessImageView.isHidden = true
            self.streamRenderView.isHidden = true
            self.zoomView?.isHidden = true
        }

    }

    @objc private func removeFocus(_ sender: Any) {
        didTapRemoveFocus?()
    }
}

extension SingleVideoParticipantView: MicrophoneStateRepresentable, CameraStateRepresentable {
    static let syncCheckId = "SingleVideoGrid"

    var micIdentifier: String { Self.syncCheckId }

    var isMicMuted: Bool? {
        userInfoView.isMicMuted
    }

    var cameraIdentifier: String { Self.syncCheckId }

    var isCameraMuted: Bool? {
        // 仅检测用户rust摄像头状态为关闭且宫格流可见时，视频不能处于渲染状态
        if isVisible && cellViewModel?.participant.value.settings.isCameraMutedOrUnavailable == true {
            return streamRenderView.isHidden
        }
        // 其他情况一律绕过检测
        return nil
    }

    private var isVisible: Bool {
        let isAttachedToWindow = window != nil
        let isActive = UIApplication.shared.applicationState != .background
        return !isHidden && isAttachedToWindow && isActive
    }
}
