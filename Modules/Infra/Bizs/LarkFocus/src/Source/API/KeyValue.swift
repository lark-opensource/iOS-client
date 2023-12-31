//   
//  KeyValue.swift
//  LarkFocus
//
//  Created by 李昊哲 on 2022/12/27.
//  

import LarkStorage

extension KVStores {
    struct Focus {
        static let domain = Domain.biz.core.child("Focus")

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

extension KVKeys {
    struct Focus {
        // 用户无关的 key
        static let onBoarding = KVKey("focus_onboarding_4", default: false)

        // 用户相关的 key
        static let expandStatus = KVKey<Int64>("expand_status", default: 1)
    }
}
