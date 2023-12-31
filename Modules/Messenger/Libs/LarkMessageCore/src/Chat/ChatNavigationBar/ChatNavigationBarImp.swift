//
//  ChatNavigationBarImp.swift
//  Lark
//
//  Created by ChalrieSu on 23/03/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import RxCocoa
import LarkModel
import SnapKit
import LarkTag
import LarkCore
import EENavigator
import LarkBadge
import LarkFocus
import LarkBizTag
import LarkMessengerInterface
import LarkSetting
import UniverseDesignToast
import LKContentFix
import LarkInteraction
import LarkSplitViewController
import LarkSceneManager
import TangramService
import FigmaKit
import UniverseDesignIcon
import UniverseDesignShadow
import LarkEmotion
import LarkOpenChat
import UniverseDesignColor

/// 关于导航栏写在前面:
/// -------------------------------------------------------------
/// |  「 leftItems 」 --- 「 titleView 」 ---- 「 rightItems 」   |
/// -------------------------------------------------------------
/// chat的导航栏ChatNavigationBarImp，布局和通用的导航栏布局是不一样的，思路如下
/// 1. 普通导航栏
/// titleView占据最中间，然后左右两侧各自布局UI按钮
///     优点：比较符合我们的认知
///     缺点: 如果左侧按钮较多，右侧很少，就会显的左边很拥挤，标题也会被压缩，但是右边确很空
/// 2. chat的导航栏
///     基于上面的1，某天KDM反馈之后，做了优化(主要是参考了teams的设计)
///     左右两侧的按钮优先展示，然后剩余的空间中 居中展示titleView，如果展示不下 压缩titleview的内容
///     优点：能展示更多的内容，充分利用了空间
///     缺点：一些特殊的场景，比如右侧一个按钮也没有，标题不居中(屏幕的中)
/// -------------------------------------------------------------
///  两种方案各有优缺点，当前ChatNavigationBarImp使用方案2
struct ChatNavigationStyleConfig {

    var rightItemSpace: CGFloat {
        return showLeftStyle ? 20 : 16
    }

    var titleLeftMargin: CGFloat {
        return showLeftStyle ? 6 : 16
    }

    let showLeftStyle: Bool

    init(showLeftStyle: Bool) {
        self.showLeftStyle = showLeftStyle
    }
}
public final class ChatNavigationBarImp: UIView, ChatNavigationBar, UIGestureRecognizerDelegate {

    public var rootPath: Path { return Path().prefix(Path().chat_id, with: self.viewModel.chat.id) }

    public var statusBarStyle: UIStatusBarStyle {
        if self.darkStyle {
            return UIStatusBarStyle.lightContent
        } else {
             return UIStatusBarStyle.default
        }
    }
    public var naviBarHeight: CGFloat = Display.pad ? 60 : 44
    public var leastTopMargin: CGFloat = 0 { //最小上边距。避免当（modalView等情况下）safeAreaLayoutGuide为0时，顶到头太丑
        didSet {
            guard contentView.superview != nil else { return }
            contentView.snp.updateConstraints { (make) in
                make.top.greaterThanOrEqualToSuperview().offset(self.leastTopMargin).priority(.required)
            }
        }
    }

    lazy var styleConfig: ChatNavigationStyleConfig = {
        return ChatNavigationStyleConfig(showLeftStyle: viewModel.showLeftStyle)
    }()

    /// bar 初始背景色
    private let navigationBarBackgroundColor: UIColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.75) & UIColor.ud.staticBlack.withAlphaComponent(0.75)

    public weak var delegate: ChatNavigationBarDelegate?

    public var contentTop: ConstraintItem {
        return contentView.snp.top
    }
    public var centerView: UIView?

    private let disposeBag = DisposeBag()
    private let viewModel: ChatNavigationBarViewModel
    private var naviBarWidth: CGFloat = 0
    private let blurEnabled: Bool

    private let darkStyle: Bool

    /// 是否展示浮出的返回按钮
    private var needShowFloatBack: Bool = true

    // MARK: - Lazy UI
    private lazy var containView: UIView = {
        if blurEnabled {
            let containView = BackgroundBlurView()
            containView.blurRadius = 25
            return containView
        } else {
            return UIView()
        }
    }()

    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.clear
        contentView.addGestureRecognizer(panGestureRecognizer)
        return contentView
    }()
    private var panHandler: ((UIPanGestureRecognizer) -> Void)?
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGes))
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }()

    private lazy var chatTitleLayoutGuide = UILayoutGuide()

    private let leftButtonsStackView = ExpandTouchStackView()
    private let rightButtonsStackView = UIStackView()

    private lazy var floatBackButton: ChatFloatBackButton = {
        let button = ChatFloatBackButton()
        button.addPointerStyle()
        button.alpha = 0
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self, weak button] (_) in
                guard let `self` = self, let btn = button else { return }
                self.delegate?.backItemClicked(sender: btn)
            })
            .disposed(by: disposeBag)
        return button
    }()

    private var rightButtonWidthConstraint: Constraint?
    // MARK: - Life Cycle
    // blurEnabled: 是否启用模糊效果
    public init(viewModel: ChatNavigationBarViewModel,
                blurEnabled: Bool = true,
                darkStyle: Bool) {
        self.viewModel = viewModel
        self.blurEnabled = blurEnabled
        self.darkStyle = darkStyle
        super.init(frame: .zero)
        setupUI()
    }

    public func loadSubModuleData() {
        if viewModel.moduleAleadySetup { return }
        self.viewModel.setupModule()
        setupNavgitaonBarItems()
        setupTitleView()
        setupFloatButton()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor.clear
        containView.backgroundColor = self.navigationBarBackgroundColor
        self.addSubview(containView)
        containView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        containView.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.height.equalTo(naviBarHeight)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(self.leastTopMargin).priority(.required)
            make.top.equalTo(safeAreaLayoutGuide).priority(.high)
        }
    }

    fileprivate func setupTitleView() {
        if let centerView = self.centerView {
            centerView.removeFromSuperview()
            self.centerView = nil
        }
        guard let titleView = self.viewModel.titleView else {
            return
        }
        self.centerView = titleView
        contentView.addLayoutGuide(chatTitleLayoutGuide)
        contentView.addSubview(titleView)
        chatTitleLayoutGuide.snp.remakeConstraints { make in
            make.right.equalTo(rightButtonsStackView.snp.left).offset(-16)
            make.left.equalTo(leftButtonsStackView.snp.right).offset(self.styleConfig.titleLeftMargin)
        }
        /// 左右按钮不可以压缩，展示不下压缩内容
        titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if viewModel.showLeftStyle {
            titleView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(chatTitleLayoutGuide)
                make.right.lessThanOrEqualTo(chatTitleLayoutGuide.snp.right)
            }
        } else {
            titleView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.centerX.equalTo(chatTitleLayoutGuide)
                make.right.lessThanOrEqualTo(chatTitleLayoutGuide.snp.right)
                make.left.greaterThanOrEqualTo(chatTitleLayoutGuide.snp.left)
            }
        }
    }

    private func setupFloatButton() {
        self.insertSubview(floatBackButton, belowSubview: self.containView)
        floatBackButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(2)
            make.top.equalTo(self.contentView.snp.top)
        }
    }

    private func setupNavgitaonBarItems() {
        contentView.addSubview(leftButtonsStackView)
        leftButtonsStackView.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        leftButtonsStackView.axis = .horizontal
        leftButtonsStackView.alignment = .center
        leftButtonsStackView.distribution = .fill
        leftButtonsStackView.spacing = Display.pad ? 20 : 0
        let padding = calcButtonsStackPadding()
        leftButtonsStackView.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(padding)
        }

        contentView.addSubview(rightButtonsStackView)
        rightButtonsStackView.lu.harder()
        rightButtonsStackView.axis = .horizontal
        rightButtonsStackView.alignment = .center
        rightButtonsStackView.distribution = .fill
        rightButtonsStackView.spacing = styleConfig.rightItemSpace
        rightButtonsStackView.snp.remakeConstraints { (make) in
            rightButtonWidthConstraint = make.width.equalTo(0).constraint
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(padding)
        }
        rightButtonsStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        setupLeftItems()
        setupRightItems()
    }

    /// 根据导航栏宽度计算导航栏控件离两侧距离
    private func calcButtonsStackPadding() -> Int {
        // 设计希望不影响iPhone的视图，Pro Max宽度为428pt，iPad mini 竖2/3分屏为438pt，暂时以435作为分界
        return self.bounds.width > 435 ? 20 : 12
    }

    private func setupRightItems() {
        rightButtonWidthConstraint?.deactivate()
        rightButtonsStackView.arrangedSubviews.forEach {
            rightButtonsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let items = self.viewModel.rightItems
        for item in items {
            rightButtonsStackView.addArrangedSubview(item.view)
            item.view.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        // 申请加群视图右侧无按钮,约束会出现异常,需要手动适配一下
        if items.isEmpty {
            rightButtonWidthConstraint?.activate()
        }
    }

    private func setupLeftItems() {
        leftButtonsStackView.subviews.forEach { (view) in
            leftButtonsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        self.needShowFloatBack = false
        self.viewModel.leftItems.forEach { item in
            if item.type == .back {
                self.needShowFloatBack = true
            }
        }
        self.viewModel.leftItems.forEach { item in
            item.view.setContentCompressionResistancePriority(.required, for: .horizontal)
            leftButtonsStackView.addArrangedSubview(item.view)
        }
    }

    private func cleanStackView() {
        leftButtonsStackView.subviews.forEach { (view) in
            leftButtonsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        rightButtonsStackView.subviews.forEach { (view) in
            rightButtonsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func reloadNavgitaonBarItems() {
        cleanStackView()
        setupNavgitaonBarItems()
        setupTitleView()
    }

    @objc
    private func panGes(_ getsture: UIPanGestureRecognizer) {
        self.panHandler?(getsture)
    }

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if panGestureRecognizer == gestureRecognizer {
            return self.panHandler != nil
        }
        return true
    }

    public func show(style: NavigationBarStyle, animateDuration: TimeInterval) {
        switch style {
        case .normal:
            UIView.animate(withDuration: animateDuration, animations: {
                if self.darkStyle {
                    self.delegate?.changeStatusBarStyle(UIStatusBarStyle.lightContent)
                }
                self.containView.alpha = 1
                self.containView.transform = .identity
                self.floatBackButton.alpha = 0
            })
        case .floatButtons(let floatButtons, let translationY):
            UIView.animate(withDuration: animateDuration, animations: {
                if self.darkStyle {
                    self.delegate?.changeStatusBarStyle(UIStatusBarStyle.default)
                }
                self.containView.alpha = 0
                self.containView.transform = CGAffineTransform(translationX: 0, y: translationY)
                if self.needShowFloatBack, floatButtons.contains(.backButton) {
                    self.floatBackButton.alpha = 1
                } else {
                    self.floatBackButton.alpha = 0
                }
            })
        }
    }

    public func showMultiSelectCancelItem(_ isShow: Bool) {
        self.viewModel.multiSelecting = isShow
    }

    public func viewWillAppear() {
        self.viewModel.viewWillAppear()
    }

    /// VC viewDidAppear
    public func viewDidAppear() {
        self.viewModel.viewDidAppear()
    }

    public func viewWillRealRenderSubView() {
        self.viewModel.viewWillRealRenderSubView()
    }

    public func afterMessagesRender() {
        self.viewModel.viewFinishedMessageRender()
    }

    public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.viewModel.viewWillTransition(to: size, with: coordinator)
    }

    public func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        self.viewModel.splitSplitModeChange()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if naviBarWidth != self.bounds.width {
            naviBarWidth = self.bounds.width
            let padding = calcButtonsStackPadding()
            leftButtonsStackView.snp.updateConstraints {
                $0.left.equalToSuperview().inset(padding)
            }
            rightButtonsStackView.snp.updateConstraints {
                $0.right.equalToSuperview().inset(padding)
            }
        }
    }

    public func setBackgroundColor(_ color: UIColor) {
        containView.backgroundColor = color
    }

    public  func setNavigationBarDisplayStyle(_ barStyle: OpenChatNavigationBarStyle) {
        self.viewModel.barStyle = barStyle
        self.viewModel.barStyleDidChange()
    }

    public func refreshRightItems() {
        self.setupRightItems()
    }

    public func navigationBarDisplayStyle() -> OpenChatNavigationBarStyle {
        return viewModel.barStyle
    }

    public func refreshLeftItems() {
        self.setupLeftItems()
    }

    public func refreshCenterContent() {
        self.setupTitleView()
    }

    public func refresh() {
        self.reloadNavgitaonBarItems()
    }

    public func getRightItem(type: ChatNavigationExtendItemType) -> ChatNavigationExtendItem? {
        self.viewModel.getRightItem(type: type)
    }

    public func getLeftItem(type: ChatNavigationExtendItemType) -> ChatNavigationExtendItem? {
        return self.viewModel.getLeftItem(type: type)
    }

    public func observePanGesture(_ panHandler: @escaping (UIPanGestureRecognizer) -> Void) {
        self.panHandler = panHandler
    }
}

final class ChatFloatBackButton: UIButton {

    private lazy var circleView: UIImageView = {
        let circleView = UIImageView(image: UDIcon.getIconByKey(.leftOutlined).ud.withTintColor(UIColor.ud.iconN1))
        circleView.backgroundColor = UIColor.ud.bgFloat
        circleView.contentMode = .center
        circleView.layer.cornerRadius = 20
        circleView.layer.ud.setShadow(type: .s3Down)
        return circleView
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.circleView.backgroundColor = UIColor.ud.udtokenBtnSeBgNeutralHover
            } else {
                self.circleView.backgroundColor = UIColor.ud.bgFloat
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(circleView)
        circleView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.top.equalToSuperview().inset(2)
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(40)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ExpandTouchStackView: UIStackView {
    public var hitTestEdgeInsets: UIEdgeInsets = .zero
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.hitTestEdgeInsets == .zero {
            return super.point(inside: point, with: event)
        }
        let relativeFrame = self.bounds
        let hitFrame = relativeFrame.inset(by: self.hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
