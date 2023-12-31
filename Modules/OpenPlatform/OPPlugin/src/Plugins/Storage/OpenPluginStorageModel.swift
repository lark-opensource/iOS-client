//
//  OpenPluginStorageModel.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/11/30.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

// MARK: - For setStorage & setStorageSync
final class OpenPluginSetStorageParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "key", validChecker: { !$0.isEmpty })
    var key: String
    /// JSSDK 通过 dataType 处理了 data ，setStorage 时，端上获取到的 data 类型均为 string
    /// 处理类型包括：
    /// String、Array、Object、Number、Boolean、Date、Undefined、Null
    /// JSSDK 会把 undefined 转换为 “undefined” 字符串，把 null 转换为 “null”，空字符串保留为空字符串 “”。
    /// 其他预期外的类型将会把 data 当作空字符串处理
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "data",
        defaultValue: "undefined"
    )
    var data: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "dataType", validChecker: {!$0.isEmpty })
    var dataType: String

    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if let data = params["data"] as? String {
            self.data = data
            return
        }
        if let data = params["data"] as? NSNumber {
            self.data = data.stringValue
            return
        }
        self.data = ""
    }

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // data 在 required init 中处理。
        return [_key, _dataType]
    }
}


// MARK: - For getStorage & getStorageSync
final class OpenPluginGetStorageParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "key", validChecker: { !$0.isEmpty })
    var key: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_key]
    }
}
final class OpenPluginGetStorageResult: OpenAPIBaseResult {
    /// JSSDK 通过 dataType 处理了 data ，setStorage 时，端上获取到的 data 类型均为 string
    /// 处理类型包括：
    /// String、Array、Object、Number、Boolean、Date、Undefined、Null
    /// JSSDK 会把 undefined 转换为 “undefined” 字符串，把 null 转换为 “null”，空字符串保留为空字符串 “”。
    /// 其他预期外的类型将会把 data 当作空字符串处理
    /// data 从 storage 中取出，类型为 Any?  这里暂时保持现状，后续可以明确类型为 String
    var data: Any?
    var dataType: String
    init(storageDict: [String: Any]) {
        self.data = storageDict["data"]
        self.dataType = storageDict["dataType"] as? String ?? "string"
        super.init()
    }
    override func toJSONDict() -> [AnyHashable : Any] {
        return [
            "data": data,
            "dataType": dataType
        ]
    }
}





