//
//  OPURLSessionManager.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/12.
//

import Foundation

private class OPURLSessionTask: NSObject {

    let requestIdentifier: String

    let dataTask: URLSessionTask

    var handlers: [OPURLSessionTaskEventHandler] = []

    var data: Data = Data()

    init(requestIdentifier: String, dataTask: URLSessionTask) {
        self.requestIdentifier = requestIdentifier
        self.dataTask = dataTask
    }
}

fileprivate extension OPURLSessionConfiguration {

    /// 转换成系统的configuration
    var standartConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        return config
    }
}

public extension OPURLSessionTaskConfigration {
    /// 如果是get请求，会组装到url的query里，如果是post，会塞到httpbody
    var urlRequest: URLRequest {
        var request: URLRequest
        switch method.paramType {
        case .query:
            request = URLRequest(url: url.append(parameters: params as? [String: String] ?? [:], forceNew: true))
        case .body:
            request = URLRequest(url: url)
            if JSONSerialization.isValidJSONObject(params),
               let body = try? JSONSerialization.data(withJSONObject: params) {
                request.httpBody = body
            }
        }
        request.httpMethod = method.httpMethod
        (headers as? [String: String])?.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        return request
    }
}

/// 开放平台网络请求管理器：对应一个session，管理一个session内的多个网络任务的调度
public final class OPURLSessionManager: NSObject {

    private let configuration: OPURLSessionConfiguration

    /// 真正的urlsession
    private lazy var session: URLSession = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = configuration.maxConcurrentOperationCount
        let session = URLSession(configuration: configuration.standartConfiguration,
                                 delegate: self,
                                 delegateQueue: queue)
        return session
    }()

    deinit {
        session.invalidateAndCancel()
    }

    /// 内部操作task字典时需要进行上锁，以避免多线程操作引起不一致
    private let taskLock = DispatchSemaphore(value: 1)

    /// 内部执行的任务列表，取消或执行完成后会移除
    private var tasks: [Int: OPURLSessionTask] = [:]

    init(configuration: OPURLSessionConfiguration) {
        self.configuration = configuration
    }

    public func startFetch(with taskConfig: OPURLSessionTaskConfigration) {
        lockOperation {
            if taskConfig.shouldMergeWithSameId,
               let task = tasks.values.first(where: { $0.requestIdentifier == taskConfig.identifier }) {
                // 尝试提高优先级，但任务开始后是否会真正提高，试网络协议而定
                task.dataTask.priority = max(task.dataTask.priority, taskConfig.priority)
                if let handler = taskConfig.eventHandler {
                    task.handlers.append(handler)
                }
            } else {
                var dataTask = session.dataTask(with: taskConfig.urlRequest)
                dataTask.priority = taskConfig.priority
                let opTask = OPURLSessionTask(requestIdentifier: taskConfig.identifier, dataTask: dataTask)
                if let handler = taskConfig.eventHandler {
                    opTask.handlers.append(handler)
                }
                tasks[dataTask.taskIdentifier] = opTask
                dataTask.resume()
            }
        }
    }

    public func pauseFetch(with identifier: String) {
        lockOperation {
            tasks.values.forEach({
                if $0.requestIdentifier == identifier {
                    $0.dataTask.suspend()
                }
            })
        }
    }

    public func cancelFetch(with identifier: String) {
        lockOperation {
            let taskKeys = tasks.filter({ $0.value.requestIdentifier == identifier }).map({ $0.key })
            taskKeys.forEach({
                let task = tasks.removeValue(forKey: $0)
                task?.dataTask.cancel()
            })
        }
    }

    public func clearFecth() {
        lockOperation {
            tasks.forEach({ $0.value.dataTask.cancel() })
            tasks.removeAll()
        }
    }

    private func lockOperation(_ opt: () -> Void) {
        taskLock.wait()
        opt()
        taskLock.signal()
    }
}

extension OPURLSessionManager: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lockOperation {
            if let optask = tasks[dataTask.taskIdentifier] {
                optask.data.append(data)
                optask.handlers.forEach({
                    $0.onProgress?(data, Float(dataTask.countOfBytesReceived), Float(dataTask.countOfBytesExpectedToReceive))
                })
            } else {
                //log & monitor
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lockOperation {
            if let optask = tasks[task.taskIdentifier] {
                optask.handlers.forEach({
                    $0.onComplete?(error == nil ? optask.data : nil, error?.newOPError(monitorCode: OPSDKMonitorCode.unknown_error))
                })
                tasks.removeValue(forKey: task.taskIdentifier)
            } else {
                //log & monitor
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        lockOperation {
            tasks[task.taskIdentifier]?.handlers.forEach({
                $0.onMetricsCollected?(metrics)
            })
        }
    }

}
