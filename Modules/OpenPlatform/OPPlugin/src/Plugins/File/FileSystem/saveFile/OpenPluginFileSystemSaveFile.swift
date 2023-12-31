//
//  OpenPluginFileSystemSaveFile.swift
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

final class OpenPluginFileSystemSaveFile: OpenBasePlugin {

    static func saveFile(
        params: OpenAPIFileSystemSaveFileParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIFileSystemSaveFileResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = saveFileSync(params: params, context: context)
            callback(response)
        }
    }

    static func saveFileSync(
        params: OpenAPIFileSystemSaveFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemSaveFileResult> {
        return standardSaveFileSync(params: params, context: context)
    }

    private static func standardSaveFileSync(
        params: OpenAPIFileSystemSaveFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemSaveFileResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "saveFile")
                let tempFile = try FileObject(rawValue: params.tempFilePath)

                /// 如果目标文件不存在则生成随机路径
                var targetFile: FileObject
                if let filePath = params.filePath {
                    targetFile = try FileObject(rawValue: filePath)
                } else {
                    let pathExtension = (params.tempFilePath as NSString).pathExtension
                    targetFile = FileObject.generateRandomTTFile(type: .user, fileExtension: pathExtension)
                }
                /// 源文件是否在 temp 目录
                let tempPrefix = "\(BDP_TTFILE_SCHEME)://\(APP_TEMP_DIR_NAME)"
                guard tempFile.rawValue.hasPrefix(tempPrefix) else {
                    return .failure(error: OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "tempFilePath"))))
                }

                /// 检查源文件是否是文件
                guard try !FileSystem.isDirectory(tempFile, context: fsContext) else {
                    return .failure(error: OpenAPIError(code: OpenAPIFileSystemErrorCode.fileIsNotRegularFile).setErrno(OpenAPICommonErrno.fileIsNotRegularFile(filePath: tempFile.rawValue)))
                }

                /// 移动文件
                try FileSystem.moveFile(src: tempFile, dest: targetFile, context: fsContext)
                let resultData = OpenAPIFileSystemSaveFileResult(savedFilePath: targetFile.rawValue)
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
            for: "saveFile",
            paramsType: OpenAPIFileSystemSaveFileParams.self,
            resultType: OpenAPIFileSystemSaveFileResult.self,
            handler: Self.saveFile
        )

        registerSyncHandler(
            for: "saveFileSync",
            paramsType: OpenAPIFileSystemSaveFileParams.self,
            resultType: OpenAPIFileSystemSaveFileResult.self,
            handler: Self.saveFileSync
        )
    }

}
