//
//  KVStore.swift
//  LarkCore
//
//  Created by 李晨 on 2020/10/28.
//

import LarkStorage

struct KVStore {
    private static let secretChatStore = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("SecretChat"))

    private static let secretChatNotFirstKey = KVKey("notFirst", default: false)

    @KVConfig(key: secretChatNotFirstKey, store: secretChatStore)
    static var secretChatNotFirst: Bool
}
