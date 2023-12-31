//
//  OpenAPIFileSystemUnlinkModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemUnlinkParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath", validChecker: { !$0.isEmpty })
    var filePath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath]
    }

}
