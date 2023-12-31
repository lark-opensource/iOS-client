//
//  OpenAPIFeatureKey.swift
//  LarkOpenAPIModel
//
//  Created by 王飞 on 2022/3/24.
//

public enum OpenAPIFeatureKey: String {
    case getSystemInfo = "feature_key_get_system_info"
    case authorize = "feature_key_authorize"
    
    public func isEnable() -> Bool {
        OpenAPIUtils.isEnable(feature: rawValue)
    }
}
