//
//  KeyValue.swift
//  LarkChat
//
//  Created by zhangwei on 2022/12/21.
//

import Foundation
import LarkStorage

extension KVStores {
    struct Chat {
        static let domain = Domain.biz.messenger.child("Chat")

        /// 构建 Chat 业务用户无关的 `KVStore`
        static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }

        /// 构建 Chat 业务用户相关的 `KVStore`
        static func user(id: String) -> KVStore {
            return KVStores.udkv(space: .user(id: id), domain: domain)
        }
    }
}

extension KVKeys {
    struct Chat {
        static let codeLineBreak = KVKey("code_detail_line_break", default: false)
    }
}
