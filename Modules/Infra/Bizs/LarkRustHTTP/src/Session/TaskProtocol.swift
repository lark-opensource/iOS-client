//
//  TaskProtocol.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2023/4/14.
//

import Foundation
import HTTProtocol
// swiftlint:disable line_length
// Task内部使用的直接导流到rust的URLProtocol, 主要定制task和session task差异的部分
class RustHTTPSessionTaskProtocol: RustHttpURLProtocol {
    var sessionTask: RustHTTPSessionTask?
    override var context: RustHttpURLProtocolContext { Context(base: self) }
    required convenience init(sessionTask: RustHTTPSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        guard let request = sessionTask.currentRequest else {
            #if DEBUG || ALPHA
            fatalError("task currentRequest shouldn't nil")
            #else
            logger.error("task currentRequest shouldn't nil")
            let errorURL = URL(string: "about:error") ?? URL(fileURLWithPath: "about:error")
            self.init(request: URLRequest(url: errorURL), cachedResponse: cachedResponse, client: client)
            return
            #endif
        }
        self.init(request: request, cachedResponse: cachedResponse, client: client)
        self.sessionTask = sessionTask
    }
    #if DEBUG || ALPHA
    override func startLoading() {
        precondition(task == nil, "shouldn't used with RustHTTPSessionTask")
        super.startLoading()
    }
    #endif
    override func willStartRequestServer(request: FetchRequest?) {
        guard let request else { return }
        if let sessionTask, let session = sessionTask.session,
           let callback = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:task:willRequest:) {
            sessionTask.asyncOnDelegateQueue(session: session) {
                callback(session, sessionTask, RustHTTPRequest(original: self.request, rust: request))
            }
        }
    }
    struct Context: RustHttpURLProtocolContext {
        var base: RustHTTPSessionTaskProtocol
        var request: URLRequest { base.request }
        var task: RustHTTPSessionTask? { base.sessionTask }
        var session: RustHTTPSession? { task?.session }
        var configuration: RustHTTPSessionConfig.Raw? { session?._configuration }

        var cookieStorage: HTTPCookieStorage? {
            // httpShouldSetCookies为false时，不应该发送和设置cookies
            guard self.request.httpShouldHandleCookies else { return nil }
            if let configuration = configuration {
                if configuration.httpShouldSetCookies {
                    return configuration.httpCookieStorage
                } else {
                    return nil
                }
            }
            return HTTPCookieStorage.shared
        }

        var urlCache: URLCache? {
            if let configuration = configuration {
                return configuration.urlCache
            }
            return URLCache.shared
        }

        var cachePolicy: URLRequest.CachePolicy {
            // 优先取request的，其次是configuration上的
            if case let policy = request.cachePolicy, policy != .useProtocolCachePolicy { return policy }
            if let policy = configuration?.requestCachePolicy { return policy }
            return .useProtocolCachePolicy
        }
        var bodyStream: InputStream? {
            if let bodyStream = request.httpBodyStream { return bodyStream }
            if let body = request.httpBody { return InputStream(data: body) }
            return nil
        }
        var credentialStorage: URLCredentialStorage? {
            if let configuration = configuration {
                return configuration.urlCredentialStorage
            }
            return URLCredentialStorage.shared
        }

        var taskPriority: FetchRequest.Priority? {
            guard let task = self.task else { return nil }
            switch task.priority {
            case let priority where priority < 1 / 3:      return FetchRequest.Priority.low
            case let priority where priority > 2 / 3:      return FetchRequest.Priority.high
            default: return nil
            }
        }

        func setTaskExpectedToSend() {
            if let task = self.task, task.countOfBytesExpectedToSend < 1,
                let clength = self.request.value(forHTTPHeaderField: "Content-Length"),
                let length = Int64(clength), length > 0 {
                    task.run {
                        guard task._currentLoadingProtocol() === `base` else { return }
                        task.countOfBytesExpectedToSend = length
                    }
            }
        }

        var hasSendProgressDelegate: Bool {
            // NOTE: URLSession实现测试是始终通知的.., swift corelib实现区分了behaviour..,
            if (task?.session?.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:) != nil {
                return true
            }
            return false
        }

        func didSend(count: Int, hasProgress: Bool) {
            if count > 0, let task = self.task { // swiftlint:disable:this all
                task.run {
                    guard let session = task.session, task._currentLoadingProtocol() === `base` else { return }
                    var sent = task.countOfBytesSent
                    sent += Int64(count)
                    task.countOfBytesSent = sent
                    if hasProgress, let callback = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:) {
                        task.asyncOnDelegateQueue(session: session) {
                            callback(session, task, Int64(count), sent, task.countOfBytesExpectedToSend)
                        }
                    }
                    task.refreshResponsiveTimer()
                }
            }
        }

        func nextConnection(request: URLRequest, client: URLProtocolClient) -> RustHttpURLProtocol {
            let connection = RustHTTPSessionTaskProtocol(request: request, cachedResponse: nil, client: client)
            connection.workQueue = base.workQueue
            if let task = base.sessionTask {
                // 设置了就会调用代理..
                connection.sessionTask = task // pass current task so can use same session configuration
                #if DEBUG || ALPHA
                dispatchPrecondition(condition: .onQueue(task.workQueue))
                #endif
                task.metrics.redirectCount += 1
                task.metrics.transactionMetrics.append(connection.metrics)
            }
            return connection
        }
        func authProgress() {
            if let task {
                task.workQueue.async {
                    task.refreshResponsiveTimer()
                }
            }
        }
        func auth(challenge: URLAuthenticationChallenge) {
            base.response(event: .challenge(challenge))
        }
    }

    // MARK: RustHTTPSessionTask Client Implement
    class Client: NSObject, URLProtocolClient {
        func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) {
            // 重定向应该发起新调用，忽略旧调用.
            // 即使中断重定向, 因为有response了，也可以直接finish(但是URLSession的实现会等着调用..)
            guardRun(protocol: `protocol`) { [self](session) in
                if let callback = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:),
                  let response = redirectResponse as? HTTPURLResponse {
                    shouldBuffer = true // afterThis, newer urlProtocol response will be hold
                    task.stopResponsiveTimer()
                    let `protocol` = UncheckedSendable(`protocol`)
                    task.asyncOnDelegateQueue(session: session) { [self] in
                        callback(session, task, response, request) { request in
                            if let request {
                                self.base.run { [self] in
                                    shouldBuffer = false
                                    bufferedResponse = []
                                    guard task.session != nil, task._currentLoadingProtocol() === `protocol`.value else { return }
                                    doRedirect(newRequest: request)
                                }
                            } else {
                                // 传递和恢复response队列
                                self.base.run { [self] in
                                    shouldBuffer = false
                                    bufferedResponse = self.bufferedResponse
                                    self.bufferedResponse = []
                                    guard let session = task.session, task._currentLoadingProtocol() === `protocol`.value else { return }
                                    task.startResponsiveTimer()
                                    // forward hold response
                                    for action in bufferedResponse {
                                        action(session)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    doRedirect(newRequest: request)
                }
            }
        }

        func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) {
            // NOTE: 有些实现后跟着调用正常的response，data，finish流程，有些不会..
            // 这里选择直接短路，finish后会忽略后续调用
            urlProtocol(`protocol`, didReceive: cachedResponse.response, cacheStoragePolicy: .notAllowed)
            let data = cachedResponse.data
            if !data.isEmpty {
                urlProtocol(`protocol`, didLoad: data)
            }
            urlProtocolDidFinishLoading(`protocol`)
        }

        // swiftlint:disable:next function_body_length
        func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) {
            guardRun(protocol: `protocol`) { [self](session) in
                task.response = response
                task.countOfBytesExpectedToReceive = response.expectedContentLength

                func setCacheResponse(shouldCacheForComplete: Bool = false) throws {
                    var maxLength: Int? // nil is not need cache
                    cachePolicy = .notAllowed
                    // 测试看HEAD不应该缓存
                    let method = `protocol`.request.httpMethod?.uppercased()
                    if let urlCache = session._configuration.urlCache, method != "HEAD" {
                        switch policy {
                        case .allowed:
                            // apple willCache代理文档默认是diskSize的0.05
                            cachePolicy = policy
                            maxLength = Int(Double(urlCache.diskCapacity) * 0.05)
                        case .allowedInMemoryOnly:
                            cachePolicy = policy
                            maxLength = 0
                        case .notAllowed:
                            // CachePolicy default notAllowed
                            break
                        @unknown default: break
                        }
                    }
                    if shouldCacheForComplete { maxLength = Int.max }
                    if let maxLength {
                        cacheableResponse = response
                        cacheableData = try .init(response: response, policy: policy, maxDiskLength: maxLength)
                    }
                }
                /// return false is error
                func forceCacheResponse() -> Bool {
                    do {
                        try setCacheResponse(shouldCacheForComplete: true)
                        return true
                    } catch {
                        base.didFailWithError(RustHTTPError(
                            code: NSURLErrorUnknown, message: error.localizedDescription,
                            request: `protocol`.request, underlyingError: error))
                        return false
                    }
                }

                switch session.taskRegistry.behaviour(task: task) {
                case .callDelegate:
                    if task is RustHTTPSessionDownloadTask, (session.delegate as? RustHTTPSessionDownloadDelegate)?.rustHTTPSession(_:downloadTask:didFinishDownloadingTo:) != nil {
                        // need download URL to ensure download File
                        guard forceCacheResponse() else { return }
                    } else {
                        try? setCacheResponse()
                    }
                    if let dataDelegate = session.delegate as? RustHTTPSessionDataDelegate,
                       let dataTask = task as? RustHTTPSessionDataTask,
                       let callback = dataDelegate.rustHTTPSession(_:dataTask:didReceive:completionHandler:) {
                        task.asyncOnDelegateQueue(session: session) {
                            callback(session, dataTask, response, { _ in
                                // TODO: response control
                            })
                        }
                    }
                    // TODO: webSocketTask
                    // } else if let webSocketDelegate = delegate as? RustHTTPSessionWebSocketDelegate,
                    //           let webSocketTask = task as? RustHTTPSessionWebSocketTask {
                    //     task.asyncOnDelegateQueue(session: session) {
                    //         webSocketDelegate.urlSession(session, webSocketTask: webSocketTask, didOpenWithProtocol: webSocketTask.protocolPicked)
                    //     }
                case .noDelegate: try? setCacheResponse()
                case .dataCompletionHandler, .downloadCompletionHandler:
                    // NOTE: 测试发现大数据data会撑爆内存直接crash. 这里暂时和系统一样都没有做保护
                    _ = forceCacheResponse()
                }
            }
        }

        func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
            guardRun(protocol: `protocol`) { [self](session) in
                task.countOfBytesReceived += Int64(data.count)

                var err: Swift.Error?
                func okForAppend() -> Bool {
                    if let err {
                        base.didFailWithError(RustHTTPError(
                            code: NSURLErrorUnknown, message: err.localizedDescription,
                            request: `protocol`.request, underlyingError: err
                        ))
                        return false
                    }
                    return true
                }
                // append and may save error
                do {
                    try cacheableData?.append(data: data)
                } catch {
                    err = error
                    cacheableData = nil
                }
                switch session.taskRegistry.behaviour(task: task) {
                case .callDelegate:
                    switch task {
                    case let task as RustHTTPSessionDataTask:
                        guard let delegate = session.delegate as? RustHTTPSessionDataDelegate,
                            let callback = delegate.rustHTTPSession(_:dataTask:didReceive:)
                        else {
                            break
                        }
                        task.asyncOnDelegateQueue(session: session) {
                            callback(session, task, data)
                        }
                    case let task as RustHTTPSessionDownloadTask:
                        guard okForAppend(), cacheableData != nil else { return }
                        guard let delegate = session.delegate as? RustHTTPSessionDownloadDelegate,
                            let callback = delegate.rustHTTPSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)
                        else { break }
                        task.asyncOnDelegateQueue(session: session) {
                            callback(session, task, Int64(data.count), Int64(task.countOfBytesReceived), Int64(task.countOfBytesExpectedToReceive))
                        }
                    default: break
                    }
                case .dataCompletionHandler, .downloadCompletionHandler:
                    guard okForAppend() else { return }
                default: break
                }
            }
        }

        // DONE: 回调线程安全保证, 如果redirect之类被提前stop了，应该也只finish一次。是否有时序问题
        // swiftlint:disable:next function_body_length
        func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
            guardRun(protocol: `protocol`) { [self](session) in
                // 中断停止后续的响应
                let counter = getUniqueID()
                task.stopProtocol(.ending(counter))

                // NOTE: now 401 response handle and save by RustHttpURLProtocol, different to URLSession
                let body = cacheableData.flatMap { RustHTTPBody($0) }
                let behaviour = session.taskRegistry.behaviour(task: task)
                task.asyncOnDelegateQueue(session: session) { [self] in
                    // 这个函数调用遇到了编译器的bug..., 不能同时optional+throw.. 只能选择返回bool了
                    if let error = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession?(session, validate: task, body: body) {
                        base.didFailWithErrorInDelegateQueue(session: session, counter: counter, taskBehaviour: behaviour, error: error)
                        return
                    }
                    maySaveCache(`protocol`, session: session, body: body)

                    func forceGetURLOrError() -> URL? {
                        if let url = body?.fileURL {
                            return url
                        } else {
                            base.didFailWithErrorInDelegateQueue(
                                session: session, counter: counter, taskBehaviour: behaviour,
                                error: RustHTTPError(
                                    code: NSURLErrorUnknown, message: "invalid download data",
                                    request: `protocol`.request))
                            return nil
                        }
                    }

                    var completionActions: [() -> Void] = []
                    switch behaviour {
                    case .callDelegate:
                        if let downloadTask = task as? RustHTTPSessionDownloadTask, let callback = (session.delegate as? RustHTTPSessionDownloadDelegate)?.rustHTTPSession(_:downloadTask:didFinishDownloadingTo:) {
                            if let url = forceGetURLOrError() {
                                completionActions.append {
                                    callback(session, downloadTask, url)
                                }
                            } else { return }
                        }
                        // TODO: webSocketTask
                        completionActions.append { [self] in
                            (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession?(session, task: task, didCompleteWithError: nil)
                        }
                    case .noDelegate: break
                    case .dataCompletionHandler(let completion):
                        completionActions.append { [self] in
                            assert(cacheableResponse == task.response)
                            completion(body?.data, task.response, nil)
                        }
                    case .downloadCompletionHandler(let completion):
                        guard let url = forceGetURLOrError() else { return }
                        completionActions.append { [self] in
                            assert(cacheableResponse == task.response)
                            completion(url, task.response, nil)
                        }
                    }
                    task.finishInDelegateQueue {
                        base.async { [self] in task._invalidateProtocol() }
                        for action in completionActions {
                            action()
                        }
                    }
                }
            }
        }

        func urlProtocol(_ `protocol`: URLProtocol, didFailWithError error: Error) {
            guardRun(protocol: `protocol`) { [self](_) in
                base.didFailWithError(error)
            }
        }

        func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) {
            guardRun(protocol: `protocol`) { (session) in
                guard let sender = challenge.sender as? RustHttpURLProtocol.AuthenticateEnv else {
                    assertionFailure("pass in challenge should use AuthenticateEnv as sender")
                    challenge.sender?.performDefaultHandling?(for: challenge)
                    return
                }
                if let callback = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:task:didReceive:completionHandler:) {
                    let challenge = UncheckedSendable(challenge)
                    self.task.asyncOnDelegateQueue(session: session) { [self] in
                        callback(session, task, challenge.value) { (disposition, credential) in
                            sender.onAuthResponse(disposition, credential, challenge.value)
                        }
                    }
                } else {
                    challenge.sender?.performDefaultHandling?(for: challenge)
                }
            }
        }
        func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) {
            #if DEBUG || ALPHA
            fatalError("no implementation")
            #endif
        }
        func guardRun(`protocol`: URLProtocol, action: @escaping (RustHTTPSession) -> Void) {
            base.run { [self] in
                /// 检查protocol一致性，并保证在queue上运行, 这样保证protocol的状态修改串行, 避免多余的回调
                guard let session = task.session, task._currentLoadingProtocol() === `protocol` else { return }
                if shouldBuffer {
                    self.bufferedResponse.append(action)
                } else {
                    action(session)
                }
                task.refreshResponsiveTimer()
            }
        }

        func maySaveCache(_ `protocol`: URLProtocol, session: RustHTTPSession, body: RustHTTPBody?) {
            session.assertInDelegateQueue()
            // NOTE: 系统API说willCacheResponse有5%的diskSize限制. 这里缓存要再检查一下size
            guard
                let body, let cache = session._configuration.urlCache, cachePolicy != .notAllowed,
                let response = cacheableResponse, let task = task as? RustHTTPSessionDataTask,
                body.length < cache.memoryCapacity / 8 || body.length < cache.diskCapacity / 20
            else { return }

            let cacheable = CachedURLResponse(response: response, data: body.data, storagePolicy: cachePolicy)
            let request = `protocol`.request
            if let callback = (session.delegate as? RustHTTPSessionDataDelegate)?.rustHTTPSession(_:dataTask:willCacheResponse:completionHandler:) {
                callback(session, task, cacheable) { (actualCacheable) in
                    if let actualCacheable = actualCacheable {
                        cache.storeCachedResponse(actualCacheable, for: request)
                    }
                }
            } else {
                cache.storeCachedResponse(cacheable, for: request)
            }
        }
        func doRedirect(newRequest: URLRequest) {
            #if DEBUG || ALPHA
            dispatchPrecondition(condition: .onQueue(task.workQueue))
            #endif
            let redirectLimit = 20
            if task.metrics.redirectCount >= redirectLimit {
                base.didFailWithError(RustHTTPError(
                    code: NSURLErrorHTTPTooManyRedirects, message: "too many redirects",
                    request: task.currentRequest
                    ))
            } else {
                task.stopProtocol(.toBeCreated)
                task.currentRequest = newRequest
                task.metrics.redirectCount += 1
                task.startProtcol()
            }
        }

        var base: RustHTTPSessionTask.Client
        var task: RustHTTPSessionTask { base.task }

        var cachePolicy: URLCache.StoragePolicy = .notAllowed
        var cacheableData: HTTProtocolBuffer?
        var cacheableResponse: URLResponse?
        var shouldBuffer = false // 设置为true拦截response
        var bufferedResponse: [(RustHTTPSession) -> Void] = []
        internal init(base: RustHTTPSessionTask) {
            self.base = .init(task: base)
        }
    }
}

extension RustHTTPSessionTask {
    /// simple sessionTask impl wrapper, no state
    class Client: HTTProtocolWorkQueue {
        init(task: RustHTTPSessionTask) {
            self.task = task
        }
        var task: RustHTTPSessionTask

        /// 需要考虑线程安全和并发时序。
        /// 目前有两个输入：外部接口和protocol回调.
        /// protocol的生命周期到这里已经结束了，可以忽略。
        /// 但是这里如果要和delegate同步交互的情况下，外部接口随时可能更改状态，所以需要确认一致性.
        /// 比如可以suspend，cancel等等
        /// NOTE: 暂定行为如下：
        /// 1. complete的调用可以打断其他状态(通过lock保证state原子性，没有在workQueue上运行)
        /// 2. cancel可以打断除complete之外的中间状态（只complete一次）
        /// 3. suspend, resume对应的暂停恢复，需要根据状态区分处理（一般是取消重试。结束期间是暂停和恢复）
        func didFailWithError(_ error: Error) {
            #if DEBUG || ALPHA
            dispatchPrecondition(condition: .onQueue(task.workQueue))
            #endif
            guard let session = task.session, task.valid else {
                return
            }
            // 停止后续的响应
            let counter = getUniqueID()
            task.stopProtocol(.ending(counter))

            let behaviour = session.taskRegistry.behaviour(task: task)
            task.asyncOnDelegateQueue(session: session) {
                self.didFailWithErrorInDelegateQueue(session: session, counter: counter, taskBehaviour: behaviour, error: error)
            }
        }
        func didFailWithErrorInDelegateQueue(session: RustHTTPSession, counter: UInt64, taskBehaviour: RustHTTPSession.TaskRegistry.Behaviour, error: Error) {
            session.assertInDelegateQueue()
            let reportError = { [self] in _report(session: session, taskBehaviour: taskBehaviour, error: error) }
            func isCancelled() -> Bool { task.state == .canceling }

            if let retryHandler = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:shouldRetry:with:completionHandler:),
               // cancel时不重试
               !isCancelled() {
                let finished = UncheckedSendable(false)
                // NOTE: 必须且只能调用一次，如果不调用，没有finish，task和session的循环引用不会打破，会有内存泄露
                retryHandler(session, task, error) { newRequest in
                    if finished.value == true {
                        #if DEBUG || ALPHA
                        fatalError("completionHandler can only call once!!")
                        #else
                        return
                        #endif
                    }
                    finished.value = true
                    self.run { [self] in
                        guard task.session != nil, task._protocolStorage.id == counter else { return }
                        if let newRequest {
                            task.stopProtocol(.toBeCreated) // ready to refetch
                            task.currentRequest = newRequest
                            task.metrics.retryCount += 1
                            task.startProtcol() // 如果非running会被里面拦截
                        } else {
                            task.asyncOnDelegateQueue(session: session, reportError)
                        }
                    }
                }
            } else {
                reportError()
            }
        }
        /// NOTE: 保证只结束一次, 需要在delegateQueue调用
        fileprivate func _report(session: RustHTTPSession, taskBehaviour: RustHTTPSession.TaskRegistry.Behaviour, error: Error) {
            session.assertInDelegateQueue()
            task.finishInDelegateQueue {
                self.async { self.task._invalidateProtocol() }
                task.error = error
                // notify finish callback
                switch taskBehaviour {
                case .callDelegate:
                    (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession?(session, task: task, didCompleteWithError: error)
                case .noDelegate: break
                case .dataCompletionHandler(let completion):
                    completion(nil, task.response, error)
                case .downloadCompletionHandler(let completion):
                    completion(nil, task.response, error)
                }
            }
        }
        // MARK: workQueue
        public func isInQueue() -> Bool {
            DispatchQueue.getSpecific(key: task.queueKey) == true
        }

        public func async(execute: @escaping () -> Void) {
            task.workQueue.async(execute: execute)
        }

        public func asyncAfter(interval: TimeInterval, execute: @escaping () -> Void) {
            task.workQueue.asyncAfter(deadline: .now() + interval, execute: execute)
        }

        public func run(execute: @escaping () -> Void) {
            if isInQueue() {
                execute()
            } else {
                task.workQueue.async(execute: execute)
            }
        }
    }
}

class UncheckedSendable<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

// swiftlint:enable line_length
