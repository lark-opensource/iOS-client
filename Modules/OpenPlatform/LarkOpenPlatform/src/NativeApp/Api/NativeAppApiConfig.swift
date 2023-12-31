//
//  NativeAppApiConfig.swift
//  LarkOpenPluginManager
//
//  Created by bytedance on 2022/6/8.
//

import Foundation
import LarkOpenAPIModel
import NativeAppPublicKit

/// APIPlugin的配置，与对应Plist文件里的kv一一对应
final class NativeAppApiConfig: NSObject, Codable  {
    let apiName: String
    
    /// 该API的参数模型类：默认为NativeAppAPIBaseParams
    let pluginClass: String
    
    let paramsClass: String
    
    /// 该API是否强制需要在主线程执行
    let excuteOnMainThread: Bool
    
    /// 是否是同步API
    let isSync: Bool

    public init(apiName: String,
                pluginClass: String,
                paramsClass: String,
                excuteOnMainThread: Bool,
                isSync: Bool) {
        self.apiName = apiName
        self.pluginClass = pluginClass
        self.paramsClass = paramsClass
        self.excuteOnMainThread = excuteOnMainThread
        self.isSync = isSync
        super.init()
    }
    
    enum CodingKeys: String, CodingKey {
        case apiName = "apiName"
        case pluginClass = "pluginClass"
        case paramsClass = "paramsClass"
        case isSync = "isSync"
        case excuteOnMainThread = "excuteOnMainThread"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.apiName = try container.decode(String.self, forKey: .apiName)
        self.pluginClass = try container.decode(String.self, forKey: .pluginClass)
        self.paramsClass = (try? container.decode(String.self, forKey: .paramsClass)) ?? NSStringFromClass(NativeAppAPIBaseParams.self)
        self.excuteOnMainThread = (try? container.decode(Bool.self, forKey: .excuteOnMainThread)) ?? false
        self.isSync = (try? container.decode(Bool.self, forKey: .isSync)) ?? false
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(apiName, forKey: .apiName)
        try container.encode(pluginClass, forKey: .pluginClass)
        try container.encode(paramsClass, forKey: .paramsClass)
        try container.encode(excuteOnMainThread, forKey: .excuteOnMainThread)
        try container.encode(isSync, forKey: .isSync)
    }
}
