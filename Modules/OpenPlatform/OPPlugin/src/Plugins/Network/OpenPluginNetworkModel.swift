//
//  OpenPluginNetworkModel.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/27.
//

import Foundation
import LarkOpenAPIModel

final class OpenPluginNetworkRequestParams: OpenAPIBaseParams {
    /// 选择列表中是否排除当前用户，true：排除，false：不排除
    @OpenAPIRequiredParam(userOptionWithJsonKey: "payload", defaultValue: "")
    public var payload: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_payload]
    }
}

final class OpenAPINetworkRequestResult: OpenAPIBaseResult {
    /// rust 透传的 response 数据
    public let payload: String?
    public var prefetchDetail: [String: Any]?
    public var podfile: [AnyHashable: Any]?

    /// 初始化方法
    public init(payload: String?) {
        self.payload = payload
        super.init()
    }
    
    /// 返回打包结果
    public override func toJSONDict() -> [AnyHashable : Any] {
        var result = [AnyHashable : Any]()
        if let payload = payload {
            result["payload"] = payload
        }
        if let prefetchDetail = prefetchDetail {
            result["prefetchDetail"] = prefetchDetail
        }
        if let podfile = podfile {
            result["podfile"] = podfile
        }
        return result
    }
}
