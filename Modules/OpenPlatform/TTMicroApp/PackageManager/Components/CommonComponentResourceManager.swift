//
//  CommonComponentResourceManager.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/1/20.
//  ajaxHook JS脚本热更管理器
//

import Foundation
import ECOProbe
import ECOInfra
import OPSDK
import LarkSetting
import LarkStorage
import LKCommonsLogging

private let logger = Logger.oplog(CommonComponentResourceManager.self, category: "CommonComponentResourceManager")

public protocol CommonComponentResourceManagerProtocol : AnyObject {
    func updateAllComponetsIfNeeded()
    func fetchAjaxHookJS() -> String?
    
    /// 通过在 settings 上配置的key，返回组件的JS 脚本
    /// componentName->例：ajaxhook_for_webapp
    /// https://cloud.bytedance.net/appSettings-v2/detail/config/151656/detail/status
    /// - Returns: settings 配置的的动态JS脚本组件
    func fetchJSWithSepcificKey(componentName: String) -> String?
    
    /// 通过在 settings 上配置的key，返回组件的JS 脚本
    /// componentName->例：ajaxhook_for_webapp
    ///resourceType -> 例：js（支持自定义文件类型）
    /// https://cloud.bytedance.net/appSettings-v2/detail/config/151656/detail/status
    /// - Returns: settings 配置的的动态JS脚本组件
    func fetchResourceWithSepcificKey(componentName: String, resourceType: String) -> String?
}

@objcMembers
public final class CommonComponentResourceManager: NSObject, CommonComponentResourceManagerProtocol {
    private static let settingsKey = "openplatform_js_update"

    private let manager = ComponentsManager.shared

    private let trace = OPTraceService.default().generateTrace()

    private var scriptCacheMap: [String: String?] = [:]
    
    private static let browserErrorPageTxzEnable: Bool = !EMAFeatureGating.boolValue(forKey: "openplatform.webapp.inner_bundle_txz.disable")
    private static let browserErrorPagePackageName: String = "errorpage"
    private static let browserTXZFileExtension: String = "txz"
    
    private lazy var uniteStorageReformEnable: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform")
    }()
    
    /// 是否需要更新全部Components
    @objc public func updateAllComponetsIfNeeded() {
        trace.info("[JSHOOK] updateAllComponetsIfNeeded")
        if let manager = ECOConfig.service() as? EMAConfigManager, let config = manager.getLatestDictionaryValue(for: Self.settingsKey) {
            for componentName in config.keys {
                updateComponetsIfNeeded(componentName)
            }
        } else {
            trace.error("[JSHOOK] No  config in ECOConfig")
        }
    }

    /// 更新组件(如果需要的话)
    @objc public func updateComponetsIfNeeded(_ componentName: String) {
        if let manager = ECOConfig.service() as? EMAConfigManager, let config = manager.getLatestDictionaryValue(for: Self.settingsKey) {
            trace.info("[JSHOOK] get config:\(config)")

            if let value = config[componentName] as? [String : String] {
                update(componentName: componentName, component: value, appType: OPAppType.webApp)
            } else {
                trace.error("[JSHOOK] can not find worker: \(componentName) from config: \(config)")
            }
        } else {
            trace.error("[JSHOOK] No config in ECOConfig")
        }
    }
    
    /// 获取ajaxHook执行脚本
    @objc public func fetchAjaxHookJS() -> String? {
        return fetchJSWithSepcificKey(componentName: "ajaxhook_for_webapp")
    }
    
    @objc public func fetchJSWithSepcificKey(componentName: String) -> String? {
        return fetchResourceWithSepcificKey(componentName: componentName, resourceType: "js")
    }
        /// 获取ajaxHook执行脚本
    @objc public func fetchResourceWithSepcificKey(componentName: String, resourceType: String) -> String? {
        let resourceName = "\(componentName).\(resourceType)"
        trace.info("[JSHOOK] try to load \(resourceName) from component manager")
        if let scriptToHook = scriptCacheMap[resourceName] {
            trace.info("[JSHOOK fetch \(resourceName) from static cache]")
            return scriptToHook
        }
        if let componentPath = componentJSSDKLocalPath(componentName) {
            let url = URL(fileURLWithPath: componentPath)
            do {
                let scriptToLoad = try String(contentsOf: url, encoding: .utf8)
                scriptCacheMap[resourceName] = scriptToLoad
                return scriptToLoad
            } catch {
                trace.error("[JSHOOK] load script from component manager error, script parse fail, url=\(url)")
            }
        }
        //没有话尝试去JSSDK里面找一份
        trace.info("[JSHOOK] try to load \(resourceName) from JSSDK")
        if EMAFeatureGating.boolValue(forKey: "openplatform.jsupdate.hook.jssdk") {
            // 本地没有正在使用的版本， 使用内置
            if let storageModule = BDPModuleManager(of: .gadget).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol{
                let hookJSPath = "\(storageModule.sharedLocalFileManager().path(for: .jsLib))/\(componentName).\(resourceType)"
                if FileManager.default.fileExists(atPath: hookJSPath) {
                    let url = URL(fileURLWithPath: hookJSPath)
                    do {
                        let scriptToLoad = try String(contentsOf: url, encoding: .utf8)
                        scriptCacheMap[resourceName] = scriptToLoad
                        return scriptToLoad
                    } catch {
                        trace.error("[JSHOOK] load \(resourceName) from JSSDK error, script parse fail, url=\(url)")
                    }
                }
            }
        }
        //最后从bundle里面获取资源兜底
        trace.info("[JSHOOK] try to load \(resourceName) from TimorAssetsBundle")
        var bundleFilePath: String? = nil
        if Self.browserErrorPageTxzEnable && componentName == Self.browserErrorPagePackageName {
            bundleFilePath = unzipWebBundleIfNeed(package: componentName, type: resourceType)
        } else {
            bundleFilePath = OPBundle.timor.path(forResource: componentName, ofType: resourceType)
        }
        if let ajaxHookPath = bundleFilePath {
            let url = URL(fileURLWithPath: ajaxHookPath)
            do {
                let scriptToLoad = try String(contentsOf: url, encoding: .utf8)
                scriptCacheMap[resourceName] = scriptToLoad
                return scriptToLoad
            } catch {
                trace.error("[JSHOOK] load \(resourceName) from bundle error, script parse fail, url=\(url)")
            }
        }
        return nil
    }

    /// 获取组件JSSDK本地路径
    @objc private func componentJSSDKLocalPath(_ componentName: String) -> String? {
        let model = manager.localModelOfComponent(componentName, appType: .webApp)
        guard let localModel = model else {
            trace.info("[JSHOOK] local  model not exsit")
            return nil
        }
        trace.info("[JSHOOK]  jssdk localPath: \(String(describing: localModel.localPath))")
        return localModel.localPath
    }
    
    /// 更新组件逻辑
    private func update(componentName: String, component:[String : String], appType: BDPType) {
        let components = [componentName : component]

        trace.info("[JSHOOK] update :\(components)")
        // 这里一定要赋值给ComponentsManager
        manager.setComponentsConfig(components, forAppType: appType)

        var shouldInstall = false

        // 配置信息中没有版本信息则直接结束更新流程
        guard let configComponentVersion = component["version"] else {
            trace.error("[JSHOOK] config version info is nil")
            return
        }

        if let localModel = manager.localModelOfComponent(componentName, appType: appType) {
            if Self.versionCompare(versionA: localModel.version, versionB: configComponentVersion) < 0 {
                trace.info("[JSHOOK] local model is outdated, config component version: \(configComponentVersion)")
                shouldInstall = true
            }
        } else {
            // Config 里有，本地没有，那就需要下载
            trace.info("[JSHOOK] local model not found")
            shouldInstall = true
        }

        trace.info("[JSHOOK] should install components? \(shouldInstall)")

        if shouldInstall {
            manager.install(componentName: componentName, componentVersion: configComponentVersion, appType: appType, uniqueID: nil) {[weak self] _, error in
                guard self != nil else {
                    BDPLogError(tag: .webview, "WebAppAjaxHookJSManager self is nil!")
                    return
                }
                if let err = error {
                    self?.trace.error("[JSHOOK] component \(componentName) install failed, error:\(err)")
                } else {
                    self?.trace.info("[JSHOOK] component \(componentName) installed")
                }
            }
        }
    }

    private class func versionCompare(versionA: String, versionB: String) -> Int {
        return BDPVersionManager.compareVersion(versionA, with: versionB)
    }
    
    /// 解压网页容器资源包
    /// - Parameters:
    ///   - name: 包名称
    ///   - type: 包内主索引文件类型
    /// - Returns: 解压文件路径
    private func unzipWebBundleIfNeed(package name: String?, type: String?) -> String? {
        guard let name = name else {
            return nil
        }
        if self.uniteStorageReformEnable {
            return self.unzipWebBundleIsoPath(package: name, type: type)
        }
        guard let libraryDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
            return nil
        }
        var libPath = libraryDir.appendingPathComponent("Timor/twebapp/\(name)")
        // 默认解压文件路径为 $libPath/Timor/twebapp/$package/$package
        var filePath: String = libPath.appendingPathComponent("\(name)")
        // 若网页容器错误页资源包, 则解压文件路径为 $libPath/Timor/twebapp/$package/$package.$type
        if name == Self.browserErrorPagePackageName, let type = type {
            filePath = libPath.appendingPathComponent("\(name).\(type)")
        }
        // 若解压文件已存在, 则直接返回文件路径
        if FileManager.default.fileExists(atPath: filePath) {
            return filePath
        }
        // 记录文件的解压时间和解压移动时间
        var startTs = Date().timeIntervalSince1970
        var unzippedTs = startTs
        var endTs = Date().timeIntervalSince1970
        // 待解压资源路径为 $libPath/Timor/twebapp/$package.tmp
        let tmpPath = libPath + ".tmp"
        // 待解压资源完成路径为 $libPath/Timor/twebapp/$package.tmp/$package
        let tmpResultPath = tmpPath.appendingPathComponent(name)
        let filename = name + ".\(Self.browserTXZFileExtension)"
        let unzipResult = unzipBundleFile(filename: filename, filetype: .TXZ, tmpPath: tmpPath, tmpResultPath: tmpResultPath, password: nil)
        unzippedTs = Date().timeIntervalSince1970
        guard unzipResult == true else {
            return nil
        }
        
        BDPFileSystemHelper.removeFolderIfNeed(libPath)
        do {
            var moveResult = try FileManager.default.moveItem(atPath: tmpResultPath, toPath: libPath)
        } catch let error as NSError {
            logger.error("web_bundle_size_compress move throws exception: \(error.localizedDescription)")
            return nil
        }
        BDPFileSystemHelper.removeFolderIfNeed(tmpPath)
        
        endTs = Date().timeIntervalSince1970
        let totalTimeMs = (endTs - startTs) * 1000
        let unzipTimeMs = (unzippedTs - startTs) * 1000
        logger.info("web_bundle_size_compress unzippedTs = \(unzipTimeMs), totalTs = \(totalTimeMs)")
        // 返回解压文件路径
        return filePath
    }
    
    private func unzipWebBundleIsoPath(package name: String, type: String?) -> String? {
        let pathBuilder = IsoPath.in(space: .global, domain: Domain.biz.webApp)
        let libIsoPath = pathBuilder.build(forType: .library, relativePart: "\(name)")
        // 默认解压文件路径为 $libPath/Timor/twebapp/$package/$package
        var filePath: IsoPath = libIsoPath.appendingRelativePath("\(name)")
        // 若网页容器错误页资源包, 则解压文件路径为 $libPath/Timor/twebapp/$package/$package.$type
        if name == Self.browserErrorPagePackageName, let type = type {
            filePath = libIsoPath.appendingRelativePath("\(name).\(type)")
        }
        // 若解压文件已存在, 则直接返回文件路径
        if  filePath.exists {
            return filePath.absoluteString
        }
        // 记录文件的解压时间和解压移动时间
        var startTs = Date().timeIntervalSince1970
        var unzippedTs = startTs
        var endTs = Date().timeIntervalSince1970
        // 待解压资源路径为 $libPath/Timor/twebapp/$package.tmp
        let tmpPath = pathBuilder.build(forType: .library, relativePart: "\(name).tmp")
        // 待解压资源完成路径为 $libPath/Timor/twebapp/$package.tmp/$package
        let tmpResultPath = tmpPath.appendingRelativePath(name)
        let filename = name + ".\(Self.browserTXZFileExtension)"
        let unzipResult = unzipBundleFile(filename: filename, filetype: .TXZ, tmpPath: tmpPath.absoluteString, tmpResultPath: tmpResultPath.absoluteString, password: nil)
        unzippedTs = Date().timeIntervalSince1970
        guard unzipResult == true else {
            return nil
        }
        do {
            try tmpResultPath.moveItem(to: libIsoPath)
        } catch let error as NSError {
            logger.error("web_bundle_size_compress move throws exception: \(error.localizedDescription)")
            return nil
        }
        do {
            try tmpPath.removeItem()
//            try tmpResultPath.moveItem(to: filePath)
//            try tmpPath.removeItem()
        } catch let error as NSError {
            logger.error("web_bundle_size_compress move throws exception: \(error.localizedDescription)")
        }
        endTs = Date().timeIntervalSince1970
        let totalTimeMs = (endTs - startTs) * 1000
        let unzipTimeMs = (unzippedTs - startTs) * 1000
        logger.info("web_bundle_size_compress unzippedTs = \(unzipTimeMs), totalTs = \(totalTimeMs)")
        // 返回解压文件路径
        return filePath.absoluteString
    }
    
    /// 解压资源, 支持zip、txz
    /// - Parameters:
    ///   - filename: 待解压资源名称
    ///   - filetype: 解压类型
    ///   - tmpPath: 待解压资源路径
    ///   - tmpResultPath: 待解压资源完成路径
    ///   - password: 可选, 解压密码
    /// - Returns: 解压结果
    private func unzipBundleFile(filename: String, filetype: BDPBundleResourceType, tmpPath: String, tmpResultPath: String, password: String?) -> Bool {
        // 清空临时目录
        BDPFileSystemHelper.removeFolderIfNeed(tmpPath)
        BDPFileSystemHelper.createFolderIfNeed(tmpPath)
        // 压缩包路径
        guard let path = OPBundle.timor.path(forResource: filename, ofType: nil) else {
            logger.error("web_bundle_size_compress \(filename) not found")
            return false
        }
        let event = OPMonitor("wb_bundle_size_compress")
        event.addCategoryValue("resource", filename)
        // 解压流程
        var retryCount: Int = 3  // 解压重试3次
        var unzipSucceed: Bool = false
        while retryCount > 0 {
            retryCount -= 1
            do {
                try BDPBundleResourceExtractor.extractBundleResource(path: path, type: filetype, targetPath: tmpPath, password: password, overwrite: true)
                let isExist = FileManager.default.fileExists(atPath: tmpResultPath)
                if isExist {
                    unzipSucceed = true
                    break
                } else {
                    let contents = try? FileManager.default.contentsOfDirectory(atPath: tmpResultPath)
                    event.addCategoryValue("unzipExist", isExist)
                        .addCategoryValue("unzipContent", contents)
                    logger.error("web_bundle_size_compress unzip result not exist")
                }
            } catch let error as NSError {
                event.addCategoryValue("unzipException", error.description)
                logger.error("web_bundle_size_compress unzip throws exception \(error.description)")
            }
        }
        // 若解压失败
        if !unzipSucceed {
            event.addCategoryValue("stage", "unzip")
                .setResultTypeFail()
                .flush()
            logger.error("web_bundle_size_compress unzip failed multi times!")
            return false
        }
        // 若解压成功
        event.setResultTypeSuccess()
            .addMetricValue("remainUnzipTimes", retryCount)
            .flush()
        logger.info("web_bundle_size_compress unzip succeed remain \(retryCount) times")
        return true
    }
}
