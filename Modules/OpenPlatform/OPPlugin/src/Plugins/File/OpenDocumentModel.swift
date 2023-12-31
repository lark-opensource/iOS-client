//
//  OpenDocumentModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/13.
//

import Foundation
import LarkOpenAPIModel
import OPFoundation

final class OpenAPIOpenDocumentParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath", validChecker: {
        !$0.isEmpty
    })
    public var filePath: String

    // 去除文件类型限制，直接使用DriveSDK，避免之后新增文件类型小程序的工作，跟android逻辑同步，已和产品确认
    @OpenAPIOptionalParam(jsonKey: "fileType")
    public var fileType: String?

    @OpenAPIRequiredParam(userOptionWithJsonKey: "padFullScreen", defaultValue: false)
    public var padFullScreen: Bool

    @OpenAPIRequiredParam(userOptionWithJsonKey: "showMenu", defaultValue: true)
    public var showMenu: Bool

    public convenience init(filePath: String, fileType: String?, showMenu: Bool) throws {
        var dict: [String: Any] = ["filePath": filePath, "showMenu": showMenu]
        if let fileType = fileType {
            dict["fileType"] = fileType
        }
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath, _fileType, _showMenu, _padFullScreen]
    }
}

final class OpenAPIDocsPickerParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "maxNum", defaultValue: 10)
    public var maxNum: Int
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "pickerTitle", defaultValue: BDPI18n.doc_picker_title)
    public var pickerTitle: String
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "pickerConfirm", defaultValue: BDPI18n.doc_picker_confirm)
    public var pickerConfirm: String

    public convenience init() throws {
        let dict: [String: Any] = [:]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_maxNum, _pickerTitle, _pickerConfirm]
    }
}

final class OpenAPIDocsPickerResult: OpenAPIBaseResult {
    public let dict: [AnyHashable: Any]?

    public init(dict: [AnyHashable: Any]?) {
        self.dict = dict
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return dict ?? [:]
    }
}
