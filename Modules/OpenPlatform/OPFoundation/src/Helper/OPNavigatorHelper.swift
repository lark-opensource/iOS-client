//
//  OPNavigatorHelper.swift
//  OPFoundation
//
//  Created by Nicholas Tau on 2020/12/22.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import EENavigator
import LarkNavigation
import LarkSplitViewController

public enum TopMostQueryExtra {
    case SearchSubviews(Bool)
    case FixPopupOver(Bool)
    case OpenSchemaPadWebNavFixEnabled(Bool)
}

@objcMembers
open class OPNavigatorHelper: NSObject {
    
    public class func push(_ viewController: UIViewController, window: UIWindow?, animated: Bool = true) {
        guard let navigation = topmostNav(window: window) else {
            return
        }
        Navigator.shared.push(viewController, from: navigation, animated: animated) // Global
    }

    public class func presentWithLKWraper(_ viewController: UIViewController, window: UIWindow?, animated flag: Bool, completion: (() -> Void)? = nil) {
        if #available(iOS 13.0, *) {
            viewController.modalPresentationStyle = .fullScreen
        }
        topMostVC(window: window)?.present(LkNavigationController(rootViewController: viewController), animated: flag, completion: completion)
    }
    
    /// Returns the current application's top most navigation controller.
    ///
    /// - Parameter searchSubViews: 是否搜索子视图的vc层级，默认为false。如果为true，在小程序内会找到BDPAppController的navigation controller
    /// - Returns: top most navigation controller
    public class func topmostNav(searchSubViews: Bool = false, window: UIWindow?) -> UINavigationController? {
        return topMostNavigation(window: window, options: [.SearchSubviews(searchSubViews)])
    }
    
    /// Returns the current application's top most app controller.
    ///
    /// - Returns: top most app controller
    public class func topMostAppController(window: UIWindow?) -> UIViewController? {
        return topMostVC(searchSubViews: true, window: window)
    }
    
    public class func topMostNavigation(window: UIWindow?, options:[TopMostQueryExtra]) -> UINavigationController? {
        guard let vc = topMostVC(window: window, options: options) else {
            return nil
        }
        let nav = nextResponderOfNav(responder: vc)
        return nav
    }

    /// Returns the current application's top most view controller.
    ///
    /// - Parameter searchSubViews: 是否搜索子视图的vc层级，默认为false。如果为true，在小程序内会找到BDPAppController
    /// - Returns: top most view controller
    public class func topMostVC(searchSubViews: Bool = false, window: UIWindow?) -> UIViewController? {
        return topMostVC(window: window, options: [.SearchSubviews(searchSubViews)])
    }
    
    private class func topMostVC(window: UIWindow?, options: [TopMostQueryExtra]) -> UIViewController? {
        var rootViewController: UIViewController?
        if let rootViewController1 = window?.rootViewController {
            rootViewController = rootViewController1
        } else {
            if let window = UIApplication.shared.delegate?.window, let rootViewController1 = window?.rootViewController {
                rootViewController = rootViewController1
            } else {
                if let rootViewController2 = UIApplication.shared.keyWindow?.rootViewController {
                    rootViewController = rootViewController2
                } else {
                    let currentWindows = UIApplication.shared.windows
                    for window in currentWindows {
                        if let windowRootViewController = window.rootViewController {
                            rootViewController = windowRootViewController
                            break
                        }
                    }
                }
            }
        }
        
        return topMost(of: rootViewController, options: options)
    }
    
    // Returns the top nearest navigation controller from given responder's stack.
    private class func nextResponderOfNav(responder: UIResponder) -> UINavigationController? {
        if let responder1 = responder as? UINavigationController {
            return responder1
        }
        if let responder4 = responder as? UIViewController, let responder5 = responder4.navigationController {
            return nextResponderOfNav(responder: responder5)
        }
        if let responder2 = responder as? UIViewController, let responder3 = responder2.presentingViewController {
            return nextResponderOfNav(responder: responder3)
        }
        guard let responder6 = responder.next else {
            return nil
        }
        return nextResponderOfNav(responder: responder6)
    }
    
    // Returns the top most view controller from given view controller's stack.
    // 但是增加了对iPad present弹出popover视图的支持，使之在这种情况下可以返回正确的VC,需要开启修复只需fixForPopover为true
    public class func topMost(of viewController: UIViewController?, searchSubViews: Bool = false, fixForPopover: Bool = false) -> UIViewController? {
        return topMost(of: viewController, options: [.SearchSubviews(searchSubViews), .FixPopupOver(fixForPopover)])
    }
    
    private class func topMost(of viewController: UIViewController?, options: [TopMostQueryExtra]) -> UIViewController? {
        var searchSubViews = false
        var fixForPopover = false
        var openSchemaPadWebNavFixEnabled = false
        for option in options {
            switch option {
            case .SearchSubviews(let value):
                searchSubViews = value
            case .FixPopupOver(let value):
                fixForPopover = value
            case .OpenSchemaPadWebNavFixEnabled(let value):
                openSchemaPadWebNavFixEnabled = value
            }
        }
        
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            if fixForPopover || Display.pad {
                if Display.pad, let _ = presentedViewController.presentationController as? UIPopoverPresentationController {
                    // 什么都不做，让其继续判断下面的条件
                    // 因为修复的逻辑就是屏蔽presentedViewController，因为这个VC是Popover出来的VC
                    // 让查找逻辑不知道presentedViewController，于是我们就可以解决查找错误的bug
                } else {
                    return topMost(of: presentedViewController, options: options)
                }
            } else {
                return topMost(of: presentedViewController, options: options)
            }
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return topMost(of: selectedViewController, options: options)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController {
            if fixForPopover || Display.pad {
                // 如果开启了修复，那么这里应该找topVC而不是visibleVC，因为visibleVC可能不在这个导航栈中
                // 注意开启了修复，也只会在是iPad的时候，且弹出popover的时候进行修复
                if Display.pad, let _ = viewController?.presentedViewController?.presentationController as? UIPopoverPresentationController {
                    if let visibleViewController = navigationController.topViewController {
                        return topMost(of: visibleViewController, options: options)
                    }
                } else {
                    if let visibleViewController = navigationController.visibleViewController {
                        return topMost(of: visibleViewController, options: options)
                    }
                }
            } else {
                if let visibleViewController = navigationController.visibleViewController {
                    return topMost(of: visibleViewController, options: options)
                }
            }
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return topMost(of: pageViewController.viewControllers?.first, options: options)
        }

        // detailvc is the topmost vc
        if let lastVC = (viewController as? UISplitViewController)?.viewControllers.last {
            return topMost(of: lastVC, options: options)
        }

        // lark iPad 采用的是自定义的LKSpiltViewController2，需要单独处理
        // 同理可参考UIViewController.topMost
        if let lastVC = (viewController as? LKSplitVCDelegate)?.lkTopMost {
            return topMost(of: lastVC, options: options)
        }
        /** 对于小程序，不再检查子视图，因为小程序容器层级是TMAContainerController.view.subviews包含名为subNav的UINavigationController的view，在此之上添加了小程序页面视图BDPAppController，这里需要返回TMAContainerController
         */
         // child view controller
        if searchSubViews {
            for subview in viewController?.view?.subviews ?? [] {
                if let childViewController = subview.next as? UIViewController {
                    return topMost(of: childViewController, options: options)
                }
            }
        }
        
        // iPad H5应用作为主Tab时，通过OpenSchema 跳转页面 会盖住 主Tab
        if openSchemaPadWebNavFixEnabled, let tabWrapperVC = viewController as? TabbarWrapperController, let selectedTabVC = tabWrapperVC.children.last {
            return topMost(of: selectedTabVC, options: options)
        }

        return viewController
    }
    
    public static func showDefaultDetailForPad(from: UIViewController) {
        guard Display.pad else {
            return
        }
        Navigator.shared.showDetail(LKSplitViewController2.DefaultDetailController(), wrap: LkNavigationController.self, from: from) // Global
    }
}
