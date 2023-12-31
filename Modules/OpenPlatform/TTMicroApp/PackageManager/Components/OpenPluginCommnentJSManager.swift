//
//  OpenPluginCommnentJSManager.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/23.
//  评论组件JS包下载管理工具

import Foundation
import LarkOpenPluginManager

@objcMembers
public final class OpenPluginCommnentJSManager: NSObject {
    private static let jsWorkComponent = "js_worker_component"

    private let manager = ComponentsManager.shared

    private let trace = OPTraceService.default().generateTrace()

    /// commentSDK版本
    private var sdkVersion: String?

    /// 是否需要更新全部CommentComponents
    @objc public func updateAllCommentComponetsIfNeeded() {
        trace.info("[COMMENT] updateAllCommentComponetsIfNeeded")
        if let manager = ECOConfig.service() as? EMAConfigManager, let config = manager.getDictionaryValue(for: Self.jsWorkComponent) {
            for workerName in config.keys {
                updateCommentComponetsIfNeeded(workerName)
            }
        } else {
            trace.error("[COMMENT] No comment config in ECOConfig")
        }
    }

    /// 更新评论组件(如果需要的话)
    @objc public func updateCommentComponetsIfNeeded(_ workerName: String) {
        if let manager = ECOConfig.service() as? EMAConfigManager, let config = manager.getDictionaryValue(for: Self.jsWorkComponent) {
            trace.info("[COMMENT] get comment config:\(config)")

            if let value = config[workerName] as? [String : String] {
                update(componentName: workerName, component: value, appType: OPAppType.gadget)
            } else {
                trace.error("[COMMENT] can not find worker: \(workerName) from config: \(config)")
            }
        } else {
            trace.error("[COMMENT] No comment config in ECOConfig")
        }
    }

    /// 获取评论组件JSSDK本地路径
    @objc public func commentJSSDKLocalPath(_ workerName: String) -> String? {
        let model = manager.localModelOfComponent(workerName, appType: OPAppType.gadget)
        guard let localModel = model else {
            trace.info("[COMMENT] local comment model not exsit")
            return nil
        }
        trace.info("[COMMENT] comment jssdk localPath: \(String(describing: localModel.localPath))")
        return localModel.localPath
    }


    /// 更新组件逻辑
    private func update(componentName: String, component:[String : String], appType: BDPType) {
        let components = [componentName : component]

        trace.info("[COMMENT] update comment:\(components)")
        // 这里一定要赋值给ComponentsManager
        manager.setComponentsConfig(components, forAppType: appType)

        var shouldInstall = false

        // 配置信息中没有版本信息则直接结束更新流程
        guard let configComponentVersion = component["version"] else {
            trace.error("[COMMENT] config version info is nil")
            return
        }

        if let localModel = manager.localModelOfComponent(componentName, appType: appType) {
            if Self.versionCompare(versionA: localModel.version, versionB: configComponentVersion) < 0 {
                trace.info("[COMMENT] local model is outdated, config component version: \(configComponentVersion)")
                shouldInstall = true
            }
        } else {
            // Config 里有，本地没有，那就需要下载
            trace.info("[COMMENT] local model not found")
            shouldInstall = true
        }

        trace.info("[COMMENT] should install components? \(shouldInstall)")

        if shouldInstall {
            manager.install(componentName: componentName, componentVersion: configComponentVersion, appType: appType, uniqueID: nil) {[weak self] _, error in
                if let err = error {
                    self?.trace.error("[COMMENT] component \(componentName) install failed, error:\(err)")
                } else {
                    self?.trace.info("[COMMENT] component \(componentName) installed")
                }
            }
        }
    }

    private class func versionCompare(versionA: String, versionB: String) -> Int {
        return BDPVersionManager.compareVersion(versionA, with: versionB)
    }

    // 是否使用在线更新的评论JSSDK版本，debug使用
    @objc public class func commentUseOnlineSDK() -> Bool {
        let workerName = "comment_for_gadget"
        guard let providerClass = OpenJSWorkerInterpreterManager.shared.getInterpreter(workerName: workerName, interpreterType: .resource) as? NSObject.Type, let local = providerClass.init() as? OpenJSWorkerResourceProtocol, let onlineModel = ComponentsManager.shared.localModelOfComponent(workerName, appType: OPAppType.gadget) else {
            return false
        }
        return versionCompare(versionA: onlineModel.version, versionB: local.scriptVersion ?? "0.0.0") >= 0

    }

    // 本地的评论JS SDK 版本，debug使用
    @objc public class func currentCommentVersion() -> String? {
        let workerName = "comment_for_gadget"
        guard let providerClass = OpenJSWorkerInterpreterManager.shared.getInterpreter(workerName: workerName, interpreterType: .resource) as? NSObject.Type, let local = providerClass.init() as? OpenJSWorkerResourceProtocol, let onlineModel = ComponentsManager.shared.localModelOfComponent(workerName, appType: OPAppType.gadget) else {
            return nil
        }
        if versionCompare(versionA: onlineModel.version, versionB: local.scriptVersion ?? "0.0.0") < 0 {
            return local.scriptVersion
        }
        return onlineModel.version
    }
}

extension OpenPluginCommnentJSManager: OpenJSWorkerNetResourceProtocol {
    public var scriptVersion: String? {
        trace.info("[COMMENT] offer comment JSSDK version:\(String(describing: sdkVersion))")
        return sdkVersion
    }

    public func scriptUrl(workerName: String, local: OpenJSWorkerResourceProtocol) -> URL? {
        // 如果沙盒中没有已下载的JSSDK,则使用内置的;
        guard let model = manager.localModelOfComponent(workerName, appType: OPAppType.gadget) else {
            sdkVersion = local.scriptVersion
            trace.info("[COMMENT] offer comment JSSDK from bundle version:\(String(describing: sdkVersion))")
            return local.scriptLocalUrl
        }

        // 如果沙盒里的JSSDK包版本比CCM内置JSSDK版本要老,则直接使用内置的
        if let scriptVersion = local.scriptVersion, Self.versionCompare(versionA: model.version, versionB: scriptVersion) < 0 {
            sdkVersion = local.scriptVersion
            trace.info("[COMMENT] offer comment JSSDK from bundle version:\(String(describing: sdkVersion))")
            return local.scriptLocalUrl
        }

        sdkVersion = model.version
        trace.info("[COMMENT] offer comment JSSDK from sandbox version:\(String(describing: sdkVersion))")
        if let localPath = model.localPath {
            return URL(fileURLWithPath: localPath)
        } else {
            trace.error("[COMMENT] offer comment JSSDK failed: not exist in sandbox")
            return nil
        }
    }

    public func updateJS(workerName: String) {
        self.updateCommentComponetsIfNeeded(workerName)
    }
}
