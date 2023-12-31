//
//  UniqueAddress.swift
//  LarkFoundation
//
//  Created by Kongkaikai on 2023/7/28.
//

import Foundation

/// > Associated objects are strongly discouraged in Swift and may be deprecated.
/// > Nonetheless, legacy code can't always be redesigned at the time of a language
/// > update. We offer some quick workarounds here.
/// >  https://github.com/atrick/swift-evolution/blob/diagnose-implicit-raw-bitwise/proposals/nnnn-implicit-raw-bitwise-conversion.md#associated-object-string-keys
@propertyWrapper
public struct UniqueAddress {
    var placeholder: Int8 = 0

    public init() {}

    public var wrappedValue: UnsafeRawPointer {
        mutating get {
            // This is "ok" only as long as the wrapped property appears
            // inside of something with a stable address (a global/static
            // variable or class property) and the pointer is never read or
            // written through, only used for its unique value
            withUnsafeBytes(of: &self) {
                return $0.baseAddress.unsafelyUnwrapped
            }
        }
    }
}
