//
//  ECOConfig.swift
//  ECOInfra
//
//  Created by 窦坚 on 2021/6/20.
//

import Foundation
import LarkContainer
import Swinject
import LarkSetting
import LKCommonsLogging

@objc extension ECOConfig {
    public class func service() -> ECOConfigService {
        return Injected<ECOConfigService>().wrappedValue
    }

}

@objc public protocol ECOConfigBridgeProtocol {
    func valueFromLarkSettingsWithKey(_ key: String, needLatest: Bool) -> Any?
}

extension ECOConfig {
    private static let logger = Logger.oplog(ECOConfig.self, category: "ECOConfig")
}

@objc extension ECOConfig: ECOConfigBridgeProtocol {
    
    /// 从 LarkSetting 中获取配置的值
    /// - Parameters:
    ///   - key:配置的key
    ///   - needLatest: 是否需要获取最新的配置，如果 true 则表示不从静态数据里获取
    /// - Returns: 配置的值
    public func valueFromLarkSettingsWithKey(_ key: String, needLatest: Bool) -> Any? {
        //如果FG开启，优先从LarkSetting 中获取对应的配置，否则返回 nil
        var settingValue: Any? = nil
        var hasException = false
        do {
            var originalStringValue: String? = nil
            if needLatest {
                // TODOZJX
                originalStringValue = try SettingManager.shared.setting(with: String.self, of: key, decodeStrategy: .useDefaultKeys)
            } else {
                // TODOZJX
                originalStringValue = try SettingManager.shared.staticSetting(with: String.self, of: key, decodeStrategy: .useDefaultKeys)
            }
            if let originalStringValue = originalStringValue {
                let data = originalStringValue.data(using: .utf8) ?? Data()
                settingValue = try JSONSerialization.jsonObject(with: data, options: [])
            }
        } catch  {
            //打印错误信息
            Self.logger.error("get setting from SettingManager with exception:\(error)")
            hasException = true
        }
        //如果 settingValue 没有，且没有执行 exception 逻辑（false）。说明返回的数据本身就是空，不能之后的降级兜底逻辑
        if settingValue == nil {
            OPMonitor(EPMClientOpenPlatformCommonConfigCode.config_value_empty)
            .addCategoryValue("config_key", key)
            .addCategoryValue("has_exception", hasException)
            .flush()
            //stringValue 如果是nil，默认设为空字符串。避免兜底从 ECOConfig 中获取值的逻辑
            if hasException == false {
                settingValue = ""
            }
            Self.logger.warn("setting value is nil with key:\(key)")
        }
        return settingValue
        
    }
}
