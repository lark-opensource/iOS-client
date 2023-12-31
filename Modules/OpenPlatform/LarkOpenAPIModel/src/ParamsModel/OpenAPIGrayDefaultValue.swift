//
//  OpenAPIGrayDefaultValue.swift
//  LarkOpenAPIModel
//
//  Created by 窦坚 on 2022/2/7.
//

import Foundation

/// 参数灰度验证器
public struct OpenAPIGrayDefaultValue<T> {

    /// 灰度默认值
    public let defaultValue: T
    
    /// 灰度 featureKey
    public let featureKey: String

    private init(defaultValue: T, featureKey: String) {
        self.defaultValue = defaultValue
        self.featureKey = featureKey
    }

    public static func grayDefaultValue<T>(
        defaultValue: T,
        featureKey: String
    ) -> OpenAPIGrayDefaultValue<T> {
        return OpenAPIGrayDefaultValue<T>(defaultValue: defaultValue, featureKey: featureKey)
    }
}
