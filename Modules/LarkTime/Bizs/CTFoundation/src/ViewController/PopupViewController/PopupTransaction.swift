//
//  PopupTransaction.swift
//  Calendar
//
//  Created by 张威 on 2020/2/19.
//

import UIKit
import Foundation

final class PopupTransitor: NSObject, UIViewControllerTransitioningDelegate {

    var backgroundColor: UIColor = .clear {
        didSet { backgroundView.backgroundColor = backgroundColor }
    }
    // distinguish presentation from dismissal
    private var isPresentation = false
    lazy private var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = backgroundColor
        return view
    }()

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        isPresentation = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
        isPresentation = false
        return self
    }

}

// MARK: UIViewControllerAnimatedTransitioning

extension PopupTransitor: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresentation ? 0.25 : 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let popupVC = (isPresentation ? toVC : fromVC) as? PopupViewController else {
            transitionContext.completeTransition(false)
            return
        }
        let containerView = transitionContext.containerView

        let calPopupVisibleHeight = { [weak popupVC] () -> CGFloat in
            guard let popupVC = popupVC else { return 0 }
            return popupVC.contentHeight * popupVC.currentPopupOffset.rawValue + Popup.Const.indicatorHeight
        }

        if isPresentation {
            backgroundView.frame = containerView.bounds
            backgroundView.alpha = 0.0
            backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            containerView.addSubview(backgroundView)

            popupVC.view.frame = containerView.bounds
            popupVC.view.transform = CGAffineTransform(translationX: 0, y: calPopupVisibleHeight())
            containerView.addSubview(popupVC.view)
            let duration = transitionDuration(using: transitionContext)
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseOut],
                animations: { [weak self, weak popupVC] in
                    self?.backgroundView.alpha = 1.0
                    popupVC?.view.transform = .identity
                },
                completion: { _ in transitionContext.completeTransition(true) }
            )

        } else {
            let duration = transitionDuration(using: transitionContext)
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseIn],
                animations: { [weak self, weak popupVC] in
                    self?.backgroundView.alpha = 0.0
                    popupVC?.view.transform = CGAffineTransform(translationX: 0, y: calPopupVisibleHeight())
                },
                completion: { [weak self, weak popupVC] _ in
                    self?.backgroundView.removeFromSuperview()
                    popupVC?.view.transform = .identity
                    transitionContext.completeTransition(true)
                }
            )
        }
    }

}
