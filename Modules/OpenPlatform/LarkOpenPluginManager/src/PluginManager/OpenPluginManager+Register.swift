//
//  OpenPluginManager+Register.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/9.
//

import Foundation
import LarkOpenAPIModel

extension OpenPluginManager {
    
    /// 无多线程保护, 需要在初始化之后调用
    public func register<Service>(
        _ serviceType: Service.Type,
        factory: @escaping (ExtensionResolver, OpenAPIContext) throws -> Service
    ) {
        extensionResolver._register(serviceType, factory: factory)
    }
}
