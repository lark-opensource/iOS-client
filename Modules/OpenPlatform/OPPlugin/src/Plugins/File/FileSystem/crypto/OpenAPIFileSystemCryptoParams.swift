//
//  OpenAPIFileSystemCryptoParams.swift
//  OPPlugin
//
//  Created by Meng on 2021/10/27.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemDecryptParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(
        userRequiredWithJsonKey: "filePath",
        validChecker: { !$0.isEmpty }
    )
    var filePath: String

    @OpenAPIRequiredParam(
        userRequiredWithJsonKey: "targetFilePath",
        validChecker: { !$0.isEmpty }
    )
    var targetFilePath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath, _targetFilePath]
    }

}
