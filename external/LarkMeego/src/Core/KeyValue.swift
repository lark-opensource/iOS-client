//
//  KeyValue.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/7/12.
//

import Foundation
import LarkStorage

extension KVStores {
    struct Meego {
        static let domain = Domain.biz.meego

        /// 构建 Meego 业务用户无关的 `KVStore`
        static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }

        /// 构建 Meego 业务用户相关的 `KVStore`
        static func user(id: String) -> KVStore {
            return KVStores.udkv(space: .user(id: id), domain: domain)
        }
    }
}

extension KVKeys {
    struct Meego {
        static let enablePay = KVKey<Bool?>("pay_enable")
    }
}
