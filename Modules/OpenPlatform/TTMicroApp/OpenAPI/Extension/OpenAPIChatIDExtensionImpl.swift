//
//  OpenAPIChatIDExtensionImpl.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/8/15.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

final class OpenAPIChatIDExtensionGadgetImpl: OpenAPIChatIDExtensionAppImpl {
    
    // 除了该方法, 其他都继承自父类
    override func sessionKey() -> String {
        "minaSession"
    }
}

typealias OpenAPIChatIDExtensionBlockImpl = OpenAPIChatIDExtensionAppImpl

class OpenAPIChatIDExtensionAppImpl: OpenAPIChatIDExtension, OpenAPIExtensionApp {
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
}
