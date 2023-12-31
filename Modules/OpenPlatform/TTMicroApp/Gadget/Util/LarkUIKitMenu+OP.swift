//
//  LarkUIKitMenu+OP.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/4/24.
//

import Foundation
import LarkUIKit
import OPSDK

extension MenuItemModel {
    private static var _opMenuItemButtonIdKey: Void?

    public var menuItemCode: OPMenuItemMonitorCode {
        get {
            return objc_getAssociatedObject(self, &MenuItemModel._opMenuItemButtonIdKey) as? OPMenuItemMonitorCode ?? .unknown
        }
        set {
            objc_setAssociatedObject(self, &MenuItemModel._opMenuItemButtonIdKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

extension MenuAdditionView {
    private static var _opAddtionViewButtonIdListKey: Void?

    public var menuItemCodeList: [OPMenuItemMonitorCode] {
        get {
            return objc_getAssociatedObject(self, &MenuAdditionView._opAddtionViewButtonIdListKey) as? [OPMenuItemMonitorCode] ?? []
        }
        set {
            objc_setAssociatedObject(self, &MenuAdditionView._opAddtionViewButtonIdListKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension MenuPlugin {
    public func itemActionReport(applicationID: String?, menuItemCode: OPMenuItemMonitorCode) {
        OPMonitor("openplatform_mp_container_menu_click")
            .addCategoryValue("application_id", applicationID ?? "none")
            .addCategoryValue("click", "button")
            .addCategoryValue("target", "none")
            .addCategoryValue("button_id", menuItemCode.rawValue)
            .setPlatform(.tea)
            .flush()
    }
}

@objcMembers
open class OPMenuItemModelbridge: NSObject {
    public static func menuItemCodeString(_ menuItem: MenuItemModel) -> String {
        return menuItem.menuItemCode.rawValue
    }

    public static func addtionViewItemCodeList(_ addtionView: MenuAdditionView) -> [String] {
        return addtionView.menuItemCodeList.map {
            $0.rawValue
        }
    }
}


/// 导航栏按钮的标识符
/// 产品埋点
@objcMembers
open class OPNavigationBarItemConsts: NSObject {
    /// 返回上一个按钮"<"
    public static let backButtonKey = "gadget.navigationBarItem.backButton"
    /// 返回首页按钮
    public static let homeButtonKey = "gadget.navigationBarItem.homeButton"
    /// 工具栏中更多按钮(与原来的字符串保持一致)
    public static let moreButtonKey = "gadget.page.moreButton"
    /// 工具栏中关闭按钮(与原来的字符串保持一致)
    public static let closeButtonKey = "gadget.page.closeButton"
}

@objcMembers
open class OPNavigationBarItemMonitorCodeBridge: NSObject {
    /// 返回按钮"<"
    public static let backButton = OPNavigationBarItemMonitorCode.backButton.rawValue
    /// 返回首页按钮
    public static let homeButton = OPNavigationBarItemMonitorCode.homeButton.rawValue
    /// 更多按钮
    public static let moreButton = OPNavigationBarItemMonitorCode.moreButton.rawValue
    /// 关闭按钮
    public static let closeButton = OPNavigationBarItemMonitorCode.closeButton.rawValue
    /// 独立窗口按钮
    public static let windowButton = OPNavigationBarItemMonitorCode.windowButton.rawValue
    /// 完成按钮
    public static let completeButton = OPNavigationBarItemMonitorCode.completeButton.rawValue
    /// 前进按钮
    public static let forwardButton = OPNavigationBarItemMonitorCode.forwardButton.rawValue
}
