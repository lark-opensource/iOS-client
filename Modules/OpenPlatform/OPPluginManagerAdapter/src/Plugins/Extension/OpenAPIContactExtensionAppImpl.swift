//
//  OpenAPIContactExtensionAppImpl.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/6/5.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager

final class OpenAPIContactExtensionAppImpl: OpenAPIContactExtension, OpenAPIExtensionApp {
    let gadgetContext: GadgetAPIContext
    let context: OpenAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.context = context
        self.gadgetContext = try getGadgetContext(context)
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func requestParams(openid: String, ttcode: String) -> [String: String] {
        [
            "appid": uniqueID.appID,
            "openid": openid,
            "ttcode": ttcode,
            "session": self.sessionExtension.session(),
        ]
    }
    
    override func networkContext() -> ECONetworkServiceContext {
        OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: uniqueID, source: .api)
    }
}
