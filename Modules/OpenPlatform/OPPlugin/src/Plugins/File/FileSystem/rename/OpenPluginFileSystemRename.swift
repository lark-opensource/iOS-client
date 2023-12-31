//
//  OpenPluginFileSystemRename.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPFoundation
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginFileSystemRename: OpenBasePlugin {

    static func rename(
        params: OpenAPIFileSystemRenameParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = renameSync(params: params, context: context)
            callback(response)
        }
    }

    static func renameSync(
        params: OpenAPIFileSystemRenameParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardRenameSync(params: params, context: context)
    }

    private static func standardRenameSync(
        params: OpenAPIFileSystemRenameParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "rename")
                let srcFile = try FileObject(rawValue: params.oldPath)
                let destFile = try FileObject(rawValue: params.newPath)

                /// 移动文件
                try FileSystem.moveFile(src: srcFile, dest: destFile, context: fsContext)
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
            for: "rename",
            paramsType: OpenAPIFileSystemRenameParams.self,
            handler: Self.rename
        )

        registerSyncHandler(
            for: "renameSync",
            paramsType: OpenAPIFileSystemRenameParams.self,
            handler: Self.renameSync
        )
    }

}
