//
//  RustHttp.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/11/12.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import CFNetwork
import HTTProtocol
import EEAtomic

import LKCommonsLogging

let logger = Logger.log(RustHttpManager.self, category: "RustSDK.HTTPClient")
// swiftlint:disable missing_docs
public typealias FetchRequest = Tool_V1_FetchRequest
public typealias OnFetchResponse = Tool_V1_OnFetchResponse
typealias CancelFetchRequest = Tool_V1_CancelFetchRequest
typealias SetNetworkProxyRequest = Tool_V1_SetNetworkProxyRequest
typealias ClearNetworkProxyRequest = Tool_V1_ClearNetworkProxyRequest
typealias HttpHeader = Tool_V1_HttpHeader

// swiftlint:enable missing_docs

/// 管理和Rust交互和回调的命名空间
public final class RustHttpManager {
    /// 给rust一个独立的请求队列，避免对native的堆栈和线程占用产生干扰
    let queue = DispatchQueue(label: "RustHTTP")

    /// RustHTTP依赖rust初始化，rust网络也依赖于TTNet初始化，所以在初始化前不可用，需要拦截等待
    static public var ready = false {
        didSet {
            // 目前没有保证堆积请求和后面请求的请求顺序.. http本身也是可以并发的
            if ready {
                atomic_thread_fence(memory_order_release)
                RustHttpManager.shared.queue.async {
                    RustHttpManager.shared.ready()
                    logger.info("fetchAsync ready")
                }
            }
        }
    }
    /// 注入cancelRequest等部分消息要使用的rustService, 目前实现依赖于提供rustService, 以后可能会争取通用并解藕
    static public var rustService: (() -> RustService?)?

    static let shared = RustHttpManager()
    private var tasks: [Int64: RustHttpEventHandler] = [:]
    private let lock = UnfairLockCell()

    fileprivate func task(for id: Int64) -> RustHttpEventHandler? {
        lock.lock(); defer { lock.unlock() }
        return tasks[id]
    }
    private func addTask(for id: Int64, handler: RustHttpEventHandler) {
        lock.lock(); defer { lock.unlock() }
        assert(tasks[id] == nil, "can't override exist task event handler")
        tasks[id] = handler
    }
    private func removeTask(for id: Int64) {
        lock.lock(); defer { lock.unlock() }
        tasks[id] = nil
    }

    private var _nextTaskID = AtomicInt64Cell(1)
    /// 必须使用该方法统一管理生成id，否则id可能重复。此id和FetchRequest的id一致
    static func nextTaskID() -> Int64 {
        return RustHttpManager.shared._nextTaskID.increment(order: .relaxed)
    }

    // MARK: RustHttpTask
    typealias OnReadIntoBuffer = (UnsafeMutablePointer<UInt8>, Int) -> Int
    typealias OnEvent = (OnFetchResponse) -> Void
    /// 代表一个执行中的http请求，结束前释放掉会导致http请求被cancel
    /// this class is thread safe
    final class Task: RustHttpEventHandler {
        deinit {
            cancel()
            _disposed.deallocate()
        }

        let taskID: Int64
        private let onRead: OnReadIntoBuffer?
        private let onEvent: OnEvent
        init(id: Int64, onRead: OnReadIntoBuffer?, onEvent: @escaping OnEvent) {
            taskID = id
            self.onRead = onRead
            self.onEvent = onEvent
        }

        private var _disposed = AtomicBoolCell()
        var disposed: Bool {
            return _disposed.value
        }
        @discardableResult
        func dispose() -> Bool {
            if _disposed.exchange(true) == false {
                RustHttpManager.shared.removeTask(for: taskID)
                return true
            }
            return false
        }
        func cancel() {
            if dispose() {
                // logger.info("[\(taskID)] cancel by user")
                if let rustService = RustHttpManager.rustService?() {
                    var cancelRequest = CancelFetchRequest()
                    cancelRequest.requestID = taskID
                    _ = rustService.sendAsyncRequest(cancelRequest).subscribe() // will release memory when finish.
                }
            }
        }

        // RustHttpEventHandler
        func rustHttp(response: OnFetchResponse) {
            guard let v = response.response else {
                assertionFailure("empty OnFetchResponse!!")
                logger.warn("empty OnFetchResponse")
                return
            }
            // dispose后不再接收消息
            if disposed { return }
            switch v {
            case .cancelResponse, .errorResponse, .successResponse:
                // logger.info("[\(taskID)] \(enumCaseName(v))")
                dispose() // 结束事件，在回调前先dispose，不再接收消息，同时避免回调处理时调用cancel等
            @unknown default: break
            }
            onEvent(response)
        }
        func rustHttp(readInto buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
            return onRead?(buffer, maxLength) ?? -3
        }
    }

    func ready() {
        for task in waitingTask {
            task()
        }
        waitingTask = []
    }
    // protected by serial queue..
    private var waitingTask: [() -> Void] = []

    /// 封装Rust的C API请求
    /// - Parameters:
    ///   - request: 发送给Rust的网络请求参数, id需要用`nextTaskID`生成
    ///   - onReadBuf: 懒加载数据，主要用途是支持流式数据，避免一次性加载和传递大量数据. 无上传数据时传空
    ///   - onEvent: httpg相关事件回调, 在error，cancel，或finish时结束
    /// - Returns: 封装的Task对象，可Cancel。Cancel后不收到后续消息
    /// - Throws: 请求参数错误
    static func fetchAsync(
        request: FetchRequest,
        onReadBuf: OnReadIntoBuffer?,
        onEvent: @escaping OnEvent
    ) throws -> Task {
        let data = try request.serializedData()
        #if DEBUG
        if HTTProtocol.shouldShowDebugMessage {
            logger.debug("fetchAsync: \((try? request.jsonString()) ?? "json error")")
        }
        #else
        // logger.info("[\(request.requestID)][\(request.method)]: \(request.url)")
        #endif

        let taskID = request.requestID
        let task = Task(id: taskID, onRead: onReadBuf, onEvent: onEvent)
        let manager = RustHttpManager.shared
        manager.addTask(for: taskID, handler: task)

        func fetch() {
            let readFn =
                onReadBuf == nil ?
                nil : rustHttpReadIntoBuffer(taskID:buffer:maxLength:) as ReadBufCallbackWithTaskId
            data.withUnsafeBytes { (data: UnsafeRawBufferPointer) in
                // https://forums.swift.org/t/how-to-use-data-withunsafebytes-in-a-well-defined-manner/12811/11
                // https://github.com/atrick/swift/blob/type-safe-mem-docs/docs/TypeSafeMemory.rst
                // 根据Swift内存模型，内存必须且只能绑定到一种类型。按不匹配的类型使用是未定义行为
                // 而data代表了无类型的raw bytes pointer. 所以应该由拥有者指定bind类型
                // 使用assumeBind是未定义行为
                let count = data.count
                let ptr = data.baseAddress?.bindMemory(to: UInt8.self, capacity: count)
                fetch_async(ptr, count, taskID,
                            readFn,
                            rustHttpResponse(taskID:hasError:payload:count:)
                )
            }
        }
        manager.queue.async {
            if ready {
                fetch()
            } else {
                manager.waitingTask.append(fetch)
                logger.info("fetchAsync wait init!")
            }
        }
        return task
    }
}

extension RustHttpManager {
    /// 设置全局的rust proxy信息，需要先配置好rustService给rust发送设置消息。
    /// 格式如: http://127.0.0.1:8888
    /// 如果为nil, 表示不启用代理
    /// NOTE: 启用代理会禁用quic, 加密等私有传输协议的优化。可能只会对部分有相关权限的用户有效。
    public static var globalProxyURL: URL? {
        get {
            let lock = RustHttpManager.shared.lock
            lock.lock(); defer { lock.unlock() }
            return _globalProxyURL
        }
        set {
            guard let rustService = rustService?() else {
                logger.warn("should set rustService before set proxy!!")
                return
            }
            do {
                let lock = RustHttpManager.shared.lock
                lock.lock(); defer { lock.unlock() }
                _globalProxyURL = newValue
            }
            if let newValue = newValue {
                var setMesasge = SetNetworkProxyRequest()
                setMesasge.proxyURL = newValue.absoluteString
                _ = rustService.sendAsyncRequest(setMesasge).subscribe()
            } else {
                _ = rustService.sendAsyncRequest(ClearNetworkProxyRequest()).subscribe()
            }
        }
    }
    private static var _globalProxyURL: URL?

    /// 读取系统的proxy设置
    public static var systemProxyURL: URL? {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else { return nil }

        if
            let httpEnabled = unsafeBitCast(
                CFDictionaryGetValue(proxySettings, Unmanaged.passUnretained(kCFNetworkProxiesHTTPEnable).toOpaque()),
                to: Unmanaged<AnyObject>?.self)?.takeUnretainedValue() as? Bool,
            httpEnabled,
            let proxy = unsafeBitCast(
                CFDictionaryGetValue(proxySettings, Unmanaged.passUnretained(kCFNetworkProxiesHTTPProxy).toOpaque()),
                to: Unmanaged<CFString>?.self)?.takeUnretainedValue() as String?,
            var components = URLComponents(string: "http://\(proxy)")
        {
            if
                let port = unsafeBitCast(
                CFDictionaryGetValue(proxySettings, Unmanaged.passUnretained(kCFNetworkProxiesHTTPPort).toOpaque()),
                to: Unmanaged<AnyObject>?.self)?.takeUnretainedValue() as? Int
            {
                components.port = port
            }
            return components.url
        }

        return nil
    }
}

// MARK: - RustHttpEvent
private protocol RustHttpEventHandler {
    func rustHttp(response: OnFetchResponse)
    func rustHttp(readInto buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int
}

// MARK: C Callback Function
private func rustHttpResponse(taskID: Int64, hasError: Bool, payload: UnsafePointer<UInt8>?, count: Int) {
    // rust 没有创建自动释放池，不处理可能会有内存泄露
    autoreleasepool {
        guard let handler = RustHttpManager.shared.task(for: taskID) else { return }

        func wrapErrorAndForward(_ message: String) {
            var error = OnFetchResponse.OnErrorResponse()
            error.code = .others
            error.message = message
            var response = OnFetchResponse()
            response.response = .errorResponse(error)
            handler.rustHttp(response: response)
        }

        guard let payload = payload else {
            if !hasError {
                assertionFailure("rust http no error no payload response callback??")
                logger.error("rust http no error no payload response callback??")
            }
            return wrapErrorAndForward("rust http has error without payload")
        }
        let data = Data(bytes: payload, count: count)
        guard !hasError, let response = try? OnFetchResponse(serializedData: data) else {
            let message: String
            do {
                let error = try LarkError(serializedData: data)
                message = RCError.businessFailure(
                    errorInfo: BusinessErrorInfo(error)
                ).description
            } catch {
                message = RCError.sdkErrorSerializeFailure(error: error).description
            }
            return wrapErrorAndForward(message)
        }
        guard response.response != nil else {
            assertionFailure("empty OnFetchResponse!!")
            logger.error("empty OnFetchResponse")
            return wrapErrorAndForward("rust http return empty response")
        }

        handler.rustHttp(response: response)
    }
}

/// 主要是用于懒加载大数据流
///   - buffer: 存放数据的Buffer
///   - maxLength: buffer的大小
/// - Returns: 读取的字节数，返回0代表读取结束。负数代表错误
private func rustHttpReadIntoBuffer(
    taskID: Int64, buffer: UnsafeMutablePointer<UInt8>?, maxLength: Int
) -> Int32 {
    // rust 没有创建自动释放池，不处理可能会有内存泄露
    return autoreleasepool {
        guard let handler = RustHttpManager.shared.task(for: taskID) else { return -1 }
        guard let buffer = buffer else {
            assertionFailure("void http read body buffer!")
            logger.error("void http read body buffer!")
            return -2
        }
        return Int32(handler.rustHttp(readInto: buffer, maxLength: maxLength))
    }
}
