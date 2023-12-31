//
//  DocCommonDownloader.swift
//  LarkApp
//
//  Created by maxiao on 2019/8/2.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//
// nolint: long parameters

import Foundation
import RxSwift
import SpaceInterface
import ThreadSafeDataStructure
import SKCommon
import SKFoundation
import SKInfra
import SpaceInterface

extension DocCommonDownloadPriority {
    var rustPriority: DriveDownloadPriority {
        .custom(priority: rawValue)
    }
}

extension DocCommonDownloadType {
    func convertToDriveType() -> DriveDownloadRequest.ApiType {
        switch self {
        case .originFile:
            return .drive
        case .previewFile:
            return .preview
        case .image:
            return .img
        case .cover:
            return .cover
        }
    }

}

public final class DocCommonDownloader {

    private let downloader = SpaceRustRouter.shared
    private var bag = DisposeBag()
    private lazy var downloadCacheServive: SpaceDownloadCacheProtocol = DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!
    // key: Rust返回的下载任务的key
    // value: 回调数组，因为有可能触发多次下载，所以是一个数组
    private var jobs = SafeDictionary<String, [PublishSubject<DocCommonDownloadResponseContext>]>()
    // key: Rust返回的下载任务的key
    // value: 下载请求的数据，用来回调给业务使用
    private var contextsMap = SafeDictionary<String, DocCommonDownloadRequestContext>()

    public init() {
        DriveDownloadCallbackService.shared.addObserver(self)
    }
}

extension DocCommonDownloader: DocCommonDownloadProtocol {

    // 批量下载接口
    // 目前的使用场景：Docs 预加载文档内图片
    public func download(with contexts: [DocCommonDownloadRequestContext]) -> Observable<DocCommonDownloadResponseContext> {
        let requests: [DriveDownloadRequest] = contexts.map({ (context) -> DriveDownloadRequest in
            // docs 请求图片的时候，不知道版本信息和后缀名
            let downloadType = context.downloadType
            let localPath = context.localPath ?? DocDownloadCacheService.getDocDownloadCacheURL(key: context.fileToken,
                                                                                                type: downloadType).pathString
            let context = SpaceRustRouter.DownloadRequestContext(localPath: localPath,
                                                                 fileToken: context.fileToken,
                                                                 docToken: context.docToken,
                                                                 docType: context.docType,
                                                                 mountNodePoint: context.mountNodePoint,
                                                                 mountPoint: context.mountPoint,
                                                                 dataVersion: nil,
                                                                 priority: .custom(priority: context.priority.rawValue),
                                                                 apiType: context.downloadType.convertToDriveType(),
                                                                 coverInfo: getCoverInfo(with: downloadType),
                                                                 authExtra: nil,
                                                                 disableCDN: context.disableCdn,
                                                                 teaParams: context.teaParams)
            let request = SpaceRustRouter.constructDownloadRequest(context: context)
            return request
        })
        // 批量下载走同一个回调接口
        let progressSubject = PublishSubject<DocCommonDownloadResponseContext>()
        // Map 返回的是下载文件的 Token 和下载id这个 key 的映射关系
        downloader.download(requests: requests).subscribe(onNext: {[weak self] keysMap in
            // 通过返回的 token 和 key 进行请求数据的缓存，收到回调后再拿这个 key 对应的数据进行回调
            for (token, key) in keysMap {
                guard let context = contexts.first(where: { (context) -> Bool in
                    return context.fileToken == token
                }) else {
                    DocsLogger.error("can not find this token's context, token: \(DocsTracker.encrypt(id: token)), key: \(key)")
                    continue
                }
                // 有可能触发多次下载，批量进行存储，后续批量进行回调
                if var job = self?.jobs[key] {
                    job.append(progressSubject)
                    self?.jobs[key] = job
                } else {
                    self?.jobs[key] = [progressSubject]
                }
                // context 这里没有做多次缓存是因为key相同context信息肯定相同，如果context不同，Rust 认为是不同的两次任务
                self?.contextsMap[key] = context
                // 通知调用方开始下载，同时将key返回给调用方
                let response = DocCommonDownloadResponseContext.initailResponseContext(with: context, key: key)
                progressSubject.onNext(response)
            }
        }).disposed(by: bag)
        return progressSubject.asObserver()
    }

    // 单个文件下载接口
    // 目前的使用场景：Docs 打开后下载文档内图片
    public func download(with context: DocCommonDownloadRequestContext) -> Observable<DocCommonDownloadResponseContext> {
        let localPath = context.localPath ?? DocDownloadCacheService.getDocDownloadCacheURL(key: context.fileToken,
                                                                                            type: context.downloadType).pathString
        let progressSubject = PublishSubject<DocCommonDownloadResponseContext>()
        let reqContext = SpaceRustRouter.DownloadRequestContext(localPath: localPath,
                                                                fileToken: context.fileToken,
                                                                docToken: "",
                                                                docType: nil,
                                                                mountNodePoint: context.mountNodePoint,
                                                                mountPoint: context.mountPoint,
                                                                dataVersion: nil,
                                                                priority: context.priority.rustPriority,
                                                                apiType: context.downloadType.convertToDriveType(),
                                                                coverInfo: getCoverInfo(with: context.downloadType),
                                                                authExtra: context.authExtra,
                                                                disableCDN: context.disableCdn,
                                                                disableCoverRetry: context.disableCoverRetry,
                                                                teaParams: context.teaParams)
        let request = SpaceRustRouter.constructDownloadRequest(context: reqContext)
        downloader.download(request: request)
            .subscribe(onNext: { [weak self] key in
                // 有可能触发多次下载，批量进行存储，后续批量进行回调
                if var job = self?.jobs[key] {
                    job.append(progressSubject)
                    self?.jobs[key] = job
                } else {
                    self?.jobs[key] = [progressSubject]
                }
                // context 这里没有做多次缓存是因为key相同context信息肯定相同，如果context不同，Rust 认为是不同的两次任务
                self?.contextsMap[key] = context
                let response = DocCommonDownloadResponseContext.initailResponseContext(with: context, key: key)
                progressSubject.onNext(response)
            })
            .disposed(by: bag)

        return progressSubject.asObserver()
    }

    public func downloadNormal(remoteUrl: String, localPath: String, priority: DocCommonDownloadPriority) -> Observable<DocCommonDownloadResponseContext> {
        let progressSubject = PublishSubject<DocCommonDownloadResponseContext>()
        downloader.downloadNormal(remoteUrl: remoteUrl,
                                  localPath: localPath,
                                  priority: priority.rustPriority,
                                  authExtra: nil).subscribe(onNext: { [weak self] key in
            guard let self = self else { return }
            // 有可能触发多次下载，批量进行存储，后续批量进行回调
            if var job = self.jobs[key] {
                job.append(progressSubject)
                self.jobs[key] = job
            } else {
                self.jobs[key] = [progressSubject]
            }
            let context = DocCommonDownloadRequestContext(fileToken: "",
                                                          mountNodePoint: "",
                                                          mountPoint: "",
                                                          priority: priority,
                                                          downloadType: .originFile,
                                                          localPath: localPath,
                                                          isManualOffline: false,
                                                          dataVersion: nil,
                                                          originFileSize: nil,
                                                          fileName: nil)
            self.contextsMap[key] = context
            let response = DocCommonDownloadResponseContext.initailResponseContext(with: context, key: key)
            progressSubject.onNext(response)
        }).disposed(by: bag)
        return progressSubject.asObserver()
    }

    public func cancelDownload(key: String) -> Observable<Bool> {
        return downloader.cancelDownload(key: key).map { (result) -> Bool in
            return result == -1 ? false : true
        }
    }

    private func getCoverInfo(with type: DocCommonDownloadType) -> DriveCoverDownloadInfo? {
        guard case let .cover(width, height, policy) = type else { return nil }
        var info = DriveCoverDownloadInfo()
        info.width = Int32(width)
        info.height = Int32(height)
        info.policy = policy.rawValue
        return info
    }
}

extension DocCommonDownloader: DriveDownloadCallback {

    public func updateProgress(context: DriveDownloadContext) {
        let key = context.key
        let status = context.status
        guard let subjects = jobs[key] else { return }
        guard let requestContext = contextsMap[key] else {
            log(downloadTaskKey: key, downloadStatus: status)
            return
        }
        guard status != .failed else {
            // 避免 failed 回调执行两次，updateProgress里面的failed回调不处理
            log(downloadTaskKey: key, downloadStatus: status)
            return
        }
        let responseContext = DocCommonDownloadResponseContext(requestContext: requestContext,
                                                               downloadStatus: DocCommonDownloadStatus(rawValue: status.rawValue) ?? .pending,
                                                               downloadProgress: (Float(context.bytesTransferred), Float(context.bytesTotal)),
                                                               key: key,
                                                               localFilePath: context.filePath,
                                                               fileName: context.fileName,
                                                               fileType: context.fileType)
        if status == .success {
            log(downloadTaskKey: key, downloadStatus: status)
            handleSuccess(request: requestContext, response: responseContext, subjects: subjects)
        } else {
            subjects.forEach { (subject) in
                subject.onNext(responseContext)
            }
        }
    }

    public func onFailed(key: String, errorCode: Int) {
        guard let subjects = jobs[key] else { return }
        guard let requestContext = contextsMap[key] else {
            DocsLogger.error("contextsMap[key]: \(String(describing: contextsMap[key]))")
            return
        }
        log(downloadTaskKey: key, downloadStatus: .failed)
        let responseContext = DocCommonDownloadResponseContext(requestContext: requestContext,
                                                               downloadStatus: .failed,
                                                               downloadProgress: (0, 0),
                                                               errorCode: errorCode,
                                                               key: key,
                                                               localFilePath: "",
                                                               fileName: "",
                                                               fileType: "")
        subjects.forEach { (subject) in
            subject.onNext(responseContext)
        }
        jobs.removeValue(forKey: key)
    }

    private func log(downloadTaskKey: String, downloadStatus: DriveDownloadCallbackStatus) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            guard let requestContext = self.contextsMap[downloadTaskKey] else { return }
            DocsLogger.driveInfo(
                """
                "DocCommonDownloader: download status is \(downloadStatus),
                "downloadTaskKey is \(downloadTaskKey), "
                and the file token is \(DocsTracker.encrypt(id: requestContext.fileToken))"
                """)
        }
    }
    
    private func handleSuccess(request: DocCommonDownloadRequestContext,
                               response: DocCommonDownloadResponseContext,
                               subjects: [PublishSubject<DocCommonDownloadResponseContext>]) {
        if request.localPath != nil {
            DocsLogger.driveInfo("DocCommonDownloader: handleSuccess no need save file, task key: \(response.key)")
            // 如果传了下载路径，不保存到DriveCache
            subjects.forEach { (subject) in
                subject.onNext(response)
            }
            self.jobs.removeValue(forKey: response.key)
        } else {
            // 将文件传入缓存，异步操作，保存完成后才执行回调
            downloadCacheServive.save(request: request) { [weak self] success in
                guard let self = self else { return }
                subjects.forEach { (subject) in
                    subject.onNext(response)
                }
                self.jobs.removeValue(forKey: response.key)
                if !success {
                    DocsLogger.driveError(
                    """
                    "DocCommonDownloader: save file failed, rust task key is \(response.key), and the file token is \(DocsTracker.encrypt(id: request.fileToken))"
                    """)
                }
            }
        }
    }
}
