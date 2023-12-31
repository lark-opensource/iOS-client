//
//  OpenAPIFileSystemStatusModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemStatusParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "path", validChecker: { !$0.isEmpty })
    var path: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_path]
    }
}

final class OpenAPIFileSystemStatusResult: OpenAPIBaseResult {
    let size: UInt64
    let mode: Int
    let lastAccessedTime: TimeInterval?
    let lastModifiedTime: TimeInterval?

    init(size: UInt64, mode: Int, lastAccessedTime: TimeInterval?, lastModifiedTime: TimeInterval?) {
        self.size = size
        self.mode = mode
        self.lastAccessedTime = lastAccessedTime
        self.lastModifiedTime = lastModifiedTime
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        var stat: [AnyHashable: Any] = [:]
        stat["size"] = size
        stat["mode"] = mode
        if let lastAccessedTime = lastAccessedTime {
            stat["lastAccessedTime"] = lastAccessedTime
        }
        if let lastModifiedTime = lastModifiedTime {
            stat["lastModifiedTime"] = lastModifiedTime
        }
        return ["stat": stat]
    }
}
