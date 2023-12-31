//
//  ECONetworkTask.swift
//  ECOInfra
//
//  Created by MJXin on 2021/5/27.
//

import Foundation
import LKCommonsLogging

protocol ECONetworkTaskRequestContext {
    /// 内部真正控制网络请求的 URLSessionTask
    var internalTask: URLSessionTask { get }
    /// 当前环境的上下文信息
    var context: ECONetworkContextProtocol { get }
    /// 网络请求结束的响应回调
    var completionHandler: TaskCompletionHandler? { get }
    /// 网络请求获取到的数据(data or url)
    var responseDataHandler: ECONetworkResponseDataHandler { get }
}

/// 描述真正执行 Task 的执行器协议
protocol ECONetworkTaskClient: AnyObject {
    func taskResuming(task: ECONetworkTask)
    func taskPausing(task: ECONetworkTask)
    func taskCanceling(task: ECONetworkTask)
    func taskCompleting(task: ECONetworkTask)
}

@objcMembers
class ECONetworkTask: NSObject, ECONetworkTaskProtocol, ECONetworkTaskRequestContext {
    private static let logger = Logger.oplog(ECONetworkTask.self, category: "ECONetwork")
    
    internal init(
        context: ECONetworkContextProtocol,
        client: ECONetworkTaskClient,
        task: URLSessionTask,
        responseDataHandler: ECONetworkResponseDataHandler,
        completionHandler: TaskCompletionHandler?
    ) {
        self.client = client
        self.internalTask = task
        self.originalRequest = task.originalRequest
        self.currentRequest = task.currentRequest
        self.state = .suspended
        self.context = context
        self.responseDataHandler = responseDataHandler
        self.completionHandler = completionHandler
        super.init()
    }

    public var taskIdentifier: Int { internalTask.taskIdentifier }
    public var requestURL: URL? { currentRequest?.url }
    public var trace: OPTrace? { context.trace }
    public var requestID: String? { context.trace.getRequestID() }
    public var httpResponse: HTTPURLResponse? {
        get {
            guard let httpResponse = response as? HTTPURLResponse else {
                Self.logger.info("task:\(taskIdentifier) have unknown response: \(String(describing: response.self))")
                return nil
            }
            return httpResponse
        }
    }
    
    public internal(set) var state: ECONetworkTaskState
    public internal(set) var originalRequest: URLRequest?
    public internal(set) var currentRequest: URLRequest?
    public internal(set) var response: URLResponse?
    public internal(set) var error: Error?
    public internal(set) var metrics: ECONetworkMetrics?
    
    /// 内部真正控制网络请求的 URLSessionTask
    internal var internalTask: URLSessionTask
    /// 当前环境的上下文信息
    internal var context: ECONetworkContextProtocol
    /// 网络请求结束的响应回调
    internal var completionHandler: TaskCompletionHandler?
    /// 网络请求获取到的数据(data or url)
    internal var responseDataHandler: ECONetworkResponseDataHandler
    /// 是否自动清理临时数据(下载链接)
    internal var shouldCleanTempFile: Bool = true
    
    private weak var client: ECONetworkTaskClient?
    private let stateSemaphore = DispatchSemaphore(value: 1)
    
    public func resume() { client?.taskResuming(task: self) }

    public func suspend() { client?.taskPausing(task: self) }

    public func cancel() { client?.taskCanceling(task: self) }
    
    internal func complete() { client?.taskCompleting(task: self) }
    
    deinit {
        Self.logger.debug("task:\(taskIdentifier) deinit")
    }
}
