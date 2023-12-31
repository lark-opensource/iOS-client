//
//  BTController+Transition.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/8/4.
//  


import Foundation
import SKUIKit
import SKFoundation

extension BTController: UIViewControllerTransitioningDelegate {

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard self.delegate?.cardGetBrowserController() != nil else {
            return nil
        }
        if UserScopeNoChangeFG.ZJ.btCardReform {
            dismissAnimation.animationPosition = .right
        } else {
            dismissAnimation.animationPosition = .bottom
        }
        return dismissAnimation
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return dismissTransition.interactive ? dismissTransition : nil
    }
    
    func animationController(forPresented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard UserScopeNoChangeFG.ZJ.btCardReform, let browserVC = self.delegate?.cardGetBrowserController() else { return nil }
        currentCardPresentMode = nextCardPresentMode
        viewModel.currentCardPresentMode = .card
        return presentAnimation
    }
    
    func interactionControllerForPresentation(using: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

enum BTAnimationPosition {
    /// 底部弹出
    case bottom
    /// 右边弹出
    case right
}

extension BTController {
    func prepareForInteractiveDismiss() {
        guard !UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        view.backgroundColor = .clear
        var frame = view.bounds
        frame.size.height = view.frame.size.height * 2
        frame.origin.y = -view.frame.size.height
        backgroundView.frame = frame
        backgroundView.backgroundColor = defaultBackgroundColor

        var superView = view
        while superView != nil {
            superView?.clipsToBounds = false
            superView = superView?.superview
        }
        view.insertSubview(backgroundView, at: 0)
//        UIView.animate(withDuration: 0.2) { [self] in
//            titleView.alpha = 0
//        }
    }
    
    func restoreForInteractiveDismiss() {
        guard !UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        var superView = view
        while superView != nil {
            superView?.clipsToBounds = false
            superView = superView?.superview
        }
        
        backgroundView.removeFromSuperview()
        view.backgroundColor = defaultBackgroundColor
//        UIView.animate(withDuration: 0.2) { [self] in
//            titleView.alpha = 1
//        }
    }
    
    func updateBackgroundViewColor(_ fraction: CGFloat) {
        backgroundView.alpha = max(1 - fraction, 0.3)
    }
}
