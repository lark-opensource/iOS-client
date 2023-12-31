//
//  ECONetworkRustTask.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation
import LarkRustHTTP

@objc public protocol ECONetworkRustTaskProtocol {
    var taskIdentifier: Int { get }
    func resume()
    func suspend()
    func cancel()
}

protocol ECONetworkRustTaskClient: AnyObject {
    func taskResuming(task: ECONetworkRustTask)
    func taskPausing(task: ECONetworkRustTask)
    func taskCanceling(task: ECONetworkRustTask)
    func taskCompleting(task: ECONetworkRustTask)
}

class ECONetworkRustTask: NSObject, ECONetworkRustTaskProtocol {
    var taskIdentifier: Int { internalTask.taskIdentifier }
    var state: ECONetworkTaskState
    var response: URLResponse?
    var error: Error?
    var requestURL: URL? { internalTask.currentRequest?.url }
    var trace: OPTrace? { context.trace }
    var requestID: String? { context.trace.getRequestID() }
    var metrics: ECONetworkRustMetrics?
    private weak var client: ECONetworkRustTaskClient?
    var internalTask: RustHTTPSessionTask
    internal var shouldCleanTempFile: Bool = true
    var context: ECONetworkContextProtocol
    var completionHandler: TaskCompletionHandler?
    var responseDataHandler: ECONetworkResponseDataHandler
    
    internal init(
        context: ECONetworkContextProtocol,
        client: ECONetworkRustTaskClient,
        task: RustHTTPSessionTask,
        responseDataHandler: ECONetworkResponseDataHandler,
        completionHandler: TaskCompletionHandler?
    ) {
        self.client = client
        self.internalTask = task
        self.state = .suspended
        self.context = context
        self.responseDataHandler = responseDataHandler
        self.completionHandler = completionHandler
        super.init()
    }
    
    func resume() {
        self.client?.taskResuming(task: self)
    }
    
    func suspend() {
        self.client?.taskPausing(task: self)
    }
    
    func cancel() {
        self.client?.taskCanceling(task: self)
    }
    
    internal func complete() { client?.taskCompleting(task: self) }
    
}
