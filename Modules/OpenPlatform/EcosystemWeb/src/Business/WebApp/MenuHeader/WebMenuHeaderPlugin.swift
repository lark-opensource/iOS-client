//
//  WebMenuHeaderPlugin.swift
//  WebBrowser
//
//  Created by 刘洋 on 2021/3/3.
//

import UIKit
import LarkUIKit
import LKCommonsLogging
import WebBrowser

/// 日志
private let logger = Logger.ecosystemWebLog(WebMenuHeaderPlugin.self, category: NSStringFromClass(WebMenuHeaderPlugin.self))

/// 网页菜单的头部插件，用于显示网址
public final class WebMenuHeaderPlugin: MenuPlugin {
    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            logger.info("WebMenuHeaderPlugin init failure because there is no WebBrowserMenuContext")
            return nil
        }
        guard let browser = webMenuContext.webBrowser else {
            logger.info("WebMenuHeaderPlugin init failure because webMenuContext.webBrowser is nil")
            return nil
        }
        if browser.isWebAppForCurrentWebpage {
            logger.info("WebMenuHeaderPlugin plugin init failure because there is webApp")
            return nil
        }
        self.menuContext = webMenuContext
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        // 产品需求要求:仅iPhone才显示网页菜单的头部
        guard !Display.pad else {
            return
        }
        fetchAdditionView{
            additionView in
            handler.updatePanelHeader(for: additionView)
        }
    }

    public static var pluginID: String {
        "WebMenuHeaderPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }

    /// 获取头部视图的数据模型
    /// - Parameter updater: 更新头部视图的回调
    private func fetchAdditionView(updater: @escaping (MenuAdditionView?) -> ()) {
        let url = self.menuContext.webBrowser?.browserURL
        /// - warning:
        ///     由于国际化文案返回的字符串中的替换符可能随时改变，所以在这里我们通过现有方法将替换符替换成$，然后再将替换好的文本使用$切割，这里有一个很危险的情况，那就是要确保国际化文案不能包含$，这里要随时注意国际化文案的内容，以免出现不好的意外
        if url == nil || url?.host == nil {
            // 如果没有host，则记录一下日志
            logger.warn("host of url or url is nil, neeed to notice!")
        }
        // 与产品协商好了，如果没有host，那么就显示整个url，显示视图已经做好了自适应，不必担心会超长
        let hostName = url?.host ?? url?.absoluteString ?? ""
        let delimiter = Character("$")
        let displayTitle = BundleI18n.EcosystemWeb.OpenPlatform_AppActions_DisplayDomainDesc(delimiter)
        var delimiterCount = 0
        for character in displayTitle {
            if character == delimiter {
                delimiterCount += 1
            }
        }
        guard delimiterCount == 1, let index = displayTitle.firstIndex(of: delimiter) else {
            logger.error("There are multiple $ in international copywriting!")
            assert(false, "这里必然有$,且只允许有一个,否则就是国际化文案处理方法有问题")
            return
        }
        var leftString = ""
        let middleString = hostName
        var rightString = ""
        if index == displayTitle.startIndex {
            rightString = String(displayTitle[displayTitle.index(after: index) ..< displayTitle.endIndex])
        } else if index == displayTitle.index(before: displayTitle.endIndex) {
            leftString = String(displayTitle[displayTitle.startIndex ..< index])
        } else {
            leftString = String(displayTitle[displayTitle.startIndex ..< index])
            rightString = String(displayTitle[displayTitle.index(after: index) ..< displayTitle.endIndex])
        }
        logger.info("success to anlystic url of web, ready to display")

        let titleAdditionView = MenuTitleAdditionView(leftTitle: leftString, middleTitle: middleString, rightTitle: rightString)
        let additionView = MenuAdditionView(titleView: titleAdditionView)
        updater(additionView)
    }
}
