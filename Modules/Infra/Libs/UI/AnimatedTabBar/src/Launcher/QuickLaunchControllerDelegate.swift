//
//  QuickLaunchControllerDelegate.swift
//  AnimatedTabBar
//
//  Created by ByteDance on 2023/4/26.
//

import UIKit
import LarkTab
import RxSwift
import RustPB

protocol QuickLaunchControllerDelegate: AnyObject {

    // MARK: MainTab 事件回调

    /// 通知代理 `QuickLaunchController` 上选中了底栏的 Tab
    func quickLaunchController(_ controller: QuickLaunchController, didSelectItemInBarView tab: Tab)
    /// 通知代理 `QuickLaunchController` 上选中了 “常用” 的 Tab
    func quickLaunchController(_ controller: QuickLaunchController, didSelectItemInPinView tab: Tab)
    /// 通知代理 `QuickLaunchController` 上长按了底栏的 Tab
    func quickLaunchController(_ controller: QuickLaunchController, didLongPressItemInBarView tab: Tab)

    // MARK: QuickTab 事件回调

    /// 通知代理 `QuickLaunchController` 上点击了底栏的关闭按钮
    func quickLaunchControllerDidTapCloseButton(_ controller: QuickLaunchController)
    /// 通知代理 `QuickLaunchController` 上点击了 “编辑” 按钮
    func quickLaunchControllerDidTapEditButton(_ controller: QuickLaunchController)

    // MARK: ”快捷导航“ 事件回调

    /// 请求是否Tab已经存在于「常用」或主导航
    func quickLaunchController(_ controller: QuickLaunchController, findItemIsInQuickLaunchView tab: TabCandidate) -> Observable<Bool>
    /// 通知代理 `QuickLaunchController` 上把 “快捷导航” 的 item 重命名
    func quickLaunchController(_ controller: QuickLaunchController, shouldRenameItemInQuickLaunchArea tabItem: AbstractTabBarItem, success: (() -> Void)?, fail: (() -> Void)?)
    /// 通知代理 `QuickLaunchController` 上把 “快捷导航” 的 item 删除
    func quickLaunchController(_ controller: QuickLaunchController, shouldDeleteItemInQuickLaunchArea tab: Tab, success: (() -> Void)?, fail: (() -> Void)?)
}
