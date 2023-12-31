//
//  BaseHTTProtocol.swift
//  HTTProtocol
//
//  Created by SolaWing on 2019/7/18.
//

import UIKit
import Foundation
import LKCommonsLogging
import EEAtomic

let logger = Logger.log(BaseHTTProtocol.self, category: "BaseHTTProtocol")

/// this class's responsibility is ensure main flow correct.
/// mainly focus on the URLProtocolClient's interact
///
/// subclass should override handler to provide a concrete implementation for provide resource
/// (include dealing with cache, cookie, and auth)
/// subclass shouldn't call client directly
open class BaseHTTProtocol: URLProtocol {
    open override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        // debug(reflect(request))
        return scheme == "https" || scheme == "http"
    }
    open override class func canInit(with task: URLSessionTask) -> Bool {
        guard let scheme = task.currentRequest?.url?.scheme?.lowercased() else { return false }
        // debug("\(task): \(reflect(task.currentRequest))")
        return scheme == "https" || scheme == "http"
    }
    open override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        //        debug(request.description)
        return request.canonicalHTTPRequest()
    }
    #if DEBUG
    // swiftlint:disable identifier_name
    open override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        let v = super.requestIsCacheEquivalent(a, to: b)
        debug("<\(a)> equal to <\(b)>? \(v)")
        return v
    }
    #endif
    /// subclass need to override for providing resource loading.
    open var handler: HTTProtocolHandler {
        fatalError("should override in subclassl to provide a Handler")
    }
    // MARK: - State and Properties
    // TODO: metrics
    public enum State: Int, Comparable {
        public static func < (lhs: BaseHTTProtocol.State, rhs: BaseHTTProtocol.State) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        case waiting        /// 初始状态
        case starting       /// 收到startLoading请求，开始加载数据
        case redirecting    /// 收到redirecting消息，重定向中
        // case authenticating /// 收到auth消息，等待auth中, 
        case waitingData    /// 收到header响应，等待数据
        case waitingFinish  /// 等待结束状态，不再转发任何消息
        case finish         /// 已经结束
    }
    public private(set) var state = State.waiting
    /// use this var for check request is finish and shouldn't do any further task.
    public var isFinish: Bool { return state >= .waitingFinish }
    // swiftlint:disable identifier_name
    // use underscore prefix to indicate private var, but internal for split into multiple file
    #if DEBUG
    var _holdClient: URLProtocolClient? {
        // avoid drop client unconditionally
        willSet { assert(_holdClient == nil || newValue == nil) }
    }
    #else
    var _holdClient: URLProtocolClient?
    #endif
    var safeClient: URLProtocolClient? {
        if !isFinish {
            if let holdClient = self._holdClient { return holdClient }
            return self.client
        } else {
            // debug("refer client after finished! \(Thread.callStackSymbols[0..<3])")
            return nil
        }
    }
    func _forwardHoldResponses() {
        if let replayClient = self._holdClient as? URLProtocolRecordClient {
            self._holdClient = nil // before forward, clear old hold records
            // wait finish make safeClient return nil.
            // but the hold redirect message is not deliver.
            if self.state != .finish, let client = self.client {
                debug(dump(request: self.request))
                replayClient.forwardRecords(to: client, from: self)
            }
        }
    }
    // swiftlint:enable identifier_name
    /// receive finish event, waiting for finish and don't send any further message to client
    private func waitingFinish() {
        if !isFinish {
            self.state = .waitingFinish
        }
    }
    private func finish() {
        if state != .finish { // 资源清理收敛
            // stoploading会在complete后调用. 收到该调用后应该停止调用client. 同时清理资源
            // 现在使用safeClient来根据状态返回对应client
            let oldState = state
            self.state = .finish
            if oldState != .waiting {
                self.handler.stopLoading(request: self) // only call after call startLoading
            }
            _holdClient = nil
        }
    }
    #if DEBUG
    deinit {
        debug(dump(request: self.request))
    }
    #endif

    // MARK: - Thread Guard
    // https://developer.apple.com/library/archive/samplecode/CustomHTTPProtocol/Introduction/Intro.html#//apple_ref/doc/uid/DTS40013653-Intro-DontLinkElementID_2
    // apple delegate all client callback to start thread.
    // so may assume client method is not thread safe and callback in same thread

    /// 保证线程安全的队列
    private var _workQueue: HTTProtocolWorkQueue?
    public var workQueue: HTTProtocolWorkQueue? {
        get {
            #if DEBUG || ALPHA
            precondition(_workQueue != nil, "should set workQueue before use it!")
            #endif
            return _workQueue
        }
        set {
            _workQueue = newValue
        }
    }

    private var counter = DispatchGroup()
    /// called when startLoading, default set workQueue by use current Thread if not set
    open func setupCallbackThread() {
        guard _workQueue == nil else { return }

        let startThread = Thread.current
        var mode = [RunLoop.Mode.default]
        if let v = RunLoop.current.currentMode, v != .default {
            mode.append(v)
        }
        workQueue = WorkQueue(thread: startThread, mode: mode)
        Self.monitorStart(thread: startThread, mode: mode)
    }
    // MARK: - Loading API
    override open func startLoading() {
        // FIXME: 是否做并发数限制，导流的情况下，URLSession好像没做并发数限制..
        assert(self.state == .waiting, "startLoading should call only once")
        // debug( dump(request:request) ) // request rust have json log
        setupCallbackThread()

        self.state = .starting
        debug( "\(dump(request: self.request)) onevent: startLoading" )
        self.handler.startLoading(request: self)
    }
    override open func stopLoading() {
        finish()
        debug(dump(request: self.request))
    }
    // MARK: - Callback
    public typealias ClientEvent = URLProtocolForwardClient.Event.Kind
    /// public response api for handler, ensure deal event serially on start thread
    public func response(event: ClientEvent) {
        // if already on start thread and no queued event, call directly and avoid a async call
        if workQueue?.isInQueue() == true, self.counter.wait(timeout: DispatchTime.now()) == .success {
            self._response(event: event)
            return
        }
        self.counter.enter()
        self.workQueue?.async { [weak self] in
            guard let self = self else { return }
            self.counter.leave()
            self._response(event: event)
        }
    }
    private func _response(event: ClientEvent) {
        guard !isFinish else { return } // 如果异步时已经结束了，就直接忽略
        debug( "\(dump(request: self.request)) onevent: \(event)" )
        switch event {
        case .redirect(let newRequest, let response):
            self.redirect(to: newRequest, with: response)
        case .receive(response: let response, policy: let policy):
            self.response(response, policy: policy)
        case .data(let v):
            self.receive(data: v)
        case .finish:
            assert(self.state > .starting) // finish前应该收到过response
            self.safeClient?.urlProtocolDidFinishLoading(self)
            self.waitingFinish()
        case .error(let error):
            self.safeClient?.urlProtocol(self, didFailWithError: error)
            self.waitingFinish()
        case .cached(let cachedResponse):
            self.safeClient?.urlProtocol(self, cachedResponseIsValid: cachedResponse)
            self.waitingFinish() // 收到缓存响应后已经结束，不再转发任何消息
        case .challenge(let challenge):
            // TODO: 验证在URLSession和Rust网络下的行为一致性
            self.safeClient?.urlProtocol(self, didReceive: challenge)
        case .cancel(let challenge):
            self.safeClient?.urlProtocol(self, didCancel: challenge)
        }
    }
    private func response(_ response: URLResponse, policy: URLCache.StoragePolicy) {
        guard self.state < .waitingData else {
            // 代码留着检测预防rust重复回调的问题
            let message = "\(dump(request: self.request)) should receive header response only once"
            assertionFailure(message)
            logger.warn("should receive header response only once")
            return
        }
        self.state = .waitingData
        self.safeClient?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
    }
    private func redirect(to newRequest: URLRequest, with response: URLResponse) {
        guard self.state == .starting else {
            let message = "\(dump(request: self.request)) should receive redirect before receive response"
            assertionFailure(message)
            logger.warn("should receive redirect before receive response")
            return
        }
        self.state = .redirecting
        // redirect api 将导致client触发新请求
        // URLSession发新请求前会调用stop进行cancel
        // WKWebview不会调用cancel
        //
        // 而如果重定向后，还有client的消息延迟发送, 可能造成response和error都为nil的异常回应
        // 经过在startLoading线程测试，如果延迟发送didReceiveResponse, 异常回应为这个response
        // 而如果startLoading直接response finish, 也是response和error都为nil的回应
        // 所以极有可能系统把延迟的回应当成了下一次重定向请求的回应
        // 如果在异步线程上回调，不卡startLoading线程，延迟足够长时间后，则不会触发异常，应该被忽略了。
        // 进一步观察到client在stopLoading后，有drop操作。
        //
        // 所以猜测在client异步发送消息给session等后，session决定重定向，状态改变, 异步drop client并等待下一次请求。
        // 如果我的回调在这之前收到就没事，状态改变会丢弃之前的response。在这之后再到达就出问题。但更后面一点client被drop后又没事了。
        //
        // 如果重定向后不在回调，一般情况都正常，但不能控制获取非重定向的response, 和URLSession不兼容
        // 而如果单纯延迟结束回调，高并发时堆积在网络线程，反而导致改变状态后到异步drop的时间非常长(甚至可以长达几秒)
        // 而如果一次性进行回调，在模拟器上测着正常，但在真机上还是有问题
        //
        // 现在暂时的解法是:
        // 进行延迟等待，同时用queue控制startThread的堵塞和占用, 保证URLSession等的调用能即时响应，从而清理资源忽略旧client上的回调
        // 现在暂定延迟0.05s, 如果不堵塞的情况应该是够用了。
        // 但如果delegate回应刚好延迟相近的时间，仍然有可能撞上异步同时发消息响应错误的异常。
        self.safeClient?.urlProtocol(self, wasRedirectedTo: newRequest, redirectResponse: response)
        self._holdClient = URLProtocolRecordClient { [weak self] _, event in
            // recordClient会记录并引用protocol
            // 结束释放replayClient, 并回放录制的数据给原client
            if event.data.isFinishEvent {
                let delayTimeForAvoidSystemError = 0.05
                self?.workQueue?.asyncAfter(interval: delayTimeForAvoidSystemError) {
                    self?._forwardHoldResponses()
                }
            }
        }
    }
    private func receive(data: Data) {
        if !(self.state == .waitingData) {
            assertionFailure("should receive header before receive body data")
            logger.warn("should receive header before receive body data")
        }
        self.safeClient?.urlProtocol(self, didLoad: data)
    }

    // MARK: - Monitor
    /// 监控协议线程卡死的回调
    // - Parameter whenStuck: called when stuck
    public static func setupProtocolThreadMonitor(timeout: TimeInterval, whenStuck: @escaping (Thread) -> Void) {
        // only support one observer..
        monitor = Monitor(whenStuck: whenStuck, timeout: timeout)
    }
    public static func stopThreadMonitor() {
        monitor = nil // release to automatically stop
    }
    class Monitor: NSObject {
        var whenStuck: (Thread) -> Void
        var timeout: TimeInterval
        var thread: Thread?
        var mode: [RunLoop.Mode] = []
        init(whenStuck: @escaping (Thread) -> Void, timeout: TimeInterval) {
            self.whenStuck = whenStuck
            self.timeout = timeout
        }
        deinit {
            counter.deallocate()
        }
        var counter = AtomicUIntCell(1)
        @objc
        func heartbeat() {
            _ = self.counter.increment()
        }
        func schedule(current: UInt) {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let self, let thread = self.thread else { return }
                // check if heartbeat counter changed
                var counter = self.counter.value
                if counter == current {
                    // stuck and not change since last counter
                    self.whenStuck(thread)
                    counter = self.counter.value // update counter before call heartbeat
                }
                // send heartbeat
                self.perform(#selector(self.heartbeat), on: thread, with: nil,
                             waitUntilDone: false, modes: self.mode.map { $0.rawValue })
                // should heartbeat before next schedule
                self.schedule(current: counter)
            }
        }
    }
    @AtomicObject static var monitor: Monitor?
    fileprivate static func monitorStart(thread: Thread, mode: [RunLoop.Mode]) {
        Self._monitor.withLocking { (monitor) in
            guard let monitor, monitor.thread == nil else { return }
            guard thread.name == "com.apple.CFNetwork.CustomProtocols" else { return }
            // only set once
            monitor.thread = thread
            monitor.mode = mode
            monitor.schedule(current: 0)
        }
    }
}
