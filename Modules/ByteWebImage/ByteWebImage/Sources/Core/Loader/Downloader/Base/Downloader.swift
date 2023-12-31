//
//  DownLoadManager.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/25.
//

import Foundation

/**
 如果任务超过并行上限则会进入等待队列，BDDownloadStackMode指定了等待队列的模式
 */

public protocol DownloaderDelegate: AnyObject {
    func downloader(_ downloader: Downloader, task: DownloadTask, finishedWith result: Result<Data, ByteWebImageError>, savePath: String?)
    func downloader(_ downloader: Downloader, task: DownloadTask, reiceivedSize rSize: Int, expectedSize eSize: Int)
    func downloader(_ downloader: Downloader, task: DownloadTask, didReceived received: Data?, increment: Data?)
}

/// 下载器协议
public protocol Downloader: DownloadTaskDelegate {

    typealias WeakTaskIdentifier = NSString

    var delegate: DownloaderDelegate? { get set }
    var maxConcurrentTaskCount: Int { get set } // 最大同时下载任务
    var timeoutInterval: TimeInterval { get set }
    var timeoutIntervalForResource: TimeInterval { get set }
    var downloadTaskClass: DownloadTask.Type { get }
    var operationQueue: OperationQueue { get set } // 执行下载任务的queue
    var mutex: pthread_mutex_t { get set } // 保证线程安全的锁
    var weakTasks: NSMapTable<WeakTaskIdentifier, DownloadTask> { get set } // weakTable，存Task
    var tempPath: NSString { get set } // 存临时文件目录
    var downloadResumeEnable: Bool { get set } // 是否支持断点续传
    var checkMimeType: Bool { get set }
    var checkDataLength: Bool { get set }
    var isConcurrentCallback: Bool { get set }
    var defaultHeaders: [String: String] { get set } // http request default header

    func taskFromCache(with identifier: String) -> DownloadTask?
    func task(with request: ImageRequest) -> DownloadTask
    /// 下载方法，Rust协议由于是写文件，需要传，其他Downloader根据情况进行处理
    @discardableResult
    func download(with request: ImageRequest) -> DownloadTask?

}

public extension Downloader {

    func downloadTask(_ task: DownloadTask, received rSize: Int, expected eSize: Int) {
        delegate?.downloader(self, task: task, reiceivedSize: rSize, expectedSize: eSize)
    }

    func downloadTask(_ task: DownloadTask, didReceived data: Data?, increment: Data?) {
        delegate?.downloader(self, task: task, didReceived: data, increment: increment)
    }

    func downloadTask(_ task: DownloadTask, finishedWith result: Result<Data, ByteWebImageError>, path: String?) {
        self.delegate?.downloader(self, task: task, finishedWith: result, savePath: path)
    }

    func downloadTaskDidCanceled(_ task: DownloadTask) {
        let error = ImageError(ByteWebImageErrorUserCancelled, userInfo: [NSLocalizedDescriptionKey: "User canceled"])
        delegate?.downloader(self, task: task, finishedWith: Result.failure(error), savePath: nil)
    }
}

public extension Downloader {

    // 根据Requestoptions 获取Downloader队列的优先级
    func transformQueuePriority(_ request: ImageRequest) -> Operation.QueuePriority {
        request.params.priority.queuePriority
    }

    func taskFromCache(with identifier: String) -> DownloadTask? {
        var task: DownloadTask?
        pthread_mutex_lock(&self.mutex)
        task = self.weakTasks.object(forKey: identifier as WeakTaskIdentifier)
        pthread_mutex_unlock(&self.mutex)
        return task
    }

    func task(with request: ImageRequest) -> DownloadTask {
        let task = downloadTaskClass.init(with: request)
        task.delegate = self
        task.timeoutInterval = request.timeoutInterval > 0 ? request.timeoutInterval : self.timeoutInterval
        task.defaultHeaders = self.defaultHeaders
        task.timeoutIntervalForResource = self.timeoutIntervalForResource
        task.downloadResumeEnable = self.downloadResumeEnable
        task.checkMimeType = self.checkMimeType
        task.checkDataLength = self.checkDataLength
        task.isConcurrentCallback = self.isConcurrentCallback
        return task
    }

    @discardableResult
    func download(with request: ImageRequest) -> DownloadTask? {
        var task: DownloadTask?
        pthread_mutex_lock(&self.mutex)
        task = self.weakTasks.object(forKey: request.requestKey as WeakTaskIdentifier)
        if task == nil || (task?.isFinished ?? true) || (task?.isCancelled ?? true) {
            task = self.task(with: request)
            guard let task = task else { return nil }
            task.progressDownload = request.params.animatedImageProgressiveDownload || request.params.progressiveDownload
            task.savePath = request.downloadDiretory
            let verifyData = request.params.notVerifyData
            if !verifyData {
                task.checkDataLength = false
                task.checkMimeType = false
            }
            if task.tempPath.isEmpty {
                task.tempPath = (tempPath as NSString).appendingPathComponent(task.identifier)
            }
            task.queuePriority = self.transformQueuePriority(request)
            #if ByteWebImage_Include_Lark
            (task as? RustDownloadTask)?.fromLocal = request.currentRequestURL.isFileURL
            #endif
            weakTasks.setObject(task, forKey: task.identifier as WeakTaskIdentifier)
            operationQueue.addOperation(task)
        } else {
            if let task = task {
                if !task.isExecuting {
                    task.progressDownload = request.params.animatedImageProgressiveDownload || request.params.progressiveDownload
                    let priority = self.transformQueuePriority(request)
                    if task.queuePriority.rawValue < priority.rawValue {
                        task.queuePriority = priority
                    }
                }
            }
        }
        pthread_mutex_unlock(&mutex)
        return task
    }
}
