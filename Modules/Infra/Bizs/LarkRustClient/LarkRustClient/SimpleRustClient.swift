//
//  SimpleRustClient.swift
//  Lark
//
//  Created by linlin on 2017/7/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import SwiftProtobuf
import RustPB
import RxSwift
import LKCommonsLogging
import EEAtomic
import ServerPB

// swiftlint:disable line_length file_length

/// 基础的rust接口调用逻辑封装，包括回调queue，日志打印等.
/// 纯逻辑，无状态。不会调用rust的初始化等
/// 目前推送和Command Map的使用依赖于RustClient的初始化
public class SimpleRustClient: RustService, GlobalRustService {
    public static var hook: RustClientHook? // 外部注入的扩展位
    public static var logger = Logger.log(RustClient.self, category: "RustSDK.Client")
    public static var showLogDetails = false
    /// 全局共享的简单rust接口封装对象.
    /// 提供给用户无关的全局接口之类的简单场景使用
    /// 用户相关的应该使用容器里的RustClient
    /// TODO: 该类暴露能力过大，未来会逐渐收敛至内部使用
    public static let global = SimpleRustClient(identifier: "global")

    public let userID: String?
    var clientUserID: UInt64 { return userID.flatMap { UInt64($0) } ?? 0 }

    private var _rustContainerID: (UInt64, UInt64)? // (destinationID, userLifeContainerID)
    public var rustContainerID: (dest: UInt64, user: UInt64)? {
        get { lock.withLocking { _rustContainerID } }
        set {
            lock.withLocking { _rustContainerID = newValue }
        }
    }
    public var destinationID: UInt64? { rustContainerID?.dest }
    public var userLifeContainerID: UInt64? { rustContainerID?.user }

    public let identifier: String
    /// async callback queue
    let callbackQueue = DispatchQueue(label: "Rust Client Callback", attributes: [.concurrent], target: DispatchQueue.global())
    /// 可被barrior的异步并发queue, 所有service api应该运行在这个queue上，保证dispose能正常和其它请求互斥
    let sendQueue = DispatchQueue(label: "Rust Client Send", attributes: [.concurrent], target: DispatchQueue.global())
    let pushQueue: DispatchQueue
    var barrierChecker: ((RequestPacket) -> Bool)?
    private let defaultCommandMap: [String: Command]

    /// 初始化一个简单的RustClient，纯功能性，不含业务的调用依赖.
    ///
    /// PS: 推送的接口需要RustClient初始化后才生效
    /// NOTE: 业务方不应该再创建实例。实例只能被生命周期管控容器创建
    ///
    /// - Parameters:
    ///   - identifier: 日志标识
    ///   - userID: 用户标识
    ///   - defaultCommandMap: Message到Command的映射. 之前是RustClient初始化从Rust获取的，初始化之前拿不到，所以需要手动设置
    ///   - callbackQueue: 回调所在队列
    public init(identifier: String = "Simple", userID: String? = nil, defaultCommandMap: [(SwiftProtobuf.Message.Type, Command)] = []) {
        self.identifier = identifier
        self.userID = userID
        self.defaultCommandMap = Dictionary(uniqueKeysWithValues: defaultCommandMap.map { (k, v) in (k.protoMessageName, v) })

        // registerFactory会懒加载handler，所以这里需要串行..
        self.pushQueue = DispatchQueue(label: "Rust Client Push", target: callbackQueue)
    }

    /// 这个锁用于任何短时间的内存保护, 需要注意重入
    /// 目前保护了barrierChecker, dispose, cancel task
    var lock = UnfairLockCell()
    private var _disposed = AtomicBoolCell()
    #if DEBUG
    @AtomicObject private var _disposedTime: CFTimeInterval = CFTimeInterval.greatestFiniteMagnitude
    #endif
    var disposed: Bool { _disposed.value }
    /// return true when first dispose
    @discardableResult
    private func markDispose() -> Bool {
        return _disposed.exchange(true) == false
    }

    // https://bytedance.feishu.cn/docs/doccnYAhcyiD02FCaXn4VmT4N3c#eMOf6L
    // 因为现在rustclient可能被各种情况意外持有，所以需要显式的调用dispose标记生命周期的结束，防止用户切换导致的一些环境变化错误
    public func dispose() {
        guard markDispose() else { return }
        #if DEBUG
        _disposedTime = CACurrentMediaTime()
        #endif
        SimpleRustClient.logger.info("\(self.identifier) will dispose")

        do {
            lock.lock(); defer { lock.unlock() }
            _runDisposeTasks()
            _runPushCancelTasks()
            onDisposeCancelPush()
        }
        clearMSGOnDispose()

        SimpleRustClient.logger.info("\(self.identifier) did disposed")
        DispatchQueue.global().asyncAfter(deadline: .now() + M.disposeRecycleTime) { [weak self] in
            if let self {
                M.logger.error("\(self.identifier) not deinit after \(M.disposeRecycleTime)s. maybe memory leak or use expired client")
                // TODO: 未来修复相关问题后升级成运行时崩溃
            }
        }
    }

    deinit {
        dispose()
        lock.deallocate()
        _disposed.deallocate()
        callbackQueueLock.deallocate()
        sendQueueLock.deallocate()
        pushMsgQueueLock.deallocate()
        #if DEBUG || ALPHA
        M.logger.debug("\(self.identifier) deinit")
        #endif
    }

    private func _disposeGuard<R>(context: RequestContext) -> ResponsePacketWithMetrics<R>? {
        if self.disposed {
            #if DEBUG
            if CACurrentMediaTime() - _disposedTime > M.disposeRecycleTime {
                assertionFailure("call disposed RustClient. you should use the newest client")
            }
            #endif
            return (ResponsePacket(contextID: context.contextID, result: .failure(RCError.cancel)),
                    Metrics(title: "\(self.identifier) --> \(context.label) Cancel By Disposed",
                            contextID: context.contextID))
        }
        return nil
    }
    func disposeGuard<R>(context: RequestContext, on callbackQueue: DispatchQueue? = nil, callback: @escaping (ResponsePacket<R>) -> Void) -> Bool {
        if let (error, metrics): ResponsePacketWithMetrics<R> = _disposeGuard(context: context) {
            if context.direct {
                metrics.doCallbackAndFinish {
                    callback(error)
                }
            } else {
                self.callback(on: callbackQueue ?? self.callbackQueue, metrics: metrics) {
                    callback(error)
                }
            }
            return true
        }
        return false
    }

    // ensure unique owner of tasks, avoid COW
    final class TaskQueue {
        typealias Action = () -> Void
        var tasks: [Action] = []
    }
    /// 根据标记，复用相同的Queue, 保证串行
    var serialQueuePool = [UInt64: TaskQueue]()
    var serialQueuePoolLock = UnfairLock()

    /// action should call finishAsyncAction
    func push(token: SerialToken, action: @escaping TaskQueue.Action) {
        if token == 0 {
            action()
            return
        }

        var doAction = false
        serialQueuePoolLock.withLocking {
            if let queue = serialQueuePool[token] {
                queue.tasks.append(action)
            } else {
                let v = TaskQueue()
                serialQueuePool[token] = v
                doAction = true
            }
        }
        if doAction { action() }
    }
    func finishAsyncAction(token: SerialToken, maxDelay: TimeInterval) {
        if token == 0 { return }

        func finish() {
            var action: TaskQueue.Action?
            serialQueuePoolLock.withLocking {
                guard let queue = serialQueuePool[token] else {
                    assertionFailure("the token\(token) should in serialQueuePool")
                    return
                }
                if queue.tasks.isEmpty {
                    serialQueuePool.removeValue(forKey: token)
                } else {
                    action = queue.tasks.remove(at: 0)
                }
            }
            if let action = action { action() }
        }
        if maxDelay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + maxDelay, execute: finish)
        } else {
            finish()
        }
    }

    func sync<T>(label: String, contextID: String, barrier: Bool = false, execute: () throws -> T) rethrows -> T {
        let timer = Metrics.BlockedTimer(timeout: M.queueBlockedWarnTime) { [identifier = self.identifier] in
            SimpleRustClient.logger.warn(
                "\(identifier) --> \(label) Waiting...",
                additionalData: ["contextID": contextID])
        }
        sendQueueLock.lock()
        if let sendTasks {
            // 同步等待锁释放
            let semphore = DispatchSemaphore(value: 0)
            sendTasks.tasks.append { semphore.signal() }
            sendQueueLock.unlock()
            semphore.wait()
        } else {
            sendQueueLock.unlock()
        }
        return try self.sendQueue.sync(flags: barrier ? .barrier : []) {
            timer.finish()
            return try execute()
        }
    }

    /// onQueue必须是sendQueue的子Queue，以保证正确的被barrier block
    func async(token: SerialToken, maxDelay: TimeInterval = 0, label: String, contextID: String, qos: DispatchQoS = .unspecified, barrier: Bool = false, execute: @escaping () -> Void) {
        let timer = Metrics.BlockedTimer(timeout: M.queueBlockedWarnTime) { [identifier = self.identifier] in
            SimpleRustClient.logger.warn(
                "\(identifier) --> \(label) Waiting...",
                additionalData: ["contextID": contextID])
        }
        func action() {
            do {
                sendQueueLock.lock(); defer { sendQueueLock.unlock() }
                if let sendTasks {
                    sendTasks.tasks.append(doaction)
                    return
                }
            }
            doaction()
            func doaction() {
                self.sendQueue.async(qos: qos, flags: barrier ? .barrier : []) {
                    timer.finish()
                    defer {
                        self.finishAsyncAction(token: token, maxDelay: maxDelay)
                    }
                    execute()
                }
            }
        }
        self.push(token: token, action: action)
    }
    private var sendQueueLock = UnfairLockCell()
    // access in sendQueueLock only
    private var sendTasks: HoldTask? {
        didSet { oldValue?.flush() }
    }

    private var callbackQueueLock = UnfairLockCell()
    // access in callbackQueueLock only
    private var callbackTasks: HoldTask? {
        didSet { oldValue?.flush() }
    }
    // 所有callbackQueue都应该使用这个方法，建立统一的引用, 并统一记录等待时长
    func callback(on queue: DispatchQueue, qos: DispatchQoS = .unspecified, execute: @escaping () -> Void) {
        do {
            callbackQueueLock.lock(); defer { callbackQueueLock.unlock() }
            if let callbackTasks {
                callbackTasks.tasks.append {
                    queue.async(qos: qos, execute: execute)
                }
                return
            }
        }
        queue.async(qos: qos, execute: execute)
    }
    func callback(on queue: DispatchQueue, qos: DispatchQoS = .unspecified, metrics: Metrics, execute: @escaping () -> Void) {
        let doCallback = metrics.wrapCallback {
            metrics.doCallbackAndFinish(action: execute)
        }
        callback(on: queue, qos: qos, execute: doCallback)
    }
    /// optional log only when cost so many time
    func callback(
        on queue: DispatchQueue, qos: DispatchQoS = .unspecified,
        label: String, contextID: String,
        execute: @escaping () -> Void
    ) {
        let metrics = Metrics(title: label, contextID: contextID)
        let doCallback = metrics.wrapCallback {
            metrics.doCallback(action: execute)
            if metrics.hasBlock { metrics.finish() }
        }
        callback(on: queue, qos: qos, execute: doCallback)
    }

    func direct(request: RequestPacket) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return self.barrierChecker?(request) == true
    }

    class RequestContext {
        let label: String
        let contextID: String
        let direct: Bool // 是否直接请求和回调，跳过queue
        let cacheAge: Int
        let tid: Int64
        let spanID: UInt64?
        let collectTrace: Bool?
        let mailAccountId: String?
        let enableStartUpControl: Bool?
        let startTime = CACurrentMediaTime()

        init(label: String, parentID: String? = nil, needTid: Bool = true, spanID: UInt64? = nil, collectTrace: Bool? = false, mailAccountId: String? = nil) {
            self.label = label
            self.contextID = RequestContext.genContextID(parentID)
            self.direct = false
            self.cacheAge = 0
            self.tid = needTid ? M.getCurrentThreadInt64() : 0
            self.spanID = spanID
            self.collectTrace = collectTrace
            self.mailAccountId = mailAccountId
            self.enableStartUpControl = false
        }

        init(request: RequestPacket, type: String, direct: Bool, needTid: Bool = true) {
            if direct {
                self.label = "\(request.message.protoMessageName) (\(type) Direct)"
            } else if request.barrier {
                self.label = "\(request.message.protoMessageName) (\(type) Barrier)"
            } else {
                self.label = "\(request.message.protoMessageName) (\(type))"
            }
            self.contextID = RequestContext.genContextID(request.parentID)
            self.direct = direct
            self.cacheAge = request.cacheAge
            self.tid = needTid ? M.getCurrentThreadInt64() : 0
            self.spanID = request.spanID
            self.collectTrace = request.collectTrace
            self.enableStartUpControl = request.enableStartUpControl
            self.mailAccountId = request.mailAccountId
            request.contextIdGenerationCallback(self.contextID)
        }
        init(request: RawRequestPacket, type: String, needTid: Bool = true) {
            let name: String
            if let serCommand = request.serCommand {
                name = "ser cmd \(serCommand)#\(serCommand.rawValue)"
            } else {
                name = "cmd \(request.command)#\(request.command.rawValue)"
            }
            self.label = "\(name) (\(type))"
            self.contextID = RequestContext.genContextID(request.parentID)
            self.direct = false
            self.cacheAge = request.cacheAge
            self.tid = needTid ? M.getCurrentThreadInt64() : 0
            self.spanID = request.spanID
            self.collectTrace = request.collectTrace
            self.enableStartUpControl = request.enableStartUpControl
            self.mailAccountId = request.mailAccountId
            request.contextIdGenerationCallback(self.contextID)
        }

        /// return the duration for this request by now - startTime
        var duration: CFTimeInterval {
            return CACurrentMediaTime() - startTime
        }

        static func genContextID(_ parent: String?) -> String {
            var contextId = ""
            if let parent = parent {
                contextId = "\(parent)-\(M.uuid())"
            } else {
                contextId = M.uuid()
            }
            return TraceIdUtil.wrapContextId(contextId)
        }
    }
    // MARK: - Hold Current Async Request for cancel when deinit
    private var disposeTasks: Set<CancelTask> = []
    func add(disposeTask: CancelTask) throws {
        lock.lock(); defer { lock.unlock() }
        if disposed { throw RCError.cancel }
        let old = disposeTasks.update(with: disposeTask)
        assert(old == nil, "each disposeTask should be unique!!")
    }
    @discardableResult
    func remove(disposeTask: CancelTask) -> CancelTask? {
        lock.lock(); defer { lock.unlock() }
        return disposeTasks.remove(disposeTask)
    }
    private func _runDisposeTasks() {
        #if DEBUG
        lock.assertOwner()
        #endif
        let tasks = disposeTasks
        disposeTasks = []
        for task in tasks {
            task.handler(self)
        }
    }
    final class CancelTask: Hashable {
        static func == (lhs: SimpleRustClient.CancelTask, rhs: SimpleRustClient.CancelTask) -> Bool {
            return lhs === rhs
        }

        func hash(into hasher: inout Hasher) {
            ObjectIdentifier(self).hash(into: &hasher)
        }
        var handler: (SimpleRustClient) -> Void
        init(handler: @escaping (SimpleRustClient) -> Void) {
            self.handler = handler
        }
    }
    // MARK: pushState
    var rustPushRegistry: [Command: RustPushRegistry] = [:]
    var serverPushRegistry: [ServerCommand: ServerPushRegistry] = [:]
    /// 这里缓存push主要作用是移交给下一个实例，保证关键push不丢
    /// 需要保证接收顺序和处理顺序
    /// PushCallBack还有白名单可以提前运行，无法保证出入顺序.. 但大部分应该是先入先出
    /// NOTE: 考虑到不能保证绝对的执行顺序，且要保证不丢，所以这里专门记录任务，方便移除。
    /// 队列顺序靠pushQueeue分发执行，绝对顺序由PushMsg的创建顺序决定
    let pushMsgQueueLock = UnfairLockCell()
    var pushMsgQueue: Set<PushMsg> = []

    // FIXME: 旧代码等FG全量后应该可以清理掉
    private var pushCancelTasks: Set<CancelTask> = []
    func add(pushCancelTask: CancelTask) throws {
        lock.lock(); defer { lock.unlock() }
        if disposed { throw RCError.cancel }
        let old = pushCancelTasks.update(with: pushCancelTask)
        assert(old == nil, "each pushCancelTask should be unique!!")
    }
    @discardableResult
    func remove(pushCancelTask: CancelTask) -> CancelTask? {
        lock.lock(); defer { lock.unlock() }
        return pushCancelTasks.remove(pushCancelTask)
    }
    /// caller should lock it
    private func _runPushCancelTasks() {
        #if DEBUG
        lock.assertOwner()
        #endif
        let tasks = pushCancelTasks
        pushCancelTasks = []
        for task in tasks {
            task.handler(self)
        }
    }
    var holdPush: HoldPush? // access on push queue

    // MARK: - Command Cache
    // packet wrapper with additionalData
    typealias CommonPacket = (packet: Basic_V1_RequestPacket, cmd: CMD)
    /// - throws: RCError
    /// - throws: BinaryEncodingError
    func makeRequestPacket(command: Command, serCommand: ServerPB_Improto_Command?, request: SwiftProtobuf.Message, context: RequestContext) throws -> CommonPacket {
        self.log(request: request, context: context)
        var packet: Basic_V1_RequestPacket
        let cmd: CMD
        if let serCommand = serCommand {
            packet = try makeServerRequestPacket(serCommand: serCommand, payload: serialize(request: request, context: context), context: context)
            cmd = .server(serCommand)
        } else {
            let rustcmd = try self.extractCommand(defaultCommand: command, request: request)    // throws RCError
            packet = try makeRustRequestPacket(command: rustcmd, payload: serialize(request: request, context: context)) // throws BinaryEncodingError
            cmd = .rust(rustcmd)
        }
        configure(request: &packet, context: context)
        return (packet, cmd)
    }
    // override by RustClient
    func serialize(request: SwiftProtobuf.Message, context: RequestContext) throws -> Data {
        try request.serializedData()
    }

    func makeRequestPacket(command: Command, serCommand: ServerPB_Improto_Command?, payload: Data, context: RequestContext) throws -> CommonPacket {
        self.log(context: context)
        var packet: Basic_V1_RequestPacket
        let cmd: CMD
        if let serCommand = serCommand {
            packet = try makeServerRequestPacket(serCommand: serCommand, payload: payload, context: context)
            cmd = .server(serCommand)
        } else {
            if command == .unknownCommand {
                SimpleRustClient.logger.error(
                    "Extract command failed with raw request \(context.label).")
                throw RCError.unknownRustSDKCommand(request: context.label)
            }
            packet = makeRustRequestPacket(command: command, payload: payload) // throws BinaryEncodingError
            cmd = .rust(command)
        }
        configure(request: &packet, context: context)
        return (packet, cmd)
    }
    private func makeRustRequestPacket(command: Command, payload: Data) -> Basic_V1_RequestPacket {
        var packet = Basic_V1_RequestPacket()
        packet.cmd = command
        packet.payload = payload
        return packet
    }
    private func makeServerRequestPacket(serCommand: ServerPB_Improto_Command, payload: Data, context: RequestContext) throws -> Basic_V1_RequestPacket {
        // 透传接口,需要把业务request再拼接成一个单独的ServerPB_Improto_Packet,然后再通过rust发送出去
        let serverPacket: ServerPB_Improto_Packet = makeServerRequestPacket(serCommand: serCommand, payload: payload, context: context)
        let requestData = try serverPacket.serializedData()
        var passThrough = Basic_V1_RequestPacket.PassThrough()
        passThrough.serCommand = String(serCommand.rawValue)
        var packet = Basic_V1_RequestPacket()
        packet.cmd = Command.passThroughApi
        packet.passThrough = passThrough
        packet.payload = requestData
        return packet
    }
    private func makeServerRequestPacket(serCommand: ServerPB_Improto_Command, payload: Data, context: RequestContext) -> ServerPB_Improto_Packet {
        var serverPacket = ServerPB_Improto_Packet()
        serverPacket.payload = payload
        serverPacket.cid = context.contextID
        serverPacket.cmd = serCommand
        serverPacket.payloadType = ServerPB_Improto_PayloadType.json
        return serverPacket
    }
    private func configure(request packet: inout Basic_V1_RequestPacket, context: RequestContext) {
        packet.threadID = context.tid
        if let userID = self.userID {
            packet.userID = userID
        }
        if let destinationID {
            packet.userContainerID = destinationID
        }
        if let spanID = context.spanID {
            packet.spanID = spanID
        }
        if let mailAccountId = context.mailAccountId, !mailAccountId.isEmpty {
            packet.mailAccountID = mailAccountId
        }
        if let collectTrace = context.collectTrace {
            packet.collectTrace = collectTrace
        }
        if let enableStartUpControl = context.enableStartUpControl {
            packet.enableStartUpControl = enableStartUpControl
        }

        packet.contextID = context.contextID
        if context.cacheAge > 0 {
            packet.maxAge = Int64(context.cacheAge)
            packet.useCacheControl = true
        }
    }
    func extractCommand(defaultCommand: Command, request: SwiftProtobuf.Message) throws -> Command {
        guard defaultCommand == .unknownCommand else { return defaultCommand }
        var cmd = RustManager.shared.extractCommand(fromRequest: request)
        if cmd == .unknownCommand {
            cmd = defaultCommandMap[request.protoMessageName] ?? .unknownCommand
        }
        if cmd == .unknownCommand {
            SimpleRustClient.logger.error(
                "Extract command failed with request \(request.protoMessageName).")
            throw RCError.unknownRustSDKCommand(request: request.protoMessageName)
        }
        return cmd
    }

    // MARK: - Overridable
    func startEventStream<R: Message>(
        _ request: RequestPacket, finishOnError: Bool, event: @escaping (ResponsePacket<R>?, Bool) -> Void
    ) -> Disposable {
        var type = "Stream"
        if request.serialToken != 0 {
            type += "(\(request.serialToken))"
            if request.serialDelay > 0 { type += "[\(M.format(time: request.serialDelay))]" }
        }
        let context = RequestContext(request: request, type: type, direct: false, needTid: false)
        let disposed = disposeGuard(context: context) { event($0, true) }
        if disposed { return Disposables.create() }

        let disposable = SingleAssignmentDisposable()
        self.async(token: request.serialToken, maxDelay: request.serialDelay, label: context.label, contextID: context.contextID, barrier: request.barrier) {
            let disposed = self.disposeGuard(context: context, callback: { event($0, true) })
            if disposed { return }
            disposable.setDisposable(
                self.startEventStreamImpl(request: request.message,
                                          config: request.bizConfig,
                                          context: context,
                                          finishOnError: finishOnError,
                                          callback: event))
        }
        return disposable
    }

    // MARK: - RustService
    public func wait(callback: @escaping () -> Void) {
        let contextID = RequestContext.genContextID(nil)
        self.async(token: 0, label: "waiting", contextID: contextID) {
            self.callback(on: self.callbackQueue, label: "waiting", contextID: contextID, execute: callback)
        }
    }

    public func barrier(allowRequest: @escaping (RequestPacket) -> Bool, enter: @escaping (_ leave: @escaping () -> Void) -> Void) {
        // NOTE: callbackQueue执行的代码是不可控的，先锁callback，再锁sendQueue, 避免callback中send死锁。
        // 但这样不能及时的锁sendQueue...
        // CHANGE: 现在callbackQueue因为不可控，可能卡死，改成只block新调用，不等待已经在执行的旧调用.
        //   这样SendQueue也能即时的进入barrier.
        //   SendQueue主要不可控的调用在rust，rust应该有异步分发，同步的耗时都比较快，卡死可能性很低.
        //   不过多用户后都上锁的话会占用大量线程，所以还是改成异步的.., 上锁前已经发起的没结束，影响应该不大
        let startTime = CACurrentMediaTime()
        let contextID = M.uuid()
        SimpleRustClient.logger.info("\(self.identifier) will barrier", additionalData: ["contextID": contextID])
        self.callbackQueue.async { [self] in
            callbackQueueLock.withLocking { self.callbackTasks = HoldTask() }
            sendQueueLock.withLocking { self.sendTasks = HoldTask() }

            let beforeExecute = CACurrentMediaTime()
            let waiting = beforeExecute - startTime
            if waiting > M.sendQueueWaitWarnDuration {
                SimpleRustClient.logger.warn("\(self.identifier) --> Barrier Waiting...", additionalData: [
                    "Execution-Time": M.format(time: waiting),
                    "contextID": contextID
                ])
            }
            self.lock.withLocking {
                RustClient.OnInvalidUserID.hasBarrier = true
                self.barrierChecker = allowRequest
            }
            var finish = false
            enter { [self] in
                do {
                    lock.lock(); defer { lock.unlock() }
                    if finish { return }
                    finish = true
                    self.barrierChecker = nil
                    RustClient.OnInvalidUserID.hasBarrier = false
                }
                callbackQueueLock.withLocking { self.callbackTasks = nil }
                SimpleRustClient.logger.info("\(self.identifier) end barrier", additionalData: [
                    "contextID": contextID,
                    "Execution-Time": M.format(time: CACurrentMediaTime() - startTime)])
                sendQueueLock.withLocking { self.sendTasks = nil }
            }
        }
    }

    /// 内部控制流程使用，外部不要调用barrier相关的方法
    /// 该外部action会占用sendQueue
    public func barrier(id: String, action: @escaping () -> Void) {
        M.logger.info("\(self.identifier) will barrier for action \(id)")
        self.sendQueue.async(flags: .barrier) {
            action()
            M.logger.info("\(self.identifier) end barrier for action \(id)")
        }
    }

    public func sync(_ request: RequestPacket) -> ResponsePacket<Void> {
        return sync(request) { [self](context) -> ResponsePacketWithMetrics<Void> in
            return sendSyncRequestImpl(
                command: request.command, serCommand: request.serCommand, request.message,
                context: context)
        }
    }

    public func sync<R>(_ request: RequestPacket) -> ResponsePacket<R> where R: Message {
        return sync(request) { [self](context) -> ResponsePacketWithMetrics<R> in
            return sendSyncRequestImpl(
                command: request.command, serCommand: request.serCommand, request.message,
                context: context)
        }
    }

    func sync<R>(_ request: RequestPacket, doSend: @escaping (RequestContext) -> ResponsePacketWithMetrics<R>) -> ResponsePacket<R> {
        let context = RequestContext(request: request, type: "Synchronous", direct: direct(request: request))

        func disposeGuard(context: RequestContext) -> ResponsePacket<R>? {
            if let (error, metrics): ResponsePacketWithMetrics<R> = _disposeGuard(context: context) {
                metrics.finish()
                return error
            }
            return nil
        }
        if let error: ResponsePacket<R> = disposeGuard(context: context) { return error }

        func wrapDoSend() -> ResponsePacket<R> {
            let result = doSend(context)
            result.1.finish()
            return result.0
        }
        func send() -> ResponsePacket<R> {
            if context.direct { return wrapDoSend() }
            return self.sync(label: context.label, contextID: context.contextID, barrier: request.barrier) {
                if let error: ResponsePacket<R> = disposeGuard(context: context) { return error }
                return wrapDoSend()
            }
        }
        if Self.hook?.mainThreadTimedout == true, Thread.isMainThread {
            if !Self.blockMainThread {
                var result: ResponsePacket<R>?
                let work = DispatchWorkItem { result = send() }
                DispatchQueue.global(qos: .userInteractive).async(execute: work)
                // block until success or timedout
                if work.wait(timeout: .now() + M.mainSyncErrorTime) == .success, let result = result {
                    return result
                }
                Self.blockMainThread = true
                M.logger.info("blocking MainThread PB")
                DispatchQueue.main.async(qos: .userInteractive) {
                    Self.blockMainThread = false
                    M.logger.info("release blocking MainThread PB")
                }
            }
            #if DEBUG || ALPHA
            fatalError("\(self.identifier) --> \(context.label) MainThread Timed out. contextID: \(context.contextID)")
            #else
            M.logger.error("\(self.identifier) --> \(context.label) MainThread Timed out", additionalData: ["contextID": context.contextID])
            return ResponsePacket(contextID: context.contextID, result: .failure(RCError.timedOut))
            #endif
        } else {
            return send()
        }
    }
    static var blockMainThread = false

    public func async(_ request: RequestPacket, callback: @escaping (ResponsePacket<Void>) -> Void) {
        async(request) { (context, action: AsyncAction<Void>) in
            switch action {
            case .callback(let res):
                callback(res)
            case .sync:
                let res: ResponsePacketWithMetrics<Void> = self.sendSyncRequestImpl(
                    command: request.command, serCommand: request.serCommand,
                    request.message, context: context)
                self.callback(on: self.callbackQueue, metrics: res.1) {
                    callback(res.0)
                }
            case .async:
                self.sendAsyncRequestImpl(
                    command: request.command,
                    request.message,
                    context: context,
                    serCommand: request.serCommand,
                    callback: callback
                )
            }
        }
    }

    public func async<R>(_ request: RequestPacket, callback: @escaping (ResponsePacket<R>) -> Void) where R: Message {
        async(request) { (context, action: AsyncAction<R>) in
            switch action {
            case .callback(let res):
                callback(res)
            case .sync:
                let res: ResponsePacketWithMetrics<R> = self.sendSyncRequestImpl(
                    command: request.command, serCommand: request.serCommand,
                    request.message, context: context)
                self.callback(on: self.callbackQueue, metrics: res.1) {
                    callback(res.0)
                }
            case .async:
                self.sendAsyncRequestImpl(
                    command: request.command,
                    request.message,
                    context: context,
                    serCommand: request.serCommand,
                    callback: callback
                )
            }
        }
    }

    public func async(_ request: RawRequestPacket, callback: @escaping (ResponsePacket<Data>) -> Void) {
        var type = "Asynchronous"
        if request.serialToken != 0 { type = type + "(\(request.serialToken))" }

        let context = RequestContext(request: request, type: type, needTid: false)
        if disposeGuard(context: context, callback: callback) { return }
        func send () {
            sendAsyncRequestImpl(
                command: request.command,
                serCommand: request.serCommand,
                request.message,
                context: context,
                callback: callback
            )
        }
        if context.direct { send() }

        self.async(token: request.serialToken, label: context.label, contextID: context.contextID, barrier: false) {
            if self.disposeGuard(context: context, callback: callback) { return }
            send()
        }
    }

    enum AsyncAction<R> {
    case async, sync
    case callback(ResponsePacket<R>)
    }
    func async<R>(_ request: RequestPacket, handler: @escaping (RequestContext, AsyncAction<R>) -> Void) {
        var type = "Asynchronous"
        if request.serialToken != 0 {
            type += "(\(request.serialToken))"
            if request.serialDelay > 0 { type += "[\(M.format(time: request.serialDelay))]" }
        }

        let context = RequestContext(request: request, type: type, direct: direct(request: request), needTid: false)
        if disposeGuard(context: context, callback: { handler(context, .callback($0)) }) { return }
        if context.direct { return handler(context, .async) }

        self.async(token: request.serialToken, maxDelay: request.serialDelay, label: context.label, contextID: context.contextID, barrier: request.barrier) {
            if self.disposeGuard(context: context, callback: { handler(context, .callback($0)) }) { return }
            // barrier请求卡住并等待请求结束
            if request.barrier {
                handler(context, .sync)
            } else {
                handler(context, .async)
            }
        }
    }

    public func eventStream<R>(_ request: RequestPacket, event handler: @escaping (ResponsePacket<R>?, Bool) -> Void) -> Disposable where R: Message {
        return startEventStream(request, finishOnError: false, event: handler)
    }

    /// need to pass internal finishOnError, to finish immediately. so override here, instead of as service default implement
    public func eventStream<R>(request: SwiftProtobuf.Message,
                               config: Basic_V1_RequestPacket.BizConfig?) -> Observable<R> where R: SwiftProtobuf.Message {
        return Observable.create { (observer) -> Disposable in
            var req = RequestPacket(message: request)
            req.bizConfig = config
            return self.startEventStream(req, finishOnError: true) { (response: ResponsePacket<R>?, finish) in
                switch response?.result {
                case .some(.failure(let error)):
                    observer.on(.error(error))
                case .some(.success(let response)):
                    observer.on(.next(response))
                    fallthrough
                default:
                    if finish {
                        observer.on(.completed)
                    }
                }
            }
        }
    }

    public func eventStream<R>(request: SwiftProtobuf.Message,
                               config: Basic_V1_RequestPacket.BizConfig?,
                               spanID: UInt64?) -> Observable<R> where R: SwiftProtobuf.Message {
        return Observable.create { (observer) -> Disposable in
            var req = RequestPacket(message: request, spanID: spanID)
            req.bizConfig = config
            return self.startEventStream(req, finishOnError: true) { (response: ResponsePacket<R>?, finish) in
                switch response?.result {
                case .some(.failure(let error)):
                    observer.on(.error(error))
                case .some(.success(let response)):
                    observer.on(.next(response))
                    fallthrough
                default:
                    if finish {
                        observer.on(.completed)
                    }
                }
            }
        }
    }
}

// swiftlint:disable missing_docs
extension RustClient {
    public struct OnInvalidUserID {
        public var scenario: String
        public var command: Int?
        public var serverCommand: Int?
        public var clientUserID: UInt64
        public var sdkUserID: UInt64
        public var contextID: String
        public var hasError: Bool = false
        public var intercepted: Bool
        public static var hasBarrier = false
    }
    public struct PushBarrierStat {
        /// 拦截时长
        public var barrier: TimeInterval
        /// 总时长，包括拦截时长+拦截消息延迟分发处理时长
        public var total: TimeInterval
        /// 缓存的payload总消息量，单位Byte
        public var size: Int
        /// 缓存的push消息条数
        public var count: Int
        /// 是否超时过期, 目前barrier最多拦截5分钟
        public var expired: Bool = false
        /// 机器的最大物理内存
        public var maxMemory: UInt64 = physicalMemory
    }
}
let physicalMemory = ProcessInfo.processInfo.physicalMemory

public protocol RustClientHook {
    /// 是否启用主线程同步调用超时
    var mainThreadTimedout: Bool { get }

    // 检查到用户不一致时回调，用于统计上报
    func onInvalidUserID(_ data: RustClient.OnInvalidUserID)
    func onPushBarrierStat(_ data: RustClient.PushBarrierStat)

    /// 多用户的流程FG
    var multiUserFlow: Bool { get }
    func shouldKeepLive(cmd: CMD) -> Bool
}
// swiftlint:enable missing_docs
