//
//  Navigator+ShowTemporaryOrPush.swift
//  LarkNavigator
//
//  Created by Yaoguoguo on 2023/6/11.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import LKCommonsLogging
import LarkTab

extension Navigatable {
    // ipad: 有弹窗，先dismiss, 然后showDetail
    // iphone 走push
    public func showTemporaryOrPush(
        _ viewController: UIViewController,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Completion? = nil) {
        if Display.pad {
            let lksplit = from.larkSplitViewController?.larkSplitViewController
            let split = (from as? UISplitViewController) ?? from.splitViewController
            let detail = lksplit ?? split?.viewControllers.last
            autoDissmisModals(detail)
            self.showDetail(viewController,
                                        wrap: wrap,
                                        from: from,
                                        completion: completion)
        } else {
            self.push(viewController,
                                  from: from,
                                  animated: animated,
                                  completion: completion)
        }
    }

    public func showTemporaryOrPush<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        if Display.pad {
            let lksplit = from.larkSplitViewController
            let split = (from as? UISplitViewController) ?? from.splitViewController
            let detail = lksplit ?? split?.viewControllers.last
            autoDissmisModals(detail)
            self.showDetail(body: body,
                                        naviParams: naviParams,
                                        context: context,
                                        wrap: wrap,
                                        from: from,
                                        completion: completion)
        } else {
            self.push(body: body,
                                  naviParams: naviParams,
                                  context: context,
                                  from: from,
                                  animated: animated,
                                  completion: completion)
        }
    }

    public func showTemporaryOrPush(
        _ url: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        if Display.pad {
            let lksplit = from.larkSplitViewController
            let split = (from as? UISplitViewController) ?? from.splitViewController
            let detail = lksplit ?? split?.viewControllers.last
            autoDissmisModals(detail)
            self.showDetail(url,
                                        context: context,
                                        wrap: wrap,
                                        from: from,
                                        completion: completion)
        } else {
            self.push(url,
                                  context: context,
                                  from: from,
                                  animated: animated,
                                  completion: completion)
        }
    }

    private func autoDissmisModals(_ from: UIViewController?) {
        from?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.larkSplitViewController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.splitViewController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.tabBarController?.presentedViewController?.dismiss(animated: false, completion: nil)
    }
}
