//
//  CustomDismissAnimated.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/10/30.
//
import SKUIKit

class CustomDismissAnimated: NSObject {

}

extension CustomDismissAnimated: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toViewController: UIViewController? = transitionContext.viewController(forKey: .to)
        let fromViewController: UIViewController? = transitionContext.viewController(forKey: .from)

        var toView: UIView?
        var fromView: UIView?

        if transitionContext.responds(to: #selector(UIViewControllerContextTransitioning.view(forKey:))) {
            fromView = transitionContext.view(forKey: .from)
            toView = transitionContext.view(forKey: .to)
        } else {
            fromView = fromViewController?.view
            toView = toViewController?.view
        }

        //将toView加到fromView的下面，非常重要！！！
        if let aView = toView, let aView1 = fromView {
            transitionContext.containerView.insertSubview(aView, belowSubview: aView1)
        }

        let width: CGFloat = fromView?.window?.frame.size.width ?? 0
        let height: CGFloat = fromView?.window?.frame.size.height ?? 0

        fromView!.frame = CGRect(x: 0, y: 0, width: width, height: height)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromView!.frame = CGRect(x: width, y: 0, width: width, height: height)
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
