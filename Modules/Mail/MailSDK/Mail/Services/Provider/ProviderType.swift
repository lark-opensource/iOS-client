//
//  ProviderType.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/7/14.
//

import Foundation

@propertyWrapper
public struct MailProvider<Value> {

    private let intialBlock: () -> Value?
    private var _wrappedValue: Value?
    public var wrappedValue: Value? {
        mutating get {
            if let value = _wrappedValue {
                return value
            } else {
                _wrappedValue = intialBlock()
                return _wrappedValue
            }
        }
    }

    public init() {
        self.intialBlock = {
            ProviderManager.default.lazyLoadProvider(type: Value.self)
        }
    }

    mutating func clean() {
        _wrappedValue = nil
    }
}
