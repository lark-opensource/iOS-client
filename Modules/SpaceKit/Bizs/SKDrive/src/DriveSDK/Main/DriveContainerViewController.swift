//
//  DriveContainerViewController.swift
//  SKDrive
//
//  Created by 邱沛 on 2021/9/10.
//

import SKCommon
import RxSwift
import LarkUIKit
import SKFoundation
import SKUIKit

class DriveContainerViewController: BaseViewController,
                                    UIViewControllerTransitioningDelegate,
                                    UIGestureRecognizerDelegate,
                                    DriveAnimatedContainer {

    var childVCFrame: (() -> CGRect)?
    var resetChildVC: (() -> Void)?

    let childVC: BaseViewController

    private var dismissPanGesture = UIPanGestureRecognizer()
    var shouldHandleDismiss = false
    var interactiveTransition: UIPercentDrivenInteractiveTransition?

    init(vc: BaseViewController) {
        self.childVC = vc
        super.init(nibName: nil, bundle: nil)
        self.setNavigationBarHidden(true, animated: false)
        self.statusBar.isHidden = true
        setupDismissGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var prefersStatusBarHidden: Bool {
        return (childVC as? DriveFileBlockVCProtocol)?.statusBarIsHidden ?? false
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .slide }

    override var shouldAutorotate: Bool {
        return childVC.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return childVC.supportedInterfaceOrientations
    }

    deinit {
        DocsLogger.driveInfo("DriveContainerViewController deinit")
        childVC.view.removeGestureRecognizer(dismissPanGesture)
    }

    @objc
    func willDealloc() -> Bool {
        return false
    }

    func setupChild() {
        removeChildVC()
        childVC.willMove(toParent: self)
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        childVC.didMove(toParent: self)
        childVC.view.isUserInteractionEnabled = true
        childVC.view.addGestureRecognizer(dismissPanGesture)
        guard let pan = (childVC as? DriveFileBlockVCProtocol)?.panGesture else { return }
        pan.addTarget(self, action: #selector(handleScrollPan(gesture:)))
    }

    func removeChildVC() {
        childVC.willMove(toParent: nil)
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }

    private func setupDismissGesture() {
        self.dismissPanGesture.maximumNumberOfTouches = 1
        self.dismissPanGesture.addTarget(self, action: #selector(handleDismissPan(gesture:)))
        self.dismissPanGesture.delegate = self
    }

    var initialPosition: CGFloat = 0

    // 下滑返回
    @objc
    private func handleScrollPan(gesture: UIPanGestureRecognizer) {
        guard let window = self.view.window else { return }
        var progress: CGFloat = 0
        var canBeginDismiss = false
        if let scrollView = gesture.view as? UIScrollView {
            progress = (-scrollView.contentOffset.y - 60) / 20
            canBeginDismiss = scrollView.contentOffset.y < -60
        } else {
            progress = ((gesture.location(in: window).y - initialPosition) - 80) / 70
            canBeginDismiss = progress > 0
        }
        guard !shouldHandleDismiss else { return }
        switch gesture.state {
        case .began:
            initialPosition = gesture.location(in: window).y
        case .changed:
            guard canBeginDismiss else { return }
            self.dismiss(animated: true, completion: nil)
            // 产品说，先不要跟手返回
            // 如果要，把下面注释代码改回来就行
//            if self.interactiveTransition == nil {
//                self.interactiveTransition = UIPercentDrivenInteractiveTransition()
//                self.dismiss(animated: true, completion: nil)
//            }
//            if progress > 1 {
//                self.interactiveTransition?.finish()
//                self.interactiveTransition = nil
//            } else {
//                self.interactiveTransition?.update(progress)
//            }
        case .cancelled, .ended:
            break
//            if progress > 1 {
//                self.interactiveTransition?.finish()
//                self.reportReturn(clickEventType: .slide, actionType: "slide_down")
//            } else {
//                self.interactiveTransition?.cancel()
//            }
//            self.interactiveTransition = nil
        default: break
        }
    }

    // 测滑返回
    @objc
    private func handleDismissPan(gesture: UIPanGestureRecognizer) {
        guard !SKDisplay.pad else { return }
        guard shouldHandleDismissGesture else { return }
        let currentLocation = gesture.location(in: self.view)
        let progress = currentLocation.x / 100
        switch gesture.state {
        case .began:
            if progress < 0.3 {
                self.interactiveTransition = UIPercentDrivenInteractiveTransition()
                self.dismiss(animated: true, completion: nil)
                self.shouldHandleDismiss = true
            }
        case .changed:
            guard shouldHandleDismiss else { return }
            if progress > 1 {
                self.interactiveTransition?.finish()
                self.interactiveTransition = nil
                self.shouldHandleDismiss = false
            } else {
                self.interactiveTransition?.update(progress)
            }
        case .cancelled, .ended:
            guard shouldHandleDismiss else { return }
            if progress > 1 {
                self.interactiveTransition?.finish()
                self.reportReturn(clickEventType: .slide, actionType: "slide_right")
            } else {
                self.interactiveTransition?.cancel()
            }
            self.interactiveTransition = nil
            self.shouldHandleDismiss = false
        default: break
        }
    }

    func willChangeMode(_ mode: DrivePreviewMode) {
        (self.childVC as? DKMainViewController)?.willChangeMode(mode)
    }

    func changingMode(_ mode: DrivePreviewMode) {
        (self.childVC as? DKMainViewController)?.changingMode(mode)
    }

    func didChangeMode(_ mode: DrivePreviewMode) {
        (self.childVC as? DKMainViewController)?.didChangeMode(mode)
    }

    var shouldHandleDismissGesture: Bool {
        (self.childVC as? DKMainViewController)?.shouldHandleDismissGesture ?? false
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DriveTransitionPresentAnimation()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DriveTransitionDismissAnimation()
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        print("require interactiveTransition")
        return self.interactiveTransition
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == dismissPanGesture {
            return false
        }
        return true
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        nil
    }

    // 退出埋点
    private func reportReturn(clickEventType: DriveStatistic.DriveFileOpenClickEventType, actionType: String?) {
        guard let vc = childVC as? DKMainViewController else { return }
        var params: [String: Any] = [
            "display": "card"
        ]
        if let action = actionType {
            params["action_type"] = action
        }
        vc.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileOpenClick, clickEventType: clickEventType, params: params)
    }
}

class DriveTransitionPresentAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    let firstDuration: Double = 0.2
    let secondDuration: Double = 0.1

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return firstDuration + secondDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        var toVC: DriveAnimatedContainer?
        var toVCNav: UINavigationController?
        if let to = transitionContext.viewController(forKey: .to) as? UINavigationController {
            toVCNav = to
            toVC = to.viewControllers.first(where: { $0 is DriveAnimatedContainer }) as? DriveAnimatedContainer
        } else {
            toVC = transitionContext.viewController(forKey: .to) as? DriveAnimatedContainer
        }
        guard let toVC = toVC,
              let toVCNav = toVCNav,
              let frame = toVC.childVCFrame?() else { return }

        toVCNav.view.frame = frame
        toVCNav.view.layer.cornerRadius = 8
        toVCNav.view.layer.masksToBounds = true
        toVC.view.frame = toVCNav.view.bounds
        toVC.setupChild()

        let blurView = UIVisualEffectView()
        blurView.effect = UIBlurEffect(style: .light)
        blurView.alpha = 0
        containerView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.addSubview(toVCNav.view)
        containerView.backgroundColor = .clear
        toVC.willChangeMode(.normal)
        UIView.animate(withDuration: firstDuration, animations: {
            toVC.changingMode(.normal)
            blurView.alpha = 1
            toVCNav.view.frame = CGRect(x: containerView.bounds.width * 0.1,
                                     y: containerView.bounds.height * 0.1,
                                     width: containerView.bounds.width * 0.8,
                                     height: containerView.bounds.height * 0.8)
            toVCNav.view.layoutIfNeeded()
        }) { _ in
            UIView.animate(withDuration: self.secondDuration) {
                toVCNav.view.frame = CGRect(x: 0,
                                            y: containerView.safeAreaInsets.top,
                                            width: containerView.bounds.width,
                                            height: containerView.bounds.height - containerView.safeAreaInsets.top)
                toVCNav.view.layoutIfNeeded()
            } completion: { _ in
                toVCNav.view.layer.cornerRadius = 0
                toVCNav.view.frame = containerView.bounds
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                toVC.didChangeMode(.normal)
            }
        }
    }
}

class DriveTransitionDismissAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    let firstDuration: Double = 0.2
    let secondDuration: Double = 0.15

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return firstDuration + secondDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        var fromVC: DriveAnimatedContainer?
        var fromVCNav: UINavigationController?
        if let from = transitionContext.viewController(forKey: .from) as? UINavigationController {
            fromVCNav = from
            fromVC = from.viewControllers.first(where: { $0 is DriveAnimatedContainer }) as? DriveAnimatedContainer
        } else {
            fromVC = transitionContext.viewController(forKey: .from) as? DriveAnimatedContainer
        }
        guard let fromVC = fromVC,
              let fromVCNav = fromVCNav,
              let frame = fromVC.childVCFrame?() else { return }
        fromVC.willChangeMode(.card)
        fromVCNav.view.layer.cornerRadius = 8
        fromVCNav.view.layer.masksToBounds = true
        let blurView = containerView.subviews.first(where: { $0 is UIVisualEffectView })
        UIView.animate(withDuration: secondDuration) {
            fromVCNav.view.frame = CGRect(x: containerView.bounds.width * 0.1,
                                          y: containerView.bounds.height * 0.1,
                                          width: containerView.bounds.width * 0.8,
                                          height: containerView.bounds.height * 0.8)
            fromVC.changingMode(.card)
            fromVCNav.view.layoutIfNeeded()
        } completion: { _ in
            if transitionContext.transitionWasCancelled {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                fromVCNav.view.frame = containerView.bounds
                fromVCNav.view.layer.cornerRadius = 0
                fromVC.view.frame = containerView.bounds
                fromVC.didChangeMode(.normal)
            } else {
                UIView.animate(withDuration: self.firstDuration) {
                    blurView?.alpha = 0
                    fromVCNav.view.frame = frame
                    fromVCNav.view.layoutIfNeeded()
                } completion: { _ in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    blurView?.removeFromSuperview()
                    fromVCNav.view.layer.cornerRadius = 0
                    fromVC.resetChildVC?()
                    fromVC.view.layoutIfNeeded()
                    fromVC.didChangeMode(.card)
                }
            }
        }
    }
}
