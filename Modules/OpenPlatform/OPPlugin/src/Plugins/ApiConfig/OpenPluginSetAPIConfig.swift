//
//  OpenPluginSetAPIConfig.swift
//  OPPlugin
//
//  Created by zhangxudong on 6/9/22.
//

import UIKit
import OPSDK
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter
import LarkContainer
/// 仅对WebApp seApiConfig
final class OpenPluginSetAPIConfig: OpenBasePlugin {

    class func setAPIConfig(params: OpenAPISetAPIConfigParams,
                      context: OpenAPIContext) -> OpenAPIBaseResponse<OpenAPIBaseResult>  {
        
        let apiConfig = params.toJSONDict()
        /// 发送 openApiWebAppDeveloperDidSetConfig 为 拦截器服务
        NotificationCenter.default.post(name: .openApiWebAppDeveloperDidSetConfig, object: nil, userInfo: apiConfig)
        context.apiTrace.info("webapp uniqueID: \(String(describing: context.uniqueID)) didSetAPIConfig: \(apiConfig)")
        return OpenAPIBaseResponse.success(data: nil)
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerSyncHandler(for: "setAPIConfig", paramsType: OpenAPISetAPIConfigParams.self, handler: Self.setAPIConfig)
    }
}
