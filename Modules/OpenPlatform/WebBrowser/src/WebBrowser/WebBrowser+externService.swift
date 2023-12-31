//
//  WebBrowser+externService.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/7/19.
//

import Foundation

public extension WebBrowser {
    func registerExtensionItemsForBitableHomePage() {
        webBrowserDependency.registerExtensionItemsForBitableHomePage(browser: self)
    }
}
