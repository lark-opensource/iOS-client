//
//  FloatingInteractionViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/8/19.
//

import UIKit
import SnapKit
import ByteViewUI
import ByteViewTracker
import ByteViewNetwork
import UniverseDesignIcon

/*
 * 位于宫格流左侧的 reaction + chat 浮动按钮以及 reaction 面板，
 * 层级位于宫格流之上，内容限制在 contentGuide 之间，通过重写 hitTest 限制可点击区域
 */
class FloatingInteractionViewController: VMViewController<FloatingInteractionViewModel>, UIGestureRecognizerDelegate {
    weak var container: InMeetViewContainer? {
        didSet {
            if let container = self.container {
                let meetingContent = container.context.meetingContent
                isSharing = meetingContent != .flow && meetingContent != .selfShareScreen
                setupPanelView(container)
                updateFloatingViewHidden()
            }
        }
    }
    var contentGuide: UILayoutGuide?
    var interpreterGuide: UILayoutGuide?
    var subtitleInitialGuide: UILayoutGuide?
    var chatInputKeyboardGuide: UILayoutGuide?
    private let initialLayoutGuide = UILayoutGuide()
    private var floatingButtonGuideToken: MeetingLayoutGuideToken?

    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var panStartingPoint: CGPoint = .zero
    private var isFirstLayoutSubviews = true
    private var guideSureAction: (() -> Void)?

    private typealias PanelState = FloatingInteractionViewModel.PanelState
    private typealias PanelLocation = FloatingInteractionViewModel.PanelLocation
    /// 浮动面板状态
    private lazy var panelState: PanelState = viewModel.panelState {
        didSet {
            if oldValue != panelState {
                updatePanelStyle()
            }
        }
    }
    /// 浮动面板在屏幕中的位置，决定了其在 collapsed 和 dragging 状态下的样式
    private lazy var panelLocation: PanelLocation = viewModel.panelLocation {
        didSet {
            if oldValue != panelLocation {
                updatePanelStyle()
            }
        }
    }
    /// 表情面板是否被展开
    private var isReactionExpanded = false {
        didSet {
            viewModel.isReactionPanelExpanded = isReactionExpanded
        }
    }
    private var isShowingGuide = false
    private static let animationDuration: TimeInterval = 0.25
    private static let pressTriggleTime: TimeInterval = 0.3
    private static let guideAnimationDelay: TimeInterval = 0.6
    private static let guideAnimationDuration: TimeInterval = 0.3
    private static let springDamping: CGFloat = {
        // tension & friction -> spring damping ratio
        // https://stackoverflow.com/a/50081043
        let tension: CGFloat = 443.47
        let friction: CGFloat = 22.17
        return friction / (2 * (1 * tension).squareRoot())
    }()
    private var isSingleVideo = false
    private var isFullScreen = false
    private var isSharing = false
    private lazy var isWhiteboardMenuEnable = viewModel.context.isWhiteboardMenuEnabled
    private lazy var meetingScene = viewModel.context.meetingScene
    private var isInterpreting = false
    // 用户是否用手指移动过面板，没有移动过时，从共享态到非共享态，浮动面板要自动调整位置
    private var hasMovedPanel = false
    private var isSubtitleOn = false
    private var isAnimating = false
    private let panelHeightLayoutGuide = UILayoutGuide()
    /// interactionLayoutGuide 代表浮动面板的可显示区域，上下边界等于拖拽范围，
    /// 左右不对拖拽过程设限，但是手指放开以后会回到左右边界内
    private let interactionLayoutGuide = UILayoutGuide()
    private let interactionVerticalGuide = UILayoutGuide()

    private static let rightArrowImage = UDIcon.getIconByKey(.vcToolbarRightFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
    private static let leftArrowImage = UDIcon.getIconByKey(.vcToolbarLeftFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))

    private lazy var chatInputVC: ChatInputViewController = {
        let vc = ChatInputViewController()
        vc.delegate = self
        return vc
    }()

    // 懒加载 + 防止在 iPhone 上被初始化
    private lazy var _landscapeVC: LandscapeChatInputViewController = {
        let vc = LandscapeChatInputViewController()
        vc.delegate = self
        return vc
    }()

    private var landscapeInputVC: LandscapeChatInputViewController? {
        Display.phone ? _landscapeVC : nil
    }

    private enum Layout {
        static let floatingHeight: CGFloat = 40
        static let panelPadding: CGFloat = 4
        static let verticalPadding: CGFloat = 8
        // interpreter height(44) + inset(8)
        static let interpreterInset: CGFloat = 44 + 8
        static let shrinkThreshold: CGFloat = 60
    }

    private var floatingBottomPadding: CGFloat {
        if Display.pad, isWhiteboardMenuEnable {
            return 8
        } else if Display.pad {
            return 48
        } else if isSharing {
            return 8
        } else if currentLayoutContext.layoutType.isCompact {
            return 32
        } else if panelLocation == .right {
            // 组件互斥功能之前的临时方案：iPhone 横屏右边时避开麦克风默认位置，距离其顶部 12
            return Display.iPhoneXSeries ? 56 : 69
        } else {
            return Display.iPhoneXSeries ? 3 : 16
        }
    }

    private var floatingLeftPadding: CGFloat {
        if Display.iPhoneXSeries && view.orientation == .landscapeRight {
            return 0
        } else {
            return 7
        }
    }

    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard blockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    private var panBlockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard panBlockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    private var guideBlockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard panBlockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    private var containerIsHidden = false {
        didSet {
            if oldValue != containerIsHidden {
                updateFloatingViewHidden()
            }
        }
    }
    /// 最外层浮动视图，提供阴影
    private let floatingContainerView: UIView = {
        let view = UIView()
        view.layer.ud.setShadow(type: .s4Down)
        return view
    }()

    /// 所有浮动内容视图的容器，包括表情、聊天框、箭头（收起或拖拽过程中出现）
    private let floatingView = UIView()

    // 下面两个视图是为了做拖动和自动收起过程中的圆角动画。iOS maskedCorners 本身不支持动画，如果在动画过程中涉及这个属性的变动，效果会非常奇怪，因此采用妥协的方案，
    // 左右各一个 maskedCorners 不变的视图，只改变 cornerRadius（可动画属性），因此 border、圆角均由 left、rightFloatingView 提供
    // 这样会在视图中间也有一个 border，因此用 HalfView 把这道线盖住 TaT
    // It's ugly, but it works :]

    private let leftFloatingView: UIView = {
        let view = HalfView(isLeftSide: true)
        view.layer.masksToBounds = true
        view.layer.borderWidth = 0.5
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        return view
    }()

    private let rightFloatingView: UIView = {
        let view = HalfView(isLeftSide: false)
        view.layer.masksToBounds = true
        view.layer.borderWidth = 0.5
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    /// floatingView 的直接子视图，用于方便控制隐藏子视图时的约束更新
    private let floatingStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 2
        return view
    }()

    private lazy var arrowButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleArrowButtonClick), for: .touchUpInside)
        button.addInteraction(type: .hover)
        return button
    }()

    /// 表情和聊天框的父视图
    private let interactionView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        return view
    }()

    private lazy var reactionButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.emojiOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 22, height: 22)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.emojiOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 22, height: 22)), for: .highlighted)
        button.setImage(UDIcon.getIconByKey(.emojiOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 22, height: 22)), for: .selected)
        button.addTarget(self, action: #selector(handleReactionButtonClick), for: .touchUpInside)
        button.addInteraction(type: .hover)
        return button
    }()

    private lazy var panelView: FloatingReactionPanelView = {
        let view = FloatingReactionPanelView(service: viewModel.meeting.service)
        return view
    }()

    private let triangleView: TriangleView = {
        let view = TriangleView()
        view.layer.ud.setShadow(type: .s4Down)
        view.backgroundColor = .clear
        view.color = UIColor.ud.bgFloat
        view.direction = .top
        return view
    }()

    private let chatLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.attributedText = NSAttributedString(string: I18n.View_G_SaySthDots, config: .tinyAssist)
        label.textInsets = UIEdgeInsets(top: 0, left: 9, bottom: 0, right: 9)
        label.textColor = UIColor.ud.textPlaceholder
        label.isUserInteractionEnabled = true
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    deinit {
        viewModel.currentPosition = floatingContainerView.frame.origin
        viewModel.panelLocation = panelLocation
        viewModel.panelState = panelState
        viewModel.isPortraitOnExit = currentLayoutContext.layoutType.isCompact
    }

    // MARK: - Override

    // 使用 VCMenuView 提供的支持自定义点击响应范围的能力
    override func loadView() {
        let menuView = VCMenuView()
        menuView.delegate = self
        view = menuView
    }

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = .clear
        view.addLayoutGuide(panelHeightLayoutGuide)
        view.addLayoutGuide(interactionLayoutGuide)
        view.addLayoutGuide(interactionVerticalGuide)
        view.addLayoutGuide(initialLayoutGuide)
        updateInteractionLayoutGuide()
        view.addSubview(floatingContainerView)
        resetFloatingViewPosition()

        floatingContainerView.addSubview(floatingView)
        floatingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.lessThanOrEqualTo(view).dividedBy(2)
        }
        floatingView.addSubview(leftFloatingView)
        floatingView.addSubview(rightFloatingView)
        leftFloatingView.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2).offset(1)
        }
        rightFloatingView.snp.makeConstraints { make in
            make.left.equalTo(leftFloatingView.snp.right).offset(-2)
            make.top.bottom.right.equalToSuperview()
        }
        floatingView.addSubview(floatingStackView)
        floatingStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(Layout.floatingHeight)
        }

        // 这两个视图的约束将在 updatePanelStyle 中更新
        if panelLocation == .left {
            floatingStackView.addArrangedSubview(interactionView)
            floatingStackView.addArrangedSubview(arrowButton)
        } else {
            floatingStackView.addArrangedSubview(arrowButton)
            floatingStackView.addArrangedSubview(interactionView)
        }

        interactionView.addSubview(reactionButton)
        reactionButton.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(46)
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        interactionView.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.equalTo(reactionButton.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalTo(14)
            make.width.equalTo(1)
        }
        interactionView.addSubview(chatLabel)
        chatLabel.snp.makeConstraints { make in
            make.left.equalTo(line.snp.right)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        chatInputVC.view.layer.ud.setShadow(type: .s4Up)
        addChild(chatInputVC)
        view.addSubview(chatInputVC.view)
        chatInputVC.view.isHidden = true
        chatInputVC.view.snp.makeConstraints { make in
            make.top.equalTo(view.snp.bottom)
            make.left.right.equalToSuperview()
        }

        if let landscapeInputVC = landscapeInputVC {
            landscapeInputVC.view.layer.ud.setShadow(type: .s4Up)
            addChild(landscapeInputVC)
            view.addSubview(landscapeInputVC.view)
            landscapeInputVC.view.isHidden = true
            landscapeInputVC.view.snp.makeConstraints { make in
                make.top.equalTo(view.snp.bottom)
                make.left.right.equalToSuperview()
            }
        }

        panelView.allowSendReaction = viewModel.allowSendReaction
        updatePanelHeightLayoutGuide()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        floatingContainerView.addGestureRecognizer(pan)

        let keyboardTap = UITapGestureRecognizer(target: self, action: #selector(showChatInput))
        chatLabel.addGestureRecognizer(keyboardTap)

        updateFloatingViewHidden()
        updateChatPlaceholder()
        updatePanelStyle()
    }

    override func viewWillFirstAppear(_ animated: Bool) {
        super.viewWillFirstAppear(animated)
        setupChatInputKeyboardGuide()
        showInteractionGuide()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let position = viewModel.currentPosition, viewModel.isPortraitOnExit == currentLayoutContext.layoutType.isCompact {
            containerIsHidden = true
            // 0.25: 小窗动画结束的时间，这里如果立刻重设约束，会伴随着小窗放大有一段奇怪的动画，
            // 且当前无法从此 VC 访问到小窗动画结束的回调，因此直接采用延时的办法
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.updateFloatingViewPosition(position)
                self.containerIsHidden = false
            })
            viewModel.currentPosition = nil
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.addListener(self)
        viewModel.showReactionPanelBlock = { [weak self] anchor in
            if let self = self, self.viewModel.meeting.isWebinarAttendee && !self.viewModel.allowSendReaction {
                Toast.show(I18n.View_G_HostNotAllowEmoji)
                return
            }
            self?.showReactionPanel(at: anchor)
        }
        viewModel.hideReactionPanelBlock = { [weak self] in
            self?.hideReactionPanel()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if oldContext.layoutType != newContext.layoutType {
            resetFloatingViewPosition()
            if Display.pad {
                chatInputVC.updateMaxLine(newContext.layoutType.isRegular ? 2 : 4)
                if newContext.layoutType == .regular {
                    guideSureAction?()
                }
            }
        }
    }

    override func viewLayoutContextDidChanged() {
        updatePanelHeightLayoutGuide()
    }

    func attachInteractionVerticalLayoutGuide(_ layoutGuide: UILayoutGuide) {
        interactionVerticalGuide.snp.remakeConstraints { make in
            make.edges.equalTo(layoutGuide)
        }
    }

    func setupPanelView(_ container: InMeetViewContainer) {
        let reactionPanel = container.loadContentViewIfNeeded(for: .reactionPanel)
        panelView.delegate = self
        panelView.alpha = 0
        panelView.isHidden = true
        reactionPanel.addSubview(panelView)
        triangleView.isHidden = true
        reactionPanel.addSubview(triangleView)
    }

    func updateInteractionLayoutGuide() {
        interactionLayoutGuide.snp.remakeConstraints { make in
            make.top.bottom.equalTo(interactionVerticalGuide)
            if Display.pad || currentLayoutContext.layoutType.isCompact {
                make.left.right.equalTo(view.safeAreaLayoutGuide)
            } else if view.orientation == .landscapeLeft {
                make.left.equalTo(0)
                make.right.equalTo(view.safeAreaLayoutGuide)
            } else {
                make.left.equalTo(view.safeAreaLayoutGuide)
                make.right.equalTo(0)
            }
        }
        // 页面完成布局之前不用走这段逻辑，防止影响入会耗时
        if !isFirstLayoutSubviews {
            view.layoutIfNeeded()
            checkFloatingPanelOverlay()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstLayoutSubviews {
            isFirstLayoutSubviews = false
            checkFloatingPanelOverlay()
        }
    }

    func resetFloatingViewPosition() {
        guard !isAnimating else { return }
        initialLayoutGuide.snp.remakeConstraints { make in
            if panelLocation == .left {
                make.left.equalTo(interactionLayoutGuide).offset(-0.5)
            } else {
                make.right.equalTo(self.interactionLayoutGuide).offset(0.5)
            }
            let isCompact = currentLayoutContext.layoutType.isCompact
            if let interpreterGuide = interpreterGuide, interpreterGuide.canUse(on: view), isInterpreting && isCompact {
                make.bottom.equalTo(interpreterGuide).inset(Layout.interpreterInset)
            } else if let guide = subtitleInitialGuide, guide.canUse(on: view), isSubtitleOn && (Display.pad || isCompact) {
                make.bottom.equalTo(guide.snp.top).offset(-8)
            } else {
                make.bottom.equalTo(interactionLayoutGuide).inset(floatingBottomPadding)
            }
        }

        floatingContainerView.snp.remakeConstraints { make in
            make.edges.equalTo(initialLayoutGuide)
        }
    }

    func containerDidTransition() {
        hideReactionPanel()
        updateInteractionLayoutGuide()
        // 旋转屏幕时重置表情按钮位置
        hasMovedPanel = false
        resetFloatingViewPosition()
        chatInputVC.textView.resignFirstResponder()
        landscapeInputVC?.textField.resignFirstResponder()
        if Display.iPhoneXSeries {
            updatePanelStyle()
        }
    }

    func updateChatPlaceholder() {
        let allowSendMessage = viewModel.allowSendMessage
        let banText = viewModel.meeting.subType == .webinar ? I18n.View_G_MessageBanned : I18n.View_G_BanAllFromMessage
        let chatPlaceholder = allowSendMessage ? I18n.View_G_SaySthDots : banText
        let inputVCPlaceholer = allowSendMessage ? I18n.View_G_MessageMeetingTitle(viewModel.meetingTopic) : banText
        let color = allowSendMessage ? UIColor.ud.textPlaceholder : UIColor.ud.textDisabled

        if !allowSendMessage {
            chatInputVC.endEditing()
            chatInputVC.clearText()
            landscapeInputVC?.endEditing()
            landscapeInputVC?.clearText()
        }

        chatInputVC.allowInput = viewModel.allowSendMessage
        landscapeInputVC?.allowInput = viewModel.allowSendMessage

        chatLabel.attributedText = NSAttributedString(string: chatPlaceholder, config: .tinyAssist)
        chatLabel.textColor = color
        chatInputVC.setPlaceholder(inputVCPlaceholer)
        landscapeInputVC?.setPlaceholder(inputVCPlaceholer)
    }

    // MARK: - Private

    /// 横屏模式下悬浮面板是否在刘海屏一侧
    private var isOnSafeAreaSide: Bool {
        let left = view.orientation == .landscapeRight && panelLocation == .left
        let right = view.orientation == .landscapeLeft && panelLocation == .right
        return Display.iPhoneXSeries && (left || right)
    }

    private func updatePanelStyle() {
        updatePanelCorner()
        let floatingBackgroundColor: UIColor
        switch panelState {
        case .expanded:
            floatingBackgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
            arrowButton.isHiddenInStackView = true
            interactionView.isHiddenInStackView = false
            interactionView.layer.cornerRadius = 0
            interactionView.layer.borderWidth = 0
            interactionView.alpha = 1
            interactionView.backgroundColor = .clear
            floatingStackView.snp.updateConstraints { make in
                make.edges.equalToSuperview()
            }
            leftFloatingView.snp.remakeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.width.equalToSuperview().dividedBy(2).offset(1)
            }
        case .collapsed:
            floatingBackgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
            arrowButton.isHiddenInStackView = false
            interactionView.isHiddenInStackView = true
            interactionView.alpha = 0
            if panelLocation == .left {
                arrowButton.setImage(Self.rightArrowImage, for: .normal)
            } else {
                arrowButton.setImage(Self.leftArrowImage, for: .normal)
            }
            if isOnSafeAreaSide {
                leftFloatingView.snp.remakeConstraints { make in
                    make.left.top.bottom.equalToSuperview()
                    make.width.equalToSuperview().dividedBy(2).offset(1)
                }
            } else {
                leftFloatingView.snp.remakeConstraints { make in
                    make.left.top.bottom.equalToSuperview()
                    make.width.equalTo(panelLocation == .left ? 4 : 20)
                }
            }
            floatingStackView.snp.updateConstraints { make in
                make.left.right.equalToSuperview().inset(isOnSafeAreaSide ? 6 : 4)
                make.top.bottom.equalToSuperview()
            }
        case .dragging:
            floatingBackgroundColor = UIColor.ud.bgContentBase
            arrowButton.isHiddenInStackView = false
            interactionView.isHiddenInStackView = false
            interactionView.alpha = 1
            interactionView.layer.cornerRadius = 8
            interactionView.layer.borderWidth = 0.5
            interactionView.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
            arrowButton.removeFromSuperview()
            if panelLocation == .left {
                arrowButton.setImage(Self.leftArrowImage, for: .normal)
                floatingStackView.insertArrangedSubview(arrowButton, belowArrangedSubview: interactionView)
            } else {
                arrowButton.setImage(Self.rightArrowImage, for: .normal)
                floatingStackView.insertArrangedSubview(arrowButton, aboveArrangedSubview: interactionView)
            }
            floatingStackView.snp.updateConstraints { make in
                make.edges.equalToSuperview().inset(4)
            }
            leftFloatingView.snp.remakeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.width.equalToSuperview().dividedBy(2).offset(1)
            }
        }
        [leftFloatingView, rightFloatingView].forEach { $0.backgroundColor = floatingBackgroundColor }
    }

    private func updatePanelCorner() {
        switch panelState {
        case .expanded, .collapsed:
            if isOnSafeAreaSide {
                leftFloatingView.layer.cornerRadius = 8
                rightFloatingView.layer.cornerRadius = 8
            } else if panelLocation == .left {
                leftFloatingView.layer.cornerRadius = 0
                rightFloatingView.layer.cornerRadius = 8
            } else {
                leftFloatingView.layer.cornerRadius = 8
                rightFloatingView.layer.cornerRadius = 0
            }
        case .dragging:
            leftFloatingView.layer.cornerRadius = 8
            rightFloatingView.layer.cornerRadius = 8
        }
    }

    private func updateFloatingViewPosition(_ position: CGPoint, _ f: String = #function) {
        panelLocation = position.x + floatingContainerView.frame.width / 2 > view.bounds.width / 2 ? .right : .left
        floatingContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(position.y).priority(.high)
            make.left.equalToSuperview().offset(position.x)
            make.top.greaterThanOrEqualTo(interactionLayoutGuide)
            make.bottom.lessThanOrEqualTo(interactionLayoutGuide)
        }
    }

    private func updateFloatingViewHidden() {
        // containerIsHidden 控制表情悬浮按钮临时隐藏 or 显示
        floatingContainerView.isHidden = containerIsHidden
        // 以下变量控制整个 view 是否在可以显示的状态
        let isHidden = isFullScreen || isSingleVideo
        if Display.pad {
            view.isHidden = isHidden || !viewModel.isToolBarReactionHidden
        } else {
            view.isHidden = isHidden
        }

        if view.isHidden {
            floatingButtonGuideToken?.invalidate()
            floatingButtonGuideToken = nil
        } else if floatingButtonGuideToken == nil {
            floatingButtonGuideToken = container?.layoutContainer.registerAnchor(anchor: .reactionButton)
            floatingButtonGuideToken?.layoutGuide.snp.remakeConstraints({ make in
                make.left.right.bottom.equalTo(initialLayoutGuide)
                make.height.equalTo(Layout.floatingHeight)
            })
        }
    }

    /// 布局更新完成以后，如果浮动面板距离底部间距小于默认边距，则初始化其位置。
    /// 场景为如果用户拖动过面板（此时约束已经记录了面板的最新位置），然后会中开启共享（或字幕等），出现共享栏，
    /// 浮动面板距离共享栏距离可能过近，因此此时将面板调回到对应场景的默认位置
    private func checkFloatingPanelOverlay() {
        let originalFrame = floatingContainerView.frame
        let shouldResetPosition: Bool
        if let interpreterGuide = interpreterGuide, !view.isLandscape && isInterpreting {
            shouldResetPosition = originalFrame.maxY >= interpreterGuide.layoutFrame.maxY - 44 - 8 - floatingBottomPadding
        } else {
            shouldResetPosition = originalFrame.maxY >= interactionLayoutGuide.layoutFrame.maxY - floatingBottomPadding
        }
        if shouldResetPosition {
            resetFloatingViewPosition()
        } else {
            updateFloatingViewPosition(originalFrame.origin)
        }
    }

    private func setupChatInputKeyboardGuide() {
        guard let guide = chatInputKeyboardGuide, guide.canUse(on: view) else { return }
        guide.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.lessThanOrEqualTo(chatInputVC.view.snp.top)
            make.bottom.equalTo(chatInputVC.view.snp.top).priority(.veryHigh)
            if let landscapeInputVC = landscapeInputVC {
                make.bottom.lessThanOrEqualTo(landscapeInputVC.view.snp.top)
                make.bottom.equalTo(landscapeInputVC.view.snp.top).priority(.veryHigh)
            }
        }
    }

    private func showReactionPanel(at anchor: UIView) {
        if isReactionExpanded {
            return
        }
        viewModel.updateRecentEmoji()
        MeetingTracksV2.trackClickUnfoldReaction()
        blockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()

        reactionButton.isSelected = true
        panelView.isHidden = false
        triangleView.isHidden = false
        let arrowHeight: CGFloat = 13
        let panelPadding = 12 + arrowHeight
        let leftPadding = self.floatingLeftPadding

        // 提前展开一级面板，动画只有透明度变化，没有大小变化
        panelView.snp.remakeConstraints { make in
            make.centerX.equalTo(anchor).priority(.medium)
            make.left.greaterThanOrEqualTo(leftPadding)
            make.bottom.equalTo(anchor.snp.top).offset(-panelPadding)
            make.width.equalTo(FloatingReactionPanelView.reactionPanelWidth)
            make.height.equalTo(panelHeightLayoutGuide)
        }
        panelView.updateExpandDirection(isUpward: true)
        triangleView.snp.remakeConstraints { make in
            make.top.equalTo(panelView.snp.bottom)
            make.centerX.equalTo(anchor).priority(.medium)
            make.left.greaterThanOrEqualTo(panelView)
            make.right.lessThanOrEqualTo(panelView)
            make.height.equalTo(arrowHeight)
            make.width.equalTo(47)
        }
        updateAllowSendReaction()
        triangleView.setNeedsDisplay()
        panelView.superview?.layoutIfNeeded()
        panelView.resetScrollPosition()

        panelView.alpha = 0
        triangleView.alpha = 0
        UIView.animate(withDuration: Self.animationDuration, animations: {
            self.panelView.alpha = 1
            self.triangleView.alpha = 1
            self.isReactionExpanded = true
        }, completion: { [weak self] _ in
            self?.isReactionExpanded = true
            ChatTracksV2.trackShowReactionView()
        })
    }

    private func showReactionPanel() {
        guard let contentGuide = contentGuide, !isReactionExpanded else {
            return
        }
        viewModel.updateRecentEmoji()
        MeetingTracksV2.trackClickUnfoldReaction()
        blockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()

        reactionButton.isSelected = true
        panelView.isHidden = false

        let panelPadding = Layout.panelPadding
        let leftPadding = self.floatingLeftPadding

        // 根据上方下方可用空间大小决定展开方向
        let topUsableSpace = floatingContainerView.frame.minY - panelPadding - interactionLayoutGuide.layoutFrame.minY
        // 优先向上展开一级菜单，不考虑一级菜单两边都展不开的情况
        let shouldExpandUpward = topUsableSpace > panelView.recentViewIntrinsicHeight

        Self.logger.info("FloatingReactionPanelView will expand reation panel: panelView.frame = \(panelView.frame), isSharing = \(isSharing), contentLayoutGuideFrame: \(contentGuide.layoutFrame), shouldExpandUpward = \(shouldExpandUpward)")

        // 提前展开一级面板，动画只有透明度变化，没有大小变化
        panelView.snp.remakeConstraints { make in
            if VCScene.bounds.width > FloatingReactionPanelView.reactionPanelWidth + 2 * leftPadding {
                if self.panelLocation == .left {
                    make.left.equalTo(floatingContainerView).inset(leftPadding)
                } else {
                    make.right.equalTo(floatingContainerView).inset(leftPadding)
                }
            } else {
                make.centerX.equalToSuperview()
            }
            make.width.equalTo(FloatingReactionPanelView.reactionPanelWidth)
            if shouldExpandUpward {
                make.bottom.equalTo(floatingContainerView.snp.top).offset(-panelPadding).priority(.medium)
            } else {
                make.top.equalTo(floatingContainerView.snp.bottom).offset(panelPadding).priority(.medium)
            }
            make.top.greaterThanOrEqualTo(interactionLayoutGuide).inset(currentLayoutContext.layoutType.isPhoneLandscape ? Layout.verticalPadding : 0)
            make.bottom.lessThanOrEqualTo(interactionLayoutGuide)

            make.height.equalTo(panelHeightLayoutGuide)
        }
        updateAllowSendReaction()
        // 表情面板内部不再需要区分展开方向，直接写死 true
        panelView.updateExpandDirection(isUpward: true)
        panelView.superview?.layoutIfNeeded()
        panelView.resetScrollPosition()

        // 动画展开 reaction 面板
        UIView.animate(withDuration: Self.animationDuration, animations: {
            self.panelView.alpha = 1
            self.isReactionExpanded = true
        }, completion: { _ in
            ChatTracksV2.trackShowReactionView()
        })
    }

    private func hideReactionPanel() {
        guard isReactionExpanded else { return }
        reactionButton.isSelected = false
        MeetingTracksV2.trackClickFoldReaction()

        UIView.animate(withDuration: Self.animationDuration, animations: {
            self.panelView.alpha = 0
            self.triangleView.alpha = 0
        }, completion: { _ in
            self.panelView.snp.removeConstraints()
            self.panelView.isHidden = true
            self.triangleView.isHidden = true
            self.isReactionExpanded = false
            self.blockFullScreenToken = nil
        })
    }

    private func generateImpactFeedback() {
        if Display.phone {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func autoLocateFloatingContainerView(velocity: CGPoint) {
        let threshold: CGFloat = Layout.shrinkThreshold
        let leftEdge = interactionLayoutGuide.layoutFrame.minX
        let rightEdge = interactionLayoutGuide.layoutFrame.maxX
        let leftDistanceCheck = floatingContainerView.frame.minX <= leftEdge - threshold
        let leftVelocityCheck = floatingContainerView.frame.minX <= leftEdge && velocity.x <= -1000
        let rightDistanceCheck = floatingContainerView.frame.maxX >= rightEdge + threshold
        let rightVelocityCheck = floatingContainerView.frame.maxX >= rightEdge && velocity.x >= 1000
        let isCollapseLeftward = leftDistanceCheck || leftVelocityCheck
        let isCollapseRightward = rightDistanceCheck || rightVelocityCheck
        UIView.animate(withDuration: Self.animationDuration, delay: 0, options: [], animations: {
            self.floatingContainerView.snp.remakeConstraints { make in
                if self.floatingContainerView.frame.midX <= self.view.frame.width / 2 {
                    make.left.equalTo(self.interactionLayoutGuide).offset(-0.5)
                } else {
                    make.right.equalTo(self.interactionLayoutGuide).offset(0.5)
                }
                make.top.equalTo(self.floatingContainerView.frame.minY)
            }
            if  isCollapseLeftward || isCollapseRightward {
                self.panelState = .collapsed
            } else {
                self.panelState = .expanded
            }
            self.view.layoutIfNeeded()
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            VCTracker.post(name: .vc_meeting_chat_reaction_click,
                           params: [.click: "haul_reaction",
                                    "haul_location": self.panelLocation == .left ? "left" : "right",
                                    "if_fold": self.panelState == .collapsed ? "true" : "false"])
        })
    }

    private func updateInteractionViewAlpha() {
        let minX = floatingContainerView.frame.minX
        let maxX = floatingContainerView.frame.maxX
        let b: CGFloat = Layout.shrinkThreshold
        let k: CGFloat = 80
        let alpha: CGFloat
        if minX < 0 {
            alpha = min(max(1 + (b + minX) / k, 0), 1)
        } else if maxX > view.frame.width {
            alpha = max(1 - (maxX - view.frame.width - b) / k, 0)
        } else {
            alpha = 1.0
        }
        interactionView.alpha = alpha
    }

    private func updateAllowSendReaction() {
        if panelView.allowSendReaction != viewModel.allowSendReaction {
            panelView.allowSendReaction = viewModel.allowSendReaction
            if viewModel.meeting.isWebinarAttendee && !viewModel.allowSendReaction {
                hideReactionPanel()
            } else {
                updatePanelHeightLayoutGuide()
            }
        }
    }

    private func updatePanelHeightLayoutGuide() {
        panelHeightLayoutGuide.snp.remakeConstraints { make in
            if viewModel.allowSendReaction {
                if Display.pad || currentLayoutContext.layoutType.isCompact {
                    // 竖屏下或 iPad 下固定高度 400
                    make.height.equalTo(400)
                } else {
                    // 刘海屏且非共享状态时，底部距离是安全区高度，已经在 interactionLayoutGuide 中减掉了
                    let padding = Display.iPhoneXSeries && !isSharing ? -Layout.verticalPadding : -2 * Layout.verticalPadding
                    make.height.equalTo(interactionLayoutGuide).offset(padding)
                }
            } else {
                make.height.equalTo(panelView.recentViewIntrinsicHeight)
            }
        }
    }

    // MARK: - Guide

    private func showInteractionGuide() {
        guard viewModel.meeting.service.shouldShowGuide(.interactionFloatingPanel), currentLayoutContext.layoutType != .regular else {
            return
        }

        containerIsHidden = true
        isAnimating = true
        view.layoutIfNeeded()
        floatingContainerView.transform = CGAffineTransform(translationX: -floatingContainerView.frame.width, y: 0)
        let guideView = GuideView(frame: view.bounds)
        guideView.isHidden = true
        guideView.alpha = 0
        guideView.sureAction = { [weak self, weak guideView] _ in
            self?.didGuideSureAction(guideView)
        }
        guideSureAction = { [weak self, weak guideView] in
            self?.didGuideSureAction(guideView)
        }
        view.addSubview(guideView)
        guideView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        UIView.animate(withDuration: Self.guideAnimationDuration, delay: Self.guideAnimationDelay, usingSpringWithDamping: Self.springDamping, initialSpringVelocity: 0.0, options: [], animations: {
            self.containerIsHidden = false
            self.floatingContainerView.transform = .identity
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.isShowingGuide = true
            self.isAnimating = false
            self.guideBlockFullScreenToken = self.viewModel.fullScreenDetector?.requestBlockAutoFullScreen()
            guideView.isHidden = false
            guideView.setStyle(.darkPlain(content: I18n.View_G_SwipeLeftHide), on: .top, of: self.floatingContainerView)
            UIView.animate(withDuration: Self.animationDuration, animations: {
                guideView.alpha = 1
            })
        })
    }

    private func didGuideSureAction(_ guideView: GuideView?) {
        isShowingGuide = false
        guideBlockFullScreenToken = nil
        guideView?.removeFromSuperview()
        viewModel.meeting.service.didShowGuide(.interactionFloatingPanel)
    }

    // MARK: - Actions

    @objc
    private func handleReactionButtonClick() {
        VCTracker.post(name: .vc_meeting_chat_send_message_click,
                       params: [.click: "unfold_reaction",
                                .target: "vc_meeting_chat_send_message_view"])
        guard !viewModel.meeting.isWebinarAttendee || viewModel.allowSendReaction else {
            Toast.show(I18n.View_G_HostNotAllowEmoji)
            return
        }
        showReactionPanel()
        generateImpactFeedback()
    }

    @objc
    private func handleArrowButtonClick() {
        if panelState == .collapsed {
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "unfold_reaction_message_button"])
            UIView.animate(withDuration: Self.animationDuration, delay: 0, options: [], animations: {
                self.panelState = .expanded
            })
        }
    }

    @objc func handleTap() {
        hideReactionPanel()
        chatInputVC.textView.resignFirstResponder()
        landscapeInputVC?.textField.resignFirstResponder()
    }

    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)

        switch recognizer.state {
        case .began:
            // 从收起状态进入拖拽状态时，要保持箭头的位置不变
            let oldState = panelState
            // 先记录之前箭头的位置
            let oldRect = arrowButton.convert(arrowButton.bounds, to: view)
            // 状态切换，并更新 UI，此时由于前面 interactionView 出现，floatingContainerView 的宽度增加
            panelState = .dragging
            view.layoutIfNeeded()
            // 获取新状态下箭头的位置
            let newRect = arrowButton.convert(arrowButton.bounds, to: view)
            // 获取需要偏移的距离
            let distance = oldState == .collapsed ? newRect.minX - oldRect.minX : 0
            let origin = floatingContainerView.frame.origin
            // 记录起始位置为偏移后的位置（只有 oldState 为拖拽状态是需要偏移），并更新 floatingContainerView 的位置
            panStartingPoint = CGPoint(x: origin.x - distance, y: origin.y)
            updateFloatingViewPosition(panStartingPoint)
            hasMovedPanel = true
            panBlockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()
            generateImpactFeedback()
        case .changed:
            let targetPosition = CGPoint(x: panStartingPoint.x + point.x, y: panStartingPoint.y + point.y)
            updateFloatingViewPosition(targetPosition)
            updateInteractionViewAlpha()
        case .ended, .cancelled:
            autoLocateFloatingContainerView(velocity: velocity)
            panBlockFullScreenToken = nil
        default:
            break
        }
    }

    @objc
    private func showChatInput() {
        guard viewModel.isChatEnabled() else { return }
        VCTracker.post(name: .vc_meeting_chat_send_message_click,
                       params: [.click: "unfold_reaction",
                                .target: "vc_meeting_chat_send_message_view"])
        viewModel.createMeetingGroupIfNeeded()
        if currentLayoutContext.layoutType.isPhoneLandscape {
            landscapeInputVC?.textField.becomeFirstResponder()
        } else {
            chatInputVC.textView.becomeFirstResponder()
        }
    }

    // MARK: - Notifications

    @objc
    private func handleKeyboardShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let editView: UIView
        if currentLayoutContext.layoutType.isPhoneLandscape {
            guard let inputVC = landscapeInputVC, inputVC.textField.isFirstResponder else { return }
            editView = inputVC.view
            inputVC.setText(viewModel.context.chatRecordText)
        } else {
            guard chatInputVC.textView.isFirstResponder else { return }
            editView = chatInputVC.view
            chatInputVC.setText(viewModel.context.chatRecordText)
        }

        editView.isHidden = false
        containerIsHidden = true
        let converted = view.convert(endFrame, from: nil)

        self.blockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()
        var slideOverBottomInset: CGFloat = 0
        if let w = self.view.window {
            let frame = w.convert(w.bounds, to: w.screen.coordinateSpace)
            slideOverBottomInset = w.screen.bounds.height - frame.maxY
        }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
            editView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.lessThanOrEqualTo(self.view).inset(converted.height - slideOverBottomInset)
                make.bottom.equalTo(self.view).inset(converted.height - slideOverBottomInset).priority(.veryHigh)
                if Display.pad, let contentGuide = self.contentGuide {
                    // 键盘收起状态时的高度
                    make.bottom.lessThanOrEqualTo(contentGuide.snp.bottom)
                }
            }
            (self.chatInputKeyboardGuide?.owningView ?? self.view).layoutIfNeeded()
        }, completion: { [weak self] _ in
            self?.chatInputVC.fixMenuOrientation()
            self?.landscapeInputVC?.fixMenuOrientation()
            VCTracker.post(name: .vc_meeting_chat_send_message_view,
                           params: [.from_source: "onthecall_fold_button"])
        })
    }

    @objc
    private func handleKeyboardHide(_ notification: Notification) {
        guard let info = notification.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        containerIsHidden = false
        let option = UIView.AnimationOptions(rawValue: curve << 16)
        UIView.animate(withDuration: duration, delay: 0, options: option, animations: {
            self.chatInputVC.view.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.view.snp.bottom)
            }
            self.landscapeInputVC?.view.snp.remakeConstraints({ make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.view.snp.bottom)
            })
            (self.chatInputKeyboardGuide?.owningView ?? self.view).layoutIfNeeded()
        }, completion: { [weak self] _ in
            self?.chatInputVC.view.isHidden = true
            self?.landscapeInputVC?.view.isHidden = true
            self?.blockFullScreenToken = nil
        })

    }

    @objc
    private func handleAppResignActive(_ notification: Notification) {
        chatInputVC.textView.resignFirstResponder()
        landscapeInputVC?.textField.resignFirstResponder()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == tapGestureRecognizer else { return true }
        let location = gestureRecognizer.location(in: view)
        let converted = view.convert(location, to: panelView)
        return !panelView.bounds.contains(converted)
    }
}

extension FloatingInteractionViewController: FloatingInteractionViewModelDelegate {
    func toolbarReactionVisibilityDidChange() {
        if Display.pad {
            updateFloatingViewHidden()
        }
    }

    func recentReactionsDidChange(reactions: [ReactionEntity]) {
        panelView.recentReactions = reactions
    }

    func allReactionsDidChange(reactions: [Emojis]) {
        panelView.allReactions = reactions
    }

    func didChangeStatusReaction(info: ParticipantSettings.ConditionEmojiInfo?) {
        guard let info = info else { return }
        if info.isStepUp ?? false {
            panelView.statusReactionsView.status = .quickLeave
        } else if info.isHandsUp ?? false {
            panelView.statusReactionsView.status = .raiseHand
        } else {
            panelView.statusReactionsView.status = .none
        }
    }

    func didChangePanelistPermission(isUpdateMessage: Bool) {
        if isUpdateMessage {
            updateChatPlaceholder()
        } else {
            updateAllowSendReaction()
        }
    }

    func didUpdateHandsUpSkin(key: String) {
        panelView.statusReactionsView.updateHandsUpSkin(key: key)
    }

    func didChangeWhiteboardOperateStatus(isOpaque: Bool) {
        DispatchQueue.main.async {
            // disable-lint: magic number
            let alpha: CGFloat = isOpaque ? 1 : 0.3
            UIView.animate(withDuration: 0.25, animations: {
                self.floatingContainerView.alpha = alpha
            })
        }
        // enable-lint: magic number
    }
}

extension FloatingInteractionViewController: FloatingReactionPanelViewDelegate {

    func reactionPanelDidSelectReaction(reactionKey: String, isRecent: Bool) {
        MeetingTracksV2.trackClickSendReaction(reactionKey, location: "send_reaction_view", isRecent: isRecent, isChangeSkin: viewModel.isChangeSkin(reactionKey))
        viewModel.isLongPress = false
        viewModel.sendReaction(reactionKey)
        hideReactionPanel()
        generateImpactFeedback()
    }

    func reactionPanelDidLongPressReaction(reactionKey: String, isRecent: Bool) {
        MeetingTracksV2.trackClickSendReaction(reactionKey, location: "send_reaction_view", isRecent: isRecent, isChangeSkin: viewModel.isChangeSkin(reactionKey))
        viewModel.isLongPress = true
        viewModel.sendReaction(reactionKey)
        generateImpactFeedback()
    }

    func reactionPanelDidFinishLongPress() {
        viewModel.isLongPress = false
        hideReactionPanel()
    }

    func statusPanelDidSelectRaiseHand(isChangeSkin: Bool) {
        let status = panelView.statusReactionsView.status
        let skinKey = panelView.statusReactionsView.selectedHandsUpEmojiKey

        if status == .raiseHand && !isChangeSkin {
            MeetingTracksV2.trackClickConditionEmoji("hands_down", location: "send_reaction_view")
            panelView.statusReactionsView.status = .none
            viewModel.raiseHand(isHandsUp: false, handsUpEmojiKey: skinKey)
        } else {
            MeetingTracksV2.trackClickConditionEmoji("hands_up", location: "send_reaction_view", isChangeSkin: isChangeSkin)
            MeetingTracksV2.trackClickSendReaction(skinKey, location: "send_reaction_view", isRecent: false, isChangeSkin: isChangeSkin)
            MeetingTracksV2.trackHandsUpEmojiHoldDown(skinKey: skinKey)
            panelView.statusReactionsView.status = .raiseHand
            viewModel.raiseHand(isHandsUp: true, handsUpEmojiKey: skinKey)
        }

        hideReactionPanel()
    }

    func statusPanelDidSelectQuickLeave() {
        let status = panelView.statusReactionsView.status
        if status == .quickLeave {
            MeetingTracksV2.trackClickConditionEmoji("back", location: "send_reaction_view")
        } else {
            MeetingTracksV2.trackClickConditionEmoji("leave", location: "send_reaction_view")
        }
        panelView.statusReactionsView.status = status == .quickLeave ? .none : .quickLeave
        viewModel.quickLeave(isStepUp: status != .quickLeave)
        hideReactionPanel()
    }
}

extension FloatingInteractionViewController: VCMenuViewDelegate {
    func menuView(_ menu: VCMenuView, shouldRespondTouchAt point: CGPoint) -> VCMenuViewHitTestResult {
        if isShowingGuide {
            return .default
        } else if isReactionExpanded {
            let converted = menu.convert(point, to: panelView)
            if panelView.hitTest(converted, with: nil) != nil {
                return .default
            } else {
                return .custom(view)
            }
        } else if chatInputVC.textView.isFirstResponder {
            let converted = menu.convert(point, to: chatInputVC.view)
            if chatInputVC.view.hitTest(converted, with: nil) != nil {
                return .default
            } else {
                return .custom(view)
            }
        } else if let inputVC = landscapeInputVC, inputVC.textField.isFirstResponder {
            let converted = menu.convert(point, to: inputVC.view)
            if inputVC.view.hitTest(converted, with: nil) != nil {
                return .default
            } else {
                return .custom(view)
            }
        } else {
            let converted = menu.convert(point, to: floatingContainerView)
            if floatingContainerView.hitTest(converted, with: nil) != nil {
                return .default
            } else {
                return .ignore
            }
        }
    }
}

extension FloatingInteractionViewController: MeetingLayoutStyleListener {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        isFullScreen = container.meetingLayoutStyle == .fullscreen
        updateFloatingViewHidden()
        if !isFullScreen && !hasMovedPanel {
            resetFloatingViewPosition()
        }
        if currentLayoutContext.layoutType == .phoneLandscape {
            updatePanelHeightLayoutGuide()
        }
    }
}

extension FloatingInteractionViewController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .singleVideo:
            guard let isSingleVideo = userInfo as? Bool else { return }
            self.isSingleVideo = isSingleVideo
            updateFloatingViewHidden()
        case .contentScene:
            guard let container = self.container else { return }
            let meetingContent = container.context.meetingContent
            isSharing = meetingContent != .flow && meetingContent != .selfShareScreen
            if Display.pad, self.meetingScene != container.context.meetingScene {
                self.meetingScene = container.context.meetingScene
            }
            updateInteractionLayoutGuide()
            if !hasMovedPanel {
                resetFloatingViewPosition()
            }
        case .flowPageControl:
            if !hasMovedPanel {
                resetFloatingViewPosition()
            }
        case .whiteboardMenu:
            isWhiteboardMenuEnable = userInfo as? Bool ?? false
            if Display.pad {
                resetFloatingViewPosition()
            }
        case .subtitle:
            isSubtitleOn = container?.context.isSubtitleVisible ?? false
            if !hasMovedPanel {
                resetFloatingViewPosition()
            }
        default:
            break
        }

        if currentLayoutContext.layoutType == .phoneLandscape {
            updatePanelHeightLayoutGuide()
        }
    }
}

extension FloatingInteractionViewController: ChatInputViewControllerDelegate {
    func chatInputViewDidPressReturnKey(text: String) {
        guard !text.isEmpty else { return }
        VCTracker.post(name: .vc_meeting_chat_send_message_click,
                       params: [.click: "send_message",
                                .location: "onthecall_fold_button"])
        viewModel.sendMessage(text)
        chatInputVC.clearText()
        chatInputVC.textView.resignFirstResponder()
        landscapeInputVC?.clearText()
        landscapeInputVC?.textField.resignFirstResponder()
    }

    func chatInputViewTextDidChange(to text: String) {
        viewModel.updateUnsendText(text)
    }
}

extension FloatingInteractionViewController: InMeetInterpreterViewModelObserver {
    func selfInterpreterSettingDidChange(_ setting: InterpreterSetting?) {
        Util.runInMainThread {
            let isInterpreting = setting?.isUserConfirm ?? false
            guard self.isInterpreting != isInterpreting else { return }
            self.isInterpreting = isInterpreting
            if !self.view.isLandscape && !self.hasMovedPanel {
                self.resetFloatingViewPosition()
            }
        }
    }
}

// 解决左侧或右侧 border 隐藏问题
private class HalfView: UIView {
    let customMask = UIView()
    let isLeft: Bool

    init(isLeftSide: Bool) {
        self.isLeft = isLeftSide
        super.init(frame: .zero)
        customMask.backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        customMask.frame = CGRect(x: isLeft ? 0 : 1, y: 0, width: bounds.width - 1, height: bounds.height)
        mask = customMask
    }
}
