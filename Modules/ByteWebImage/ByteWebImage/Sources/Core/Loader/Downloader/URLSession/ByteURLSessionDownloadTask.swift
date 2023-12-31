//
//  URLSessionDownloadTask.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/28.
//

import UIKit

// lint:disable lark_storage_check - 不影响 Lark，无需检查

private let kDownloadTaskInfoURLSessionResumeDataKey = "ResumeData"

public final class ByteURLSessionDownloadTask: DownloadTask {

    public weak var sessionManager: URLSessionDownloader?

    private(set) var task: URLSessionTask?
    /** DNS耗时 单位ms */
    private(set) var DNSDuration: Int = 0
    /** 建立连接耗时 单位ms */
    private(set) var connectDuration: Int = 0
    /** SSL建连耗时 单位ms */
    private(set) var sslDuration: Int = 0
    /** 发送耗时 单位ms */
    private(set) var sendDuration: Int = 0
    /** 等待耗时 单位ms */
    private(set) var waitDuration: Int = 0
    /** 接收耗时 单位ms */
    private(set) var receiveDuration: Int = 0
    private(set) var isSocketReused: Bool = false
    private(set) var isFromProxy: Bool = false
    /** 图片类型*/
    private(set) var mimeType: String?
    /** http请求状态码*/
    private(set) var statusCode: Int = 0
    /*图片系统在response header中增加的追踪信息，目前包含回复时间戳和处理总延迟*/
    private(set) var nwSessionTrace: String = ""
    /**上报response header的相关信息*/
    private(set) var headers: [String: Any] = [:]

    private var HTTPResponseHeaders: [AnyHashable: Any]?
    private var HTTPRequestHeaders: [AnyHashable: Any]?
    private var resumeData: Data?
    private var imageData: Data?
    private var hasContentLength: Bool = false
    private var imageRequest: ImageRequest?

    public required init(with request: ImageRequest) {
        super.init(with: request)
        self.imageRequest = request
    }

    deinit {
        self.task?.cancel()
        self.task = nil
    }

    public override func start() {
        super.start()
        if self.isCancelled { return }
        self.resetTask()
    }

    // MAKR: - Private Func
    private func resetTask() {
        let infoPath = (self.tempPath as NSString).appendingPathComponent("cfg")
        if !FileManager.default.fileExists(atPath: infoPath) {
            self.cleanTempFile()
        } else {
            let info = NSDictionary(contentsOf: URL(fileURLWithPath: infoPath))
            self.resumeData = info?.object(forKey: ByteDownloadTaskInfo.requsetHeader) as? Data
        }
        if let resumeData = self.resumeData, self.downloadResumeEnable {
            self.task = self.sessionManager?.session.downloadTask(withResumeData: resumeData)
            self.resumeData = nil
        }
        if self.task == nil {
            var request = URLRequest(url: self.url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: self.timeoutInterval)
            if let modifier = self.imageRequest?.modifier {
                request = modifier(request)
            }
            request.httpShouldHandleCookies = false
            request.httpShouldUsePipelining = true
            for item in self.defaultHeaders {
                request.setValue(item.value, forHTTPHeaderField: item.key)
            }
            // 这里不能是DownloadSession，因为无法即时获取Data数据，从而无法Progressive的现实数据
            self.task = self.sessionManager?.session.dataTask(with: request)
        }
        if let task = self.task {
            switch self.queuePriority {
            case .high:
                task.priority = URLSessionTask.highPriority
            case .low:
                task.priority = URLSessionTask.lowPriority
            default:
                task.priority = URLSessionTask.defaultPriority
            }
            if self.isCancelled {
                self.isFinished = true
            } else {
                task.resume()
            }
        } else {
            self.isFinished = true
            let error = ImageError(ByteWebImageErrorBadImageUrl, userInfo: [NSLocalizedDescriptionKey: "failed to create download request"])
            self.delegate?.downloadTask(self, finishedWith: Result.failure(error), path: nil)
        }
    }

    private func saveTempInfo() {
        if let response = self.task?.response as? HTTPURLResponse {
            self.HTTPResponseHeaders = response.allHeaderFields
        }
        self.HTTPRequestHeaders = self.task?.currentRequest?.allHTTPHeaderFields
        if self.HTTPRequestHeaders != nil {
            if !FileManager.default.fileExists(atPath: self.tempPath) {
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: self.tempPath), withIntermediateDirectories: true, attributes: nil)
            }
            var headers = [ByteDownloadTaskInfo.Key: Any]()
            headers[ByteDownloadTaskInfo.responseHeader] = self.HTTPResponseHeaders
            headers[ByteDownloadTaskInfo.requsetHeader] = self.HTTPRequestHeaders
            headers[ByteDownloadTaskInfo.originURL] = self.url.absoluteString
            headers[ByteDownloadTaskInfo.resumeData] = self.resumeData
            let infoPath = (self.tempPath as NSString).appendingPathComponent("cfg")
            (headers as NSDictionary).write(to: URL(fileURLWithPath: infoPath), atomically: true)
        }
    }

    private func cleanTempFile() {
        let fileManager = FileManager.default
        let cfgPath = (tempPath as NSString).appendingPathComponent("cfg")
        do {
            try fileManager.removeItem(atPath: tempPath)
            try fileManager.removeItem(atPath: cfgPath)
        } catch {

        }

    }
}

extension ByteURLSessionDownloadTask: URLSessionDownloadDelegate {

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.isFinished = true
        if let data = try? Data(contentsOf: location) {
            if let cacheControl = self.HTTPResponseHeaders?[ByteDownloadTaskInfo.cacheControl] as? String {
                self.cacheControlTime = DownloadTask.getCacheControlTime(from: cacheControl)
            }
            self.delegate?.downloadTask(self, finishedWith: Result.success(data), path: nil)
        }
        self.task = nil
        self.imageData = nil
        self.cleanTempFile()
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        self.set(received: Int(fileOffset), expected: Int(expectedTotalBytes))
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.set(received: Int(totalBytesWritten), expected: Int(totalBytesExpectedToWrite))
    }

}

extension ByteURLSessionDownloadTask: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.mimeType = response.mimeType
        if let response = response as? HTTPURLResponse {
            self.statusCode = response.statusCode
            self.HTTPResponseHeaders = response.allHeaderFields
            if let reponseCache = self.HTTPRequestHeaders?[ByteDownloadTaskInfo.responseCache] {
                self.headers = [ByteDownloadTaskInfo.responseCache: reponseCache]
            }
        }
        // '304 Not Modified' is an exceptional one
        // disable-lint: magic number
        let httpResponse = response as? HTTPURLResponse
        let code = (httpResponse?.statusCode ?? 999)
        if httpResponse == nil || (code < 400 && code != 304) {
            self.expectedSize = Int(response.expectedContentLength)
            self.hasContentLength = self.expectedSize != 0
            self.set(received: self.expectedSize, expected: self.expectedSize)
            if self.imageData != nil {
                self.imageData = nil
            }
            self.imageData = Data(capacity: self.expectedSize)
        } else {
            if code == 304 {
                self._cancel()
            } else {
                self._cancel()
                self.cleanTempFile()
            }
            let error = ImageError(code, userInfo: [:])
            self.delegate?.downloadTask(self, finishedWith: Result.failure(error), path: nil)
        }
        completionHandler(.allow)
        // enable-lint: magic number
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.isFinished = true
        if let data = self.imageData {
            let headers = self.HTTPResponseHeaders as? [ByteDownloadTaskInfo.Key: String] ?? [:]
            self.setupSmartCropRect(from: headers)
            // 检查下载内容是否正常，出错重试 https
            do {
                try self.checkDataError(data, headers: headers)
                if let conrtol = self.HTTPResponseHeaders?[ByteDownloadTaskInfo.cacheControl] as? String {
                    self.cacheControlTime = DownloadTask.getCacheControlTime(from: conrtol)
                }
                self.delegate?.downloadTask(self, finishedWith: Result.success(data), path: nil)
            } catch {

                self.imageData = nil
                let nsError = error as NSError
                if nsError.code == ByteWebImageErrorUserCancelled {
                    self.task = nil
                }
                let byteImageError = ImageError(nsError.code, userInfo: [NSLocalizedDescriptionKey: nsError.localizedDescription])
                self.delegate?.downloadTask(self, finishedWith: Result.failure(byteImageError), path: nil)
            }
        } else {
            let nsError = error as? NSError
            let byteImageError = ImageError(nsError?.code ?? ByteWebImageErrorUnkown, userInfo: [NSLocalizedDescriptionKey: nsError?.localizedDescription ?? "unkown error"])
            self.delegate?.downloadTask(self, finishedWith: Result.failure(byteImageError), path: nil)
        }

    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.imageData?.append(data)
        if !self.hasContentLength {
            self.expectedSize = self.imageData?.count ?? 0
        }
        if let imageData = self.imageData {
            self.set(received: imageData.count, expected: self.expectedSize)
        }
        self.delegate?.downloadTask(self, didReceived: self.imageData, increment: data)

    }

    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        for metric in metrics.transactionMetrics {
            if metric.resourceFetchType != .networkLoad {
                continue
            }
            if let domainLookupEndTime = metric.domainLookupEndDate?.timeIntervalSince1970, let domainLookupStartTime = metric.domainLookupStartDate?.timeIntervalSince1970 {
                self.DNSDuration = Int((domainLookupEndTime - domainLookupStartTime) * 1000)
            }
            if let connectEndTime = metric.connectEndDate?.timeIntervalSince1970, let connectStartTime = metric.connectStartDate?.timeIntervalSince1970 {
                self.connectDuration = Int((connectEndTime - connectStartTime) * 1000)
            }
            if let secureConnectionEndTime = metric.secureConnectionEndDate?.timeIntervalSince1970, let secureConnectionStartTime = metric.secureConnectionStartDate?.timeIntervalSince1970 {
                self.sslDuration = Int((secureConnectionEndTime - secureConnectionStartTime) * 1000)
            }
            if let requestEndTime = metric.requestEndDate?.timeIntervalSince1970, let requestStartTime = metric.requestStartDate?.timeIntervalSince1970 {
                self.sendDuration = Int((requestEndTime - requestStartTime) * 1000)
            }
            if let responseStartTime = metric.responseStartDate?.timeIntervalSince1970, let requestEndTime = metric.requestStartDate?.timeIntervalSince1970 {
                self.waitDuration = Int((responseStartTime - requestEndTime) * 1000)
            }
            if let responseEndTime = metric.responseEndDate?.timeIntervalSince1970, let responseStartTime = metric.responseStartDate?.timeIntervalSince1970 {
                self.receiveDuration = Int((responseEndTime - responseStartTime) * 1000)
            }
            self.isSocketReused = metric.isReusedConnection
            self.isFromProxy = metric.isProxyConnection
        }
    }
}
