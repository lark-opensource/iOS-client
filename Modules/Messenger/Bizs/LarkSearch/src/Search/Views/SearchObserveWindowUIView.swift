//
//  SearchObserveWindowUIView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/6/30.
//

import UIKit
import LarkUIKit
import LarkSearchCore
import LarkSDKInterface

class SearchObserveWindowUIView: UIView {
    weak var base: UIViewController?
    override func didMoveToWindow() {
        guard self.superview != nil, self.window == nil, let base = self.base, let navigationController = base.navigationController else { return }

        // Tab页离开时，退出大搜, 目前通过所在的NavigationController不可见, 且selectedViewController和响应链不一致来判断
        // tabbar selectedViewController KVO and method hook not work..., use window visible check instead
        if
          navigationController.view.window == nil,
          let tabbarController = navigationController.tabBarController,
          let tabbarControllerSelected = tabbarController.selectedViewController,
          !Search.UIResponderIterator(start: navigationController)
            .prefix(while: { $0 != tabbarController })
            .contains(tabbarControllerSelected),

          // SearchViewController in navigationController and not root
          case let vcs = navigationController.viewControllers,
          let currentIndex = vcs.lastIndex(of: base),
          currentIndex > 0,

          // NOTE: container不需要这个子视图的逻辑. 但目前存在部分详情页，没有加入到上导航里
          let top = navigationController.topViewController {
            // do pop when top is search controller or child controller
            switch top {
            case is SearchBarTransitionTopVCDataSource:
                navigationController.setViewControllers(Array(vcs[0..<currentIndex]), animated: false)
            default: return
            }
        }
    }
}
