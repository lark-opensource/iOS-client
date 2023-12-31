//
//  OpenFileModel.swift
//  OPPlugin
//
//  Created by yinyuan on 2021/5/21.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

final class OpenAPIFilePickerParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "maxNum", defaultValue: -1)
    public var maxNum: Int
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "isSystem", defaultValue: false)
    public var isSystem: Bool
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "pickerTitle", defaultValue: BDPI18n.littleApp_TTMicroApp_PickerTitle)
    public var pickerTitle: String
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "pickerConfirm", defaultValue: BDPI18n.littleApp_TTMicroApp_PickerConfirm)
    public var pickerConfirm: String

    public convenience init() throws {
        let dict: [String: Any] = [:]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_maxNum, _isSystem, _pickerTitle, _pickerConfirm]
    }
}

final class OpenAPIFilePickerResult: OpenAPIBaseResult {
    public let list: [[AnyHashable: Any]]

    public init(list: [[AnyHashable: Any]]) {
        self.list = list
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["list": list]
    }
}
