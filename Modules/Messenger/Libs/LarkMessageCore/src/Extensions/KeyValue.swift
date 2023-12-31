//   
//  KeyValue.swift
//  LarkMessageCore
//
//  Created by 李昊哲 on 2022/12/23.
//  

import Foundation
import LarkStorage

extension KVStores {
    struct Messenger {
        static let domain = Domain.biz.messenger

        /// 构建用户无关的 `KVStore`
        static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }

        /// 构建用户相关的 `KVStore`
        static func user(id: String) -> KVStore {
            return KVStores.udkv(space: .user(id: id), domain: domain)
        }
    }
}
