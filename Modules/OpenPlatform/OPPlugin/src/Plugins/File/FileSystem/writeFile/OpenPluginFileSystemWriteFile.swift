//
//  OpenPluginFileSystemWriteFile.swift
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

final class OpenPluginFileSystemWriteFile: OpenBasePlugin {

    static func writeFile(
        params: OpenAPIFileSystemWriteFileParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = writeFileSync(params: params, context: context)
            callback(response)
        }
    }

    static func writeFileSync(
        params: OpenAPIFileSystemWriteFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardWriteFileSync(params: params, context: context)
    }

    private static func standardWriteFileSync(
        params: OpenAPIFileSystemWriteFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "writeFile")
                let file = try FileObject(rawValue: params.filePath)

                /// 写入文件
                let internalSupportTemp: Bool = params.internalSupportTemp ?? false
                try FileSystem.writeFile(file, data: params.data, context: fsContext, internalSupportTemp: internalSupportTemp)
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
            for: "writeFile",
            paramsType: OpenAPIFileSystemWriteFileParams.self,
            handler: Self.writeFile
        )

        registerSyncHandler(
            for: "writeFileSync",
            paramsType: OpenAPIFileSystemWriteFileParams.self,
            handler: Self.writeFileSync
        )
    }
}
