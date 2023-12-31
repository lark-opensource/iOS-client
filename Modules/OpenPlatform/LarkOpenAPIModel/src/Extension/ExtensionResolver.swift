//
//  ExtensionResolver.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/9.
//

import Foundation

// PluginManager所持有的manager实现
public protocol ExtensionResolver: AnyObject {
    func resolve<Service>(
        _ serviceType: Service.Type,
        arguments context: OpenAPIContext
    ) throws -> Service
}