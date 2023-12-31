//
//  OpenPluginBase64ToTempFilePath.swift
//  OPPlugin
//
//  Created by xiangyuanyuan on 2021/11/29.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOInfra
import LarkContainer

final class OpenPluginBase64ToTempFilePath: OpenBasePlugin {
    
    func base64ToTempFilePathSync(
        params: OpenAPIBase64ToTempFilePathParams, context: OpenAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBase64ToTempFilePathResult> {
        context.apiTrace.info("base64ToTempFilePathSync start save base64 data")
        guard let uniqueID = context.uniqueID else {
            let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("resolve uniqueId failed")
                .setErrno(OpenAPICommonErrno.unknown)
            return .failure(error: errorInfo)
        }
        let data = Data(base64Encoded: params.base64Data, options: [])
        let fileExtension = TMACustomHelper.contentType(forImageData: data)
        let randomFileObj = FileObject.generateRandomTTFile(type: .temp, fileExtension: fileExtension)
        let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: nil, tag: "base64ToTempFilePath")
        guard let data = data else {
            fsContext.trace.error("write system data failed with nil data")
            let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("write base64 data failed")
                .setErrno(OpenAPICommonErrno.unknown)
            return .failure(error: errorInfo)
        }
        context.apiTrace.info("base64ToTempFilePathSync data.count:\(data.count)")
        do {
            try FileSystemCompatible.writeSystemData(data, to: randomFileObj, context: fsContext)
        } catch let error as FileSystemError {
            fsContext.trace.error("write system data failed", error: error)
            let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("write base64 data failed")
                .setErrno(OpenAPICommonErrno.unknown)
            return .failure(error: errorInfo)
        } catch {
            fsContext.trace.error("write system data failed with unknown error", error: error)
            let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("write base64 data failed with unknown error")
                .setErrno(OpenAPICommonErrno.unknown)
            return .failure(error: errorInfo)
        }
        return .success(data: OpenAPIBase64ToTempFilePathResult(tempFilePath: BDPSafeString(randomFileObj.rawValue)))
    }
    
    func base64ToTempFilePath(
        params: OpenAPIBase64ToTempFilePathParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBase64ToTempFilePathResult>) -> Void
    ) {
        DispatchQueue.global().async {
            let response = self.base64ToTempFilePathSync(params: params, context: context)
            callback(response)
        }
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceSyncHandler(
            for: "base64ToTempFilePathSync", pluginType: Self.self,
            paramsType: OpenAPIBase64ToTempFilePathParams.self,
            resultType: OpenAPIBase64ToTempFilePathResult.self
        ){ (this, params, context) in
            
            return this.base64ToTempFilePathSync(params: params, context: context)
        }
        
        registerInstanceAsyncHandler(
            for: "base64ToTempFilePath", pluginType: Self.self,
            paramsType: OpenAPIBase64ToTempFilePathParams.self,
            resultType: OpenAPIBase64ToTempFilePathResult.self
        ){ (this, params, context, callback) in
            
            this.base64ToTempFilePath(params: params, context: context, callback: callback)
        }
    }
}
