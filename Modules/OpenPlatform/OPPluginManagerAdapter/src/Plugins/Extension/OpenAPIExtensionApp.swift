//
//  OpenAPIExtensionApp.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/6/10.
//

import Foundation
import OPFoundation
import LarkOpenPluginManager

public protocol OpenAPIExtensionApp {
    var gadgetContext: GadgetAPIContext { get }
    var uniqueID: OPAppUniqueID { get }
}

public extension OpenAPIExtensionApp {
    var uniqueID: OPAppUniqueID {
        gadgetContext.uniqueID
    }
}
