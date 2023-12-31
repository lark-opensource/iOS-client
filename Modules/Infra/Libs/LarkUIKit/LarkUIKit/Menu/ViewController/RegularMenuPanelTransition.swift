//
//  RegularMenuPanelTransition.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/18.
//

import Foundation
import UIKit

/// Regular菜单面板模态弹出的转场动画
final class RegularMenuPanelTransition: NSObject, UIViewControllerAnimatedTransitioning {

    /// 动画时间
    private var duration = 0.25

    /// true是弹出，false是dismiss
    var presented: Bool = true

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        if presented {
            guard let toViewController = transitionContext.viewController(forKey: .to) as? UIViewController & MenuPanelVisibleProtocol else {
                transitionContext.completeTransition(true)
                return
            }
            // 一定要加入到containerView中，否则不会显示
            containerView.addSubview(toViewController.view)
            containerView.bringSubviewToFront(toViewController.view)

            toViewController.show(animation: true, duration: duration, complete: {
                transitionContext.completeTransition($0)
            })
        } else {
            guard let fromViewController = transitionContext.viewController(forKey: .from) as? UIViewController & MenuPanelVisibleProtocol else {
                transitionContext.completeTransition(true)
                return
            }
            if let toView = transitionContext.view(forKey: .to) {
                containerView.addSubview(toView)
            }

            containerView.bringSubviewToFront(fromViewController.view)
            fromViewController.hide(animation: true, duration: duration) {
                transitionContext.completeTransition($0)
            }
        }

    }
}
