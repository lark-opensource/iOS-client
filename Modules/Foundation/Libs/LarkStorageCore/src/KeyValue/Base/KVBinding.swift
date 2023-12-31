//
//  KVBinding.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/8.
//

import Foundation

@propertyWrapper
public struct KVBinding<OuterSelf, Value: KVValue> {

    public typealias ValueKeyPath = ReferenceWritableKeyPath<OuterSelf, Value>
    public typealias SelfKeyPath = ReferenceWritableKeyPath<OuterSelf, Self>
    public typealias StoreKeyPath = KeyPath<OuterSelf, KVStore>

    public static subscript(
        _enclosingInstance instance: OuterSelf,
        wrapped wrappedKeyPath: ValueKeyPath,
        storage storageKeyPath: SelfKeyPath
    ) -> Value {
        get {
            let wrapper = instance[keyPath: storageKeyPath]
            let key = wrapper.key
            let store = instance[keyPath: wrapper.storePath]
            return KVConfig(key: key, store: store).value
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            let key = wrapper.key
            let store = instance[keyPath: wrapper.storePath]

            var conf = KVConfig(key: key, store: store)
            conf.value = newValue
        }
    }

    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError("only works on instance properties") }
        set { fatalError("only works on instance properties, \(newValue)") }
    }

    let key: KVKey<Value>
    let storePath: StoreKeyPath

    public init(to storePath: StoreKeyPath, key: KVKey<Value>) {
        self.storePath = storePath
        self.key = key
    }

    public init(to storePath: StoreKeyPath, key: String, default defaultValue: Value) {
        self.storePath = storePath
        self.key = KVKey(key, default: defaultValue)
    }

    public init(to storePath: StoreKeyPath, key: String) where Value: KVOptional {
        self.storePath = storePath
        self.key = KVKey(key)
    }

}
