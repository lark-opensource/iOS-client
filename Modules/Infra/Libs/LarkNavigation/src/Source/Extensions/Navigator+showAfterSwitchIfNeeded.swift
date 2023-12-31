//
//  Navigator+showAfterSwitchIfNeeded.swift
//  LarkNavigator
//
//  Created by lixiaorui on 2019/9/3.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import LarkNavigator
import LarkTab

/// 先放到这里, LarkNavigator不应该依赖较重的LarkNavigation
extension Navigatable {
    public func showDetailOrPush(url: URL, tab: Tab, from: NavigatorFrom) {
        var params = NaviParams()
        params.switchTab = tab.url
        /// see URLInterceptorManager.push(), only valid for router's push
        params.forcePush = true
        let context = [String: Any](naviParams: params)
        self.showAfterSwitchIfNeeded(
            url, tab: tab.url, context: context,
            wrap: LkNavigationController.self, from: from) { (err) in
                if err != nil {
                    Navigator.logger.error(
                        "url interceptor failed",
                        additionalData: ["url": url.absoluteString],
                        error: err
                    )
                }
        }
    }

    // iPad 先跳转tab，再showDetail
    // iphone，直接push
    public func showAfterSwitchIfNeeded<T: Body> (
        tab: URL,
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any]? = nil,
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        animated: Bool = true,
        completion: ((RouterError?) -> Void)? = nil) {
        if Display.pad {
            // ipad先跳转在showDetail
            self.switchTab(tab, from: from, animated: animated) { success in
                guard success else {
                    completion?(RouterError.empty)
                    return
                }
                guard let realFrom = (RootNavigationController.shared.viewControllers.first as? UITabBarController)?.selectedViewController else {
                    completion?(RouterError.invalidParameters("can not find real from after switch"))
                    return
                }
                self.showDetailOrPush(
                    body: body, naviParams: naviParams, context: context ?? [String: Any](),
                    wrap: wrap, from: realFrom, completion: { (_, res) in
                        completion?(res.error)
                    })
            }
        } else {
            // iphone直接走push
            self.push(
                body: body, naviParams: naviParams, context: context ?? [String: Any](),
                from: from, animated: animated, completion: { (_, res) in
                    completion?(res.error)
                })
        }
    }

    public func showAfterSwitchIfNeeded (
        _ url: URL,
        tab: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        animated: Bool = true,
        completion: ((RouterError?) -> Void)? = nil) {
        if Display.pad {
            // ipad switch tab first
            self.switchTab(tab, from: from, animated: animated) { success in
                guard success else {
                    completion?(RouterError.empty)
                    return
                }
                guard let realFrom = (RootNavigationController.shared.viewControllers.first as? UITabBarController)?.selectedViewController else {
                    completion?(RouterError.invalidParameters("can not find real from after switch"))
                    return
                }
                self.showDetailOrPush(
                    url, context: context, wrap: wrap,
                    from: realFrom, animated: animated, completion: { (_, res) in
                        completion?(res.error)
                    })
            }
        } else {
            // iphone use push directly
            self.push(url, context: context, from: from, animated: animated, completion: { (_, res) in
                completion?(res.error)
            })
        }
    }
}
