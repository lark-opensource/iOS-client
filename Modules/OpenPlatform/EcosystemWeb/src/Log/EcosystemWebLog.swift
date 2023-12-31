//
//  EcosystemWebLog.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/9/8.
//

import LarkOPInterface
import LarkWebViewContainer
import LKCommonsLogging
import WebBrowser

private let ecosystemWebLogLogCategoryPrefix = "ecosystemWeb."

extension Logger {
    public class func ecosystemWebLog(_ type: Any, category: String = "") -> Log {
        //  基于 webBrowser 扩展一层
        webBrowserLog(type, category: ecosystemWebLogLogCategoryPrefix + category)
    }
}
