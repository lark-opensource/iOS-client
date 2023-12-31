//
//  OpenPluginFileSystemGetFileInfo.swift
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

final class OpenPluginFileSystemGetFileInfo: OpenBasePlugin {

    static func getFileInfo(
        params: OpenAPIFileSystemGetFileInfoParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIFileSystemGetFileInfoResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = getFileInfoSync(params: params, context: context)
            callback(response)
        }
    }

    /// 使用 sync 方式实现，将来如果需要开放 sync 能力，直接注册即可
    private static func getFileInfoSync(
        params: OpenAPIFileSystemGetFileInfoParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemGetFileInfoResult> {
        return standardGetFileInfoSync(params: params, context: context)
    }

    private static func standardGetFileInfoSync(
        params: OpenAPIFileSystemGetFileInfoParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemGetFileInfoResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "getFileInfo")
                let file = try FileObject(rawValue: params.filePath)

                /// 获取文件大小
                let attributes = try FileSystem.attributesOfFile(file, context: fsContext) as NSDictionary
                let resultData = OpenAPIFileSystemGetFileInfoResult(size: attributes.fileSize())

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
            for: "getFileInfo",
            paramsType: OpenAPIFileSystemGetFileInfoParams.self,
            resultType: OpenAPIFileSystemGetFileInfoResult.self,
            handler: Self.getFileInfo
        )
    }

}
