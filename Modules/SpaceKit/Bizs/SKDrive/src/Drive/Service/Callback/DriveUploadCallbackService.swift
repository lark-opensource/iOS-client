//
//  DriveUploadCallbackService.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/2/26.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import SpaceInterface

// MARK: - 处理分发上传回调Service
final class DriveUploadCallbackService: DriveMultipDelegates, DriveUploadCallbackServiceBase {
    private var bag = DisposeBag()
    static let shared = DriveUploadCallbackService()
    private var isReachable = DocsNetStateMonitor.shared.isReachable {
        didSet {
            /// 避免反复切换网络 确定网络可达发生变化之后再进行操作
            if isReachable != oldValue {
                if isReachable {
                    // 只有在前台才恢复上传，提高后台上传成功率
                    guard UIApplication.shared.applicationState != .background else {
                        DocsLogger.driveInfo("does not resumeAllTask when app in background")
                        return
                    }
                    resumeUploadTasks(delay: 1)
                    DocsLogger.driveInfo("resumeAllTask with netwrok")
                } else {
                    pauseUploadTasks(delay: 1)
                    DocsLogger.driveInfo("pauseAllTask without netwrok")
                }
            }
        }
    }
    
    // 标记上传成功后，拷贝到缓存目录而非移动的 Keys
    @ThreadSafe private var uploadSuccessCopyInsteadOfMoveKeys = Set<String>()

    override init() {
        super.init()
        setupNetworkMonitor()
    }

    public func addToUploadSuccessCopyInsteadOfMove(key: String) {
        uploadSuccessCopyInsteadOfMoveKeys.insert(key)
    }
    
    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { (networkType, isReachable) in
            DocsLogger.driveInfo("Current networkType info, networkType: \(networkType), isReachable: \(isReachable)")
            DispatchQueue.main.async { // 监听网络变化的对象比较多，避免在同一个runloop执行操作卡顿
                self.isReachable = isReachable
            }
        }
    }
    
    // 后台队列线程delay 3秒调用，避免cpu占用导致lark卡顿问题
    private func resumeUploadTasks(delay: TimeInterval) {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delay) {
            SpaceRustRouter.shared.resumeAllUploadTask().subscribe().disposed(by: self.bag)
        }
    }

    private func pauseUploadTasks(delay: TimeInterval) {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delay) {
            guard DriveUploadStatusManager.shared.uploadingCount != 0 else {
                DocsLogger.driveInfo("no need to pauseUploadTasks", extraInfo: ["delay": delay])
                return
            }
            SpaceRustRouter.shared.pauseAllUploadTask().subscribe().disposed(by: self.bag)
        }
    }
}

// MARK: - 上传回调
extension DriveUploadCallbackService: DriveUploadCallback {

    /// 失败回调
    ///
    /// - Parameters:
    ///   - key: 失败的文件key
    ///   - errorCode: 错误码
    /// - Returns:
    func onFailed(key: String, mountPoint: String, scene: DriveUploadScene, errorCode: Int, fileSize: Int64) {
        DocsLogger.warning("Rust upload failed", extraInfo: ["key": key, "errorCode": errorCode])
        uploadSuccessCopyInsteadOfMoveKeys.remove(key)
        cleanUploadCacheFileIfNeeded(key: key, errorCode: errorCode)
        DriveUploadStatusManager.shared.onFailed(key: key, mountPoint: mountPoint, scene: scene, errorCode: errorCode, fileSize: fileSize)
        invoke({ (delegate: DriveUploadCallback) in
            DispatchQueue.main.async {
                delegate.onFailed(key: key, mountPoint: mountPoint, scene: scene, errorCode: errorCode, fileSize: fileSize)
            }
        })
    }

    /// 文件上传回调
    ///
    /// - Parameters:
    ///   - key: 文件key
    ///   - status: 状态
    ///   - bytesTransferred: 已经传输的大小
    ///   - bytesTotal: 总大小
    ///   - filePath: 上传文件路径
    ///   - token: 上传完成会返回文件token 用于移动文件至缓存文件夹
    ///   - mountNodePoint: 对应文件夹的token
    /// - Returns:
    func updateProgress(context: DriveUploadContext) {
        DocsLogger.debug("update_progress - status: \(context.status), bytesTransferred: \(context.bytesTransferred), bytesTotal: \(context.bytesTotal), mountpoint: \(context.mountPoint)")
        DriveUploadStatusManager.shared.updateProgress(context: context)
        invoke({ (delegate: DriveUploadCallback) in
            DispatchQueue.main.async {
                delegate.updateProgress(context: context)
            }
        })
        // 如果上传成功 并且返回了文件token 则将原文件移动至缓存文件夹
        if context.status == .success,
           !context.filePath.isEmpty,
           !context.fileToken.isEmpty {
            let moveInsteadOfCopy = !uploadSuccessCopyInsteadOfMoveKeys.contains(context.key)
            uploadSuccessCopyInsteadOfMoveKeys.remove(context.key)
            // 上传后可以使用缓存预览
            let newPath: SKFilePath
            if let isoPath = try? SKFilePath.parse(path: context.filePath) {
                newPath = isoPath
            } else {
                DocsLogger.driveInfo("parse from rust path failed")
                newPath = SKFilePath(absPath: context.filePath)
            }
            let size = newPath.fileSize
            let basicInfo = DriveCacheServiceBasicInfo(cacheType: .similar,
                                                       source: .standard,
                                                       token: context.fileToken,
                                                       fileName: context.fileName,
                                                       fileType: SKFilePath.getFileExtension(from: context.fileName),
                                                       dataVersion: context.dataVersion,
                                                       originFileSize: size)
            let saveContext = SaveFileContext(filePath: newPath,
                                              moveInsteadOfCopy: moveInsteadOfCopy,
                                              basicInfo: basicInfo,
                                              rewriteFileName: false)

            DriveCacheService.shared.saveDriveFile(context: saveContext, completion: nil)
            
            // Drive业务埋点：文件上传结果
            DriveStatistic.clientContentManagement(action: DriveStatisticAction.driveUploadResult,
                                                   fileId: context.fileToken,
                                                   additionalParameters: ["dummy_token": context.key, "status": "success"])
            DocsTracker.reportDriveUploadFinish(mountPoint: context.mountPoint,
                                                isSuccess: true,
                                                fileToken: context.fileToken,
                                                fileName: context.fileName)
        } else if context.status == .failed {
            uploadSuccessCopyInsteadOfMoveKeys.remove(context.key)
            // Drive业务埋点：文件上传结果
            DriveStatistic.clientContentManagement(action: DriveStatisticAction.driveUploadResult,
                                                   fileId: context.fileToken,
                                                   additionalParameters: ["dummy_token": context.key, "status": "failed"])
            DocsTracker.reportDriveUploadFinish(mountPoint: context.mountPoint,
                                                isSuccess: false,
                                                fileToken: context.fileToken,
                                                fileName: context.fileName)
        }
    }

    private func cleanUploadCacheFileIfNeeded(key: String, errorCode: Int) {
        guard let errorCode = FileUploaderErrorCode(rawValue: errorCode) else {
            DocsLogger.error("Can not cast error code to FileUploaderErrorCode")
            return
        }
        /// 如果失败可重试，不处理
        guard !errorCode.canRetry else {
            DocsLogger.driveInfo("can retry, errcode: \(errorCode)")
            return
        }
        /// 不可重试，删除缓存文件
        SpaceRustRouter.shared.getUploadFileData(key: key).subscribe(onNext: {[weak self] uploadFile in
            guard let self = self else { return }
            guard let file = uploadFile else {
                DocsLogger.error("Can not get file data by key \(key)")
                return
            }
            let filePath = file.path
            guard !filePath.isEmpty else {
                DocsLogger.driveInfo("filePath is empty, filePath: \(filePath)")
                return
            }
            self.safeDelete(path: filePath)
            DocsLogger.driveInfo("this file was deleted, path: \(filePath)")

        }).disposed(by: bag)
    }

    func safeDelete(path: String) {
        guard !path.isEmpty else {
            DocsLogger.driveInfo("path is empty, path: \(path)")
            return
        }
        guard let path = try? SKFilePath.parse(path: path) else {
            DocsLogger.driveInfo("parse path from rust failed")
            return
        }
        do {
            try path.removeItem()
            DocsLogger.driveInfo("This file was deleted! --- path: \(path)")
        } catch {
            DocsLogger.error("remove file path failed", error: error)
        }
    }
}
