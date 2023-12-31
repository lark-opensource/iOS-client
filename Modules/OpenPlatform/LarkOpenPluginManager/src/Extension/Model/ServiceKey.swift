//
//  ServiceKey.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/7.
//

import Foundation

struct ServiceKey: Hashable, Equatable {
    let serviceType: Any.Type
    let argumentsType: Any.Type

    init(
        serviceType: Any.Type,
        argumentsType: Any.Type
    ) {
        self.serviceType = serviceType
        self.argumentsType = argumentsType
    }
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(serviceType).hash(into: &hasher)
        ObjectIdentifier(argumentsType).hash(into: &hasher)
    }
    
    // MARK: Equatable
    static func == (lhs: ServiceKey, rhs: ServiceKey) -> Bool {
        return lhs.serviceType == rhs.serviceType
            && lhs.argumentsType == rhs.argumentsType
    }
}
