//
//  OpenAPIWebSessionUpdateIMP.swift
//  EcosystemWeb
//
//  Created by zhaojingxin on 2023/6/13.
//

import Foundation
import WebBrowser
import LKCommonsLogging

final class OpenAPIWebSessionUpdateIMP: OpenAPIWebSessionUpdate {
    
    private static let logger = Logger.oplog(OpenAPIWebSessionUpdateIMP.self, category: "OpenAPIWebSessionUpdateIMP")
    
    func updateSession(_ session: String, url: URL, browser: WebBrowser) {
        if let extensionItem = browser.resolve(WebAppExtensionItem.self) {
            extensionItem.webAppJsSDKWithAuth?.updateSession(session: session, url: url)
        } else {
            Self.logger.error("WebAppExtensionItem resolve failed")
        }
    }
}
