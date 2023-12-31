//
//  ProviderKey.swift
//  Action
//
//  Created by tefeng liu on 2019/6/24.
//

import Foundation

// MARK: - ServiceKey
internal struct ProviderKey {
    internal let serviceType: Any.Type
    internal let name: String?

    internal init(
        serviceType: Any.Type,
        name: String? = nil
        ) {
        self.serviceType = serviceType
        self.name = name
    }
}

// MARK: Hashable
extension ProviderKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(serviceType))
        hasher.combine(name?.hashValue ?? 0)
    }
}

// MARK: Equatable
func == (lhs: ProviderKey, rhs: ProviderKey) -> Bool {
    return lhs.serviceType == rhs.serviceType
        && lhs.name == rhs.name
}
