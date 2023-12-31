//
//  LynxBuildInPkgProcessor.swift
//  SKCommon
//
//  Created by ByteDance on 2022/8/8.
//

import UIKit
import Foundation
import BDXServiceCenter
import BDXResourceLoader
import SKFoundation
import BootManagerConfig

final class LynxPkgProcessor: NSObject, BDXResourceLoaderProcessorProtocol {
    let pkgSource: LynxPkgSource
    let resourceLoaderName: String
    init(pkgSource: LynxPkgSource, name: String) {
        self.pkgSource = pkgSource
        self.resourceLoaderName = name
        super.init()
    }
    
    func fetchResource(
        withURL url: String, container: UIView?, loaderConfig: BDXResourceLoaderConfig?,
        taskConfig: BDXResourceLoaderTaskConfig?,
        resolve resolveHandler: @escaping BDXResourceLoaderResolveHandler,
        reject rejectHandler: @escaping BDXResourceLoaderRejectHandler
    ) {
        DocsLogger.info("pkgSource:[\(pkgSource)] fetchPkg...", component: LogComponents.lynx)
        pkgSource.fetchPkg { [weak self] pkg in
            guard let self = self else {
                return
            }
            guard let pkg = pkg else {
                DocsLogger.info("fetchPkg, get nil", component: LogComponents.lynx)
                rejectHandler(PkgProcessorError.fetchPkgFail)
                return
            }
            let resource = LynxLocalResource(pkg: pkg, taskConfig: taskConfig)
            DocsLogger.info("fetchPkg, get resource:\(pkg.description)", component: LogComponents.lynx)
            resolveHandler(resource, self.resourceLoaderName)
        }
    }
    
    func cancelLoad() {}
    
}

final class LynxHotfixPkgProcessor: NSObject, BDXResourceLoaderProcessorProtocol {
    let resourceLoaderName: String = "SKLynxHotfixPkgProcessor"
    private let bizId: String
    private let channel: String
    private let accessKey: String?
    private let buildInVersionURL: SKFilePath?
    private var pkgSources: [LynxGeckoLoadStrategy: SKLynxHotfixPkgSource] = [:]
    
    init(bizId: String, channel: String, accessKey: String?, buildInVersionURL: SKFilePath?) {
        self.bizId = bizId
        self.channel = channel
        self.accessKey = accessKey
        self.buildInVersionURL = buildInVersionURL
        super.init()
    }
    func fetchResource(
        withURL url: String, container: UIView?, loaderConfig: BDXResourceLoaderConfig?,
        taskConfig: BDXResourceLoaderTaskConfig?,
        resolve resolveHandler: @escaping BDXResourceLoaderResolveHandler,
        reject rejectHandler: @escaping BDXResourceLoaderRejectHandler
    ) {
        let loadStrategy = getLoadStrategy(from: taskConfig) ?? .localFirstNotWaitRemote
        guard let accessKey = accessKey else {
            DocsLogger.info("accessKey is nil", component: LogComponents.lynx)
            rejectHandler(PkgProcessorError.accessKeyNil)
            return
        }
        let pkgSource = getPkgSource(with: loadStrategy, accessKey: accessKey)
        pkgSource.fetchPkg { [weak self] pkg in
            guard let self = self else {
                return
            }
            guard let pkg = pkg else {
                DocsLogger.info("fetchPkg is nil, reject", component: LogComponents.lynx)
                rejectHandler(PkgProcessorError.fetchPkgFail)
                return
            }
            if let buildInVersionURL = self.buildInVersionURL,
               let buildInVersion = LynxIOHelper.syncGetVersion(from: buildInVersionURL),
               buildInVersion.isBig(than: pkg.version) {
                DocsLogger.info("buildInVersion:\(buildInVersion), pkg.version:\(pkg.version), reject", component: LogComponents.lynx)
                rejectHandler(PkgProcessorError.hotfixPkgExpired)
                return
            }
            let resource = LynxLocalResource(pkg: pkg, taskConfig: taskConfig)
            DocsLogger.info("resolve local resource: \(pkg.description)", component: LogComponents.lynx)
            resolveHandler(resource, self.resourceLoaderName)
        }
    }
    
    func cancelLoad() {}
    
    private func getPkgSource(with loadStrategy: LynxGeckoLoadStrategy, accessKey: String) -> SKLynxHotfixPkgSource {
        if let pkgSource = pkgSources[loadStrategy] {
            return pkgSource
        }
        let pkgSource = SKLynxHotfixPkgSource(
            bizId: bizId, channel: channel,
            accessKey: accessKey, loadStrategy: loadStrategy
        )
        pkgSources[loadStrategy] = pkgSource
        return pkgSource
    }
    
    private func getLoadStrategy(from taskConfig: BDXResourceLoaderTaskConfig?) -> LynxGeckoLoadStrategy? {
        guard let taskConfig = taskConfig else {
            return nil
        }
        return LynxGeckoLoadStrategy(rawValue: taskConfig.dynamic.intValue)
    }
    
    /// 检测到App版本升级后，清理热更包
    /// 背景: app升级后如果仍然使用旧的热更包可能会有问题，因此升级后需要清理现有的热更包
    static func clearHotfixPkgIfNeeded() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              !currentVersion.isEmpty else {
            DocsLogger.error("currentVersion is empty", component: LogComponents.lynx)
            return
        }
        let versionFileName = "lastAccessAppVersion"
        let versionFilePath = LynxIOHelper.Path.getRootFolder_().appendingRelativePath(versionFileName)
        
        let clearAction = {
            let hotfixDir = LynxIOHelper.Path.getSourceFolder_(for: LynxEnvManager.bizID, type: .hotfix)
            do {
                try hotfixDir.removeItem()
                DocsLogger.info("remove hotfixDir [\(hotfixDir)], result => true", component: LogComponents.lynx)
            } catch {
                DocsLogger.info("remove hotfixDir [\(hotfixDir)], result error => \(error)", component: LogComponents.lynx)
            }
        }
        let writeVersionAction = {
            let data = currentVersion.data(using: .utf8) ?? Data()
            let result = versionFilePath.writeFile(with: data, mode: .over)
            DocsLogger.info("write currentVersion [\(currentVersion)] result => \(result)", component: LogComponents.lynx)
        }
        if let readVersion = try? String.read(from: versionFilePath, encoding: .utf8) {
            if readVersion == currentVersion {
                // no-op
            } else {
                clearAction()
                writeVersionAction()
            }
        } else { // 未读到版本号
            if currentVersion.hasPrefix("5.23") {
                clearAction()
            }
            writeVersionAction()
        }
    }
}

final class LynxLocalResource: NSObject {
    let pkg: LynxResourcePkg?
    let taskConfig: BDXResourceLoaderTaskConfig?
    init(pkg: LynxResourcePkg?, taskConfig: BDXResourceLoaderTaskConfig?) {
        self.pkg = pkg
        self.taskConfig = taskConfig
        super.init()
    }
}
extension LynxLocalResource: BDXResourceProtocol {
    func sourceUrl() -> String? { nil }
    
    func cdnUrl() -> String? { nil }
    
    func channel() -> String? { nil }
    
    func version() -> UInt64 { 0 }
    
    func bundle() -> String? { nil }
    
    func accessKey() -> String? { nil }
    
    func originSourceURL() -> String? { return nil }
    
    func absolutePath() -> String? {
        guard let bundleName = taskConfig?.bundleName else {
            return nil
        }
        return pkg?.getAbsolutePath(with: bundleName).pathString
    }
    
    func resourceData() -> Data? {
        guard let pkg = pkg else {
            return nil
        }
        guard let bundleName = taskConfig?.bundleName, !bundleName.isEmpty else {
            DocsLogger.error("taskConfig.bundleName is empty", component: LogComponents.lynx)
            return nil
        }
        let path = pkg.getAbsolutePath(with: bundleName)
        do {
            let data = try Data.read(from: path)
            return data
        } catch let error {
            DocsLogger.error("read data fail", error: error, component: LogComponents.lynx)
        }
        return nil
    }
    
    func resourceType() -> BDXResourceStatus {
        if pkg?.type == .hotfix {
            return .gecko
        } else if pkg?.type == .bundle {
            return .buildIn
        }
        return .offline
    }
    
    static func resource(with url: URL) -> LynxLocalResource {
        spaceAssertionFailure()
        return LynxLocalResource(pkg: nil, taskConfig: nil)
    }
}

enum PkgProcessorError: Error {
    case fetchPkgFail
    case accessKeyNil
    case hotfixPkgExpired
}
