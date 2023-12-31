//
//  OpenPluginFileSystemRemoveSavedFile.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPFoundation
import OPSDK
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginFileSystemRemoveSavedFile: OpenBasePlugin {

    static func removeSavedFile(
        params: OpenAPIFileSystemRemoveSavedFileParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = removeSavedFileSync(params: params, context: context)
            callback(response)
        }
    }

    /// 使用 sync 方式实现，将来如果需要开放 sync 能力，直接注册即可
    private static func removeSavedFileSync(
        params: OpenAPIFileSystemRemoveSavedFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardRemoveSavedFileSync(params: params, context: context)
    }

    private static func standardRemoveSavedFileSync(
        params: OpenAPIFileSystemRemoveSavedFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "removeSavedFile")
                let file = try FileObject(rawValue: params.filePath)

                /// 删除文件
                try FileSystem.removeFile(file, context: fsContext)
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
            for: "removeSavedFile",
            paramsType: OpenAPIFileSystemRemoveSavedFileParams.self,
            handler: Self.removeSavedFile
        )
    }

}
