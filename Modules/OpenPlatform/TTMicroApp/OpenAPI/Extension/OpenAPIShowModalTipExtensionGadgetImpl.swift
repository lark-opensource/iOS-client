//
//  OpenAPIShowModalTipExtensionGadgetImpl.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/8/14.
//

import Foundation
import ECOInfra
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter

final class OpenAPIShowModalTipExtensionGadgetImpl: OpenAPIShowModalTipInfoExtension, OpenAPIExtensionApp {
    let gadgetContext: GadgetAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.gadgetContext = try getGadgetContext(context)
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func applicationName() -> String {
        if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID), let model = OPUnsafeObject(common.model) {
            return OPUnsafeObject(model.name) ?? ""
        }
        return ""
    }
}

