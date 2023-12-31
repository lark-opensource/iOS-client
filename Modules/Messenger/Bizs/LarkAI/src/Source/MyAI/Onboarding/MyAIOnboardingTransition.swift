//
//  MyAIOnboardingTransition.swift
//  LarkAI
//
//  Created by Hayden on 16/6/2023.
//

import UIKit

final class MyAIOnboardingTransition: NSObject {

    enum OperationType {
        case push
        case pop
    }

    private var operationType: OperationType
    private weak var transitionContext: UIViewControllerContextTransitioning?

    init(type: OperationType) {
        self.operationType = type
        super.init()
    }
}

extension MyAIOnboardingTransition: UIViewControllerAnimatedTransitioning {

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        switch operationType {
        case .push:
            pushAnimation(transitionContext: transitionContext)
        case .pop:
            popAnimation(transitionContext: transitionContext)
        }
    }
}

extension MyAIOnboardingTransition {

    private func pushAnimation(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? MyAIOnboardingInitController,
              let toVC = transitionContext.viewController(forKey: .to) as? MyAIOnboardingConfirmController else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
         // 添加到containerView中
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)

        toVC.view.alpha = 0
        UIView.animate(withDuration: 0.2) {
            toVC.view.alpha = 1
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            toVC.view.layoutIfNeeded()
            DispatchQueue.main.async {
                toVC.animateToShow()
            }
        }
     }

     private func popAnimation(transitionContext: UIViewControllerContextTransitioning) {
         guard let fromVC = transitionContext.viewController(forKey: .from) as? MyAIOnboardingConfirmController,
               let toVC = transitionContext.viewController(forKey: .to) as? MyAIOnboardingInitController else {
             transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
             return
         }
         let containerView = transitionContext.containerView
         containerView.addSubview(toVC.view)
         containerView.addSubview(fromVC.view)
         toVC.view.frame = transitionContext.finalFrame(for: toVC)

         UIView.animate(withDuration: 0.4) {
             fromVC.greetLabel.alpha = 0
             fromVC.agreeInfoLabel.alpha = 0
             fromVC.avatarView.transform = .identity
             fromVC.shadowView.transform = .identity
         }
         UIView.animate(withDuration: 0.2, delay: 0.3) {
             fromVC.view.alpha = 0
         } completion: { _ in
             transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
         }
     }
}
