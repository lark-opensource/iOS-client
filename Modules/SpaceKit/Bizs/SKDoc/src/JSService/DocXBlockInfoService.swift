//
//  DocXBlockInfoService.swift
//  SKDoc
//
//  Created by liujinwei on 2023/8/1.
//  


import SKBrowser
import SKCommon
import SKFoundation
import LarkWebViewContainer
import SKInfra

final class DocXBlockInfoService: BaseJSService {
    

}

extension DocXBlockInfoService: JSServiceHandler {
    
    var handleServices: [DocsJSService] {
        [.blockInfo]
    }
    
    func handle(params: [String : Any], serviceName: String) {
        guard let token = params["token"] as? String,
              let type = params["type"] as? Int,
              let tenantId = params["creatorTenantId"] as? String else {
            DocsLogger.error("blockInfo error")
            return
        }
        hostDocsInfo?.syncBlocksConfig.updateInfo(token, type, tenantId)
        WatermarkManager.shared.requestWatermarkInfo(WatermarkKey(objToken: token, type: type))
    }
    
}
