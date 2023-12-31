//
//  File.swift
//  WebBrowser
//
//  Created by xiangyuanyuan on 2021/8/23.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIConfigParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "appId", validChecker: OpenAPIValidChecker.notEmpty)
    public var appId: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "timestamp", validChecker: {
        $0 > 0
    })
    public var timestamp: Int64
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "nonceStr", validChecker: OpenAPIValidChecker.notEmpty)
    public var nonceStr: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "signature", validChecker: OpenAPIValidChecker.notEmpty)
    public var signature: String
    
    @OpenAPIOptionalParam(jsonKey: "jsApiList")
    public var jsApiList: [String]?
    
    @OpenAPIOptionalParam(jsonKey: "deviceId", validChecker: OpenAPIValidChecker.notEmpty)
    public var deviceId: String?
    
    @OpenAPIOptionalParam(jsonKey: "openId", validChecker: OpenAPIValidChecker.notEmpty)
    public var openId: String?
    
    @OpenAPIOptionalParam(jsonKey: "type")
    public var type: RequestType?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_appId, _timestamp, _nonceStr, _signature, _jsApiList, _deviceId, _openId, _type]
    }
    
    public required init(with params: [AnyHashable : Any]) throws {
        do {
            try super.init(with: params)
        } catch {
            if let initError = error as? OpenAPIError {
                throw initError.setAddtionalInfo(OpenAPIConfigError.invalidParam.errorInfo)
            } else {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setAddtionalInfo(OpenAPIConfigError.invalidParam.errorInfo)
            }
        }
    }
}

enum RequestType: String, OpenAPIEnum {
    case userAccessToken = "user_access_token"
}

final class OpenAPIConfigResult: OpenAPIBaseResult {
    // 目前该返回结果有部分数据是内部使用，在调用处拦截后处理真正返回给jssdk的数据
    public var data: [AnyHashable: Any]
    public var currentURL: URL?
    public var jsApiList: [String]
    public var appId: String
    public var apiCaller: ConfigAPICaller
    
    public init(data: [AnyHashable: Any], currentURL: URL?, jsApiList: [String], appId: String, apiCaller: ConfigAPICaller){
        self.data = data
        self.currentURL = currentURL
        self.jsApiList = jsApiList
        self.appId = appId
        self.apiCaller = apiCaller
    }
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        var result: [String: Any] = ["data": data, "appId": appId, "jsApiList": jsApiList, "apiCaller": apiCaller]
        if let url = currentURL {
            result["currentURL"] = url
        }
        return result
    }
}
