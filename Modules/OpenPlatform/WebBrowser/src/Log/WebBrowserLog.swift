//
//  WebBrowserLog.swift
//  WebBrowser
//
//  Created by houjihu on 2020/10/1.
//

import LarkOPInterface
import LarkWebViewContainer
import LKCommonsLogging

/// 套件统一浏览器日志category前缀
private let webBrowserLogLogCategoryPrefix = "webBrowser."

/// Logger extension，封装专门用于标识套件统一浏览器模块的log方法
extension Logger {
    /// 获取专门用于标识套件统一浏览器模块的日志对象
    /// - Parameters:
    ///   - type: 类型
    ///   - category: 类别，可为空
    /// - Returns: 日志对象
    public class func webBrowserLog(_ type: Any, category: String = "") -> Log {
        //  基于op进行lwvc的extension
        lkwlog(type, category: webBrowserLogLogCategoryPrefix + category)
    }
}
