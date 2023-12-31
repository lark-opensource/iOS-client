//
//  UINavigationController+GadgetUtils.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/26.
//

import Foundation
import LarkSplitViewController
import LarkUIKit
import TTMicroApp
import LarkFeatureGating

extension UINavigationController {
    /// 清除自己的内容VC并替换为默认的占位VC
    func op_cleanContent(recoverAction: GadgetDefaultDetailController.RecoverAction? = nil, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let originViewControllers = self.viewControllers

        let defaultViewController = op_defaultDetailController(recoverAction: recoverAction)
        self.op_setViewControllers([defaultViewController], animated: false, complete: {
            /// ⚠️如果当前UINavigationController在后台，通过数组方式移除之前的VC⚠️
            /// 会使之前的VC的parent不会马上置为nil，需要在这里加入代码手动保证
            for originViewController in originViewControllers {
                originViewController.view.removeFromSuperview()
                originViewController.removeFromParent()
            }
            complete()
        }, failure: failure)

    }

    /// 从视图中dismiss自己
    /// - Parameters:
    ///   - animated: 是否开启动画
    ///   - complete: 操作完成的回调
    ///   - failure: 操作失败的回调
    /// - Note: 必须在主线程执行,如果当前它不是模态弹出的或者它还弹出了其他模态弹窗，则只会显示占位符不会dimiss
    func op_dismissIfNeed(recoverAction: GadgetDefaultDetailController.RecoverAction? = nil, animated: Bool, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        /// 如果自己没有模态弹出，那么仅仅那么将自己设置为空白
        if self.presentingViewController == nil {
            op_cleanContent(recoverAction: recoverAction, complete: complete, failure: failure)
            return
        /// 如果自己还弹出了新的页面，那么将自己设置为空白
        } else if self.presentedViewController != nil {
            op_cleanContent(recoverAction: recoverAction, complete: complete, failure: failure)
            return
        } else {
            /// 否则将自己dismiss掉
            self.dismiss(animated: animated, completion: {
                [weak self] in
                /// dismiss之后需要将自己的所有VC卸载掉
                self?.op_cleanContent(recoverAction: recoverAction, complete: complete, failure: failure)

            })
            return
        }
    }

    /// 判断自己是否有有意义的VC
    /// 当且仅当只有一个VC且这个VC还是个占位符才返回false，否则返回true
    /// - Note: 必须在主线程调用
    var op_hasReallyContentViewController: Bool {
        if viewControllers.count == 0 {
            return false
        } else if viewControllers.count == 1, viewControllers[0] is DefaultDetailVC {
            return false
        } else {
            return true
        }
    }

    /// 获取空白页面的占位符
    private func op_defaultDetailController(recoverAction: GadgetDefaultDetailController.RecoverAction? = nil) -> UIViewController {
        /// 如果当前NC不是模态弹出的，那么就使用LarkUIKit的默认占位符
        if self.presentingViewController == nil {
            return UIViewController.DefaultDetailController()
        } else {
            /// 如果当前NC是模态弹出的，那么就使用我们定制的空白占位符
            let blankViewController = GadgetDefaultDetailController()
            /// 设置空白页面的recoverAction
            blankViewController.recoverAction = recoverAction
            return blankViewController
        }
    }

}


extension UINavigationController {
    /// push一个VC
    /// - Parameters:
    ///   - viewController: 需要push的VC
    ///   - animated: 是否动画
    ///   - complete: push完成的回调
    ///   - failure: push失败的回调
    func op_pushViewController(_ viewController: UIViewController, animated: Bool, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        GadgetNavigator.logger.info("enter push with animated: \(animated) from: \(self) viewController:\(viewController)")
        
        //push twice with the same viewcontroller is forbidden. https://bytedance.feishu.cn/docx/doxcnxAn9w1baBdPkx5QEcucStf
        if self.topViewController == viewController {
            GadgetNavigator.logger.error("[Gadget] nav push same viewController instance \(viewController)")
            failure(NSError(domain: "GadgetPushError", code: -1, userInfo: nil))
            return
        }
        
        self.pushViewController(viewController, animated: animated)
        if animated {
            guard let coordinator = self.transitionCoordinator else {
                GadgetNavigator.logger.info("leave push without transitionCoordinator")
                complete()
                return
            }
            coordinator.animate(alongsideTransition: nil) { _ in
                GadgetNavigator.logger.info("leave push with animated")
                complete()
            }
        } else {
            GadgetNavigator.logger.info("leave push without animated")
            complete()
        }
    }

    /// 设置新的VCs
    /// - Parameters:
    ///   - viewControllers: 新的VCs
    ///   - animated: 是否开启动画
    ///   - complete: setViewControllers完成的回调
    ///   - failure: setViewControllers失败的回调
    func op_setViewControllers(_ viewControllers: [UIViewController], animated: Bool, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        GadgetNavigator.logger.info("enter setViewController with animated: \(animated) from: \(self)")
        self.setViewControllers(viewControllers, animated: animated)
        
        /*
         UIKit UITabbarController的任意tabbar item的导航控制器pop至首页时，默认会将tabbar展示(Apple的tabbar默认实现)
         在控制器的appear阶段来控制tabbar的显示/隐藏的时机太晚，会造成闪动
         需要在更新控制器之后立即触发
         warning:不能写在self.setViewControllers(viewControllers, animated: animated)之前
         代码逻辑写在这存在高耦合问题，考虑到本身这就是本方法需要兼容的问题，且只能写在这里
         除非遇到系统变更造成的兼容性问题，否则轻易不要改
         */
        viewControllers.forEach { viewController in
            if let vc = viewController as? OPGadgetContainerController {
                if let appVc = vc.appController {
                    if let tabbarVc = appVc.contentVC as? BDPTabBarPageController  {
                        tabbarVc.temporaryHiddenAndRecover()
                    }
                }
            }
        }
        
        if animated {
            guard let coordinator = self.transitionCoordinator else {
                GadgetNavigator.logger.info("leave setViewController without transitionCoordinator")
                complete()
                return
            }
            coordinator.animate(alongsideTransition: nil) { _ in
                GadgetNavigator.logger.info("leave setViewController with animated")
                complete()
            }
        } else {
            GadgetNavigator.logger.info("leave setViewController without animated")
            complete()
        }
    }
}
