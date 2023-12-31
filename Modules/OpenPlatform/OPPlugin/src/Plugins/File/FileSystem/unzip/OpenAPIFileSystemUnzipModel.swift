//
//  OpenAPIFileSystemUnzipModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemUnzipParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "zipFilePath", validChecker: { !$0.isEmpty })
    var zipFilePath: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "targetPath", validChecker: { !$0.isEmpty })
    var targetPath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_zipFilePath, _targetPath]
    }

}
