//
//  InMeetUserInfoView.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/9/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUDColor
import UniverseDesignColor
import ByteViewNetwork

/// 会中名牌
/// - 显示规则：([身份左边距] + [身份（主持人/联席主持人）] + [身份右边距]) + [用户信息左边距] + ([共享icon] + [图文间隔]) + ([麦克风icon] + [图文间隔]) + [用户信息] + [用户信息右边距]
class InMeetUserInfoView: UIView {

    private struct Layout {
        static let iconAndLabelSpacing: CGFloat = 2.0
        static let borderLineWidth: CGFloat = 0.5
        static let defaultIconSideLength: CGFloat = 16.0
        static let defaultFontSize: CGFloat = 12.0
        static let fillScreenRightOffset: CGFloat = 4.0
        static let userInfoLabelMinWidth: CGFloat = 11.0
    }

    private static let truncateName = "\u{2026}" // …
    private var displayText = ""

    /// 显示用户身份
    private var isHostTagDisplay: Bool {
        components.contains(.identity)
    }

    private(set) var components: UserInfoComponents = .all

    var displayParams: UserInfoDisplayStyle = .inMeetingGrid {
        didSet {
            guard oldValue != displayParams else {
                return
            }
            updateUI()
            setNeedsLayout()
        }
    }

    var didTapUserName: (() -> Void)?
    var tapGestureRecognizer: UITapGestureRecognizer?
    private(set) var isMicMuted = false

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = Layout.iconAndLabelSpacing
        return stackView
    }()

    private lazy var identityBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.vcTokenMeetingBgHostTag
        view.layer.addSublayer(identityBorderLayer)
        identityBorderLayer.ud.setFillColor(UIColor.clear)
        identityBorderLayer.ud.setStrokeColor(UIColor.ud.vcTokenMeetingLineHostTag)
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    static var hostImg = UDIcon.getIconByKey(.memberFilled,
                                             iconColor: .ud.primaryOnPrimaryFill,
                                             size: CGSize(width: Layout.defaultIconSideLength, height: Layout.defaultIconSideLength))
    private lazy var identityImageView: UIImageView = {
        let imgView = UIImageView.init(image: InMeetUserInfoView.hostImg)
        imgView.contentMode = .scaleAspectFit
        imgView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imgView.setContentCompressionResistancePriority(.required, for: .vertical)
        imgView.isUserInteractionEnabled = false
        return imgView
    }()

    /// 会议身份（主持人）底部视图边框
    private lazy var identityBorderLayer: CAShapeLayer = {
        let iLayer = CAShapeLayer()
        iLayer.lineWidth = Layout.borderLineWidth
        return iLayer
    }()

    private lazy var userInfoBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00.withAlphaComponent(0.8)
        view.layer.addSublayer(userInfoBorderLayer)
        userInfoBorderLayer.ud.setFillColor(UIColor.clear)
        userInfoBorderLayer.ud.setStrokeColor(UIColor.ud.lineDividerDefault)
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    /// 会议信息底部视图边框
    private lazy var userInfoBorderLayer: CAShapeLayer = {
        let uLayer = CAShapeLayer()
        uLayer.lineWidth = Layout.borderLineWidth
        return uLayer
    }()

    private let userInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Layout.defaultFontSize)
        label.textColor = UIColor.ud.textTitle
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        label.isUserInteractionEnabled = false
        return label
    }()

    private let micImageView: UIImageView = {
        let imageView = UIImageView(image: InMeetUserInfoView.micImg)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    static var micImg = UDIcon.getIconByKey(.micOffFilled,
                                            iconColor: UDColor.functionDangerFillDefault,
                                            size: CGSize(width: Layout.defaultIconSideLength, height: Layout.defaultIconSideLength))

    private let localRecordImageView: UIImageView = {
        let imageView = UIImageView(image: InMeetUserInfoView.localRecordImg)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    static var localRecordImg = UDIcon.getIconByKey(.recordingColorful,
                                                    iconColor: .ud.functionDangerFillDefault,
                                                    size: CGSize(width: Layout.defaultIconSideLength, height: Layout.defaultIconSideLength))

    private let sharingImageView: UIImageView = {
        let imageView = UIImageView(image: InMeetUserInfoView.sharingImg)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    static var sharingImg = UDIcon.getIconByKey(.shareScreenFilled,
                                                iconColor: .ud.functionSuccessFillDefault,
                                                size: CGSize(width: Layout.defaultIconSideLength, height: Layout.defaultIconSideLength))

    static var focusImg = UDIcon.getIconByKey(.focusFilled,
                                              iconColor: .ud.N650,
                                              size: CGSize(width: Layout.defaultIconSideLength, height: Layout.defaultIconSideLength))
    /// 焦点视频
    private let focusImgView: UIImageView = {
        let imageView = UIImageView(image: InMeetUserInfoView.focusImg)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    /// 弱网提示视图
    private let weakNetworkImageView: UIImageView = {
        var imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.isUserInteractionEnabled = false
        // imageView.isHidden = true
        return imageView
    }()

    // 名牌在 superview 中右侧偏移量，
    // 用于计算名牌是否通栏 (名牌通栏时需要异化右边圆角)
    var externalRightInset: CGFloat?

    // 是否可以异化左下圆角
    var canSpecilizeBottomLeftRadius = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // add views
        addSubview(identityBackgroundView)
        addSubview(userInfoBackgroundView)
        addSubview(contentStackView)
        // layout
        updateUI()
    }

    private func setupTapGesture() {
        contentStackView.isUserInteractionEnabled = true
        let tapGr = UITapGestureRecognizer(target: self, action: #selector(tapUserInfo))
        contentStackView.addGestureRecognizer(tapGr)
    }

    @objc
    func tapUserInfo() {
        didTapUserName?()
    }

    // disable-lint: long function
    private func refreshAllConstraints() {
        self.contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if components.contains(.identity) {
            contentStackView.addArrangedSubview(identityImageView)
        }
        if components.contains(.mic) {
            contentStackView.addArrangedSubview(micImageView)
        }
        if components.contains(.localRecord) {
            contentStackView.addArrangedSubview(localRecordImageView)
        }
        if components.contains(.sharing) {
            contentStackView.addArrangedSubview(sharingImageView)
        }
        if components.contains(.focus) {
            contentStackView.addArrangedSubview(focusImgView)
        }
        if components.contains(.name) {
            contentStackView.addArrangedSubview(userInfoLabel)
        }
        if components.contains(.weakNetwork) {
            contentStackView.addArrangedSubview(weakNetworkImageView)
        }

        let style = displayParams
        // defines
        let fontSize = style.params.fontSize
        let iconSideLength = style.params.iconSideLength
        let idLeftOffset = style.params.identityLeftOffset
        let idRightOffset = style.params.identityRightOffset
        let uiLeftOffset = style.params.userInfoLeftOffset
        let uiRightOffset = (style.isFillScreen && !isHostTagDisplay) ? Layout.fillScreenRightOffset : style.params.userInfoRightOffset
        let fullHeight = style.params.fullHeight
        _ = style.params.identityMaxWidth
        let isLeftLayout = style.layoutStyle == .left
        // configs
        userInfoLabel.font = UIFont.systemFont(ofSize: fontSize)
        contentStackView.setCustomSpacing(isHostTagDisplay ? (idRightOffset + uiLeftOffset) : uiLeftOffset, after: identityImageView)
        // constraints
        if isLeftLayout {
            contentStackView.snp.remakeConstraints {
                $0.left.equalToSuperview().inset(isHostTagDisplay ? idLeftOffset : uiLeftOffset)
                $0.right.equalToSuperview().inset(uiRightOffset)
                $0.top.greaterThanOrEqualToSuperview()
                $0.bottom.equalToSuperview()
                $0.height.equalTo(fullHeight)
            }
        } else {
            contentStackView.snp.remakeConstraints {
                $0.left.greaterThanOrEqualToSuperview().inset(isHostTagDisplay ? idLeftOffset : uiLeftOffset)
                $0.right.lessThanOrEqualToSuperview().inset(uiRightOffset)
                $0.top.bottom.equalToSuperview()
                $0.height.equalTo(fullHeight)
                $0.centerX.equalToSuperview()
            }
        }

        if components.contains(.identity) {
        identityImageView.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            // 固定宽度
            $0.width.height.equalTo(iconSideLength)
        }

        identityBackgroundView.snp.remakeConstraints {
            $0.left.equalTo(identityImageView).inset(-idLeftOffset)
            $0.right.equalTo(identityImageView).inset(-idRightOffset)
            $0.centerY.equalTo(identityImageView)
            $0.height.equalTo(fullHeight)
        }
        }

        if components.contains(.mic) {
            micImageView.snp.remakeConstraints {
                $0.width.height.equalTo(iconSideLength)
            }
        }

        if components.contains(.localRecord) {
            localRecordImageView.snp.remakeConstraints {
                $0.width.height.equalTo(iconSideLength)
            }
        }

        if components.contains(.sharing) {
            sharingImageView.snp.remakeConstraints {
                $0.width.height.equalTo(iconSideLength)
            }
        }
        if components.contains(.focus) {
        focusImgView.snp.remakeConstraints {
            $0.width.height.equalTo(iconSideLength)
        }
        }
        if components.contains(.weakNetwork) {
        weakNetworkImageView.snp.remakeConstraints {
            $0.width.height.equalTo(iconSideLength)
        }
        }

        if components.contains(.name) {
            userInfoLabel.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.height.equalTo(fullHeight)
                $0.width.greaterThanOrEqualTo(Layout.userInfoLabelMinWidth)
            }
        }
        userInfoBackgroundView.snp.remakeConstraints {
            if components.contains(.mic) {
                $0.left.equalTo(micImageView).inset(-uiLeftOffset)
            } else if components.contains(.localRecord) {
                $0.left.equalTo(localRecordImageView).inset(-uiLeftOffset)
            } else if components.contains(.sharing) {
                $0.left.equalTo(sharingImageView).inset(-uiLeftOffset)
            } else if components.contains(.focus) {
                $0.left.equalTo(focusImgView).inset(-uiLeftOffset)
            } else if components.contains(.name) {
                $0.left.equalTo(userInfoLabel).inset(-uiLeftOffset)
            }
            if components.contains(.weakNetwork) {
                $0.right.equalTo(weakNetworkImageView).inset(-uiRightOffset)
            } else if components.contains(.name) {
                $0.right.equalTo(userInfoLabel).inset(-uiRightOffset)
            }

            if components.contains(.name) {
                $0.centerY.equalTo(userInfoLabel)
            }
            $0.height.equalTo(fullHeight)
        }

        dealUserLabelTruncate()
    }
    // enable-lint: long function

    private func remakeInfoLabelConstraints() {
        let style = displayParams
        // defines
        let isLeftLayout = style.layoutStyle == .left
        let idLeftOffset = style.params.identityLeftOffset
        let uiLeftOffset = style.params.userInfoLeftOffset
        let uiRightOffset = (style.isFillScreen && !isHostTagDisplay) ? Layout.fillScreenRightOffset : style.params.userInfoRightOffset
        let fullHeight = style.params.fullHeight
        // constraints
        if isLeftLayout {
            contentStackView.snp.remakeConstraints {
                $0.left.equalToSuperview().inset(isHostTagDisplay ? idLeftOffset : uiLeftOffset)
                $0.right.equalToSuperview().inset(uiRightOffset)
                $0.bottom.equalToSuperview()
                $0.height.equalTo(fullHeight)
            }
        } else {
            contentStackView.snp.remakeConstraints {
                $0.left.greaterThanOrEqualToSuperview().inset(isHostTagDisplay ? idLeftOffset : uiLeftOffset)
                $0.right.lessThanOrEqualToSuperview().inset(uiRightOffset)
                $0.top.bottom.equalToSuperview()
                $0.height.equalTo(fullHeight)
                $0.centerX.equalToSuperview()
            }
        }

        dealUserLabelTruncate()
    }

    /// userInfoLabel 在多个 icon（身份+麦克风+共享+焦点） 都展示的情况下，姓名展示截断会出现中文显示一个汉字，不符合预期。
    /// UX 和 PM 最终选定方案是在 iPhone 上 singleRow 视图下，身份+麦克风+共享+焦点都展示的情况下，默认显示 `…`
    private func dealUserLabelTruncate() {
        let style = displayParams
        let tooManyIcon = components.contains([.identity, .mic, .sharing, .focus, .localRecord])
        if style == .singleRow && Display.phone && tooManyIcon {
            userInfoLabel.text = InMeetUserInfoView.truncateName
        } else if let attrText = self.userInfoStatus.attributedName {
            userInfoLabel.attributedText = attrText
        } else {
            userInfoLabel.text = displayText
        }
    }

    static var micRestrictedImg = UDIcon.getIconByKey(.micOffFilled, iconColor: UIColor.ud.N400, size: CGSize(width: 16.0, height: 16.0))
    static var micMutedImg = UDIcon.getIconByKey(.micOffFilled, iconColor: .ud.functionDangerContentDefault, size: CGSize(width: 16.0, height: 16.0))
    static var micNoConnectImg = UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: .ud.iconN2, size: CGSize(width: 16.0, height: 16.0))

    var userInfoStatus: ParticipantUserInfoStatus = .init(hasRoleTag: false, meetingRole: .participant, isSharing: false, isFocusing: false, isMute: true, isLarkGuest: false, name: "", isRinging: false, isMe: false, rtcNetworkStatus: nil, audioMode: .unknown, is1v1: false, meetingSource: nil, isRoomConnected: false, isLocalRecord: false) {
        didSet {
            guard self.userInfoStatus != oldValue else {
                return
            }
            updateUI()
        }
    }
    private func updateUI() {
        let status = self.userInfoStatus
        let isSharingContent = status.isSharing
        let isLocalRecord = status.isLocalRecord
        var components = UserInfoComponents.all

        switch status.audioMode {
        case .noConnect:
            isMicMuted = true
            if status.isMe, !status.isRoomConnected {
                micImageView.image = Self.micNoConnectImg
            } else {
                micImageView.image = Self.micMutedImg
            }
        case .internet, .unknown, .pstn:
            if status.isMe && !Privacy.micAccess.value.isAuthorized {
                isMicMuted = true
                micImageView.image = Self.micRestrictedImg
            } else if status.isMute {
                isMicMuted = true
                micImageView.image = Self.micMutedImg
            } else {
                isMicMuted = false
                components.remove(.mic)
            }
        }


        // update text and hidden
        if status.hasRoleTag, let bgColor = status.meetingRole.displayBgColor {
            identityBackgroundView.isHidden = false
            identityBackgroundView.backgroundColor = bgColor
        } else {
            identityBackgroundView.isHidden = true
            components.remove(.identity)
        }
        if !isSharingContent {
            components.remove(.sharing)
        }

        if !isLocalRecord {
            components.remove(.localRecord)
        }
        if !status.isFocusing {
            components.remove(.focus)
        }
        if let networkImage = status.rtcNetworkStatus?.networkIcon(is1V1: status.is1v1),
           status.audioMode != .pstn && networkImage.1 {
            weakNetworkImageView.image = networkImage.0
        } else {
            components.remove(.weakNetwork)
        }

        var displayText: String = status.name
        if self.displayParams.components.contains(.nameDesc) {
            if status.isMe {
                displayText.append(I18n.View_M_MeParentheses)
            } else if status.isLarkGuest {
                displayText.append(status.meetingSource == .vcFromInterview ? I18n.View_G_CandidateBracket : I18n.View_M_GuestParentheses)
            }
            if status.isRinging {
                displayText.append(I18n.View_M_CallingParentheses)
            }
        }
        self.displayText = displayText
        if let attrText = self.userInfoStatus.attributedName {
            userInfoLabel.attributedText = attrText
        } else {
            userInfoLabel.text = displayText
        }

        components = components.intersection(self.displayParams.components)
        self.components = components

        refreshAllConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // defines
        let _: CGRect = contentStackView.frame
        let identityBgBounds: CGRect = identityBackgroundView.isHidden ? .zero : identityBackgroundView.bounds
        let userInfoBgBounds: CGRect = userInfoBackgroundView.isHidden ? .zero : userInfoBackgroundView.bounds
        // config appearance
        configBgAndCornerAppearance(identityBgBounds: identityBgBounds,
                                    userInfoBgBounds: userInfoBgBounds)
        dealUserLabelTruncate()
    }
}

/// 画圆角相关
extension InMeetUserInfoView {

    /// 设置底色的圆角和边缘
    /// - Parameters:
    ///   - identityBgBounds: 用户身份
    ///   - userInfoBgBounds: 用户信息
    private func configBgAndCornerAppearance(identityBgBounds: CGRect, userInfoBgBounds: CGRect) {
        let style = displayParams
        let isSingle: Bool = displayParams.isMobileLandscapeSingle
        let isLeftStyle: Bool = style.layoutStyle == .left
        let commonCornerRadius = style.params.cornerRadius
        let isLandscapeGrid: Bool = isLandscape && style == .inMeetingGrid && isSingle // 单人横屏宫格流，不特化圆角
        let specializedCornerRadius = isLandscapeGrid ? commonCornerRadius : style.params.specializedCornerRadius
        var rightCornerIsSpecialized: Bool = false
        if isLeftStyle,
           let superviewWidth = self.superview?.bounds.width,
           let externalRightInset = self.externalRightInset {
            rightCornerIsSpecialized = superviewWidth - externalRightInset - self.frame.maxX < 1.0
        }
        if isHostTagDisplay {
            configAppearanceOnStyle(.identity,
                                    bounds: identityBgBounds,
                                    topLeft: commonCornerRadius,
                                    topRight: 0,
                                    bottomLeft: isLeftStyle && canSpecilizeBottomLeftRadius ? specializedCornerRadius : commonCornerRadius,
                                    bottomRight: 0)
            configAppearanceOnStyle(.userInfo,
                                    bounds: userInfoBgBounds,
                                    topLeft: 0,
                                    topRight: commonCornerRadius,
                                    bottomLeft: 0,
                                    bottomRight: rightCornerIsSpecialized ? specializedCornerRadius : commonCornerRadius)
        } else {
            configAppearanceOnStyle(.userInfo,
                                    bounds: userInfoBgBounds,
                                    topLeft: commonCornerRadius,
                                    topRight: commonCornerRadius,
                                    bottomLeft: isLeftStyle && canSpecilizeBottomLeftRadius ? specializedCornerRadius : commonCornerRadius,
                                    bottomRight: rightCornerIsSpecialized ? specializedCornerRadius : commonCornerRadius)
        }
    }

    private func configAppearanceOnStyle(_ style: BgStyle, bounds: CGRect, topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) {
        let path = CGPath.createSpecializedCornerRadiusPath(bounds: bounds,
                                                            topLeft: topLeft,
                                                            topRight: topRight,
                                                            bottomLeft: bottomLeft,
                                                            bottomRight: bottomRight)
        setAppearance(style: style, path: path)
    }

    private func setAppearance(style: BgStyle, path: CGPath) {
        let bgView: UIView
        let borderLayer: CAShapeLayer
        switch style {
        case .identity:
            bgView = identityBackgroundView
            borderLayer = identityBorderLayer
        case .userInfo:
            bgView = userInfoBackgroundView
            borderLayer = userInfoBorderLayer
        }
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = bgView.bounds
        shapeLayer.path = path
        bgView.layer.mask = shapeLayer
        borderLayer.path = path
    }

}

// https://stackoverflow.com/questions/43831695/stackview-ishidden-attribute-not-updating-as-expected
extension UIView {
    var isHiddenInStackView: Bool {
        get {
            return isHidden
        }
        set {
            if isHidden != newValue {
                isHidden = newValue
            }
        }
    }
}

private extension Participant.MeetingRole {
    var displayBgColor: UIColor? {
        switch self {
        case .host:
            return UIColor.ud.vcTokenMeetingBgHost
        case .coHost:
            return UIColor.ud.vcTokenMeetingBgCohost
        default:
            return nil
        }
    }
}
