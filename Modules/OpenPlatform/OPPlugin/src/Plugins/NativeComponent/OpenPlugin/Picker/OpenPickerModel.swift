//
//  OpenPickerModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/12.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIShowPickerViewParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "frameId", defaultValue: 0)
    public var frameId: Int

    @OpenAPIOptionalParam(jsonKey: "array")
    public var array: [Any]?

    @OpenAPIOptionalParam(jsonKey: "current")
    public var current: Any?

    @OpenAPIRequiredParam(userOptionWithJsonKey: "column", defaultValue: 0)
    public var column: Int

    public convenience init(frameId: Int, array: [Any]?, current: Any?, column: Int) throws {
        var dict: [String: Any] = ["frameId": frameId, "column": column]
        if let array = array {
            dict["array"] = array
        }
        if let current = current {
            dict["current"] = current
        }
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_frameId, _array, _current, _column]
    }
}

final class OpenAPIShowPickerViewResult: OpenAPIBaseResult {
    public var current: [Int]?
    public var index: Int?

    public init(current: [Int]?, index: Int?) {
        self.current = current
        self.index = index
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        var result = [AnyHashable : Any]()
        if let current = current {
            result["current"] = current
        }
        if let index = index {
            result["index"] = index
        }
        return result
    }
}

final class OpenAPIShowDatePickerViewParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "range")
    public var range: [AnyHashable: Any]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "style", defaultValue: [AnyHashable: Any]())
    public var style: [AnyHashable: Any]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "current", defaultValue: "")
    public var current: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "fields", defaultValue: "")
    public var fields: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "mode", defaultValue: "")
    public var mode: String

    public convenience init(style: [AnyHashable: Any], range: [AnyHashable: Any], current: String, fields: String, mode: String) throws {
        let dict: [String: Any] = ["range": range, "style": style, "current": current, "fields": fields, "mode": mode]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_range, _current, _fields, _mode, _style]
    }
}

final class OpenAPIShowDatePickerViewResult: OpenAPIBaseResult {
    public var value: String

    public init(value: String) {
        self.value = value
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["value": value]
    }
}

final class OpenAPIShowRegionPickerViewParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "current", defaultValue: [])
    public var current: [String]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "customItem", defaultValue: "")
    public var customItem: String

    public convenience init(current: [String], customItem: String) throws {
        let dict: [String: Any] = ["current": current, "customItem": customItem]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_current, _customItem]
    }
}

final class OpenAPIShowRegionPickerViewResult: OpenAPIBaseResult {
    public var value: [String]
    public var code: [String]

    public init(value: [String], code: [String]) {
        self.value = value
        self.code = code
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["value": value, "code": code]
    }
}
