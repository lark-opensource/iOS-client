//
//  OpenAPIGetFilterFGExtensionWebAppImpl.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import WebBrowser
import OPFoundation

final class OpenAPIGetFilterFGExtensionWebAppImpl: OpenAPIGetFilterFGExtension {
    let gadgetContext: GadgetAPIContext
    let context: OpenAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.gadgetContext = try getGadgetContext(context)
        self.context = context
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func appId() -> String? {
        let userResolver = OPUserScope.userResolver()
        guard let target = gadgetContext.controller as? WebBrowser, let appId = try? userResolver.resolve(assert: WebBrowserDependencyProtocol.self).appInfoForCurrentWebpage(browser: target)?.id else {
            context.apiTrace.info("getFilterFeatureGating API:appid is nil")
            return nil
        }
        return appId
    }
}
