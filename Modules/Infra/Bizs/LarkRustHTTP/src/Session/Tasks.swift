//
//  Tasks.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2023/4/11.
//

import Foundation
import EEAtomic

// swiftlint:disable missing_docs line_length type_name identifier_name unused_setter_value file_length

// TODO: retain cycle, ensure cleanup
@objc
public class RustHTTPSessionTask: NSObject {
    public typealias ID = Int
    // 一次task可能对应多次request，所以不能用rust内部的requestID
    static let counter = AtomicUIntCell(1)
    // MARK: Public Propreties
    @objc public let taskIdentifier: ID = Int(bitPattern: RustHTTPSessionTask.counter.increment())
    /// Sets a task-specific delegate. Methods not implemented on this delegate will
    /// still be forwarded to the session delegate.
    /// 
    /// Cannot be modified after task resumes. Not supported on background session.
    /// 
    /// Delegate is strongly referenced until the task completes, after which it is
    /// reset to `nil`.
    // TODO: 需要task级别的delegate定制回调能力时再来实现
    // @objc public var delegate: URLSessionTaskDelegate? // swiftlint:disable:this weak_delegate
    @objc public let originalRequest: URLRequest
    /// May differ from originalRequest due to http server redirection
    @objc dynamic public internal(set) var currentRequest: URLRequest? {
        get { lock.withLocking { _currentRequest } }
        set { lock.withLocking { _currentRequest = newValue } }
    }
    private var _currentRequest: URLRequest?
    @objc public internal(set) var state: State {
        get { lock.withLocking { _state } }
        set { lock.withLocking { _state = newValue } }
    }
    @objc dynamic public internal(set) var response: URLResponse? {
        get { lock.withLocking { _response } }
        set { lock.withLocking { _response = newValue } }
    }
    private var _response: URLResponse?
    @objc dynamic public internal(set) var error: Error? {
        get { lock.withLocking { _error } }
        set { lock.withLocking { _error = newValue } }
    }
    private var _error: Error?
    @objc public var priority: Float {
        get {
            return lock.withLocking { return self._priority }
        }
        set {
            lock.withLocking { self._priority = newValue }
        }
    }
    fileprivate var _priority: Float = URLSessionTask.defaultPriority
    @objc public internal(set) var retryCount: Int {
        get { _metrics.retryCount }
        set { _metrics.retryCount = newValue }
    }

    // MARK: Progress Properties
    @objc public let progress = Progress(totalUnitCount: -1)
    /// Number of body bytes already received
    @objc dynamic public internal(set) var countOfBytesReceived: Int64 {
        get {
            return lock.withLocking { return self._countOfBytesReceived }
        }
        set {
            lock.withLocking { self._countOfBytesReceived = newValue }
            updateProgress()
        }
    }
    fileprivate var _countOfBytesReceived: Int64 = 0

    /// Number of body bytes already sent */
    @objc dynamic public internal(set) var countOfBytesSent: Int64 {
        get {
            return lock.withLocking { return self._countOfBytesSent }
        }
        set {
            lock.withLocking { self._countOfBytesSent = newValue }
            updateProgress()
        }
    }
    fileprivate var _countOfBytesSent: Int64 = 0

    /// Number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
    @objc public internal(set) var countOfBytesExpectedToSend: Int64 = 0 {
        didSet { updateProgress() }
    }

    /// Number of bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
    @objc public internal(set) var countOfBytesExpectedToReceive: Int64 = 0 {
        didSet { updateProgress() }
    }

    convenience init(session: RustHTTPSession, request: URLRequest) {
        self.init(session: session, request: request, body: Self.knownBody(from: request))
    }
    init(session: RustHTTPSession, request: URLRequest, body: _Body?) {
        self.session = session
        self.originalRequest = request
        self.workQueue = DispatchQueue(label: "RustHTTPSessionTask<\(taskIdentifier)>", target: session.workQueue)
        self.knownBody = body
        self.workQueue.setSpecific(key: queueKey, value: true)
        super.init()
        self._currentRequest = request
        #if DEBUG
        _ = Self.resourceCounter.increment()
        #endif
    }
    deinit {
        lock.deallocate()
        #if DEBUG
        _ = Self.resourceCounter.decrement()
        #endif
    }
    #if DEBUG || ALPHA
    static public let resourceCounter = AtomicInt64Cell(0)
    #endif

    // MARK: Private Property
    let lock = UnfairLockCell() // protect simple property
    var session: RustHTTPSession? // NOTE: nil after finish to break retain cycle.
    let workQueue: DispatchQueue
    let queueKey = DispatchSpecificKey<Bool>()
    /// run action in workQueue. if already in workQueue, run directly
    func run(inWorkQueue action: @escaping () -> Void) {
        Client(task: self).run(execute: action)
    }

    internal let knownBody: _Body? // nil use to defer get
    static func knownBody(from req: URLRequest) -> _Body {
        if let body = req.httpBody {
            return .data(body)
        } else if let stream = req.httpBodyStream {
            return .stream(stream)
        }
        return .none
    }
    func getBody(completion: @escaping (_Body) -> Void) {
        if let body = knownBody {
            completion(body)
            return
        }
        if let session = session, let callback = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:task:needNewBodyStream:) {
            // lazy get body
            asyncOnDelegateQueue(session: session) {
                callback(session, self) { (stream) in
                    if let stream = stream {
                        completion(.stream(stream))
                    } else {
                        completion(.none)
                    }
                }
            }
        } else {
            completion(.none)
        }
    }

    class DelegateActionCompleteInfo {
        /// AtomicFlag to indicate if has change. false mean no change. can only set once
        var setted: AtomicBoolCell = .init(false)
        var action: (() -> Void)?
        deinit { setted.deallocate() }
    }
    private weak var _lastDelegateActionInfo: DelegateActionCompleteInfo?
    func asyncOnDelegateQueue(session: RustHTTPSession, _ action: @escaping () -> Void) {
        // 使用operation dependecy, 会在最后才一起释放block，容易堆积内存和延迟释放。
        // NOTE: 且测试中还必现dealloc崩溃，改用其他保证同步的方法..
        let currentInfo = DelegateActionCompleteInfo()
        let wrapAction = { [weak session] in
            #if DEBUG || ALPHA
            Thread.current.threadDictionary["RustHTTPSessionDelegateQueue"] = true
            defer { Thread.current.threadDictionary.removeObject(forKey: "RustHTTPSessionDelegateQueue") }
            #endif

            action()

            if currentInfo.setted.exchange(true) == true, let action = currentInfo.action, let session {
                currentInfo.action = nil
                // already set before finish, run next action, async to avoid stackoverflow
                session.delegateQueue.addOperation(action)
            }
        }
        var nowait = true
        lock.withLocking {
            if let _lastDelegateActionInfo {
                _lastDelegateActionInfo.action = wrapAction // write in before set flag
                // return value means action if finished. if no finish, return false and mark next action
                nowait = _lastDelegateActionInfo.setted.exchange(true)
                if nowait { _lastDelegateActionInfo.action = nil } // remove to avoid unnecessary retain
            }
            _lastDelegateActionInfo = currentInfo
        }
        if nowait {
            session.delegateQueue.addOperation(wrapAction)
        }
    }

    // MARK: State Change
    #if DEBUG || ALPHA
    @LockGuard var _state: State = .suspended
    @LockGuard fileprivate var suspendCount = 1
    #else
    var _state: State = .suspended
    fileprivate var suspendCount = 1
    #endif
    // task 任务结束, 后续不再可用. 需要确保这个的调用
    func finishInDelegateQueue(beforeAction: () -> Void) {
        guard let session = self.session else { return }
        session.assertInDelegateQueue()
        let metrics: RustHTTPSessionTaskMetrics
        do {
            lock.lock(); defer { lock.unlock() }
            if _state == .completed { return }

            let now = Date()
            // NOTE: metrics is immutable after finish
            metrics = self._metrics
            if now > metrics.taskInterval.start {
                metrics.taskInterval.end = now // avoid crash
            }
            self._state = .completed
        }

        if let metricsCallback = (session.delegate as? RustHTTPSessionTaskDelegate)?.rustHTTPSession(_:task:didFinishCollecting:) {
            metricsCallback(session, self, metrics)
        }
        beforeAction()
        session.workQueue.async {
            session.taskRegistry.remove(self)
            self.session = nil
        }
    }

    let _metrics = RustHTTPSessionTaskMetrics() // use in workQueue
    var metrics: RustHTTPSessionTaskMetrics {
        #if DEBUG || ALPHA
        dispatchPrecondition(condition: .onQueue(self.workQueue))
        #endif
        return _metrics
    }
    /// NOTE: 结束后才应该访问
    @objc public var rustMetrics: [RustHttpMetrics] { 
        guard self.state == .completed else {
            #if DEBUG || ALPHA
            fatalError("should access rustMetrics only after task completed!")
            #else
            return [] // 异常兜底，避免多线程访问崩溃
            #endif
        }
        return _metrics.transactionMetrics
    }

    func updateProgress() {
        self.workQueue.async {
            let progress = self.progress

            switch self.state {
            case .canceling, .completed:
                let total = progress.totalUnitCount
                let finalTotal = total < 0 ? 1 : total
                progress.totalUnitCount = finalTotal
                progress.completedUnitCount = finalTotal

            default:
                let toBeSent: Int64?
                if self.countOfBytesExpectedToSend >= 0 {
                    toBeSent = self.countOfBytesExpectedToSend
                // } else if self.countOfBytesClientExpectsToSend != NSURLSessionTransferSizeUnknown && self.countOfBytesClientExpectsToSend > 0 {
                //     toBeSent = Int64(clamping: self.countOfBytesClientExpectsToSend)
                } else {
                    toBeSent = nil
                }

                let sent = self.countOfBytesSent

                let toBeReceived: Int64?
                if self.countOfBytesExpectedToReceive > 0 {
                    toBeReceived = Int64(clamping: self.countOfBytesExpectedToReceive)
                // } else if self.countOfBytesClientExpectsToReceive != NSURLSessionTransferSizeUnknown && self.countOfBytesClientExpectsToReceive > 0 {
                //     toBeReceived = Int64(clamping: self.countOfBytesClientExpectsToReceive)
                } else {
                    toBeReceived = nil
                }

                let received = self.countOfBytesReceived

                progress.completedUnitCount = sent.addingReportingOverflow(received).partialValue

                if let toBeSent = toBeSent, let toBeReceived = toBeReceived {
                    progress.totalUnitCount = toBeSent.addingReportingOverflow(toBeReceived).partialValue
                } else {
                    progress.totalUnitCount = NSURLSessionTransferSizeUnknown
                }

            }
        }
    }
    private var timerID = 0
    #if DEBUG || ALPHA
    @WorkQueueGuard private var latestResponseTime: Date?
    #else
    private var latestResponseTime: Date?
    #endif
    func refreshResponsiveTimer() {
        if latestResponseTime != nil {
            latestResponseTime = Date()
        }
    }
    func startResponsiveTimer() {
        guard let timeout = self.currentRequest?.timeoutInterval, timeout > 0 else { return }
        latestResponseTime = Date()
        timerID &+= 1
        // 如果workQueue被长时间占用，可能来不及更新？
        workQueue.asyncAfter(wallDeadline: .now() + timeout) {[weak self, timerID] in
            self?.fireDebounceTimer(id: timerID, timeout: timeout)
        }
    }
    func stopResponsiveTimer() {
        latestResponseTime = nil
    }
    func fireDebounceTimer(id: Int, timeout: TimeInterval) {
        guard let latestResponseTime, id == timerID else { return }
        let left = timeout - (-latestResponseTime.timeIntervalSinceNow)
        if left > 0 {
            // after refresh latestResponseTime, continue
            self.workQueue.asyncAfter(wallDeadline: .now() + left) { [weak self] in
                self?.fireDebounceTimer(id: id, timeout: timeout)
            }
        } else {
            // time out cancel
            let error = RustHTTPError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, message: "responsive timeout", request: self.currentRequest)
            Client(task: self).didFailWithError(error)
        }
    }

    // MARK: Protocol State Manage
    enum ProtocolState {
        case toBeCreated // lazy等待创建
        case creating(UInt64)
        // case awaitingCacheReply(Bag<(URLProtocol?) -> Void>)
        case existing(URLProtocol)
        case ending(UInt64) // 异步等待中，可能被打断，需要校验唯一id
        case invalidated // 结束后不能再次使用

        /// 中断的ID
        var id: UInt64? {
            switch self {
            case .creating(let v), .ending(let v):
                return v
            default: return nil
            }
        }
    }
    // NOTE: has retain cycle, must finish or cancel to release protocol
    // 注意异步情况下，没有原子性保证，随时有可能打断流程，打断和中断都要可控
    #if DEBUG || ALPHA
    @WorkQueueGuard var _protocolStorage: ProtocolState = .toBeCreated
    #else
    var _protocolStorage: ProtocolState = .toBeCreated
    #endif

    // 需要保证start和stop的配对和一次性调用, 防重和遗漏
    // swiftlint:disable:next function_body_length
    func startProtcol(clearBody: Bool = false) {
        // _protocolStorage: toBeCreated -> waiting -> existing
        #if DEBUG || ALPHA
        dispatchPrecondition(condition: .onQueue(self.workQueue))
        #endif
        // FIXME: 网络并发数限制？现在session的workQueue是串行的，应该还好..
        guard self.state == .running, case .toBeCreated = _protocolStorage, let session = self.session else { return }
        func unsupportError() {
            var userInfo: [String: Any] = [NSLocalizedDescriptionKey: "unsupported URL"]
            if let url = self.currentRequest?.url {
                userInfo[NSURLErrorFailingURLErrorKey] = url
                userInfo[NSURLErrorFailingURLStringErrorKey] = url.absoluteString
            }
            let urlError = URLError(_nsError: NSError(domain: NSURLErrorDomain,
                                                      code: NSURLErrorUnsupportedURL,
                                                      userInfo: userInfo))
            Client(task: self).didFailWithError(urlError)
        }
        guard var req = currentRequest, RustHTTPSessionTaskProtocol.canInit(with: req)
        else { return unsupportError() }
        func continueWithBody(_ body: _Body) {
            lock.withLocking {
                self._countOfBytesSent = 0
                self._countOfBytesReceived = 0
                self.countOfBytesExpectedToReceive = 0
                self.countOfBytesExpectedToSend = (try? body.getBodyLength())
                    .flatMap { Int64(exactly: $0) }
                    ?? NSURLSessionTransferSizeUnknown
                if countOfBytesExpectedToSend > 0 && req.value(forHTTPHeaderField: "Content-Length") == nil {
                    req.setValue(countOfBytesExpectedToSend.description, forHTTPHeaderField: "Content-Length")
                }
                // TODO: 现在retry和redirect不好提供新的body..
                switch body {
                case .none:
                    req.httpBodyStream = nil
                    req.setValue(nil, forHTTPHeaderField: "Content-Length") // 没有body时需要清空
                case .data(let data):
                    req.httpBody = data
                case .file(let url):
                    // lint:disable:next lark_storage_check
                    req.httpBodyStream = InputStream(url: url)
                case .stream(let stream):
                    req.httpBodyStream = stream
                }
            }
            if let headers = session._configuration.httpAdditionalHeaders {
                for (key, value) in headers where req.value(forHTTPHeaderField: key) == nil {
                    req.setValue(value, forHTTPHeaderField: key)
                }
            }
            /// NOTE: redirect, retry等场景可能导致被重复标准化。需要注意影响
            self.currentRequest = RustHTTPSessionTaskProtocol.canonicalRequest(for: req)
            let client = RustHTTPSessionTaskProtocol.Client(base: self)
            let urlProtocol = RustHTTPSessionTaskProtocol(sessionTask: self, cachedResponse: nil, client: client)
            urlProtocol.workQueue = client.base // use queue instead of default current thread
            metrics.transactionMetrics.append(urlProtocol.metrics)

            _protocolStorage = .existing(urlProtocol)
            startResponsiveTimer()
            urlProtocol.startLoading()
        }

        let shouldNoBody = req.httpMethod?.caseInsensitiveCompare("GET") == .orderedSame
        if shouldNoBody {
            /// redirect成GET时，不继承原来的body
            /// 另外get带body可能导致各种基础网络库卡死
            continueWithBody(.none)
        } else {
            let counter = getUniqueID()
            self._protocolStorage = .creating(counter) // 状态锁定防后续重入, 或者重置打断
            self.getBody { (body) in
                Client(task: self).run {
                    guard self.state == .running, self._protocolStorage.id == counter else { return }
                    // 状态未发生变化，继续创建
                    continueWithBody(body)
                }
            }
        }
        // TODO: useProtocolCachePolicy默认不传cache, 需要使用protocol自己加载.
        // 而目前rusthttpprotocol有加载cache，task就先不处理了
    }
    func stopProtocol(_ value: URLProtocol) {
        value.stopLoading()
        if let metrics = (value as? RustHttpURLProtocol)?.metrics, metrics.fetchEndDate == nil {
            metrics.fetchEndDate = Date()
        }
        stopResponsiveTimer()
    }
    func stopProtocol(_ value: ProtocolState) {
        // 保证existing的清理, 并切换到目标状态

        #if DEBUG || ALPHA
        dispatchPrecondition(condition: .onQueue(workQueue))
        #endif
        var oldProtocol: URLProtocol?
        switch _protocolStorage {
        case .existing(let urlProtocol):
            oldProtocol = urlProtocol
        case .invalidated: return // after invalid, shouldn't change
        default: break
        }
        _protocolStorage = value
        if let oldProtocol { stopProtocol(oldProtocol) }
    }
    func _suspend() {
        #if DEBUG || ALPHA
        dispatchPrecondition(condition: .onQueue(workQueue))
        #endif
        var oldProtocol: URLProtocol?
        switch _protocolStorage {
        // ending时不打断，ending结束的resume需要判断state来决定是否resume
        case .ending, .invalidated: return
        case .existing(let urlProtocol):
            oldProtocol = urlProtocol
            fallthrough
        default:
            _protocolStorage = .toBeCreated
        }
        if let oldProtocol { stopProtocol(oldProtocol) }
    }
    /// 配合在workQueue上同步调用的_invalidateProtocol, 保证只invalidated一次
    var valid: Bool {
        switch _protocolStorage {
        case .invalidated: return false
        default: return true
        }
    }
    func _invalidateProtocol() { stopProtocol(.invalidated) }
    func _currentLoadingProtocol() -> URLProtocol? {
        switch _protocolStorage {
        case let .existing(urlProtocol):
            return urlProtocol
        default:
            return nil
        }
    }
}

// swiftlint:disable attributes
@objc public class RustHTTPSessionDataTask: RustHTTPSessionTask {}
@objc public class RustHTTPSessionUploadTask: RustHTTPSessionDataTask {}
@objc public class RustHTTPSessionDownloadTask: RustHTTPSessionTask {}
// swiftlint:enable attributes

// MARK: Public API
@objc
public extension RustHTTPSessionTask {
    @objc(RustHTTPSessionTaskState)
    enum State: Int {
        case running
        /// this is the initial state, no network activity
        case suspended
        case canceling // cancel中，发出cancel错误请求
        case completed
    }
    // Real Call Should Async On WorkQueue, Avoid Deadlock
    func resume() {
        lock.lock(); defer { lock.unlock() }
        let oldState = _state
        guard oldState != .canceling && oldState != .completed else { return }
        guard self.suspendCount > 0 else { return } // 防多次重复resume的调用

        self.suspendCount -= 1
        if self.suspendCount == 0 {
            #if DEBUG || ALPHA
            precondition(oldState == .suspended)
            #endif
            _state = .running
            self.workQueue.async { self.startProtcol() }
        } else {
            #if DEBUG || ALPHA
            precondition(oldState == .running)
            #endif
        }
    }
    func suspend() {
        lock.lock(); defer { lock.unlock() }
        let oldState = _state
        guard oldState != .canceling && oldState != .completed else { return }
        self.suspendCount += 1
        if self.suspendCount == 1 {
            #if DEBUG || ALPHA
            precondition(oldState == .running)
            #endif
            _state = .suspended
            self.workQueue.async { self._suspend() }
        } else {
            #if DEBUG || ALPHA
            precondition(oldState == .suspended)
            #endif
        }
    }
    func cancel() {
        // NOTE: 状态修改同步进行，锁的时间短。queue里只用于异步使用
        let canceled = lock.withLocking {
            guard self._state == .running || self._state == .suspended else { return true }
            self._state = .canceling
            return false
        }
        guard !canceled else { return }
        self.workQueue.async {
            let error = RustHTTPError(code: NSURLErrorCancelled, message: "\(URLError.Code.cancelled)", request: self.originalRequest)
            Client(task: self).didFailWithError(error)
        }
    }
    /// you can configure the task after created in delegate,
    /// read original request, modify and replace the first current request.
    /// eg: add common header, set timeout, etc.
    /// this behaviour similar to Alamofire's RequestAdapter
    ///
    /// NOTE: this method can only called before resume!
    /// NOTE: request body can't be modified and is ignored
    func updateStartRequest(_ request: URLRequest) {
        switch state {
        case .suspended:
            self.currentRequest = request
        #if DEBUG || ALPHA
        case .running:
            fatalError("you should update current request before resume!!!")
        #endif
        default: // 可能resume前, 提前cancel结束, 这种情况进行忽略
            break
        }
    }
}

// MARK: Private Implement
extension RustHTTPSession {
    class TaskRegistry {
        /// Completion handler for `URLSessionDataTask`, and `URLSessionUploadTask`.
        typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
        /// Completion handler for `URLSessionDownloadTask`.
        typealias DownloadTaskCompletion = (URL?, URLResponse?, Error?) -> Void
        /// What to do upon events (such as completion) of a specific task.
        enum Behaviour {
            case noDelegate
            /// Call the `URLSession`s delegate
            case callDelegate
            /// Default action for all events, except for completion.
            case dataCompletionHandler(DataTaskCompletion)
            /// Default action for all events, except for completion.
            case downloadCompletionHandler(DownloadTaskCompletion)
        }
        // NOTE: state must access on session workQueue
        var tasks: [RustHTTPSessionTask.ID: RustHTTPSessionTask] = [:]
        var behaviours: [RustHTTPSessionTask.ID: Behaviour] = [:]
        var tasksFinishedCallback: (() -> Void)?

        var isEmpty: Bool { tasks.isEmpty }
        func add(_ task: RustHTTPSessionTask, behaviour: Behaviour) {
            let identifier = task.taskIdentifier
            guard tasks.index(forKey: identifier) == nil else {
                #if DEBUG || ALPHA
                if tasks[identifier] === task {
                    fatalError("Trying to re-insert a task that's already in the registry.")
                } else {
                    fatalError("Trying to insert a task, but a different task with the same identifier is already in the registry.")
                }
                #else
                return
                #endif
            }
            tasks[identifier] = task
            behaviours[identifier] = behaviour
        }
        /// Remove a task
        ///
        /// - Note: This must **only** be accessed on the owning session's work queue.
        func remove(_ task: RustHTTPSessionTask) {
            let identifier = task.taskIdentifier
            guard let tasksIdx = tasks.index(forKey: identifier) else {
                #if DEBUG || ALPHA
                fatalError("Trying to remove task, but it's not in the registry.")
                #else
                return
                #endif
            }
            tasks.remove(at: tasksIdx)
            guard let behaviourIdx = behaviours.index(forKey: identifier) else {
                #if DEBUG || ALPHA
                fatalError("Trying to remove task's behaviour, but it's not in the registry.")
                #else
                return
                #endif
            }
            behaviours.remove(at: behaviourIdx)

            guard let allTasksFinished = tasksFinishedCallback else { return }
            if self.isEmpty {
                self.tasksFinishedCallback = nil
                allTasksFinished()
            }
        }
        func behaviour(task: RustHTTPSessionTask) -> Behaviour {
            let identifier = task.taskIdentifier
            guard let behaviour = behaviours[identifier] else {
                #if DEBUG || ALPHA
                fatalError("Trying to get behaviour of task, but it's not in the registry.")
                #else
                return .noDelegate
                #endif
            }
            return behaviour
        }
    }
}

internal extension RustHTTPSessionTask {
    enum _Body {
        case none
        case data(Data)
        /// Body data is read from the given file URL
        case file(URL)
        case stream(InputStream)
        // case nil: get from delegate
    }
}
internal extension RustHTTPSessionTask._Body {
    enum _Error: Error {
        case fileForBodyDataNotFound
    }
    /// - Returns: The body length, or `nil` for no body (e.g. `GET` request).
    func getBodyLength() throws -> UInt64? {
        switch self {
        case .none:
            return 0
        case .data(let d):
            return UInt64(d.count)
        /// Body data is read from the given file URL
        case .file(let fileURL):
            guard let s = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber else {
                throw _Error.fileForBodyDataNotFound
            }
            return s.uint64Value
        case .stream:
            return nil
        }
    }
}

#if DEBUG || ALPHA
@propertyWrapper
struct WorkQueueGuard<Value> {
    var value: Value
    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    public var projectedValue: Self { self }
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError("should call static subscript api") }
        set { fatalError("should call static subscript api") }
    }
    public static subscript(
        _enclosingInstance observed: RustHTTPSessionTask,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<RustHTTPSessionTask, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<RustHTTPSessionTask, Self>
        ) -> Value {
        get {
            dispatchPrecondition(condition: .onQueue(observed.workQueue))
            return observed[keyPath: storageKeyPath].value
        }
        set {
            dispatchPrecondition(condition: .onQueue(observed.workQueue))
            observed[keyPath: storageKeyPath].value = newValue
        }
    }
}
@propertyWrapper
struct LockGuard<Value> {
    var value: Value
    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError("should call static subscript api") }
        set { fatalError("should call static subscript api") }
    }
    public static subscript(
        _enclosingInstance observed: RustHTTPSessionTask,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<RustHTTPSessionTask, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<RustHTTPSessionTask, Self>
        ) -> Value {
        get {
            observed.lock.assertOwner()
            return observed[keyPath: storageKeyPath].value
        }
        set {
            observed.lock.assertOwner()
            observed[keyPath: storageKeyPath].value = newValue
        }
    }
}
#endif
