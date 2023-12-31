//
//  OpenAPIFileSystemRemoveDirectoryParams.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemRemoveDirectoryParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "dirPath", validChecker: { !$0.isEmpty })
    var dirPath: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "recursive", defaultValue: false)
    var recursive: Bool

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_dirPath, _recursive]
    }
}
