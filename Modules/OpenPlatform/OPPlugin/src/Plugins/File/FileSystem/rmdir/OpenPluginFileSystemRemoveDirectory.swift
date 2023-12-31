//
//  OpenPluginFileSystemRemoveDirectory.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import LarkContainer

final class OpenPluginFileSystemRemoveDirectory: OpenBasePlugin {

    static func rmdir(
        params: OpenAPIFileSystemRemoveDirectoryParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        return FileSystem.ioQueue.async {
            let response = Self.rmdirSync(params: params, context: context)
            callback(response)
        }
    }

    static func rmdirSync(
        params: OpenAPIFileSystemRemoveDirectoryParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardRmdirSync(params: params, context: context)
    }

    private static func standardRmdirSync(
        params: OpenAPIFileSystemRemoveDirectoryParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "rmdir")
                let file = try FileObject(rawValue: params.dirPath)

                /// 删除文件夹
                try FileSystem.removeDirectory(file, recursive: params.recursive, context: fsContext)
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
            for: "rmdir",
            paramsType: OpenAPIFileSystemRemoveDirectoryParams.self,
            handler: Self.rmdir
        )

        registerSyncHandler(
            for: "rmdirSync",
            paramsType: OpenAPIFileSystemRemoveDirectoryParams.self,
            handler: Self.rmdirSync
        )
    }

}
