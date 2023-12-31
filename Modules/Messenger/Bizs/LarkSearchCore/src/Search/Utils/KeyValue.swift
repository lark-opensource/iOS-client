//   
//  KVStore.swift
//  LarkSearchCore
//
//  Created by 李昊哲 on 2022/12/19.
//  

import LarkStorage

public extension KVStores {
    public struct Search {
        static let domain = Domain.biz.messenger.child("Search")

        public static let globalStore = KVStores.udkv(space: .global, domain: domain)
    }

    public struct SearchDebug {
        static let domain = Domain.biz.messenger.child("Search").child("Debug")

        public static let globalStore = KVStores.udkv(space: .global, domain: domain)
    }
}

public extension KVKeys {
    public struct SearchDebug {
        public static let lynxHostKey = KVKey("ASLynxHostKey", default: "")
        public static let localDebugOn = KVKey("ASLLocalDebugOn", default: false)
        public static let contextIdShow = KVKey("ASLContextIdShow", default: false)
    }
}
