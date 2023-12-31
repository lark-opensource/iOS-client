//
//  OpenPluginFileSystemUnlink.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPFoundation
import OPSDK
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginFileSystemUnlink: OpenBasePlugin {

    static func unlink(
        params: OpenAPIFileSystemUnlinkParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = unlinkSync(params: params, context: context)
            callback(response)
        }
    }

    static func unlinkSync(
        params: OpenAPIFileSystemUnlinkParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
            return standardUnlinkSync(params: params, context: context)
    }

    private static func standardUnlinkSync(
        params: OpenAPIFileSystemUnlinkParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "unlink")
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
            for: "unlink",
            paramsType: OpenAPIFileSystemUnlinkParams.self,
            handler: Self.unlink
        )

        registerSyncHandler(
            for: "unlinkSync",
            paramsType: OpenAPIFileSystemUnlinkParams.self,
            handler: Self.unlinkSync
        )
    }
}
