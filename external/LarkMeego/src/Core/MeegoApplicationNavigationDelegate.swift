//
//  MeegoApplicationNavigationDelegate.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/7/30.
//

import Foundation
import LarkFlutterContainer
import LarkContainer
import ThreadSafeDataStructure
import EEAtomic

final class ModifiedNavigationContext {
    private(set) weak var navigationController: UINavigationController?
    private(set) weak var lastNavigationDelegate: UINavigationControllerDelegate?

    var isValid: Bool {
        navigationController != nil
    }

    init(navigationController: UINavigationController? = nil, lastNavigationDelegate: UINavigationControllerDelegate? = nil) {
        self.navigationController = navigationController
        self.lastNavigationDelegate = lastNavigationDelegate
    }
}

final class MeegoApplicationNavigationDelegate: NSObject, UINavigationControllerDelegate {
    let animatorMatcher: AnimatorMatcher
    private var navigationContexts: SafeArray<ModifiedNavigationContext> = [] + .readWriteLock
    private let unfairLock = UnfairLockCell()

    init(userResolver: UserResolver) {
        animatorMatcher = AnimatorMatcher(userResolver: userResolver)
    }

    func update(with context: ModifiedNavigationContext) {
        guard context.navigationController != nil else {
            return
        }
        unfairLock.withLocking {
            let oldIndex = navigationContexts.firstIndex { $0.navigationController == context.navigationController }
            if let oldIndex = oldIndex {
                if context.lastNavigationDelegate != nil {
                    navigationContexts[oldIndex] = context
                } else {
                    navigationContexts.remove(at: oldIndex)
                }
            } else {
                navigationContexts.append(context)
            }
        }
    }

    func rollback() {
        unfairLock.withLocking {
            navigationContexts.filter { $0.isValid }.forEach { ctx in
                ctx.navigationController?.delegate = ctx.lastNavigationDelegate
            }
            navigationContexts.removeAll()
        }
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if !animatorMatcher.hasMatch(viewController) {
            getOldDelegate(with: navigationController)?.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if !animatorMatcher.hasMatch(viewController) {
            getOldDelegate(with: navigationController)?.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        let oldDelegate = getOldDelegate(with: navigationController)
        let canProxy = oldDelegate?.responds(to: #selector(navigationControllerSupportedInterfaceOrientations(_:))) ?? false
        if let oldDelegate = oldDelegate, canProxy {
            return oldDelegate.navigationControllerSupportedInterfaceOrientations!(navigationController)
        } else {
            return navigationController.topViewController?.supportedInterfaceOrientations ?? .portrait
        }
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        let oldDelegate = getOldDelegate(with: navigationController)
        let canProxy = oldDelegate?.responds(to: #selector(navigationControllerPreferredInterfaceOrientationForPresentation(_:))) ?? false
        if let oldDelegate = oldDelegate, canProxy {
            return oldDelegate.navigationControllerPreferredInterfaceOrientationForPresentation!(navigationController)
        } else {
            return navigationController.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
        }
    }

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        func forward() -> UIViewControllerAnimatedTransitioning? {
            getOldDelegate(with: navigationController)?.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC)
        }
        switch operation {
        case .push: return animatorMatcher.hasMatch(toVC) ? PushAnimator() : forward()
        case .pop: return animatorMatcher.hasMatch(fromVC) ? PopAnimator() : forward()
        default: return forward()
        }
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animationController is PushAnimator || animationController is PopAnimator {
            return nil
        }
        return getOldDelegate(with: navigationController)?.navigationController?(navigationController, interactionControllerFor: animationController)
    }
}

private extension MeegoApplicationNavigationDelegate {
    func getOldDelegate(with navigationController: UINavigationController) -> UINavigationControllerDelegate? {
        return navigationContexts.first { $0.navigationController == navigationController }?.lastNavigationDelegate
    }
}
