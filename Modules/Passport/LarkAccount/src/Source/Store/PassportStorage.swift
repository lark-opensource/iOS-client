//
//  PassportStorage.swift
//  LarkAccount
//
//  Created by au on 2023/3/21.
//

//  https://bytedance.feishu.cn/wiki/wikcnzLMSQYqmlUJlgqjI8F0k6g

import Foundation

final class PassportStorageKey<T: Codable> {

    let hashedValue: String
    let cleanValue: String

    init(key: String) {
        self.cleanValue = key
        self.hashedValue = genKey(key)
    }
}

enum PassportStorageSpace {
    case global
    case user(id: String)
}

protocol PassportStorage {
    func value<T: Codable>(forKey: PassportStorageKey<T>) -> T?
    func set<T: Codable>(_ value: T, forKey key: PassportStorageKey<T>)
    func removeValue<T: Codable>(forKey key: PassportStorageKey<T>)
}
