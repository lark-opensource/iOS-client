//
//  ProxyPropertyWrapper.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/15.
//

import Foundation

@propertyWrapper
public struct Proxy<Value, EnclosingSelf> {
    private let keyPath: KeyPath<EnclosingSelf, Value>

    public init(_ keyPath: KeyPath<EnclosingSelf, Value>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: Value {
        get { fatalError("Should not implement.") }
        set { fatalError("Should not implement.\(newValue)") }
    }

    public static subscript(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            let storageValue = observed[keyPath: storageKeyPath]
            let value = observed[keyPath: storageValue.keyPath]
            return value
        }
        set {
            let storageValue = observed[keyPath: storageKeyPath]
            if let keypath = storageValue.keyPath as? ReferenceWritableKeyPath<EnclosingSelf, Value> {
                observed[keyPath: keypath] = newValue
            }
        }
    }

}
