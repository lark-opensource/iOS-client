//
//  OpenAPIFileSystemAccessParams.swift
//  OPPlugin
//
//  Created by Meng on 2021/6/22.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemAccessParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "path", validChecker: { !$0.isEmpty })
    var path: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_path]
    }
}
