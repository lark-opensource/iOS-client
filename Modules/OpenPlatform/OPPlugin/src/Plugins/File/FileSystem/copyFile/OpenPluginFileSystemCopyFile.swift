//
//  OpenPluginFileSystemCopyFile.swift
//  OPPlugin
//
//  Created by Meng on 2021/6/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import ECOProbe
import LarkContainer

final class OpenPluginFileSystemCopyFile: OpenBasePlugin {

    static func copyFile(
        params: OpenAPIFileSystemCopyFileParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        FileSystem.ioQueue.async {
            let response = copyFileSync(params: params, context: context)
            callback(response)
        }
    }

    static func copyFileSync(
        params: OpenAPIFileSystemCopyFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardCopyFileSync(params: params, context: context)
    }

    static func standardCopyFileSync(
        params: OpenAPIFileSystemCopyFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "copyFile")
                let srcFile = try FileObject(rawValue: params.srcPath)
                let destFile = try FileObject(rawValue: params.destPath)

                /// 复制文件
                try FileSystem.copyFile(src: srcFile, dest: destFile, context: fsContext)
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
            for: "copyFile",
            paramsType: OpenAPIFileSystemCopyFileParams.self,
            handler: Self.copyFile
        )

        registerSyncHandler(
            for: "copyFileSync",
            paramsType: OpenAPIFileSystemCopyFileParams.self,
            handler: Self.copyFileSync
        )
    }
}
