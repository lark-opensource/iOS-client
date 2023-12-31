//
//  UIPresentationController+DynamicModal.swift
//  ByteViewUI
//
//  Created by Tobb Huang on 2023/5/9.
//

import Foundation

extension UIPresentationController {

    private static var panViewControllerKey: String = "panViewControllerKey"

    var panViewController: PanViewController? {

        get {
            let weakBox = objc_getAssociatedObject(
                self,
                &UIPresentationController.panViewControllerKey
                ) as? WeakBox<UIViewController>

            return weakBox?.value as? PanViewController
        }

        set {
            objc_setAssociatedObject(
                self,
                &UIPresentationController.panViewControllerKey,
                WeakBox<UIViewController>(newValue),
                .OBJC_ASSOCIATION_RETAIN)
        }

    }

    func presentForOverFullScreen(_ transitionCoordinator: UIViewControllerTransitionCoordinator?, config: DynamicModalConfig) {
        transitionCoordinator?.animate(alongsideTransition: { ctx in
            var transitionView: UIView?
            if config.presentationStyle == .pan {
                if let view = self.presentedViewController.panViewController?.view.superview {
                    transitionView = view
                } else if let view = self.presentedViewController.navigationController?.panViewController?.view.superview {
                    transitionView = view
                }
            } else {
                if let view = self.presentedViewController.view.superview {
                    transitionView = view
                } else if let view = self.presentedViewController.navigationController?.view.superview {
                    transitionView = view
                }
            }
            if let transitionView = transitionView {
                self.configTransitionView(config: config, transitionView: transitionView, ctx: ctx)
            } else {
                assertionFailure("transitionView is nil")
                return
            }
        })
    }

    func configTransitionView(config: DynamicModalConfig, transitionView: UIView, ctx: UIViewControllerTransitionCoordinatorContext) {
        let backgroundColor = config.backgroundColor
        transitionView.backgroundColor = backgroundColor

        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.backgroundColor))
        animation.fromValue = backgroundColor.withAlphaComponent(0).cgColor
        animation.toValue = backgroundColor.cgColor
        animation.duration = ctx.transitionDuration
        animation.timingFunction = ctx.completionCurve.timingFunction
        transitionView.layer.add(animation, forKey: nil)
    }
}

private extension UIView.AnimationCurve {
    var timingFunction: CAMediaTimingFunction {
        let name: CAMediaTimingFunctionName
        switch self {
        case .easeIn:
            name = .easeIn
        case .easeOut:
            name = .easeOut
        case .easeInOut:
            name = .easeInEaseOut
        case .linear:
            name = .linear
        @unknown default:
            name = .linear
        }
        return CAMediaTimingFunction(name: name)
    }
}
