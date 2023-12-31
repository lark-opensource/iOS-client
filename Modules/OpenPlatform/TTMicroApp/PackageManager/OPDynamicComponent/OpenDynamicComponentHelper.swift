//
//  OpenDynamicComponentHelper.swift
//  OPPlugin
//
//  Created by laisanpin on 2022/6/21.
//  服务小程序动态插件工具类

import Foundation
import OPSDK
import ECOInfra
import OPFoundation
import LKCommonsLogging
import LarkContainer
import ECOProbe
import ECOProbeMeta

final class OPGetPluginScriptError {
    static public let providerIsNil = NSError(domain: "cannot get dynamicComponentManager", code: -10001, userInfo: nil)

    static public  let invalidParams = NSError(domain: "params invalid", code: -10002, userInfo: nil)

    static public let uniqueIDNil = NSError(domain: "uniqueID is nil", code: -10003, userInfo: nil)

    static public let dataIsNil = NSError(domain: "data is nil", code: -10004, userInfo: nil)

    static public let convertStringFail = NSError(domain: "convert string fail", code: -10005, userInfo: nil)
}

@objcMembers
public final class OPDynamicComponentHelper: NSObject {
    private static let logger = Logger.oplog(OPDynamicComponentHelper.self)

    /// 返回插件功能中enable(总开关状态)
    static public func enableDynamicComponent() -> Bool {
        let configService = Injected<ECOConfigService>().wrappedValue
        guard let config = configService.getDictionaryValue(for: "dynamic_component_config"),
              let enable = config["enable"] as? Bool else {
            Self.logger.warn("[OPDynamicComponentHelper] config is invalid")
            return false
        }

        Self.logger.info("[OPDynamicComponentHelper] enable: \(enable)")
        return enable
    }

    /// 判断某个应用是否支持插件功能
    /// - Parameter uniqueID: appID
    /// - Returns: 是否开启插件功能
    static public func enableDynamicComponent(_ uniqueID: OPAppUniqueID?) -> Bool {
        guard let uniqueID = uniqueID else {
            Self.logger.warn("[OPDynamicComponentHelper] uniqueID is nil")
            return false
        }

        let configService = Injected<ECOConfigService>().wrappedValue
        guard let config = configService.getDictionaryValue(for: "dynamic_component_config") else {
            Self.logger.warn("[OPDynamicComponentHelper] config is nil")
            return false
        }

        // 检查黑名单
        if let blacklist = config["app_id_black_list"] as? [String],
           blacklist.contains(BDPSafeString(uniqueID.appID)) {
            Self.logger.info("[OPDynamicComponentHelper] \(BDPSafeString(uniqueID.appID)) in black list")
            return false
        }

        // 检查白名单
        if let whitelist = config["app_id_white_list"] as? [String], whitelist.contains(BDPSafeString(uniqueID.appID)) {
            Self.logger.info("[OPDynamicComponentHelper] \(BDPSafeString(uniqueID.appID)) in white list")
            return true
        }

        // 检查总开关
        guard let enable = config["enable"] as? Bool else {
            Self.logger.warn("[OPDynamicComponentHelper] config is invalid")
            return false
        }

        Self.logger.info("[OPDynamicComponentHelper] \(BDPSafeString(uniqueID.appID)) enable: \(enable)")
        return enable
    }

    /// 上报开始调用loadPlugin埋点
    static public func reportLoadPluginStartMonitor(uniqueID: OPAppUniqueID?,
                                                    pluginId: String,
                                                    pluginVersion: String,
                                                    webviewId: Int) {
        OPMonitor(EPMClientOpenPlatformGadgetDynamicComponentCode.native_load_plugin_start)
            .addMap(["plugin_id" : BDPSafeString(pluginId),
                     "input_version" : BDPSafeString(pluginVersion),
                     "webview_id" : webviewId])
            .setUniqueID(uniqueID)
            .flush()
    }

    /// 上报开始loadPlugin调用成功
    static public func reportLoadPluginSuccessMonitor(uniqueID: OPAppUniqueID?,
                                                      pluginId: String,
                                                      pluginVersion: String,
                                                      webviewId: Int,
                                                      downloadDuration: Double,
                                                      loadScriptDuration: Double) {
        OPMonitor(EPMClientOpenPlatformGadgetDynamicComponentCode.native_load_plugin_success)
            .addMap(["plugin_id" : BDPSafeString(pluginId),
                     "input_version" : BDPSafeString(pluginVersion),
                     "webview_id" : webviewId,
                     "plugin_download_time" : downloadDuration,
                     "plugin_frame_load_time" : loadScriptDuration])
            .setUniqueID(uniqueID)
            .flush()
    }

    /// 上报开始loadPlugin调用失败
    static public func reportLoadPluginFailMonitor(uniqueID: OPAppUniqueID?,
                                                   pluginId: String,
                                                   pluginVersion: String,
                                                   webviewId: Int,
                                                   errCode: Int,
                                                   errMsg: String?) {
        OPMonitor(EPMClientOpenPlatformGadgetDynamicComponentCode.native_load_plugin_fail)
            .addMap(["plugin_id" : BDPSafeString(pluginId),
                     "input_version" : BDPSafeString(pluginVersion),
                     "webview_id" : webviewId,
                     "error_code" : errCode,
                     "error_message" : BDPSafeString(errMsg)])
            .setUniqueID(uniqueID)
            .flush()
    }


    /// 上报开始调用loadPluginScript埋点
    static public func reportLoadPluginScriptStartMonitor(uniqueID: OPAppUniqueID?,
                                                          pluginId: String?,
                                                          version: String?,
                                                          scriptPath: String?) {
        OPMonitor(EPMClientOpenPlatformGadgetDynamicComponentCode.native_load_plugin_script_start)
            .addMap(["plugin_id" : BDPSafeString(pluginId),
                     "version" : BDPSafeString(version),
                     "path" : BDPSafeString(scriptPath)])
            .setUniqueID(uniqueID)
            .flush()
    }

    /// 上报loadPluginScript调用成功埋点
    static public func reportLoadPluginScriptSuccessMonitor(uniqueID: OPAppUniqueID?,
                                                            pluginId: String?,
                                                            version: String?,
                                                            scriptPath: String?,
                                                            loadScriptDuration: Double) {
        OPMonitor(EPMClientOpenPlatformGadgetDynamicComponentCode.native_load_plugin_script_suceess)
            .addMap(["plugin_id" : BDPSafeString(pluginId),
                     "version" : BDPSafeString(version),
                     "path" : BDPSafeString(scriptPath),
                     "script_load_time" : loadScriptDuration])
            .setUniqueID(uniqueID)
            .flush()
    }

    /// 上报loadPluginScript调用失败埋点
    static public func reportLoadPluginScriptFailMonitor(uniqueID: OPAppUniqueID?,
                                                         pluginId: String?,
                                                         version: String?,
                                                         scriptPath: String?,
                                                         errMsg: String?) {
        OPMonitor(EPMClientOpenPlatformGadgetDynamicComponentCode.native_load_plugin_script_fail)
            .addMap(["plugin_id" : BDPSafeString(pluginId),
                     "version" : BDPSafeString(version),
                     "path" : BDPSafeString(scriptPath),
                     "error_message" : BDPSafeString(errMsg)])
            .setUniqueID(uniqueID)
            .flush()
    }
}
