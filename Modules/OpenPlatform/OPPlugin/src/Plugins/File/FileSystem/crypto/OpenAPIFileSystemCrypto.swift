//
//  OpenAPIFileSystemCrypto.swift
//  OPPlugin
//
//  Created by Meng on 2021/10/27.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkContainer

final class OpenAPIFileSystemCrypto: OpenBasePlugin {

    private static func decryptFile(
        params: OpenAPIFileSystemDecryptParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
    ) -> Void) {
        return FileSystem.ioQueue.async {
            let response = decryptFileSync(params: params, context: context)
            callback(response)
        }
    }

    private static func decryptFileSync(
        params: OpenAPIFileSystemDecryptParams,
        context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        return FileSystem.ioQueue.sync {
            do {
                guard let uniqueId = context.uniqueID else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve uniqueId failed")
                        .setErrno(OpenAPICommonErrno.internalError)
                    return .failure(error: error)
                }

                let src = try FileObject(rawValue: params.filePath)
                let dest = try FileObject(rawValue: params.targetFilePath)
                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: context.apiTrace, tag: "decryptFile")

                try FileSystemCompatible.decryptFile(src: src, dest: dest, context: fsContext)
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
            for: "decryptFile",
            paramsType: OpenAPIFileSystemDecryptParams.self,
            handler: Self.decryptFile
        )
    }
}
