//
//  TabMicroAppHandler.swift
//  LarkTabMicroApp
//
//  Created by tujinqiu on 2019/12/19.
//

import EENavigator
import Swinject
import LarkUIKit
import AnimatedTabBar
import LarkTab
import OPSDK
import LarkMicroApp
import LarkFeatureGating
import LarkNavigator

class TabMicroAppHandler: UserRouterHandler {
    private let queryKey = "key"
    private let iPad_tab_push_fg = "mobile.ipad.ecosystem.navigation.ipad_tab_push"
    
    static func compatibleMode() -> Bool {
        OPUserScope.compatibleModeEnabled
    }
    
    func handle(req: EENavigator.Request, res: Response) throws {
        if let appIDKey = getAppIDKey(url: req.url),
           let tab = Tab.getTab(appType: .gadget, key: appIDKey) ?? Tab.getTab(appType: .appTypeOpenApp, key: appIDKey) {
            let tabExtra = GadgetTabExtra(dict: tab.extra)
            let nav : LkNavigationController

            // 通知需要保证登录（某些场景下默认的主动登录任务会延迟数秒才会执行，可能晚于用户操作）
            OpenAppEngine.shared.notifyLoginIfNeeded()
            let controller: UIViewController = TabGadgetViewController(resolver: userResolver, tab: tab)
            let iPad_tab_push_fg = LarkFeatureGating.shared.getFeatureBoolValue(for: iPad_tab_push_fg)
            if Display.pad && iPad_tab_push_fg {
                // UITabbarController调用setViewControllers时，当多于6个VC时，系统会默认把多余的VC加入到moreNavigation里，
                // moreNavigation自身就是一个UINavigationController，不能再push一个节点是UINavigationController的导航栈
                // 此时需要wrapper一层
                // LkTabbarController有类似兜底逻辑，但为了 `fetchNavigationContext`方法里的跳转判断能在小程序范围内可控，所以本地加了vc的wrapper
                nav = LkNavigationController(rootViewController: controller)
                let wrapper = UIViewController()
                nav.willMove(toParent: wrapper)
                wrapper.addChild(nav)
                nav.view.frame = wrapper.view.frame
                wrapper.view.addSubview(nav.view)
                nav.didMove(toParent: wrapper)
                res.end(resource: wrapper)
            } else {
                res.end(resource: controller)
            }
        } else {
            res.end(resource: nil)
        }
    }

    private func getAppIDKey(url: URL) -> String? {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = urlComponents.queryItems {
            return queryItems.first { (item) -> Bool in
                return item.name == queryKey
            }?.value
        }
        return nil
    }
}
