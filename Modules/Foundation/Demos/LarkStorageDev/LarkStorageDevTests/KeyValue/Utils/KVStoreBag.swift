//
//  KVStoreBag.swift
//  LarkStorageDevTests
//
//  Created by 李昊哲 on 2023/4/10.
//  

import Foundation
import LarkStorage

// 遵循RAII思想，释放时清除 store
final class KVStoreBag {
    private var stores: [KVStore]

    init() {
        self.stores = []
    }

//    init(store: KVStore) {
//        self.stores = [store]
//    }
//
//    init(stores: [KVStore]) {
//        self.stores = stores
//    }
//
//    init(stores: KVStore...) {
//        self.stores = stores
//    }

    func add(_ store: KVStore) {
        self.stores.append(store)
    }

    deinit {
        stores.forEach(KVStores.clearStore(_:))
    }
}

extension KVStore {
    func disposed(_ bag: KVStoreBag) -> Self {
        bag.add(self)
        return self
    }
}

extension Optional<KVStore> {
    func disposed(_ bag: KVStoreBag) -> Self {
        if let self {
            bag.add(self)
        }
        return self
    }
}
