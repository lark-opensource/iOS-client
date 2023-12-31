//
//  OpenAPIContext+Extension.swift
//  OPPluginManagerAdapter
//
//  Created by zhangxudong.999 on 2023/2/21.
//

import Foundation
import LarkOpenAPIModel
import OPFoundation

public extension OpenAPIContext {
    
    var gadgetContext: OPAPIContextProtocol? {
        get {
            return additionalInfo["gadgetContext"] as? OPAPIContextProtocol
        }
    }
    
    var controller: UIViewController? {
        get {
            return gadgetContext?.controller
        }
    }
    
    var uniqueID: OPAppUniqueID? {
        get {
            return gadgetContext?.uniqueID
        }
    }
}
