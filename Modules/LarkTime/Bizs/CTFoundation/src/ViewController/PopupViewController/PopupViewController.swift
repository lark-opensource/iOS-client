//
//  PopupViewController.swift
//  iOS
//
//  Created by 张威 on 2020/1/8.
//  Copyright © 2020 SadJason. All rights reserved.
//

import UIKit
import QuartzCore
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont

// MARK: - PopupViewController

/// Popup（弹窗）容器，实现类似于 Apple Map App 那样的弹窗效果；弹窗支持交互，支持转场，接口风格类似于
/// `UINavigationController`
public final class PopupViewController: UIViewController {

    // MARK: Public Properties

    /// 最上层的 item ViewController
    public private(set) var topViewController: PopupViewControllerItem? {
        didSet { updateTopViewControllerContext() }
    }

    /// 栈中的 ViewControllers
    public var viewControllers: [PopupViewControllerItem] = []

    /// 当前 popupOffset
    public var currentPopupOffset: PopupOffset {
        let rawValue = (view.bounds.height - foregroundView.frame.minY - headerHeight) / contentHeight
        return PopupOffset(rawValue: rawValue)
    }

    /// contentHeight = foregroundHeight - indicatorView.height
    public var contentHeight: CGFloat = 0

    /// C视图时展示上方指示拖动的indicator
    public var shouldShowTopIndicatorInCompact = true

    /// 弹窗交互区域背景色
    public var foregroundColor: UIColor = UIColor.ud.bgBody {
        didSet { foregroundView.backgroundColor = foregroundColor }
    }

    /// 弹窗背景色
    public var backgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5) {
        didSet { transitor.backgroundColor = backgroundColor }
    }

    /// 交互手势：拖拽调整弹窗的高度
    public var interactivePopupGestureRecognizer: UIGestureRecognizer { panGesture }

    // MARK: Private Properties

    private typealias TopViewControllerContext = (preferredPopupOffset: PopupOffset, hoverPopupOffsets: [PopupOffset])
    private typealias PanGestureRecognizerContext = (locationY: CGFloat, offset: PopupOffset)

    private var isViewAppeared = false
    private var isTransitioning = false
    private var isRotating = false
    private var naviBarHeight: CGFloat = 0
    private var headerHeight: CGFloat = 0
    private var keyboardHeight: CGFloat = 0
    private var foregroundViewHeight: CGFloat = 0
    private var panGestureBeginContext: PanGestureRecognizerContext?
    private var topViewControllerContext: TopViewControllerContext?
    private var naviBarStyle: Popup.NaviBarStyle
    private var lastHorizontalSizeClass: UIUserInterfaceSizeClass?
    private let distanceToTop: CGFloat

    private let disposeBag = DisposeBag()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()

    private let transitor = PopupTransitor()

    // MARK: Subviews

    private lazy var tapInteractiveView: UIButton = {
        let theView = UIButton()
        theView.rx.controlEvent(.touchUpInside).subscribe { [weak self] _ in
            self?.topViewController?.popupBackgroundDidClick()
        }.disposed(by: disposeBag)
        return theView
    }()

    private var foregroundViewBottomConstraint: Constraint?
    private lazy var foregroundView: UIView = {
        let theView = UIView()
        theView.backgroundColor = foregroundColor
        theView.addSubview(indicatorView)
        return theView
    }()

    private lazy var indicatorView: UIView = {
        let indicatorView = UIView()
        indicatorView.layer.cornerRadius = 2
        indicatorView.backgroundColor = UIColor.ud.textDisabled
        return indicatorView
    }()

    private lazy var contentView: UIView = {
        let theView = UIView()
        theView.backgroundColor = UIColor.ud.bgBody
        theView.clipsToBounds = true
        return theView
    }()

    private lazy var titleView: UILabel = {
       let label = UILabel()
        label.font = UDFont.title3(.fixed)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 1
        return label
    }()

    private lazy var naviBar = {
        let naviBar = TitleNaviBar(titleView: titleView)
        naviBar.leftItems = [backItem]
        return naviBar
    }()

    private lazy var backItem = TitleNaviBarItem(image: UDIcon.closeOutlined.colorImage(UDColor.iconN1)) { [weak self] _ in
        guard let self = self else { return }
        self.popViewController(animated: true)
    }

    private var viewControllerFromInitializer: PopupViewControllerItem?

    public init(
        rootViewController: PopupViewControllerItem,
        distanceToTop: CGFloat = Popup.standardDistanceToTop
    ) {
        self.viewControllerFromInitializer = rootViewController
        self.distanceToTop = distanceToTop
        self.naviBarStyle = rootViewController.naviBarStyle
        super.init(nibName: nil, bundle: nil)

        transitor.backgroundColor = backgroundColor
        modalPresentationStyle = .custom
        transitioningDelegate = transitor
        modalPresentationCapturesStatusBarAppearance = false

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.lastHorizontalSizeClass = self.traitCollection.horizontalSizeClass
        self.headerHeight = self.getHeaderHeight(sizeClass: self.traitCollection.horizontalSizeClass)
        self.contentHeight = self.view.frame.height - UIApplication.shared.statusBarFrame.height - headerHeight - distanceToTop
        self.foregroundViewHeight = self.contentHeight + headerHeight

        setupViews()

        if let viewController = viewControllerFromInitializer {
            viewControllers.append(viewController)
            safelyTransition(from: nil, to: viewController, operation: .push, animated: false)
            viewControllerFromInitializer = nil
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isViewAppeared else { return }
        // 在viewdidload中计算一次布局，再在viewwillappear中更新一次数据，保证拿到horizontalSizeClass的准确值
        let sizeClass = self.traitCollection.horizontalSizeClass
        if lastHorizontalSizeClass != sizeClass {
            lastHorizontalSizeClass = sizeClass
            self.transformToNewSizeClass(sizeClass, animated: false)
        }
        if sizeClass == .compact {
            adjustForegroundViewPositionInCompact(
                with: topViewControllerContext?.preferredPopupOffset ?? .zero,
                animated: false
            )
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isViewAppeared else { return }
        isViewAppeared = true
    }

    /// iPad R视图与C视图切换
    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.lastHorizontalSizeClass = newCollection.horizontalSizeClass
        coordinator.animate { _ in
            self.transformToNewSizeClass(newCollection.horizontalSizeClass, animated: false)
        }
    }

    /// iPad 屏幕旋转
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.isRotating = true
            let height = context.containerView.frame.height
            let insetDistance = self.getInsetDistance(screenHeight: height)
            self.contentHeight = height - UIApplication.shared.statusBarFrame.height - self.headerHeight - self.distanceToTop
            self.foregroundViewHeight = self.contentHeight + self.headerHeight
            if self.lastHorizontalSizeClass == .compact {
                self.foregroundView.snp.updateConstraints { $0.height.equalTo(self.foregroundViewHeight) }
                let targetOffset = self.topViewControllerContext?.preferredPopupOffset ?? .zero
                self.adjustForegroundViewPositionInCompact(with: targetOffset, animated: false)
            } else {
                self.adjustForegroundViewPositionInRegular(bottomPosition: insetDistance, animated: false)
            }
        }) { _ in
            self.isRotating = false
        }
    }

    private func setupViews() {
        view.backgroundColor = UIColor.clear

        /// subviews layout:
        ///
        ///   |---self.view
        ///       |---tapInteractiveView
        ///       |---foregroundView (可交互区域)
        ///           |---contentView
        ///               |---contentViewController.view
        ///
        view.addSubview(tapInteractiveView)
        tapInteractiveView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(foregroundView)
        indicatorView.snp.makeConstraints {
            $0.width.equalTo(30)
            $0.height.equalTo(4)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
        }

        foregroundView.addSubview(contentView)
        foregroundView.addSubview(naviBar)
        contentView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(headerHeight)
            $0.left.right.bottom.equalToSuperview()
        }
        naviBar.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(Popup.Const.naviBarHeight)
        }
        self.transformToNewSizeClass(traitCollection.horizontalSizeClass, animated: false)
        foregroundView.isUserInteractionEnabled = true
        foregroundView.addGestureRecognizer(panGesture)
    }

    private func getHeaderHeight(sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        let showTopIndicator = shouldShowTopIndicator(sizeClass: sizeClass)
        if showTopIndicator {
            return Popup.Const.indicatorHeight
        } else {
            if self.naviBarStyle == .default {
                return Popup.Const.naviBarHeight
            } else {
                return 0.0
            }
        }
    }

    private func shouldShowTopIndicator(sizeClass: UIUserInterfaceSizeClass) -> Bool {
        return sizeClass == .compact && shouldShowTopIndicatorInCompact
    }

    private func transformToNewSizeClass(_ sizeClass: UIUserInterfaceSizeClass, animated: Bool) {
        let remakeForegroundViewConstraints: (() -> Void)
        if sizeClass == .regular {
            foregroundView.lu.addCorner(
                corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner],
                cornerSize: CGSize(width: 12, height: 12)
            )
            naviBar.isHidden = self.naviBarStyle == .none
            let insetDistance = getInsetDistance(screenHeight: self.view.frame.height)
            remakeForegroundViewConstraints = {
                self.foregroundView.snp.remakeConstraints {
                    $0.width.equalTo(Popup.Const.popupViewRegularWeight)
                    $0.height.equalTo(Popup.Const.popupViewRegularHeight)
                    $0.centerX.equalToSuperview()
                    self.foregroundViewBottomConstraint = $0.bottom.equalToSuperview().inset(insetDistance).constraint
                }
            }
        } else {
            foregroundView.lu.addCorner(
                corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                cornerSize: CGSize(width: 12, height: 12)
            )
            naviBar.isHidden = true
            remakeForegroundViewConstraints = {
                self.foregroundView.snp.remakeConstraints {
                    $0.left.right.equalToSuperview()
                    $0.height.equalTo(self.foregroundViewHeight)
                    self.foregroundViewBottomConstraint = $0.bottom.equalToSuperview().constraint
                }
                let targetOffset = self.topViewControllerContext?.preferredPopupOffset ?? .zero
                self.adjustForegroundViewPositionInCompact(with: targetOffset, animated: false)
            }
        }
        if animated {
            UIView.animate(withDuration: Popup.Const.animationDuration,
                           delay: 0,
                           options: [.curveEaseIn]) {
                remakeForegroundViewConstraints()
                self.view.layoutIfNeeded()
            }
        } else {
            remakeForegroundViewConstraints()
        }
        // 更新header高度和contentView位置
        let showTopIndicator = shouldShowTopIndicator(sizeClass: sizeClass)
        indicatorView.isHidden = !showTopIndicator
        self.headerHeight = getHeaderHeight(sizeClass: sizeClass)
        contentView.snp.updateConstraints {
            $0.top.equalToSuperview().offset(headerHeight)
        }
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        if isRotating { return } // 窗口旋转时，不计算键盘弹出高度
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
        }
        guard self.traitCollection.horizontalSizeClass == .regular else { return }
        let insetDistance = getInsetDistance(screenHeight: self.view.frame.height)
        self.adjustForegroundViewPositionInRegular(bottomPosition: insetDistance, animated: true)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if isRotating { return } // 窗口旋转时，不计算键盘收起
        self.keyboardHeight = 0.0
        guard self.traitCollection.horizontalSizeClass == .regular else { return }
        self.adjustForegroundViewPositionInRegular(bottomPosition: (self.view.frame.height - Popup.Const.popupViewRegularHeight) / 2,
                                                   animated: true)
    }

    private func handlePanGestureRecognizerInRegular(_ pan: UIPanGestureRecognizer) {
        let locationPoint = pan.location(in: view)
        let originY: CGFloat = (self.view.frame.height - Popup.Const.popupViewRegularHeight) / 2

        switch pan.state {
        case .began:
            let foregroundViewFrame = view.convert(foregroundView.frame, from: foregroundView.superview)
            guard foregroundViewFrame.contains(locationPoint) else {
                return
            }
            let locationY = locationPoint.y
            panGestureBeginContext = (locationY, PopupOffset(rawValue: 0))
        case .changed:
            guard let panGestureBeginContext = panGestureBeginContext else { return }
            if locationPoint.y < panGestureBeginContext.locationY {
                // 窗口的位置高于原位置时，产生阻尼感，手势向上移动越多，窗口上移越慢
                let offsetY = min(Popup.Const.slideUpMultiple * sqrt(panGestureBeginContext.locationY - locationPoint.y),
                                  panGestureBeginContext.locationY - locationPoint.y)
                self.adjustForegroundViewPositionInRegular(bottomPosition: originY + offsetY, animated: false)
            } else {
                // 窗口高度低于原位置时，跟随手势上下移动
                self.adjustForegroundViewPositionInRegular(bottomPosition: originY - locationPoint.y + panGestureBeginContext.locationY,
                                                           animated: false)
            }
        case .ended:
            // 手势结束时，若窗口高度小于关闭高度或者手势速度过快，直接关闭窗口，否则将窗口高度恢复至原位置
            if self.foregroundView.frame.centerY > self.view.frame.height || pan.velocity(in: view).y > Popup.Const.minDismissVelocity {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.adjustForegroundViewPositionInRegular(bottomPosition: (self.view.frame.height - Popup.Const.popupViewRegularHeight) / 2,
                                                           animated: true)
            }
        default:
            break
        }
    }

    private func handlePanGestureRecognizerInCompact(_ pan: UIPanGestureRecognizer) {
        let locationPoint = pan.location(in: view)
        switch pan.state {
        case .began:
            let foregroundViewFrame = view.convert(foregroundView.frame, from: foregroundView.superview)
            guard foregroundViewFrame.contains(locationPoint) else {
                return
            }
            let locationY = locationPoint.y
            let visibleContentHeight = view.bounds.height - foregroundViewFrame.minY - headerHeight
            panGestureBeginContext = (locationY, PopupOffset(rawValue: visibleContentHeight / contentHeight))
        case .changed, .ended, .cancelled, .failed:
            guard let beginContext = panGestureBeginContext else { return }
            var targetOffset = PopupOffset(rawValue: beginContext.offset.rawValue + (beginContext.locationY - locationPoint.y) / contentHeight)

            guard case .changed = pan.state else {
                panGestureBeginContext = nil
                let bestOffset = findBestOffset(
                    in: topViewControllerContext?.hoverPopupOffsets ?? [.zero],
                    forGesture: pan,
                    beginContext: beginContext,
                    referenceOffset: targetOffset
                )
                let needDismissOrPop = bestOffset == nil
                guard needDismissOrPop else {
                    adjustForegroundViewPositionInCompact(with: bestOffset ?? .zero, animated: true)
                    break
                }

                if viewControllers.count <= 1 {
                    adjustForegroundViewPositionInCompact(with: bestOffset ?? .zero, animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    popViewController(animated: true)
                }
                break
            }
            targetOffset = min(topViewControllerContext?.hoverPopupOffsets.last ?? .maximum, targetOffset)
            adjustForegroundViewPositionInCompact(with: targetOffset, animated: false)
        default:
            break
        }
    }

    @objc
    private func handlePanGestureRecognizer(_ pan: UIPanGestureRecognizer) {
        contentView.endEditing(true)
        if traitCollection.horizontalSizeClass == .regular {
            handlePanGestureRecognizerInRegular(pan)
        } else {
            handlePanGestureRecognizerInCompact(pan)
        }
    }

    private func findBestOffset(
        in hoverOffsets: [PopupOffset],
        forGesture gesture: UIPanGestureRecognizer,
        beginContext: PanGestureRecognizerContext,
        referenceOffset: PopupOffset
    ) -> PopupOffset? {
        guard !hoverOffsets.isEmpty else { return nil }

        let velocity = gesture.velocity(in: view)
        let validOffsetDiff: CGFloat = 30.0 / contentHeight

        // 手势向上，且移动了有效距离
        if referenceOffset.rawValue >= beginContext.offset.rawValue + validOffsetDiff && velocity.y < -100 {
            return hoverOffsets.first { $0 >= referenceOffset } ?? hoverOffsets.last
        }

        // 手势向下，且移动了有效距离
        if referenceOffset.rawValue + validOffsetDiff <= beginContext.offset.rawValue && velocity.y > 100 {
            return hoverOffsets.last { $0 <= referenceOffset }
        }

        // 寻找相邻的 hover offset
        let lessThanOrEqual = hoverOffsets.last { $0 <= referenceOffset } ?? hoverOffsets.first!
        let greaterThanOrEqual = hoverOffsets.first { $0 >= referenceOffset } ?? hoverOffsets.last!
        if abs(lessThanOrEqual.rawValue - referenceOffset.rawValue) > abs(greaterThanOrEqual.rawValue - referenceOffset.rawValue) {
            return greaterThanOrEqual
        } else {
            return lessThanOrEqual
        }
    }

    internal func updateTopViewControllerContext() {
        guard let topViewController = topViewController else {
            topViewControllerContext = nil
            return
        }
        topViewControllerContext = (
            preferredPopupOffset: topViewController.preferredPopupOffset,
            hoverPopupOffsets: topViewController.hoverPopupOffsets.sorted()
        )
    }

    private func adjustForegroundViewPositionInCompact(
        with offset: PopupOffset,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        let invisibleOffset = PopupOffset(rawValue: 0.01)
        let foregroundViewBottomOffset: CGFloat
        if offset <= invisibleOffset {
            foregroundViewBottomOffset = foregroundViewHeight
        } else {
            foregroundViewBottomOffset = ceil((PopupOffset.full.rawValue - offset.rawValue) * contentHeight)
        }
        let updateConstraint = {
            self.foregroundViewBottomConstraint?.update(offset: foregroundViewBottomOffset)
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(
                withDuration: Popup.Const.animationDuration,
                animations: { updateConstraint() },
                completion: { _ in completion?() }
            )
        } else {
            updateConstraint()
            completion?()
        }
    }

    private func adjustForegroundViewPositionInRegular(bottomPosition: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: Popup.Const.animationDuration) {
                self.foregroundViewBottomConstraint?.update(inset: bottomPosition)
                self.view.layoutIfNeeded()
            }
        } else {
            self.foregroundViewBottomConstraint?.update(inset: bottomPosition)
        }
    }

    private func getInsetDistance(screenHeight: CGFloat) -> CGFloat {
        return min((screenHeight - Popup.Const.popupViewRegularHeight) / 2 + self.keyboardHeight / 2,
                   screenHeight - Popup.Const.popupViewRegularHeight - Popup.Const.minHeightToTop)
    }
}

// MARK: Push & Pop

extension PopupViewController {

    private enum TransitionOperation {
        case push, pop
    }

    private func transition(
        from fromVC: PopupViewControllerItem?,
        to toVC: PopupViewControllerItem?,
        operation: TransitionOperation,
        animated: Bool
    ) {
        isTransitioning = true

        if case .pop = operation {
            fromVC?.willMove(toParent: nil)
        }

        if let toVC = toVC {
            self.naviBarStyle = toVC.naviBarStyle
            self.titleView.text = toVC.naviBarTitle
            self.naviBar.backgroundColor = toVC.naviBarBackgroundColor
            if let leftItems = toVC.naviBarLeftItems {
                naviBar.leftItems = leftItems
            }
            if let rightItems = toVC.naviBarRightItems {
                naviBar.rightItems = rightItems
            }
            if case .push = operation {
                addChild(toVC)
            }
            contentView.addSubview(toVC.view)
            toVC.view.snp.remakeConstraints { $0.edges.equalToSuperview() }
            toVC.didMove(toParent: self)
        }
        topViewController = toVC

        fromVC?.view.removeFromSuperview()
        if case .pop = operation {
            fromVC?.removeFromParent()
        }

        if case .push = operation {
            contentView.layoutIfNeeded()
        }

        if self.traitCollection.horizontalSizeClass == .compact {
            let offset = topViewControllerContext?.preferredPopupOffset ?? .zero
            adjustForegroundViewPositionInCompact(with: offset, animated: animated) {  [weak self] in
                self?.isTransitioning = false
            }
        } else {
            self.isTransitioning = false
        }
    }

    private func safelyTransition(
        from fromVC: PopupViewControllerItem?,
        to toVC: PopupViewControllerItem?,
        operation: TransitionOperation,
        animated: Bool
    ) {
        let bothNil = fromVC == nil && toVC == nil
        guard !bothNil else { return }
        let neitherNilButEqual = fromVC != nil && toVC != nil && fromVC! == toVC!
        guard !neitherNilButEqual else { return }

        if isTransitioning {
            DispatchQueue.main.asyncAfter(deadline: .now() + Popup.Const.animationDuration) {
                self.transition(from: fromVC, to: toVC, operation: operation, animated: animated)
            }
            return
        }
        transition(from: fromVC, to: toVC, operation: operation, animated: animated)
    }

    public func pushViewController(_ viewController: PopupViewControllerItem, animated: Bool) {
        loadViewIfNeeded()
        guard !(viewControllers as [UIViewController]).contains(viewController as UIViewController) else {
            return
        }
        viewControllers.append(viewController)
        guard isViewLoaded else { return }
        let fromVC = topViewController
        safelyTransition(from: fromVC, to: viewController, operation: .push, animated: animated)
    }

    @discardableResult
    public func popViewController(animated: Bool) -> PopupViewControllerItem? {
        loadViewIfNeeded()
        guard let fromVC = viewControllers.last else { return nil }
        let toVC: PopupViewControllerItem? = viewControllers.count > 1 ? viewControllers[viewControllers.count - 2] : nil
        viewControllers.removeLast()
        if toVC == nil {
            self.dismiss(animated: true)
        } else {
            safelyTransition(from: fromVC, to: toVC, operation: .pop, animated: animated && isViewAppeared)
        }
        return fromVC
    }

}

extension PopupViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !isTransitioning else { return false }
        guard let topViewController = topViewController else { return false }
        if self.traitCollection.horizontalSizeClass == .compact {
            return topViewController.shouldBeginPopupInteractingInCompact(with: gestureRecognizer)
        } else {
            return topViewController.shouldBeginPopupInteractingInRegular(with: gestureRecognizer)
        }
    }

}
