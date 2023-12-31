//
//  OpenPluginFileSystemAppendFile.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/8/1.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPFoundation
import OPSDK
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginFileSystemAppendFile: OpenBasePlugin {

    static func appendFile(
        params: OpenPluginFileSystemManagerAppendFileRequest,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = appendFileSync(params: params, context: context)
            callback(response)
        }
    }

    static func appendFileSync(
        params: OpenPluginFileSystemManagerAppendFileRequest, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardAppendFileSync(params: params, context: context)
    }

    private static func standardAppendFileSync(
        params: OpenPluginFileSystemManagerAppendFileRequest, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                context.apiTrace.info("appendFile API call start")
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                    return .failure(error: error)
                }
                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "appendFile")
                let file = try FileObject(rawValue: params.filePath)
                
                if let dataString = params.data as? String {//String 类型data
                    guard let encoding = FileSystemEncoding(rawValue: params.encoding) else{
                        let error = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.invalidParam(param: "encoding")))
                            .setMonitorMessage("parameter value invalid encoding:\(params.encoding)")
                        return .failure(error: error)
                    }
                    guard let stringByteData = FileSystemUtils.decodeFileDataString(dataString, encoding: encoding) else{
                        let error = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.invalidParam(param: "data")))
                            .setMonitorMessage("parameter value invalid: data")
                        return .failure(error: error)
                    }
                    try FileSystem.appendFile(file, data: stringByteData, context: fsContext)
                } else if let arrayBufferByteData = params.data as? Data {//arrayBuffer 类型data
                    try FileSystem.appendFile(file, data: arrayBufferByteData, context: fsContext)
                } else {
                    let error = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.paramWrongType(param: "data")))
                        .setMonitorMessage("parameter value invalid: data")
                    return .failure(error: error)
                }
                context.apiTrace.info("appendFile API call end")
                return .success(data: nil)
            } catch let error as FileSystemError {
                return .failure(error: error.newOpenAPIError)
            } catch {
                return .failure(error: error.newFileSystemUnknownError)
            }
        }
    }


    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAsyncHandler(
            for: "appendFile",
            paramsType: OpenPluginFileSystemManagerAppendFileRequest.self,
            handler: Self.appendFile
        )

        registerSyncHandler(
            for: "appendFileSync",
            paramsType: OpenPluginFileSystemManagerAppendFileRequest.self,
            handler: Self.appendFileSync
        )
    }
}
