//
//  MailDriveDownloader.swift
//  MailSDK
//
//  Created by ByteDance on 2023/8/25.
//

import Foundation
import ThreadSafeDataStructure
import RxSwift
import LarkStorage

// Mail Rust 对Drive下载接口做了封装
// Mail Rust层通过调用Drive Rust下载进行图片附件的预拉取，为了复用与拉取的任务和缓存，统一管理下载任务
// Native不直接调用Drive的下载接口，而是调用Mail封装的下载接口。
// https://bytedance.feishu.cn/docx/Vh3HdBWJsoaOaMxQ6YLcOcP0ncc
class MailDriveDownloadService {
    private let bag = DisposeBag()
    private let service: DataService
    // key: Rust返回的下载任务的key
    // value: 回调数组，因为有可能触发多次下载，所以是一个数组
    private var jobs = SafeDictionary<String, [PublishSubject<DriveDownloadResponseCtx>]>()
    // key: Rust返回的下载任务的key
    // value: 下载请求的数据，用来回调给业务使用
    private var contextsMap = SafeDictionary<String, DriveDownloadRequestCtx>()
    
    init(dataService: DataService) {
        self.service = dataService
        addDownloadProgressObserver()
    }
    
    deinit {
        MailLogger.info("MailDriveDownloadService: deinit")
    }
    
    private func addDownloadProgressObserver() {
        MailCommonDataMananger.shared.downloadProgressChange.observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] change in
            guard let self = self else { return }
            let key = change.progressInfo.key
            let status = change.progressInfo.status
            guard let subjects = self.jobs[key] else { // 非主动触发下载的(rust预拉取的情况)
                MailLogger.error("MailDriveDownloadService: no subject for key: \(key)")
                return
            }
            guard let requestContext = self.contextsMap[key] else {
                MailLogger.error("MailDriveDownloadService: no request context downloadKey \(key), status \(status)")
                return
            }
            MailLogger.info("MailDriveDownloadService:  for key: \(key)")
            guard status != .failed else {
                // 避免 failed 回调执行两次，updateProgress里面的failed回调不处理
                MailLogger.error("MailDriveDownloadService: handle failed \(key), status \(status), errcode: \(change.progressInfo.failedInfo.errorCode)")
                self.handleFailed(key: key, errorCode: Int(change.progressInfo.failedInfo.errorCode))
                return
            }
            let downloadStatus = DriveDownloadResponseCtx.DownloadStatus(rawValue: status.rawValue) ?? .pending
            let progress = (Float(change.progressInfo.bytesTransferred) ?? 0, Float(change.progressInfo.bytesTotal) ?? 0)
            let responseCtx = DriveDownloadResponseCtx(requestContext: requestContext,
                                                       downloadStatus: downloadStatus,
                                                       downloadProgress: progress,
                                                       errorCode: -1, key: key,
                                                       path: change.progressInfo.filePath)
            if status == .success {
                self.handleSuccess(request: requestContext, response: responseCtx, subjects: subjects)
            } else {
                subjects.forEach { (subject) in
                    subject.onNext(responseCtx)
                }
            }
        }).disposed(by: bag)
    }
    
    private func handleFailed(key: String, errorCode: Int) {
        guard let subjects = jobs[key] else {
            MailLogger.error("MailDriveDownloadService: no subjects")
            return
        }
        guard let requestContext = contextsMap[key] else {
            MailLogger.error("MailDriveDownloadService: no request context")
            return
        }
        let responseContext = DriveDownloadResponseCtx(requestContext: requestContext,
                                                       downloadStatus: .failed,
                                                       downloadProgress: (0, 0),
                                                       errorCode: errorCode, key: key,
                                                       path: nil)
        subjects.forEach { (subject) in
            subject.onNext(responseContext)
        }
        jobs.removeValue(forKey: key)
    }
    
    private func handleSuccess(request: DriveDownloadRequestCtx,
                               response: DriveDownloadResponseCtx,
                               subjects: [PublishSubject<DriveDownloadResponseCtx>]) {
        MailLogger.info("MailDriveDownloadService: handleSuccess task key: \(response.key)")
        // 如果传了下载路径，不保存到DriveCache
        subjects.forEach { (subject) in
            subject.onNext(response)
        }
        self.jobs.removeValue(forKey: response.key)
    }
    
    private func constructSuccessResponse(requestContext: DriveDownloadRequestCtx, path: String) -> DriveDownloadResponseCtx {
        return DriveDownloadResponseCtx(requestContext: requestContext, downloadStatus: .success, downloadProgress: (1.0, 1.0), errorCode: -1, key: "", path: path)
        
    }
    
    private func constructFailResponse(requestContext: DriveDownloadRequestCtx) -> DriveDownloadResponseCtx {
        return DriveDownloadResponseCtx(requestContext: requestContext, downloadStatus: .failed, downloadProgress: (0, 1), errorCode: -1, key: "", path: nil)
    }
    
    private func constructInitResponse(requestContext: DriveDownloadRequestCtx, key: String) -> DriveDownloadResponseCtx {
        return DriveDownloadResponseCtx(requestContext: requestContext, downloadStatus: .pending, downloadProgress: (0.0, 1), errorCode: -1, key: key, path: nil)
    }

}

extension MailDriveDownloadService: DriveDownloadProxy {
    func download(with context: DriveDownloadRequestCtx, messageID: String?) -> Observable<DriveDownloadResponseCtx> {
        let progressSubject = PublishSubject<DriveDownloadResponseCtx>()
        service.download(context: context, messageID: messageID, scene: .clientNormal, forceDownload: true).subscribe(onNext: {[weak self] response in
            guard let self = self else { return }
            MailLogger.info("MailDriveDownloadService: download response key \(response.key)")
            if let path = response.cachePath, !path.isEmpty {
                MailLogger.info("MailDriveDownloadService: download file return cachePath")
                progressSubject.onNext(self.constructSuccessResponse(requestContext: context, path: path))
                return
            }
            guard let key = response.key else {
                MailLogger.error("MailDriveDownloadService: download failed invalid key")
                progressSubject.onNext(self.constructFailResponse(requestContext: context))
                return
            }
            if var job = self.jobs[key] {
                job.append(progressSubject)
                self.jobs[key] = job
            } else {
                self.jobs[key] = [progressSubject]
            }
            // context 这里没有做多次缓存是因为key相同context信息肯定相同，如果context不同，Rust 认为是不同的两次任务
            self.contextsMap[key] = context
            // 通知调用方开始下载，同时将key返回给调用方
            let response = self.constructInitResponse(requestContext: context, key: key)
            progressSubject.onNext(response)
        }).disposed(by: bag)
        return progressSubject.asObserver()
    }
    
    func cancel(with key: String) -> Observable<Bool> {
        return service.cancelDownload(key: key).map { (result) -> Bool in
            return result == -1 ? false : true
        }
    }

}
