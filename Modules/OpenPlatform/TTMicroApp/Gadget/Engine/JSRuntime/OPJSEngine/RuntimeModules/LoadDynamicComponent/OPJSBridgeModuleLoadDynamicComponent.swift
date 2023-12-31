//
//  OPJSBridgeModuleLoadDynamicComponent.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/6/3.
//

import Foundation
import OPJSEngine
import LKCommonsLogging
import OPSDK

public final class OPJSBridgeModulLoadDynamicComponent: NSObject, OPJSLoadDynamicComponent {
    static let logger = Logger.log(OPJSBridgeModulLoadDynamicComponent.self, category: "OPJSEngine")
    @objc weak public var jsRuntime: GeneralJSRuntime?

    @objc public func loadPluginScript(pluginID: NSString?,
                                       version: NSString?,
                                       scriptPath: NSString?) {
        OPDynamicComponentHelper.reportLoadPluginScriptStartMonitor(uniqueID: jsRuntime?.uniqueID, pluginId: pluginID as String?, version: version as String?, scriptPath: scriptPath as String?)
        guard let jsRuntime = self.jsRuntime else {
            Self.logger.error("\(String.kLoadDynamicTag) worker loadScript fail, jsRuntime is nil")
            OPDynamicComponentHelper.reportLoadPluginScriptFailMonitor(uniqueID: jsRuntime?.uniqueID, pluginId: pluginID as String?, version: version as String?, scriptPath: scriptPath as String?, errMsg: "jsRuntime is nil")
            return
        }

        let uniqueID = jsRuntime.uniqueID

        // 检查settings开关
        guard OPDynamicComponentHelper.enableDynamicComponent(uniqueID) else {
            Self.logger.error("\(String.kLoadDynamicTag) settings enable is false")
            OPDynamicComponentHelper.reportLoadPluginScriptFailMonitor(uniqueID: uniqueID, pluginId: pluginID as String?, version: version as String?, scriptPath: scriptPath as String?, errMsg: "settings enable is false")
            return
        }

        jsRuntime.delegate?.bindCurrentThreadTracing?()

        guard let pluginID = pluginID,
              let version = version,
              let scriptPath = scriptPath else {
                  Self.logger.error("\(String.kLoadDynamicTag) params is invalid. pluginID: \(String(describing: pluginID)), version: \(String(describing: version)), scriptPath: \(String(describing: scriptPath))")
                  OPDynamicComponentHelper.reportLoadPluginScriptFailMonitor(uniqueID: uniqueID, pluginId: pluginID as String?, version: version as String?, scriptPath: scriptPath as String?, errMsg: "params is invalid")
                  return
              }

        // 开始加载插件时间戳(单位:ms)
        let startLoadPluginScript = Date().timeIntervalSince1970 * 1000

        // Note: getPluginScript方法中已经上报了
        do {
            let script = try getPluginScript(pluginID: pluginID, version: version, scriptPath: scriptPath, uniqueID: uniqueID)

            guard let sourceURL = URL(string: "plugin/\(pluginID)/\(version)/\(scriptPath)") else {
                Self.logger.error("\(String.kLoadDynamicTag) \(uniqueID.fullString) sourceURL is nil; pluginID: \(pluginID), version: \(version), scriptPath: \(scriptPath)")
                OPDynamicComponentHelper.reportLoadPluginScriptFailMonitor(uniqueID: uniqueID, pluginId: pluginID as String?, version: version as String?, scriptPath: scriptPath as String?, errMsg: "sourceURL generate fail")
                return
            }

            Self.logger.info("\(String.kLoadDynamicTag) \(uniqueID.fullString) load plugin script success, pluginID: \(pluginID), version: \(version), sourceURL: \(sourceURL.absoluteString)")

            jsRuntime.evaluateScript(script, withSourceURL: sourceURL)

            // 完成加载插件时间戳(单位:ms)
            let endLoadPluginScript = Date().timeIntervalSince1970 * 1000
            // 加载耗时(单位:ms)
            let loadPluginScriptDuration = endLoadPluginScript - startLoadPluginScript
            OPDynamicComponentHelper.reportLoadPluginScriptSuccessMonitor(uniqueID: uniqueID, pluginId: pluginID as String?, version: version as String?, scriptPath: scriptPath as String?, loadScriptDuration: loadPluginScriptDuration)
        } catch {
            let error = error as NSError
            OPDynamicComponentHelper.reportLoadPluginScriptFailMonitor(uniqueID: uniqueID, pluginId: pluginID as String?, version: version as String?, scriptPath: scriptPath as String?, errMsg: error.domain)
        }
    }

    @objc public func getPluginScript(pluginID: NSString?,
                                      version: NSString?,
                                      scriptPath: NSString?,
                                      uniqueID: BDPUniqueID?) throws -> String {
        guard let provider = OPTTMicroAppConfigProvider.dynamicComponentManagerProvider,
              let dynamicComponentManager = provider() else {
                  Self.logger.error("\(String.kLoadDynamicTag) cannot get dynamicComponentManager from OPTTMicroAppConfigProvider")
                  throw OPGetPluginScriptError.providerIsNil
              }

        guard let uniqueID = uniqueID else {
            Self.logger.error("\(String.kLoadDynamicTag) uniqueID is nil")
            throw OPGetPluginScriptError.uniqueIDNil
        }

        guard let pluginID = pluginID,
              let version = version,
              let scriptPath = scriptPath else {
                  Self.logger.error("\(String.kLoadDynamicTag) params is invalid. pluginID: \(String(describing: pluginID)), version: \(String(describing: version)), scriptPath: \(String(describing: scriptPath))")
                  throw OPGetPluginScriptError.invalidParams
              }

        Self.logger.info("\(String.kLoadDynamicTag) get load plugin script start, pluginID: \(pluginID), version: \(version) scriptPath: \(scriptPath) appID: \(uniqueID)")

        var previewToken: String?
        // 这边预览插件的时候,开发者传入的version要为dev, 否则不认为其在调试插件.
        if version == "dev" && uniqueID.versionType == .preview,
           let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID),
           let _previewToken = container.containerContext.containerConfig.previewToken {
            previewToken = _previewToken
            Self.logger.info("\(String.kLoadDynamicTag) \(BDPSafeString(uniqueID.fullString)) getPluginScript by preview")
        } else {
            Self.logger.info("\(String.kLoadDynamicTag) \(BDPSafeString(uniqueID.fullString)) getPluginScript by \(uniqueID.versionType) version: \(version) ")
        }

        guard let data = dynamicComponentManager.getComponentResourceByPath(path: scriptPath as String,
                                                                            previewToken: previewToken,
                                                                            componentID: pluginID as String,
                                                                            requireVersion: version as String) else {
            Self.logger.error("\(String.kLoadDynamicTag) \(uniqueID.fullString) can not get data with pluginID: \(pluginID) version: \(version)")
            throw OPGetPluginScriptError.dataIsNil
        }

        guard let script = String(data: data, encoding: .utf8) else {
            Self.logger.error("\(String.kLoadDynamicTag) \(uniqueID.fullString) convert data to string failed, pluginID: \(pluginID), version: \(version)")
            throw OPGetPluginScriptError.convertStringFail
        }

        Self.logger.info("\(String.kLoadDynamicTag) \(uniqueID.fullString) get load plugin script success, pluginID: \(pluginID), version: \(version)")

        return script
    }
}

fileprivate extension String {
    static let kLoadDynamicTag = "[Load Dynamic Script]"
}
