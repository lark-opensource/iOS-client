//
//  OpenAPIFileSystemWriteFileModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenAPIModel
import ECOInfra
import OPPluginManagerAdapter

final class OpenAPIFileSystemWriteFileParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath", validChecker: { !$0.isEmpty })
    var filePath: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "data")
    var data: Data

    @OpenAPIOptionalParam(jsonKey: "encoding")
    var encoding: FileSystemEncoding?
    
    @OpenAPIOptionalParam(jsonKey: "internalSupportTemp")
    var internalSupportTemp: Bool?

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath, _internalSupportTemp]
    }

    required init(with params: [AnyHashable : Any]) throws {
        try super.init(with: params)
        
        if let encodingStr = params["encoding"] as? String {
            if let encoding = FileSystemEncoding(rawValue: encodingStr) {
             self.encoding = encoding
            } else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("parameter value invalid: encoding")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "encoding")))
            }
        }
        
        guard let dataOriginValue = params["data"] else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("missing parameter: data")
            .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "data")))
        }

        /// data 为 string 时，encoding 默认值为 utf8
        if let dataString = dataOriginValue as? String {//String 类型data
            guard let stringByteData = FileSystemUtils.decodeFileDataString(dataString, encoding: encoding ?? .utf8) else{
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("parameter value invalid: data")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "data")))
            }
            self.data = stringByteData
        } else if let dataValue = dataOriginValue as? Data {//arrayBuffer 类型data
            self.data = dataValue
        } else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("parameter value invalid: data")
            .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: "data")))
        }
        
    }
}
