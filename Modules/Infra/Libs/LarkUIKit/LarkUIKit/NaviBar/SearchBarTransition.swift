//
//  SearchBarTransition.swift
//  LarkUIKit
//
//  Created by CharlieSu on 2018/11/27.
//

import Foundation
import UIKit

public extension UIViewController {
    var transitionViewController: UIViewController? {
        if let navigation = self as? UINavigationController {
            return navigation.topViewController?.transitionViewController
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.transitionViewController
        }
        return self
    }
}

private extension SearchUITextField {
    var copied: SearchUITextField {
        let copied = SearchUITextField()
        copied.placeholder = self.placeholder
        copied.backgroundColor = self.backgroundColor
        copied.frame = self.frame
        return copied
    }
}

public protocol SearchBarTransitionBottomVCDataSource: UIViewControllerTransitioningDelegate, CustomNaviAnimation {
    var naviBarView: UIView { get }
    var searchTextField: SearchUITextField { get }
}

public protocol SearchBarTransitionTopVCDataSource {
    var searchBar: SearchBar { get }
    var bottomView: UIView { get }
}

extension SearchBarTransitionTopVCDataSource {
    var searchTextField: SearchUITextField { return searchBar.searchTextField }
    var cancelButton: UIButton { return searchBar.cancelButton }
}

public final class SearchBarPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromDataSource = fromVC.transitionViewController as? SearchBarTransitionBottomVCDataSource,
            let toDataSource = toVC.transitionViewController as? SearchBarTransitionTopVCDataSource else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        toVC.view.frame = containerView.bounds
        toVC.view.layoutIfNeeded()

        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.N00
        containerView.addSubview(bgView)

        let textFieldScreenShot = fromDataSource.searchTextField.copied
        containerView.addSubview(textFieldScreenShot)
        textFieldScreenShot.frame = fromDataSource.searchTextField.convert(fromDataSource.searchTextField.bounds, to: containerView)
        toDataSource.searchTextField.becomeFirstResponder()

        let naviBarScreenShot = UIImageView(image: fromDataSource.naviBarView.lu.screenshot())
        containerView.addSubview(naviBarScreenShot)
        naviBarScreenShot.frame = fromDataSource.naviBarView.convert(fromDataSource.naviBarView.bounds, to: containerView)

        let cancelScreenShot = UIImageView(image: toDataSource.cancelButton.lu.screenshot())
        containerView.addSubview(cancelScreenShot)
        cancelScreenShot.bounds = toDataSource.cancelButton.bounds
        cancelScreenShot.frame.centerY = textFieldScreenShot.frame.centerY
        cancelScreenShot.frame.left = textFieldScreenShot.frame.right + 12
        cancelScreenShot.alpha = 0

        bgView.frame.size = CGSize(width: containerView.bounds.width, height: textFieldScreenShot.frame.maxY)

        toVC.view.alpha = 0
        fromDataSource.searchTextField.alpha = 0
        fromDataSource.naviBarView.alpha = 0
        toDataSource.searchTextField.alpha = 0
        toDataSource.cancelButton.alpha = 0
        let originBottomTop = toDataSource.bottomView.frame.top
        toDataSource.bottomView.frame.top += 28
        toDataSource.bottomView.alpha = 0
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                toVC.view.alpha = 1
                textFieldScreenShot.frame = containerView.convert(
                    toDataSource.searchTextField.bounds,
                    from: toDataSource.searchTextField)
                naviBarScreenShot.frame.bottom = 0
                naviBarScreenShot.alpha = 0
                cancelScreenShot.frame = containerView.convert(toDataSource.cancelButton.bounds, from: toDataSource.cancelButton)
                cancelScreenShot.alpha = 1
                toDataSource.bottomView.frame.top = originBottomTop
                toDataSource.bottomView.alpha = 1
                bgView.frame.bottom = textFieldScreenShot.frame.bottom
            }
        ) { (_) in
            textFieldScreenShot.removeFromSuperview()
            naviBarScreenShot.removeFromSuperview()
            cancelScreenShot.removeFromSuperview()
            bgView.removeFromSuperview()
            fromDataSource.searchTextField.alpha = 1
            fromDataSource.naviBarView.alpha = 1
            toDataSource.searchTextField.alpha = 1
            toDataSource.cancelButton.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

public final class SearchBarDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromDataSource = fromVC.transitionViewController as? SearchBarTransitionTopVCDataSource,
            let toDataSource = toVC.transitionViewController as? SearchBarTransitionBottomVCDataSource else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView

        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.N00
        containerView.addSubview(bgView)

        let textFieldScreenShot = fromDataSource.searchTextField.copied
        containerView.addSubview(textFieldScreenShot)
        textFieldScreenShot.frame = fromDataSource.searchTextField.convert(fromDataSource.searchTextField.bounds, to: containerView)

        let cancelScreenShot = UIImageView(image: fromDataSource.cancelButton.lu.screenshot())
        containerView.addSubview(cancelScreenShot)
        cancelScreenShot.frame = fromDataSource.cancelButton.convert(fromDataSource.cancelButton.bounds, to: containerView)

        let originFrame = toDataSource.naviBarView.frame
        let naviBarScreenShot = UIImageView(image: toDataSource.naviBarView.lu.screenshot())
        containerView.addSubview(naviBarScreenShot)
        naviBarScreenShot.frame = originFrame
        naviBarScreenShot.frame.origin = .zero
        naviBarScreenShot.frame.bottom = 0
        naviBarScreenShot.alpha = 0

        fromDataSource.searchTextField.alpha = 0
        fromDataSource.cancelButton.alpha = 0
        toDataSource.searchTextField.alpha = 0
        toDataSource.naviBarView.alpha = 0
        let originBottomTop = fromDataSource.bottomView.frame.top
        bgView.frame.size = CGSize(
            width: containerView.bounds.width,
            height: textFieldScreenShot.frame.bottom - naviBarScreenShot.frame.top)
        bgView.frame.top = naviBarScreenShot.frame.top

        containerView.insertSubview(toVC.view, at: 0)
        toVC.view.frame = containerView.bounds

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
                        textFieldScreenShot.frame = containerView.convert(
                            toDataSource.searchTextField.bounds,
                            from: toDataSource.searchTextField)

                        cancelScreenShot.frame = cancelScreenShot.frame
                        cancelScreenShot.frame.centerY = textFieldScreenShot.frame.centerY
                        cancelScreenShot.frame.left = textFieldScreenShot.frame.right + 12
                        cancelScreenShot.alpha = 0

                        naviBarScreenShot.frame = containerView.convert(toDataSource.naviBarView.bounds, from: toDataSource.naviBarView)
                        naviBarScreenShot.alpha = 1

                        bgView.frame.bottom = textFieldScreenShot.frame.bottom

                        fromDataSource.bottomView.frame.top += 28
                        fromDataSource.bottomView.alpha = 0

                        fromVC.view.alpha = 0
        }) { (_) in
            textFieldScreenShot.removeFromSuperview()
            naviBarScreenShot.removeFromSuperview()
            cancelScreenShot.removeFromSuperview()
            bgView.removeFromSuperview()
            fromVC.view.alpha = 1
            fromDataSource.searchTextField.alpha = 1
            fromDataSource.cancelButton.alpha = 1
            toDataSource.searchTextField.alpha = 1
            toDataSource.naviBarView.alpha = 1
            fromDataSource.bottomView.frame.top = originBottomTop
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

public protocol NewSearchBarTransitionBottomVC: UIViewControllerTransitioningDelegate, CustomNaviAnimation, UIViewController {
    var naviBarView: UIView { get }
}

public final class SearchBarNewPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromDataSource = (fromVC as? CustomNaviAnimation)?.animationProxy as? NewSearchBarTransitionBottomVC,
            let toDataSource = toVC.transitionViewController as? SearchBarTransitionTopVCDataSource else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        toVC.view.frame = containerView.bounds
        toVC.view.layoutIfNeeded()

        let bgView = UIView()
        containerView.insertSubview(bgView, belowSubview: toVC.view)


        let naviBarScreenShot = UIImageView(image: fromDataSource.naviBarView.lu.screenshot())
        containerView.addSubview(naviBarScreenShot)
        naviBarScreenShot.frame = fromDataSource.naviBarView.convert(fromDataSource.naviBarView.bounds, to: containerView)

        // 50是顶部topMask的高度
        bgView.frame = CGRect(x: 0, y: 0, width: naviBarScreenShot.frame.width, height: 50 + naviBarScreenShot.frame.height)
        bgView.backgroundColor = fromDataSource.naviBarView.backgroundColor

        toVC.view.alpha = 0
        toVC.view.frame.top += 28

        fromDataSource.naviBarView.alpha = 0

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                naviBarScreenShot.frame.bottom = 0
                naviBarScreenShot.alpha = 0
                toVC.view.alpha = 1
                toVC.view.frame.top = 0
            }
        ) { (_) in
            naviBarScreenShot.removeFromSuperview()
            bgView.removeFromSuperview()
            fromDataSource.naviBarView.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

public final class SearchBarNewDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromDataSource = fromVC.transitionViewController as? SearchBarTransitionTopVCDataSource,
            let toDataSource = (toVC as? CustomNaviAnimation)?.animationProxy as? NewSearchBarTransitionBottomVC else {
                transitionContext.completeTransition(false)
                return
        }

        let containerView = transitionContext.containerView

        let bgView = UIView()
        containerView.addSubview(bgView)

        let originFrame = toDataSource.naviBarView.convert(toDataSource.naviBarView.bounds, to: containerView)
        let naviBarScreenShot = UIImageView(image: toDataSource.naviBarView.lu.screenshot())
        let bgNaviBar = UIView()
        bgNaviBar.addSubview(naviBarScreenShot)
        containerView.addSubview(bgNaviBar)

        // 50是顶部topMask的高度
        naviBarScreenShot.frame = CGRect(x: 0, y: 50, width: originFrame.size.width, height: originFrame.size.height)

        bgNaviBar.backgroundColor = toDataSource.naviBarView.backgroundColor
        bgNaviBar.frame = originFrame
        bgNaviBar.frame.origin = .zero
        // 50是顶部topMask的高度
        bgNaviBar.frame.origin.y -= 50
        bgNaviBar.frame.size.height += 50
        bgNaviBar.frame.bottom = 0
        bgNaviBar.alpha = 0

        bgView.frame = originFrame

        containerView.insertSubview(toVC.view, at: 0)
        toVC.view.frame = containerView.bounds

        toDataSource.naviBarView.alpha = 0

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
                        bgNaviBar.frame.bottom = toDataSource.naviBarView.frame.bottom
                        bgNaviBar.alpha = 1
                        fromVC.view.alpha = 0
                        fromVC.view.frame.top += 28
        }) { (_) in
            bgView.removeFromSuperview()
            bgNaviBar.removeFromSuperview()
            fromVC.view.alpha = 1
            fromVC.view.frame.top -= 28
            toDataSource.naviBarView.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
