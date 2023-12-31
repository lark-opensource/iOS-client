//
//  SpaceListDriveUploadHelper.swift
//  SKECM
//
//  Created by Weston Wu on 2021/4/16.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxRelay
import SwiftyJSON
import SKInfra
import SpaceInterface

public final class SpaceListDriveUploadHelper: DriveUploadStatusUpdator {
    private var bag = DisposeBag()
    public let mountToken: String
    public let mountPoint: String
    public let scene: DriveUploadScene
    // 打 log 用
    let identifier: String
    public let driveListConfig = DriveListConfig()

    // 上传状态变化，UI 需要更新
    private let uploadStateInput = PublishRelay<Void>()
    public var uploadStateChanged: Observable<Void> {
        uploadStateInput.asObservable()
    }

    // 文件上传完成，部分列表需要拉取更新，提供回调
    private let fileUploadedInput = PublishRelay<Void>()
    public let fileDidUploaded: Observable<Void>
    
    // 通知监听者有文件上传结束，成功为true，失败为false
    private let fileUploadFinishSuccessInput = PublishRelay<Bool>()
    public var fileUploadFinishSuccess: Observable<Bool> {
        return fileUploadFinishSuccessInput.asObservable()
    }

    public init(mountToken: String, mountPoint: String, scene: DriveUploadScene, identifier: String) {
        self.mountToken = mountToken
        self.mountPoint = mountPoint
        self.scene = scene
        self.identifier = identifier
        fileDidUploaded = fileUploadedInput.asObservable().delay(.seconds(5), scheduler: MainScheduler.instance)
    }

    public func setup() {
        DocsContainer.shared.resolve(DriveUploadStatusManagerBase.self)?.addObserver(self)
    }

    /// 存在未上传的文件
    public func onExistUploadingFile() {
        guard !driveListConfig.isNeedUploading else { return }
        driveListConfig.renew()
        DocsLogger.info("[Drive Upload] onExistUploadingFile",
                        extraInfo: ["identifier": identifier])
        uploadStateInput.accept(())
    }

    /// 等待上传中
    ///
    /// - Parameters:
    ///   - progress: 进度
    ///   - reminder: 剩余文件数量
    public func onWaitingUpload(_ progress: Double, reminder: Int) {
        driveListConfig.update(progress: progress, total: nil, reminder: reminder)
        DocsLogger.info("[Drive Upload] onWaitingUpload",
                        extraInfo: ["identifier": identifier])
        uploadStateInput.accept(())
    }

    /// 上传中更新进度
    ///
    /// - Parameters:
    ///   - progress: 进度
    ///   - reminder: 剩余文件数量
    public func onUpdateProgress(_ progress: Double, reminder: Int, total: Int) {
        driveListConfig.update(progress: progress, total: total, reminder: reminder)
        DocsLogger.info("[Drive Upload] onUpdateProgress",
                        extraInfo: ["identifier": identifier, "reminder": reminder])
        uploadStateInput.accept(())
    }

    /// 所有任务上传完成没有失败项
    ///
    /// - Parameter progress: 进度为1.0
    public func onAllUploadTaskCompletedNoError(progress: Double) {
        driveListConfig.update(progress: progress, total: nil, reminder: nil)
        DocsLogger.info("[Drive Upload] onAllUploadTaskCompletedNoError",
                        extraInfo: ["identifier": identifier])
        // 要先展示进度完成，再隐藏
        driveListConfig.finished()
        uploadStateInput.accept(())
        fileUploadedInput.accept(())
    }

    /// 上传完成但存在失败文件
    ///
    /// - Parameters:
    ///   - progress: 上传进度1.0
    ///   - errorCount: 失败文件数量
    public func onUploadFinishedExistError(progress: Double, errorCount: Int) {
        driveListConfig.update(progress: progress, total: nil, reminder: nil)
        DocsLogger.info("[Drive Upload] onUploadFinishedExistError",
                        extraInfo: ["identifier": identifier])
        // 要先展示进度完成，再展示失败
        driveListConfig.updateForError(errCount: errorCount)
        uploadStateInput.accept(())
        fileUploadedInput.accept(())
    }

    public func onUploadedFile(fileToken: String, moutNodePoint: String, nodeToken: String) {
        DocsLogger.info("[Drive Upload] onUploadedFile",
                        extraInfo: ["identifier": identifier])
        /// 上传完成后，通知外部
        fileUploadedInput.accept(())
        fileUploadFinishSuccessInput.accept(true)
        reportBrowserIfNeed(nodeToken: nodeToken)
    }

    public func onUploadFailedCount(count: Int) {
        driveListConfig.updateForError(errCount: count)
        DocsLogger.info("[Drive Upload] onUploadError",
                        extraInfo: ["identifier": identifier])
        uploadStateInput.accept(())
    }

    public func onUploadError(mountNodePoint: String, key: String, errorCode: Int) {
        guard mountToken == mountNodePoint, !mountNodePoint.isEmpty else {
            DocsLogger.info("[Drive Upload] mismatched mountNotePoint",
                            extraInfo: ["mountToken": "\(DocsTracker.encrypt(id: mountToken))",
                                        "mountNodePoint": "\(DocsTracker.encrypt(id: mountNodePoint))",
                                        "identifier": identifier
                            ])
            return
        }
        DocsLogger.warning("[Drive Upload] onUploadError",
                           extraInfo: ["mountNodePoint": "\(DocsTracker.encrypt(id: mountNodePoint))",
                                       "key": key,
                                       "errorCode": errorCode,
                                       "identifier": identifier
                           ])
        fileUploadFinishSuccessInput.accept(false)
    }

    public func onNoExistUploadingFile() {
        guard driveListConfig.isNeedUploading else { return }
        driveListConfig.finished()
        DocsLogger.info("[Drive Upload] finished",
                        extraInfo: ["identifier": identifier])
        uploadStateInput.accept(())
    }
    private func reportBrowserIfNeed(nodeToken: String?) {
        if let wikiToken = nodeToken, mountPoint == DriveConstants.wikiMountPoint {
            DocsLogger.info("upload wiki file success report upload: \(DocsTracker.encrypt(id: wikiToken))")
            reportBrowser(wikiToken: wikiToken).subscribe().disposed(by: bag)
        }
    }
    private func reportBrowser(wikiToken: String) -> Observable<()> {
        return RxDocsRequest<JSON>().request(OpenAPI.APIPath.wikiBrowserReport,
                                             params: ["token": wikiToken],
                                             method: .POST,
                                             encoding: .jsonEncodeDefault)
            .flatMap { (result) -> Observable<()> in
                guard let json = result,
                      json["code"].int != nil else {
                        return .error(WikiError.dataParseError)
                }
                return .just(())
            }
    }
}
