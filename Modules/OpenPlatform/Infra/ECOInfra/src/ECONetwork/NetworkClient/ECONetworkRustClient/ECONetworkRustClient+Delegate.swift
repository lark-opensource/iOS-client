//
//  ECONetworkRustClient+Delegate.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation
import LarkRustHTTP

extension ECONetworkRustClient: RustHTTPSessionTaskDelegate, RustHTTPSessionDataDelegate, RustHTTPSessionDownloadDelegate {
    
    //MARK: - RustHTTPSessionTaskDelegate
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request)
    }
    
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didFinishCollecting metrics: RustHTTPSessionTaskMetrics) {
        guard let requestingTask = self.requestingTasks[task.taskIdentifier],
              let metrics = metrics.transactionMetrics.first else {
            Self.logger.warn("taskID: \(task.taskIdentifier) requestContext or task is release")
            return
        }
        let networkMetrics = ECONetworkRustMetrics(with: metrics)
        requestingTask.metrics = networkMetrics
    }
    
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didCompleteWithError error: Error?) {
        Self.logger.info("TaskLifecycle - didComplete \(String(describing: error))", additionalData: ["clientID": identifier, "taskID": String(task.taskIdentifier)])
        guard let requestingTask = self.requestingTasks[task.taskIdentifier] else {
            Self.logger.warn("taskID: \(task.taskIdentifier) requestingTask is nil")
            return
        }
        requestingTask.responseDataHandler.finish()
        requestingTask.error = error
        requestingTask.complete()
    }
    
    //MARK: - RustHTTPSessionDataDelegate
    
    func rustHTTPSession(_ session: RustHTTPSession, dataTask: RustHTTPSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (RustHTTPSession.ResponseDisposition) -> Void) {
        Self.logger.info("TaskLifecycle - didReceiveResponse", additionalData: ["clientID": identifier, "taskID": String(dataTask.taskIdentifier)])
        guard let requestingTask = self.requestingTasks[dataTask.taskIdentifier] else {
            Self.logger.warn("taskID: \(dataTask.taskIdentifier) requestingTask is nil")
            completionHandler(.allow)
            return
        }
        requestingTask.response = response
        completionHandler(.allow)
    }
    
    func rustHTTPSession(_ session: RustHTTPSession, dataTask: RustHTTPSessionDataTask, didReceive data: Data) {
        guard let requestingTask = self.requestingTasks[dataTask.taskIdentifier] else {
            Self.logger.warn("taskID: \(dataTask.taskIdentifier) requestingTask is nil")
            return
        }
        // 收到新数据, 使用 responseDataHandler 接收
        _ = requestingTask.responseDataHandler.receiveChunk(withData: data)
    }
    
    
    //MARK: - RustHTTPSessionDownloadDelegate
    
    func rustHTTPSession(_ session: LarkRustHTTP.RustHTTPSession, downloadTask: LarkRustHTTP.RustHTTPSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Self.logger.info("TaskLifecycle - didFinishDownloading", additionalData: ["clientID": identifier, "taskID": String(downloadTask.taskIdentifier)])
        guard let requestingTask = self.requestingTasks[downloadTask.taskIdentifier] else {
            Self.logger.warn("taskID: \(downloadTask.taskIdentifier) requestingTask is nil")
            return
        }
        // 收到新数据, 使用 responseDataHandler 接收
        if let error = requestingTask.responseDataHandler.receiveURL(source: location) {
            Self.logger.error("taskID: \(downloadTask.taskIdentifier) didFinishDownloadingTo \(location) error: \(error)")
            requestingTask.error = error
        }
        requestingTask.response = downloadTask.response
    }
}
