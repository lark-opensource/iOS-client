//
//  PanelBrowserPresentAnimation.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/9/8.
//

import UIKit
import LarkUIKit
import EENavigator

class PanelBrowserPresentAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    var duration: Double = 0.3
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        guard let toViewController = transitionContext.viewController(forKey: .to) as? UIViewController, let toView = transitionContext.view(forKey: .to) as? UIView else  {
            transitionContext.completeTransition(true)
            return
        }
        
        let maskView = UIView(frame: containerView.bounds)
        maskView.backgroundColor = UIColor.ud.bgMask
        maskView.alpha = 0.0
        containerView.addSubview(maskView)
        
        // 由下向上从底部出现
        var toViewInitialFrame = transitionContext.initialFrame(for: toViewController)
        let toViewFinalFrame = toView.frame
        
        containerView.addSubview(toView)
        toViewInitialFrame.origin = CGPoint(x: containerView.bounds.minX, y: containerView.bounds.maxY)
        toViewInitialFrame.size = toViewFinalFrame.size
        toView.frame = toViewInitialFrame
       
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0, 0.4, 0.2, 1))
        UIView.animate(withDuration: duration, animations: {
            maskView.alpha = 1.0
            toView.frame = toViewFinalFrame
        }) { finished in
            maskView.removeFromSuperview()
            if let containerNav = toViewController as? LkNavigationController {
                if let container = containerNav.visibleViewController as? PanelBrowserViewContainer {
                    container.showMaskBgView(true)
                }
            }
            let wasCancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCancelled)
        }
        CATransaction.commit()
    }
}
