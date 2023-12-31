//   
//  KeyValue.swift
//  LarkChatSetting
//
//  Created by 李昊哲 on 2022/12/22.
//  

import Foundation
import LarkStorage

extension KVStores {
    struct ChatSetting {
        static let domain = Domain.biz.messenger.child("ChatSetting")

        /// 构建用户无关的 `KVStore`
        static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }
    }
}
