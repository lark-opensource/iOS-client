//
//  WebInspectorPatternHandler.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2022/9/13.
//

import Foundation
import Swinject
import EENavigator
import LKCommonsLogging
import LarkSetting
import UniverseDesignDialog
import LarkNavigator
import LarkContainer

private let logger = Logger.ecosystemWebLog(WebInspectorValidator.self, category: "WebInspectorPatternHandler")

final class WebInspectorPatternHandler: UserRouterHandler {
    public static let pattern = "//client/enable_webview_debug"
    
    public func handle(req: EENavigator.Request, res: EENavigator.Response) {
        //网页在线调试能力由灰度开关控制
        guard WebInspectorValidator.hostWhiteList != nil else {
            // 如果从 settings 拉取的域名白名单为空，说明该用户不该被开启调试能力
            logger.info("settings: web_onlineDebug is nil")
            res.end(resource: nil)
            return
        }
        
        // 用户扫码后显示提示弹窗
        logger.info("show notice for web debug tool")
        
        var dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Tip)
        dialog.setContent(text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Open_Info)
        dialog.addSecondaryButton(
            text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Cancel,
            dismissCompletion: {
                logger.info("user canceled opening the web debug tool")
            }
        )
        dialog.addPrimaryButton(
            text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Confirm,
            dismissCompletion: {
                logger.info("user checked opening the web debug tool, start update mark")
                //用户确认开启网页调试工具，更新本地的悬浮窗标记
                WebInspectorValidator.updateMark()
            }
        )
        
        req.from.fromViewController?.present(dialog, animated: true)
        res.end(resource: nil)
    }
}

