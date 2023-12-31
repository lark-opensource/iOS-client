//
//  OpenAPICommonExtension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/10.
//

import Foundation
import ECOProbe

public protocol OpenAPICommonExtension: AnyObject {
    
    // MARK: Monitor
    
    func monitor(_ name: String) -> OPMonitor
    func monitor(_ name: String, metrics: [AnyHashable: Any]?, categories: [AnyHashable: Any]?) -> OPMonitor
    
    // MARK: Log
    
    func uniqueDescription() -> String
    
    // MARK: Controller
    
    func window() -> UIWindow?
    
    func controller() -> UIViewController?
}
