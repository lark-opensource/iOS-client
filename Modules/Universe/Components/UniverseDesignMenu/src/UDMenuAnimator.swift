//
//  UDMenuAnimator
//  UniverseDesignMenu
//
//  Created by qsc on 2020/11/5.
//  Copyright © ByteDance. All rights reserved.
//

import UIKit
import Foundation

enum PresentationType {
    case present
    case dismiss
}

class UDMenuAminator: NSObject, UIViewControllerAnimatedTransitioning {
    static let DefaultAnimateDuration: TimeInterval = 0.3

    var style: PresentationType
    var animationDuration: TimeInterval

    required init(presentStyle: PresentationType) {
        self.style = presentStyle
        self.animationDuration = UDMenuAminator.DefaultAnimateDuration
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let menuVC: UIViewController?
        switch style {
        case .present:
            menuVC = transitionContext.viewController(forKey: .to)
        case .dismiss:
            menuVC = transitionContext.viewController(forKey: .from)
        }
        guard let vc = menuVC else {
            return
        }
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        vc.view.alpha = style == .present ? 0.0 : 1.0

        containerView.addSubview(vc.view)

        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut) {
            vc.view.alpha = self.style == .present ? 1.0 : 0.0
        } completion: { (finished) in
            transitionContext.completeTransition(finished)
        }
    }
}
