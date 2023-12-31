//
//  PopupViewController.swift
//  iOS
//
//  Created by 张威 on 2020/1/8.
//

import UIKit
import QuartzCore
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - PopupViewController

/// Popup（弹窗）容器，实现类似于 Apple Map App 那样的弹窗效果；弹窗支持交互，支持转场，接口风格类似于
/// `UINavigationController`
final class PopupViewController: UIViewController {

    // MARK: Properties

    /// 最上层的 item ViewController
    private(set) var topViewController: PopupViewControllerItem?  = nil {
        didSet { updateTopViewControllerContext() }
    }

    /// 栈中的 ViewControllers
    var viewControllers: [PopupViewControllerItem] = []

    /// 当前 popupOffset
    var currentPopupOffset: PopupOffset {
        let rawValue = (view.bounds.height - foregroundView.frame.minY - Popup.Const.indicatorHeight) / contentHeight
        return PopupOffset(rawValue: rawValue)
    }

    /// contentHeight = foregroundHeight - indicatorView.height
    let contentHeight: CGFloat

    /// 弹窗交互区域背景色
    var foregroundColor: UIColor = UIColor.ud.bgBody {
        didSet { foregroundView.backgroundColor = foregroundColor }
    }

    /// 弹窗背景色
    var backgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5) {
        didSet { transitor.backgroundColor = backgroundColor }
    }

    /// 交互手势：拖拽调整弹窗的高度
    var interactivePopupGestureRecognizer: UIGestureRecognizer { panGesture }

    // MARK: Private Properties

    private typealias TopViewControllerContext = (preferredPopupOffset: PopupOffset, hoverPopupOffsets: [PopupOffset])
    private typealias PanGestureRecognizerContext = (locationY: CGFloat, offset: PopupOffset)

    private var isViewAppeared = false
    private var isTransitioning = false
    private var foregroundViewHeight: CGFloat { contentHeight + Popup.Const.indicatorHeight }
    private var panGestureBeginContext: PanGestureRecognizerContext?
    private var topViewControllerContext: TopViewControllerContext?

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

    private var foregroundViewBottomConstraint: Constraint!
    private lazy var foregroundView: UIView = {
        let theView = UIView()
        theView.lu.addCorner(
            corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
            cornerSize: CGSize(width: 12, height: 12)
        )
        theView.backgroundColor = foregroundColor

        let indicatorView = UIView()
        indicatorView.layer.cornerRadius = 2
        indicatorView.backgroundColor = UIColor.ud.lineBorderComponent
        theView.addSubview(indicatorView)
        indicatorView.snp.makeConstraints {
            $0.width.equalTo(30)
            $0.height.equalTo(4)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
        }

        return theView
    }()

    private lazy var contentView: UIView = {
        let theView = UIView()
        theView.backgroundColor = UIColor.ud.bgBody
        theView.clipsToBounds = true
        theView.backgroundColor = UIColor.ud.functionDangerContentDefault
        return theView
    }()

    private var viewControllerFromInitializer: PopupViewControllerItem?

    init(
        rootViewController: PopupViewControllerItem,
        contentHeight: CGFloat = Popup.standardContentHeight
    ) {
        self.contentHeight = contentHeight
        viewControllerFromInitializer = rootViewController
        super.init(nibName: nil, bundle: nil)

        transitor.backgroundColor = backgroundColor
        modalPresentationStyle = .custom
        transitioningDelegate = transitor
        modalPresentationCapturesStatusBarAppearance = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        if let viewController = viewControllerFromInitializer {
            viewControllers.append(viewController)
            safelyTransition(from: nil, to: viewController, operation: .push, animated: false)
            viewControllerFromInitializer = nil
        }

        adjustForegroundViewPosition(
            with: topViewControllerContext?.preferredPopupOffset ?? .zero,
            animated: false
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isViewAppeared else { return }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isViewAppeared else { return }
        isViewAppeared = true
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
        foregroundView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(foregroundViewHeight)
            foregroundViewBottomConstraint = $0.bottom.equalToSuperview().constraint
        }

        foregroundView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.equalTo(Popup.Const.indicatorHeight)
            $0.left.right.bottom.equalToSuperview()
        }

        foregroundView.isUserInteractionEnabled = true
        foregroundView.addGestureRecognizer(panGesture)
    }

    @objc
    private func handlePanGestureRecognizer(_ pan: UIPanGestureRecognizer) {
        let locationPoint = pan.location(in: view)
        switch pan.state {
        case .began:
            let foregroundViewFrame = view.convert(foregroundView.frame, from: foregroundView.superview)
            guard foregroundViewFrame.contains(locationPoint) else {
                return
            }
            let locationY = locationPoint.y
            let visibleContentHeight = view.bounds.height - foregroundViewFrame.minY - Popup.Const.indicatorHeight
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
                    adjustForegroundViewPosition(with: bestOffset ?? .zero, animated: true)
                    break
                }

                if viewControllers.count <= 1 {
                    adjustForegroundViewPosition(with: bestOffset ?? .zero, animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    popViewController(animated: true)
                }
                break
            }
            targetOffset = min(topViewControllerContext?.hoverPopupOffsets.last ?? .maximum, targetOffset)
            adjustForegroundViewPosition(with: targetOffset, animated: false)
        default:
            break
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

    internal func adjustForegroundViewPosition(
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
        let closure = {
            self.foregroundViewBottomConstraint.update(offset: foregroundViewBottomOffset)
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(
                withDuration: Popup.Const.animationDuration,
                animations: { closure() },
                completion: { _ in completion?() }
            )
        } else {
            closure()
            completion?()
        }
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

        let offset = topViewControllerContext?.preferredPopupOffset ?? .zero
        adjustForegroundViewPosition(with: offset, animated: animated) {  [weak self] in
            self?.isTransitioning = false
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

    func pushViewController(_ viewController: PopupViewControllerItem, animated: Bool) {
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
    func popViewController(animated: Bool) -> PopupViewControllerItem? {
        loadViewIfNeeded()
        guard let fromVC = viewControllers.last else { return nil }
        let toVC: PopupViewControllerItem? = viewControllers.count > 1 ? viewControllers[viewControllers.count - 2] : nil
        viewControllers.removeLast()
        safelyTransition(from: fromVC, to: toVC, operation: .pop, animated: animated && isViewAppeared)
        return fromVC
    }

}

extension PopupViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !isTransitioning else { return false }
        guard let topViewController = topViewController else { return false }
        return topViewController.shouldBeginPopupInteracting(with: gestureRecognizer)
    }

}
