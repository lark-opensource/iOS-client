//
//  OpenAPIChatIDExtensionWebAppImpl.swift
//  EcosystemWeb
//
//  Created by baojianjun on 2023/8/15.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

final class OpenAPIChatIDExtensionWebAppImpl: OpenAPIChatIDExtension, OpenAPIExtensionApp {
    let gadgetContext: GadgetAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.gadgetContext = try getGadgetContext(context)
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func requestParams(openChatIDs: [String], ttcode: String) -> [String: Codable] {
        [
            "appid": uniqueID.appID,
            "open_chatids": openChatIDs,
            "ttcode":ttcode,
            sessionKey(): sessionExtension.session(),
        ]
    }
    
    override func sessionKey() -> String {
        "h5Session"
    }
}

