//
//  UIWindow+GadgetUtils.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/19.
//

import UIKit
import LarkUIKit
import LarkSplitViewController
import LKCommonsLogging

extension UIWindow {
    /// 新版三栏
    /// 返回Window中聊天、文档等页面中主要的SplitVC
    /// - Note: ⚠️这个机制十分的严格，它返回的SplitVC必须是RootNavigationController中的MainTabbarController中当前选择的LKSplitViewController
    ///         不符合这个模式的均被视为没有SplitVC⚠️
    var op_newSplitViewControllerStrictly: SplitViewController? {
        /// 这里应该严格要求是RootNavigationController，但是由于引入LarkNavigation会造成循环依赖，因此这里因此这里降级判断为LkNavigationController
        /// ⚠️注意Lark中rootVC必须是一个UINavigationController，否则是视图层级的严重错误⚠️
        guard let rootVC = self.rootViewController as? LkNavigationController else {
            let errMsg = "getSplitViewControllerStrict don't find RootNavigationController"
            GadgetNavigator.logger.error(errMsg)
            assertionFailure(errMsg)
            return nil
        }
        /// 这里应该严格要求是MainTabbarController，但是由于引入LarkNavigation会造成循环依赖，而且它还是一个interal访问权限，因此这里降级判断为UITabBarController
        guard let topVC = rootVC.topViewController as? UITabBarController else {
            GadgetNavigator.logger.info("getSplitViewControllerStrict don't find MainTabbarController")
            return nil
        }
        /// 这里严格判断是LKSplitViewController类型
        guard let splitVC = topVC.selectedViewController as? SplitViewController else {
            GadgetNavigator.logger.info("getSplitViewControllerStrict don't find LKSplitViewController")
            return nil
        }
        GadgetNavigator.logger.info("getSplitViewControllerStrict  find LKSplitViewController: \(splitVC)")
        return splitVC
    }

    /// 获取Window的RootVC中适合的UINavigationController来响应路由
    /// - Note: 如果找不到则会返回`nil`，则没有
    var op_navigationControllerForRootViewController: UINavigationController? {
        self.rootViewController as? UINavigationController
    }

    /// 找到window以presentedViewController方式弹出的最上面的VC
    /// - Note: 如果找不到则会返回`nil`，很简单，找不到就表示它没有任何present弹出VC
    var op_topMostPresentViewController: UIViewController? {
        if var rootPresentViewController = self.rootViewController?.presentedViewController {
            while let presentViewController = rootPresentViewController.presentedViewController {
                rootPresentViewController = presentViewController
            }
            return rootPresentViewController
        } else {
            return nil
        }
    }
}

extension SplitViewController {

    /// 判断这个SplitVC的lark显示模式
    /// - Note: ⚠️当前Lark的环境中，只有存在SplitVC的时候才有可能是单栏或者双栏模式⚠️
    private var op_larkDisplayMode: LarkDisplayMode {
        /// 如果有SplitVC才有可能是单栏或双栏模型，否则都是正常的显示模式
        if !self.isCollapsed, (self.splitMode == .twoBesideSecondary || self.splitMode == .twoOverSecondary || self.splitMode == .twoDisplaceSecondary) {
            /// 经过与李晨的讨论，allVisible模式才被我们视为双栏模式
            return .doubleColumn
        } else {
            return .singleColumn
        }
    }


    /// 获取SplitVC中适合的UINavigationController来响应路由
    /// - Note: 如果找不到则会返回`nil`，则没有
    var op_navigationControllerForSplitViewController: UINavigationController? {
        switch self.op_larkDisplayMode {
        case .doubleColumn, .singleColumn:
            return self.topMost as? UINavigationController
        case .normal:
            return nil
        }
    }
}
