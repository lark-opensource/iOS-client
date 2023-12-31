//
//  InMeetingParticipantView.swift
//  ByteView
//
//  Created by Prontera on 2020/11/2.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Lottie
import Action
import RxSwift
import UniverseDesignTheme
import RxRelay
import UniverseDesignIcon
import UniverseDesignShadow
import UniverseDesignColor
import ByteViewCommon
import ByteViewRTCRenderer
import ByteViewNetwork
import ByteViewUI
import ByteViewRtcBridge

struct ParticipantViewStyleConfig: Equatable {
    var isSpeechFloat: Bool
    var isSingleRow: Bool
    // 使用 topBarInset/bottomBarInset 控制名牌、顶部按钮偏移量
    var hasTopBottomBarInset: Bool
    var topBarInset: CGFloat = 0.0
    var bottomBarInset: CGFloat = 0.0

    var showBorderLines: Bool
    // 是否在视频渲染状态下描边
    // Webinar 嘉宾样式, 仅在有视频流时需要描边, 无视频流时不描边
    var showVideoBorderLines: Bool = false
    // 边框的颜色
    var borderColor: UIColor = UIColor.ud.lineDividerDefault
    // 边框线条宽度
    var borderWidth: CGFloat = 0.5
    var cornerRadius: CGFloat
    var isSingleVideoEnabled: Bool
    var renderMode: ByteViewRenderMode

    var userInfoViewStyle: InMeetUserInfoView.UserInfoDisplayStyle = .inMeetingGrid

    var systemCallingStatusInfoSyle: InMeetSystemCallingStatusView.InMeetSystemCallingStatusDisplayStyle = Display.phone ? .systemCallingBigPhone : .systemCallingBigPad

    // Mobile 横屏模式下，单人，页数为 1
    var isLandscapeSingle: Bool = false
    var isOverlayFullScreen: Bool {
        meetingLayoutStyle.isOverlayFullScreen
    }
    var meetingLayoutStyle: MeetingLayoutStyle = .tiled
    var isPhoneLandscapeMode = false
    var avatarOffset: CGFloat = 0.0
    var cameraHaveNoAccessOffset: CGFloat = 0.0
    var topViewHorizontalInset = 6.0
}

extension ParticipantViewStyleConfig {
    static var singleRow: ParticipantViewStyleConfig {
        var cfg = ParticipantViewStyleConfig(isSpeechFloat: false,
                                   isSingleRow: true,
                                   hasTopBottomBarInset: false,
                                   showBorderLines: false,
                                   cornerRadius: 8.0,
                                   isSingleVideoEnabled: true,
                                   renderMode: .renderModeAuto)
        cfg.userInfoViewStyle = .singleRow
        cfg.systemCallingStatusInfoSyle = Display.phone ? .systemCallingSmallPhone : .systemCallingSinglePad
        cfg.renderMode = InMeetFlowComponent.isNewLayoutEnabled ? .renderModeHidden : .renderModeAuto
        cfg.topViewHorizontalInset = 0.0
        return cfg
    }

    static var padGrid: ParticipantViewStyleConfig {
        var cfg = ParticipantViewStyleConfig(isSpeechFloat: false,
                                             isSingleRow: false,
                                             hasTopBottomBarInset: true,
                                             showBorderLines: false,
                                             cornerRadius: 8.0,
                                             isSingleVideoEnabled: true,
                                             renderMode: .renderModePadGallery)
        cfg.userInfoViewStyle = .inMeetingGrid
        cfg.systemCallingStatusInfoSyle = Display.phone ? .systemCallingMidPhone : .systemCallingMidPad
        return cfg
    }

    static var squareGrid: ParticipantViewStyleConfig {
        var cfg = ParticipantViewStyleConfig(isSpeechFloat: false,
                                             isSingleRow: false,
                                             hasTopBottomBarInset: true,
                                             showBorderLines: false,
                                             cornerRadius: 8.0,
                                             isSingleVideoEnabled: true,
                                             renderMode: .renderModeHidden)
        cfg.userInfoViewStyle = .inMeetingGrid
        return cfg
    }

    static var phoneLandscapeGrid: ParticipantViewStyleConfig {
        var cfg = ParticipantViewStyleConfig(isSpeechFloat: false,
                                             isSingleRow: false,
                                             hasTopBottomBarInset: true,
                                             showBorderLines: false,
                                             cornerRadius: 8.0,
                                             isSingleVideoEnabled: true,
                                             renderMode: .renderModeAuto)
        cfg.isPhoneLandscapeMode = true
        cfg.userInfoViewStyle = .inMeetingGrid
        cfg.systemCallingStatusInfoSyle = Display.phone ? .systemCallingMidPhone : .systemCallingMidPad
        return cfg
    }

    static var speechFloating: ParticipantViewStyleConfig {
        var cfg = ParticipantViewStyleConfig(isSpeechFloat: true,
                                             isSingleRow: false,
                                             hasTopBottomBarInset: false,
                                             showBorderLines: true,
                                             cornerRadius: 8.0,
                                             isSingleVideoEnabled: false,
                                             renderMode: .renderModeAuto)
        cfg.userInfoViewStyle = .inMeetingGrid
        cfg.topViewHorizontalInset = 0.0
        return cfg
    }

    static var webinarStage: ParticipantViewStyleConfig {
        var cfg = ParticipantViewStyleConfig(isSpeechFloat: false,
                                             isSingleRow: false,
                                             hasTopBottomBarInset: true,
                                             showBorderLines: false,
                                             cornerRadius: 8.0,
                                             isSingleVideoEnabled: false,
                                             renderMode: .renderModeFit1x1)
        cfg.showVideoBorderLines = true
        cfg.borderColor = .ud.staticWhite.withAlphaComponent(0.2)
        cfg.borderWidth = 1.0
        var userInfoViewStyle = InMeetUserInfoView.UserInfoDisplayStyle.inMeetingGrid
        userInfoViewStyle.components = [.name, .nameDesc]
        cfg.userInfoViewStyle = userInfoViewStyle
        return cfg
    }
}

class InMeetingParticipantView: UIView {
    static let logger = Logger.grid

    struct Layout {
        static var topLeftInset: CGFloat { VCScene.isRegular ? 8 : 6 }
        static var singleRowTopLeftInset: CGFloat = 4
        static var singleRowEmojiSize: CGFloat { Display.pad ? 28 : 24 }
        static var topButtonGuideInset: CGFloat = 6
    }

    lazy var syncCheckId = "\(Self.syncCheckId)_\(address(of: self))"
    var disposeBag = DisposeBag()
    var cellViewModel: InMeetGridCellViewModel?
    var systemCallingStatusValue: ParticipantSettings.MobileCallingStatus? {
        didSet {
            guard systemCallingStatusValue != oldValue else { return }
            updateSystemCallingInfo(mobileCallingStatus: systemCallingStatusValue)
        }
    }

    var isCellVisible: Bool {
        get {
            streamRenderView.isCellVisible
        }
        set {
            streamRenderView.isCellVisible = newValue
        }
    }

    var styleRelay = BehaviorRelay<ParticipantViewStyleConfig>(value: .squareGrid)

    var styleConfig: ParticipantViewStyleConfig = .squareGrid {
        didSet {
            guard self.styleConfig != oldValue else {
                return
            }
            refreshStyle()
            if oldValue.showBorderLines != self.styleConfig.showBorderLines ||
                oldValue.borderColor != self.styleConfig.borderColor ||
                oldValue.showVideoBorderLines != self.styleConfig.showVideoBorderLines ||
                oldValue.borderWidth != self.styleConfig.borderWidth ||
                oldValue.cornerRadius != self.styleConfig.cornerRadius {
                configureCornerAndBorder()
            }
            updateLayoutGuide(styleConfig: self.styleConfig)
            styleRelay.accept(styleConfig)
        }
    }

    var viewSize: CGSize = .zero {
        didSet {
            guard viewSize != oldValue, Display.pad else { return }
            self.updateStatusEmojiConstrains()
        }
    }

    private var emojiViewSize: CGFloat {
        if Display.phone { return 32.0 }
        if styleConfig.isSingleRow { return Layout.singleRowEmojiSize }
        if styleConfig.isSpeechFloat { return 30 }
        if viewSize == .zero { return 52.0 }
        let emojiViewSize: CGFloat
        let minLength = min(viewSize.width, viewSize.height)
        if minLength > 360 {
            emojiViewSize = 52
        } else if minLength >= 240 {
            emojiViewSize = 44
        } else if minLength >= 120 {
            emojiViewSize = 36
        } else {
            emojiViewSize = 28
        }
        return emojiViewSize
    }

    private func refreshStyle() {
        if styleConfig.isSpeechFloat {
            contentView.backgroundColor = UIColor.ud.N100
        } else {
            contentView.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff
        }
        self.layer.shadowOpacity = 0.0

        topView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview().inset(styleConfig.topViewHorizontalInset)
            if styleConfig.hasTopBottomBarInset {
                make.top.equalTo(topButtonGridGuide)
            } else {
                make.top.equalToSuperview().inset(2)
            }
        }

        if styleConfig.isSingleRow {
            let avatarMarginTop: CGFloat = Display.pad ? 15 : 18
            avatar.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().inset(avatarMarginTop)
                make.centerX.equalToSuperview()
                make.width.equalTo(avatar.snp.height)
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
                make.height.lessThanOrEqualToSuperview().multipliedBy(0.5)
            }
            cameraHaveNoAccessImageView.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                if Display.pad {
                    make.top.equalToSuperview().inset(21)
                    make.width.equalTo(cameraHaveNoAccessImageView.snp.height)
                    make.width.lessThanOrEqualToSuperview().multipliedBy(0.4)
                    make.height.lessThanOrEqualToSuperview().multipliedBy(0.4)
                } else {
                    make.top.equalToSuperview().inset(24)
                    make.size.equalTo(34)
                }
            }
            connectingLabel.attributedText = NSAttributedString(string: I18n.View_G_Connecting, config: .tiniestAssist, alignment: .center)
            connectingLabel.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(4)
                make.top.equalTo(avatar.snp.bottom).offset(0)
            }

            statusEmojiView.snp.remakeConstraints { make in
                make.size.equalTo(Layout.singleRowEmojiSize)
                make.left.equalToSuperview().inset(Layout.singleRowTopLeftInset)
                make.top.equalTo(topButtonGridGuide).inset(Layout.singleRowTopLeftInset - Layout.topButtonGuideInset).priority(.low)
            }
        } else {
            avatar.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(styleConfig.avatarOffset)
                make.width.equalTo(avatar.snp.height)
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
                make.height.lessThanOrEqualToSuperview().multipliedBy(0.5)
                make.width.equalToSuperview().multipliedBy(0.5).priority(.high)
                make.height.equalToSuperview().multipliedBy(0.5).priority(.high)
            }
            cameraHaveNoAccessImageView.snp.remakeConstraints { (make) in
                let sizeMultiplier = InMeetFlowComponent.isNewLayoutEnabled ? 0.38 : 0.4
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(styleConfig.cameraHaveNoAccessOffset)
                make.width.equalTo(cameraHaveNoAccessImageView.snp.height)
                make.width.lessThanOrEqualToSuperview().multipliedBy(sizeMultiplier)
                make.height.lessThanOrEqualToSuperview().multipliedBy(sizeMultiplier)
                make.width.equalToSuperview().multipliedBy(sizeMultiplier).priority(.high)
                make.height.equalToSuperview().multipliedBy(sizeMultiplier).priority(.high)
            }
            connectingLabel.attributedText = NSAttributedString(string: I18n.View_G_Connecting, config: .assist, alignment: .center)
            connectingLabel.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(4)
                make.top.equalTo(avatar.snp.bottom).offset(8)
            }
            if styleConfig.isSpeechFloat {
                statusEmojiView.snp.remakeConstraints { make in
                    make.size.equalTo(30)
                    make.top.left.equalToSuperview().inset(5)
                }
            } else {
                statusEmojiView.snp.remakeConstraints { make in
                    make.size.equalTo(emojiViewSize)
                    make.left.equalToSuperview().inset(Layout.topLeftInset)
                    make.top.equalTo(topButtonGridGuide).inset(Layout.topLeftInset - Layout.topButtonGuideInset).priority(.low)
                    make.top.greaterThanOrEqualTo(safeAreaLayoutGuide).offset(Layout.topLeftInset)
                }
            }
        }
        self.streamRenderView.renderMode = styleConfig.renderMode
        if systemCallingStatusView.isHidden == false {
            systemCallingStatusView.displayParams = styleConfig.systemCallingStatusInfoSyle
        }
        // config userInfoView
        updateUserInfoViewLayout()
        updateSwitchCameraLayout()
        userInfoView.displayParams = styleConfig.userInfoViewStyle
    }

    var isRenderingHandler: ((Bool) -> Void)?

    var isRendering: Bool {
        return streamRenderView.isRendering
    }

    private func updateLayoutGuide(styleConfig: ParticipantViewStyleConfig) {
        topButtonGridGuide.snp.remakeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalToSuperview()
            if styleConfig.hasTopBottomBarInset {
                make.top.greaterThanOrEqualToSuperview().offset(styleConfig.topBarInset + Layout.topButtonGuideInset).priority(.high)
                make.top.equalToSuperview().inset(Layout.topButtonGuideInset).priority(.low)
            } else {
                make.top.equalToSuperview().inset(Layout.topButtonGuideInset)
            }
        }
        userInfoViewBottomGuide.snp.remakeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalToSuperview()
            if styleConfig.isSingleRow {
                make.bottom.equalToSuperview().inset(Display.pad ? 2.5 : 1.5)
            } else if styleConfig.hasTopBottomBarInset {
                make.bottom.lessThanOrEqualToSuperview().offset(-styleConfig.bottomBarInset - 2).priority(.required)
                make.bottom.equalToSuperview().offset(-2).priority(.low)
            } else {
                make.bottom.equalToSuperview().inset(2.0)
            }
        }

    }

    // 圆角的填充颜色
    private let cornerColor: UIColor = UIColor.ud.bgBody

    private func configureCornerAndBorder() {
        let showBorderLines = styleConfig.showBorderLines || styleConfig.showVideoBorderLines && isRenderingRelay.value
        if styleConfig.cornerRadius == 0.0 {
            contentView.layer.cornerRadius = styleConfig.cornerRadius
            roundedMaskView.isHidden = true
        } else if offscreenOptimiseEnable {
            roundedMaskView.cornerColor = cornerColor
            roundedMaskView.cornerRadius = styleConfig.cornerRadius
            roundedMaskView.borderColor = styleConfig.borderColor
            roundedMaskView.borderWidth = showBorderLines ? styleConfig.borderWidth : 0
            contentView.layer.cornerRadius = 0
            contentView.layer.masksToBounds = true
            contentView.layer.borderWidth = showBorderLines ? styleConfig.borderWidth : 0
            roundedMaskView.isHidden = false
        } else {
            contentView.layer.cornerRadius = styleConfig.cornerRadius
            contentView.layer.ud.setBorderColor(styleConfig.borderColor)
            contentView.layer.borderWidth = showBorderLines ? styleConfig.borderWidth : 0
            contentView.layer.masksToBounds = true
            roundedMaskView.isHidden = true
        }
    }

    // 悬浮窗(回到Lark页面上的小窗)情况，因为背景是透明的不能进行圆角优化
    var offscreenOptimiseEnable: Bool = false {
        didSet {
            guard offscreenOptimiseEnable != oldValue else {
                return
            }
            configureCornerAndBorder()
        }
    }

    var layoutStyle: MeetingLayoutStyle = .tiled

    private let topButtonGridGuide: UILayoutGuide = UILayoutGuide()
    private let userInfoViewBottomGuide: UILayoutGuide = UILayoutGuide()

    deinit {
        Self.logger.debug("deinit InMeetingParticipantView")
        if let vm = cellViewModel {
            vm.meeting.syncChecker.unregisterMicrophone(self, for: syncCheckId)
            vm.meeting.syncChecker.unregisterCamera(self, for: syncCheckId)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
        bindActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    let streamRenderView = StreamRenderView()

    let isRenderingRelay = BehaviorRelay<Bool>(value: false)

    lazy var roundedMaskView: InMeetingParticipantRoundedMaskView = {
        let view = InMeetingParticipantRoundedMaskView()
        return view
    }()

    private func setupRenderView() {
        let renderView = self.streamRenderView
        contentView.insertSubview(renderView, at: 0)
        renderView.frame = self.contentView.bounds
        renderView.clipsToBounds = true
        renderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.updateRendering(renderView.isRendering)
        renderView.addListener(self)
    }

    private let topView = UIView()

    lazy var statusEmojiView: BVImageView = {
        let emoji = BVImageView()
        emoji.edgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        emoji.backgroundColor = .ud.vcTokenMeetingBgFloat.withAlphaComponent(0.7)
        emoji.layer.masksToBounds = true
        emoji.layer.cornerRadius = 6
        emoji.isHidden = true
        return emoji
    }()

    var shouldShowSwitchCamera: Bool = false
    lazy var switchCameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.cameraFlipOutlined, iconColor: .ud.primaryOnPrimaryFill,
                                            size: CGSize(width: 24.0, height: 24.0)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.cameraFlipOutlined, iconColor: .ud.primaryOnPrimaryFill.withAlphaComponent(0.5),
                                            size: CGSize(width: 24.0, height: 24.0)), for: .highlighted)
        button.ud.setLayerShadowColor(UIColor.ud.vcTokenVCShadowSm)
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.isHidden = true
        return button
    }()

    lazy var systemCallingStatusView: InMeetSystemCallingStatusView = {
        let view = InMeetSystemCallingStatusView()
        view.isHidden = true
        return view
    }()

    lazy var moreSelectionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Self.moreSelectionNormalImg, for: .normal)
        button.setImage(Self.moreSelectionHighlightImg, for: .highlighted)
        button.layer.ud.setShadowColor(UIColor.ud.staticBlack.withAlphaComponent(0.5))
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 2
        button.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        button.layer.cornerRadius = 8
        button.addInteraction(type: .hover)
        return button
    }()
    static let moreSelectionNormalImg = UDIcon.getIconByKey(.moreBoldOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 24.0, height: 24.0))
    static let moreSelectionHighlightImg = UDIcon.getIconByKey(.moreBoldOutlined, iconColor: .ud.primaryOnPrimaryFill.withAlphaComponent(0.5), size: CGSize(width: 24.0, height: 24.0))


    let cameraHaveNoAccessImageView: UIImageView = {
        let image = UDIcon.getIconByKey(.videoOffOutlined, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 144.0, height: 144.0))
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()

    let avatar = AvatarView()

    let connectingLabel: UILabel = {
        let connectingLabel = UILabel()
        connectingLabel.textColor = UIColor.ud.textCaption
        connectingLabel.numberOfLines = 2
        connectingLabel.attributedText = NSAttributedString(string: I18n.View_G_Connecting, config: .assist, alignment: .center)
        connectingLabel.textAlignment = .center
        connectingLabel.isHidden = true
        return connectingLabel
    }()

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

    let rippleView: LOTAnimationView = {
        let rippleView = LOTAnimationView(name: InMeetingParticipantView.rippleName(), bundle: .localResources)
        rippleView.loopAnimation = true
        rippleView.isHidden = true
        return rippleView
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_CancelButton, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14.0)
        let size = CGSize(width: 60, height: 28)
        button.setBackgroundImage(Self.cancelNormalImg, for: .normal)
        button.setBackgroundImage(Self.cancelHighlightImg, for: .highlighted)
        button.layer.cornerRadius = 6
        button.layer.ud.setShadow(type: .s3Down)
        button.snp.makeConstraints { (make) in
            make.size.equalTo(size)
        }
        button.isHidden = true
        button.addInteraction(type: .hover)
        return button
    }()

    static let cancelNormalImg = UIImage.vc.fromColor(UIColor.ud.vcTokenMeetingBgFloat, size: CGSize(width: 60, height: 28), cornerRadius: 4)
    static let cancelHighlightImg = UIImage.vc.fromColor(UIColor.ud.vcTokenMeetingBgFloatPressed, size: CGSize(width: 60, height: 28), cornerRadius: 4)

    let userInfoView = InMeetUserInfoView()

    var imageInfo: AvatarInfo = .asset(AvatarResources.unknown) {
        didSet {
            guard imageInfo != oldValue else {
                return
            }
            avatar.setAvatarInfo(imageInfo, size: .large)
        }
    }

    func reloadImageInfo() {
        avatar.setAvatarInfo(imageInfo, size: .large)
    }

    var showsRipple = false {
        didSet {
            if showsRipple {
                rippleView.setAnimation(named: InMeetingParticipantView.rippleName(), bundle: .localResources)
                rippleView.loopAnimation = true

                rippleView.isHidden = false
                rippleView.play()
            } else {
                rippleView.isHidden = true
                rippleView.stop()
            }
        }
    }

    static func rippleName() -> String {
        var ripple: String = ""
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            ripple = "rippleWhite"
        } else {
            ripple = "ripple"
        }
        return ripple
    }

    var isConnected: Bool = true {
        didSet {
            guard isConnected != oldValue else {
                return
            }
            updateConnectingLabelVisibility()
        }
    }

    var didTapCancelButton: ((Participant) -> Void)?
    var didTapMoreSelectionButton: ((InMeetGridCellViewModel, _ isFullscreen: Bool) -> Void)?
    var didTapUserName: ((Participant) -> Void)?

    private func setUpUI() {
        addSubview(contentView)
        addSubview(roundedMaskView)
        configureCornerAndBorder()
        #if DEBUG
        topButtonGridGuide.identifier = "topButtonGridGuide"
        userInfoViewBottomGuide.identifier = "userInfoViewBottomGuide"
        #endif
        contentView.addLayoutGuide(topButtonGridGuide)
        contentView.addLayoutGuide(userInfoViewBottomGuide)
        contentView.addSubview(rippleView)
        contentView.addSubview(connectingLabel)
        contentView.addSubview(cameraHaveNoAccessImageView)
        contentView.addSubview(avatar)
        contentView.addSubview(systemCallingStatusView)
        contentView.addSubview(userInfoView)
        setUpTopView()

        setupRenderView()

        makeConstraints()
        refreshStyle()
        updateLayoutGuide(styleConfig: self.styleConfig)
    }

    private func setUpTopView() {
        // 因为点击区域的原因不加到topView中，用topView做布局辅助
        contentView.addSubview(topView)
        contentView.addSubview(statusEmojiView)
        contentView.addSubview(switchCameraButton)
        contentView.addSubview(moreSelectionButton)
        contentView.addSubview(cancelButton)
    }

    // disable-lint: duplicated code
    private func makeConstraints() {
        topView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(6)
            make.left.right.equalToSuperview().inset(6)
            make.height.equalTo(0)
        }

        statusEmojiView.snp.makeConstraints { make in
            make.size.equalTo(emojiViewSize)
            make.left.equalToSuperview().inset(Layout.topLeftInset)
            make.top.equalTo(topButtonGridGuide).inset(Layout.topLeftInset - Layout.topButtonGuideInset).priority(.low)
            make.top.greaterThanOrEqualTo(safeAreaLayoutGuide).offset(Layout.topLeftInset)
        }

        switchCameraButton.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.left.equalTo(statusEmojiView.snp.right).offset(10)
            make.centerY.equalTo(statusEmojiView)
        }

        systemCallingStatusView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }

        moreSelectionButton.snp.makeConstraints { (make) in
            make.top.equalTo(topView)
            make.right.equalTo(topView).offset(-6.0)
            make.size.equalTo(CGSize(width: 32.0, height: 32.0))
        }
        cancelButton.snp.makeConstraints { (make) in
            make.top.equalTo(topView).offset(2)
            make.right.equalTo(topView).offset(-2)
        }
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        userInfoView.snp.makeConstraints { (make) in
            let inset = 2.0
            make.bottom.left.equalToSuperview().inset(inset)
            make.right.lessThanOrEqualToSuperview().inset(inset)
        }
        rippleView.snp.makeConstraints { (make) in
            make.center.equalTo(avatar)
            make.width.equalTo(avatar.snp.width).offset(28.0)
            make.height.equalTo(avatar.snp.height).offset(28.0)
        }
        cameraHaveNoAccessImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(cameraHaveNoAccessImageView.snp.height)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.4)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.4)
        }
        avatar.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(styleConfig.avatarOffset)
            make.width.equalTo(avatar.snp.height)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.5)
        }
        connectingLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(4)
            make.top.equalTo(avatar.snp.bottom).offset(8.0)
        }
        roundedMaskView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    // enable-lint: duplicated code

    private func bindActions() {
        moreSelectionButton.rx.action = moreSelectionAction
        cancelButton.rx.action = cancelInvitationAction
    }

    private func updateStatusEmojiConstrains() {
        let padding: CGFloat = emojiViewSize >= 44 ? 5 : 3
        statusEmojiView.edgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        statusEmojiView.snp.updateConstraints { make in
            make.size.equalTo(emojiViewSize)
        }
    }

    private func updateConnectingLabelVisibility() {
        connectingLabel.isHidden = avatar.isHidden || isConnected
    }

    func updateSystemCallingInfo(mobileCallingStatus: ParticipantSettings.MobileCallingStatus?) {
        if let isMe = cellViewModel?.isMe, !isMe, mobileCallingStatus == .busy {
            systemCallingStatusView.isHidden = false
            systemCallingStatusView.displayParams = styleConfig.systemCallingStatusInfoSyle
        } else {
            systemCallingStatusView.isHidden = true
        }
    }

    func updateStatusEmojiInfo(statusEmojiInfo: ParticipantSettings.ConditionEmojiInfo?) {
        var image: UIImage?
        if statusEmojiInfo?.isHandsUp ?? false {
            image = EmojiResources.getEmojiSkin(by: statusEmojiInfo?.handsUpEmojiKey)
        } else if statusEmojiInfo?.isStepUp ?? false {
            image = EmojiResources.emoji_quickleave
        }
        if image != nil {
            statusEmojiView.isHidden = false
            statusEmojiView.image = image
        } else {
            statusEmojiView.isHidden = true
            statusEmojiView.image = nil
        }
        updateSwitchCameraLayout()
    }

    func updateSwitchCameraLayout() {
        let leftInset = styleConfig.isSingleRow ? 10 : 14
        switchCameraButton.snp.remakeConstraints { make in
            make.size.equalTo(24)
            if statusEmojiView.isHidden {
                make.left.equalToSuperview().inset(leftInset)
                if moreSelectionButton.superview != nil {
                    make.centerY.equalTo(moreSelectionButton)
                } else {
                    make.top.equalToSuperview().inset(10)
                }
            } else {
                make.left.equalTo(statusEmojiView.snp.right).offset(styleConfig.isSingleRow ? 2 : 10)
                make.centerY.equalTo(statusEmojiView)
            }
        }
    }

    func insertSketchView(_ view: UIView?) {
        guard streamRenderView.superview != nil, let view = view else { return }
        contentView.insertSubview(view, aboveSubview: streamRenderView)
        view.snp.makeConstraints { make in
            make.edges.equalTo(streamRenderView.videoContentLayoutGuide)
        }
    }

    func updateLayoutWith(style: MeetingLayoutStyle) {
        guard self.layoutStyle != style else {
            return
        }
        self.layoutStyle = style
    }

    func updateUserInfoViewLayout() {
        // config userInfoView
        let inset: CGFloat
        if styleConfig.isSingleRow {
            inset = Display.pad ? 2.5 : 1.5
        } else {
            inset = 2.0
        }
        userInfoView.externalRightInset = inset
        userInfoView.snp.remakeConstraints {
            $0.left.equalToSuperview().offset(inset)
            $0.right.lessThanOrEqualToSuperview().offset(-inset)
            $0.bottom.equalTo(userInfoViewBottomGuide)
        }
    }
}

extension InMeetingParticipantView: StreamRenderViewListener {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        self.updateRendering(isRendering)
    }

    private func updateRendering(_ isRendering: Bool) {
        self.isRenderingRelay.accept(isRendering)
        self.isRenderingHandler?(isRendering)
        if styleConfig.showVideoBorderLines {
            self.configureCornerAndBorder()
        }
    }
}

extension InMeetingParticipantView {
    var moreSelectionAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            Self.logger.info("did tap moreSelection")
            if let didTapMoreSelectionButton = self.didTapMoreSelectionButton,
               let cellVM = self.cellViewModel {
                ParticipantTracks.trackParticipantAction(.participantMore,
                                                         isFromGridView: true,
                                                         isSharing: self.cellViewModel?.meeting.shareData.isSharingContent ?? false)
                didTapMoreSelectionButton(cellVM, false)
            }
            return .empty()
        })
    }

    var switchCameraAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.info("did tap switchCamera")
            self?.cellViewModel?.meeting.camera.switchCamera()
            return .empty()
        })
    }

    var cancelInvitationAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            Self.logger.info("did tap cancelInviteAction")
            if let didTapCancelButton = self.didTapCancelButton,
               let participant = self.cellViewModel?.participant.value {
                didTapCancelButton(participant)
            }
            return .empty()
        })
    }
}


extension InMeetingParticipantView: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .containerLayoutStyle, let style = userInfo as? MeetingLayoutStyle {
            self.updateLayoutWith(style: style)
        }
    }
}
