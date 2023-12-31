//
//  URLSessionDownloader.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/28.
//

import UIKit

/// 内置的基于 URLSession 的 http(s) 下载器
public final class URLSessionDownloader: NSObject, Downloader {

    private(set) var session: URLSession!
    private let sessionQueue: DispatchQueue = DispatchQueue(label: "com.bt.imageLoadTaskQueue")
    private let delegateQueue: OperationQueue = OperationQueue()

    public var maxConcurrentTaskCount: Int = OperationQueue.defaultMaxConcurrentOperationCount
    public var mutex: pthread_mutex_t = pthread_mutex_t()
    public var weakTasks: NSMapTable<WeakTaskIdentifier, DownloadTask>
    public var operationQueue: OperationQueue

    public weak var delegate: DownloaderDelegate?
    public var tempPath: NSString = NSTemporaryDirectory() as NSString
    private var _timeoutInterval: TimeInterval = Constants.defaultTimeoutInterval
    public var timeoutInterval: TimeInterval {
        get { _timeoutInterval }
        set {
            if newValue > 0 {
                _timeoutInterval = newValue
            } else {
                _timeoutInterval = Constants.defaultTimeoutInterval
            }
        }
    }
    private var _timeoutIntervalForResource: TimeInterval = Constants.defaultTimeoutInterval
    public var timeoutIntervalForResource: TimeInterval {
        get { _timeoutIntervalForResource }
        set {
            if newValue > 0 {
                _timeoutIntervalForResource = newValue
            } else {
                _timeoutIntervalForResource = Constants.defaultTimeoutInterval
            }
        }
    }
    public var defaultHeaders: [String: String]
    public var downloadResumeEnable: Bool = false
    public var checkMimeType: Bool = false
    public var checkDataLength: Bool = true
    public var isConcurrentCallback: Bool = false

    public var downloadTaskClass: DownloadTask.Type { return ByteURLSessionDownloadTask.self }

    public override init() {
        self.weakTasks = NSMapTable(keyOptions: NSPointerFunctions.Options.strongMemory, valueOptions: NSPointerFunctions.Options.weakMemory)
        self.operationQueue = OperationQueue()
        self.defaultHeaders = [:]
        super.init()
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 10
        config.timeoutIntervalForRequest = self.timeoutInterval
        config.timeoutIntervalForResource = self.timeoutIntervalForResource
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: self.delegateQueue)
        pthread_mutex_init(&self.mutex, nil)
    }

    // MARK: - Public Func

    public func task(with identifier: Int) -> ByteURLSessionDownloadTask? {
        for operation in self.operationQueue.operations {
            if let task = operation as? ByteURLSessionDownloadTask {
                if task.isExecuting && (task.task?.taskIdentifier ?? 0 == identifier) {
                    return task
                }
            }
        }
        return nil
    }

    public func task(with request: ImageRequest) -> DownloadTask {
        let task = ByteURLSessionDownloadTask(with: request)
        task.delegate = self
        task.timeoutInterval = request.timeoutInterval > 0 ? request.timeoutInterval : self.timeoutInterval
        task.defaultHeaders = defaultHeaders
        task.timeoutIntervalForResource = timeoutIntervalForResource
        task.downloadResumeEnable = downloadResumeEnable
        task.checkMimeType = checkMimeType
        task.checkDataLength = checkDataLength
        task.isConcurrentCallback = isConcurrentCallback
        task.sessionManager = self
        return task
    }

}

extension URLSessionDownloader: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let task = self.task(with: dataTask.taskIdentifier)
        task?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let task = self.task(with: dataTask.taskIdentifier)
        task?.urlSession(session, dataTask: dataTask, didReceive: data)

    }

    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let dataTask = self.task(with: task.taskIdentifier)
        dataTask?.urlSession(session, task: task, didFinishCollecting: metrics)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let dataTask = self.task(with: task.taskIdentifier)
        dataTask?.urlSession(session, task: task, didCompleteWithError: error)
    }
}

extension URLSessionDownloader: URLSessionDownloadDelegate {

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let task = self.task(with: downloadTask.taskIdentifier)
        task?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        let task = self.task(with: downloadTask.taskIdentifier)
        task?.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let task = self.task(with: downloadTask.taskIdentifier)
        task?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
}
