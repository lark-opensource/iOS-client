//
//  CustomPresentAnimated.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/10/30.
//

class CustomPresentAnimated: NSObject {

}

extension CustomPresentAnimated: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController: UIViewController? = transitionContext.viewController(forKey: .from) //主页VC
        let toViewController: UIViewController? = transitionContext.viewController(forKey: .to) //present的VC

        let containerView: UIView = transitionContext.containerView //转场的容器视图，动画完成后，会消失
        var fromView: UIView?
        var toView: UIView?

//        if transitionContext.responds(to: #selector(UIViewControllerContextTransitioning.view(forKey:))) {
//            fromView = transitionContext.view(forKey: .from)
//            toView = transitionContext.view(forKey: .to)
//        } else {
            fromView = fromViewController?.view
            toView = toViewController?.view
//        }

        let isPresenting: Bool = toViewController?.presentingViewController == fromViewController

        let fromFrame: CGRect = transitionContext.initialFrame(for: fromViewController!)
        let toFrame: CGRect = transitionContext.finalFrame(for: toViewController!)

        if isPresenting {
            fromView!.frame = fromFrame
            toView!.frame = toFrame.offsetBy(dx: toFrame.size.width, dy: 0)
        }

        if isPresenting {
            containerView.addSubview(toView!)
        }

        let transitionDuration: TimeInterval = self.transitionDuration(using: transitionContext)

        UIView.animate(withDuration: transitionDuration, animations: {
            if isPresenting {
                toView!.frame = toFrame
                fromView!.frame = fromFrame
            }
        }, completion: { _ in
            let wasCancelled: Bool = transitionContext.transitionWasCancelled

            if wasCancelled {
                toView!.removeFromSuperview()
            }

            transitionContext.completeTransition(!wasCancelled)
        })
    }
}
