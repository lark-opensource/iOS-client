//
//  UIViewController+GadgetUtils.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/26.
//

import UIKit
import TTMicroApp
import LarkSplitViewController
import LarkSceneManager

extension UIViewController {
    /// 将VC从它所属的导航控制器中删除
    /// - Parameters:
    ///   - animated: 是否动画
    ///   - failure: 删除失败的回调
    ///   - complete: 删除完成的回调
    /// - Note: 注意此方法与`removeViewControllerFromNavigationController`的区别，此方法会进行一些复杂的逻辑判断，判断是否在栈顶或栈内，进行一些场景的特殊适配
    func op_removeFromViewHierarchy(isCloseOtherSceneWhenOnlyHasIt: Bool, recoverAction: GadgetDefaultDetailController.RecoverAction? = nil, animated: Bool, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        // iPad 临时区
        if OPTemporaryContainerService.isGadgetTemporaryEnabled() && self.isTemporaryChild {
            self.view.removeFromSuperview()
            self.removeFromParent()
            complete()
            return
        }
        
        if let currentNavigationController = self.navigationController {
            /// 如果当前VC在导航控制器的顶部
            if currentNavigationController.topViewController === self {
                /// 如果当前导航控制器只有它一个VC
                if currentNavigationController.viewControllers.count == 1 {
                    /// 如果当前VC在一个SplitVC中，那么将SplitVC重置它的detailVC
                    /// ⚠️因为有一个路由前提，就是当有SplitVC时，路由的VC必须是应该被放置在SplitVC的detailVC中的⚠️
                    if let splitVC = self.larkSplitViewController {
                        /// SplitVC的detailVC必须是一个UINavigationController
                        if let topMostNC = splitVC.secondaryViewController as? UINavigationController {
                            /// 从detailVC中找到当前的ViewController，为了确保这个ViewController符合路由的前提假设
                            /// 避免线上出现crash，严重的事故
                            let isContains = topMostNC.viewControllers.contains {
                                $0 === self
                            }
                            /// 如果包含就将SplitVC的detailVC恢复成默认VC，这样就成功的将ViewController从视图层级中移除了
                            if isContains {
                                /// 这个方法现在是同步完成的，所以可以放心使用
                                splitVC.cleanSecondaryViewController()
                                /// ⚠️上述方法仅仅只是将它的detailViewcontroller移除掉
                                /// 但是不是说将VC从它外面包装的NC也一并移除掉
                                /// 所以我们在这里还要小心的将其也一并移除掉
                                /// 这样才能完全保证这个VC一定不被任何其他VC所挂载⚠️
                                self.view.removeFromSuperview()
                                self.removeFromParent()
                                complete()
                                return
                            } else {
                                /// ⚠️如果不包含，那么就打破了假设，路由失败⚠️
                                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                                          message: "current VC not in SplitVC's detailViewController")
                                assertionFailure(error.description)
                                failure(error)
                                return
                            }
                        } else {
                            /// ⚠️如果SpliVC的detailVC不是一个UINavigationController，那么打破了路由假设，路由失败⚠️
                            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                                      message: "current VC in SplitVC's detailViewController isn't navigationController")
                            assertionFailure(error.description)
                            failure(error)
                            return
                        }
                    } else {
                        /// 判断当前ViewController是否在window中
                        if let window = self.view.window {
                            /// 在window中就需要判断是否有scene
                            /// ⚠️这种情况表示我们需要路由一个VC，他不在SplitVC中，而且它所在的导航栈只有他一个⚠️
                            /// ⚠️这种场景在Lark中只会出现在iPad的多Scene中，辅助Scnene中往往会出现这种情况⚠️
                            /// ⚠️因此我们可以直接关闭Scene⚠️
                            if #available(iOS 13.0, *) {
                                /// 找到当前所在的Scene
                                if let sceneInfo = window.windowScene?.sceneInfo {
                                    /// 如果不在主Scene
                                    if !sceneInfo.isMainScene() {
                                        /// 如果在window中，但是它是导航栈中唯一的，
                                        /// 因此需要检查这个导航栈是不是被模态弹出的
                                        /// 如果是则需要尝试去dismiss它
                                        /// ⚠️这里我们有可能会dismiss一个第三方创建的UINavigationController⚠️
                                        if let _ = currentNavigationController.presentingViewController {
                                            currentNavigationController.op_dismissIfNeed(recoverAction: recoverAction, animated: animated, complete: complete, failure: failure)
                                            return
                                        } else {
                                            /// 如果VC要求关闭Scene，那么直接关闭
                                            if isCloseOtherSceneWhenOnlyHasIt {
                                                /// ⚠️缺少成功的回调⚠️
                                                /// ⚠️ 按照Apple的接口，就没有提供给我们成功的回调⚠️
                                                SceneManager.shared.deactive(scene: sceneInfo){error in
                                                    /// 如果失败了我们只能打个日志
                                                    GadgetNavigator.logger.error("Scene close failure")
                                                }
                                                /// 强制完成
                                                /// ⚠️这里需要及时将导航栈清理掉，因为如果这个Scene在后台或者关闭Scene失败了
                                                /// 会导致这个VC的parent仍然有值，如果继续执行代码会导致命中后面的assert
                                                /// 在线上则会直接路由失败，在这里及时清理，可以让线上路由成功⚠️
                                                currentNavigationController.op_cleanContent(recoverAction: recoverAction, complete: complete, failure: failure)
                                                return
                                            } else {
                                                /// 否则替换为新的占位符
                                                currentNavigationController.op_cleanContent(recoverAction: recoverAction, complete: complete, failure: failure)
                                                return
                                            }
                                        }
                                    } else {
                                        /// 如果在主Scene
                                        /// 如果在window中，但是它是导航栈中唯一的，
                                        /// 因此需要检查这个导航栈是不是模态弹出的
                                        /// 如果是则需要尝试去dismiss它
                                        /// ⚠️这里我们有可能会dismiss一个第三方创建的UINavigationController⚠️
                                        if let _ = currentNavigationController.presentingViewController {
                                            currentNavigationController.op_dismissIfNeed(recoverAction: recoverAction, animated: animated, complete: complete, failure: failure)
                                            return
                                        } else {
                                            /// 否则肯定是业务异常或者逻辑缺失，导致落入此分支，必须触发assert
                                            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                                                      message: "current VC in NavigationController, but only has it and in main scene")
                                            assertionFailure(error.description)
                                            failure(error)
                                            return
                                        }
                                    }
                                } else {
                                    /// 如果当前不在scene中，那么我们也可以认为它不在视图层级中
                                    /// 我们可以直接简单的将它从currentNavigationController中移除，替换成占位符
                                    currentNavigationController.op_cleanContent(recoverAction: recoverAction, complete: complete, failure: failure)
                                    return
                                }
                            } else {
                                /// 如果在window中，但是它是导航栈中唯一的，
                                /// 因此需要检查这个导航栈是不是模态弹出的
                                /// 如果是则需要尝试去dismiss它
                                /// ⚠️这里我们有可能会dismiss一个第三方创建的UINavigationController⚠️
                                if let _ = currentNavigationController.presentingViewController {
                                    currentNavigationController.op_dismissIfNeed(recoverAction: recoverAction, animated: animated, complete: complete, failure: failure)
                                    return
                                } else {
                                    /// 否则肯定是业务异常或者逻辑缺失，导致落入此分支，必须触发assert
                                    let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                                              message: "current VC in NavigationController, but only has it and there is no scene")
                                    assertionFailure(error.description)
                                    failure(error)
                                    return
                                }
                            }
                        } else {
                            /// 因为如果不在window中，我们可以直接简单的将它从currentNavigationController中移除，替换成占位符
                            currentNavigationController.op_cleanContent(recoverAction: recoverAction,  complete: complete, failure: failure)
                            complete()
                            return
                        }
                    }
                } else {
                    /// 如果当前导航控制器不只有它一个VC，但是现在自己又在栈顶
                    /// 于是将自己直接从导航栈中Pop移除
                    op_removeFromNavigationController(animated: animated, complete: complete, failure: failure)
                    return
                }
            } else {
                /// 如果当前导航控制器不只有它一个VC，将自己直接从导航栈中移除，不需要使用动画
                op_removeFromNavigationController(animated: false, complete: complete, failure: failure)
                return
            }
        } else {
            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                      message: "viewController isn't in navigationController when removeViewHierarchy")
            assertionFailure(error.description)
            failure(error)
        }
    }

    /// 从当前VC的导航栈中直接删除当前VC
    /// - Parameters:
    ///   - animated: 是否进行动画
    ///   - complete: 删除完成的回调
    ///   - failure: 删除失败的回调
    /// - Note: 注意此方法与`removeViewControllerFromViewHierarchy`的区别，此方法直接将viewController从导航控制器栈中删除
    func op_removeFromNavigationController(animated: Bool, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        if let currentNavigationController = self.navigationController {
            var allViewControllers = currentNavigationController.viewControllers
            allViewControllers.removeAll{
                $0 === self
            }
            GadgetNavigator.logger.info("enter remove with animated: \(animated) from: \(currentNavigationController)")
            currentNavigationController.op_setViewControllers(allViewControllers, animated: animated, complete: {
                [weak self] in
                /// ⚠️如果当前操作的currentNavigationController在后台，那么由于系统机制
                /// 即使将它从NC数组中移走，他的parent也不会被马上置为nil⚠️
                /// 在这里需要手动的设置
                GadgetNavigator.logger.info("leave remove with animated: \(animated)")
                self?.view.removeFromSuperview()
                self?.removeFromParent()
                complete()
            }, failure: failure)
        } else {
            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                      message: "viewController isn't in navigationController when remvoe")
            assertionFailure(error.description)
            failure(error)
        }
    }

    /// 用当前VC showDetail的另一个VC
    /// - Parameters:
    ///   - viewController: 要显示的VC
    ///   - animated: 是否动画
    ///   - complete: showDetail完成的回调
    ///   - failure: showDetail失败的回调
    func op_showDetailViewController(_ viewController: UIViewController, animated: Bool, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        GadgetNavigator.logger.info("enter showDetail with animated: \(animated) from: \(self)")
        self.showDetailViewController(viewController, sender: nil)
        if animated {
            guard let coordinator = self.transitionCoordinator else {
                GadgetNavigator.logger.info("leave showDetail without transitionCoordinator")
                complete()
                return
            }
            coordinator.animate(alongsideTransition: nil) { _ in
                GadgetNavigator.logger.info("leave showDetail with animated")
                complete()
            }
        } else {
            GadgetNavigator.logger.info("leave showDetailv without animated")
            complete()
        }
    }

    /// present一个VC
    /// - Parameters:
    ///   - viewController: 要弹出的VC
    ///   - modalStyle: 模态弹出的样式
    ///   - animated: 是否动画
    ///   - complete: presented完成的回调
    ///   - failure: presented失败的回调
    func op_present(_ viewController: UIViewController, modalStyle: UIModalPresentationStyle, animated: Bool, complete: @escaping () -> (), failure: @escaping (Error) -> ()) {
        GadgetNavigator.logger.info("enter present with animated: \(animated) from: \(self)")
        viewController.modalPresentationStyle = modalStyle
        self.present(viewController, animated: animated){
            GadgetNavigator.logger.info("leave present")
            complete()
        }
    }

}
