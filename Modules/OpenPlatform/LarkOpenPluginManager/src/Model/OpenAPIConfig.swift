//
//  OpenAPIConfig.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation
import LarkOpenAPIModel

/// 该domain配置多端对齐，后续做成平台化
public enum OpenAPIBizDomain: String, Codable {
    case all
    case openPlatform
    case messenger
    case ccm
    case vc
    case mail
    case calendar
    case passport
    case pano
    case internalWeb
    case comment
}

public enum OpenAPIBizType: String, Codable {
    case all
    case web
    case webApp
    case gadget
    case block
    case widget
    case thirdNativeApp
    case messageCard
    case universalCard
}

public final class OpenAPIAccessConfig: NSObject, Codable {
    // 可以使用该API的业务域
    let bizDomain: OpenAPIBizDomain

    // 可以使用该API的业务场景
    let bizScene: String

    // 可以使用该API的业务形态
    public let bizType: OpenAPIBizType

    // 是否直接开放给web
    let publicToJS: Bool

    init(bizDomain: OpenAPIBizDomain, bizScene: String, bizType: OpenAPIBizType, publicToJS: Bool) {
        self.bizDomain = bizDomain
        self.bizScene = bizScene
        self.bizType = bizType
        self.publicToJS = publicToJS
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case bizDomain = "bizDomain"
        case bizScene = "bizScene"
        case bizType = "bizType"
        case publicToJS = "publicToJS"
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bizDomain = (try? container.decode(OpenAPIBizDomain.self, forKey: .bizDomain)) ?? .all
        self.bizScene = (try? container.decode(String.self, forKey: .bizScene)) ?? ""
        self.bizType = (try? container.decode(OpenAPIBizType.self, forKey: .bizType)) ?? .all
        self.publicToJS = (try? container.decode(Bool.self, forKey: .publicToJS)) ?? true
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bizDomain, forKey: .bizDomain)
        try container.encode(bizType, forKey: .bizType)
        try container.encode(publicToJS, forKey: .publicToJS)
        try container.encode(bizScene, forKey: .bizScene)
    }

}

/// APIPlugin的配置，与对应Plist文件里的kv一一对应
final class OpenAPIConfig: NSObject, Codable  {
    let apiName: String
    /// 该API的参数模型类：默认为OpenAPIBaseParams
    let pluginClass: String
    /// 实现该API的handler所在的类
    let paramsClass: String
    /// 负责该API的业务域
    let owner: OpenAPIBizDomain
    /// 该API的访问控制权限
    let conditions: [OpenAPIAccessConfig]
    /// 该API是否强制需要在主线程执行
    let excuteOnMainThread: Bool
    /// 是否是同步API
    let isSync: Bool

    public init(apiName: String,
                pluginClass: String,
                paramsClass: String,
                owner: OpenAPIBizDomain,
                excuteOnMainThread: Bool,
                isSync: Bool,
                conditions: [OpenAPIAccessConfig] = []) {
        self.apiName = apiName
        self.pluginClass = pluginClass
        self.paramsClass = paramsClass
        self.owner = owner
        self.conditions = conditions
        self.excuteOnMainThread = excuteOnMainThread
        self.isSync = isSync
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case owner = "owner"
        case apiName = "apiName"
        case pluginClass = "pluginClass"
        case paramsClass = "paramsClass"
        case conditions = "conditions"
        case isSync = "isSync"
        case excuteOnMainThread = "excuteOnMainThread"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.owner = try container.decode(OpenAPIBizDomain.self, forKey: .owner)
        self.apiName = try container.decode(String.self, forKey: .apiName)
        self.pluginClass = try container.decode(String.self, forKey: .pluginClass)
        self.excuteOnMainThread = (try? container.decode(Bool.self, forKey: .excuteOnMainThread)) ?? false
        self.paramsClass = (try? container.decode(String.self, forKey: .paramsClass)) ?? NSStringFromClass(OpenAPIBaseParams.self)
        self.isSync = (try? container.decode(Bool.self, forKey: .isSync)) ?? false
        self.conditions = (try? container.decode([OpenAPIAccessConfig].self, forKey: .conditions)) ?? []
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(owner, forKey: .owner)
        try container.encode(apiName, forKey: .apiName)
        try container.encode(pluginClass, forKey: .pluginClass)
        try container.encode(paramsClass, forKey: .paramsClass)
        try container.encode(conditions, forKey: .conditions)
        try container.encode(excuteOnMainThread, forKey: .excuteOnMainThread)
        try container.encode(isSync, forKey: .isSync)
    }
}

///
public final class OpenAPIInfo {

    let apiName: String
    /// 该API的参数模型类
    let pluginClass: String
    /// 实现该API的handler所在的类
    let paramsClass: String
    /// 该API是否强制需要在主线程执行
    public let excuteOnMainThread: Bool
    /// 是否是同步API
    public let isSync: Bool
    /// 是否直接开放给JSSDK
    let publicToJS: Bool

    public init(apiName: String,
                pluginClass: String,
                paramsClass: String,
                excuteOnMainThread: Bool,
                isSync: Bool,
                publicToJS: Bool) {
        self.apiName = apiName
        self.pluginClass = pluginClass
        self.paramsClass = paramsClass
        self.publicToJS = publicToJS
        self.excuteOnMainThread = excuteOnMainThread
        self.isSync = isSync
    }
}

extension OpenAPIAccessConfig {
    func available(for domain: OpenAPIBizDomain, type: OpenAPIBizType, scene: String) -> Bool {
        let domainAvailable = bizDomain == .all || bizDomain == domain
        let typeAvailable = bizType == .all || bizType == type
        let sceneAvailable = bizScene.isEmpty || bizScene == scene
        return domainAvailable && typeAvailable && sceneAvailable
    }

}

extension OpenAPIConfig {

    func matchedAPIInfo(for domain: OpenAPIBizDomain, type: OpenAPIBizType, scene: String) -> OpenAPIInfo? {
        // conditions为空，则为Public
        guard !conditions.isEmpty else {
            return OpenAPIInfo(apiName: apiName, pluginClass: pluginClass, paramsClass: paramsClass, excuteOnMainThread: excuteOnMainThread, isSync: isSync, publicToJS: true)
        }
        // 配置了conditions，需要看是否匹配
        let matched = conditions.filter({ $0.available(for: domain, type: type, scene: scene) })
        guard !matched.isEmpty else {
            return nil
        }
        // 有public配置，优先认为是public的
        let publicToJS = matched.first(where: { $0.publicToJS }) != nil
        return OpenAPIInfo(apiName: apiName, pluginClass: pluginClass, paramsClass: paramsClass, excuteOnMainThread: excuteOnMainThread, isSync: isSync, publicToJS: publicToJS)
    }

}
