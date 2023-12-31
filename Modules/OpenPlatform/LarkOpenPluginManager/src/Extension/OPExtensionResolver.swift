//
//  OPExtensionResolver.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/7.
//

import Foundation
import LarkOpenAPIModel

final class OPExtensionResolver {
    
    // MARK: register
    
    private var _services = [ServiceKey: AnyObject]()
    
    func _register<Service, Arguments>(
        _ serviceType: Service.Type,
        factory: @escaping (Arguments) throws -> Service
    ) {
        let key = ServiceKey(serviceType: serviceType,
                             argumentsType: Arguments.self)
        let entry = ServiceEntry(serviceType: serviceType,
                                 factory: factory)
        
        _services[key] = entry
    }
}

extension OPExtensionResolver: ExtensionResolver {
    
    func resolve<Service>(
        _ serviceType: Service.Type,
        arguments context: OpenAPIContext
    ) throws -> Service {
        let resolverContext: ResolverContext<Service, (ExtensionResolver, OpenAPIContext)> = ResolverContext(
            resolver: self, arguments: {($0, context)})
        return try resolve(context: resolverContext)
    }
    
    fileprivate func resolve<Service, Arguments>(context: ResolverContext<Service, Arguments>) throws -> Service {
        let key = context.key
        guard let entry = _services[key] as? ServiceEntry<Service> else {
            let message = "cannot find entry of key: \(key) -> Service: \(Service.self)"
            throw OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage(message)
        }
        return try entry.invoke(arguments: context.arguments(context.resolver))
    }
}

// Resolve上下文
final class ResolverContext<Service, Arguments> {
    let key: ServiceKey
    let resolver: ExtensionResolver
    let arguments: (ExtensionResolver) -> Arguments

    init(resolver: ExtensionResolver, arguments: @escaping (ExtensionResolver) -> Arguments) {
        self.arguments = arguments
        self.key = ServiceKey(serviceType: Service.self, argumentsType: Arguments.self)
        self.resolver = resolver
    }
}
