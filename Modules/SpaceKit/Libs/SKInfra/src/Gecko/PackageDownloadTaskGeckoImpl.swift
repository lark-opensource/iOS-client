//
//  PackageDownloadTaskGeckoImpl.swift
//  SKCommon
//
//  Created by ByteDance on 2022/7/4.
//

import RxSwift
import Foundation
import SKFoundation
import OfflineResourceManager

class PackageDownloadTaskGeckoImpl: PackageDownloadTask {
    private var status: Status = .initialization
    private let agent: TTGeckoAbility
    private let geckoConfig: GeckoBizConfig
    private weak var _delegate: PackageDownloadTaskDelegate?
    var delegate: PackageDownloadTaskDelegate? {
        _delegate
    }
    
    var isGrayscale: Bool {
        slimVersion == nil
    }
    
    private(set) var version: String
    
    private(set) var slimVersion: String?
    
    private(set) var downloadPath: SKFilePath
    
    private(set) var resourceInfo: GeckoPackageManager.FEResourceInfo?
    
    private let appVersion: String
    
    private let disposeBag = DisposeBag()
    
    private var retryCount = 0
    
    private static let maxRetryCount = 3
    
    private var downloadFullPkgTime: TimeInterval = 0
    
    /// 是否由解压内置精简包失败后触发
    var isForUnzipBundleSlimFailed = false
    
    
    /// 初始化方法，通过slimVersion决定是下完整包还是灰度包
    /// - Parameters:
    ///   - version: 资源包版本号
    ///   - resourceInfo: 当下载的是内嵌精简包指定完整包，需传精简包的FEResourceInfo。灰度包不用
    ///   - downloadPath: 资源包本地保存路径。期望是一个文件夹路径，如：xxx/xxx/fullPkgDownload/unzip,最终资源包将存放于xxx/xxx/fullPkgDownload/unzip/docs_channel/eesz
    ///   - agent: Gecko SDK的封装
    ///   - appVersion: 应用版本号
    ///   - delegate: 任务结果回调
    init?(version: String, resourceInfo: GeckoPackageManager.FEResourceInfo?, downloadPath: SKFilePath, agent: TTGeckoAbility, appVersion: String, delegate: PackageDownloadTaskDelegate? = nil) {
        self.resourceInfo = resourceInfo
        if let slimVersion = resourceInfo?.simplePkgInfo.version {
            if slimVersion.isEmpty {
                GeckoLogger.error("slim version is empty")
                spaceAssertionFailure()
                return nil
            }
            self.slimVersion = slimVersion
        }
        guard !version.isEmpty else {
            GeckoLogger.error("version is empty")
            spaceAssertionFailure()
            return nil
        }
        guard !downloadPath.isEmpty else {
            GeckoLogger.error("downloadPath is empty")
            spaceAssertionFailure()
            return nil
        }
        if !downloadPath.exists || !downloadPath.isDirectory {
            do {
                try downloadPath.createDirectoryIfNeeded(withIntermediateDirectories: true)
            } catch {
                GeckoLogger.debug("create directory fail, error:\(error)")
                spaceAssertionFailure()
                return nil
            }
        }
        self.version = version
        self.appVersion = appVersion
        self.downloadPath = downloadPath
        self.agent = agent
        _delegate = delegate
        if slimVersion == nil {
            geckoConfig = GeckoBizConfig(
                identifier: "ccm_web_grayscale_pkg",
                key: OpenAPI.DocsDebugEnv.geckoAccessKey,
                channel: "docs_gray_channel"
            )
        } else {
            geckoConfig = GeckoBizConfig(
                identifier: "ccm_web_full_pkg",
                key: OpenAPI.DocsDebugEnv.geckoAccessKey,
                channel: "docs_fullpkg_channel"
            )
        }
        agent.registerBiz(geckoConfig)
        RxNetworkMonitor.networkStatus(observerObj: self)
            .filter({ $0.isReachable })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.networkBecomeAvailable()
            })
            .disposed(by: disposeBag)
    }
    
    func start() {
        guard status == .initialization else {
            GeckoLogger.error("task has already started")
            return
        }
        innerDownload()
        recordDownloadFullPkgTime(isStart: true)
    }
    
    func cancel() {
        if status == .success || status == .failure || status == .cancel {
            GeckoLogger.error("task finished, no need to cancel")
            return
        }
        status = .cancel
        GeckoLogger.info("cancel task")
    }
    
    private func innerDownload() {
        status = .downloading
        if isGrayscale {
            GeckoLogger.info("start fetch grayscale pkg: version(\(version)), localPath:\(downloadPath), retry count:\(retryCount)")
            agent.fetchResource(
                by: geckoConfig.identifier,
                resourceVersion: appVersion,
                customParams: nil
            ) { [weak self] finish, result in
                self?.handleFetchResourceCallback(finish: finish, result: result)
            }
        } else {
            DocsLogger.info("start fetch full pkg: slim version(\(slimVersion)), full version(\(version), localPath:\(downloadPath.pathString), retry count:\(retryCount)")
            agent.fetchResource(
                by: geckoConfig.identifier,
                resourceVersion: appVersion,
                customParams: ["slim_res_version": slimVersion ?? ""]
            ) { [weak self] finish, result in
                self?.handleFetchResourceCallback(finish: finish, result: result)
            }
        }
    }
    
    private func handleFetchResourceCallback(finish: Bool, result: GeckoFetchResult) {
        guard status != .cancel else {
            DocsLogger.info("task has been canceled")
            return
        }
        let cacheStatus: OfflineResourceStatus = agent.resourceStatus(for: result.config.identifier)
        guard finish, result.isSuccess, cacheStatus == .ready else {
            GeckoLogger.info("gecko sdk did not pull pkg: \(result.config.identifier), finish:\(finish), isSuccess:\(result.isSuccess), cacheStatus:\(cacheStatus)")
            occurError(errorMsg: "PullPkgFail")
            return
        }
        guard checkVersion(result) else {
            GeckoLogger.error("version mismatch")
            occurError(errorMsg: "VersionMismatch")
            return
        }
        moveResult(result) { [weak self] success in
            guard let self = self else { return }
            guard success else {
                self.occurError(errorMsg: "MoveFileFail")
                return
            }
            GeckoLogger.info("download success")
            self.status = .success
            self.recordDownloadFullPkgTime(isStart: false, isSuccess: true)
            self.delegate?.onSuccess(task: self)
        }
    }
    
    private func checkVersion(_ result: GeckoFetchResult) -> Bool {
        guard let rootPath = agent.resourceRootFolderPath(identifier: geckoConfig.identifier) else {
            GeckoLogger.error("can't get gecko sdk cache path for:\(geckoConfig.identifier)")
            return false
        }
        let eeszPath = rootPath + "/eesz"
        guard let version = GeckoPackageManager.Folder.revision(in: SKFilePath(absPath: eeszPath)) else {
            GeckoLogger.error("can't get version field from \(eeszPath)")
            return false
        }
        GeckoLogger.info("request version:\(self.version), download version:\(version)")
        return self.version == version
    }
    private func moveResult(_ result: GeckoFetchResult, complete: @escaping (Bool) -> Void) {
        guard let rootPath = agent.resourceRootFolderPath(identifier: geckoConfig.identifier) else {
            GeckoLogger.error("can't get gecko sdk cache path for:\(geckoConfig.identifier)")
            complete(false)
            return
        }
        
        let targetFolder = GeckoPackageManager.shared.appendDocsChannel(to: downloadPath)
        DispatchQueue.global().async {
            if targetFolder.exists && targetFolder.isDirectory {
                do {
                    try targetFolder.removeItem()
                } catch {
                    GeckoLogger.error("remove \(targetFolder.pathString) fail:\(error)")
                    DispatchQueue.main.async { complete(false) }
                }
            }
            do {
                if let path = URL(string: rootPath) {
                    try targetFolder.copyItemFromUrl(from: path)
                } else {
                    GeckoLogger.error("gecko copyItemFromUrl fail:\(rootPath)")
                }
            } catch {
                GeckoLogger.error("move gecko cache to \(targetFolder) fail:\(error)")
                DispatchQueue.main.async { complete(false) }
            }
            DispatchQueue.main.async { complete(true) }
        }
    }
    
    private func recordDownloadFullPkgTime(isStart: Bool, isSuccess: Bool = false, errorMsg: String = "") {
        guard !isGrayscale else { return }
        
        let now = Date().timeIntervalSince1970
        if isStart {
            downloadFullPkgTime = now
        } else {
            let startTime = downloadFullPkgTime
            let diff = (now - startTime) * 1000 // ms
            downloadFullPkgTime = 0
            GeckoPackageManager.shared.logDownloadFullPkgTime(
                durationMS: diff,
                isSuccess: isSuccess,
                errorMsg: errorMsg,
                retryCount: 0,
                downloader: "gecko"
            )
        }
    }
    
    private func occurError(errorMsg: String) {
        if retryCount < PackageDownloadTaskGeckoImpl.maxRetryCount {
            if DocsNetStateMonitor.shared.isReachable {
                retryCount += 1
                innerDownload()
            } else {
                GeckoLogger.info("network unreachable, pend task")
                status = .pending
            }
        } else {
            status = .failure
            if let delegate = self.delegate {
                delegate.onFailure(task: self, errorMsg: errorMsg)
            }
            recordDownloadFullPkgTime(isStart: false, isSuccess: false, errorMsg: errorMsg)
        }
    }
    
    private func networkBecomeAvailable() {
        guard status == .pending else { return }
        
        GeckoLogger.info("network recover, retry task")
        retryCount += 1
        innerDownload()
    }
    
    enum Status {
        case initialization //任务刚创建，初始状态
        case downloading // 下载中
        case pending // 下载失败，重试前若网络不可用，进入挂起状态
        case success
        case failure
        case cancel
    }
}
