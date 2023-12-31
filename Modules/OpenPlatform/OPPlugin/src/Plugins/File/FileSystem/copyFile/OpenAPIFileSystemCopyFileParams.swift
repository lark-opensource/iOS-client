//
//  OpenAPIFileSystemCopyFileParams.swift
//  OPPlugin
//
//  Created by Meng on 2021/6/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel

final class OpenAPIFileSystemCopyFileParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "srcPath", validChecker: { !$0.isEmpty })
    var srcPath: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "destPath", validChecker: { !$0.isEmpty })
    var destPath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_srcPath, _destPath]
    }

}
