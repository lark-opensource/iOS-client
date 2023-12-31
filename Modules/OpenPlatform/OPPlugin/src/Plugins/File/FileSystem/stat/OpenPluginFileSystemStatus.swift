//
//  OpenPluginFileSystemStatus.swift
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

final class OpenPluginFileSystemStatus: OpenBasePlugin {

    static func stat(
        params: OpenAPIFileSystemStatusParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIFileSystemStatusResult>
    ) -> Void) {
        return FileSystem.ioQueue.async {
            let response = Self.statSync(params: params, context: context)
            callback(response)
        }
    }

    static func statSync(
        params: OpenAPIFileSystemStatusParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemStatusResult> {
        return standardStatSync(params: params, context: context)
    }

    private static func standardStatSync(
        params: OpenAPIFileSystemStatusParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemStatusResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "stat")
                let file = try FileObject(rawValue: params.path)

                /// 获取文件属性
                let attributes = try FileSystem.attributesOfFile(file, context: fsContext) as NSDictionary
                let isDirectory = try FileSystem.isDirectory(file, context: fsContext)
                var mode: Int = 0
                if isDirectory {
                    mode = file.isInTempDir ? 16530 : 16676
                } else {
                    mode = file.isInTempDir ? 32914 : 33060
                }

                /// 返回结果
                let resultData = OpenAPIFileSystemStatusResult(
                    size: attributes.fileSize(),
                    mode: mode,
                    lastAccessedTime: attributes.fileCreationDate()?.timeIntervalSince1970,
                    lastModifiedTime: attributes.fileModificationDate()?.timeIntervalSince1970
                )
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
            for: "stat",
            paramsType: OpenAPIFileSystemStatusParams.self,
            resultType: OpenAPIFileSystemStatusResult.self,
            handler: Self.stat
        )

        registerSyncHandler(
            for: "statSync",
            paramsType: OpenAPIFileSystemStatusParams.self,
            resultType: OpenAPIFileSystemStatusResult.self,
            handler: Self.statSync
        )
    }
}
