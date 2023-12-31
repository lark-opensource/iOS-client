//
//  WKNavigationDelegateFailFix.swift
//  WebBrowser
//
//  Created by yinyuan on 2021/11/3.
//

import Foundation

public final class WKNavigationDelegateFailFix {
    
    /// 检查 WKNavigationDelegate 返回的 Error 是否是严重 Error（实际上一些情况的 Error 不会导致明确的网页异常）
    /// - Parameter error: didFail 和 didFailProvisionalNavigation 中的异常
    /// - Returns: 是否是严重 Error
    public static func isFatalWebError(error: Error) -> Bool {
        // Ignore the "Frame load interrupted" error that is triggered when we cancel a request
        // to open an external application and hand it over to UIApplication.openURL(). The result
        // will be that we switch to the external app, for example the app store, while keeping the
        // original web page in the tab instead of replacing it with an error page.
        let error = error as NSError
        let cancelRequestCode = 102
        /* code from WebKitErrorsPrivate.h
        // FIXME: WebKitErrorPlugInWillHandleLoad is used for the cancel we do to prevent loading plugin content twice.  See <rdar://problem/4258008>
        #define WebKitErrorPlugInWillHandleLoad 204
         */
        let plugInWillHandleLoadCode = 204
        if error.domain == "WebKitErrorDomain" && (error.code == cancelRequestCode || error.code == plugInWillHandleLoadCode) {
            return false
        }
        if error.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
            return false
        }
        return true
    }
    
}
