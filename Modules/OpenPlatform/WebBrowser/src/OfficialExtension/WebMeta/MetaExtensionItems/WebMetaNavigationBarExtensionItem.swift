//
//  WebMetaNavigationBarExtensionItem.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/1/4.
//

import Foundation
import LKCommonsLogging
import LarkSetting
import UniverseDesignColor
import UniverseDesignTheme

private let logger = Logger.webBrowserLog(WebMetaNavigationBarExtensionItem.self, category: "WebMetaNavigationBarExtensionItem")

final public class WebMetaNavigationBarExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebMetaNavigationBarExtensionItem"
    private weak var browser: WebBrowser?
    
    private var isShowNavBar: Bool = true
    private var isShowNavLeftBarBtn: Bool = true
    private var isShowNavRightBarBtn: Bool = true
    private var navBgColor: UIColor? = nil
    private var navFgColor: UIColor? = nil
    
    public static func isShowNavigationBarEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_shownavigationbar"))// user:global
    }
    
    public static func isURLCustomQueryMonitorEnabled() -> Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.urlcustomquerymonitor.disable"))// user:global
    }
    
    public static func isNavBgAndFgColorEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_navigationbarcolor"))// user:global
    }
    
    public static func isHideNavBarItemsEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.hide_navbar_items.enabled"))// user:global
    }
    
    public static func colorFrom(_ string: String?, fgColor flag: Bool) -> UIColor? {
        guard let string = string else {
            return nil
        }
        let components = string.components(separatedBy: ",")
        if components.isEmpty {
            return nil
        }
        if components.count >= 2 {
            if let lightColor = Self.colorFromSingle(components[0], fgColor: flag),
               let darkColor = Self.colorFromSingle(components[1], fgColor: flag) {
                return lightColor & darkColor
            }
        } else if components.count == 1 {
            return Self.colorFromSingle(components[0], fgColor: flag)
        }
        return nil
    }
    
    private static func colorFromSingle(_ string: String, fgColor flag: Bool) -> UIColor? {
        guard UIColor.isValidColorHexString(string) else {
            return nil
        }
        // 若前景色系统仅支持黑色和白色
        if flag {
            guard string.lowercased().hasSuffix("ffffff") || string.lowercased().hasSuffix("000000") else {
                return nil
            }
        }
        // 若 AARRGGBB 或 #AARRGGBB 格式
        if string.count == 8 || string.count == 9 {
            return UIColor.ud.rgba(string)
        }
        return UIColor.ud.rgb(string)
    }
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    public func applyWebMeta(_ meta: WebMeta?) {
        guard let browser = browser else {
            logger.error("applyWebMeta browser is nil")
            return
        }
        guard let url = browser.browserURL else {
            logger.info("applyWebMeta browser url is nil")
            return
        }
        guard browser.configuration.acceptWebMeta else {
            logger.info("applyWebMeta browser do not accept webmeta")
            return
        }
        guard let meta = meta else {
            logger.info("applyWebMeta meta is nil")
            return
        }
        guard let item = browser.resolve(NavigationBarStyleExtensionItem.self) else {
            logger.error("NavigationBarStyleExtensionItem is nil")
            return
        }
        // 若 URL 包含旧版私有参数, 则不再根据 web-meta 更新
        let queryDict = url.lf.queryDictionary
        // 隐藏导航栏&导航按钮FG开关
        if WebMetaNavigationBarExtensionItem.isShowNavigationBarEnabled() {
        if queryDict["op_platform_service"] == nil {
            isShowNavBar = true
            if let showNavBar = meta.showNavBar, showNavBar.lowercased() == "false" {
                isShowNavBar = false
            }
            item.setNavgationBarHidden(browser: browser, hidden: !isShowNavBar, animated: false)
        }
        if queryDict["show_left_button"] == nil {
            isShowNavLeftBarBtn = true
            if let showNavLBarBtn = meta.showNavLBarBtn, showNavLBarBtn.lowercased() == "false" {
                isShowNavLeftBarBtn = false
            }
            item.setNavigationLeftBarBtnItemsHidden(browser: browser, hidden: !isShowNavLeftBarBtn, animated: false)
        }
        if queryDict["show_right_button"] == nil {
            isShowNavRightBarBtn = true
            if let showNavRBarBtn = meta.showNavRBarBtn, showNavRBarBtn.lowercased() == "false" {
                isShowNavRightBarBtn = false
            }
            if browser.isNavigationRightBarExtensionDisable {
                item.setNavigationRightBarBtnItemsHidden(browser: browser, hidden: !isShowNavRightBarBtn, animated: false)
            } else {
                if let navigationExtension = browser.resolve(NavigationBarRightExtensionItem.self) {
                    navigationExtension.isMetaHideRightItems = !isShowNavRightBarBtn
                    navigationExtension.resetAndUpdateRightItems(browser: browser)
                }
            }
        }
        }
        // 导航栏背景色&前景色FG开关
        if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() {
        if !item.isBarColorApi && queryDict["lark_nav_bgcolor"] == nil {
            navBgColor = nil
            if let bgColorStr = meta.navBgColor?.trimmingCharacters(in: .whitespacesAndNewlines), !bgColorStr.isEmpty {
                logger.info("apply web meta navbgcolor: \(bgColorStr)")
                navBgColor = Self.colorFrom(bgColorStr, fgColor: false)
            }
            item.updateBarBgColor(browser: browser, color: navBgColor)
        }
        if !item.isBarColorApi {
            navFgColor = nil
            if let fgColorStr = meta.navFgColor?.trimmingCharacters(in: .whitespacesAndNewlines), !fgColorStr.isEmpty {
                logger.info("apply web meta navfgcolor: \(fgColorStr)")
                navFgColor = Self.colorFrom(fgColorStr, fgColor: true)
            }
            item.updateBarFgColor(browser: browser, color: navFgColor)
        }
        }
        // 隐藏导航栏指定按钮
        if WebMetaNavigationBarExtensionItem.isHideNavBarItemsEnabled() {
        if let hideNavBarItems = meta.hideNavBarItems {
            item.updateNavBarItems(browser: browser, meta: hideNavBarItems)
        }
        }
    }
}
