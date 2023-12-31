//
//  OpenAPIFileSystemSaveFileModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

final class OpenAPIFileSystemSaveFileParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "tempFilePath", validChecker: { !$0.isEmpty })
    var tempFilePath: String

    @OpenAPIOptionalParam(jsonKey: "filePath")
    var filePath: String?

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_tempFilePath, _filePath]
    }
}


final class OpenAPIFileSystemSaveFileResult: OpenAPIBaseResult {
    let savedFilePath: String

    init(savedFilePath: String) {
        self.savedFilePath = savedFilePath
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        return ["savedFilePath": savedFilePath]
    }
}
