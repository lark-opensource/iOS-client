//
//  GadgetNavigatorProcessor.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/19.
//

import UIKit
import LKCommonsLogging
import EENavigator
import LarkSceneManager
import LarkUIKit
import LarkSplitViewController
import TTMicroApp
import OPFoundation
import LarkFeatureGating
import LarkTab
import LarkContainer
import LarkQuickLaunchInterface

/// 用于实现小程序路由的处理器
final class GadgetNavigatorProcessor {

    /// 日志
    private static let logger = Logger.oplog(GadgetNavigatorProcessor.self, category: "OPGadget")
    
    @InjectedUnsafeLazy var temporaryTabService: TemporaryTabService

    /// Pop操作
    /// - Parameters:
    ///   - viewController: 需要Pop的viewController
    ///   - animated: 是否开启动画
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    /// - Note: 必须在主线程调用，否则会引发异常
    func pop(viewController: UIViewController & GadgetNavigationProtocol, animated: Bool, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        /// 找到当前viewController所属的navigationController，如果不在，则打破了路由假设，直接路由失败
        guard viewController.navigationController != nil else {
            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                      message: "viewController isn't in navigationController when pop")
            failure(error)
            return
        }

        /// 将viewController从当前视图层级中移除
        viewController.op_removeFromViewHierarchy(isCloseOtherSceneWhenOnlyHasIt: viewController.isCloseOtherSceneWhenOnlyHasIt, animated: animated, complete: success, failure: failure)
    }

    /// Push操作
    /// - Parameters:
    ///   - viewController: 需要Push的viewController
    ///   - window: 需要在哪个Window中显示
    ///   - animated: 是否动画
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    /// - Note: 必须在主线程调用，否则会引发异常， success如果参数为true，表示路由过程结束，无需进行下一步操作
    func push(viewController: UIViewController & GadgetNavigationProtocol, from window: UIWindow, animated: Bool, success: @escaping () -> (), failure: @escaping (Error) -> ()) {

        /// 适合显示当前VC的NavigationController
        let navigationControllerOptional: UINavigationController?

        do {
            /// 获取适合显示当前VC的NavigationContext
            let navigationContext = try fetchNavigationContext(for: window, targetViewController: viewController)
            switch navigationContext {
            /// ⚠️在SplitVC没有内容和presentedViewController不是一个NavigationController时，我们需要自己生成一个导航栏
            /// 将这个VC放入导航栏才能进行下一步操作
            /// 在这里我们直接设置为nil，这将强制触发从视图层级中删除此VC的逻辑，符合我们预期⚠️
            case .splitViewControllerNoneDetail:
                navigationControllerOptional = nil
            case .presentedNoneNavigation(_, let navigationStyle):
                /// 检查这个VC是否允许被presented弹出
                switch navigationStyle {
                /// 如果在这种情况下目标VC指定需要innerOpen打开，则不支持，直接路由失败
                case .innerOpen:
                    let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                              message: "view controller can't open in nonNavigationController")
                    failure(error)
                    return
                case .present:
                    navigationControllerOptional = nil
                case .none:
                    let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                              message: "view controller don't allow to be presented")
                    failure(error)
                    return
                }
            case .presentedNavigationDetail(let presentNavigationController, let navigationStyle):
                /// 检查这个VC是否允许被presented弹出
                switch navigationStyle {
                case .innerOpen:
                    navigationControllerOptional = presentNavigationController
                case .present:
                    navigationControllerOptional = nil
                case .none:
                    let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                              message: "view controller don't allow to be presented")
                    failure(error)
                    return
                }
            case .presentedNavigationNoneDetail(let presentNavigationController, let navigationStyle):
                /// 检查这个VC是否允许被presented弹出
                switch navigationStyle {
                case .innerOpen:
                    navigationControllerOptional = presentNavigationController
                case .present:
                    navigationControllerOptional = nil
                case .none:
                    let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                              message: "view controller don't allow to be presented")
                    failure(error)
                    return
                }
            case .splitViewControllerDetailNavigation(let navigationController):
                navigationControllerOptional = navigationController
            case .splitViewControllerDetailNoneNavigation(let navigationController):
                navigationControllerOptional = navigationController
            case .navigationViewController(let navigationController):
                navigationControllerOptional = navigationController
            case .windowRootViewController(let navigationController):
                navigationControllerOptional = navigationController
            case .temporaryTabContainer:
                navigationControllerOptional = nil
            }
        } catch {
            /// 获取失败
            failure(error)
            return
        }


        Self.logger.error("find navigationController to response gadget navigation： \(String(describing: navigationControllerOptional))")
        
        if OPTemporaryContainerService.isGadgetTemporaryEnabled() {
            // iPad C视图打开下,使用iPhone的打开逻辑;
            // 原本预计在临时区打开的应用尽管保持了在iPhone的打开逻辑，但是需要向临时区添加标签，用于切换回R视图的恢复
            if Display.pad,
               window.traitCollection.horizontalSizeClass == .compact,
               viewController.openInTemporaryTab,
               let container = viewController as? TabContainable {
                Self.logger.info("iPad compact record in temporary")
                temporaryTabService.updateTab(container)
            }
        }
        /// viewController 任何时刻只能存在一个地方，我们需要进行视图层级的调整
        self.adjustViewHierarchy(for: viewController, targetNavigationController: navigationControllerOptional, failure: failure) { [weak self] isNavigationComplete in
            guard let `self` = self else {
                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                          message: "navigation task dealloc advance, maybe it timeout")
                failure(error)
                return
            }
            /// 如果直接路由成功
            if isNavigationComplete {
                success()
                return
            } else {
                /// 我们在这里获取新的信息，由于之前肯定将ViewController从视图层级中删除了，所以在这里加回来肯定不会崩溃
                /// 如果之前没有从视图层级中删除，那么表示VC之前已经在即将显示的NavigationController栈顶了，于是路由直接成功了
                /// 不会走入这个分支
                /// 我们可以在这个分支里加入assert，以确保有视图层级时已经不会落入这个分支
                if viewController.parent != nil {
                    let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                              message: "view controller in view hierarchy")
                    assertionFailure(error.description)
                    failure(error)
                    return
                } else {
                    self.show(viewController: viewController, window: window, animated: animated, success: success, failure: failure)
                }
            }
        }

    }
    /// 获取路由上下文
    /// - Parameter window: 当前的Window
    /// - Throws: 找不到合适的用来路由的NC
    /// - Returns: 当前路由环境的上下文
    private func fetchNavigationContext(for window: UIWindow, targetViewController: UIViewController & GadgetNavigationProtocol) throws -> GadgetNavigationContext {
        
        if OPTemporaryContainerService.isGadgetTemporaryEnabled() {
            if Display.pad && targetViewController.openInTemporaryTab && window.traitCollection.horizontalSizeClass == .regular  {
                return .temporaryTabContainer
            }
        }
        
        /// 如果当前window有present出来VC，那么我们需要取到最上层的VC
        /// 因为一旦有presentViewController，那么我们就需要走另外的一套处理逻辑
        /// 专门用于有presentedViewController时的处理方式
        if let presentViewController = window.op_topMostPresentViewController {
            let navigationStyle = targetViewController.navigationStyle(in: presentViewController)
            /// 如果弹出来的presentedViewController是一个NC，那么我们将直接在这个NC中push
            if let navigationController = presentViewController as? UINavigationController {
                if navigationController.op_hasReallyContentViewController {
                    /// 如果当前NC有内容
                    return .presentedNavigationDetail(presentNavigationController: navigationController, navigationStyle: navigationStyle)
                } else {
                    /// 如果当前NC无内容
                    return .presentedNavigationNoneDetail(presentNavigationController: navigationController, navigationStyle: navigationStyle)
                }
            } else {
                /// 否则我们需要生成一个NC，然后将VC放入之后在present出来
                /// 这个时候我们的响应路由的对象则是presentViewController，用它来presented
                return .presentedNoneNavigation(presentViewController: presentViewController, navigationStyle: navigationStyle)
            }
        } else {
            /// 是否触发SplitVC查询NavigationController的降级逻辑
            var isSplitViewControllerDowngrade = false
            /// 如果当前window有SplitVC，而且SplitVC还没有detailVC
            /// 那么我们需要以showDetail的方式进行显示，因此我们需要生成一个新的NavigationController
            /// 用这个NavigationController包装viewController，因为showDetail在SplitVC中的表现是替换它的detailVC
            /// 如果不用NC包装VC，那么showDetail的VC就不是NC，会破坏Lark的视图层级结构假设以及路由假设，造成意想不到的错误
            if let splitVC = window.op_newSplitViewControllerStrictly {
                /// 如果detailVC是空的占位符
                if splitVC.secondaryViewController == nil || splitVC.isCollapsed {
                    /// 这个时候我们的响应路由对象是SplitVC
                    return .splitViewControllerNoneDetail(splitViewController: splitVC)
                } else {
                    /// 如果splitVC有适合的UINavigationController
                    if let navigationController = splitVC.op_navigationControllerForSplitViewController {
                        return .splitViewControllerDetailNavigation(navigationController: navigationController)
                    } else {
                        /// 如果SplitVC的detailVC不是一个UINavigationController，则我们需要走降级逻辑，但是此种情况是严重的异常情况
                        /// 我们降级为使用window的rootVC逻辑
                        /// 开发过程中，我们需要及时assert
                        isSplitViewControllerDowngrade = true
                        assertionFailure("SplitVC detailVC isn't UINavigationController")
                    }
                }
            }
            
            /// 如果不符合以上场景，那么我们必须找到合适的NavigationController
            /// 如果找不到NavigationController，那么我们就要放弃路由
            let useIpadTabPush = LarkFeatureGating.shared.getFeatureBoolValue(for: "mobile.ipad.ecosystem.navigation.ipad_tab_push")
            if let navigationController = window.op_navigationControllerForRootViewController {
                if isSplitViewControllerDowngrade {
                    return .splitViewControllerDetailNoneNavigation(navigationController: navigationController)
                } else if useIpadTabPush, let topMostVC = OPNavigatorHelper.topMostVC(window: window), let wrapNav = topMostVC.children.first as? UINavigationController {
                    return .navigationViewController(navigationController: wrapNav)
                } else {
                    return .windowRootViewController(navigationController: navigationController)
                }
            } else {
                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                          message: "not find navigationController to response gadget navigation")
                throw error
            }
        }
    }

    /// 显示ViewController
    /// - Parameters:
    ///   - viewController: 需要显示的VC
    ///   - window: 需要显示在哪个Window
    ///   - animated: 是否动画
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    private func show(viewController: UIViewController & GadgetNavigationProtocol, window: UIWindow, animated: Bool, success: @escaping () -> (), failure: @escaping (Error) -> ()) {

        /// 路由的上下文
        let navigationContext: GadgetNavigationContext

        do {
            /// 获取适合显示当前VC的NavigationController
            navigationContext = try fetchNavigationContext(for: window, targetViewController: viewController)
        } catch {
            /// 获取失败
            failure(error)
            return
        }

        switch navigationContext {
        /// 当前在模态弹窗中，且弹窗是一个UINavigationController,有内容
        case .presentedNavigationDetail(let presentNavigationController, let navigationStyle):
            switch navigationStyle {
            case .innerOpen:
                /// 直接push
                push(viewController: viewController, in: presentNavigationController, animated: animated, success: success, failure: failure)
            case .present:
                /// 需要将viewController包装入navigationController
                let navigationController = LkNavigationController(rootViewController: viewController)
                let modalStyle = viewController.modalStyleWhenPresented(from: presentNavigationController)
                present(viewController: navigationController, from: presentNavigationController, modalStyle: modalStyle, animated: animated, success: success, failure: failure)
            case .none:
                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                          message: "view controller don't allow to be presented")
                failure(error)
                return
            }
        /// 当前在模态弹窗中，且弹窗是一个UINavigationController，只有占位符，没有内容
        case .presentedNavigationNoneDetail(let presentNavigationController, let navigationStyle):
            switch navigationStyle {
            case .innerOpen:
                /// 如果navigationController里面是空的，那么我们就需要判断它需要showDetail
                showDetail(viewController: viewController, in: presentNavigationController, success: success, failure: failure)
            case .present:
                /// 需要将viewController包装入navigationController
                let navigationController = LkNavigationController(rootViewController: viewController)
                let modalStyle = viewController.modalStyleWhenPresented(from: presentNavigationController)
                present(viewController: navigationController, from: presentNavigationController, modalStyle: modalStyle, animated: animated, success: success, failure: failure)
            case .none:
                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                          message: "view controller don't allow to be presented")
                failure(error)
                return
            }
        /// 当前在模态弹窗中，且弹窗不是一个UINavigationController
        case .presentedNoneNavigation(let presentViewController,  let navigationStyle):
            switch navigationStyle {
            /// 如果在这种情况下目标VC指定需要innerOpen打开，则不支持，直接路由失败
            case .innerOpen:
                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                          message: "view controller can't open in nonNavigationController")
                failure(error)
                return
            case .present:
                /// 需要将viewController包装入navigationController
                let navigationController = LkNavigationController(rootViewController: viewController)
                let modalStyle = viewController.modalStyleWhenPresented(from: presentViewController)
                present(viewController: navigationController, from: presentViewController, modalStyle: modalStyle, animated: animated, success: success, failure: failure)
            case .none:
                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                          message: "view controller don't allow to be presented")
                failure(error)
                return
            }
        /// 当前在SplitVC中，且SplitVC的detail有内容,且detailVC是一个UINavigationController
        case .splitViewControllerDetailNavigation(let navigationController):
            /// 我们直接push
            push(viewController: viewController, in: navigationController, animated: animated, success: success, failure: failure)
        /// 当前在SplitVC中，且SplitVC的detail有内容,且detailVC不是一个UINavigationController
        case .splitViewControllerDetailNoneNavigation(let navigationController):
            /// 我们直接push
            push(viewController: viewController, in: navigationController, animated: animated, success: success, failure: failure)
        /// 当前在SplitVC中，且SplitVC的detail没有内容
        case .splitViewControllerNoneDetail(let splitVC):
            /// 需要获取合适的SplitVC,，然后showDetail
            /// 需要将viewController包装入navigationController
            let navigationController = LkNavigationController(rootViewController: viewController)
            showDetail(viewController: navigationController, in: splitVC, success: success, failure: failure)
        case .navigationViewController(let navigationController):
            push(viewController: viewController, in: navigationController, animated: animated, success: success, failure: failure)
        /// 当前在UIWindow的RootVC中
        case .windowRootViewController(let navigationController):
            /// 我们直接push
            push(viewController: viewController, in: navigationController, animated: animated, success: success, failure: failure)
        case .temporaryTabContainer:
            if Display.pad,let container = viewController as? TabContainable {
                temporaryTabService.showTab(container)
            }
        }
    }

    /// present的方式弹出VC
    /// - Parameters:
    ///   - viewController: 需要显示的VC
    ///   - presentViewController: 弹出viewController的VC
    ///   - modalStyle: 模态弹出的样式
    ///   - animated: 是否动画
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    private func present(viewController: UIViewController, from presentViewController: UIViewController, modalStyle: UIModalPresentationStyle, animated: Bool, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        presentViewController.op_present(viewController, modalStyle: modalStyle, animated: animated, complete: success, failure: failure)
        /// ⚠️如果想替换为EENavigation的路由，那么我们可以在这里修复为其的present方法⚠️
    }

    /// push的方式显示VC
    /// - Parameters:
    ///   - viewController: 需要显示的VC
    ///   - navigationController: VC将要放入的NavigationController
    ///   - animated: 是否动画
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    private func push(viewController: UIViewController, in navigationController: UINavigationController, animated: Bool, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        navigationController.op_pushViewController(viewController, animated: animated, complete: success, failure: failure)
        /// ⚠️如果想替换为EENavigation的路由，那么我们可以在这里修复为其的push方法⚠️
    }

    /// showDetail的方式弹出VC
    /// - Parameters:
    ///   - viewController: 需要显示的VC
    ///   - splitViewController: VC将要放入的SplitVC
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    /// - Note: 需要注意，此方法仅在有SplitVC时，而且还需要showDetail的时候使用
    private func showDetail(viewController: UIViewController, in splitViewController: UIViewController, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        splitViewController.op_showDetailViewController(viewController, animated: false, complete: success, failure: failure)
        /// ⚠️如果想替换为EENavigation的路由，那么我们可以在这里修复为其的showDetail方法⚠️
    }

    /// showDetail的方式弹出VC
    /// - Parameters:
    ///   - viewController: 需要显示的VC
    ///   - navigationController: VC将要放入的navigationController
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    /// - Note: ⚠️需要注意,VC将作为navigationController的rootVC在navigationController中被显示⚠️
    private func showDetail(viewController: UIViewController, in navigationController: UINavigationController, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let originViewControllers = navigationController.viewControllers
        navigationController.op_setViewControllers([viewController], animated: false, complete: {
            /// ⚠️如果当前UINavigationController在后台，通过数组方式移除之前的VC⚠️
            /// 会使之前的VC的parent不会马上置为nil，需要在这里加入代码手动保证
            for originViewController in originViewControllers {
                /// ⚠️如果之前就有自己，那么不要进行removeFromParent操作⚠️
                if originViewController === viewController {
                    continue
                }
                originViewController.view.removeFromSuperview()
                originViewController.removeFromParent()
            }
            success()
        }, failure: failure)
        /// ⚠️如果想替换为EENavigation的路由，现在没法实现，EE那边暂时还未提供对UINavigationController空白页面替换的能力⚠️
    }

    /// VC在进行push之前，需要进行一些状态检查以及视图层级的调整
    /// - Parameters:
    ///   - viewController: 当前VC
    ///   - targetNavigationController: 当前VC将要被放置的NavigationController，也可以传入nil，这表示无条件的从视图层级中删除它
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    ///   - complete: 调整完成的回调
    /// - Note: ⚠️这里有几点需要注意:⚠️
    ///         ⚠️1.路由成功的回调`success`表示整个路由成功，调整完成的回调`complete`不代表路由成功，还需要后续的一些步骤⚠️
    ///         ⚠️小程序路由有几个前提假设：⚠️
    ///         ⚠️1. 给定的VC一定在某个导航控制器中；⚠️
    ///         ⚠️2. 当有SplitVC时，路由的VC必须是应该被放置在SplitVC的detailVC中的；⚠️
    ///         ⚠️3. 我们需要路由一个VC，他不在SplitVC中，而且它所在的导航栈只有他一个，且这个VC只能存在一个⚠️
    ///         ⚠️那么这种场景在Lark中只会出现在iPad的多Scene中，辅助Scnene中会出现这种情况；⚠️
    private func adjustViewHierarchy(for viewController: UIViewController & GadgetNavigationProtocol, targetNavigationController: UINavigationController?, failure: @escaping (Error) -> (), complete: @escaping (Bool) -> ()) {
        /// 如果当前VC不在视图层级中，那么就不需要调整，直接完成调整
        /// ⚠️注意有parent不能表示它在视图层级中，因为它有可能不在window中⚠️
        if viewController.parent == nil {
            complete(false)
        } else {
            /// 如果当前VC在的导航控制器中，否则直接路由失败
            /// ⚠️因为与我们之前的假设不一致，假设就是按照我们的路由体系，给定的VC一定在某个导航控制器中⚠️
            if let currentNavigationController = viewController.navigationController {
                /// 如果当前VC的导航控制器与将要放置的导航控制器一致
                if currentNavigationController === targetNavigationController {
                    /// 如果当前VC在导航控制器的顶部，那么直接路由完成，不需要任何操作
                    if currentNavigationController.topViewController === viewController {
                        complete(true)
                        return
                    } else {
                        /// 否则需要将自己从导航控制器中删除，默认关闭动画
                        viewController.op_removeFromNavigationController(animated: false, complete: {
                            complete(false)
                        }, failure: failure)
                        return
                    }
                } else {
                    /// 如果当前VC的导航控制器与将要放置的导航控制器不一致，默认需要开启动画
                    viewController.op_removeFromViewHierarchy(isCloseOtherSceneWhenOnlyHasIt: viewController.isCloseOtherSceneWhenOnlyHasIt, recoverAction: viewController.recoverBlankViewControllerActionOnPresented(), animated: false, complete: {
                        /// 由于调整了视图层级，需要等待一个RunLoop让移除视图的生命周期函数执行
                        /// 才能继续将其加上，否则会导致视图的生命周期混乱，引发一些奇怪的bug
                        /// 至于为什么上面的那个op_removeFromNavigationController不需要延迟complete执行
                        /// 是因为在那种情况下，视图已经在导航栈中了
                        /// 生命周期肯定是已经执行完成了的，所以不需要执行延迟
                        /// op_removeFromViewHierarchy方法中也存在从导航栈中移除的，为什么不进行区分
                        /// 因为方法内部如果要添加需要在不同地方加入这样子的代码，导致代码阅读困难
                        /// 注意在这个方法op_removeFromViewHierarchy中一定是非动画的
                        /// 如果之后将这个方法变成允许动画之后，可以经过测试，移除这个延迟逻辑
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
                            complete(false)
                        })
                    }, failure: failure)
                }
            } else {
                /// 因为自己不在一个导航控制器中，不符合路由的假设前提，直接路由失败，必须触发assert
                let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                          message: "current VC not in NavigationController")
                assertionFailure(error.description)
                failure(error)
                return
            }
        }
    }
}
