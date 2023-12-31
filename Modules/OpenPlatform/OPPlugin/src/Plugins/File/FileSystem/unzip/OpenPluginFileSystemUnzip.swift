//
//  OpenPluginFileSystemUnzip.swift
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
import SSZipArchive
import LarkSetting
import LarkContainer

final class OpenPluginFileSystemUnzip: OpenBasePlugin {
    
    private final class UnzipDelegateObject: NSObject, OPFileSystemZipArhiveDelegate {
        // TODOZJX
        @RealTimeFeatureGatingProvider(key: "openplatform.api.unzip.ios.forbid_symblick_link") private var symbolicLinkForbidden: Bool
        
        func zipArchiveShouldUnzipFile(at fileIndex: Int, totalFiles: Int, archivePath: String, fileInfo: unz_file_info) -> Bool { // same as `SSZipArchive`内部方法`_fileIsSymbolicLink`的实现
            if (!symbolicLinkForbidden) {
                return true
            }
            
            let ZipUNIXVersion: UInt32 = 3
            let BSD_SFMT: UInt32 = 61440
            let BSD_IFLNK: UInt32 = 40960
            let isSymbolicLinkFile = fileInfo.version >> 8 == ZipUNIXVersion && (BSD_SFMT & (fileInfo.external_fa >> 16)) == BSD_IFLNK
            return !isSymbolicLinkFile
        }
    }

    static func unzip(
        params: OpenAPIFileSystemUnzipParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        FileSystem.ioQueue.async {
            let response = unzipSync(params: params, context: context)
            callback(response)
        }
    }

    /// 使用 sync 方式实现，将来如果需要开放 sync 能力，直接注册即可
    private static func unzipSync(
        params: OpenAPIFileSystemUnzipParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return standardUnzipSync(params: params, context: context)
    }

    private static func standardUnzipSync(
        params: OpenAPIFileSystemUnzipParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "unzip", isAuxiliary: true)
                let srcFile = try FileObject(rawValue: params.zipFilePath)
                let destFile = try FileObject(rawValue: params.targetPath)

                /// 解压缩文件
                try FileSystemCompatible.unzip(src: srcFile, dest: destFile, context: fsContext, delegate: UnzipDelegateObject())
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
            for: "unzip",
            paramsType: OpenAPIFileSystemUnzipParams.self,
            handler: Self.unzip
        )
    }

}
