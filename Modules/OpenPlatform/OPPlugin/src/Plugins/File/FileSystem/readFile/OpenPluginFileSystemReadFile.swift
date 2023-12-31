//
//  OpenPluginFileSystemReadFile.swift
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

final class OpenPluginFileSystemReadFile: OpenBasePlugin {

//    static let overReadThreshold: Int64 = 1024 * 1024 * 10 // 10MB

    static func readFile(
        params: OpenAPIFileSystemReadFileParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIFileSystemReadFileResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = readFileSync(params: params, context: context)
            callback(response)
        }
    }

    static func readFileSync(
        params: OpenAPIFileSystemReadFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemReadFileResult> {
        return standardReadFileSync(params: params, context: context)
    }

    private static func standardReadFileSync(
        params: OpenAPIFileSystemReadFileParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIFileSystemReadFileResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "readFile")
                let file = try FileObject(rawValue: params.filePath)

                /// 读取文件数据
                let readSizeThreshold = FileSystemUtils.readSizeThreshold(uniqueId: fsContext.uniqueId)
                context.apiTrace.info("readSizeThreshold :\(readSizeThreshold)")
                let data = try FileSystem.readFile(
                    file,
                    position: params.position,
                    length: params.length,
                    threshold: readSizeThreshold,
                    context: fsContext
                )
                context.apiTrace.info("readFile data.count :\(data.count)")
                /// 转换文件数据
                var dataString: String? = nil
                if let encoding = params.encoding {
                    dataString = FileSystemUtils.encodeFileData(data, encoding: encoding)
                    
                    /// 编码失败返回错误，提示 encoding 参数错误
                    if dataString == nil {
                        let status = FSCrypto.checkEncryptStatus(forData: data)
                        context.apiTrace.error("file encryptStatus:\(status)")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                            .setMonitorMessage("encode file failed, encoding \(encoding)")
                            .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "encoding")))
                        return .failure(error: error)
                    }
                }

                /// 返回结果
                let resultData = OpenAPIFileSystemReadFileResult(data: data, dataString: dataString)

                /// 检查结果是否能正常传递给 JSSDK
                let jsonDict = resultData.toJSONDict() as NSDictionary
                guard let encodeJSONDict = jsonDict.encodeNativeBuffersIfNeed(), /* 处理 data 类型的 nativeBuffer 编码 */
                      JSONSerialization.isValidJSONObject(encodeJSONDict) else {
                    /// 无法解析 json 返回错误，提示 encoding 参数错误
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                        .setMonitorMessage("valid result json data failed, encoding: \(params.encoding?.rawValue ?? "")")
                        .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "encoding")))
                    return .failure(error: error)
                }

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
            for: "readFile",
            paramsType: OpenAPIFileSystemReadFileParams.self,
            resultType: OpenAPIFileSystemReadFileResult.self,
            handler: Self.readFile
        )

        registerSyncHandler(
            for: "readFileSync",
            paramsType: OpenAPIFileSystemReadFileParams.self,
            resultType: OpenAPIFileSystemReadFileResult.self,
            handler: Self.readFileSync
        )
    }
}
