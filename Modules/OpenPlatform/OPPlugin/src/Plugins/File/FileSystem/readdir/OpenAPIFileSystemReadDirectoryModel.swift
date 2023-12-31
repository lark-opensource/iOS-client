//
//  OpenAPIFileSystemReadDirectoryModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemReadDirectoryParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "dirPath", validChecker: { !$0.isEmpty })
    var dirPath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_dirPath]
    }
}

final class OpenAPIFileSystemReadDirectoryResult: OpenAPIBaseResult {
    let files: [String]

    init(files: [String]) {
        self.files = files
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        return ["files": files]
    }
}
