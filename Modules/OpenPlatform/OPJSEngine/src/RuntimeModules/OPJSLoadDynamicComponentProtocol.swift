//
//  OPJSRuntimeDynamicProtocol.swift
//  OPJSEngine
//
//  Created by qsc on 2023/1/17.
//

import Foundation

@objc public protocol OPJSLoadDynamicComponent: AnyObject {
    func loadPluginScript(pluginID: NSString?, version: NSString?, scriptPath: NSString?)
}
