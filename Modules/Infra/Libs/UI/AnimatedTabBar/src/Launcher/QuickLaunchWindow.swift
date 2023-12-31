//
//  QuickLaunchWindow.swift
//  AnimatedTabBar
//
//  Created by ByteDance on 2023/4/26.
//

import UIKit
import LKWindowManager
import LarkContainer
import LarkExtensions

// QuickLaunch 页面需要在高于当前 MainWindow 的层级打开，所以需要创建独立 Window
// TODO: @qujieye由于屏幕旋转问题，这里临时使用UIWindow，后续考虑替换为LKWindow
public final class QuickLaunchWindow: UIWindow, UserResolverWrapper {

    public let userResolver: UserResolver

    // 是否显示「更多」tab，目前精简模式下不显示该tab
    private let moreTabEnabled: Bool

    init(frame: CGRect, delegate: QuickLaunchControllerDelegate, tabbarVC: AnimatedTabBarController, userResolver: UserResolver, moreTabEnabled: Bool) {
        self.userResolver = userResolver
        self.moreTabEnabled = moreTabEnabled
        super.init(frame: frame)
        // 层级低于多任务浮窗的 9.8
        windowLevel = UIWindow.Level(9.6)
        rootViewController = QuickLaunchController(delegate: delegate, tabbarVC: tabbarVC, userResolver: userResolver, moreTabEnabled: moreTabEnabled)
        self.windowIdentifier = "AnimatedTabBar.QuickLaunchWindow"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 快捷访问 `QuickLaunchController`
    var launchController: QuickLaunchController {
        if let currentController = rootViewController as? QuickLaunchController {
            return currentController
        } else {
            assertionFailure("launchController should not be nil")
            let newController = QuickLaunchController(delegate: nil, tabbarVC: nil, userResolver: self.userResolver, moreTabEnabled: self.moreTabEnabled)
            rootViewController = newController
            return newController
        }
    }

    public func reloadData() {
        launchController.reloadData()
    }
}

