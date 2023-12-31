//
//  UserContainerExt.swift
//  LarkStorage
//
//  Created by 7Up on 2023/4/14.
//

import Foundation
import LarkContainer

extension UserResolver {
    public func mmkv(domain: DomainType, mode: MMKVStoreMode = .normal) -> KVStore {
        return KVStores.mmkv(space: .user(id: userID), domain: domain, mode: mode)
    }

    public func udkv(domain: DomainType, mode: UDKVStoreMode = .normal) -> KVStore {
        return KVStores.udkv(space: .user(id: userID), domain: domain, mode: mode)
    }

    public func isoPath(in domain: DomainType, type: RootPathType.Normal) -> IsoPath {
        return .in(space: .user(id: userID), domain: domain).build(type)
    }
}

extension UserResolverWrapper {
    public func mmkv(domain: DomainType, mode: MMKVStoreMode = .normal) -> KVStore {
        return userResolver.mmkv(domain: domain, mode: mode)
    }

    public func udkv(domain: DomainType, mode: UDKVStoreMode = .normal) -> KVStore {
        return userResolver.udkv(domain: domain, mode: mode)
    }

    public func isoPath(in domain: DomainType, type: RootPathType.Normal) -> IsoPath {
        return userResolver.isoPath(in: domain, type: type)
    }
}
