//
//  FeedMainViewController+SearchBarTransitionBottomVCDataSource
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import LarkUIKit

extension FeedMainViewController: UIViewControllerTransitioningDelegate, CustomNaviAnimation {
    var animationProxy: CustomNaviAnimation? {
        animatedTabBarController as? CustomNaviAnimation
    }

    func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else { return nil }
        return SearchBarPresentTransition()
    }

    func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else { return nil }
        return SearchBarDismissTransition()
    }
}
