//
//  PanelBrowserDismissAnimation.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/9/8.
//

import UIKit
import LarkUIKit

class PanelBrowserDismissAnimation: NSObject, UIViewControllerAnimatedTransitioning {

    var duration: Double = 0.3
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? UIViewController,
              let toViewController = transitionContext.viewController(forKey: .to) as? UIViewController,
              let fromView = transitionContext.view(forKey: .from) else  {
            transitionContext.completeTransition(true)
            return
        }
        
        // 部分ViewController可能会在viewWillDisappear时显示导航栏，这导致导航栏显示在dismiss动画上、因此隐藏导航栏
        fromViewController.navigationController?.isNavigationBarHidden = true
        if let containerNav = toViewController as? LkNavigationController {
            if let container = containerNav.visibleViewController as? PanelBrowserViewContainer {
                container.showMaskBgView(false)
            }
        }
        
        let maskView = UIView(frame: containerView.bounds)
        maskView.backgroundColor = UIColor.ud.bgMask
        maskView.alpha = 1.0
        containerView.addSubview(maskView)
        
        containerView.addSubview(fromView)
        
        let fromViewFinalFrame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.size.height)
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.3, 0, 0.9, 0.6))
        UIView.animate(withDuration: duration, animations: {
            maskView.alpha = 0
            fromView.frame = fromViewFinalFrame
        }) { finished in
            maskView.removeFromSuperview()
            let wasCancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCancelled)
        }
        CATransaction.commit()
    }
}
