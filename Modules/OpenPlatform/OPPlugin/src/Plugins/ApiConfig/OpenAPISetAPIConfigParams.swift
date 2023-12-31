//
//  OpenAPISetAPIConfigParams.swift
//  OPPlugin
//
//  Created by zhangxudong on 6/9/22.
//

import UIKit
import LarkOpenAPIModel
/*
 {
    "apiConfig": {
        "getLocation":{
            "version": 2 // 代表希望使用 getLocationV2的API
        },
        "chooseLocation":{
            "version": 2 // 代表希望使用 getLocationV2的API
        }
     }
*/
final class OpenAPISetAPIConfigParams: OpenAPIBaseParams {
    private struct JsonKey {
        static let apiConfig = "apiConfig"
    }
     
    public var apiConfig: [String: OpenAPISetAPIConfigItem]
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "callerID", validChecker: {
        !$0.isEmpty
    })
    var callerID: String
    
    public required init(with params: [AnyHashable: Any]) throws {
        guard let apiConfigMap = params[JsonKey.apiConfig] as? [String: [AnyHashable: Any]] else {
            OpenAPIBaseParams.logger.error("required \(JsonKey.apiConfig) missed in srouceDic with keys \(params.keys)")
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("missing parameter: \(JsonKey.apiConfig) ")
        }
        var apiConfig = [String: OpenAPISetAPIConfigItem]()
        for (key, value) in apiConfigMap {
            let item = try OpenAPISetAPIConfigItem(with: value)
            apiConfig[key] = item
        }
        self.apiConfig = apiConfig
        try super.init(with: params)
    }
   
    
    func toJSONDict() -> [AnyHashable : Any] {
        let apiConfig = apiConfig.reduce(into: [:], { reult, item in
            reult[item.key] = item.value.toJSONDict()
        })
        
        return [JsonKey.apiConfig : apiConfig,
                _callerID.jsonKey : callerID ]
    }
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_callerID]
    }
}

final class OpenAPISetAPIConfigItem: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "version")
    public var version: Int

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_version]
    }
    func toJSONDict() -> [AnyHashable : Any] {
        return [_version.jsonKey : version]
    }

}

final class OpenAPISetAPIConfigItemResult: OpenAPIBaseResult {
    public var version: Int
    public init(version: Int) {
        self.version = version
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["version": String(version)]
    }
}

final class OpenAPISetAPIConfigResult: OpenAPIBaseResult {
    
    public var apiConfig: [String: OpenAPISetAPIConfigItemResult]

    public init(apiConfig: [String: OpenAPISetAPIConfigItemResult]) {
        self.apiConfig = apiConfig
        super.init()
    }
    
    convenience init(configParams: OpenAPISetAPIConfigParams) {
        let apiConfig = configParams.apiConfig.reduce(into: [String: OpenAPISetAPIConfigItemResult](), { reult, item in
            reult[item.key] = OpenAPISetAPIConfigItemResult(version: item.value.version)
        })
        self.init(apiConfig: apiConfig)
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return apiConfig.reduce(into: [AnyHashable : Any](), { reult, item in
            reult[item.key] = item.value.toJSONDict
        })
    }
}
