//
//  OpenAPIFileSystemRenameModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemRenameParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "oldPath", validChecker: { !$0.isEmpty })
    var oldPath: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "newPath", validChecker: { !$0.isEmpty })
    var newPath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_oldPath, _newPath]
    }

}
