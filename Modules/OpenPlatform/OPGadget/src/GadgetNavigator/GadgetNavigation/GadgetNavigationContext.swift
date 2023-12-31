//
//  GadgetNavigationContext.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/26.
//

import Foundation
import LarkSplitViewController

/// 路由支持的上下文，其中包括路由发生的场景以及该场景下适合响应路由的对象
enum GadgetNavigationContext {
    /// 当前在模态弹窗中，且弹窗是一个UINavigationController,有内容
    /// `presentNavigationController`表示建议响应路由的对象
    /// `navigationStyle`表示应该以何种方式弹出新的目标VC
    case presentedNavigationDetail(presentNavigationController: UINavigationController, navigationStyle: GadgetNavigationStyle)
    /// 当前在模态弹窗中，且弹窗是一个UINavigationController，只有占位符，没有内容
    /// `presentNavigationController`表示建议响应路由的对象
    /// `navigationStyle`表示应该以何种方式弹出新的目标VC
    case presentedNavigationNoneDetail(presentNavigationController: UINavigationController, navigationStyle: GadgetNavigationStyle)
    /// 当前在模态弹窗中，且弹窗不是一个UINavigationController
    /// `presentViewController`表示建议响应路由的对象
    /// `navigationStyle`表示应该以何种方式弹出新的目标VC
    case presentedNoneNavigation(presentViewController: UIViewController, navigationStyle: GadgetNavigationStyle)
    /// 当前在SplitVC中，且SplitVC的detail有内容,且detailVC是一个UINavigationController
    /// `navigationController`表示建议响应路由的对象
    case splitViewControllerDetailNavigation(navigationController: UINavigationController)
    /// 当前在SplitVC中，且SplitVC的detail有内容,且detailVC不是一个UINavigationController
    /// `navigationController`表示建议响应路由的对象
    case splitViewControllerDetailNoneNavigation(navigationController: UINavigationController)
    /// 当前在SplitVC中，且SplitVC的detail没有内容
    /// `splitViewController`表示建议响应路由的对象
    case splitViewControllerNoneDetail(splitViewController: UIViewController)
    /// 当前在UINavigationController中
    /// `navigationController`表示建议响应路由的对象
    case navigationViewController(navigationController: UINavigationController)
    /// 当前在UIWindow的RootVC中
    /// `navigationController`表示建议响应路由的对象
    case windowRootViewController(navigationController: UINavigationController)
    /// iPad临时区打开
    case temporaryTabContainer
}
