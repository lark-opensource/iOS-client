//
//  CoreAssembly.swift
//  LarkCore
//
//  Created by liuwanlin on 2019/1/25.
//

import Foundation

/// Lark Release Config
public final class ReleaseConfig {
    /// 支持的语言：例如international版本只显示
    public static var supportedLanguages: [String] = {
        return Bundle.main.infoDictionary?["SUPPORTED_LANGUAGES"] as? [String] ?? []
    }()

    /// 是否显示升级：inhouse显示，internal/international不显示
    public static var isShowUpgrade: Bool = {
        return Bundle.main.infoDictionary?["SHOW_UPGRADE"] as? Bool ?? true
    }()

    /// 头条推送和打点用的channel
    public static var channelName: String = {
        return Bundle.main.infoDictionary?["CHANNEL_NAME"] as? String ?? ""
    }()

    /// 头条推送和打点用的appid
    public static var appId: String = {
        return Bundle.main.infoDictionary?["AppId"] as? String ?? ""
    }()

    /// frontier的app id
    public static var frontierAppId: String = {
        return Bundle.main.infoDictionary?["FrontierAppId"] as? String ?? ""
    }()

    /// frontier的App Key
    public static var frontierAppKey: String = {
        return Bundle.main.infoDictionary?["FrontierAppKey"] as? String ?? ""
    }()

    /// frontier的server id
    public static var frontierServerId: String = {
        return Bundle.main.infoDictionary?["FrontierServerId"] as? String ?? ""
    }()

    /// frontier的product id
    public static var frontierProductId: String = {
        return Bundle.main.infoDictionary?["FrontierProductId"] as? String ?? ""
    }()

    /// Share Extension、Keychain的group
    public static var groupId: String = {
        return Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
    }()

    /// 环境配置：Staging/Release/PreRelease/Oversea
    public static var releaseChannel: String = {
        return Bundle.main.infoDictionary?["RELEASE_CHANNEL"] as? String ?? ""
    }()

    /// 推送配置：inhouse/internal/international/KAChannel(runwork)
    public static var pushChannel: String = {
        return Bundle.main.infoDictionary?["PUSH_CHANNEL"] as? String ?? ""
    }()

    /// is key account packge
    public private(set) static var isKA: Bool = {
        return Bundle.main.infoDictionary?["IS_CUSTOMIZED_KA"] as? Bool ?? false
    }()
        
    public static let defaultUnit = Bundle.main.infoDictionary?["DEFAULT_UNIT"] as? String
    public static let defaultGeo = Bundle.main.infoDictionary?["DEFAULT_GEO"] as? String
    public static let defaultBrand = Bundle.main.infoDictionary?["DEFAULT_BRAND"] as? String

    /// 发布类型：企业签和AppStore签，只有 KA 包才有效
     public enum KAPublishType: String, CaseIterable {

         /// 企业签
         case enterprise = "Enterprise"

         /// app store
         case appstore = "App Store"
     }

     /// KA 是否是企业签
     public private(set) static var isKAEnterprise: Bool = {
         guard ReleaseConfig.isKA else { return false }
         if let string = Bundle.main.infoDictionary?["CHANNEL_NAME"] as? String {
             return KAPublishType(rawValue: string) == .enterprise
         }
         return false
     }()

    /// 部署类型
    public enum KADeployMode: String, CaseIterable {

        /// 专有部署
        case hosted = "hosted"

        /// 私有部署
        case onPremise = "on-premise"

        /// SaaS
        case saas = "saas"
    }

    /// 部署类型, 当且仅当 isKA 为 true 才有意义
    public static private(set) var kaDeployMode: KADeployMode = {
        if let string = Bundle.main.infoDictionary?["KA_DEPLOY_MODEO"] as? String {
            return KADeployMode(rawValue: string) ?? .saas
        }

        return .saas
    }()

    /// 是不是服务特化的KA
    public private(set) static var isPrivateKA: Bool = {
        kaDeployMode == .hosted || kaDeployMode == .onPremise
    }()

    /// 品牌名, 为了Passport 模块能区分品牌名：Lite、Sass、KA 等
    /// https://bytedance.feishu.cn/sheets/shtcnjuR0rJJaRueFRMWP24ha2e
    /// 详询： @quyiming @kongkaikai @wangjingling@bytedance.com
    public static var appBrandName: String = {
        return Bundle.main.infoDictionary?["APP_BRAND_NAME"] as? String ?? ""
    }()

    /// 环境配置
    public enum ReleaseChannel: String, CaseIterable {
        case release = "Release"
        case preRelease = "PreRelease"
        case staging = "Staging"
        case oversea = "Oversea"
        case overseaStaging = "OverseaStaging"
    }

    /// Package is Feishu brand
    public static var isFeishu: Bool = {
        if isKA { return (Bundle.main.infoDictionary?["BUILD_PRODUCT_TYPE"] as? String ?? "") == "KA" }
        let channel = ReleaseChannel(rawValue: releaseChannel) ?? .release
        switch channel {
        case .release, .staging, .preRelease:
            return true
        default:
            return false
        }
    }()

    /// Package is Lark brand
    public static var isLark: Bool = {
        if isKA { return (Bundle.main.infoDictionary?["BUILD_PRODUCT_TYPE"] as? String ?? "") == "KA_international" }
        let channel = ReleaseChannel(rawValue: releaseChannel) ?? .release
        switch channel {
        case .oversea, .overseaStaging:
            return true
        default:
            return false
        }
    }()

    /// is product lite
    public static var isLite: Bool = { appBrandName == .saasLite }()

    /// appId for reporting KA data, aligned data with Android and PC
    public static var appIdForAligned: String {
        switch (isKA, isBasedFeishu) {
        case (false, _): return appId
        case (true, true): return "1161"
        case (true, false): return "1664"
        }
    }

    /// KA包用于上报Slardar和Tea的channel
    public static var kaChannelForAligned: String = {
        return Bundle.main.infoDictionary?["KA_CHANNEL"] as? String ?? ""
    }()

    @inline(__always)
    /// Check environment in podfile
    private static var isBasedFeishu: Bool {
        #if IS_BASED_FEISHU
        true
        #else
        false
        #endif
    }
}

/// 品牌订制
extension String {
    static let saas: String = "saas"
    static let saasLite: String = "saas_lite"
}
