//
//  KVConfig.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/1.
//

import Foundation

@propertyWrapper
public struct KVConfig<Value: KVValue> {

    public var value: Value {
        get { wrappedValue }
        set { wrappedValue = newValue }
    }

    public var wrappedValue: Value {
        get {
            let store = self.store.callee()

            if let v: Value.StoreType = store.value(forKey: key.raw) {
                return Value.fromStore(v)
            } else {
                return key.defalut.callee()
            }
        }
        set {
            if let opt = newValue as? KVOptional, opt.isNil {
                store.callee().removeValue(forKey: key.raw)
            } else if let v = newValue.storeWrapped {
                store.callee().set(v, forKey: key.raw)
            } else {
                KVStores.assertionFailure()
            }
        }
    }

    let key: KVKey<Value>
    let store: KVClosure<KVStore>

    public init(key: KVKey<Value>, store: KVClosure<KVStore>) {
        self.key = key
        self.store = store
    }

    public init(key: KVKey<Value>, store: KVStore) {
        self.init(key: key, store: .static(store))
    }

    public init(key: String, default defaultValue: KVClosure<Value>, store: KVClosure<KVStore>) {
        self.init(key: KVKey(key, default: defaultValue), store: store)
    }

    public init(key: String, default defaultValue: KVClosure<Value>, store: KVStore) {
        self.init(key: key, default: defaultValue, store: .static(store))
    }

    public init(key: String, default defaultValue: Value, store: KVClosure<KVStore>) {
        self.init(key: key, default: .static(defaultValue), store: store)
    }

    public init(key: String, default defaultValue: Value, store: KVStore) {
        self.init(key: key, default: .static(defaultValue), store: .static(store))
    }

    public init(key: String, store: KVClosure<KVStore>) where Value: KVOptional {
        self.init(key: key, default: .static(Value.nilValue), store: store)
    }

    public init(key: String, store: KVStore) where Value: KVOptional {
        self.init(key: key, default: .static(Value.nilValue), store: .static(store))
    }

}

public struct KVConfigs {}
