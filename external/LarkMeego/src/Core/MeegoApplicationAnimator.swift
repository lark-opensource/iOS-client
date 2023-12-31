//
//  MeegoApplicationAnimator.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/7/30.
//

import Foundation
import UIKit
import LarkFlutterContainer
import LarkContainer
import LarkMeegoInterface

private enum Agreement {
    static let bizUrl = "biz_url"
    static let openUrl = "/openByURL"
    static let createWorkItem = "/create_work_item"
}

final class AnimatorMatcher {
    private weak var meegoService: LarkMeegoService?

    init(userResolver: UserResolver) {
        meegoService = try? userResolver.resolve(assert: LarkMeegoService.self)
    }

    func hasMatch(_ resource: UIViewController) -> Bool {
        guard let resource = resource as? LarkFlutterResource else {
            return false
        }
        if resource.flutterRouteUrl == Agreement.createWorkItem {
            return true
        }
        if resource.flutterRouteUrl == Agreement.openUrl,
           let bizUrl = resource.parameters[Agreement.bizUrl] as? String,
           meegoService?.isMeegoHomeURL(bizUrl) ?? false {
            return true
        }
        return false
    }
}

final class PushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
              let toView = transitionContext.view(forKey: UITransitionContextViewKey.to),
              let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }
        let containerView = transitionContext.containerView
        toView.frame = CGRect(
            x: fromView.frame.origin.x ?? 0,
            y: fromView.frame.maxY ?? UIScreen.main.bounds.size.height,
            width: fromView.frame.width ?? UIScreen.main.bounds.size.width,
            height: fromView.frame.height ?? UIScreen.main.bounds.size.height
        )
        containerView.insertSubview(toView, aboveSubview: fromView)

        let transitionDuration = transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: transitionDuration,
            delay: 0,
            options: [.curveLinear, .preferredFramesPerSecond60]
        ) {
            toView.frame = transitionContext.finalFrame(for: toViewController)
        } completion: { _ in
            let wasCanceled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCanceled)
        }
    }
}

final class PopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
              let toView = transitionContext.view(forKey: UITransitionContextViewKey.to),
              let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {
            return
        }
        let containerView = transitionContext.containerView
        fromView.frame = transitionContext.initialFrame(for: fromViewController)
        containerView.insertSubview(toView, belowSubview: fromView)

        let transitionDuration = transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: transitionDuration,
            delay: 0,
            options: [.curveLinear, .preferredFramesPerSecond60]
        ) {
            fromView.frame = CGRect(
                x: toView.frame.origin.x ?? 0,
                y: toView.frame.maxY ?? UIScreen.main.bounds.size.height,
                width: toView.frame.width ?? UIScreen.main.bounds.size.width,
                height: toView.frame.height ?? UIScreen.main.bounds.size.height
            )
        } completion: { _ in
            let wasCanceled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCanceled)
        }
    }
}
