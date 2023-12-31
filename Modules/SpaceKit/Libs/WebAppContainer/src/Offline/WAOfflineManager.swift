//
//  WAOfflineManager.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/20.
//

import Foundation
import SKFoundation
import LKCommonsLogging
import LarkStorage
import SKResource
import LibArchiveKit
import SSZipArchive
import LarkFoundation

public enum WAOfflinePackageStatus {
    case none
    case ready
    case failed
}


public class WAOfflineManager {
    static let logger = Logger.log(WAOfflineManager.self, category: WALogger.TAG)
    let appConfig: WebAppConfig
    let resConfig: WAResourcePackageConfig
    weak var container: WAContainer?
    
    lazy var appVersionKey: String = {
        "webapp.PackageAppVersion.\(appConfig.appName)"
    }()
    
    lazy var zipVersionKey: String = {
        "webapp.ZipVersion.\(appConfig.appName)"
    }()
    
    lazy var bundlePath: String = {
        "WebAppContainer.bundle"
    }()
    
    lazy var zipFilePath: String = {
        "/webapp/\(resConfig.rootPath)"
    }()
    
    lazy var appVersion: String = { 
        "\(Utils.appVersion)-\(Utils.buildVersion)"
    }()
    
    //当前使用资源包版本号(ready后才有值)
    private(set) var currentZipVersion: String?
    
    //安装包中的zip信息
    lazy var zipInfo: ZipInfo = {
        ZipInfo(bundle: self.bundlePath, zipName: self.resConfig.offlineZipName, zipPath: self.zipFilePath)
    }()
    
    private lazy var unzipQueue: DispatchQueue = {
        DispatchQueue(label: "webapp.pkg.\(self.appConfig.appName)")
    }()
    
    static let revisionFile = "current_revision"
    let unknowVersion = "unknow"
    private let unzipLock = NSLock()
    var status = ObserableWrapper<WAOfflinePackageStatus>(.none)
   
    init(config: WebAppConfig, resConfig: WAResourcePackageConfig) {
        self.resConfig = resConfig
        self.appConfig = config
    }
    
    func checkOfflinePackageIfNeed() {
        guard status.value == .none else { return }
        unzipQueue.async { [weak self] in
            self?.setup()
        }
    }
    
    func setup() {
        unzipLock.lock()
        defer {
            unzipLock.unlock()
        }
        Self.logger.info("start check package for:\(self.appConfig.appName)", tag: LogTag.offline.rawValue)
        if shouldUpdate() {
            //清除升级缓存
            cleanOldPackage()
            //解压bundle资源到sandbox
            unzipResToSandboxIfNeed()
        } else {
            Self.logger.info("package is newest", tag: LogTag.offline.rawValue)
            self.currentZipVersion = CCMKeyValue.globalUserDefault.string(forKey: zipVersionKey)
            status.value = .ready
        }
    }
    
    
    private func shouldUpdate() -> Bool {
        let appVersion = self.appVersion
        Self.logger.info("webapp(\(self.appConfig.appName) cur version：\(appVersion)", tag: LogTag.offline.rawValue)
        
        var isVersionChange = true
        if let lastVersion = CCMKeyValue.globalUserDefault.string(forKey: appVersionKey) {
            //使用App版本号对比来判断是否需要更新资源包
            isVersionChange = lastVersion != appVersion
            Self.logger.info("last app：\(lastVersion),", tag: LogTag.offline.rawValue)
        }
        
        if !isVersionChange {
#if DEBUG
            //Debug环境再多判断一下zip包的版本号
            //正式环境下，如果有换包，appversion肯定有变化，不需要做这个判断
            guard self.zipInfo.isVaild else {
                Self.logger.error("zip invalid, path:\(zipInfo.zipFileFullPath)", tag: LogTag.offline.rawValue)
                return false
            }
            
            let targetPath = Self.unzipResFullPath(appName: self.resConfig.rootPath)
            guard let curVersion = Self.revision(in: targetPath) else {
                Self.logger.error("cur pkg is empty", tag: LogTag.offline.rawValue)
                return true
            }
            Self.logger.info("cur pkg ver:\(curVersion), zip version: \(zipInfo.version)", tag: LogTag.offline.rawValue)
            if curVersion == zipInfo.version {
                return false
            }
            return true
#endif
        }
        return isVersionChange
    }
    
    /// 新版本启动，先清空缓存，去除升级的影响
    private func cleanOldPackage() {
        Self.logger.info("clean old pkg when version change", tag: LogTag.offline.rawValue)
        let resPath = Self.unzipResFullPath(appName: self.resConfig.rootPath)
        removeFiles(at: resPath, logTag: "del res path:\(resPath.pathString)")
    }
    
    //解压bundle资源
    func unzipResToSandboxIfNeed() {
        let startTime = WAPerformanceTiming.getTimeStamp()
        guard self.zipInfo.isVaild else {
            spaceAssertionFailure("invalid zipinfo")
            let cost = WAPerformanceTiming.getTimeStamp() - startTime
            self.container?.tracker.reportUnzipEvent(success: false, duration: cost, errorMsg: "invalid zipinfo")
            return
        }
        guard self.zipInfo.zipFileFullPath.exists else {
            Self.logger.error("zip not exist, path:\(zipInfo.zipFileFullPath)")
            let cost = WAPerformanceTiming.getTimeStamp() - startTime
            self.container?.tracker.reportUnzipEvent(success: false, duration: cost, errorMsg: "zip not exist")
            return
        }
        Self.logger.info("unzipResToSandboxIfNeed...", tag: LogTag.offline.rawValue)
        
        let zipVersion = zipInfo.version
        let unzipPath = Self.unzipResPath()
        let currentVersion = Self.revision(in: unzipPath) ?? unknowVersion

        Self.logger.info("zip_ver:\(zipVersion) unzip_ver:\(currentVersion)", tag: LogTag.offline.rawValue)
        Self.logger.info("start unzip \(zipInfo.zipFileFullPath) to \(unzipPath)", tag: LogTag.offline.rawValue)
        let result = BundlePackageExtractor.unzipBundle(zipFilePath: zipInfo.zipFileFullPath, to: unzipPath)
        let cost = WAPerformanceTiming.getTimeStamp() - startTime
        switch result {
        case .success:
            let targetPath = Self.unzipResFullPath(appName: self.resConfig.rootPath)
            if targetPath.exists {
                CCMKeyValue.globalUserDefault.set(appVersion, forKey: appVersionKey)
                CCMKeyValue.globalUserDefault.set(currentVersion, forKey: zipVersionKey)
                self.currentZipVersion = currentVersion
                status.value = .ready
                Self.logger.info("unzip success, pkg ready to use:\(currentVersion), cost:\(cost)", tag: LogTag.offline.rawValue)
                self.container?.tracker.reportUnzipEvent(success: true, duration: cost)
            } else {
                status.value = .failed
                removeFiles(at: unzipPath, logTag: "unzip failed")
                Self.logger.info("unzip success but file path is wrong,\(targetPath.pathString), cost:\(cost)", tag: LogTag.offline.rawValue)
                self.container?.tracker.reportUnzipEvent(success: false, duration: cost, errorMsg: "unzip success but file path is wrong")
            }
        case .failure(let error):
            status.value = .failed
            Self.logger.info("unzip error, cost:\(cost)", tag: LogTag.offline.rawValue, error: error)
            self.container?.tracker.reportUnzipEvent(success: false, duration: cost, errorMsg: "unzip error,\(error.localizedDescription)")
        }
        //TODO: 增加解压失败重试，可参考gecko unzipResToSandbox
    }
    
}

extension WATracker {
    func reportUnzipEvent(success: Bool, duration: Int64, errorMsg: String? = nil) {
        var params: [String: Any] = [ReportKey.is_success.rawValue: success,
                                     ReportKey.duration_ms.rawValue: duration]
        if let errorMsg {
            params[ReportKey.errorMsg.rawValue] = errorMsg
        }
        self.log(event: .extractPackage, parameters: params)
    }
}
