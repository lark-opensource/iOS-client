//
//  ECONetworkClient+URLSessionDelegate.swift
//  ECOInfra
//
//  Created by MJXin on 2021/5/27.
//

import Foundation

//MARK: - URLSessionDelegate
extension ECONetworkClient: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        Self.logger.info("didBecomeInvalidWithError \(String(describing: error))", additionalData: ["clientID": identifier])
    }
}

//MARK: - URLSessionTaskDelegate
extension ECONetworkClient: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        Self.logger.info("taskIsWaitingForConnectivity", additionalData: ["clientID": identifier, "taskID": String(task.taskIdentifier)])
    }

    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        Self.logger.info("TaskLifecycle - willPerformHTTPRedirection \(NSString.safeURL(request.url) ?? "")", additionalData: ["clientID": identifier, "taskID": String(task.taskIdentifier)])
        guard let requestingTask = self.requestingTasks[task.taskIdentifier] else {
            Self.logger.warn("taskID: \(task.taskIdentifier) requestingTask is nil")
            completionHandler(request)
            return
        }
        requestingTask.currentRequest = request
        // 重定向, 更新 request, 若 delegate 未实现则直接转发
        if let willPerformHTTPRedirection = self.delegate?.willPerformHTTPRedirection {
            willPerformHTTPRedirection(
                requestingTask.context.previousContext,
                self,
                requestingTask,
                response,
                request,
                completionHandler
            )
        } else {
            completionHandler(request)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let requestingTask = self.requestingTasks[task.taskIdentifier] else {
            Self.logger.warn("taskID: \(task.taskIdentifier) requestingTask is nil")
            return
        }
        self.delegate?.didSendBodyData?(
            context: requestingTask.context.previousContext,
            client: self,
            task: requestingTask,
            bytesSent: bytesSent,
            totalBytesSent: totalBytesSent,
            totalBytesExpectedToSend: totalBytesExpectedToSend
        )
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let requestingTask = self.requestingTasks[task.taskIdentifier],
              let metrics = metrics.transactionMetrics.first else {
            Self.logger.warn("taskID: \(task.taskIdentifier) requestContext or task is release")
            return
        }
        let networkMetrics = ECONetworkMetrics(with: metrics)
        requestingTask.metrics = networkMetrics
        self.delegate?.didFinishCollecting?(
            context: requestingTask.context.previousContext,
            client: self,
            task: requestingTask,
            metrics: networkMetrics
        )
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Self.logger.info("TaskLifecycle - didComplete \(String(describing: error))", additionalData: ["clientID": identifier, "taskID": String(task.taskIdentifier)])
        guard let requestingTask = self.requestingTasks[task.taskIdentifier] else {
            Self.logger.warn("taskID: \(task.taskIdentifier) requestingTask is nil")
            return
        }
        // 请求结束, responseDataHandler 结束接收数据
        requestingTask.responseDataHandler.finish()
        requestingTask.error = error
        requestingTask.complete()
    }
    
}

//MARK: - URLSessionDataDelegate
extension ECONetworkClient: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        Self.logger.info("TaskLifecycle - didReceiveResponse", additionalData: ["clientID": identifier, "taskID": String(dataTask.taskIdentifier)])
        guard let requestingTask = self.requestingTasks[dataTask.taskIdentifier] else {
            Self.logger.warn("taskID: \(dataTask.taskIdentifier) requestingTask is nil")
            completionHandler(.allow)
            return
        }
        requestingTask.response = response
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let requestingTask = self.requestingTasks[dataTask.taskIdentifier] else {
            Self.logger.warn("taskID: \(dataTask.taskIdentifier) requestingTask is nil")
            return
        }
        // 收到新数据, 使用 responseDataHandler 接收
        _ = requestingTask.responseDataHandler.receiveChunk(withData: data)
        self.delegate?.didReceive?(
            context: requestingTask.context.previousContext,
            client: self,
            task: requestingTask,
            data: data
        )
    }
}

//MARK: - URLSessionDownloadDelegate
extension ECONetworkClient: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
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

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let requestingTask = self.requestingTasks[downloadTask.taskIdentifier] else {
            Self.logger.warn("taskID: \(downloadTask.taskIdentifier) requestingTask is nil")
            return
        }
        self.delegate?.didWriteData?(
            context: requestingTask.context.previousContext,
            client: self,
            task: requestingTask,
            bytesWritten: bytesWritten,
            totalBytesWritten: totalBytesWritten,
            totalBytesExpectedToWrite: totalBytesExpectedToWrite
        )
    }
}
