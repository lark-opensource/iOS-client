//
//  RustDownloaderManager.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/29.
//

import Foundation
import RxSwift

open class RustDownloader: NSObject, Downloader {

    public weak var delegate: DownloaderDelegate?
    public var maxConcurrentTaskCount: Int = OperationQueue.defaultMaxConcurrentOperationCount
    public var timeoutInterval: TimeInterval = 30.0
    public var timeoutIntervalForResource: TimeInterval = 30.0
    public var downloadTaskClass: DownloadTask.Type { return RustDownloadTask.self }
    public var operationQueue: OperationQueue
    public var mutex: pthread_mutex_t = pthread_mutex_t()
    public var weakTasks: NSMapTable<WeakTaskIdentifier, DownloadTask>
    public var tempPath: NSString = NSTemporaryDirectory() as NSString
    public var downloadResumeEnable: Bool = false
    public var checkMimeType: Bool = false
    public var checkDataLength: Bool = true
    public var isConcurrentCallback: Bool = false
    public var defaultHeaders: [String: String] = [:]

    /// Rsut指定下载缓存，不指定会走默认缓存的路径
    public required override init() {
        self.operationQueue = OperationQueue()
        self.weakTasks = NSMapTable(keyOptions: NSPointerFunctions.Options.strongMemory, valueOptions: NSPointerFunctions.Options.weakMemory)
        super.init()
        pthread_mutex_init(&self.mutex, nil)
    }

    public func task(with request: ImageRequest) -> DownloadTask {
        let task = RustDownloadTask(with: request)
        task.delegate = self
        task.timeoutInterval = request.timeoutInterval > 0 ? request.timeoutInterval : self.timeoutInterval
        task.defaultHeaders = defaultHeaders
        task.timeoutIntervalForResource = timeoutIntervalForResource
        task.downloadResumeEnable = downloadResumeEnable
        task.checkMimeType = checkMimeType
        task.checkDataLength = checkDataLength
        task.isConcurrentCallback = isConcurrentCallback
        return task
    }

}
