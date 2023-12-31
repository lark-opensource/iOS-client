//
//  ServiceEntry.swift
//  Swinject
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import LarkOpenAPIModel

typealias FunctionType = Any

final class ServiceEntry<Service> {
    let factory: FunctionType

    init(serviceType: Service.Type,
         factory: FunctionType) {
        self.factory = factory
    }
    
    func invoke<Arguments>(arguments: Arguments) throws -> Service {
        guard let factory = factory as? ((Arguments) throws -> Service) else {
            let message = "factory should match \(Arguments.self) -> \(Service.self)"
            #if DEBUG || ALPHA
            fatalError(message)
            #endif
            throw OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage(message)
        }
        return try factory(arguments)
    }
}
