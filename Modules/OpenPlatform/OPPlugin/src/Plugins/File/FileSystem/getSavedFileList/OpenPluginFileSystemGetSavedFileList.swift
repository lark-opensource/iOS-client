//
//  OpenPluginFileSystemGetSavedFileList.swift
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

final class OpenPluginFileSystemGetSavedFileList: OpenBasePlugin {

    typealias FileItem = OpenAPIFileSystemGetSavedFileListResult.FileItem

    static func getSavedFileList(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIFileSystemGetSavedFileListResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = getSavedFileListSync(params: params, context: context)
            callback(response)
        }
    }

    /// 使用 sync 方式实现，将来如果需要开放 sync 能力，直接注册即可
    private static func getSavedFileListSync(
        params: OpenAPIBaseParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemGetSavedFileListResult> {
        return standardGetSavedFileListSync(params: params, context: context)
    }

    private static func standardGetSavedFileListSync(
        params: OpenAPIBaseParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemGetSavedFileListResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "getSavedFileList")
                let userFile = FileObject.user

                /// 获取子路径
                let fileNames = try FileSystem.listContents(userFile, context: fsContext)

                /// 转换子路径信息
                let fileList: [FileItem] = fileNames.compactMap { subName in
                    let file = userFile.appendingPathComponent(subName)
                    var attributeDict: NSDictionary?
                    do {
                        attributeDict = try FileSystem.attributesOfFile(file, context: fsContext) as NSDictionary
                    } catch {
                        /// 如果单个属性读取失败，也正常返回，只是缺失对应的读取字段即可，不整体报错
                        context.apiTrace.error("get file attributes failed", additionalData: [
                            "file": file.rawValue
                        ], error: error)
                    }
                    return FileItem(
                        filePath: file.rawValue,
                        size: attributeDict?.fileSize(),
                        createTime: attributeDict?.fileCreationDate()?.timeIntervalSince1970
                    )
                }

                /// 返回结果
                let resultData = OpenAPIFileSystemGetSavedFileListResult(fileList: fileList)
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
            for: "getSavedFileList",
            resultType: OpenAPIFileSystemGetSavedFileListResult.self,
            handler: Self.getSavedFileList
        )
    }

}
