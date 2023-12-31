//
//  DomainStorage.swift
//  LarkExtensionServices
//
//  Created by ByteDance on 2023/11/6.
//

import Foundation
import LarkStorageCore

public struct UserDomainStorage {
    private static let userDomainKeyPrefix = "user_domain_"
    let store: KVStore
    let userID: String
    let userDomainKey: KVKey<[String: [String]]?>

    public init(userID: String) {
        self.userID = userID
        self.store = KVStores.Extension.userShared(id: userID)
        self.userDomainKey = KVKey<[String: [String]]?>(Self.userDomainKeyPrefix + self.userID)
    }

    public func saveUserDomain(domains: [String: [String]]) {
        store[userDomainKey] = domains
    }

    public func getUserDomain() -> [String: [String]]? {
        return store[userDomainKey]
    }
}
