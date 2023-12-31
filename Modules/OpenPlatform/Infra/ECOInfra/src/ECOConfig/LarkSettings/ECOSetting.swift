//
//  ECOSetting.swift
//  ECOInfra
//
//  Created by baojianjun on 2022/9/28.
//

import Foundation
import LarkSetting
import LKCommonsLogging

public final class ECOSetting: NSObject {
}

extension ECOSetting {
    enum Key: String {
        case gadget_bugfix_input_focus_prevent_default
        /// 同步同层渲染新方案iOS侧开关setting字段
        case gadget_native_component_sync_ios_default
        case gadget_video_component_engine_config
    }
    
    private static func latestSetting(key: Key) -> [String: Any]? {
        return ECOConfig.service().getLatestDictionaryValue(for: key.rawValue)
    }
    
    private static func staticSetting(key: Key) -> [String: Any]? {
        do {
            // TODOZJX
            let setting = try SettingManager.shared.staticSetting(of: key.rawValue)
            return setting
        } catch let error {
            Self.logger.error("get setting from SettingManager with exception:\(error)")
            return nil
        }
    }
}

// MARK: - gadgetBugfixInputFocusPreventDefault
extension ECOSetting {
    private static func gadgetBugfixInputFocusPreventDefault() -> [String: Any]? {
        return latestSetting(key: Key.gadget_bugfix_input_focus_prevent_default)
    }
    
    /// 移除iOS15延时弹起键盘, 并在JSSDK input组件 _inputFocusWrap(event) 调用 event.preventDefault();
    /// see as https://cloud.bytedance.net/appSettings-v2/detail/config/164309/detail/basic
    /// - {
    ///     "enable": True,
    ///     "delay_time": 0.03,
    /// }
    @objc public static func gadgetBugfixInputFocusPreventDefaultEnable() -> Bool {
        guard let setting = Self.gadgetBugfixInputFocusPreventDefault() else {
            return false
        }
        if let enable = setting["enable"] as? Bool {
            return enable
        }
        return false
    }
    
    /// 移除iOS15延时弹起键盘, 并在JSSDK input组件 _inputFocusWrap(event) 调用 event.preventDefault();
    /// see as https://cloud.bytedance.net/appSettings-v2/detail/config/164309/detail/basic
    /// - {
    ///     "enable": True,
    ///     "delay_time": 0.03,
    /// }
    @objc public static func gadgetBugfixInputFocusPreventDefaultDelayTime() -> Double {
        guard let setting = Self.gadgetBugfixInputFocusPreventDefault() else {
            return 0.01
        }
        if let delayTime = setting["delay_time"] as? Double {
            return delayTime
        }
        return 0.01
    }
}

extension ECOSetting {
    @objc public static let kTouchMoveDisableEndEditingKey = "touchMoveDisableEndEditing"
    @objc public static func gadgetScrollViewTouchMoveDisableEndEditing(appId: String?) -> Bool {
        OPSettings(key: .make(userKeyLiteral: "op_scrollview_settings"), tag: kTouchMoveDisableEndEditingKey, defaultValue: false).getValue(appID: appId)
    }
}

extension ECOSetting {
    private static let logger = Logger.oplog(ECOSetting.self, category: "ECOSetting")
    
    private static func gadgetNativeComponentSyncIOSDefault() -> [String: Any]? {
        return staticSetting(key: Key.gadget_native_component_sync_ios_default)
    }
    /// iOS同层同步渲染新框架的settings开关
    /// see as https://cloud.bytedance.net/appSettings-v2/detail/config/173502/detail/basic
    /// - {
    ///     "native_component_sync_enable": True,
    /// }
    @objc public static func gadgetNativeComponentSyncIOSSyncEnable() -> Bool {
        guard let setting = Self.gadgetNativeComponentSyncIOSDefault() else {
            return false
        }
        if let enable = setting["native_component_sync_enable"] as? Bool {
            return enable
        }
        return false
    }
    
    /// iOS同层同步渲染新框架, 使用layer name做hook方式的开关
    /// see as https://bytedance.feishu.cn/wiki/VwjZwHa6ViIruEkjT6BcoyDknyb
    /// see as https://cloud.bytedance.net/appSettings-v2/detail/config/173502/detail/basic
    /// - {
    ///     "hook_layer_name_enable": True,
    /// }
    public static func nativeComponentSyncHookLayerNameEnable() -> Bool {
        guard let setting = Self.gadgetNativeComponentSyncIOSDefault() else {
            return false
        }
        if let enable = setting["hook_layer_name_enable"] as? Bool {
            logger.info("hook_layer_name_enable: \(enable)")
            return enable
        }
        return false
    }
    
    /// iOS同层同步渲染新框架, 修复superview比对的逻辑
    /// see as https://bytedance.feishu.cn/wiki/VwjZwHa6ViIruEkjT6BcoyDknyb
    /// see as https://cloud.bytedance.net/appSettings-v2/detail/config/173502/detail/basic
    /// - {
    ///     "superview_compare_fix_enable": True,
    /// }
    public static func nativeComponentSyncSuperviewCompareFixEnable() -> Bool {
        guard let setting = Self.gadgetNativeComponentSyncIOSDefault() else {
            return false
        }
        if let enable = setting["superview_compare_fix_enable"] as? Bool {
            logger.info("superview_compare_fix_enable: \(enable)")
            return enable
        }
        return false
    }
}

extension ECOSetting {
    private static func gadgetVideoComponentEngineConfig() -> [String: Any]? {
        return staticSetting(key: .gadget_video_component_engine_config)
    }
    
    @objc public static func gadgetVideoComponentStaticEngineConfig() -> [String: Any]? {
        guard let setting = Self.gadgetVideoComponentEngineConfig() else {
            return nil
        }
        return setting["engine"] as? [String: Any]
    }
    
    @objc public static func gadgetVideoComponentDynamicEngineConfig() -> [[String: Any]]? {
        guard let setting = Self.gadgetVideoComponentEngineConfig() else {
            return nil
        }
        return setting["engine_dynamic"] as? [[String: Any]]
    }
}
