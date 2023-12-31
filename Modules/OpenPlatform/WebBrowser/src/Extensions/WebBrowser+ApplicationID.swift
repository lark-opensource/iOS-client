//
//  WebBrowser.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/4/24.
//

import Foundation

extension WebBrowser {
    
    /// 快捷获取当前页面的 appID，仅限于 pod 内部埋点场景调用，不对外，不要改 public
    func currrentWebpageAppID() -> String? {
        if let id = webBrowserDependency.appInfoForCurrentWebpage(browser: self)?.id {
            return id
        }
        return nil
    }
    
}
