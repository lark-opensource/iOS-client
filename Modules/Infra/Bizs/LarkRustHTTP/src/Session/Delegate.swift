//
//  Delegate.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2023/4/11.
//

import Foundation
// swiftlint:disable attributes

// TODO: 按需添加需要的delegate
@objc public protocol RustHTTPSessionDelegate: NSObjectProtocol {
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        didBecomeInvalidWithError error: Error?
    )
}

@objc public protocol RustHTTPSessionTaskDelegate: RustHTTPSessionDelegate {
    // this is the first message, give a chance custom a task globally
    // NOTE: this method not call on delegateQueue, but in the caller thread directly,
    //   this ensure call this method before return
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        didCreateTask task: RustHTTPSessionTask
    )
    /// 请求结束前必定调用。如果验证不通过可以抛出错误，进入错误处理流程.
    /// - Parameter task: 请求的task, response可以从task中获取
    /// - Parameter body: response body. 使用completionHandler时必定有值. delegate流式接收body时可能没值.
    /// - Returns: error if invalid
    /// PS: optional with throws cause compiler error when called.. hacked to return Error instead..
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        validate task: RustHTTPSessionTask,
        body: RustHTTPBody?
    ) -> Error?
    /// 错误结束前必定调用(cancel除外)
    /// 必须回调completionHandler提供重试的request，或者nil正常报错结束。
    /// 泄露completionHandler回调会导致内存泄露!
    /// - Parameter task: 可以获取originalRequest或者currentRequest，用于修改和重试.
    ///                   还有retryCount属性可用于限制重试次数
    /// - Parameter error: 即将结束的错误
    /// PS: 如果想延迟重试，可以延迟调用completionHandler
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        shouldRetry task: RustHTTPSessionTask,
        with error: Error,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    )

    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        didCompleteWithError error: Error?
    )
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    )

    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        needNewBodyStream completionHandler: @escaping @Sendable (InputStream?) -> Void
    )

    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    )

    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        didFinishCollecting metrics: RustHTTPSessionTaskMetrics
    )

    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
    /// called before request rust, can get rust RequestID from request.
    /// may call multiple times for each request in a task
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        willRequest request: RustHTTPRequest
        )
}
@objc public protocol RustHTTPSessionDataDelegate: RustHTTPSessionDelegate {
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        dataTask: RustHTTPSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (RustHTTPSession.ResponseDisposition) -> Void
    )
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        dataTask: RustHTTPSessionDataTask,
        didReceive data: Data
    )
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        dataTask: RustHTTPSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse,
        completionHandler: @escaping @Sendable (CachedURLResponse?) -> Void
    )
}
@objc public protocol RustHTTPSessionDownloadDelegate: RustHTTPSessionDelegate {
    @objc func rustHTTPSession(
        _ session: RustHTTPSession,
        downloadTask: RustHTTPSessionDownloadTask,
        didFinishDownloadingTo location: URL
    )
    @objc optional func rustHTTPSession(
        _ session: RustHTTPSession,
        downloadTask: RustHTTPSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64)
}

import HTTProtocol

@objc
public class RustHTTPSessionTaskMetrics: NSObject {
    @objc public internal(set) var transactionMetrics: [RustHttpMetrics] = []
    @objc public internal(set) var taskInterval: DateInterval = .init()
    @objc public internal(set) var redirectCount: Int = 0
    @objc public internal(set) var retryCount: Int = 0
}

/// FetchRequest Wrapper to notify request rust
@objc public class RustHTTPRequest: NSObject {
    var original: URLRequest
    var rust: FetchRequest
    init(original: URLRequest, rust: FetchRequest) {
        self.original = original
        self.rust = rust
    }
}

@objc public class RustHTTPBody: NSObject {
    // the build HTTProtocolBuffer should immutable
    var raw: HTTProtocolBuffer
    /// the received data
    @objc public lazy internal(set) var data: Data = raw.asData()
    /// the disk buffer file, or may auto create a new buffer file as URL. nil when create file failed
    @objc public lazy internal(set) var fileURL: URL? = try? raw.asURL()
    init(_ raw: HTTProtocolBuffer) {
        self.raw = raw
    }
    @objc public var length: Int { raw.length }
}

// swiftlint:enable attributes
