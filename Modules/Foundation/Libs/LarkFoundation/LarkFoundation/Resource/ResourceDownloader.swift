//
//  ResourceDownloader.swift
//  Lark
//
//  Created by 齐鸿烨 on 2017/5/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias StateChangeBlock = (DownloadState) -> Void

public enum ReadyState: Int {
    case unsent = 0
    case opened = 1
    case loading = 2
    case done = 3
    case canceled = 4
}

public protocol DownloadState {
    var error: Error? { get set }
    var statusCode: Int { get set }
    var readyState: ReadyState { get set }
    var data: Data? { get set }
    var dataLength: Int64 { get set }
    var totalDataLength: Int64 { get }
}

public struct DownloadStateImpl: DownloadState {
    public var error: Error?
    public var statusCode: Int
    public var readyState: ReadyState
    public var data: Data?
    public var dataLength: Int64
    public var totalDataLength: Int64

    public init(
        error: Error?,
        statusCode: Int,
        readyState: ReadyState,
        data: Data?,
        dataLength: Int64,
        totalDataLength: Int64
    ) {
        self.error = error
        self.statusCode = statusCode
        self.readyState = readyState
        self.data = data
        self.dataLength = dataLength
        self.totalDataLength = totalDataLength
    }
}

public protocol DownloadProcessor {
    var preRequest: (URLRequest) -> URLRequest? { get set }
    var processReceiveData: (Data) -> Data? { get set }
    var processReadData: (Data) -> Data? { get set }
    var onReceiveData: (Data) -> Data { get set }
}

public struct DefaultDownloadProcessor: DownloadProcessor {
    public var processReceiveData: (Data) -> Data? = { data in
        return data
    }

    public var processReadData: (Data) -> Data? = { data in
        return data
    }

    public var preRequest: (URLRequest) -> URLRequest? = { request in
        return request
    }

    public var onReceiveData: (Data) -> Data = { data in
        return data
    }
}

public protocol ResourceFetcher {
    func fetch(key: String, onStateChange: ((DownloadState) -> Void)?)
    func cancel(key: String)
}

public struct DownloadRequestOptions {
    public var cachePolicy: URLRequest.CachePolicy
    public var timeoutInterval: TimeInterval

    public init(cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval) {
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
    }

    public static let `default` = DownloadRequestOptions(cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15)
}

fileprivate let defaultProcessor = DefaultDownloadProcessor()

public struct DataTaskOptions {
    public var policy: Float

    //    init(policy: Float) {
    //        self.policy = policy
    //    }

    public static let `default` = DataTaskOptions(policy: URLSessionTask.defaultPriority)
}

public struct DownloadOptions {
    public var request: DownloadRequestOptions
    public var dataTask: DataTaskOptions
    public var processor: DownloadProcessor
    public var downloadQueue: DispatchQueue
    public var callbackQueue: DispatchQueue
    public var context: [String: Any]

    //    init(request: DownloadRequestOptions, dataTask: DataTaskOptions) {
    //        self.request = request
    //        self.dataTask = dataTask
    //    }

    public static let `default` = DownloadOptions(request: .default,
                                                  dataTask: .default,
                                                  processor: defaultProcessor,
                                                  downloadQueue: DispatchQueue(label: "Lark.Resource.DataTask.queue",
                                                                               qos: .default,
                                                                               attributes: .concurrent),
                                                  callbackQueue: .main,
                                                  context: [:])
}

public protocol ResourceLoadTask: AnyObject {
    var id: Int { get }
    func start()
    func cancel()
    func resume()
    func pause()
}

open class ResourceDownloadTaskImpl: ResourceLoadTask {
    public var id: Int {
        return sessionDataTask.taskIdentifier
    }

    public var sessionDataTask: URLSessionDataTask
    public weak var ownerDownloader: ResourceDownloader?

    public var url: URL? {
        return sessionDataTask.originalRequest?.url
    }

    public var priority: Float {
        set {
            sessionDataTask.priority = newValue
        }
        get {
            return sessionDataTask.priority
        }
    }

    public init(task: URLSessionDataTask, downloader: ResourceDownloader? = nil) {
        sessionDataTask = task
    }

    public func start() {
        ownerDownloader?.resumeDownloadTask(task: self)
    }

    public func cancel() {
        ownerDownloader?.cancelDownloadTask(task: self)
    }

    public func resume() {
        ownerDownloader?.resumeDownloadTask(task: self)
    }

    public func pause() {
        ownerDownloader?.pauseDownloadTask(task: self)
    }
}

public protocol ResourceDownloader: AnyObject {
    var name: String { get }
    var defaultDownloadOptions: DownloadOptions? { get set }
    var maxDownloadConcurrentTaskCount: Int { get set }
    var keepAlive: Bool { get set }
    func downloadResource(key: String,
                          authToken: String?,
                          onStateChangeBlock: (@escaping StateChangeBlock),
                          options: DownloadOptions?) -> ResourceDownloadTaskImpl?
    func resumeDownloadTask(task: ResourceDownloadTaskImpl)
    func cancelDownloadTask(task: ResourceDownloadTaskImpl)
    func pauseDownloadTask(task: ResourceDownloadTaskImpl)
    func clean(url: URL)
}
