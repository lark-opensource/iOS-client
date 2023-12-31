//
//  WebBrowser+WKUIDelegate.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2020/10/2.
//

import ECOInfra
import EENavigator
import UniverseDesignDialog
import UniverseDesignInput
import WebKit

extension WebBrowser: WKUIDelegate {
    // MARK: - Creating and Closing the Web View
    /// window.open
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/open
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let traceId = traceId(from: webView)
        Self.logger.lkwlog(level: .info, "createWebViewWith configuration, navigationAction.request.url.safeURLString:\(navigationAction.request.url?.safeURLString), navigationType:\(navigationAction.navigationType)", traceId: traceId)
        // 1. 检查url不为空
        guard let url = navigationAction.request.url else {
            Self.logger.lkwlog(level: .error, "createWebViewWith configuration, navigationAction.request.url is nil", traceId: traceId)
            return nil
        }
        // 2. 判断是否为网络诊断页面
        if WebDetectHelper.isValid(url: url) {
            WebDetectHelper().loadPage(self, fromUrl: self.browserURL)
            Self.logger.lkwlog(level: .info, "window.opwn detect page", traceId: traceId)
            return nil
        }
        
        let closeSelf = self.canCloseSelf(with: url, scene: .window_open)
        if (closeSelf) {
            self.closeSelfMonitor(with: url, scene: .window_open)
        }
       
        // 3. 判断Lark其他业务是否能够处理
        let canOpen = self.tryOpenNotInWebbrowser(url: url, from: self.browserURL, closeSelf: closeSelf)
        if canOpen {
            Self.logger.lkwlog(level: .info, "createWebViewWith configuration, canOpen is true, open by extern code", traceId: traceId)
            return nil
        }
        
        // 3. push新的vc打开
        // 通过from参数来维持打开后的url request请求头中的referer
        // 参考“biz.util.openLink”的实现. 历史对接人： @lizhong.limboy
        Self.logger.lkwlog(level: .info, "createWebViewWith configuration, open by Navigator.shared.push, closeSelf: \(closeSelf)",  traceId: traceId)

        let appId = self.currrentWebpageAppID() ?? ""
        Navigator.shared.push ( // user:global
            url,
            context: [
                "from": self.browserURL?.absoluteString ?? "",
                "open_doc_desc": self.browserURL?.absoluteString ?? "",
                "open_doc_source": "web_applet",
                "open_doc_app_id": appId,
                // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                "lk_web_from": "webbrowser",
                "lk_web_mode": self.configuration.scene.rawValue,
                "forcePush": true,
                // 显示传入openType是因为EEnavigator里getNaviParams里的decode现在有问题，这里先兜底处理
                "openType": OpenType.push
            ],
            from: self
        )
        // 需要关闭时触发
        if closeSelf {
            self.delayRemoveSelfInViewControllers()
        }
        return nil
    }
    
    /// window.close
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/close
    public func webViewDidClose(_ webView: WKWebView) {
        Self.logger.lkwlog(level: .info, "webViewDidClose, webview.url.safeURLString:\(webView.url?.safeURLString)", traceId: traceId(from: webView))
        closeBrowser()
    }
    
    // MARK: - Displaying UI Panels
    /// window.alert
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/alert
    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        Self.logger.lkwlog(level: .info, "runJavaScriptAlertPanelWithMessage \(message), isMainFrame: \(frame.isMainFrame)", traceId: traceId(from: webView))
        let dialog = UDDialog()
        dialog.setContent(text: message)
        let completionHandlerCrashProtection = WKUIDelegateCrashProtection(completionHandler)
        dialog.addPrimaryButton(
            text: BundleI18n.WebBrowser.Lark_Legacy_Sure,
            dismissCompletion: {
                completionHandlerCrashProtection.callCompletionHandler()
            }
        )
        present(dialog, animated: true, completion: nil)
    }
    
    /// window.confirm
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/confirm
    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Self.logger.lkwlog(level: .info, "runJavaScriptConfirmPanelWithMessage \(message), isMainFrame: \(frame.isMainFrame)", traceId: traceId(from: webView))
        let dialog = UDDialog()
        dialog.setContent(text: message)
        let completionHandlerCrashProtection = WKUIDelegateCrashProtection(completionHandler, defaultCompletionHandlerParamsValue: false)
        dialog.addSecondaryButton(
            text: BundleI18n.WebBrowser.Lark_Legacy_Cancel,
            dismissCompletion: {
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: false)
            }
        )
        dialog.addPrimaryButton(
            text: BundleI18n.WebBrowser.Lark_Legacy_Sure,
            dismissCompletion: {
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: true)
            }
        )
        present(dialog, animated: true, completion: nil)
    }
    
    /// window.prompt
    /// https://developer.mozilla.org/zh-CN/docs/Web/API/Window/prompt
    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        Self.logger.lkwlog(level: .info, "runJavaScriptTextInputPanelWithPrompt prompt{\(prompt)} & defaultText{\(defaultText)} & isMainFrame{\(frame.isMainFrame)}", traceId: traceId(from: webView))
        let dialog = UDDialog()
        dialog.setTitle(text: prompt)
        let textfield = UDTextField(config: .init(isShowBorder: true))
        textfield.placeholder = BundleI18n.WebBrowser.Lark_Legacy_PromotDefaultText
        if let text = defaultText {
            textfield.text = text
        }
        dialog.setContent(view: textfield)
        let completionHandlerCrashProtection = WKUIDelegateCrashProtection(completionHandler, defaultCompletionHandlerParamsValue: nil)
        dialog.addSecondaryButton(
            text: BundleI18n.WebBrowser.Lark_Legacy_Cancel,
            dismissCompletion: {
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: nil)
            }
        )
        dialog.addPrimaryButton(
            text: BundleI18n.WebBrowser.Lark_Legacy_Sure,
            dismissCompletion: { [weak textfield] in
                completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: textfield?.text)
            }
        )
        present(dialog, animated: true, completion: nil)
    }
}
