//
//  DriveDownloadService.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/23.
//
// nolint: long parameters

import Foundation
import EENavigator
import SKCommon
import SKFoundation
import RxSwift
import UniverseDesignToast
import SKResource
import UIKit
import SpaceInterface

protocol DriveDownloadServiceDependency {
    // 获取文件大小，用于判断是否需要弹流量提示
    var fileSize: UInt64 { get }
    // 所下载内容(可能是转码后的)的文件大小
    var downloadFileSize: UInt64 { get }
    // 下载路径
    var cacheURL: SKFilePath { get }
    // 下载类型： 源文件下载/预览文件下载
    var downloadType: DriveDownloadService.DownloadType { get }
    // 文件是否已经存在本地，Drive文件和DriveSDK文件的判断方式不同
    func isFileExsit() -> Bool
    // 将下载完成的文件移动到缓存目录
    func saveFile(completion: ((_ success: Bool) -> Void)?)
}

class DriveDownloadService: NSObject {
    enum DownloadType {
        case origin(fileMeta: DriveFileMeta) // 源文件下载
        case similar(fileMeta: DriveFileMeta) // 预览相似文件下载
        case preview(previewType: DrivePreviewFileType, previewURL: String) // 预览转码文件下载
    }

    enum DownloadStatus {
        case downloading(progress: Float)
        case success
        case failed(errorCode: String)
        case retryFetch(errorCode: String)
    }

    let callBack: ((DownloadStatus) -> Void)

    weak var hostContainer: UIViewController?
    /// 由于流量提醒而取消下载的回调
    var forbidDownload: (() -> Void)?
    var beginDownload: (() -> Void)?
    var skipCellularCheck: Bool

    var cacheStage: ((DriveStage) -> Void)?

    private var key: String?

    @ThreadSafe private var taskKeyResultMap = [String: Bool]()

    private let priority: DriveDownloadPriority
    private let apiType: DriveDownloadRequest.ApiType
    private let authExtra: String? // 第三方附件接入业务可以通过authExtra透传参数给业务后方进行鉴权，根据业务需要可选
    private var dependency: DriveDownloadServiceDependency
    private let workQueue = DispatchQueue(label: "com.docssdk.drive.downloadservice")
    private var bag = DisposeBag()
    
    private let netWorkFlowHelper = NetworkFlowHelper()

    private(set) var downloadStatus: DownloadStatus? {
        didSet {
            if let status = downloadStatus {
                if Thread.isMainThread {
                    self.callBack(status)
                } else {
                    DispatchQueue.main.async {
                        self.callBack(status)
                    }
                }
            }
        }
    }

    init(dependency: DriveDownloadServiceDependency,
         priority: DriveDownloadPriority,
         skipCellularCheck: Bool,
         apiType: DriveDownloadRequest.ApiType,
         authExtra: String?,
         callBack: @escaping ((DownloadStatus) -> Void)) {
        self.dependency = dependency
        self.callBack = callBack
        self.priority = priority
        self.skipCellularCheck = skipCellularCheck
        self.apiType = apiType
        self.authExtra = authExtra
        super.init()
        DriveDownloadCallbackService.shared.addObserver(self)
    }

    func reset(dependeny: DriveDownloadServiceDependency) {
        self.dependency = dependeny
    }

    /// 开始下载
    func start() {
        guard let fromVC = hostContainer else {
            spaceAssertionFailure("NetworkFlowHelper need from vc")
            return
        }

        /// 流量提醒条件： 能够获取文件大小 且 不处于wifi 且 文件大于50M 且 第一次提醒
        let size = dependency.fileSize
        netWorkFlowHelper.process(size, skipCheck: skipCellularCheck,
                                requestTask: { [weak self] in
                                    self?.workQueue.async {
                                        self?._start()
                                    }
                                },
                                judgeToast: { [weak self] in
                                    self?.judgeToast()
                                })
    }
    //判断Toast弹窗出现在当前view还是在window
    private func judgeToast() {
        guard let fromVC = hostContainer else {
            spaceAssertionFailure("NetworkFlowHelper need from vc")
            return
        }
        guard let window = fromVC.view.window else { return }
        if ifNeedShowInWindow(window: window) {
            netWorkFlowHelper.presentToast(view: window, fileSize: dependency.fileSize)
        } else {
            netWorkFlowHelper.presentToast(view: fromVC.view, fileSize: dependency.fileSize)
        }
    }
    //判断Toast是否需要弹到window
    private func ifNeedShowInWindow(window: UIWindow) -> Bool {
        if window.subviews.count > 0 {
            for view in window.subviews {
                if view.isKind(of: DriveLoadingAlertView.self) {
                    return true
                }
            }
        }
        return false
    }
    
    private func _start() {
        let downloadType = dependency.downloadType
        guard !dependency.isFileExsit() else {
            DocsLogger.debug("Drive.DownloadService --- File Cache Found.")
            downloadStatus = .success
            return
        }
        let downloadObserver: Observable<String>
        switch downloadType {
        case let .preview(_, previewURL):
            DocsLogger.driveInfo("downloadNormal preview, size: \(dependency.downloadFileSize)")
            downloadObserver = SpaceRustRouter.shared.downloadNormal(remoteUrl: previewURL,
                                                        localPath: dependency.cacheURL.pathString,
                                                        fileSize: String(dependency.downloadFileSize),
                                                        priority: priority,
                                                        authExtra: authExtra)
        case .origin(let fileMeta):
            let context = SpaceRustRouter.DownloadRequestContext(localPath: dependency.cacheURL.pathString,
                                                                 fileToken: fileMeta.fileToken,
                                                                 docToken: "",
                                                                 docType: nil,
                                                                 mountNodePoint: fileMeta.mountNodeToken,
                                                                 mountPoint: fileMeta.mountPoint,
                                                                 dataVersion: fileMeta.dataVersion,
                                                                 priority: priority,
                                                                 apiType: apiType,
                                                                 coverInfo: nil,
                                                                 authExtra: authExtra,
                                                                 disableCDN: false, teaParams: [:])
            let request = SpaceRustRouter.constructDownloadRequest(context: context)
            downloadObserver = SpaceRustRouter.shared.download(request: request)
        case .similar(let fileMeta):
            if let similarURL = fileMeta.downloadPreviewURL {
                DocsLogger.driveInfo("downloadNormal similar, size: \(dependency.downloadFileSize), apiType: \(apiType)")
                downloadObserver = SpaceRustRouter.shared.downloadNormal(remoteUrl: similarURL.absoluteString,
                                                            localPath: dependency.cacheURL.pathString,
                                                            fileSize: String(dependency.downloadFileSize),
                                                            priority: priority,
                                                            apiType: apiType,
                                                            authExtra: authExtra)
            } else {
                DocsLogger.driveInfo("download similar, apiType: \(apiType)")
                let context = SpaceRustRouter.DownloadRequestContext(localPath: dependency.cacheURL.pathString,
                                                                     fileToken: fileMeta.fileToken,
                                                                     docToken: "",
                                                                     docType: nil,
                                                                     mountNodePoint: fileMeta.mountNodeToken,
                                                                     mountPoint: fileMeta.mountPoint,
                                                                     dataVersion: fileMeta.dataVersion,
                                                                     priority: priority,
                                                                     apiType: apiType,
                                                                     coverInfo: nil,
                                                                     authExtra: authExtra,
                                                                     disableCDN: false, teaParams: [:])
                let request = SpaceRustRouter.constructDownloadRequest(context: context)
                downloadObserver = SpaceRustRouter.shared.download(request: request)
            }
            
        }
        downloadObserver.observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] key in
            self?.recordTaskStart(key: key)
            self?.beginDownload?()
        }).disposed(by: bag)
    }

    /// 停止下载
    func stop() {
        guard let cancelKey = key else {
            DocsLogger.debug("取消未成功")
            return
        }
        SpaceRustRouter.shared.cancelDownload(key: cancelKey).subscribe(onNext: { result in
            DocsLogger.driveInfo("cancelDownload result: \(result)")
        }).disposed(by: bag)
    }

    deinit {
        DocsLogger.debug("DriveDownloadService-----deinit")
        stop()
    }

    // 下载开始记录
    private func recordTaskStart(key: String?) {
        guard let taskKey = key else {
            DocsLogger.driveInfo("download task key is nil")
            return
        }
        DocsLogger.driveInfo("task start", extraInfo: ["key": taskKey])
        self.key = taskKey
        taskKeyResultMap[taskKey] = true
    }

    // 下载成功的回调可能会回调多次，只有第一次需要将文件从download目录移到cache目录
    // 后续的回调不需要处理
    private func taskSuccNeedCacheFile(key: String) -> Bool {
        guard taskKeyResultMap[key] != nil else {
            DocsLogger.driveInfo("task success, file has been cache, no need to move file again", extraInfo: ["key": key])
            return false
        }
        taskKeyResultMap[key] = nil
        return true
    }

    // 下载失败记录
    private func recordTaskFailed(key: String) {
        taskKeyResultMap[key] = nil
        DocsLogger.driveInfo("下载失败..", extraInfo: ["key": key])
    }
}

// MARK: - DriveDownloadCallbackDelegate
extension DriveDownloadService: DriveDownloadCallback {

    func onFailed(key: String, errorCode: Int) {
        guard key == self.key else {
            DocsLogger.error("key is error")
            return
        }
        recordTaskFailed(key: key)
        switch errorCode {
            // nolint-next-line: magic number
        case DocsNetworkError.HTTPStatusCode.BadRequest.rawValue: // 400错误 重新获取下载地址
            downloadStatus = .retryFetch(errorCode: String(errorCode))
        default:
            downloadStatus = .failed(errorCode: String(errorCode))
        }
    }

    func updateProgress(context: DriveDownloadContext) {
        let key = context.key
        guard key == self.key else {
            DocsLogger.error("Drive.DownloadService --- updateProgress key is error")
            return
        }
        switch context.status {
        case .failed, .cancel:
            recordTaskFailed(key: key)
        case .success:
            guard taskSuccNeedCacheFile(key: key) == true else {
                DocsLogger.error("Drive.DownloadService --- second succeed callback", extraInfo: ["key": key])
                return
            }
            downloadStatus = .downloading(progress: 1.0)
            guard dependency.cacheURL.exists else {
                downloadStatus = .failed(errorCode: "Rust downloaded file not existed")
                DocsLogger.error("Drive.DownloadService --- Rust downloaded file not existed", extraInfo: ["key": key])
                return
            }
            // 这里没有处理转存文件出错的情况，能够暂时避免了预加载文件和预览下载文件同时转存时，出现文件找不到错误。
            // cacheFile是异步过程，需要等保存完成后回调才设置为成功状态
            cacheFile { [weak self] in
                self?.downloadStatus = .success
                DocsTracker.reportDriveDownload(event: .driveDownloadFinishView,
                                                mountPoint: context.mountPoint,
                                                fileToken: context.fileToken,
                                                fileType: context.fileType)
            }

        case .ready, .inflight:
            downloadStatus = .downloading(progress: Float(context.bytesTransferred) / Float(context.bytesTotal))
        case .queue, .pending:
            DocsLogger.driveInfo("Drive.DownloadService --- inflight..")
        case .rangeFinish:
            break
        @unknown default:
            spaceAssertionFailure()
        }
    }
}

extension DriveDownloadService {

    private func cacheFile(completion: @escaping () -> Void) {
        cacheStage?(.begin)
        dependency.saveFile {[weak self] (isSuccess) in
            guard let self = self else { return }
            self.cacheStage?(.end)
            if !isSuccess {
                DocsLogger.error("failed to save file in cache!")
            }
            completion()
        }
    }
}
