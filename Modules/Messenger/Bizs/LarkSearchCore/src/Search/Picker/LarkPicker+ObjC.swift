//
//  LarkPicker+ObjC.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/11/8.
//
// ObjC interface for LarkPicker

import Foundation
import LarkSDKInterface

// TODO: objc interface wrapper

@objc
open class LarkPickerOption: NSObject, Option {
    public var optionIdentifier: OptionIdentifier {
        OptionIdentifier(type: type, id: id)
    }

    @objc open var type: String {
        assertionFailure("should implemented in subclass")
        return "unknown"
    }
    @objc open var id: String {
        assertionFailure("should implemented in subclass")
        return ""
    }

    @objc
    public static func option(type: String, id: String) -> LarkPickerOption {
        return LarkSimplePickerOption(type: type, id: id)
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(type)
        hasher.combine(id)
        return hasher.finalize()
    }
    open override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Option {
            let other = other.optionIdentifier
            return other.type == type && other.id == id
        }
        return false
    }
    open override var description: String { "(\(type): \(id)" }
}

@objc
open class LarkSimplePickerOption: LarkPickerOption {
    let _type: String
    let _id: String
    @objc public override var type: String { _type }
    @objc public override var id: String { _id }
    @objc
    public init(type: String, id: String) {
        _type = type
        _id = id
        super.init()
    }
}

@objc
open class LarkWrapperPickerOption: LarkPickerOption {
    let base: Option
    public init(option: Option) {
        base = option
        super.init()
    }
}
