//
//  AppCenterCatagoryPresentAnimation.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/10/18.
//

import Foundation

/// 应用中心主页侧边栏专用的present动画工具，日后可以抽出
final class AppCenterCatagoryPresentAnimation: NSObject {

    /// 针对present和dismiss设置
    var isPresenting = false
    /// 动画时常
    let presentAnimationDuration = 0.3
}

extension AppCenterCatagoryPresentAnimation: UIViewControllerAnimatedTransitioning {

    /// 控制转场时常
    /// - Parameter transitionContext: 上下文
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return presentAnimationDuration
    }

    /// 控制转场动画
    /// - Parameter transitionContext: 上下文
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        /// 获取fromView和toView
        let toView = transitionContext.view(forKey: .to) ?? transitionContext.viewController(forKey: .to)?.view
        let fromView = transitionContext.view(forKey: .from) ?? transitionContext.viewController(forKey: .from)?.view
        guard let toView = toView, let fromView = fromView else {
            return
        }
        var transView: UIView
        if isPresenting {
            transView = toView
            transitionContext.containerView.addSubview(toView)
        } else {
            transView = fromView
            transitionContext.containerView.addSubview(fromView)
        }
        let size = transitionContext.containerView.frame.size
        transView.frame = CGRect(origin: CGPoint(x: isPresenting ? size.width : 0, y: 0), size: size)
        UIView.animate(
            withDuration: presentAnimationDuration,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                transView.frame = CGRect(origin: CGPoint(x: self.isPresenting ? 0 : size.width, y: 0), size: size)
            },
            completion: { (_) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
