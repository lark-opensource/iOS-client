//
//  OpenPluginFileSystemAccess.swift
//  OPPlugin
//
//  Created by Meng on 2021/6/22.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import ECOProbe
import LarkContainer

final class OpenPluginFileSystemAccess: OpenBasePlugin {

    static func access(
        params: OpenAPIFileSystemAccessParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = accessSync(params: params, context: context)
            callback(response)
        }
    }

    static func accessSync(
        params: OpenAPIFileSystemAccessParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardAccessSync(params: params, context: context)
    }

    private static func standardAccessSync(
        params: OpenAPIFileSystemAccessParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let file = try FileObject(rawValue: params.path)
                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "access")

                /// 判断是否存在
                guard try FileSystem.fileExist(file, context: fsContext) else {
                    let apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.fileNotExists)
                        .setOuterMessage(OpenAPIFileSystemErrorCode.fileNotExists.errMsg + ": \(params.path)")
                        .setErrno(OpenAPICommonErrno.fileNotExists(filePath: file.rawValue))
                    return .failure(error: apiError)
                }

                return .success(data: nil)
            } catch let error as FileSystemError {
                return .failure(error: error.openAPIError)
            } catch {
                return .failure(error: error.fileSystemUnknownError)
            }
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)

        registerAsyncHandler(
            for: "access",
            paramsType: OpenAPIFileSystemAccessParams.self,
            handler: Self.access
        )

        registerSyncHandler(
            for: "accessSync",
            paramsType: OpenAPIFileSystemAccessParams.self,
            handler: Self.accessSync
        )
    }
}
