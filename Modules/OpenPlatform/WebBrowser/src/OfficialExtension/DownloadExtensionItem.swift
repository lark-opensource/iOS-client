//
//  DownloadExtensionItem.swift
//  WebBrowser
//
//  Created by yinyuan on 2021/12/8.
//
import LKCommonsLogging
import WebKit
import UniverseDesignDialog
import ECOInfra
import LarkSetting
import LarkFeatureGating
import LarkWebViewContainer

private let logger = Logger.webBrowserLog(DownloadExtensionItem.self, category: "DownloadExtensionItem")

/// 目前 Extension 框架还不支持异步 decisionHandler 回调，代码先采用类似 ExtensionItem 的方式内聚在这里，后续如果 Extension 框架支持了异步回调，可快速改为标准 ExtensionItem
final class DownloadExtensionItem {
    
    /// 务必回调，否则会阻塞网页加载
    func browser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        if browser.configuration.downloadEnable,
            let url = navigationResponse.response.url,
            canDownload(browser: browser, navigationResponse: navigationResponse)
        {
            browser.webview.recordWebviewCustomEvent(.didDownLoad)
            tryDownload(browser: browser, url: url) { download in
                if download {
                    if UIApplication.shared.canOpenURL(url) {
                        decisionHandler(.cancel)
                        logger.info("download start openURL")
                        UIApplication.shared.open(url)
                    } else {
                        logger.warn("download can not openURL")
                        decisionHandler(.allow)
                    }
                } else {
                    decisionHandler(.allow)
                }
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    private func canDownload(browser: WebBrowser, navigationResponse: WKNavigationResponse) -> Bool {
        if navigationResponse.response.mimeType == MIMEType.OctetStream {
            logger.info("download type: \(MIMEType.OctetStream)")
            return true
        } else if let response = navigationResponse.response as? HTTPURLResponse,
                  let contentType = HTTPHeaderInfoUtils.value(response: response, forHTTPHeaderField: "Content-Disposition"),
                   contentType.starts(with: "attachment") {
            logger.info("download type: Content-Disposition:attachment")
            return true
        } else if navigationResponse.canShowMIMEType == false {
            logger.info("download type: canShowMIMEType")
            return true
        }
        return false
    }
    
    private func tryDownload(browser: WebBrowser, url: URL, decisionHandler: @escaping (Bool) -> Void) {
        logger.info("tryDownload safeURLString:\(url.safeURLString)")
        DispatchQueue.main.async { [weak browser] in
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.WebBrowser.OpenPlatform_WebViewDownload_DownloadBttn)
            dialog.setContent(text: BundleI18n.WebBrowser.OpenPlatform_WebViewDownload_DownloadDesc)
            let completionHandlerCrashProtection = WKUIDelegateCrashProtection(decisionHandler, defaultCompletionHandlerParamsValue: false)
            dialog.addSecondaryButton(
                text: BundleI18n.WebBrowser.OpenPlatform_Common_Cancel,
                dismissCompletion: {
                    logger.info("download cancel")
                    completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: false)
                }
            )
            dialog.addPrimaryButton(
                text: BundleI18n.WebBrowser.OpenPlatform_Common_Confirm,
                dismissCompletion: {
                    logger.info("download confirm")
                    completionHandlerCrashProtection.callCompletionHandler(completionHandlerParamsValue: true)
                }
            )
            browser?.present(dialog, animated: true, completion: nil)
        }
    }
    
}
