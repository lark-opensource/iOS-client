//
//  NativeComponentConfigManager.swift
//  NativeComponentConfigManager
//
//  Created by xiongmin on 2022/4/20.
//

import Foundation
import LarkSetting
import LKCommonsLogging


///  组件支持的形态
///  1. legacy 线上旧形态
///  2.  native_component_overlay 新框架覆盖
///  3. native_component_sandwich 新框架同层

///  组件的类别
///  1. video  native video组件
///  2.  map  native map组件
///  3.  webView native web-view组件
///  4. input native input组件
///  5. textArea native textarea组件

// setting返回示例
/*
 {
    "components": {
        // 用户粒度配置。群粒度、租户粒度、都走这里，因为最终都可以转化为当前用户的配置
        "user_config": {
            "app_id_config": {
                // 当前用户下特殊 AppId 配置，没有配置的走下面的 general_config
                "cli_a2c4648452f8d00d": {
                    "video": ["legacy"],
                    // ...
                },
                // ...
            },
            "general_config": {
                "video": ["legacy", "native_component_sandwich"],
                "map": ["legacy"],
                // ...
            }
        },
        // AppId 维度配置
        "app_id_config": {
            "cli_a0fe9ebd11f8900d": {
                "video": ["legacy", "native_component_overlay"]
            },
            // ...
        },
        // 全局配置
        "global_config": {
            "video": ["legacy", "native_component_sandwich"],
            "map": ["legacy"],
            // ...
        },
        // 允许开发者自行配置同层的情况下:
        // 如果force_setting是false, 则根据开发者的配置来; 如果开发者配置了inputAlwaysEmbed, 具体同层类型则根据type来; 如果没有配置, 则走Setting的综合结论;
        // 如果force_setting是true, 则不考虑开发者的配置, 根据当前Setting的综合结论, 不会使用type.
        // 如果force_setting没有配置, 则不考虑开发者的配置
        "force_settings": {
            "input": true,
            "type": "native_component_sandwich" / "native_component_sandwich_sync"
        },
        // focus_api在哪些情况下可使用
        "focus_api_enable": {
            "input": [
                "native_component_sandwich",
                "native_component_sandwich_sync",
                "native_component_overlay"
            ],
            "textarea": [
                "native_component_sandwich",
                "native_component_sandwich_sync",
                "native_component_overlay"
            ]
        },
    }
}
 */

/// 获取Native组件配置
/// user_config(app_id_config > general_config) > app_id_config > global_config
/// 每一级拿到数据后都会阻断
@objc
public final class NativeComponentConfigManager: NSObject {
    
    private static let logger = Logger.oplog(NativeComponentConfigManager.self, category: "NativeComponentConfig")
    
    private static let nativeComponentConfigKey = UserSettingKey.make(userKeyLiteral: "gadget_native_component_config")
    private static let userConfigKey = "user_config"
    private static let appIdConfigKey = "app_id_config"
    private static let globalConfigKey = "global_config"
    private static let generalConfigKey = "general_config"
    private static let settingFocusAPIEnableKey = "focus_api_enable"
    
    private static let forceSettingsKey = "force_settings"
    private static let forceSettingsInput = "input"
    private static let forceSettingsType = "type"
    
    private static let kSupportRenderTypesKey = "supportRenderTypes"
    private static let renderFocusAPIEnableKey = "focusAPIEnable"
    
    private static let kInputAlwaysEmbedKey = "inputAlwaysEmbed"
    
    @RawSetting(key: nativeComponentConfigKey)
    private var settingConfig: [String: Any]?
    
    private let appId: String
    private let windowConfig: [AnyHashable: Any]?
    
    public required init(with appId: String, windowConfig: [AnyHashable: Any]?) {
        self.appId = appId
        self.windowConfig = windowConfig
        super.init()
    }
    
    @objc
    public lazy var configString: String? = {
        Self.config2Str(config: self.configMap)
    }()
    
    @objc
    public lazy var configMap: [String: AnyHashable]? = {
        Self.config(with: settingConfig, appId: appId, windowConfig: windowConfig)
    }()
    
    private static func config2Str(config: [String: AnyHashable]?) -> String? {
        guard let config = config else {
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: config, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                logger.error("json data convert to string failed")
                return nil
            }
            let javaScriptString = ";window.LarkNativeComponentConfig = window.LarkNativeComponentConfig || {}; window.LarkNativeComponentConfig['componentConfig'] = () => { return \(jsonString); };"
            return javaScriptString
        } catch {
            logger.error("transform dict to json failed \(config)")
        }
        return nil
    }
    
    // 根据APPID获取Config
    private static func config(with settingConfig: [String: Any]?, appId: String, windowConfig: [AnyHashable: Any]?) -> [String: AnyHashable]? {
        var nativeComponentConfig = [String: [String: AnyHashable]]()
        guard let config = settingConfig?["components"] as? [String: AnyHashable] else {
            logger.error("components of settingConfig is nil")
            return nil
        }
        var resultLog = "origin: [appId: \(appId);"
        
        // 第一步，处理user_config
        if let userConfig = config[userConfigKey] as? [String: AnyHashable] {
            if let appIdConfigs = userConfig[appIdConfigKey] as? [String: AnyHashable],
               let appIdConfig = appIdConfigs[appId] as? [String: [String]],
               !appIdConfig.isEmpty {
                resultLog.append(contentsOf: "userConfig->appIdConfig: ")
                // 处理特殊appId的配置
                for item in appIdConfig {
                    nativeComponentConfig[item.key] = [kSupportRenderTypesKey: item.value]
                    resultLog.append(contentsOf: "\(item.key):\(item.value);")
                }
            }
            if let generalConfig = userConfig[generalConfigKey] as? [String: [String]],
               !generalConfig.isEmpty {
                resultLog.append(contentsOf: "userConfig->generalConfig: ")
                // 处理general配置
                for item in generalConfig {
                    if !nativeComponentConfig.keys.contains(item.key) {
                        nativeComponentConfig[item.key] = [kSupportRenderTypesKey: item.value]
                        resultLog.append(contentsOf: "\(item.key):\(item.value);")
                    }
                }
            }
        }
        
        if let appIdConfigs = config[appIdConfigKey] as? [String: AnyHashable],
           let appIdConfig = appIdConfigs[appId] as? [String: [String]],
           !appIdConfig.isEmpty {
            resultLog.append(contentsOf: "appIdConfig: ")
            for item in appIdConfig {
                if !nativeComponentConfig.keys.contains(item.key) {
                    nativeComponentConfig[item.key] = [kSupportRenderTypesKey: item.value]
                    resultLog.append(contentsOf: "\(item.key):\(item.value);")
                }
            }
        }
        
        if let globalConfig = config[globalConfigKey] as? [String: [String]],
           !globalConfig.isEmpty {
            resultLog.append(contentsOf: "globalConfig: ")
            for item in globalConfig {
                if !nativeComponentConfig.keys.contains(item.key) {
                    nativeComponentConfig[item.key] = [kSupportRenderTypesKey: item.value]
                    resultLog.append(contentsOf: "\(item.key):\(item.value);")
                }
            }
        }
        
        if let forceType = getInputAlwaysEmbed(config: config, windowConfig: windowConfig, resultLog: &resultLog) {
            nativeComponentConfig[forceSettingsInput] = [kSupportRenderTypesKey: [forceType]]
        }
        
        setFocusAPI(config: config, nativeComponentConfig: &nativeComponentConfig, resultLog: &resultLog)
        
        resultLog.append(contentsOf: "]")
        logger.info("\(resultLog); result nativeComponentConfig: \(nativeComponentConfig)")
        return ["components": nativeComponentConfig]
    }
    
    private static func getInputAlwaysEmbed(config: [String: AnyHashable], windowConfig: [AnyHashable: Any]?, resultLog: inout String) -> String? {
        resultLog.append(contentsOf: "force_setting: ")
        guard let userInputAlwaysEmbed = windowConfig?[kInputAlwaysEmbedKey] as? Bool else {
            // 开发者未设置 inputAlwaysEmbed, 走Setting全局配置
            resultLog.append(contentsOf: "no window inputAlwaysEmbed")
            return nil
        }
        guard userInputAlwaysEmbed else {
            // 开发者设置了 inputAlwaysEmbed = false, 走Setting全局配置
            resultLog.append(contentsOf: "{inputAlwaysEmbed: false}")
            return nil
        }
        guard let forceSetting = config[forceSettingsKey] as? [String: AnyHashable],
              let inputIsForce = forceSetting[forceSettingsInput] as? Bool else {
            // Settings 没有 force_setting 相关配置, 走Setting全局配置
            resultLog.append(contentsOf: "no force_setting")
            return nil
        }
        guard !inputIsForce else {
            // Settings force_setting: { "input": true }, 走Setting全局配置
            resultLog.append(contentsOf: "{input: true}")
            return nil
        }
        guard let forceType = forceSetting[forceSettingsType] as? String else {
            // Settings force_setting: { "type" 不是string }, 走Setting全局配置
            resultLog.append(contentsOf: "no type")
            return nil
        }
        resultLog.append(contentsOf: "{type: \(forceType)}")
        return forceType
    }
    
    private static func setFocusAPI(config: [String: AnyHashable], nativeComponentConfig: inout [String: [String: AnyHashable]], resultLog: inout String) {
        resultLog.append(contentsOf: "\(settingFocusAPIEnableKey): ")
        guard let focusAPIEnableMap = config[settingFocusAPIEnableKey] as? [String: [String]] else {
            resultLog.append(contentsOf: "no setting")
            return
        }
        for (key, componentConfig) in nativeComponentConfig {
            if let supportFocusTypes = focusAPIEnableMap[key], !supportFocusTypes.isEmpty,
               let supportRenderTypes = componentConfig[kSupportRenderTypesKey] as? [String],
               let supportRenderType = supportRenderTypes.first,
               supportFocusTypes.contains(supportRenderType) {
                resultLog.append(contentsOf: "\(key),")
                let newConfig = componentConfig.merging([renderFocusAPIEnableKey : true]) { $1 }
                nativeComponentConfig[key] = newConfig
            }
        }
    }
}
