//
//  OpenPluginFileSystemReadDirectory.swift
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

final class OpenPluginFileSystemReadDirectory: OpenBasePlugin {

    static func readdir(
        params: OpenAPIFileSystemReadDirectoryParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIFileSystemReadDirectoryResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = Self.readdirSync(params: params, context: context)
            callback(response)
        }
    }

    static func readdirSync(
        params: OpenAPIFileSystemReadDirectoryParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemReadDirectoryResult> {
        return standardReaddirSync(params: params, context: context)
    }

    private static func standardReaddirSync(
        params: OpenAPIFileSystemReadDirectoryParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemReadDirectoryResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "readdir")
                let file = try FileObject(rawValue: params.dirPath)

                /// 读取文件夹内容
                let contentFiles = try FileSystem.listContents(file, context: fsContext)
                let resultData = OpenAPIFileSystemReadDirectoryResult(files: contentFiles)
                return .success(data: resultData)
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
            for: "readdir",
            paramsType: OpenAPIFileSystemReadDirectoryParams.self,
            resultType: OpenAPIFileSystemReadDirectoryResult.self,
            handler: Self.readdir
        )

        registerSyncHandler(
            for: "readdirSync",
            paramsType: OpenAPIFileSystemReadDirectoryParams.self,
            resultType: OpenAPIFileSystemReadDirectoryResult.self,
            handler: Self.readdirSync
        )
    }

}
