//
//  OpenPluginUserModel.swift
//  OPPlugin
//
//  Created by bytedance on 2021/4/14.
//

import Foundation
import LarkOpenAPIModel

final class OpenPluginGetUserInfoExResult: OpenAPIBaseResult {
    public let data: [String:Any]
    public init(data: [String:Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return data
    }
}

final class OpenPluginUserLoginResult: OpenAPIBaseResult {
    // FeatureGatingKey.login 全量以后要删除这些代码
    public let data: [String:Any]
    public init(data: [String:Any]) {
        self.data = data
        code = ""
        firstPartyLoginOptEnabled = nil
        
        super.init()
    }
/// FeatureGatingKey.login 使用的代码
    public let code: String
    public let firstPartyLoginOptEnabled: Bool? // 是否命中 一方应用高性能登录改造
    public init(code: String, firstPartyLoginOptEnabled: Bool?) {
        self.code = code
        self.firstPartyLoginOptEnabled = firstPartyLoginOptEnabled
        self.data = [:]
        
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        /// 多端一致性专项修改
        var result: [String: Any] = ["code" : code]
        if let firstPartyLoginOptEnabled = firstPartyLoginOptEnabled {
            result["firstPartyLoginOptEnabled"] = firstPartyLoginOptEnabled
        }
        return result
    }
}

class OpenPluginUserGetUserInfoParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "withCredentials", defaultValue: false)
    public var credentials: Bool
    public convenience init(credentials: Bool) throws {
        let dict: [String: Any] = ["withCredentials":credentials]
        try self.init(with: dict)
    }
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_credentials]
    }
}

final class OpenPluginUserGetUserInfoResult: OpenAPIBaseResult {
    public let data: [String:Any]
    public init(data: [String:Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return data
    }
}
