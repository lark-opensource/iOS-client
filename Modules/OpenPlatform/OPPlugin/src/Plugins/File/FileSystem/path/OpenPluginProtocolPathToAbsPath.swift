//
//  OpenPluginProtocolPathToAbsPath.swift
//  OPPlugin
//
//  Created by xiangyuanyuan on 2021/11/30.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginProtocolPathToAbsPath: OpenBasePlugin {
    
    func protocolPathToAbsPath(
        params: OpenAPIProtocolPathToAbsPathParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIProtocolPathToAbsPathResult>) -> Void
    ) {
        let path = params.protocolPath
        context.apiTrace.info("protocolPathToAbsPath start", additionalData: ["path": path])
        callback(.success(data: OpenAPIProtocolPathToAbsPathResult(absPath: path)))
        return
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(
            for: "protocolPathToAbsPath", pluginType: Self.self,
            paramsType: OpenAPIProtocolPathToAbsPathParams.self,
            resultType: OpenAPIProtocolPathToAbsPathResult.self
        ){ (this, params, context, callback) in
            
            this.protocolPathToAbsPath(params: params, context: context, callback: callback)
        }
    }
}
