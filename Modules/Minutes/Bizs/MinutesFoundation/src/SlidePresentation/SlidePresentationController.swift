//
//  SlidePresentationController.swift
//  SlidePresentation
//
//  Created by chenlehui on 2020/8/17.
//

import UIKit

// disable-lint: magic number
class SlidePresentationController: UIPresentationController {
    private var dimmingView: UIView = .init()
    private var style: SlidePresentationStyle
    private var presentedSize: CGSize
    private var isKeyBoardShow = false
    private var keyBoardHeightOffset: CGFloat = 0.0
    private var keyBoardAnimationDuration: TimeInterval = 0
    var dismissAnimated = true
    var dimmingAlpha: CGFloat = 0.4
    var isPanCloseEnabled = false
    var landscapeSize: CGSize = .zero
    var autoSize: (() -> CGSize)?

    private weak var scrollView: UIScrollView?
    private weak var contentView: UIView?
    private var isDragScrollView = false
    private var lastTransition = CGPoint.zero

    private lazy var tap: UITapGestureRecognizer = {
        let ges = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        ges.delegate = self
        return ges
    }()

    private lazy var pan: UIPanGestureRecognizer = {
        let ges = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        ges.delegate = self
        return ges
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        let windowSize = ScreenUtils.sceneScreenSize
        var size: CGSize = presentedSize
        if presentedSize == .zero {
            size = self.size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView?.bounds.size ?? windowSize)
        }
        if let autoSize = self.autoSize {
            size = autoSize()
        }
        let width = containerView?.frame.width ?? windowSize.width
        let height = containerView?.frame.height ?? windowSize.height
        var frame = CGRect.zero
        frame.size = size
        switch style {
        case .alert:
            frame.origin = CGPoint(x: (width - size.width) / 2, y: (height - size.height) / 2)
        case .actionSheet(.right):
            frame.origin.x = width - size.width
            frame.size.height = height
        case .actionSheet(.bottom):
            frame.origin.y = height - size.height
            frame.size.width = width
        case .actionSheet(.left):
            frame.size.height = height
        case .actionSheet(.top):
            frame.size.width = width
        }
        return frame
    }

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, style: SlidePresentationStyle, presentedSize: CGSize, isObserveKeyBoard: Bool, keyBoardHeightOffset: CGFloat, dimmingAlpha: CGFloat) {
        self.style = style
        self.presentedSize = presentedSize
        self.dimmingAlpha = dimmingAlpha
        self.keyBoardHeightOffset = keyBoardHeightOffset
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        createDimmingView()
        if isObserveKeyBoard {
            observeKeyBoard()
        }
    }

    override func presentationTransitionWillBegin() {
        containerView?.addGestureRecognizer(tap)
        containerView?.addGestureRecognizer(pan)
        containerView?.insertSubview(dimmingView, at: 0)

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }
        coordinator.animate(alongsideTransition: { (_) in
            self.dimmingView.alpha = 1.0
        }, completion: nil)
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        contentView = presentedViewController.view
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        dimmingView.frame = (containerView?.bounds)!
    }

    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let width = parentSize.width
        let height = parentSize.height

        switch style {
        case .alert:
            return CGSize(width: 300, height: 200)
        case .actionSheet(.left), .actionSheet(.right):
            return CGSize(width: width * 2 / 3, height: height)
        case .actionSheet(.top), .actionSheet(.bottom):
            return CGSize(width: width, height: height / 2)
        }
    }

    private func createDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: dimmingAlpha)
        dimmingView.alpha = 0.0
        dimmingView.isUserInteractionEnabled = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - keyBoard

private extension SlidePresentationController {

    func observeKeyBoard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIApplication.keyboardWillHideNotification, object: nil)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        guard isKeyBoardShow == false else {
            return
        }
        if let keyBoardFrame = notification.keyboardEndFrame() {
            let endFrame = transitionFrame(from: keyBoardFrame)
            let defaultDuration = 0.25
            keyBoardAnimationDuration = notification.keyboardAnimationDuration() ?? defaultDuration
            UIView.animate(withDuration: keyBoardAnimationDuration, animations: {
                self.presentedView?.frame = endFrame
            })
            isKeyBoardShow = true
        }
    }

    @objc func keyBoardWillHide(notification: Notification) {
        if isKeyBoardShow {
            let defaultDuration = 0.25
            keyBoardAnimationDuration = notification.keyboardAnimationDuration() ?? defaultDuration
            UIView.animate(withDuration: keyBoardAnimationDuration, animations: {
                self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            })
            isKeyBoardShow = false
        }
    }

    func transitionFrame(from keyBoardFrame: CGRect) -> CGRect {
        var presentedFrame = frameOfPresentedViewInContainerView
        let kY = keyBoardFrame.origin.y
        let pBottom = presentedFrame.origin.y + presentedFrame.size.height
        switch style {
        case .alert:
            if pBottom > kY {
                presentedFrame.origin.y = ScreenUtils.sceneScreenSize.height - keyBoardFrame.height - presentedFrame.height + keyBoardHeightOffset
            }
        case .actionSheet(.bottom):
            presentedFrame.origin.y = presentedFrame.origin.y - keyBoardFrame.height + keyBoardHeightOffset
        default:
            break
        }
        return presentedFrame
    }
}

// MARK: - gesture delegate

extension SlidePresentationController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == pan {
            var touchView = touch.view
            while touchView != nil {
                if touchView is UIScrollView {
                    scrollView = touchView as? UIScrollView
                    isDragScrollView = true
                    break
                } else if touchView == contentView {
                    isDragScrollView = false
                    break
                }
                touchView = touchView?.next as? UIView
            }
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: containerView)
        if gestureRecognizer == tap,
            frameOfPresentedViewInContainerView.contains(point) {
            return false
        }
        if gestureRecognizer == pan,
            !frameOfPresentedViewInContainerView.contains(point) {
            return false
        }
        return true
    }
}

// MARK: - gesture action

extension SlidePresentationController {

    @objc func tapAction(_ sender: UITapGestureRecognizer) {
        switch style {
        case .actionSheet:
            if isKeyBoardShow {
                presentedView?.endEditing(true)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                    self.presentingViewController.dismiss(animated: self.dismissAnimated)
                })
                return
            }
            presentingViewController.dismiss(animated: dismissAnimated)
        default:
            break
        }

    }

    @objc private func panAction(_ sender: UIPanGestureRecognizer) {
        guard isPanCloseEnabled else { return }
        let translation = sender.translation(in: contentView)
        switch style {
        case .alert, .actionSheet(.top):
            return
        case .actionSheet(.bottom):
            bottomPanClose(with: translation)
        case .actionSheet(.left):
            leftPanClose(with: translation)
        case .actionSheet(.right):
            rightPanClose(with: translation)
        }
        lastTransition = translation
    }

    private func bottomPanClose(with translation: CGPoint) {
        var contentFrame = contentView?.frame ?? .zero
        if isDragScrollView {
            if let sv = scrollView,
                sv.contentOffset.y <= 0,
                translation.y > 0 { // 向下滑动
                scrollView?.contentOffset = .zero
                scrollView?.panGestureRecognizer.isEnabled = false
                isDragScrollView = false

                contentFrame.origin.y += translation.y
                contentView?.frame = contentFrame
            }
        } else {
            let oy = ScreenUtils.sceneScreenSize.height - contentFrame.height
            if translation.y > 0 {
                contentFrame.origin.y += translation.y
                contentView?.frame = contentFrame
            } else if translation.y < 0, contentFrame.origin.y > oy {
                contentFrame.origin.y = max(contentFrame.origin.y + translation.y, oy)
                contentView?.frame = contentFrame
            }
        }

        let da = (contentFrame.origin.y - frameOfPresentedViewInContainerView.origin.y) / frameOfPresentedViewInContainerView.height
        let alpha = 1 - da
        dimmingView.alpha = alpha

        pan.setTranslation(.zero, in: contentView)

        if pan.state == .ended {
            scrollView?.panGestureRecognizer.isEnabled = true
            let distance = contentFrame.origin.y - frameOfPresentedViewInContainerView.origin.y

            if distance > contentFrame.height / 2, !isDragScrollView {
                presentingViewController.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.contentView?.frame = self.frameOfPresentedViewInContainerView
                    self.dimmingView.alpha = 1
                }
            }
        }
    }

    private func leftPanClose(with translation: CGPoint) {
        var contentFrame = contentView?.frame ?? .zero
        if translation.x < 0 {
            contentFrame.origin.x += translation.x
            contentView?.frame = contentFrame
        } else if translation.y > 0, contentFrame.origin.x > 0 {
            contentFrame.origin.x = min(contentFrame.origin.x + translation.y, 0)
            contentView?.frame = contentFrame
        }

        let da = ( -contentFrame.origin.x) / frameOfPresentedViewInContainerView.width
        let alpha = 1 - da
        dimmingView.alpha = alpha

        pan.setTranslation(.zero, in: contentView)

        if pan.state == .ended {
            let velocity = pan.velocity(in: contentView)

            if velocity.y > 0, lastTransition.x < -5 {
                presentingViewController.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.contentView?.frame = self.frameOfPresentedViewInContainerView
                    self.dimmingView.alpha = 1
                }
            }
        }
    }
    
    private func handleRightPan(with translation: CGPoint) {
        var contentFrame = contentView?.frame ?? .zero
        let ox = ScreenUtils.sceneScreenSize.width - contentFrame.width
        if translation.x > 0 {
            contentFrame.origin.x += translation.x
            contentView?.frame = contentFrame
        } else if translation.x < 0, contentFrame.origin.x > ox {
            contentFrame.origin.x = max(contentFrame.origin.x + translation.x, ox)
            contentView?.frame = contentFrame
        }
        let da = (contentFrame.origin.x - frameOfPresentedViewInContainerView.origin.x) / frameOfPresentedViewInContainerView.width
        let alpha = 1 - da
        dimmingView.alpha = alpha
    }

    private func rightPanClose(with translation: CGPoint) {
        handleRightPan(with: translation)

        pan.setTranslation(.zero, in: contentView)

        if pan.state == .ended {
            let velocity = pan.velocity(in: contentView)

            if velocity.x > 0, lastTransition.x > 5 {
                presentingViewController.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.contentView?.frame = self.frameOfPresentedViewInContainerView
                    self.dimmingView.alpha = 1
                }

            }
        }
    }

}

extension Notification {

    func keyboardEndFrame () -> CGRect? {
        return (self.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    }

    func keyboardAnimationDuration () -> Double? {
        return (self.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
    }
}
// enable-lint: magic number
