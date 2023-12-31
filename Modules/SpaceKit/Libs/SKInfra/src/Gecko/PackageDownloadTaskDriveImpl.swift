//
//  GeckoPackageDownloadTask.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/4/29.
//  


import SKFoundation
import RxSwift
import SKInfra
import SpaceInterface

/// 前端资源包下载任务类
class PackageDownloadTaskDriveImpl: PackageDownloadTask {
    let isGrayscale: Bool
    let downloadPath: SKFilePath
    let version: String
    let resourceInfo: GeckoPackageManager.FEResourceInfo?
    private(set) var requestKey: String?
    private(set) var status: Status = .initialization
    private(set) var retryCount: Int = 0
    /// 是否由解压内置精简包失败后触发
    var isForUnzipBundleSlimFailed = false
    private weak var _delegate: PackageDownloadTaskDelegate?
    var delegate: PackageDownloadTaskDelegate? {
        _delegate
    }
    private let disposeBag = DisposeBag()
    private let urlString: String
    private var downloadFullPkgTime: TimeInterval = 0
    private static let maxRetryCount = 3
    private static let driveCommonErrorCode = -1
    
    /// 初始化方法,当前用于下载内嵌精简包指定完整包、灰度包
    /// - Parameters:
    ///   - urlString: 资源包url
    ///   - downloadPath: 资源包本地保存路径
    ///   - version: 资源包版本号
    ///   - isGrayscale: 是否为灰度包下载
    ///   - delegate: 任务结果回调
    ///   - resourceInfo: 当下载的是内嵌精简包指定完整包，需传精简包的FEResourceInfo。灰度包不用
    init?(urlString: String,
          downloadPath: SKFilePath,
          version: String,
          isGrayscale: Bool = false,
          delegate: PackageDownloadTaskDelegate? = nil,
          resourceInfo: GeckoPackageManager.FEResourceInfo? = nil) {
        guard !version.isEmpty else {
            GeckoLogger.error("资源包的版本不可为空字符串")
            assertionFailure()
            return nil
        }
        guard !downloadPath.isEmpty else {
            GeckoLogger.error("要下载的目标本地地址为空")
            assertionFailure()
            return nil
        }
        
        //TODO: huangzhikai 看下这里用 deletingLastPathComponent 跟 folderPath效果是否一致
        let temp = downloadPath.pathString.folderPath()
        let folderPath = downloadPath.deletingLastPathComponent
        guard !folderPath.isEmpty else {
            GeckoLogger.error("要下载的目标本地地址文件夹为空")
            assertionFailure()
            return nil
        }
        if !folderPath.exists || !folderPath.isDirectory {
            do {
                try folderPath.createDirectoryIfNeeded(withIntermediateDirectories: true)
            } catch {
                GeckoLogger.debug("创建本地文件夹失败, error:\(error)")
                return nil
            }
        }
        guard !urlString.isEmpty else {
            GeckoLogger.error("要下载的目标完整包url为空")
            assertionFailure()
            return nil
        }
        
        self.urlString = urlString
        self.downloadPath = downloadPath
        self.version = version
        self.isGrayscale = isGrayscale
        _delegate = delegate
        self.resourceInfo = resourceInfo
        RxNetworkMonitor.networkStatus(observerObj: self)
            .filter({ $0.isReachable })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.networkBecomeAvailable()
            })
            .disposed(by: disposeBag)
    }
    
    /// 开始执行下载任务
    func start() {
        guard status == .initialization else {
            GeckoLogger.error("任务已启动过")
            return
        }
        
        status = .waiting
        // 需要等Drive初始化好rust组件
        DocsContainer.shared.resolve(DriveRustRouterBase.self)?
            .driveInitFinishObservable
            .asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .filter({ $0 })
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.innerDownload()
            })
            .disposed(by: disposeBag)
        recordDownloadFullPkgTime(isStart: true)
    }
    
    /// 取消下载任务
    func cancel() {
        if status == .success || status == .failure || status == .cancel {
            GeckoLogger.error("已经有结果或已经取消过的任务，不必再取消")
            return
        }
        if status == .downloading, let requestKey = requestKey, let driveRustRouter = DocsContainer.shared.resolve(DriveRustRouterBase.self) {
            _ = driveRustRouter.cancelDownload(key: requestKey)
        }
        status = .cancel
        GeckoLogger.info("任务取消")
    }
    
    private func innerDownload() {
        GeckoLogger.info("开始下载 from:\(urlString) to localPath:\(downloadPath), retry count:\(retryCount)")
        
        status = .downloading
        let driveRustRouter = DocsContainer.shared.resolve(DriveRustRouterBase.self)
        driveRustRouter?.downloadNormal(remoteUrl: urlString,
                                        localPath: downloadPath.pathString,
                                        fileSize: nil,
                                        slice: true,
                                        priority: .userInteraction)
            .subscribe(onNext: {[weak self] key in
                guard let self = self else { return }
                guard !key.isEmpty, key != String(Self.driveCommonErrorCode) else {
                    GeckoLogger.error("发起下载请求时失败了，key:\(key)")
                    self.occurError(errorCode: Self.driveCommonErrorCode)
                    return
                }
                self.requestKey = key
                GeckoLogger.info("download type:\(self.isGrayscale ? "grayscale" : "full") package, reuqestkey is: \(key))")
                DocsContainer.shared.resolve(DriveDownloadCallbackServiceBase.self)?.addObserver(self)
            })
            .disposed(by: disposeBag)
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
                retryCount: retryCount,
                downloader: "rust"
            )
        }
    }
    
    private func networkBecomeAvailable() {
        guard status == .pending else { return }
        
        GeckoLogger.info("网络恢复，开始重试")
        retryCount += 1
        innerDownload()
    }
    
    private func occurError(errorCode: Int) {
        if retryCount < PackageDownloadTaskDriveImpl.maxRetryCount {
            if DocsNetStateMonitor.shared.isReachable {
                retryCount += 1
                innerDownload()
            } else {
                GeckoLogger.info("网络不可用，挂起任务")
                status = .pending
            }
        } else {
            status = .failure
            if let delegate = self.delegate {
                let msg = "errorCode:\(errorCode)，key:\(String(describing: self.requestKey))"
                delegate.onFailure(task: self, errorMsg: msg)
            }
            recordDownloadFullPkgTime(isStart: false, isSuccess: false, errorMsg: "\(errorCode)")
        }
    }
    
    enum Status {
        case initialization //任务刚创建，初始状态
        case waiting // 等待Drive初始化好rust组件
        case downloading // 下载中
        case pending // 下载失败，重试前若网络不可用，进入挂起状态
        case success
        case failure
        case cancel
    }
}

//protocol GeckoPackageDownloadTaskDelegate: AnyObject {
//    
//    /// 任务成功回调
//    /// - Parameter task: 下载任务
//    func onSuccess(task: PackageDownloadTaskDriveImpl)
//    
//    /// 任务失败回调
//    /// - Parameters:
//    ///   - task: 下载任务
//    ///   - errorCode: 错误码。常见错误码：1007网络不可用，1005请求错误，1002超时 https://bytedance.feishu.cn/docs/doccnPv5NHZelDU67B7skU
//    func onFailure(task: PackageDownloadTaskDriveImpl, errorCode: Int)
//}

extension PackageDownloadTaskDriveImpl: DriveDownloadCallback {
    // MARK: - 下载成功的回调
    public func updateProgress(context: DriveDownloadContext) {
        // 过滤掉progress等，只保留成功的回调, 失败的回调在onFailed方法中处理
        guard context.key == self.requestKey else { return }
        GeckoLogger.info("download progress: \(context.bytesTransferred)/\(context.bytesTotal)")
        guard context.status == .success else { return }
        guard self.status != .success else {
            GeckoLogger.info("下载成功后重复回调了")
            return
        }
        
        self.status = .success
        GeckoLogger.info("下载成功")
        recordDownloadFullPkgTime(isStart: false, isSuccess: true)
        if let delegate = self.delegate {
            DispatchQueue.global().async { delegate.onSuccess(task: self) }
        }
    }
    // MARK: - 下载失败的回调
    public func onFailed(key: String, errorCode: Int) {
        guard key == self.requestKey else { return }
        guard self.status != .failure else {
            GeckoLogger.info("下载失败后重复回调了")
            return
        }
        
        GeckoLogger.error("下载失败, request key:\(key), errorCode:\(errorCode)")
        
        occurError(errorCode: errorCode)
    }
}

extension String {
    // eg. "/a/b/c.zip" -> "/a/b"
    func folderPath() -> String? {
        guard !isEmpty else { return nil }
        guard let lastSlashIndex = lastIndex(of: "/") else { return nil }
        return String(self[..<lastSlashIndex])
    }
}
