//
//  OpenAPIFileSystemReadFileModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

final class OpenAPIFileSystemReadFileParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath", validChecker: { !$0.isEmpty })
    var filePath: String

    @OpenAPIOptionalParam(jsonKey: "encoding")
    var encoding: FileSystemEncoding?

    @OpenAPIOptionalParam(jsonKey: "position")
    var position: Int64?

    @OpenAPIOptionalParam(jsonKey: "length")
    var length: Int64?

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath, _position, _length]
    }

    required init(with params: [AnyHashable : Any]) throws {
        try super.init(with: params)

        if let encodingStr = params["encoding"] as? String, !encodingStr.isEmpty {
            if let encoding = FileSystemEncoding(rawValue: encodingStr) {
                self.encoding = encoding
            } else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("parameter value invalid: encoding")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "encoding")))
            }
        }
    }

}

final class OpenAPIFileSystemReadFileResult: OpenAPIBaseResult {

    let data: Data
    let dataString: String?

    init(data: Data, dataString: String?) {
        self.data = data
        self.dataString = dataString
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        return ["data": dataString ?? data]
    }
}
