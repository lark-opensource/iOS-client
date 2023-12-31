//
//  ServiceKey.swift
//  SwinjectTest
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
// MARK: - ServiceKey

public struct ServiceKey {
    public let serviceType: Any.Type
    public let argumentsType: Any.Type
    public let name: String?

    init(
        serviceType: Any.Type,
        argumentsType: Any.Type,
        name: String? = nil
    ) {
        self.serviceType = serviceType
        self.argumentsType = argumentsType
        self.name = name
    }
}

// MARK: Hashable

extension ServiceKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(serviceType).hash(into: &hasher)
        ObjectIdentifier(argumentsType).hash(into: &hasher)
        name.hash(into: &hasher)
    }
}

// MARK: Equatable

public func == (lhs: ServiceKey, rhs: ServiceKey) -> Bool {
    return lhs.serviceType == rhs.serviceType
        && lhs.argumentsType == rhs.argumentsType
        && lhs.name == rhs.name
}
