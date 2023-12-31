//
//  OpenPluginGetWebDebugConnectionResponse.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2023/9/7.
//

import UIKit
import LarkOpenAPIModel

// MARK: - OpenPluginGetWebDebugConnectionResponse
final class OpenPluginGetWebDebugConnectionResponse: OpenAPIBaseResult {
    
    /// description: 长连接ID
    let connId: String
    
    /// description: 长连接token
    let wssToken: String
    
    /// description: 调试设备ID
    let debugDeviceId: String
    
    /// description: 长连接accessKey
    let wssAccessKey: String
    
    /// description: 长连接aid
    let wssAId: String
    
    /// description: 长连接fpid
    let wssFpId: String
    
    /// description: 长连接host
    let wssHost: String
    
    /// description: API请求域名
    let apiHost: String
    
    /// description: 长连接serviceId
    let wssServiceId: String
    
    init(connId: String, wssToken: String, debugDeviceId: String, wssAccessKey: String, wssAId: String, wssFpId: String, wssHost: String, apiHost: String, wssServiceId: String) {
        self.connId = connId
        self.wssToken = wssToken
        self.debugDeviceId = debugDeviceId
        self.wssAccessKey = wssAccessKey
        self.wssAId = wssAId
        self.wssFpId = wssFpId
        self.wssHost = wssHost
        self.apiHost = apiHost
        self.wssServiceId = wssServiceId
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        var result: [AnyHashable : Any] = [:]
        result["connId"] = connId
        result["wssToken"] = wssToken
        result["debugDeviceId"] = debugDeviceId
        result["wssAccessKey"] = wssAccessKey
        result["wssAId"] = wssAId
        result["wssFpId"] = wssFpId
        result["wssHost"] = wssHost
        result["apiHost"] = apiHost
        result["wssServiceId"] = wssServiceId
        return result
    }
    
    static func parseParamDict(connID: String, apiHost: String, wssConnInfo: [String: Any]) -> OpenPluginGetWebDebugConnectionResponse? {
        
        var reponse: OpenPluginGetWebDebugConnectionResponse? = nil
        if let wssHost = wssConnInfo[ParamKeyConst.wssHost] as? String,
           let wssToken = wssConnInfo[ParamKeyConst.wssToken] as? String,
           let debugDeviceID = wssConnInfo[ParamKeyConst.debugDeviceId] as? String,
           let wssAccessKey = wssConnInfo[ParamKeyConst.wssAccessKey] as? String,
           let wssAId = wssConnInfo[ParamKeyConst.wssAid] as? String,
           let wssFpId = wssConnInfo[ParamKeyConst.wssFpid] as? String,
           let wssServiceId = wssConnInfo[ParamKeyConst.wssServiceId] as? String
        {
            reponse = OpenPluginGetWebDebugConnectionResponse(connId: connID, wssToken: wssToken, debugDeviceId: debugDeviceID, wssAccessKey: wssAccessKey, wssAId: wssAId, wssFpId: wssFpId, wssHost: wssHost, apiHost: apiHost, wssServiceId: wssServiceId)
        }
        return reponse
    }
    
}

extension OpenPluginGetWebDebugConnectionResponse {
    
    struct ParamKeyConst {
        static let wssHost = "wss_host"
        static let wssToken = "wss_token"
        static let debugDeviceId = "debug_device_id"
        static let wssAccessKey = "wss_access_key"
        static let wssAid = "wss_aid"
        static let wssFpid = "wss_fpid"
        static let connId = "conn_id"
        static let apiHost = "api_host"
        static let wssServiceId = "wss_service_id"
    }
}
