//
//  WebContainerSetting.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/20.
//

import Foundation
import LarkSetting

//MARK: 一方容器 小程序拦截配置
public struct WebContainerConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "web_container_config")
    
    public let webAppConfig: [String: WebAppConfig]
    
    enum CodingKeys: String, CodingKey {
        case webAppConfig
    }
}

public struct WebAppConfig: Codable {
    public let appID: String
    public let appName: String
    public let fgKey: String
    public let router: WebContainerRouter
    public let resConfig: WAResourcePackageConfig?
    public let resInterceptConfig: WAResourceInterceptConfig?
    public let preloadConfig: WAProloadConfig?
    public let openConfig: WAOpenConfig?
    public let webviewConfig: WAWebViewConfig?
    
    enum CodingKeys: String, CodingKey {
        case appID
        case appName
        case fgKey
        case router
        case resConfig
        case resInterceptConfig
        case preloadConfig
        case openConfig
        case webviewConfig
    }
    
    public static let `default` = WebAppConfig(appID: "000",
                                               appName: "default",
                                               fgKey: "",
                                               router: WebContainerRouter(hostConfig: .default,
                                                                          microAppInterceptConfig: [:],
                                                                          urlInterceptPaths: [],
                                                                          urlInterceptBlackListSchemes: []),
                                               resConfig: nil,
                                               resInterceptConfig: nil,
                                               preloadConfig: nil, openConfig: nil, webviewConfig: nil)
}


/// 应用路由配置
public struct WebContainerRouter: Codable {
    public let hostConfig: WAHostConfig
    public let microAppInterceptConfig: [String: MicroAppInterceptConfig]
    public let urlInterceptPaths: [String]                                     //白名单
    public let urlInterceptBlackListSchemes: [String]                          //黑名单
    
    enum CodingKeys: String, CodingKey {
        case hostConfig
        case microAppInterceptConfig
        case urlInterceptPaths
        case urlInterceptBlackListSchemes
    }
}

public struct WAHostConfig: Codable {
    public let hostType: String
    public let bizDomainAlias: String?
    public let constHosts: [String]?
    
    enum CodingKeys: String, CodingKey {
        case hostType
        case bizDomainAlias
        case constHosts
    }
    
    public static let `default` = WAHostConfig(hostType: "", bizDomainAlias: nil, constHosts: [])
}


/// 小程序路由拦截配置
public struct MicroAppInterceptConfig: Codable {
    public let urlPath: String
    public let urlQuery: MicroAppInterceptUrlQuery
    public let urlSchema: [String]?
    
    public var queryType: QueryType? {
        QueryType(rawValue: urlQuery.type)
    }
    
    enum CodingKeys: String, CodingKey {
        case urlPath
        case urlQuery
        case urlSchema
    }
    
    public enum QueryType: String {
        case append         //path后的字段都要
        case parameter      //只要Path后的query字段
    }
}

public struct MicroAppInterceptUrlQuery: Codable {
    public let type: String
    public let queryKey: [String]
    
    enum CodingKeys: String, CodingKey {
        case type
        case queryKey
    }
}

public struct WAProloadConfig: Codable {
    public enum PreloadPolicy: Int, Codable {
        case none = 0
        case preloadBlank = 1
        case preloadTemplate = 2
    }
    
    public let policy: PreloadPolicy
    public let scene: [String]?
    public let urlPath: String?
    public let timeout: Int? //ms
    
    public static let defaultTimeout = 10000
}


public struct WAResourcePackageConfig: Codable {
    public let offlineZipName: String
    public let rootPath: String
}

public struct WAResourceInterceptConfig: Codable {
    public let enable: Bool
    public let fgKey: String?
    public let necessaryCookieKeys: [String]?
    public let schemes: [String]?
    public let mainScheme: String?
    public let filetype: [String]?
    public let rootHtml: String?
    public let mapPattern: [String: String]? // [remotePattern: localPattern]
}

public struct WAOpenConfig: Codable {
    public let showLoading: Bool
    public let loadingTimeout: Int
}

public struct WAWebViewConfig: Codable {
    
    public enum KeyboardLayout: String, Codable {
        case adjustResize
    }
    
    public let aliveDuration: Int //ms
    public let maxReuseTimes: Int
    public let keyboardLayout: KeyboardLayout?
}
