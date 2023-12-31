//
//  DocsRustSessionDelegate.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/5/17.
//

import Foundation
import LarkRustHTTP
import Alamofire

public protocol DocsInternalRequestRetrier {
    //是否需要重试代理方法
    func should(retry request: URLRequest, currentRetryCount: UInt, with error: Error, completion: @escaping RequestRetryCompletion)
}


public class DocsRustSessionDelegate: NSObject {
    
//   暂时屏蔽保留代码，后续如果需要自己实现DocsRustSessionDelegate，需要自己维护task跟TaskCompletion的关系
//    public typealias DocsTaskCompletion = (DataResponse<Any>) -> Void
//    /// Completion handler for `URLSessionDownloadTask`.
//    public typealias DocsDataTaskCompletion = (DataResponse<Data>) -> Void
//    /// What to do upon events (such as completion) of a specific task.
//    public enum DocsTaskBehaviour {
//        case noHandler
//        /// Default action for all events, except for completion.
//        case didCompletionHandler(DocsTaskCompletion)
//        /// Default action for all events, except for completion.
//        case dataCompletionHandler(DocsDataTaskCompletion)
//    }
//
//    var taskBehaviour: [RustHTTPSessionTask: DocsTaskBehaviour] = [:]
//    private let lock = NSLock()
//
//    /// Access the task delegate for the specified task in a thread-safe manner.
//    public subscript(task: RustHTTPSessionTask) -> DocsTaskBehaviour? {
//        get {
//            lock.lock() ; defer { lock.unlock() }
//            return taskBehaviour[task]
//        }
//        set {
//            lock.lock() ; defer { lock.unlock() }
//            taskBehaviour[task] = newValue
//        }
//    }
    
    var retrier: DocRequestRetrier?
    
}

extension DocsRustSessionDelegate: RustHTTPSessionTaskDelegate {

    @objc public func rustHTTPSession(
            _ session: RustHTTPSession,
            shouldRetry task: RustHTTPSessionTask,
            with error: Error,
            completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        let error: Error? = error
        
        //由业务方自己判断是否需要重试
        if let retrier = retrier, let error = error {
            retrier.should(retry: task.originalRequest, currentRetryCount: UInt(task.retryCount), with: error) { shouldRetry, _ in
                guard shouldRetry else {
                    completionHandler(nil)
                    return
                }
                
                completionHandler(task.currentRequest)
            }
        } else {
            completionHandler(nil)
        }
    }
}
