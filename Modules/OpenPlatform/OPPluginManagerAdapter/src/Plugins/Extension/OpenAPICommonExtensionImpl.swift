//
//  OpenAPICommonExtensionImpl.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/6/10.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel

public final class OpenAPICommonExtensionAppImpl: OpenAPIExtensionApp, OpenAPICommonExtension {
    public let gadgetContext: GadgetAPIContext
    
    public init(gadgetContext: GadgetAPIContext) {
        self.gadgetContext = gadgetContext
    }
    
    public func monitor(_ name: String) -> OPMonitor {
        OPMonitor(name).setUniqueID(uniqueID)
    }
    
    public func monitor(_ name: String, metrics: [AnyHashable: Any]?, categories: [AnyHashable: Any]?) -> OPMonitor {
        OPMonitor(name: name, metrics: metrics, categories: categories).setUniqueID(uniqueID)
    }
    
    public func uniqueDescription() -> String {
        uniqueID.description
    }
    
    public func controller() -> UIViewController? {
        gadgetContext.controller
    }
    
    // 综合adapter和gadgetContext逻辑得到
    public func window() -> UIWindow? {
        let window = self.controller()?.view.window ?? uniqueID.window
        return window
    }
}
