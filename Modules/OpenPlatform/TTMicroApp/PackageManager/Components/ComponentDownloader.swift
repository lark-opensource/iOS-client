//
//  ComponentsDownloader.swift
//  Timor
//
//  Created by Limboy on 2020/9/10.
//

import Foundation
import OPFoundation

/// 正在下载中的任务，可以通过 requestId 和 taskId 来查询
private class DownloadingTask {
    /// 只要 reuqestIdentifier 一样，就表示是同一个 Request
    let requestIdentifier: String

    /// URLSessionTask 的 taskIdentifier
    let taskIdentifier: Int

    /// 是通过 jssdk 还是 meta 触发的下载
    let loadType: ComponentDownloader.LoadType

    let appType: BDPType
    
    /// 如果是下载JSSDK则为空，下载应用数据则不为空
    let uniqueID: BDPUniqueID?

    let componentName: String

    let componentVersion: String

    /// 请求链路各阶段耗时度量
    var bdpMetrics: BDPRequestMetrics?

    /// 当 request 结束后， blocks 会被依次调用
    var completionBlocks: [(Data?, URLResponse?, NSError?) -> Void] = []

    init(_ requestIdentifier: String, _ taskIdentifier: Int, _ appType: BDPType, _ uniqueID: BDPUniqueID?, _ componentName: String, _ componenetVersion:String, _ loadType: ComponentDownloader.LoadType) {
        self.requestIdentifier = requestIdentifier
        self.taskIdentifier = taskIdentifier
        self.appType = appType
        self.uniqueID = uniqueID
        self.componentName = componentName
        self.componentVersion = componenetVersion
        self.loadType = loadType
    }
}

class ComponentDownloader: NSObject {

    enum LoadType:String {
        case jssdk
        case meta
    }

    static let shared = ComponentDownloader()

    /// 请求最大并发数，默认值是CPU活跃核心数*2
    private let maxConcurrentOperationCount: Int

    /// 请求超时时间，默认30s
    private let timeoutIntervalForRequest: TimeInterval

    /// make downladingTasks thread safe
    private let downloadingTasksOperationLock = DispatchSemaphore(value: 1)

    private lazy var session: URLSession = {
        let sessionConfiguration = BDPNetworking.sharedSession().configuration.copy() as! URLSessionConfiguration
        sessionConfiguration.timeoutIntervalForRequest = timeoutIntervalForRequest
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = maxConcurrentOperationCount
            return queue
        }())
        return session
    }()

    fileprivate var downloadingTasks = [DownloadingTask]()

    private override init() {
        /// 保险起见，用 1 兜底
        maxConcurrentOperationCount = max(ProcessInfo.processInfo.activeProcessorCount * 2, 1)
        timeoutIntervalForRequest = 30
    }

    /// 开始下载组件
    /// - Parameters:
    ///   - request: 包含组件下载地址的 URLRequest
    ///   - requestIdentifier: 该 request 的 id，通常为 URL
    ///   - appType: 小程序类型
    ///   - completionHandler: 请求结束后会被调用
    func download(
        with request: URLRequest,
        requestIdentifier: String,
        componentName: String,
        componentVersion: String,
        appType: BDPType,
        uniqueID: BDPUniqueID?,
        loadType: LoadType,
        completionHandler: @escaping (Data?, URLResponse?, NSError?) -> Void
    ) {
        //forbidden all download action with condition, just return
        //相关功能需要关闭
        if OPSDKFeatureGating.isBoxOff() {
            BDPLogWarn(tag: .componentDownloader, "[BIG_COMPONENTS] component download is forbidden")
            return
        }
        if let downloadingTask = getTaskByRequestIdentifier(requestIdentifier) {
            BDPLogWarn(tag: .componentDownloader, "[BIG_COMPONENTS] component is downloading. url: \(request.url)")
            addCompletionHandler(completionHandler, to: downloadingTask)
            return
        }

        OPMonitor(kEventName_op_common_component_download_start)
            .addTag(.componentDownloader)
            .addCategoryValue(kEventKey_app_type, OPAppTypeToString(appType))
            .setUniqueID(uniqueID)
            .addCategoryValue("component_url", request.url?.absoluteString)
            .addCategoryValue("component", componentName)
            .addCategoryValue("load_type", loadType.rawValue)
            .flush()

        BDPLogInfo(tag: .componentDownloader, "[BIG_COMPONENTS] start downloading url: \(request.url)")
        let task = session.downloadTask(with: request)
        let downloadingTask = DownloadingTask(requestIdentifier, task.taskIdentifier, appType, uniqueID, componentName,componentVersion, loadType)
        addCompletionHandler(completionHandler, to: downloadingTask)
        addDownloadingTask(task: downloadingTask)
        task.resume()
    }
}

// MARK: URLSessionDownloadDelegate
extension ComponentDownloader:URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let task = self.getTaskByTaskIdentifier(downloadTask.taskIdentifier) else {
            BDPLogError(tag: .componentDownloader, "[BIG_COMPONENTS] downloading task does not exist. url: \(downloadTask.currentRequest?.url)")
            return
        }

        BDPLogInfo(tag: .componentDownloader, "[BIG_COMPONENTS] component \(task.componentName) downloaded. url:\(downloadTask.currentRequest?.url)")

        var err: NSError? = nil
        var data: Data? = nil
        do {
            data = try Data.init(contentsOf: location)
        } catch {
            BDPLogError(tag: .componentDownloader, "[BIG_COMPONENTS] read component \(task.componentName) download data failed. error: \(error.localizedDescription)")
            err = NSError(domain: error.localizedDescription, code: 0, userInfo: nil)
        }

        task.completionBlocks.forEach { (completionBlock) in
            BDPExecuteOnMainQueue {
                completionBlock(data, downloadTask.response, err)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let task = getTaskByTaskIdentifier(task.taskIdentifier) else {
            BDPLogError(tag: .componentDownloader, "[BIG_COMPONENTS] get task by identifier failed.")
            return
        }
        task.bdpMetrics = BDPRequestMetrics(from: metrics.transactionMetrics.first)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadingTask = self.getTaskByTaskIdentifier(task.taskIdentifier) else {
            BDPLogError(tag: .componentDownloader, "[BIG_COMPONENTS] downloading task does not exist. url: \(task.currentRequest?.url)")
            return
        }

        let monitor = OPMonitor(kEventName_op_common_component_download_result)
            .addTag(.componentDownloader)
            .addCategoryValue(kEventKey_app_type, OPAppTypeToString(downloadingTask.appType))
            .setUniqueID(downloadingTask.uniqueID)
            .addCategoryValue("component_url", task.currentRequest?.url?.absoluteString)
            .addCategoryValue("load_type", downloadingTask.loadType.rawValue)
            .addCategoryValue("component", downloadingTask.componentName)
            .addCategoryValue("componentVersion", downloadingTask.componentVersion)

        if let error = error {
            BDPLogError(tag: .componentDownloader, "[BIG_COMPONENTS] download failed")
            let opError = error.newOPError(monitorCode: CommonMonitorCodeComponent.component_download_failed)
            monitor.setError(opError)
        } else {
            BDPLogInfo(tag: .componentDownloader, "[BIG_COMPONENTS] download success")
            monitor.setMonitorCode(CommonMonitorCodeComponent.component_download_success)
            monitor.setResultTypeSuccess()
        }

        if let metrics = downloadingTask.bdpMetrics {
            monitor
                .addMetricValue("dns", metrics.dns)
                .addMetricValue("tcp", metrics.tcp)
                .addMetricValue("ssl", metrics.ssl)
                .addMetricValue("send", metrics.send)
                .addMetricValue("wait", metrics.wait)
                .addMetricValue("recv", metrics.receive)
                .setDuration(TimeInterval(metrics.requestTime))
        }

        monitor.flush()

        /// 如果没有错误，那么 completionBlocks 会在 `didFinishDownloadingTo` 回调
        if let error = error {
            let opError = OPError.error(monitorCode: CommonMonitorCodeComponent.component_download_failed, message: "[BIG_COMPONENTS] download component \(downloadingTask.componentName) failed. error: \(error.localizedDescription)")
            downloadingTask.completionBlocks.forEach { (completionBlock) in
                BDPExecuteOnMainQueue {
                    completionBlock(nil, nil, opError)
                }
            }
        }
        removeDownloadingTask(downloadingTask)
    }
}

// MARK: Utils
extension ComponentDownloader {

    private func addCompletionHandler(_ handler: @escaping (Data?, URLResponse?, NSError?) -> Void, to task:DownloadingTask) {
        BDPLogInfo(tag: .componentDownloader, "[BIG_COMPONENTS] add completion handler to task: \(task.requestIdentifier)")
        downloadingTasksOperationLock.wait()
        task.completionBlocks.append(handler)
        downloadingTasksOperationLock.signal()
    }

    private func removeDownloadingTask(_ task: DownloadingTask) {
        BDPLogInfo(tag: .componentDownloader, "[BIG_COMPONENTS] remove task: \(task.requestIdentifier)")
        downloadingTasksOperationLock.wait()
        downloadingTasks.removeAll { (downloadingTask) -> Bool in
            return downloadingTask.taskIdentifier == task.taskIdentifier
        }
        downloadingTasksOperationLock.signal()
    }

    private func addDownloadingTask(task:DownloadingTask) {
        BDPLogInfo(tag: .componentDownloader, "[BIG_COMPONENTS] add downloading task: \(task.requestIdentifier)")
        downloadingTasksOperationLock.wait()
        self.downloadingTasks.append(task)
        downloadingTasksOperationLock.signal()
    }

    private func getTaskByRequestIdentifier(_ requestIdentifier: String) -> DownloadingTask? {
        downloadingTasksOperationLock.wait()
        let downloadingTask = downloadingTasks.first { (downloadingTask) -> Bool in
            return downloadingTask.requestIdentifier == requestIdentifier
        }
        downloadingTasksOperationLock.signal()
        return downloadingTask
    }

    private func getTaskByTaskIdentifier(_ taskIdentifier: Int) -> DownloadingTask? {
        downloadingTasksOperationLock.wait()
        let downloadingTask = downloadingTasks.first { (downloadTask) -> Bool in
            return downloadTask.taskIdentifier == taskIdentifier
        }
        downloadingTasksOperationLock.signal()
        return downloadingTask
    }
}
