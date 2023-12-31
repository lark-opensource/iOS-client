//
//  OpenPluginFileSystemMakeDirectory.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/19.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import LarkContainer

final class OpenPluginFileSystemMakeDirectory: OpenBasePlugin {

    static func mkdir(
        params: OpenAPIFileSystemMakeDirectoryParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        return FileSystem.ioQueue.async {
            let response = Self.mkdirSync(params: params, context: context)
            callback(response)
        }
    }

    static func mkdirSync(
        params: OpenAPIFileSystemMakeDirectoryParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardMkdirSync(params: params, context: context)
    }

    private static func standardMkdirSync(
        params: OpenAPIFileSystemMakeDirectoryParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "mkdir")
                let file = try FileObject(rawValue: params.dirPath)

                /// 创建文件夹
                try FileSystem.createDirectory(file, recursive: params.recursive, context: fsContext)
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
            for: "mkdir",
            paramsType: OpenAPIFileSystemMakeDirectoryParams.self,
            handler: Self.mkdir
        )

        registerSyncHandler(
            for: "mkdirSync",
            paramsType: OpenAPIFileSystemMakeDirectoryParams.self,
            handler: Self.mkdirSync
        )
    }
}
