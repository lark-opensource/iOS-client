//
//  Mailfff.swift
//  MailSDK
//
//  Created by majx on 2020/9/15.
//

import Foundation

struct DropMenuAnimation {
    static let showDuration: TimeInterval = 0.45 // 0.3 * 1.5
    static let hideDuration: TimeInterval = 0.36 // 0.3 * 1.2
  static var springDamping: CGFloat {
      if Display.pad {
          return 1.0
      }
      return 1.0  // 0.8
  }
  static let springVelocity: CGFloat = 5
}

protocol MailDropMenuTransitionDelegate: AnyObject {
    func getMenuContentView() -> UIView
    func dismissMenuContent()
    func showMenuContent()
}

class MailDropMenuTransition: NSObject, UIViewControllerAnimatedTransitioning {
    enum Style {
        case show
        case dismiss
    }
    let style: Style
    init(_ style: Style) {
        self.style = style
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return DropMenuAnimation.showDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch style {
        case .show: _doShow(using: transitionContext)
        case .dismiss: _doDismiss(using: transitionContext)
        }
    }

    private func _doShow(using transitionContext: UIViewControllerContextTransitioning) {
        guard let dropMenuVC = transitionContext.viewController(forKey: .to) as? MailDropMenuTransitionDelegate else {
            return
        }
        if let view = (dropMenuVC as? UIViewController)?.view {
            transitionContext.containerView.addSubview(view)
        }
        dropMenuVC.getMenuContentView().isHidden = false
        _doAnimation(using: transitionContext, animations: {
            dropMenuVC.showMenuContent()
        }, completion: nil)
    }

    private func _doDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard let dropMenuVC = transitionContext.viewController(forKey: .from) as? MailDropMenuTransitionDelegate else {
            return
        }
        _doAnimation(using: transitionContext, animations: {
            dropMenuVC.dismissMenuContent()
        }) { (_) in
            dropMenuVC.getMenuContentView().isHidden = true
        }
    }

    private func _doAnimation(using transitionContext: UIViewControllerContextTransitioning,
                              animations: @escaping () -> Void,
                              completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: DropMenuAnimation.showDuration,
                       delay: 0,
                       usingSpringWithDamping: DropMenuAnimation.springDamping,
                       initialSpringVelocity: DropMenuAnimation.springVelocity,
                       options: [.allowUserInteraction, .layoutSubviews],
                       animations: animations) { _ in
                        transitionContext.completeTransition(true)
                        completion?(true)
        }
    }
}
