//
//  AnimatedTabBarController+QuickLauncher.swift
//  AnimatedTabBar
//
//  Created by ByteDance on 2023/4/27.
//

import UIKit
import LarkTab
import RxSwift
import EENavigator
import LarkSceneManager
import RustPB

// 记录Tab点击事件来源，业务需要记录url/小程序打开来源用来埋点
// 由于没法依赖开平埋点仓库，只能再创建一个枚举
public enum TabItemClickSource: String {
    case launcherTab = "launcher_tab"
    case launcherMore = "launcher_more"
    case launcherRecent = "launcher_recent"

    public static let tabItemSourceKey = "from"
}

// MARK: Show / Dismiss QuickLauncher

extension AnimatedTabBarController {

    func showOrDismissQuickLauncher() {
        if isQuickLaunchWindowShown {
            dismissQuickLaunchWindow()
        } else {
            showQuickLaunchWindow()
        }
    }

    public var isQuickLaunchWindowShown: Bool {
        quickLaunchWindow != nil
    }

    /// 调用接口，打开 QuickLaunchWindow
    public func showQuickLaunchWindow(fromBarHeight: CGFloat? = nil) {
        guard isQuickLauncherEnabled else { return }
        guard !isQuickLaunchWindowShown else { return }
        // 创建 QuickLaunchWindow
        if #available(iOS 13.0, *) {
            self.setupQuickLaunchWindowByConnectedScene()
        } else {
            self.setupQuickLaunchWindowByApplicationDelegate()
        }
        // 将 QuickLaunchWindow 添加到页面层级
        self.quickLaunchWindow?.isHidden = false
        // 展示 QuickLaunchWindow 时，播放动画
        self.quickLaunchWindow?.launchController.playShowAnimationV2()
    }

    public func dismissQuickLaunchWindow(fromBarHeight: CGFloat? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        // 将 QuickLaunchWindow 从当前页面层级移除
        if animated {
            quickLaunchWindow?.launchController.playDismissAnimationV2(completion: {
                self.quickLaunchWindow?.isHidden = true
                self.quickLaunchWindow = nil
                completion?()
            })
        } else {
            quickLaunchWindow?.isHidden = true
            quickLaunchWindow = nil
            completion?()
        }
    }

    @available(iOS 13.0, *)
    private func rootWindowForScene(scene: UIScene) -> UIWindow? {
        guard let scene = scene as? UIWindowScene else {
            return nil
        }
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
           let rootWindow = delegate.window.flatMap({ $0 }) {
            return rootWindow
        }
        return scene.windows.first
    }

    @available(iOS 13.0, *)
    private func setupQuickLaunchWindowByConnectedScene() {
        if let rootWindow = Navigator.shared.mainSceneWindow {
            // 先找mainScene
            self.quickLaunchWindow = self.createQuickLaunchWindow(window: rootWindow, moreTabEnabled: self.moreTabEnabled)
        } else {
            // 如果找不到mainScene，兜底下
            if let scene = SceneManager.shared.windowApplicationScenes.first,
               let windowScene = scene as? UIWindowScene,
               let rootWindow = rootWindowForScene(scene: windowScene) {
                self.quickLaunchWindow = self.createQuickLaunchWindow(window: rootWindow, moreTabEnabled: self.moreTabEnabled)
            } else {
                Self.logger.error("Find window by connected scene failed.")
            }
        }
    }

    private func setupQuickLaunchWindowByApplicationDelegate() {
        if let delegate = UIApplication.shared.delegate,
              let weakWindow = delegate.window,
              let rootWindow = weakWindow {
            self.quickLaunchWindow = self.createQuickLaunchWindow(window: rootWindow, moreTabEnabled: self.moreTabEnabled)
        } else {
            Self.logger.error("Find window by application delegate failed.")
        }
    }

    private func createQuickLaunchWindow(window: UIWindow, moreTabEnabled: Bool) -> QuickLaunchWindow {
        let launchWindow = QuickLaunchWindow(frame: window.bounds, delegate: self, tabbarVC: self, userResolver: self.userResolver, moreTabEnabled: moreTabEnabled)
        if #available(iOS 13.0, *) {
            launchWindow.windowScene = window.windowScene
        }
        return launchWindow
    }

    // 横竖屏/CR切换时，需要刷新布局
    func layoutQuickLaunchBar() {
        self.quickLaunchWindow?.launchController.layout()
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            /// 放到下个runloop更新，确保content view宽度已经完全正确
            self.quickLaunchWindow?.launchController.reloadData()
        }
    }
}

// MARK: Handle QuickLauncher Events

extension AnimatedTabBarController: QuickLaunchControllerDelegate {

    func quickLaunchController(_ controller: QuickLaunchController, didSelectItemInBarView tab: Tab) {
        dismissQuickLaunchWindow {
            if let url = URL(string: self.selectedTab.urlString), tab.openMode == .switchMode {
                Navigator.shared.switchTab(url, from: controller)
            }
            self.updateMainTabBarSelectionState(isQuickTabOpened: true)
            // 拼接来源参数
            var tab = tab
            tab.extra[TabItemClickSource.tabItemSourceKey] = TabItemClickSource.launcherTab.rawValue
            self.tabItemSelectHandler(for: tab)
        }
    }

    func quickLaunchController(_ controller: QuickLaunchController, didSelectItemInPinView tab: Tab) {
        dismissQuickLaunchWindow {
            if let url = URL(string: self.selectedTab.urlString), tab.openMode == .switchMode {
                Navigator.shared.switchTab(url, from: controller)
            }
            self.updateMainTabBarSelectionState(isQuickTabOpened: true)
            // 拼接来源参数
            var tab = tab
            tab.extra[TabItemClickSource.tabItemSourceKey] = TabItemClickSource.launcherMore.rawValue
            self.tabItemSelectHandler(for: tab)
        }
    }

    func quickLaunchController(_ controller: QuickLaunchController, didLongPressItemInBarView tab: Tab) {
        dismissQuickLaunchWindow {
            self.updateMainTabBarSelectionState(isQuickTabOpened: true)
            self.tabItemLongPressHandler(for: tab)
        }
    }

    func quickLaunchControllerDidTapCloseButton(_ controller: QuickLaunchController) {
        // close
        dismissQuickLaunchWindow {
            self.updateMainTabBarSelectionState(isQuickTabOpened: true)
        }
    }

    func quickLaunchControllerDidTapEditButton(_ controller: QuickLaunchController) {
        // show edit vc
        showTabEditController(on: controller)
    }

    func quickLaunchController(_ controller: QuickLaunchController, findItemIsInQuickLaunchView tab: TabCandidate) -> Observable<Bool> {
        return animatedTabBarDelegate?.tabbarController(self, findItemIsInQuickLaunchView: tab) ?? .just(false)
    }

    /// 通知代理 `QuickLaunchController` 上把 “快捷导航” 的 item 重命名
    func quickLaunchController(_ controller: QuickLaunchController, shouldRenameItemInQuickLaunchArea tabItem: AbstractTabBarItem, success: (() -> Void)?, fail: (() -> Void)?) {
        animatedTabBarDelegate?.tabbarController(self, fromVC: controller, shouldRename: tabItem, success: success, fail: fail)
    }

    /// 通知代理 `QuickLaunchController` 上把 “快捷导航” 的 item 删除
    func quickLaunchController(_ controller: QuickLaunchController, shouldDeleteItemInQuickLaunchArea tab: Tab, success: (() -> Void)?, fail: (() -> Void)?) {
        animatedTabBarDelegate?.tabbarController(self, shouldDelete: tab, success: success, fail: fail)
    }
}
