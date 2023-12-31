//
//  InMeetNavigationBar.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/21.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import ByteViewTracker
import ByteViewUI

protocol InMeetNavigationBarDelegate: AnyObject {
    func navigationBarDidClickBack()
    func navigationBarDidClickHangup(sender: UIButton)
    func navigationBarDidClickMeetingTitle(sender: UIButton)
    func navigationBarDidClickSwitchMeetingScene(sender: UIButton)
    func navigationBarDidClickOpenScene()
    func navigationBarDidClickCloseScene()
    func navigationBarDidClickJoinRoom(_ sender: UIButton)
    func navigationBarDidClickStatusView(_ statusView: UIView)
    func navigationBarDidClickCountDown()
    func navigationBarDidClickMoreButton(sender: UIButton)
    func navigationBarDidChangeCompactMode(currentMoreItemShow: Bool)
}

enum InMeetTopBarHangupType {
    // 结束会议、退出会议
    case hangup
    // 离开分组
    case leave
}

class InMeetNavigationBar: UIView {
    // MARK: - Input

    private let hasSwitchSceneEntrance: Bool
    private var isJoinRoomEnabled: Bool { viewModel.isJoinRoomEnabled }
    private var isMyAIEnabled: Bool { viewModel.myAIViewModel.isEnabled }
    private var isJoinRoomHidden: Bool = false
    private var statuses: [InMeetStatusThumbnailItem] = []

    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            if oldValue != meetingLayoutStyle {
                updateBackgroundColor()
                adaptShadowConfig()
            }
        }
    }

    var isOverlay: Bool {
        meetingLayoutStyle == .overlay
    }

    var isOverlayOrFullScreen: Bool {
        meetingLayoutStyle.isOverlayFullScreen
    }

    var sceneMode: InMeetSceneManager.SceneMode = .gallery {
        didSet {
            if oldValue != sceneMode {
                updateBackgroundColor()
                adaptShadowConfig()
            }
        }
    }

    var isSingleRow = false {
        didSet {
            if oldValue != isSingleRow {
                updateBackgroundColor()
            }
        }
    }

    var isFlowShrunken = false {
        didSet {
            if oldValue != isFlowShrunken {
                updateBackgroundColor()
            }
        }
    }

    var selfWidth: CGFloat {
        VCScene.bounds.width
    }

    // MARK: - Output

    static let contentHeight: CGFloat = 44

    weak var delegate: InMeetNavigationBarDelegate?
    let barContentGuide = UILayoutGuide()
    let middleLayoutGuide = UILayoutGuide()

    let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    let remainingTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.udtokenTagNeutralTextNormal
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.attributedText = .init(string: "", config: .tiniestAssist, lineBreakMode: .byTruncatingTail)
        return label
    }()

    private(set) lazy var padSwitchSceneButton: PadSwitchSceneButton = {
        let button = PadSwitchSceneButton(type: .custom)
        button.isExclusiveTouch = true
        button.addInteraction(type: .highlight)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(handleSwitchSceneClick(_:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var joinRoomButton: JoinRoomPopoverButton = {
        let button = JoinRoomPopoverButton()
        button.isInNavigation = true
        button.addTarget(self, action: #selector(didJoinRoom(_:)), for: .touchUpInside)
        return button
    }()

    // 手机竖屏及ipad compact模式下的more
    private lazy var badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.colorfulRed
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private(set) lazy var moreView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear

        view.addSubview(moreButton)
        view.addSubview(badgeView)

        moreButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 28, height: 28))
        }

        badgeView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 6, height: 6))
            make.top.equalTo(moreButton.snp.top).offset(-1)
            make.right.equalTo(moreButton.snp.right).offset(1)
        }
        view.isHiddenInStackView = true
        return view
    }()

    private(set) lazy var moreButton: UIButton = {
        let button = createButton(icon: .moreOutlined)
        button.addTarget(self, action: #selector(didClickMore(_:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var myAIButton: MyAIPadButton = {
        let button = MyAIPadButton()
        button.addTarget(self, action: #selector(didClickMyAI), for: .touchUpInside)
        return button
    }()

    private(set) lazy var statusView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.spacing = 10
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleStatusClick))
        view.addGestureRecognizer(tap)
        return view
    }()

    // MARK: - Private

    private static let arrowDownImage = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 10, height: 10))
    private static let arrowUpImage = UDIcon.getIconByKey(.expandUpFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 10, height: 10))
    private static let e2EeImage = UDIcon.getIconByKey(.vcEncryptionFilled, iconColor: UIColor.ud.functionSuccessFillDefault, size: CGSize(width: 18, height: 18))
    private static let highlightMoreButtonBgImg = UIImage.vc.fromColor(UIColor.ud.udtokenBtnTextBgNeutralHover)

    // 用于控制外部，彩排，标题三个label的最小宽度
    private var minTitleWidthConstraint: Constraint?
    private var minExternalWidthConstraint: Constraint?
    private var minRehearsalWidthConstraint: Constraint?

    // 记录三个标签原始宽度
    private var titleIntrinsicContentWidth: CGFloat = 0
    private var externalIntrinsicContentWidth: CGFloat = 0
    private var rehearsalIntrinsicContentWidth: CGFloat = 0

    // ipad右边的item是否可以被收纳
    private var isFoldEnabled: Bool = false
    // 状态栏宽度，缓存一下，避免重复计算
    private var statusViewWidth: CGFloat = 0

    private let minTitleWidth: CGFloat = 36.0
    private let minExternalWidth: CGFloat = 44.0
    private let minRehearsalWidth: CGFloat = 44.0
    private let arrowWidth: CGFloat = 10.0
    private let e2EeViewWidth: CGFloat = 18.0
    private let portraitHangUpWidth: CGFloat = 50.0
    private let landscapeHangUpWidth: CGFloat = 54.0
    private var shouldShowShadow: Bool = false {
        didSet {
            guard shouldShowShadow != oldValue else { return }
            if self.shouldShowShadow {
                self.vc.addOverlayShadow(isTop: true)
            } else {
                self.vc.removeOverlayShadow()
            }
        }
    }

    var shareScene: InMeetShareScene? {
        didSet {
            if oldValue != shareScene {
                adaptShadowConfig()
            }
        }
    }

    // 是否处于MS状态，用于更新阴影
    var isInMs: Bool {
        shareScene?.isMagicShare ?? false
    }

    // 是否处于共享状态，用于更新阴影
    var isNoSharingContent: Bool {
        shareScene?.isNone ?? false
    }

    var isOtherSharingScreenOrWhiteboard: Bool {
        if let scene = shareScene {
            return scene.isOthersSharingScreen || scene.isWhiteboard
        }
        return false
    }

    var gridVisibleRange: GridVisibleRange? {
        didSet {
            adaptShadowConfig()
        }
    }

    // 是否把rightItems收纳进more中，并将事件代理出去（主要是用于更新sourceView）
    var isMoreItemShowInCompact: Bool = false {
        didSet {
            guard isMoreItemShowInCompact != oldValue else { return }
            delegate?.navigationBarDidChangeCompactMode(currentMoreItemShow: isMoreItemShowInCompact)
        }
    }

    // ipad R模式下导航栏所处的状态，C模式和手机规则保持一致
    private var currentCompressMode: CompressMode = .left {
        didSet {
            setCompressModeForLayout()
        }
    }

    var isShowSpeakerOnMainScreen: Bool = false {
        didSet {
            guard oldValue != self.isShowSpeakerOnMainScreen else {
                return
            }
            adaptShadowConfig()
        }
    }

    private enum CompressMode {
        case left // 左对齐
        case compressLayoutButton // 两边内容居中并压缩switchScene的文字和竖线（如有的话）
        case rightIsMore // 内容居中，并将右侧功能收进more中
    }

    private let contentView = UIView()

    private lazy var backButton: UIButton = {
        let button = createButton(icon: .leftOutlined)
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()
    private lazy var openSceneButton: UIButton = {
        let button = createButton(icon: .sepwindowOutlined)
        button.addTarget(self, action: #selector(handleOpenScene), for: .touchUpInside)
        return button
    }()

    private let leftView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    private let middleView = UIView()
    private let rightView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 0
        return stackView
    }()

    private let hangupClickView = UIView()
    private lazy var hangupButton: VisualButton = {
        let button = VisualButton()
        button.isExclusiveTouch = true
        button.extendEdge = UIEdgeInsets(top: -26, left: -26, bottom: -26, right: -26)
        button.addTarget(self, action: #selector(handleHangup(_:)), for: .touchUpInside)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        return button
    }()

    private lazy var titleButton: TitleButton = {
        let button = TitleButton()
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setTitleColor(UIColor.ud.textPlaceholder, for: .highlighted)
        button.addTarget(self, action: #selector(handleTitleClick(_:)), for: .touchUpInside)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        return button
    }()

    private lazy var arrowView = UIImageView(image: Self.arrowDownImage)

    private lazy var e2EeView = UIImageView(image: Self.e2EeImage)

    private lazy var rehearsalView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.udtokenTagBgYellowSolid
        view.layer.cornerRadius = 4.0
        view.clipsToBounds = true
        view.addSubview(rehearsalLabel)
        rehearsalLabel.snp.remakeConstraints { make in
            make.bottom.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(4.0)
        }
        return view
    }()

    private let rehearsalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = UIColor.ud.udtokenTagTextSYellow
        label.backgroundColor = UIColor.clear
        label.attributedText = NSAttributedString(string: I18n.View_G_Rehearsing, config: .assist)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let externalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.clear
        label.setContentCompressionResistancePriority(.defaultLow + 1, for: .horizontal)
        label.text = I18n.View_G_ExternalLabel
        return label
    }()

    private lazy var externalView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.udtokenTagBgBlue
        view.layer.cornerRadius = 4.0
        view.clipsToBounds = true

        view.addSubview(externalLabel)
        externalLabel.snp.remakeConstraints { make in
            make.bottom.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(4.0)
        }
        return view
    }()

    private let titleContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        return stackView
    }()

    private lazy var statusContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleStatusContainerClick))
        stackView.addGestureRecognizer(tap)
        return stackView
    }()

    let remainingTimeView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.udtokenTagNeutralTextNormal.withAlphaComponent(0.1)
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()

    private let networkStatusImage = UIImageView()

    private(set) var toolbarItemViews: [NavigationBarItemView] = []
    lazy var toolBarStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        return stackView
    }()

    private var statusThumbnailViewMap: [InMeetStatusType: InMeetNavigationBarStatusThumbnailView] = [:]

    private lazy var countDownTag: CountDownTagView = {
        let tag = CountDownTagView(scene: .inTopBar)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCountDown))
        tag.addGestureRecognizer(tap)
        return tag
    }()

    private lazy var durationLine = newLine()
    private lazy var statusLine = newLine()
    private lazy var switchSceneLine = getSwitchSceneLine()
    private let viewModel: InMeetTopBarViewModel

    // MARK: - Initialize

    init(viewModel: InMeetTopBarViewModel, hasSwitchSceneEntrance: Bool) {
        self.viewModel = viewModel
        self.hasSwitchSceneEntrance = hasSwitchSceneEntrance
        super.init(frame: .zero)
        viewModel.myAIViewModel.addListener(self)
        setupSubviews()
        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func updateBackgroundColor() {
        if isOverlayOrFullScreen {
            self.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.92)
        } else {
            self.backgroundColor = UIColor.ud.bgBody
        }
    }

    func updateLayout() {
        leftView.snp.remakeConstraints { make in
            if Display.iPhoneXSeries && isLandscape {
                make.left.equalTo(44)
            } else {
                make.left.equalTo(16)
            }
            make.centerY.equalToSuperview()
        }
        rightView.snp.remakeConstraints { make in
            if Display.iPhoneXSeries && isLandscape {
                make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(15)
            } else if Display.pad {
                make.right.equalToSuperview().inset(6)
            } else {
                make.right.equalToSuperview().inset(4)
            }
            make.centerY.equalToSuperview()
        }
        networkStatusImage.snp.remakeConstraints { make in
            make.size.equalTo(VCScene.isRegular ? 16 : 12)
        }

        if VCScene.isRegular {
            statusContainerView.spacing = 10
        } else {
            statusContainerView.spacing = 6
        }

        hangupClickView.snp.remakeConstraints { make in
            make.width.equalTo(isLandscape ? landscapeHangUpWidth : portraitHangUpWidth)
            make.height.equalTo(44)
        }

        // 手机和ipad c模式，title 都靠左边对齐，ipad R模式存在全局居中和middleView居中
        if Display.phone || !VCScene.isRegular {
            updateLayoutForUnRegularMode()
        } else {
            updateLayoutForReguarMode()
        }
        // 默认先走全局居中，令约束失效
        configLabelConstaint(isEnable: false)
        let size: CGSize = CGSize(width: 28, height: 28)
        let iconSize: CGFloat = 24
        [backButton, openSceneButton].forEach {
            $0.snp.makeConstraints { make in
                make.size.equalTo(size)
            }
            $0.imageView?.snp.makeConstraints({ make in
                make.size.equalTo(iconSize)
            })
        }
        if Display.pad {
            resetIpadRightViewSubviews()
        }
        updateViewVisibility()
        updateCompressMode()
        adaptCompactRule()
    }

    func setTitle(_ title: String) {
        titleButton.setTitle(title, for: .normal)
        let width = titleButton.intrinsicContentSize.width
        titleIntrinsicContentWidth = width
        updateCompressMode()
    }

    func updateExternalView(text: String, isHidden: Bool) {
        externalLabel.attributedText = NSAttributedString(string: text, config: .assist, lineBreakMode: .byTruncatingTail)
        let width = externalLabel.intrinsicContentSize.width
        externalView.isHiddenInStackView = isHidden
        let sideInsets: CGFloat = 8
        externalIntrinsicContentWidth = width + sideInsets
        updateCompressMode()
        adaptCompactRule()
    }

    func setRehearsalHidden(_ isHidden: Bool) {
        let width = rehearsalLabel.intrinsicContentSize.width
        rehearsalView.isHiddenInStackView = isHidden
        let sideInsets: CGFloat = 8
        rehearsalIntrinsicContentWidth = width + sideInsets
        updateCompressMode()
        adaptCompactRule()
    }

    func setE2EeViewHidden(_ isHidden: Bool) {
        e2EeView.isHiddenInStackView = isHidden
        updateCompressMode()
        adaptCompactRule()
    }

    func setJoinRoomHidden(_ isHidden: Bool) {
        self.isJoinRoomHidden = isHidden
        resetIpadRightViewSubviews()
        updateViewVisibility()
        updateCompressMode()
        adaptCompactRule()
    }

    func updateHangupType(_ hangupType: InMeetTopBarHangupType) {
        let icon: UIImage
        let normalColor: UIColor
        let highlightColor: UIColor
        switch hangupType {
        case .hangup:
            normalColor = UIColor.ud.functionDangerFillDefault
            highlightColor = UIColor.ud.functionDangerFillPressed
            icon = UDIcon.getIconByKey(.callEndFilled, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 16, height: 16))
        case .leave:
            normalColor = .clear
            highlightColor = .clear
            icon = UDIcon.getIconByKey(.leaveroomFilled, iconColor: UIColor.ud.functionInfoFillDefault, size: CGSize(width: 24, height: 24))
        }
        hangupButton.vc.setBackgroundColor(normalColor, for: .normal)
        hangupButton.vc.setBackgroundColor(highlightColor, for: .highlighted)
        hangupButton.setImage(icon, for: .normal)
        hangupButton.setImage(icon, for: .highlighted)
    }

    func updateWhiteboardOpaque(_ isOpaque: Bool) {
        if isPhoneLandscape {
            // disable-lint: magic number
            let alpha: CGFloat = isOpaque ? 1 : 0.3
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = alpha
            })
            // enable-lint: magic number
        }
    }

    func updateMyAIVisible() {
        if Display.pad {
            resetIpadRightViewSubviews()
            updateViewVisibility()
            updateCompressMode()
            adaptCompactRule()
        }
    }

    func resetToolbarItemViews(_ itemViews: [NavigationBarItemView]) {
        toolBarStackView.subviews.forEach {
            $0.removeFromSuperview()
        }
        if isPhonePortrait {
            itemViews.forEach {
                $0.item.addListener(self)
            }
        }
        self.toolbarItemViews = itemViews
        itemViews.forEach {
            toolBarStackView.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.width.equalTo(isPhoneLandscape ? 56 : 44)
            }
        }
        moreView.removeFromSuperview()
        moreView.isHidden = true
        toolBarStackView.addArrangedSubview(moreView)
        moreView.snp.makeConstraints { make in
            make.width.equalTo(isPhoneLandscape ? 56 : 44)
        }
    }

    func insertItemView(_ itemView: NavigationBarItemView, at position: Int) {
        guard itemView.superview == nil, position <= toolbarItemViews.count else {
            return
        }
        toolBarStackView.insertArrangedSubview(itemView, at: position)
        toolbarItemViews.insert(itemView, at: position)
        itemView.snp.makeConstraints { make in
            make.width.equalTo(isPhoneLandscape ? 56 : 44)
        }
    }

    func removeItemView(at position: Int) {
        guard position < toolbarItemViews.count else { return }
        let view = toolbarItemViews[position]
        toolBarStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        toolbarItemViews.remove(at: position)
    }

    func updateNetworkStatus(_ status: RtcNetworkStatus) {
        let (icon, shouldShow) = status.networkIcon()
        networkStatusImage.image = icon
        networkStatusImage.isHiddenInStackView = !shouldShow
        updateViewVisibility()
        updateCompressMode()
        adaptCompactRule()
    }

    func updateSceneButtons() {
        if VCScene.isAuxSceneOpen {
            openSceneButton.isHiddenInStackView = true
        } else {
            openSceneButton.isHiddenInStackView = false
        }
        updateLayout()
    }

    func expandDetail(_ expand: Bool) {
        titleButton.isUserInteractionEnabled = false
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, animations: {
            self.arrowView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }, completion: { _ in
            self.arrowView.transform = .identity
            self.arrowView.image = expand ? Self.arrowUpImage : Self.arrowDownImage
            self.titleButton.isUserInteractionEnabled = true
        })
    }

    func updateBreakoutRoomInfo(showRemainingTime: Bool, remainingTime: TimeInterval) {
        durationLabel.isHiddenInStackView = showRemainingTime
        remainingTimeView.isHiddenInStackView = !showRemainingTime
        remainingTimeLabel.attributedText = NSAttributedString(
            string: remainingTime > 0 ? DateUtil.formatDuration(remainingTime, concise: true) : "00:00",
            config: VCScene.isRegular ? .assist : .boldTiniestAssist
        )
    }

    func updateStatus(_ items: [InMeetStatusThumbnailItem]) {
        let existedTypes = Set<InMeetStatusType>(statuses.map { $0.type })
        let newTypes = Set<InMeetStatusType>(items.map { $0.type })
        let deleted = existedTypes.subtracting(newTypes)
        let added = newTypes.subtracting(existedTypes)

        deleted.compactMap { statusThumbnailView(for: $0) }.forEach { $0.removeFromSuperview() }

        var currentStatusViewWidth: CGFloat = 0
        let spacing: CGFloat = 10.0
        let concise = items.count > 2
        for (i, item) in items.enumerated() {
            if added.contains(item.type) {
                if item.type == .countDown {
                    statusView.insertArrangedSubview(countDownTag, at: i)
                } else {
                    let view = statusThumbnailViewMap[item.type] ?? InMeetNavigationBarStatusThumbnailView(type: item.type)
                    statusView.insertArrangedSubview(view, at: i)
                    statusThumbnailViewMap[item.type] = view
                }
            }
            let itemWidth = updateStatusView(for: item, concise: concise)
            currentStatusViewWidth += itemWidth + spacing
        }
        currentStatusViewWidth -= spacing
        statuses = items
        updateViewVisibility()
        guard currentStatusViewWidth > 0 && currentStatusViewWidth != statusViewWidth else { return }
        updateCompressMode()
    }

    func updateCompressMode() {
        // 必须要有switchScene按钮或者多个其他按钮，才有可能需要收起功能的
        // ipad R模式才有各种收纳规则
        guard isFoldEnabled || hasSwitchSceneEntrance, VCScene.isRegular, !self.frame.isEmpty else { return }
        var newCompressMode: CompressMode = .left
        // 计算中间视图的宽度
        let middleViewWidth = calculateMiddleViewTotalWidth()
        let rightViewTotalWidth = getRightViewTotalWidthForRegular()
        let rightViewInset: CGFloat = 6.0
        let leftViewInset: CGFloat = 16.0
        // 右边最多需要的宽度
        let rightViewPlaceholderWidth: CGFloat = rightViewTotalWidth + rightViewInset + rightViewInset
        // 左边最多需要的宽度
        let leftViewPlaceholderWidth: CGFloat = leftView.frame.width + leftViewInset + leftViewInset
        let contentPlaceholderWidth = selfWidth - rightViewPlaceholderWidth - leftViewPlaceholderWidth
        let halfNaviWidth = selfWidth / 2
        if contentPlaceholderWidth >= middleViewWidth {
            self.currentCompressMode = .left
            return
        }

        // 压缩layout和竖线
        if hasSwitchSceneEntrance {
            newCompressMode = .compressLayoutButton
            // 增加省略的宽度，再算一次看够不够
            let padSwitchWidthWithoutText: CGFloat = 44
            if contentPlaceholderWidth + (isFoldEnabled ? 13 : 0) + (padSwitchSceneButton.totalWidth - padSwitchWidthWithoutText) >= middleViewWidth {
                self.currentCompressMode = .compressLayoutButton
                return
            }
        }
        // 收item到more
        if isFoldEnabled {
            var omitWidth: CGFloat = 0
            // 按最小约束进行压缩，统计压缩出来的宽度
            if titleIntrinsicContentWidth > minTitleWidth {
                omitWidth += titleIntrinsicContentWidth - minTitleWidth
            }
            if !externalView.isHiddenInStackView, externalIntrinsicContentWidth > minExternalWidth {
                omitWidth += externalIntrinsicContentWidth - minExternalWidth
            }
            if !rehearsalView.isHiddenInStackView, rehearsalIntrinsicContentWidth > minRehearsalWidth {
                omitWidth += rehearsalIntrinsicContentWidth - minRehearsalWidth
            }
            // 如果极限压缩还放不下，就把功能收到more里面
            if middleViewWidth - omitWidth > contentPlaceholderWidth {
                currentCompressMode = .rightIsMore
                return
            }
        }
        currentCompressMode = newCompressMode
    }

    func adaptCompactRule() {
        guard isFoldEnabled || toolbarItemViews.count >= 2 else {
            isMoreItemShowInCompact = false
            return
        }
        if isPhoneLandscape {
            isMoreItemShowInCompact = false
            return
        }
        let rightViewWidth = getRightViewWidthForCompact()
        let minWidth = calculateMiddleViewMinWidth()
        let leftViewLeftInset: CGFloat = 16.0
        let leftViewRightInset: CGFloat = 8.0
        let leftViewWidth = leftView.frame.width + leftViewLeftInset + leftViewRightInset
        let widthSuit = selfWidth - leftViewWidth - rightViewWidth >= minWidth
        configLabelConstaint(isEnable: true)
        if isPhonePortrait {
            toolbarItemViews.forEach { $0.isHiddenInStackView = !widthSuit }
            if toolbarItemViews.contains(where: { $0.item.badgeType != .none }) {
                badgeView.isHidden = false
            } else {
                badgeView.isHidden = true
            }
            moreView.isHiddenInStackView = widthSuit
        } else {
            guard isFoldEnabled else {
                isMoreItemShowInCompact = false
                return
            }
            if isMyAIEnabled {
                myAIButton.isHiddenInStackView = !widthSuit
            } else {
                myAIButton.isHiddenInStackView = true
            }
            if isJoinRoomEnabled {
                joinRoomButton.isHiddenInStackView = !widthSuit
            }
            if hasSwitchSceneEntrance {
                padSwitchSceneButton.isHiddenInStackView = !widthSuit
            }
            moreView.isHiddenInStackView = widthSuit
        }
        isMoreItemShowInCompact = !widthSuit
    }

    var countDownFoldGuideReferenceView: UIView {
        let isTagHidden = countDownTag.isHidden || countDownTag.superview == nil
        return isTagHidden ? statusView : countDownTag
    }

    var interviewPopoverReferenceView: UIView? {
        statusThumbnailViewMap[.interviewRecord]
    }

    func adaptShadowConfig() {
        Util.runInMainThread {
            switch self.sceneMode {
            case .gallery:
                if Display.phone {
                    if self.isPhoneLandscape && self.isOtherSharingScreenOrWhiteboard {
                        if let range = self.gridVisibleRange, case .range(let start, _, _) = range, start == 0 {
                            self.shouldShowShadow = false
                        } else {
                            self.shouldShowShadow = self.isOverlay
                        }
                    } else {
                        self.shouldShowShadow = self.isOverlay
                    }
                } else {
                    self.shouldShowShadow = self.isOverlay && self.isNoSharingContent
                }
            case .thumbnailRow:
                self.shouldShowShadow = false
            case .speech:
                if self.isInMs {
                    self.shouldShowShadow = true
                } else {
                    self.shouldShowShadow = self.isOverlay && (self.isShowSpeakerOnMainScreen || self.isNoSharingContent)
                }
            case .webinarStage:
                self.shouldShowShadow = self.isOverlay
            }
        }
    }

    // nolint: duplicated_code
    private func updateLayoutForReguarMode() {
        durationLabel.textColor = UIColor.ud.textTitle
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        durationLabel.snp.remakeConstraints { make in
            make.height.equalTo(20)
        }

        remainingTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        remainingTimeLabel.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(4)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(18)
        }

        middleView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(leftView.snp.right).offset(20)
            make.right.lessThanOrEqualTo(rightView.snp.left).offset(-6)
        }

        titleContainerView.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        statusContainerView.snp.remakeConstraints { make in
            make.left.equalTo(titleContainerView.snp.right).offset(21)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        currentCompressMode = .left
    }

    private func updateLayoutForUnRegularMode() {
        durationLabel.textColor = UIColor.ud.textCaption
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        durationLabel.snp.remakeConstraints { make in
            make.height.equalTo(13)
        }

        remainingTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        remainingTimeLabel.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(4)
            make.top.bottom.equalToSuperview().inset(1)
            make.height.equalTo(13)
        }

        middleView.snp.remakeConstraints { make in
            make.left.equalTo(leftView.snp.right).offset(Display.phone ? 8 : 20)
            make.right.equalTo(rightView.snp.left)
            make.top.bottom.equalToSuperview()
        }

        titleContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(5)
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        statusContainerView.snp.remakeConstraints { make in
            make.top.equalTo(titleContainerView.snp.bottom)
            make.right.lessThanOrEqualToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(14)
        }

        toolbarItemViews.forEach {
            $0.snp.remakeConstraints { make in
                make.width.equalTo(isLandscape ? 56 : 44)
            }
        }
    }

    private func resetIpadRightViewSubviews() {
        myAIButton.removeFromSuperview()
        var ipadRightItemsCount: Int = 0
        if isMyAIEnabled {
            rightView.addArrangedSubview(myAIButton)
            ipadRightItemsCount += 1
        }
        joinRoomButton.removeFromSuperview()
        if isJoinRoomEnabled && !isJoinRoomHidden {
            rightView.addArrangedSubview(joinRoomButton)
            joinRoomButton.snp.remakeConstraints { make in
                make.size.equalTo(CGSize(width: 44, height: 36))
            }
            ipadRightItemsCount += 1
        }
        switchSceneLine.removeFromSuperview()
        padSwitchSceneButton.removeFromSuperview()
        if hasSwitchSceneEntrance {
            rightView.addArrangedSubview(switchSceneLine)
            rightView.addArrangedSubview(padSwitchSceneButton)
            ipadRightItemsCount += 1
        }
        isFoldEnabled = ipadRightItemsCount >= 2

        moreView.removeFromSuperview()
        if isFoldEnabled {
            rightView.addArrangedSubview(moreView)
            moreView.isHiddenInStackView = true
            moreView.snp.remakeConstraints { make in
                make.size.equalTo(CGSize(width: 44, height: 36))
            }
        }
    }

    private func setCompressModeForLayout() {
        switch currentCompressMode {
        case .left:
            padSwitchSceneButton.isCompressMode = false
            rightView.isHiddenInStackView = false
            if hasSwitchSceneEntrance, isFoldEnabled {
                switchSceneLine.isHiddenInStackView = false
            }
        case .compressLayoutButton:
            rightView.isHiddenInStackView = false
            padSwitchSceneButton.isCompressMode = true
            switchSceneLine.isHiddenInStackView = true
        case .rightIsMore:
            rightView.isHiddenInStackView = true
        }
    }

    // 计算middleview的全部宽度，用于确定R模式的布局及缩略规则
    private func calculateMiddleViewTotalWidth() -> CGFloat {
        var result: CGFloat = 0
        let spacing: CGFloat = 4.0
        // 外部标签宽度
        if !externalView.isHiddenInStackView {
            result += externalIntrinsicContentWidth + spacing
        }
        // 彩排标签宽度
        if !rehearsalView.isHiddenInStackView {
            result += rehearsalIntrinsicContentWidth + spacing
        }
        // 加密通话图标宽度
        if !e2EeView.isHiddenInStackView {
            result += e2EeViewWidth + spacing
        }
        // 会议标题宽度加分割距离
        let splitSpacing: CGFloat = 21
        result += titleIntrinsicContentWidth + spacing + arrowWidth + splitSpacing
        // 会议时间宽度或者剩余时间宽度
        result += remainingTimeLabel.isHiddenInStackView ? remainingTimeLabel.intrinsicContentSize.width + 8.0 : durationLabel.intrinsicContentSize.width
        // 状态栏宽度
        if !statusLine.isHiddenInStackView {
            let statusViewSpacing: CGFloat = 10.0
            let networkImageWidth: CGFloat = 16.0
            result += splitSpacing + (networkStatusImage.isHiddenInStackView ? 0 : networkImageWidth + statusViewSpacing)
            result += (statusView.isHiddenInStackView ? 0 : statusViewWidth)
        }
        return result
    }

    // 计算middleview的最小宽度，用于确定iphone和C模式下右边items是否需要收纳进more
    private func calculateMiddleViewMinWidth() -> CGFloat {
        var result: CGFloat = 0
        let spacing: CGFloat = 4.0
        // 外部标签宽度
        if !externalView.isHiddenInStackView {
            result += (externalIntrinsicContentWidth >= minExternalWidth ? minExternalWidth + spacing : externalIntrinsicContentWidth + spacing)
        }
        // 彩排标签宽度
        if !rehearsalView.isHiddenInStackView {
            result += (rehearsalIntrinsicContentWidth >= minRehearsalWidth ? minRehearsalWidth + spacing : rehearsalIntrinsicContentWidth + spacing)
        }
        // 加密通话图标宽度
        if !e2EeView.isHiddenInStackView {
            result += e2EeViewWidth + spacing
        }
        // 会议标题宽度
        result += (titleIntrinsicContentWidth > minTitleWidth ? minTitleWidth : titleIntrinsicContentWidth) + spacing + arrowWidth
        return result
    }

    // 三个label是否需要最小宽度的约束（不能直接设置约束一直生效，有可能本身宽度小于最小宽度）
    private func configLabelConstaint(isEnable: Bool) {
        if isEnable {
            if titleIntrinsicContentWidth > minTitleWidth {
                minTitleWidthConstraint?.activate()
            } else {
                minTitleWidthConstraint?.deactivate()
            }
            if externalIntrinsicContentWidth > minExternalWidth {
                minExternalWidthConstraint?.activate()
            } else {
                minExternalWidthConstraint?.deactivate()
            }
            if rehearsalIntrinsicContentWidth > minRehearsalWidth {
                minRehearsalWidthConstraint?.activate()
            } else {
                minRehearsalWidthConstraint?.deactivate()
            }
        } else {
            minTitleWidthConstraint?.deactivate()
            minExternalWidthConstraint?.deactivate()
            minRehearsalWidthConstraint?.deactivate()
        }
    }

    // 包含右边距
    private func getRightViewWidthForCompact() -> CGFloat {
        let itemWidth: CGFloat = 44
        if Display.pad {
            var result: CGFloat = 0
            if isMyAIEnabled {
                result += itemWidth
            }
            if isJoinRoomEnabled {
                result += itemWidth
            }
            if hasSwitchSceneEntrance {
                result += itemWidth
            }
            return result + 6
        } else {
            let leaveItemWidth: CGFloat = isPhoneLandscape ? portraitHangUpWidth : landscapeHangUpWidth
            return CGFloat(toolbarItemViews.count) * itemWidth + leaveItemWidth + 4
        }
    }

    // 不包含右边距
    private func getRightViewTotalWidthForRegular() -> CGFloat {
        var rightViewTotalWidth: CGFloat = 0
        let itemWidth: CGFloat = 44
        if isMyAIEnabled {
            rightViewTotalWidth += itemWidth
        }
        if isJoinRoomEnabled {
            rightViewTotalWidth += itemWidth
        }
        if hasSwitchSceneEntrance {
            rightViewTotalWidth += padSwitchSceneButton.totalWidth
        }
        if isFoldEnabled, hasSwitchSceneEntrance {
            let splitSpacing: CGFloat = 13.0
            rightViewTotalWidth += splitSpacing
        }
        return rightViewTotalWidth
    }

    private func setupSubviews() {
        updateBackgroundColor()
        addSubview(contentView)
        addLayoutGuide(barContentGuide)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(barContentGuide)
        }

        contentView.addSubview(leftView)
        leftView.addArrangedSubview(backButton)
        if #available(iOS 13, *), VCScene.supportsMultipleScenes {
            leftView.addArrangedSubview(openSceneButton)
        }

        contentView.addSubview(rightView)
        if Display.phone {
            rightView.addArrangedSubview(toolBarStackView)
            toolBarStackView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
            }
            rightView.addArrangedSubview(hangupClickView)
            hangupClickView.snp.makeConstraints { make in
                make.width.equalTo(portraitHangUpWidth)
                make.height.equalTo(44)
            }
            hangupClickView.addSubview(hangupButton)
            hangupButton.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(26)
            }
        } else {
            resetIpadRightViewSubviews()
        }

        contentView.addLayoutGuide(middleLayoutGuide)
        middleLayoutGuide.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.left.equalTo(leftView.snp.right)
            make.right.equalTo(rightView.snp.left).offset(10)
        }
        contentView.addSubview(middleView)
        middleView.addSubview(titleContainerView)

        titleContainerView.addArrangedSubview(rehearsalView)
        externalView.snp.makeConstraints { make in
            minExternalWidthConstraint = make.width.greaterThanOrEqualTo(44).constraint
            make.height.equalTo(18)
        }

        titleContainerView.addArrangedSubview(externalView)
        rehearsalView.snp.makeConstraints { make in
            minRehearsalWidthConstraint = make.width.greaterThanOrEqualTo(44).constraint
            make.height.equalTo(18)
        }

        titleContainerView.addArrangedSubview(e2EeView)
        e2EeView.snp.makeConstraints { make in
            make.size.equalTo(e2EeViewWidth)
        }

        titleContainerView.addArrangedSubview(titleButton)
        titleButton.snp.makeConstraints { make in
            make.height.equalTo(20)
            minTitleWidthConstraint = make.width.greaterThanOrEqualTo(36).constraint
        }

        titleContainerView.addArrangedSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.size.equalTo(10)
        }

        middleView.addSubview(statusContainerView)

        statusContainerView.addArrangedSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.height.equalTo(13)
        }

        remainingTimeView.addSubview(remainingTimeLabel)
        remainingTimeLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(4)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(13)
        }
        statusContainerView.addArrangedSubview(remainingTimeView)

        statusContainerView.addArrangedSubview(networkStatusImage)
        networkStatusImage.snp.makeConstraints { make in
            make.size.equalTo(VCScene.isRegular ? 16 : 12)
        }

        if Display.pad {
            statusContainerView.addArrangedSubview(statusView)
        }

        contentView.addSubview(durationLine)
        durationLine.snp.makeConstraints { make in
            make.left.equalTo(arrowView.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(12)
        }

        statusContainerView.insertArrangedSubview(statusLine, belowArrangedSubview: remainingTimeView)
        statusLine.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(12)
        }
        myAIButton.update(with: viewModel.myAIViewModel)
    }

    private func updateViewVisibility() {
        if VCScene.isRegular {
            statusView.isHiddenInStackView = statuses.isEmpty
            statusLine.isHiddenInStackView = networkStatusImage.isHiddenInStackView && statusView.isHiddenInStackView
            durationLine.isHiddenInStackView = false
            switchSceneLine.isHiddenInStackView = !isFoldEnabled || (joinRoomButton.isHiddenInStackView && myAIButton.isHiddenInStackView)
        } else {
            statusLine.isHiddenInStackView = networkStatusImage.isHiddenInStackView
            durationLine.isHiddenInStackView = true
            statusView.isHiddenInStackView = true
            switchSceneLine.isHiddenInStackView = true
        }
    }

    private func createButton(icon: UDIconType, dimension: CGFloat = 24) -> UIButton {
        let button = UIButton()
        button.isExclusiveTouch = true
        button.addInteraction(type: .highlight)
        button.setImage(UDIcon.getIconByKey(icon, iconColor: UIColor.ud.iconN1, size: CGSize(width: dimension, height: dimension)), for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralHover, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralHover, for: .selected)
        return button
    }

    private func newLine() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }

    private func getSwitchSceneLine() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.snp.makeConstraints { make in
            make.width.equalTo(13)
            make.height.equalTo(20)
        }

        let line = newLine()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(12)
            make.width.equalTo(1)
        }
        return view
    }

    private func statusThumbnailView(for type: InMeetStatusType) -> UIView? {
        if type == .countDown {
            return countDownTag
        } else {
            return statusThumbnailViewMap[type]
        }
    }

    private func updateStatusView(for item: InMeetStatusThumbnailItem, concise: Bool) -> CGFloat {
        if item.type == .countDown {
            guard let data = item.data as? InMeetStatusCountDownData else { return 0 }
            countDownTag.update(hour: data.timeInHMS.hour, minute: data.timeInHMS.minute, seconds: data.timeInHMS.second, stage: data.stage)
            return countDownTag.intrinsicContentWidth
        } else if let view = statusThumbnailViewMap[item.type] {
            view.config(with: item, concise: concise)
            if item.type == .record {
                let isLaunching = item.data as? Bool ?? false
                view.isRecordLaunching = isLaunching
            }
            if item.type == .transcribe {
                let isLaunched = item.data as? Bool ?? false
                view.iconView.image = isLaunched ? ImageCache.transcribe :  ImageCache.transcribeLaunch
            }
            return concise ? 16.0 : (20 + view.labelWidth)
        }
        return 0
    }

    // MARK: - Actions

    @objc private func handleBack() {
        if VCScene.isAuxSceneOpen {
            delegate?.navigationBarDidClickCloseScene()
        } else {
            delegate?.navigationBarDidClickBack()
        }
    }

    @objc private func handleHangup(_ sender: UIButton) {
        delegate?.navigationBarDidClickHangup(sender: sender)
    }

    @objc private func handleTitleClick(_ sender: UIButton) {
        delegate?.navigationBarDidClickMeetingTitle(sender: sender)
    }

    @objc private func handleSwitchSceneClick(_ sender: UIButton) {
        delegate?.navigationBarDidClickSwitchMeetingScene(sender: sender)
    }

    @objc private func handleOpenScene() {
        delegate?.navigationBarDidClickOpenScene()
       VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "split_screen", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": isLandscape ? "true" : "false"])
    }

    @objc private func didJoinRoom(_ sender: UIButton) {
        delegate?.navigationBarDidClickJoinRoom(sender)
    }

    @objc private func didClickMore(_ sender: UIButton) {
        delegate?.navigationBarDidClickMoreButton(sender: sender)
    }

    @objc private func handleCountDown() {
        delegate?.navigationBarDidClickCountDown()
    }

    @objc private func handleStatusClick() {
        delegate?.navigationBarDidClickStatusView(statusView)
    }

    @objc private func handleStatusContainerClick() {
        if isPhoneLandscape || isRegular {
            return
        }
        handleTitleClick(titleButton)
    }

    @objc private func didClickMyAI() {
        viewModel.myAIViewModel.open()
    }
}

private class InMeetNavigationBarStatusThumbnailView: UIView {
    lazy var iconView: UIImageView = {
        let view = UIImageView()
        if type == .record {
            view.animationImages = [ImageCache.recordAnimationIcon1, ImageCache.recordAnimationIcon2]
            view.animationDuration = 1.2
        }
        return view
    }()
    let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = .systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 4
        return view
    }()

    let type: InMeetStatusType

    var isRecordLaunching: Bool = false {
        didSet {
            if isRecordLaunching {
                iconView.animationImages = nil
                iconView.image = ImageCache.recordAnimationIcon3
                iconView.stopAnimating()
            } else {
                iconView.image = nil
                iconView.animationImages = [ImageCache.recordAnimationIcon1, ImageCache.recordAnimationIcon2]
                iconView.animationDuration = 1.2
                iconView.startAnimating()
            }
        }
    }

    var labelWidth: CGFloat = 0

    init(type: InMeetStatusType) {
        self.type = type
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with item: InMeetStatusThumbnailItem, concise: Bool) {
        textLabel.isHiddenInStackView = concise
        iconView.image = ImageCache.icon(with: item)
        let needCalculate: Bool = item.title != textLabel.text
        textLabel.text = item.title
        if needCalculate {
            labelWidth = textLabel.intrinsicContentSize.width
        }
    }

    private func setupSubviews() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(16)
        }

        stackView.addArrangedSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
    }
}

private class ImageCache {
    static let imageSize = CGSize(width: 16, height: 16)
    static let recording = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.functionDangerFillDefault, size: imageSize)
    static let live = UDIcon.getIconByKey(.livestreamFilled, iconColor: UIColor.ud.functionDangerFillDefault, size: imageSize)
    static let transcribe = UDIcon.getIconByKey(.transcribeFilled, iconColor: UIColor.ud.functionInfoContentDefault, size: imageSize)
    static let transcribeLaunch = UDIcon.getIconByKey(.transcribeFilled, iconColor: UIColor.ud.iconN2, size: imageSize)
    static let lock = UDIcon.getIconByKey(.lockFilled, iconColor: UIColor.ud.iconN2.withAlphaComponent(0.8), size: imageSize)
    static let interpreter = UDIcon.getIconByKey(.languageFilled, iconColor: UIColor.ud.iconN2.withAlphaComponent(0.8), size: imageSize)
    static let interview = UDIcon.getIconByKey(.voice2textFilled, iconColor: UIColor.ud.iconN2.withAlphaComponent(0.8), size: imageSize)

    // 当使用colorful的icon做动画的时候，不产生效果，需要画一个新的image
    static let recordAnimationIcon1 = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.R400, size: imageSize).imageWithColor(color: UIColor.ud.functionDangerFillDefault)
    static let recordAnimationIcon2 = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.R600, size: imageSize).imageWithColor(color: UIColor.ud.functionDangerFillHover)
    static let recordAnimationIcon3 = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.N500, size: imageSize).imageWithColor(color: UIColor.ud.N500)

    static func icon(with item: InMeetStatusThumbnailItem) -> UIImage? {
        switch item.type {
        case .live: return live
        case .interpreter: return item.icon
        case .record: return recording
        case .transcribe: return transcribe
        case .lock: return lock
        case .interviewRecord: return interview
        default: return nil
        }
    }
}

// 如果button 出现省略文字的情况下，会出现inset，导致文字不是左对齐。
private class TitleButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let frame = self.titleLabel?.frame {
            self.titleLabel?.frame = CGRect(x: 0, y: frame.origin.y, width: frame.width, height: frame.height)
        }
    }
}

extension InMeetNavigationBar: ToolBarItemDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        if isPhonePortrait, !moreView.isHidden {
            let shouldShowBadge: Bool = toolbarItemViews.contains(where: { $0.item.badgeType != .none })
            badgeView.isHidden = !shouldShowBadge
        }
    }
}

extension InMeetNavigationBar: MyAIViewModelListener {
    func myAITitleDidUpdated() {
        myAIButton.update(with: viewModel.myAIViewModel)
    }
}
