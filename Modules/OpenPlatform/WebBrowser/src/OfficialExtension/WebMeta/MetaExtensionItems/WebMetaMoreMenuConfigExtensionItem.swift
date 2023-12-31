//
//  WebMetaMoreMenuConfigExtensionItem.swift
//  WebBrowser
//
//  Created by luogantong on 2022/8/14.
//

import Foundation
import WebKit
import UIKit
import ECOProbe
import LarkUIKit
import LarkSetting
import LKCommonsLogging


private let logger = Logger.webBrowserLog(WebMetaMoreMenuConfigExtensionItem.self, category: "WebMetaMoreMenuConfigExtensionItem")


/// meego: https://meego.feishu.cn/larksuite/story/detail/3241478
/// PRD： https://bytedance.feishu.cn/docx/doxcnN7P1NBk7xTzVynqF1lBzAg
/// 技术方案: https://bytedance.feishu.cn/wiki/wikcnEfYH0TP1lMSxZUzwPlvR0e
public final class WebMetaMoreMenuConfigExtensionItem: WebBrowserExtensionItemProtocol{
    public var itemName: String? = "WebMetaMoreMenuConfig"
    private weak var browser: WebBrowser?
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebMetaMoreMenuConfigExtensionItemBrowserLifeCycle(item: self)
    
    public lazy var browserDelegate: WebBrowserProtocol? = WebMetaMoreMenuConfigExtensionItemBrowserDelegate(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebMetaMoreMenuConfigExtensionItemBrowserNavigationDelegate(item: self)
    
    // 缓存metacontent
    var metaContent : String?
    // metacontent split 后得到的数组
    var hideMuenItems : Array<String>?
    // 发送至会话结果为链接
    public var isShareLink: Bool = false
    
    public static func isWebShareLinkEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.sharelink.enabled"))
    }
    
    /// 菜单标识到meta配置标识映射
    private let menuIdToConfigID : Dictionary<String, String> = {
        let menuIdToConfigID = [
            "share":"sendToChat",
            "shareToWeChat":"shareViaOtherApp",
            "copyLink":"copyLink",
            "openInSafari":"openInBrowser"
        ]
        return menuIdToConfigID
    }()
    
    /// meta配置标识转button埋点ID，https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
    private let metaContentToTrackButtonID : Dictionary<String, String> = {
        let menuIdToTrackButtonID = [
            "sendToChat"        : "2002",
            "shareViaOtherApp"  :"2019",
            "copyLink"          :"2017",
            "openInBrowser"     :"2016"
        ]
        return menuIdToTrackButtonID
    }()
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    public func applyMetaContent(metaContent: String?) {
        logger.info("apply meta content hidemenuitems \(metaContent ?? "")")
        guard let browser = browser else {
            logger.error("browser is nil")
            return
        }
        guard browser.configuration.acceptWebMeta else {
            logger.info("browser do not accept webmeta")
            return
        }
        self.metaContent = metaContent
        hideMuenItems = metaContent?.components(separatedBy: ",")
        browser.notifyHideMenuItemsChanged(hideMenuItems: hideMuenItems)
    }
    
    public func applyMenuItemContent(metaContent: String?) {
        logger.info("apply meta content shareLink \(metaContent ?? "")")
        guard let browser = browser else {
            logger.error("browser is nil")
            return
        }
        guard browser.configuration.acceptWebMeta else {
            logger.info("browser do not accept webmeta")
            return
        }
        isShareLink = metaContent?.lowercased() == "true"
    }
    
    public func disabled(menuIdentifier: String) -> Bool {
        if !menuIdToConfigID.keys.contains(menuIdentifier) {
            logger.info("menuIdToConfigID does not contain \(menuIdentifier) key")
            // 不在当前管理范围内，返回false
            return false
        }
        let configIdentifier = menuIdToConfigID[menuIdentifier]
        if let configIdentifier = configIdentifier, let hideMuenItems = hideMuenItems {
            // 判断当前标识是否配置了隐藏(置灰)
            if hideMuenItems.contains(configIdentifier) {
                logger.info("hideMuenItems has a \(configIdentifier) key")
                // 当前标识配置了隐藏(置灰)
                return true
            } else {
                logger.info("hideMuenItems does not contain \(configIdentifier) key")
                // 当前标识未配置隐藏(置灰)
                return false
            }
        } else {
            logger.info("moreMenu does not configuration")
            // 找不到映射的标识，或者隐藏列表配置为空，返回可用
            return false
        }
    }
    
    public func trackMenuHideConfig(){
        guard let browser = browser else {
            return
        }
        if let metaContent = metaContent, !metaContent.isEmpty {
            let button_hide_list = trackButtonHideHist()
            OPMonitor("openplatform_web_container_button_config_status")
                .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
                .addCategoryValue("url", browser.browserURL?.safeURLString)
                .addCategoryValue("is_button_hide", "true")
                .addCategoryValue("button_hide_list", button_hide_list)
                .tracing(browser.webview.trace)
                .setPlatform([.tea, .slardar])
                .flush()
        } else {
            OPMonitor("openplatform_web_container_button_config_status")
                .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
                .addCategoryValue("url", browser.browserURL?.safeURLString)
                .addCategoryValue("is_button_hide", "false")
                .tracing(browser.webview.trace)
                .setPlatform([.tea, .slardar])
                .flush()
        }
    }
    public func trackButtonHideHist() -> String {
        if let hideMuenItems = hideMuenItems, !hideMuenItems.isEmpty {
            var buttonHideList = [String]()
            for item in hideMuenItems {
                if let buttonID = metaContentToTrackButtonID[item] {
                    buttonHideList.append(buttonID)
                }
            }
            return buttonHideList.joined(separator: ",")
        } else {
            return ""
        }
    }
}

final public class WebMetaMoreMenuConfigExtensionItemBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: WebMetaMoreMenuConfigExtensionItem?
    init(item: WebMetaMoreMenuConfigExtensionItem) {
        self.item = item
    }
    
}

final public class WebMetaMoreMenuConfigExtensionItemBrowserDelegate :WebBrowserProtocol {
    private weak var item: WebMetaMoreMenuConfigExtensionItem?
    init(item: WebMetaMoreMenuConfigExtensionItem) {
        self.item = item
    }
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        guard browser.configuration.acceptWebMeta else {
            return
        }
    }
}

final public class WebMetaMoreMenuConfigExtensionItemBrowserNavigationDelegate:WebBrowserNavigationProtocol {
    private weak var item: WebMetaMoreMenuConfigExtensionItem?
    init(item: WebMetaMoreMenuConfigExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        logger.info("didFinish")
        self.item?.trackMenuHideConfig()
    }
}
