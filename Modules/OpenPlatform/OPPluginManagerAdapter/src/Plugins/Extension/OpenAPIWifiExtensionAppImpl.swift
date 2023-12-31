//
//  OpenAPIWifiExtensionAppImpl.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/6/10.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager

final class OpenAPIWifiExtensionAppImpl: OpenAPIWifiExtension, OpenAPIExtensionApp {
    let gadgetContext: GadgetAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.gadgetContext = try getGadgetContext(context)
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func addAppIdInfo(in monitor: OPMonitor) {
        monitor.addCategoryValue("appID", uniqueID.appID)
        monitor.addCategoryValue("appType", OPAppTypeToString(uniqueID.appType))
    }
}
