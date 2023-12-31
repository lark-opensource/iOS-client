//
//  OpenAPIFileSystemGetFileInfoModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemGetFileInfoParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath", validChecker: { !$0.isEmpty })
    var filePath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath]
    }

}

final class OpenAPIFileSystemGetFileInfoResult: OpenAPIBaseResult {
    let size: UInt64

    init(size: UInt64) {
        self.size = size
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        return ["size": size]
    }
}
