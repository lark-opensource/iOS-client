//
//  OpenAPIFileSystemRemoveSavedFileModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemRemoveSavedFileParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath", validChecker: { !$0.isEmpty })
    var filePath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath]
    }

}
