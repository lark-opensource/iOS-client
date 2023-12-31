//
//  DriveUploadStatusManager.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/3/11.
//

import Foundation
import EENavigator
import RxSwift
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import SpaceInterface
import SKInfra

final class DriveUploadStatusManager: DriveMultipDelegates, DriveUploadStatusManagerBase {

    private static func viewControllerForDriveUploadTips() -> UIViewController? {
        // nolint-next-line: magic number
        guard #available(iOS 13.0, *) else {
            let topVC = UIApplication.shared.delegate?.window?.map { $0 }?.rootViewController
            return topVC?.presentedViewController ?? topVC
        }
        if let activeScene = UIApplication.shared.windowApplicationScenes.first(where: {
            $0.activationState == .foregroundActive && $0.isKind(of: UIWindowScene.self)
        }),
        let windowScene = activeScene as? UIWindowScene,
        let delegate = windowScene.delegate as? UIWindowSceneDelegate {
            let topVC = delegate.window?.map { $0 }?.rootViewController
            return topVC?.presentedViewController ?? topVC
        }
        let topVC = UIApplication.shared.delegate?.window?.map { $0 }?.rootViewController
        return topVC?.presentedViewController ?? topVC
    }

    /// 查询结果
    ///
    /// - waitingUpload: 等待上传中
    /// - uploading: 正在上传
    /// - uploadCompleted: 上传完成，不存在失败
    /// - finished: 上传完成 存在失败文件
    /// - failedCount: 上传失败个数
    /// - noFileOnUpload: 没有文件在上传
    enum UploadResult {
        case waitingUpload(Int, Double)
        case uploading(Int, Int, Double)
        case uploadCompleted
        case finished(Int)
        case failedCount(Int)
        case noFileOnUpload
    }

    static let shared = DriveUploadStatusManager()
    private var disposeBag = DisposeBag()

    @ThreadSafe private var lastFileStatus: [String: DriveUploadCallbackStatus] = [:]
    @ThreadSafe private(set) var uploadingCount: Int = 0

    override func addObserver(_ delegate: AnyObject) {
        super.addObserver(delegate)

        if delegate as? DriveUploadStatusUpdator != nil {
            SpaceRustRouter.shared.driveInitFinishObservable
                .subscribe(onNext: { [weak self, weak delegate] (ready) in
                    // DriveUploadStatusUpdator 这个协议没有要求实现对象是 class，无法直接 weak observer，所以只能放在闭包内进行类型转换避免内存泄漏
                    guard let `self` = self, let observer = delegate as? DriveUploadStatusUpdator else { return }
                    if ready {
                        self.refreshUploadStatus(observer)
                    }
                }).disposed(by: disposeBag)
        }
    }

    /// 分发事件给代理 需在主线程执行
    ///
    /// - Parameters:
    ///   - delegate: 代理
    ///   - status: 上传状态
    private func dispatch(delegate: DriveUploadStatusUpdator, status: UploadResult) {
        DocsLogger.driveInfo("dispatch action", extraInfo: ["delegate": delegate.mountToken.encryptToken,
                                                       "status": status])

        switch status {
        case let .uploading(reminder, total, progress):
            delegate.onExistUploadingFile()
            delegate.onUpdateProgress(progress, reminder: reminder, total: total)
        case .uploadCompleted:
            delegate.onExistUploadingFile()
            delegate.onAllUploadTaskCompletedNoError(progress: 1.0)
        case .noFileOnUpload:
            delegate.onNoExistUploadingFile()
        case let .failedCount(count):
            delegate.onUploadFailedCount(count: count)
        case let .waitingUpload(reminder, progress):
            delegate.onWaitingUpload(progress, reminder: reminder)
        case let .finished(count):
            delegate.onExistUploadingFile()
            delegate.onUploadFinishedExistError(progress: 1.0, errorCount: count)
        }
    }

    /// 通知代理
    ///
    /// - Parameters:
    ///   - delegate: 代理
    private func refreshUploadStatus(_ delegate: DriveUploadStatusUpdator) {
        DocsLogger.driveInfo("refreshUploadStatus", extraInfo: ["delegate": delegate.mountToken.encryptToken])
        let scene = delegate.scene
        // 下面是异步操作
        self.getUploadStatus(mountNodePoint: delegate.mountToken,
                             scene: scene,
                             forProgress: false,
                             isUploading: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] uploadStatus in
                guard let self = self else { return }
                guard let status = uploadStatus else {
                    DocsLogger.driveInfo("No upload Status")
                    return
                }
                self.dispatch(delegate: delegate, status: status)
            }).disposed(by: disposeBag)
    }

    /// Rust回调updateProgress时通知代理
    ///
    /// - Parameters:
    ///   - delegate: 代理
    ///   - key: 上传文件key
    ///   - status: 上传文件status
    ///   - callback: 通知完成回调
    private func notifyDelegate(_ delegate: DriveUploadStatusUpdator,
                                key: String,
                                status: DriveUploadCallbackStatus) {
        let scene = delegate.scene
        let shouldShowUploading = shouldShowUploadingStatus(status)
        self.getUploadStatus(mountNodePoint: delegate.mountToken,
                             scene: scene,
                             forProgress: true,
                             isUploading: shouldShowUploading)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] uploadStatus in
                guard let self = self else { return }
                guard let status = uploadStatus else {
                    DocsLogger.driveInfo("No upload Status")
                    return
                }
                self.dispatch(delegate: delegate, status: status)
            }).disposed(by: disposeBag)
    }

    /// 获取上传状态
    ///
    /// - Parameters:
    ///   - mountNodePoint: 文件夹token
    ///   - forProgress: 是否是更新进度回调
    ///   - isInFlight: 是否正在上传中
    ///   - result: 返回状态、进度、剩余数量
    private func getUploadStatus(mountNodePoint: String, scene: DriveUploadScene, forProgress: Bool, isUploading: Bool) -> Observable<UploadResult?> {
        return SpaceRustRouter.shared.uploadList(mountNodePoint: mountNodePoint, scene: scene, forProgress: true)
            .map({ [weak self] (files) -> UploadResult? in
            guard let self = self else { return nil }
                DocsLogger.driveInfo("getUploadStatus", extraInfo: ["mountNodePoint": "\(mountNodePoint.encryptToken)",
                                                           "forProgress": forProgress,
                                                           "isUploading": isUploading,
                                                           "filesCount": files.count,
                                                           "scene": scene])
            let failed = files.filter({$0.status == DriveUploadCallbackStatus.failed.rawValue
                                    || $0.status == DriveUploadCallbackStatus.cancel.rawValue})      /// 上传失败
            let success = files.filter({ $0.status == DriveUploadCallbackStatus.success.rawValue })   /// 上传成功
            let pending = files.filter({$0.status == DriveUploadCallbackStatus.pending.rawValue
                                    || $0.status == DriveUploadCallbackStatus.queue.rawValue})  /// 等待上传中
            let inFlight = files.filter({$0.status == DriveUploadCallbackStatus.inflight.rawValue
                                    || $0.status == DriveUploadCallbackStatus.ready.rawValue})  /// 正在上传中
            let total = pending.count + inFlight.count + success.count

            DocsLogger.driveInfo("getUploadStatus -- uploading file", extraInfo: ["failed": failed.count,
                                                                             "pending": pending.count,
                                                                             "inFlight": inFlight.count,
                                                                             "success": success.count])
            // ref - https://jira.bytedance.com/browse/CDRIVE-2915
            // 判断是否有文件上传任务再发送Rust恢复、暂停请求
            if mountNodePoint == SpaceRustRouter.mainMountPointToken {
                self.uploadingCount = pending.count + inFlight.count
            }

            if !files.isEmpty { /// 存在上传文件
                if isUploading {
                    let totalCount = files.count - failed.count
                    var progress: Double = 0.0
                    if totalCount > 0 {
                        progress = Double(success.count) / Double(totalCount)
                    }
                    return .uploading(totalCount - success.count, totalCount, progress)
                }

                if !pending.isEmpty || !inFlight.isEmpty { /// 存在正在上传的文件
                    let progress = Double(success.count) / Double(total)
                    return .uploading(total - success.count, total, progress)
                } else { /// 不存在正在上传的文件
                    if !failed.isEmpty {
                        return forProgress ? .finished(failed.count) : .failedCount(failed.count)
                    }
                    return .uploadCompleted
                }
            } else {
                DocsLogger.driveInfo("getUploadStatus -- no uploading file")
                return forProgress ? .uploadCompleted : .noFileOnUpload
            }
        })
    }

    private func shouldShowUploadingStatus(_ status: DriveUploadCallbackStatus) -> Bool {
        switch status {
        case .queue, .pending, .ready, .inflight: return true
        @unknown default: return false
        }
    }
}

// MARK: - DriveUploadCallback
extension DriveUploadStatusManager: DriveUploadCallback {

    func updateProgress(context: DriveUploadContext) {
        let mountPoint = context.mountPoint
        let status = context.status
        let key = context.key
        DocsLogger.debug("Rust update upload status: \(status) mountNodePoint: \(DocsTracker.encrypt(id: context.mountNodePoint)) key: \(key),mountpoint: \(mountPoint)")
        guard mountPoint == DriveConstants.driveMountPoint
                || mountPoint == DriveConstants.wikiMountPoint
                || mountPoint == DriveConstants.workspaceMountPoint else {
            DocsLogger.warning("no need to handle", extraInfo: ["mountPoint": mountPoint])
            return
        }

        // 只过滤 inflight 重复的状态，避免 cancel 等其它状态没有更新(比如退到后台或者手动取消都是 cancel 状态)
        guard lastFileStatus[key] != status || status != .inflight else {
            DocsLogger.debug("File status is not changed key : \(key)")
            return
        }
        lastFileStatus[key] = status
        self.invoke { (delegate: DriveUploadStatusUpdator) in
            let delegateNodePoint = delegate.mountToken
            let curScene = delegate.scene
            guard delegateNodePoint == context.mountNodePoint || delegateNodePoint == SpaceRustRouter.mainMountPointToken else {
                // mountPoint 不匹配
                return
            }
            guard curScene == context.scene || curScene == .workspace else {
                // scene 不匹配
                return
            }
            if status == .success {
                delegate.onUploadedFile(fileToken: context.fileToken,
                                        moutNodePoint: context.mountNodePoint,
                                        nodeToken: context.nodeToken)
            }
            self.notifyDelegate(delegate,
                                key: key,
                                status: status)
        }
    }

    func onFailed(key: String, mountPoint: String, scene: DriveUploadScene, errorCode: Int, fileSize: Int64) {
        // 文件审核不通过
        if errorCode == DriveFileInfoErrorCode.auditFailureInUploadError.rawValue {
            if let hostView = Self.viewControllerForDriveUploadTips()?.view {
                DispatchQueue.main.async {
                    UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_UploadFailByPolicy(),
                                           on: hostView)
                }
            }
        } else if errorCode == FileUploaderErrorCode.mountPointCountLimited.rawValue {
            // 上层会多级目录进行监听，只能统一处理弹框逻辑
            DispatchQueue.main.async {
                self.showMountPointCountLimitedAlertIfNeeded()
            }
        } else {
            self.invoke { (delegate: DriveUploadStatusUpdator) in
                DispatchQueue.main.async {
                    let delegateNodePoint = delegate.mountToken
                    // 通知上层业务，一般是文件夹
                    self.showQuotaAlertIfNeed(mountPoint: mountPoint, errorCode: errorCode, fileSize: fileSize)
                    if delegateNodePoint != SpaceRustRouter.mainMountPointToken {
                        delegate.onUploadError(mountNodePoint: delegateNodePoint,
                                               key: key,
                                               errorCode: errorCode)
                    }
                }
            }
        }
    }

    func showMountPointCountLimitedAlertIfNeeded() {
        guard !isCountLimitedAlertShowed else {
            DocsLogger.driveInfo("already showed limited alert")
            return
        }

        guard let viewController = Self.viewControllerForDriveUploadTips() else {
            DocsLogger.error("failed to show limited alert, unable to get actived view controller")
            assertionFailure()
            return
        }
        showMountPointCountLimitedAlert(from: viewController)
    }
    
    func showQuotaAlertIfNeed(mountPoint: String, errorCode: Int, fileSize: Int64) {
        // 只有上传云空间的错误才会弹出超限弹窗
        guard mountPoint == DriveConstants.driveMountPoint || mountPoint == DriveConstants.wikiMountPoint  else {
            DocsLogger.driveInfo("only proccess space upload error")
            return
        }
        guard let from = Self.viewControllerForDriveUploadTips() else {
            DocsLogger.error("no from vc")
            return
        }
        if errorCode == DocsNetworkError.Code.uploadLimited.rawValue {
            if QuotaAlertPresentor.shared.enableTenantQuota {
                QuotaAlertPresentor.shared.showQuotaAlert(type: .upload, from: from)
            } else {
                DocsLogger.driveInfo("enableTenantQuota is false")
            }
        } else if errorCode == DocsNetworkError.Code.rustUserUploadLimited.rawValue {
            if QuotaAlertPresentor.shared.enableUserQuota {
                QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil, mountPoint: nil, from: from)
            } else {
                DocsLogger.driveInfo("enableUserQuota is false")
            }
        } else if errorCode == FileUploaderErrorCode.fileSizeLimited.rawValue {
            guard SettingConfig.sizeLimitEnable else { return }
            QuotaAlertPresentor.shared.showUserUploadAlert(mountNodeToken: nil, mountPoint: nil, from: from, fileSize: fileSize, quotaType: .bigFileUpload)
        }
    }

    private func showMountPointCountLimitedAlert(from viewController: UIViewController) {
        isCountLimitedAlertShowed = true
       let alert = UIAlertController(title: nil,
                                     message: BundleI18n.SKResource.Drive_Drive_MountNodeOutOfLimit,
                                     preferredStyle: .alert)
       let confirm = UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_Sure,
                                   style: .default) { _ in
                        self.isCountLimitedAlertShowed = false
       }

       alert.addAction(confirm)
       Navigator.shared.present(alert, from: viewController)
        DocsLogger.driveInfo("show limited alert: \(String(describing: mount))")
    }

    private struct AssociatedKeys {
        static var isCountLimitedAlertShowed = "isCountLimitedAlertShowed"
    }

    /// 是否已经显示过提示
    var isCountLimitedAlertShowed: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isCountLimitedAlertShowed) as? Bool ?? false
        }
        set {
            synchronized(self) {
                 objc_setAssociatedObject(self,
                                          &AssociatedKeys.isCountLimitedAlertShowed,
                                          newValue,
                                          .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
