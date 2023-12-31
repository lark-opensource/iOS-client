//
//  AppConfig.swift
//  Pods-AppContainerDev
//
//  Created by liuwanlin on 2018/11/15.
//

import UIKit
import Foundation

public enum EnvType {
    case release
    case preRelease
    case stagging
    case dev
}

public struct AppConfig {
    public static let `default` = AppConfig(env: .release)

    public let env: EnvType

    /// 是否开启响应多窗口事件
    ///
    /// 此开关并不是用于控制info.plist中的能力，而是用于响应系统对UIApplicationDelegate的运行时Scene相关逻辑检查
    /// 具体调研见：https://bytedance.feishu.cn/space/doc/doccn6dj46HxIOpKbRiSaYaiwPa#
    public let respondsToSceneSelectors: Bool

    public init(
        env: EnvType,
        respondsToSceneSelectors: Bool = AppConfig.defaultValueForRespondsToSceneSelectors()) {
        self.env = env
        self.respondsToSceneSelectors = respondsToSceneSelectors
    }

    /// respondsToSceneSelectors 默认值
    public static func defaultValueForRespondsToSceneSelectors() -> Bool {
        if #available(iOS 13.0, *) {
            /// 根据 infoplist 配置判断当前 app 是否支持 scene
            var supportMultiScene: Bool = false
            if let sceneManifest = Bundle.main.infoDictionary?["UIApplicationSceneManifest"] as? NSDictionary,
               let sceneConfig = sceneManifest["UIApplicationSupportsMultipleScenes"] as? Bool {
                supportMultiScene = sceneConfig
            }
            return UIApplication.shared.supportsMultipleScenes || supportMultiScene
        }
        return false
    }
}

extension AppConfig {
    #if canImport(CryptoKit)
    @available(iOS 13.0, *)
    static let sceneSelectors: [Selector] = [
        #selector(UIApplicationDelegate.application(_:configurationForConnecting:options:)),
        #selector(UIApplicationDelegate.application(_:didDiscardSceneSessions:))
    ]
    #endif
}
