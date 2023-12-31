//
//  RustClient+Push.swift
//  LarkRustClient
//
//  Created by SolaWing on 2023/11/17.
//

import Foundation
import RxSwift
import EEAtomic
import ServerPB

extension SimpleRustClient {
    // MARK: - Push Core API
    /// 推送barrier，barrier期间push会被拦截，直到barrier结束后分发..
    /// 主要用于延后推送时间
    /// - Parameters:
    ///     - allowCmds: 调用返回是否支持对应的CMD
    /// - Returns: call to finish barrier(and must call or memory will leak)
    public func pushBarrier(allowCmds: @escaping (CMD) -> Bool)
    -> () -> Void {
        var finish = false
        // 考虑这个barrier可以被重入，重入时，换成新的拦截缓存。不影响之前的释放时机
        // retained by self and closure callback
        let holdPush = HoldPush(allowCmds: allowCmds)
        let finishBlock = { [weak self] (force: Bool) in
            if finish { return }
            finish = true
            guard let self = self else { return }
            #if ALPHA
            dispatchPrecondition(condition: .onQueue(self.pushQueue))
            #endif
            if self.holdPush === holdPush { self.holdPush = nil }

            let elapse = holdPush.elapse
            if force {
                SimpleRustClient.logger.error("\(self.identifier) pushBarrier timed out in \(elapse), force finish")
            } else {
                SimpleRustClient.logger.info("\(self.identifier) pushBarrier finish in \(elapse)")
            }
            // NOTE: 需要保证这里在makeOnline, 接收containerID后..
            // force结束和fastLogin的时候没有对应的时序保证
            // 但是makeOnline发送前可能有push(会被拦截住)，发送后的barrier也只拦截sendQueue，没有拦截callback..
            for action in holdPush.tasks {
                action.1()
            }
            SimpleRustClient.hook?.onPushBarrierStat(.init(
                barrier: elapse, total: holdPush.elapse,
                size: holdPush.cacheSize, count: holdPush.cacheCount, expired: force))
        }
        // 使用串行的pushQueue做同步
        // barrier保证后续的入queue都在这之后
        self.pushQueue.async(flags: .barrier) { [self] in
            SimpleRustClient.logger.info("\(identifier) pushBarrier start")
            self.holdPush = holdPush
            // FIXME: 如果端上还没有执行完登录的话，这个超时回调可能也有问题..
            // 所以端上的登录也不能无限制的延长...
            pushQueue.asyncAfter(deadline: .now() + 5 * 60) { finishBlock(true) }
        }
        // 这个push后调用，应该在上面的执行后...
        // FIXME: barrier和containerSet的调用，可能需要检查callback的统一拦截
        return { [pushQueue] in pushQueue.async(flags: .barrier) { finishBlock(false) } }
    }
    /// containerID设置后，可以提前分发白名单拦截的消息
    public func onRustContainerSet() {
        self.pushQueue.async(flags: .barrier) { [self] in
            guard !self.disposed, let holdPush else { return }
            let msgs = pushMsgQueueLock.withLocking {
                if let rustContainerID {
                    // NOTE: 理论上这里可以把containerID不符合预期的都给清理掉..
                    let invalid = pushMsgQueue.filter { msg in
                        guard msg.revalidateContainerID else { return false }
                        msg.revalidateContainerID = false
                        let invalid = !_validContainerID(msg.id, rustContainerID: rustContainerID)
                        if !invalid { msg.finishMetrics(label: "Invalid ContainerID") }
                        return invalid
                    }
                    if !invalid.isEmpty { pushMsgQueue.subtract(invalid) }
                } else {
                    M.preconditionAlpha(false, "rustContainerID must set when onRustContainerSet called!")
                }
                // handle时会消费掉对应的msg
                return pushMsgQueue.filter { holdPush.allowCmds($0.cmd) }.sorted(by: { $0.id < $1.id })
            }
            for msg in msgs {
                self.handle(msg: msg)
            }
        }
    }

    // MARK: Old Push implement
    final class HoldPush {
        var tasks: [(UInt64, () -> Void)] = []
        let allowCmds: (CMD) -> Bool
        init(allowCmds: @escaping (CMD) -> Bool) {
            self.allowCmds = allowCmds
        }
        // STAT INFO
        let start = Date()
        var elapse: TimeInterval { -start.timeIntervalSinceNow }
        var cacheSize = 0
        var cacheCount = 0
        func append(order: UInt64, size: Int, action: @escaping () -> Void) {
            tasks.append((order, action))
            cacheSize &+= size
            cacheCount &+= 1
        }
    }
    func pushCallback(
        id: UInt64 = 0, // id用于排序，0保持顺序不变
        cmd: CMD, size: Int, execute: @escaping () -> Void
    ) {
        self.callback(on: self.pushQueue) {
            // FIXME: 如果pushQueue改并发，这个还需要另外的原子性保证..
            if let holdPush = self.holdPush, !holdPush.allowCmds(cmd) {
                return holdPush.append(order: id, size: size, action: execute)
            }
            execute()
        }
    }
    func register<R>(
        serverPushCmd cmd: ServerCommand,
        contextID: String = M.uuid(),
        onCancel: (() -> Void)? = nil,
        onSerial: @escaping (ServerPushPacket<Data>, RustManager.Cache) throws -> (R, String),
        onHandle: @escaping (R) -> Void
    ) -> Disposable {
        if SimpleRustClient.hook?.multiUserFlow == true {
            return registerV2(serverPushCmd: cmd, contextID: contextID,
                              onCancel: onCancel, onSerial: onSerial, onHandle: onHandle)
        }
        let onCancel = onCancel.flatMap { onCancel in
            return { (base: SimpleRustClient) in
                base.callback(on: base.pushQueue, label: "Server PB: Cancel (Push \(cmd))", contextID: contextID) {
                    onCancel()
                }
            }
        }
        func whenDisposed() -> Disposable {
            SimpleRustClient.logger.info("register push \(cmd) on disposed client \(self.identifier)",
                                         additionalData: ["contextID": contextID])
            return Disposables.create()
        }
        if self.disposed {
            onCancel?(self)
            return whenDisposed()
        }
        weak var env = RustManager.shared.registerServerPush(cmd: RustManager.RawCommand(cmd.rawValue)) { [weak self] (env, serverPacket, packet, context) in
            guard let self = self, !self.disposed else { return }
            var contextID = contextID
            if !packet.contextID.isEmpty {
                contextID.append("-")
                contextID.append(packet.contextID)
            }
            if verifyUserID() { return }
            do {
                // serialize data and callback
                var (result, label) = try onSerial(ServerPushPacket(cmd: cmd, contextID: contextID, packet: serverPacket, body: serverPacket.payload), context.cache)
                label = "\(label) (Push \(cmd))"
                let metrics = Metrics(title: "Server PB:\(self.identifier) <-- \(label)", contextID: contextID)
                let doCallback = metrics.wrapCallback {
                    // 异步延迟后再检查一下是否有被释放，虽然不保证并行时取消能立即生效，但应该尽量避免这种在queue里等很久的还发过去
                    if env.disposed {
                        metrics.additional = "(Cancel)"
                        metrics.finish()
                        return
                    }
                    metrics.doCallbackAndFinish {
                        onHandle(result)
                    }
                }
                self.pushCallback(cmd: .server(cmd), size: serverPacket.payload.count, execute: doCallback)
            } catch {
                SimpleRustClient.logger.error("Server PB长链接消息\(cmd)解析失败",
                                              additionalData: ["contextID": contextID],
                                              error: error)
            }
            func verifyUserID() -> Bool {
                let (clientUserID, sdkUserID) = (self.clientUserID, UInt64(packet.userID) ?? 0)
                guard packet.verifyUserID else { return false }
                if clientUserID != sdkUserID {
                    // TODO: 全局的收到用户态的push也应该拦截，为了兼容性先保持不动
                    let intercepted = packet.verifyUserID && clientUserID != 0

                    // TODO: 目前端上没有区分当前用户，且切用户时会保证原有push清空。
                    // 所以应该不会有多余的进入这里，这里需要校验保证不串。
                    // 但以后支持多用户后，这里由rust主动调用的push，就是一个正常的多用户分发接口，不应该再打印日志了。
                    SimpleRustClient.hook?.onInvalidUserID(RustClient.OnInvalidUserID(
                        scenario: "passthrough_push", command: packet.cmd.rawValue, serverCommand: serverPacket.cmd.rawValue,
                        clientUserID: clientUserID, sdkUserID: sdkUserID, contextID: contextID,
                        hasError: packet.isErr, intercepted: intercepted
                        ))
                    if intercepted {
                        SimpleRustClient.logger.info("Server PB:\(self.identifier) <-- InconsistentUser:\(clientUserID) (Push \(cmd))",
                                                     additionalData: ["contextID": contextID])
                        return true
                    }
                }
                return false
            }
        }
        // register cancel block and return
        let cancel = CancelTask { (self) in
            if env?.dispose() == true { onCancel?(self) }
        }
        do {
            try self.add(pushCancelTask: cancel)
        } catch {
            cancel.handler(self)
            return whenDisposed()
        }
        SimpleRustClient.logger.info("register Server Push \(cmd) on \(self.identifier)",
                                     additionalData: ["contextID": contextID])
        let ret = Disposables.create { [weak self] in
            if env?.dispose() == true, let self = self {
                SimpleRustClient.logger.info("register Server Push \(cmd) on \(self.identifier) disposed",
                                             additionalData: ["contextID": contextID])
                self.remove(pushCancelTask: cancel)
            }
        }
        return ret
    }

    // NOTE: rust可能在收到初始化函数过程中就开始推送.., 这样等待初始化结束，会漏消息..(必定收不到)
    // 需要一个明确的可接收通知的时间点..
    // PS1: 如果这里放开限制，注册和初始化是并行的，就有可能收到，也有可能收不到(小概率，看运行速度)
    // PS2: 如果让其在初始化前注册消息，能保证不漏，但是要注意不要和前一个用户的push串了..(push是全局的，user生命周期是端上封装的),
    //      另外提前注册可能让回调提前运行，影响初始化时序
    // PS3: 规范的用法是先注册通知，然后pull一次全量数据，并和Push去重（或者从pull调用后再开始push）
    //
    // 参考解决方案：https://bytedance.feishu.cn/wiki/wikcnyo31cvimqXYwAb0IJQE1Fn#doxcnEAK8WkS20ceeUr1mM9jVpe
    // 使用提前注册加延迟分发的机制
    // 这个方法返回，即代表对应的注册成功，之后的消息都不应该漏
    func register<R>(
        pushCmd cmd: Command,
        contextID: String = M.uuid(),
        onCancel: (() -> Void)? = nil,
        onSerial: @escaping (RustPushPacket<Data>, RustManager.Cache) throws -> (R, String),
        onHandle: @escaping (R) -> Void
    ) -> Disposable {
        if SimpleRustClient.hook?.multiUserFlow == true {
            return registerV2(pushCmd: cmd, contextID: contextID,
                              onCancel: onCancel, onSerial: onSerial, onHandle: onHandle)
        }

        let onCancel = onCancel.flatMap { onCancel in
            // cancel by disposed
            return { (base: SimpleRustClient) in
                base.callback(on: base.pushQueue, qos: M.qos(command: cmd) ?? .unspecified, label: "Cancel (Push \(cmd))", contextID: contextID) {
                    onCancel()
                }
            }
        }
        func whenDisposed() -> Disposable {
            SimpleRustClient.logger.info("register push \(cmd) on disposed client \(self.identifier)",
                                         additionalData: ["contextID": contextID])
            return Disposables.create()
        }
        if self.disposed {
            onCancel?(self)
            return whenDisposed()
        }
        // TODO: 同一cmd可能有多个接收者，优化性能.
        // 现在基本都直接拿的data, 事后再序列化的, 以后API迁移差不多了后再优化
        weak var env = RustManager.shared.register(cmd: RustManager.RawCommand(cmd.rawValue)) { [weak self] (env, packet, context) in
            guard let self = self, !self.disposed else { return }
            var contextID = contextID
            if !packet.contextID.isEmpty {
                contextID.append("-")
                contextID.append(packet.contextID)
            }
            // 验证UserID一致
            // TODO: Push按用户分发，现在只有验证拦截
            if packet.verifyUserID {
                let (clientUserID, sdkUserID) = (self.clientUserID, UInt64(packet.userID) ?? 0)
                if clientUserID != sdkUserID {
                    let intercepted = clientUserID != 0
                    report(clientUserID: clientUserID, sdkUserID: sdkUserID, intercepted: intercepted)
                    if intercepted {
                        // TODO：全局的收到用户态的push，也应该丢弃，但为了兼容性，先保持不动
                        // 另外现在实际上是单用户登录的，所以不应该出现用户不一致的情况。以后支持多用户后可能需要去除这个噪音
                        SimpleRustClient.logger.info("\(self.identifier) <-- InconsistentUser:\(clientUserID) (Push \(cmd))",
                                                     additionalData: ["contextID": contextID])
                        return
                    }
                }
            } else {
                if case let (clientUserID, sdkUserID) = (self.clientUserID, UInt64(packet.userID) ?? 0),
                  sdkUserID != 0,
                  clientUserID != sdkUserID {
                    // 有userid认为是用户态的push，也检查上报
                    report(clientUserID: clientUserID, sdkUserID: sdkUserID, intercepted: false)
                }
                // 全局的，或者之前的，保持不变
                if !packet.userID.isEmpty, let myUserID = self.userID, myUserID != packet.userID { return }
            }
            // 序列化的分发
            do {
                // serialize data and callback
                var (result, label) = try onSerial(RustPushPacket(cmd: cmd, contextID: contextID, packet: packet, body: packet.payload), context.cache)
                label = "\(label) (Push \(cmd))"
                let metrics = Metrics(title: "\(self.identifier) <-- \(label)", contextID: contextID)
                let doCallback = metrics.wrapCallback {
                    // 异步延迟后再检查一下是否有被释放，虽然不保证并行时取消能立即生效，但应该尽量避免这种在queue里等很久的还发过去
                    if env.disposed {
                        metrics.additional = "(Cancel)"
                        metrics.finish()
                        return
                    }
                    let traceId = TraceIdUtil.parseContextId(contextID)
                    TraceIdUtil.setTraceId(traceId)
                    defer { TraceIdUtil.clearTraceId() }
                    metrics.doCallbackAndFinish {
                        onHandle(result)
                    }
                }
                self.pushCallback(cmd: .rust(cmd), size: packet.payload.count, execute: doCallback)
            } catch {
                SimpleRustClient.logger.error("Rust长链接消息\(cmd)解析失败",
                                              additionalData: ["contextID": contextID],
                                              error: error)
            }
            func report(clientUserID: UInt64, sdkUserID: UInt64, intercepted: Bool) {
                // TODO: 目前端上没有区分当前用户，且切用户时会保证原有push清空。
                // 所以应该不会有多余的进入这里，这里需要校验保证不串。
                // 但以后支持多用户后，这里由rust主动调用的push，就是一个正常的多用户分发接口，不应该再打印日志了。
                SimpleRustClient.hook?.onInvalidUserID(RustClient.OnInvalidUserID(
                    scenario: "push", command: packet.cmd.rawValue, serverCommand: nil,
                    clientUserID: clientUserID, sdkUserID: sdkUserID, contextID: contextID,
                    hasError: packet.isErr, intercepted: intercepted
                    ))
            }
        }
        // register cancel block and return
        let cancel = CancelTask { (self) in
            if env?.dispose() == true { onCancel?(self) }
        }
        do {
            try self.add(pushCancelTask: cancel)
        } catch {
            cancel.handler(self)
            return whenDisposed()
        }
        SimpleRustClient.logger.info("register Push \(cmd) on \(self.identifier)",
                                     additionalData: ["contextID": contextID])
        let ret = Disposables.create { [weak self] in
            if env?.dispose() == true, let self = self {
                SimpleRustClient.logger.info("register Push \(cmd) on \(self.identifier) disposed",
                                             additionalData: ["contextID": contextID])
                self.remove(pushCancelTask: cancel)
            }
        }
        return ret
    }
    // MARK: Rust Push Register
    func registerV2<R>(
        pushCmd cmd: Command,
        contextID: String = M.uuid(),
        onCancel: (() -> Void)? = nil,
        onSerial: @escaping (RustPushPacket<Data>, RustManager.Cache) throws -> (R, String),
        onHandle: @escaping (R) -> Void
    ) -> Disposable {
        // 保证在PushQueue上进行回调，保证回调的线程安全性以及避免锁内回调
        let onCancel = wrapPushOnCancel(onCancel, M.qos(command: cmd) ?? .unspecified,
                                        "Cancel (Push \(cmd))", contextID)
        var disposable: Disposable?
        /// 保证注册和dispose检查的原子性
        self.lock.withLocking {
            if self.disposed { return }
            // onCancel被cancel时调用
            let registry = self.getRustPushRegistry(command: cmd)
            let handler = RustPushRegistry.Handler(owner: registry, contextID: contextID,
                                                   onCancel: onCancel, onSerial: onSerial, onHandle: onHandle)
            registry.handlers.update(with: handler)
            disposable = Disposables.create { [weak self, weak handler] in
                if handler?.dispose() == true, let self = self {
                    SimpleRustClient.logger.info("register Push \(cmd) on \(self.identifier) disposed",
                                                 additionalData: ["contextID": contextID])
                }
            }
        }
        guard let disposable else { // lock外回调
            onCancel?(self)
            return whenDisposed()
        }
        // 正常返回disposable
        SimpleRustClient.logger.info("register Push \(cmd) on \(self.identifier)",
                                     additionalData: ["contextID": contextID])
        return disposable

        func whenDisposed() -> Disposable {
            SimpleRustClient.logger.info("register push \(cmd) on disposed client \(self.identifier)",
                                         additionalData: ["contextID": contextID])
            return Disposables.create()
        }
    }

    func getRustPushRegistry(command: Command) -> RustPushRegistry {
        // TODO: 确认是否要分成两个锁，不同状态对应的锁是啥, 一个锁是否有可能死锁..(如果异步queue的话应该不会)
        M.assertAlpha(inLock: lock)
        if let registry = rustPushRegistry[command] { return registry }
        let registry = RustPushRegistry(base: self, command: command)
        rustPushRegistry[command] = registry
        registry.cancel = RustManager.shared.register(cmd: RustManager.RawCommand(command.rawValue),
                                                           handler: registry.onEvent(_:packet:context:))
        return registry
    }

    // 持有关系：
    // RustClient -> [Cmd: RustPushRegistry]
    // RustPushRegistry -> [Handler]
    // caller -> Handler(for dispose)
    enum PushRegistryCancelReason {
    case cancel
    case container
    }
    class RustPushRegistry {
        init(base: SimpleRustClient, command: Command) {
            self.base = base
            self.command = command
        }
        deinit {
        #if DEBUG || ALPHA
        precondition(cancel == nil) // 释放时cancel应该提前取消
        #endif
        }
        weak var base: SimpleRustClient?
        let command: Command
        weak var cancel: RustManager.PushHandler?
        var handlers: Set<BaseHandler> = []

        class BaseHandler: M.DisposableID {
            func onEvent(_ base: SimpleRustClient, packet: Packet, cache: RustManager.Cache) -> (() -> Void)? { nil }
            func onRun(packet: Packet, cache: RustManager.Cache) {}
            func onCancel(base: SimpleRustClient) {}
        }
        class Handler<R>: BaseHandler {
            init(owner: SimpleRustClient.RustPushRegistry?, contextID: String,
                 onCancel: ((SimpleRustClient) -> Void)?,
                 onSerial: @escaping (RustPushPacket<Data>, RustManager.Cache) throws -> (R, String),
                 onHandle: @escaping (R) -> Void
            ) {
                self.owner = owner
                self.contextID = contextID
                self.onCancel = onCancel
                self.onSerial = onSerial
                self.onHandle = onHandle
            }

            weak var owner: RustPushRegistry?
            let contextID: String
            let onCancel: ((SimpleRustClient) -> Void)?
            let onSerial: (RustPushPacket<Data>, RustManager.Cache) throws -> (R, String)
            let onHandle: (R) -> Void

            override func onDispose() {
                // cancel时base会先变为nil, 不过并发可能拿到base但进lock时已经变为nil了, 不过不影响
                guard let owner, let base = owner.base else { return }
                base.lock.withLocking {
                    owner.handlers.remove(self)
                    if owner.handlers.isEmpty, owner.cancel?.dispose() == true {
                        owner.cancel = nil
                        base.rustPushRegistry.removeValue(forKey: owner.command)
                    }
                }
            }
            override func onCancel(base: SimpleRustClient) {
                onCancel?(base)
            }
            fileprivate func withTraceID(contextID: String, action: () -> Void) {
                let traceId = TraceIdUtil.parseContextId(contextID)
                TraceIdUtil.setTraceId(traceId)
                defer { TraceIdUtil.clearTraceId() }
                action()
            }

            override func onEvent(_ base: SimpleRustClient, packet: Packet, cache: RustManager.Cache) -> (() -> Void)? {
                guard let owner else { return nil }
                let cmd = owner.command
                var contextID = contextID
                mayCombindContextID(contextID: &contextID, packet.contextID)
                do {
                    // serialize data and callback
                    var (result, label) = try onSerial(RustPushPacket(cmd: cmd, contextID: contextID, packet: packet, body: packet.payload), cache)
                    label = "\(label) (Push \(cmd))"
                    let metrics = Metrics(title: "\(base.identifier) <-- \(label)", contextID: contextID)
                    return metrics.wrapCallback { [self] in
                        // 异步延迟后再检查一下是否有被释放，虽然不保证并行时取消能立即生效，但应该尽量避免这种在queue里等很久的还发过去
                        if disposed {
                            metrics.additional = "(Cancel)"
                            metrics.finish()
                            return
                        }
                        withTraceID(contextID: contextID) {
                            metrics.doCallbackAndFinish { onHandle(result) }
                        }
                    }
                } catch {
                    SimpleRustClient.logger.error("Rust长链接消息\(cmd)解析失败",
                                                  additionalData: ["contextID": contextID],
                                                  error: error)
                    return nil
                }
            }
            override func onRun(packet: Packet, cache: RustManager.Cache) {
                guard !disposed, let owner, let base = owner.base
                else { return }
                let cmd = owner.command
                var contextID = contextID
                mayCombindContextID(contextID: &contextID, packet.contextID)
                do {
                    let (result, _) = try onSerial(RustPushPacket(
                        cmd: cmd, contextID: contextID, packet: packet, body: packet.payload), cache)
                    withTraceID(contextID: contextID) {
                        onHandle(result)
                    }
                } catch {
                    SimpleRustClient.logger.error("Rust长链接消息\(cmd)解析失败",
                                                  additionalData: ["contextID": contextID],
                                                  error: error)
                }
            }
        }
        func onEvent(_ handler: RustManager.PushHandler, packet: Packet, context: RustManager.PushContext) {
            guard let base, !base.disposed else { return }
            var revalidContainerID: Bool = false
            let cmd: CMD = .rust(command)
            switch base.checkPushAction(packet: packet, cmd: cmd) {
            case .deny: return
            case .allow:
                let doCallback = base.lock.withLocking(action: { handlers }).compactMap {
                    $0.onEvent(base, packet: packet, cache: context.cache)
                }
                if doCallback.isEmpty { return }
                // 还得保证holdPush后的分发顺序..
                base.pushCallback(id: context.counter, cmd: cmd, size: packet.payload.count) {
                    for v in doCallback { v() }
                }
            case .later:
                revalidContainerID = true
                fallthrough
            case .maymove:
                if base.lock.withLocking(action: { handlers }).isEmpty { return }
                base.enqueueAndDispatch(msg: .init(id: context.counter, rustContainerID: packet.userContainerID,
                                                   revalidContainerID: revalidContainerID,
                                                   payload: .rust(command, packet)))
            }
        }
        func run(packet: Packet) {
            guard let base else { return }
            let handlers = base.lock.withLocking { self.handlers }
            let cache = RustManager.Cache()
            for v in handlers {
                v.onRun(packet: packet, cache: cache)
            }
        }
    }
    // MARK: Server Push Register
    func registerV2<R>(
        serverPushCmd cmd: ServerCommand,
        contextID: String = M.uuid(),
        onCancel: (() -> Void)? = nil,
        onSerial: @escaping (ServerPushPacket<Data>, RustManager.Cache) throws -> (R, String),
        onHandle: @escaping (R) -> Void
    ) -> Disposable {
        // 保证在PushQueue上进行回调，保证回调的线程安全性以及避免锁内回调
        let onCancel = wrapPushOnCancel(onCancel, .unspecified,
                                        "Server PB: Cancel (Push \(cmd))", contextID)
        var disposable: Disposable?
        /// 保证注册和dispose检查的原子性
        self.lock.withLocking {
            if self.disposed { return } // lock外回调whenDisposed
            // onCancel被cancel时调用
            let registry = self.getServerPushRegistry(command: cmd)
            let handler = ServerPushRegistry.Handler(owner: registry, contextID: contextID,
                                                   onCancel: onCancel, onSerial: onSerial, onHandle: onHandle)
            registry.handlers.update(with: handler)
            disposable = Disposables.create { [weak self, weak handler] in
                if handler?.dispose() == true, let self = self {
                    SimpleRustClient.logger.info("register Server Push \(cmd) on \(self.identifier) disposed",
                                                 additionalData: ["contextID": contextID])
                }
            }
        }
        guard let disposable else { // lock外回调
            onCancel?(self)
            return whenDisposed()
        }
        // 正常返回disposable
        SimpleRustClient.logger.info("register Server Push \(cmd) on \(self.identifier)",
                                     additionalData: ["contextID": contextID])
        return disposable

        func whenDisposed() -> Disposable {
            SimpleRustClient.logger.info("register push \(cmd) on disposed client \(self.identifier)",
                                         additionalData: ["contextID": contextID])
            return Disposables.create()
        }
    }

    func getServerPushRegistry(command: ServerCommand) -> ServerPushRegistry {
        // TODO: 确认是否要分成两个锁，不同状态对应的锁是啥, 一个锁是否有可能死锁..(如果异步queue的话应该不会)
        M.assertAlpha(inLock: lock)
        if let registry = serverPushRegistry[command] { return registry }
        let registry = ServerPushRegistry(base: self, command: command)
        serverPushRegistry[command] = registry
        registry.cancel = RustManager.shared.registerServerPush(cmd: RustManager.RawCommand(command.rawValue),
                                                                handler: registry.onEvent(_:server:packet:context:))
        return registry
    }

    class ServerPushRegistry {
        init(base: SimpleRustClient, command: ServerCommand) {
            self.base = base
            self.command = command
        }
        deinit {
        #if DEBUG || ALPHA
        precondition(cancel == nil) // 释放时cancel应该提前取消
        #endif
        }
        weak var base: SimpleRustClient?
        let command: ServerCommand
        weak var cancel: RustManager.ServerPushHandler?
        var handlers: Set<BaseHandler> = []

        class BaseHandler: M.DisposableID {
            func onEvent(pushContextID: String, serverPacket: ServerPacket, cache: RustManager.Cache)
            -> (() -> Void)? { nil }
            func onRun(pushContextID: String, serverPacket: ServerPacket, cache: RustManager.Cache) {}
            func onCancel(base: SimpleRustClient) {}
        }
        class Handler<R>: BaseHandler {
            init(owner: SimpleRustClient.ServerPushRegistry?, contextID: String,
                 onCancel: ((SimpleRustClient) -> Void)?,
                 onSerial: @escaping (ServerPushPacket<Data>, RustManager.Cache) throws -> (R, String),
                 onHandle: @escaping (R) -> Void
            ) {
                self.owner = owner
                self.contextID = contextID
                self.onCancel = onCancel
                self.onSerial = onSerial
                self.onHandle = onHandle
            }

            weak var owner: ServerPushRegistry?
            let contextID: String
            let onCancel: ((SimpleRustClient) -> Void)?
            let onSerial: (ServerPushPacket<Data>, RustManager.Cache) throws -> (R, String)
            let onHandle: (R) -> Void

            override func onDispose() {
                // cancel时base会先变为nil, 不过并发可能拿到base但进lock时已经变为nil了, 不过不影响
                guard let owner, let base = owner.base else { return }
                base.lock.withLocking {
                    owner.handlers.remove(self)
                    if owner.handlers.isEmpty, owner.cancel?.dispose() == true {
                        owner.cancel = nil
                        base.serverPushRegistry.removeValue(forKey: owner.command)
                    }
                }
            }
            override func onCancel(base: SimpleRustClient) {
                onCancel?(base)
            }
            override func onEvent(pushContextID: String, serverPacket: ServerPacket, cache: RustManager.Cache) -> (() -> Void)? {
                guard let owner, let base = owner.base else { return nil }
                let cmd = owner.command
                var contextID = contextID
                mayCombindContextID(contextID: &contextID, pushContextID)
                do {
                    // serialize data and callback
                    var (result, label) = try onSerial(ServerPushPacket(cmd: cmd, contextID: contextID, packet: serverPacket, body: serverPacket.payload), cache)
                    label = "\(label) (Push \(cmd))"
                    let metrics = Metrics(title: "Server PB:\(base.identifier) <-- \(label)", contextID: contextID)
                    return metrics.wrapCallback { [self] in
                        // 异步延迟后再检查一下是否有被释放，虽然不保证并行时取消能立即生效，但应该尽量避免这种在queue里等很久的还发过去
                        if disposed {
                            metrics.additional = "(Cancel)"
                            metrics.finish()
                            return
                        }
                        metrics.doCallbackAndFinish { onHandle(result) }
                    }
                } catch {
                    SimpleRustClient.logger.error("Server PB长链接消息\(cmd)解析失败",
                                                  additionalData: ["contextID": contextID],
                                                  error: error)
                    return nil
                }
            }
            override func onRun(pushContextID: String, serverPacket: ServerPacket, cache: RustManager.Cache) {
                guard !disposed, let owner, let base = owner.base
                else { return }
                let cmd = owner.command
                var contextID = contextID
                mayCombindContextID(contextID: &contextID, pushContextID)
                do {
                    // serialize data and callback
                    let (result, _) = try onSerial(ServerPushPacket(cmd: cmd, contextID: contextID, packet: serverPacket, body: serverPacket.payload), cache)
                    onHandle(result)
                } catch {
                    SimpleRustClient.logger.error("Server PB长链接消息\(cmd)解析失败",
                                                  additionalData: ["contextID": contextID],
                                                  error: error)
                }
            }
        }
        func onEvent(_ handler: RustManager.ServerPushHandler, server: ServerPacket, packet: Packet, context: RustManager.PushContext) {
            guard let base, !base.disposed else { return }
            var revalidContainerID: Bool = false
            let cmd: CMD = .server(command)
            switch base.checkPushAction(packet: packet, cmd: cmd) {
            case .deny: return
            case .allow:
                let doCallback = base.lock.withLocking(action: { handlers }).compactMap {
                    $0.onEvent(pushContextID: packet.contextID, serverPacket: server, cache: context.cache)
                }
                if doCallback.isEmpty { return }
                base.pushCallback(id: context.counter, cmd: cmd, size: packet.payload.count) {
                    for v in doCallback { v() }
                }
            case .later:
                revalidContainerID = true
                fallthrough
            case .maymove:
                if base.lock.withLocking(action: { handlers }).isEmpty { return }
                base.enqueueAndDispatch(
                    msg: .init(id: context.counter, rustContainerID: packet.userContainerID,
                               revalidContainerID: revalidContainerID,
                               payload: .server(command, ServerPushPacket(cmd: command, contextID: packet.contextID,
                                                                          packet: server, body: server.payload))))
            }
        }
        func run(pushContextID: String, server: ServerPacket) {
            guard let base else { return }
            let handlers = base.lock.withLocking { self.handlers }
            let cache = RustManager.Cache()
            for v in handlers {
                v.onRun(pushContextID: pushContextID, serverPacket: server, cache: cache)
            }
        }
    }
    // MARK: Common
    func onDisposeCancelPush() {
        M.assertAlpha(inLock: lock)
       for registry in rustPushRegistry.values {
           if registry.cancel?.dispose() == true { registry.cancel = nil }

           registry.base = nil // 避免dispose反向调用死锁，这里直接dispose并调用cancel
           for handler in registry.handlers {
               // NOTE: onCancel需要注意会被dispatch到PushQueue，不会在锁内进行
               if handler.dispose() == true { handler.onCancel(base: self) }
           }
       }
       rustPushRegistry = [:]

       for registry in serverPushRegistry.values {
           if registry.cancel?.dispose() == true { registry.cancel = nil }

           registry.base = nil // 避免dispose反向调用死锁，这里直接dispose并调用cancel
           for handler in registry.handlers {
               // NOTE: onCancel需要注意会被dispatch到PushQueue，不会在锁内进行
               if handler.dispose() == true { handler.onCancel(base: self) }
           }
       }
       serverPushRegistry = [:]
    }
    /// 将当前client的push转移给下一个实例，保证push连续性，不会丢也不会漏
    /// 下一个实例需要提前加上push栅栏，注册push防止漏(外面时序保证)
    /// 然后这里原子性的等待当前的处理结束，转移存量没处理的数据(注意去重)，
    /// 并废弃旧实例上的push以拦截lock外的数据.
    public func movePushToNewClient(next: SimpleRustClient) {
        /// 需要保证转移在next的barrier结束前处理完成。所以这里占用next的barrier queue进行转移
        next.pushQueue.async(flags: .barrier) {
            guard let holdPush = next.holdPush else {
                M.preconditionAlpha(false, "next holdPush should not be nil")
                return
            }
            self.pushQueue.sync(flags: .barrier) {
                // FIXME: 因为push和这里调用的并发性，可能存在push消息处理慢,
                // 在新实例注册前开始分发，但后进queue的时序.
                // 这样的消息会因为没有在转移前进queue而被丢弃
                // 但这里从注册到这里经过了这么多代码和lock等待，还没处理完后进queue的概率很小吧？
                // FIXME: 另外因为异步的并发性，可能存在进入queue中, self已经被dispose, 缺少转移数据的情况
                self._movePushToNewClient(next: next, holdPush: holdPush)
            }
        }
    }
    private func _movePushToNewClient(next: SimpleRustClient, holdPush: HoldPush) {
        M.logger.info("move hold push from \(self.identifier) to \(next.identifier)")
        defer { M.logger.info("did move hold push from \(self.identifier) to \(next.identifier)") }
        // 进入queue后，保证其他在queue上的当前处理都已经结束了

        do {
            self.pushMsgQueueLock.lock(); defer { self.pushMsgQueueLock.unlock() }
            next.pushMsgQueueLock.lock(); defer { next.pushMsgQueueLock.unlock() }
            // 转移全生命周期的存量数据
            if let rustContainerID {
                let moved = pushMsgQueue.filter { msg in
                    msg.rustContainerID == rustContainerID.user && next.pushMsgQueue.insert(msg).inserted
                }.sorted(by: { $0.id < $1.id })
                for msg in moved {
                    msg.finishMetrics(label: "Moved")
                    let metrics = Metrics(title: "\(next.identifier) <-- Move Raw (Push \(msg.cmd)", contextID: msg.contextID)
                    msg.metrics = metrics
                    msg.inQueueTimer = metrics.makeCallbackQueueTimer()
                    msg.revalidateContainerID = true

                    holdPush.append(order: msg.id, size: msg.dataSize) { [weak next] in
                        next?.handle(msg: msg)
                    }
                }
                if !moved.isEmpty {
                    // 保证执行顺序:
                    // 现在需要把旧流程和新流程里的任务进行合并，因此需要顺序比较.
                    // 需要保证传递了顺序ID
                    holdPush.tasks.sort(by: {
                                            #if ALPHA
                                            precondition($0.0 != 0, "should give order for holdPush")
                                            #endif
                                            return $0.0 < $1.0
                                        })
                }
                pushMsgQueue.subtract(moved)
            } else {
                // NOTE: containerID没有说明登录都没有成功.. 不应该出现这种情况，需要保证登录和切换的原子性. 忽略这种情况
                M.preconditionAlpha(false, "rustContainerID must set when move to new client")
                return
            }
        }
        // 注销当前实例的push处理, 这样后续请求就不会重复处理了（会被新实例处理）
        // 新旧实例能处理的CMD可能并不完全一致。旧实例的生命周期已经结束了..
        lock.withLocking { onDisposeCancelPush() }
        clearMSGOnDispose() // 其他的没转移的push，提前清理了..
    }

    /// - Parameter revalidContainerID: set when need to valid container ID later(after barrier)
    enum PushAction {
    case deny // 验证不通过，不进行分发
    case allow // 验证通过，正常分发
    case later // 延迟验证容器ID. 但不确定是否跨容器保活. 登录成功前收到的都是这类消息..
    case maymove // 验证通过，需要跨容器保活
    }
    func checkPushAction(packet: Packet, cmd: CMD) -> PushAction {
        /// 经过和@zhangmeng沟通，使用verifyUserID判断是否用户态cmd
        /// 全局态push始终allow
        func withLog(_ type: PushAction, _ reason: String) -> PushAction {
            // M.logger.info("check msg: \(cmd) \(type) By \(reason)", additionalData: ["contextID": packet.contextID])
            return type
        }
        guard packet.verifyUserID else { return withLog(.allow, "no verifyUserID") }

        let (clientUserID, sdkUserID) = (self.clientUserID, UInt64(packet.userID) ?? 0)
        // TODO: 全局的收到用户态的push也应该拦截，为了兼容性先保持不动
        // TODO: 多用户下，全局实例应该只兼容前台用户
        if clientUserID == 0 { return withLog(.allow, "clientUserID == 0") }

        guard clientUserID == sdkUserID else { return withLog(.deny, "clientUserID != sdkUserID") } // 用户ID不一致，拒绝

        guard packet.hasUserContainerID else { return withLog(.allow, "no userContainerID") } // rust没有设置containerID，先放行
        let targetID = packet.userContainerID
        // NOTE: 没有设置的用户态client需要延迟验证. 另外也要避免其他人创建实例
        // 这个时间看起来比较短，这里的push不多.., 而maymove的cmd也不多..
        guard let rustContainerID else { return withLog(.later, "rustContainerID not ready") }
        if targetID == rustContainerID.dest { return withLog(.allow, "targetID == rustContainerID.dest") }
        if targetID == rustContainerID.user {
            if SimpleRustClient.hook?.shouldKeepLive(cmd: cmd) == true {
                return withLog(.maymove, "targetID == rustContainerID.user")
            } else {
                return withLog(.allow, "targetID == rustContainerID.user")
            }
        }
        return withLog(.deny, "containerID not expect")
    }
    func validContainerID(_ id: UInt64) -> Bool {
        guard let rustContainerID else { return true } // 没有设置的在这里先放行
        return _validContainerID(id, rustContainerID: rustContainerID)
    }
    private func _validContainerID(_ id: UInt64, rustContainerID: (UInt64, UInt64)) -> Bool {
        return id == rustContainerID.0 || id == rustContainerID.1
    }
    func wrapPushOnCancel(_ onCancel: (() -> Void)?, _ qos: @autoclosure () -> DispatchQoS, _ label: @autoclosure () -> String, _ contextID: String) -> ((SimpleRustClient) -> Void)? {
        return onCancel.flatMap { onCancel in
            // cancel by disposed
            let (label, qos) = (label(), qos())
            return { (base: SimpleRustClient) in
                base.callback(on: base.pushQueue, qos: qos, label: label, contextID: contextID) {
                    onCancel()
                }
            }
        }
    }
    class PushMsg: Hashable {
        init(id: UInt64, rustContainerID: UInt64, revalidContainerID: Bool, payload: SimpleRustClient.PushMsg.Payload) {
            self.rustContainerID = rustContainerID
            self.payload = payload
            self.revalidateContainerID = revalidContainerID
            self.id = id
        }

        let id: UInt64 // 需要保证按顺序增加
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func == (lhs: PushMsg, rhs: PushMsg) -> Bool { lhs.id == rhs.id }

        let rustContainerID: UInt64
        let payload: Payload
        var revalidateContainerID: Bool
        // 只有进出会获取的属性，应该不用保护
        var metrics: Metrics?
        var inQueueTimer: Metrics.BlockedTimer?

        enum Payload {
        case rust(Command, Packet)
        case server(ServerCommand, ServerPushPacket<Data>)
        }
        // computed properties
        var cmd: CMD {
            switch payload {
            case .rust(let cmd, _): return .rust(cmd)
            case .server(let cmd, _): return .server(cmd)
            }
        }
        var dataSize: Int {
            switch payload {
            case .rust(_, let packet): return packet.payload.count
            case .server(_, let packet): return packet.body.count
            }
        }
        var contextID: String {
            switch payload {
            case .rust(_, let packet): return packet.contextID
            case .server(_, let packet): return packet.contextID
            }
        }
        func finishInQueueTimer() {
            if let timer = inQueueTimer {
                inQueueTimer = nil
                metrics?.finishCallbackQueueTimer(timer: timer)
            }
        }
        func finishMetrics(label: String) {
            guard let metrics else { return }
            if let timer = inQueueTimer {
                inQueueTimer = nil
                metrics.finishCallbackQueueTimer(timer: timer)
            }
            metrics.additional = label
            metrics.finish()
            self.metrics = nil
        }
    }
    private func enqueue(msg: PushMsg) {
        pushMsgQueueLock.lock(); defer { pushMsgQueueLock.unlock() }
        let old = pushMsgQueue.update(with: msg)
        #if ALPHA
        if nil != old {
            fatalError("unreachable. enqueue msg should be a new one and unique!")
        }
        #endif
    }
    private func dequeue(msg: PushMsg) -> PushMsg? {
        pushMsgQueueLock.lock(); defer { pushMsgQueueLock.unlock() }
        return pushMsgQueue.remove(msg)
    }
    func enqueueAndDispatch(msg: PushMsg) {
        let metrics = Metrics(title: "\(identifier) <-- Raw (Push \(msg.cmd)", contextID: msg.contextID)
        msg.metrics = metrics
        // NOTE: dequeue时消费metrics. msg需要保证一定被消费且只被消费一次.
        // dispose场景，会清理全部并进行标记
        msg.inQueueTimer = metrics.makeCallbackQueueTimer()
        enqueue(msg: msg)

        // 全局栅栏可能会延迟pushQueue的分发..
        // 每次进queue，保证有一次配对的可能出Queue
        callback(on: pushQueue) { [weak self, weak msg] in
            // NOTE: 出Queue后发现dispose的场景，可能导致转移遗漏. 初步思路：
            // 遗漏只可能发生在出Queue后，发现dispose, 没有转移的场景.
            // 转移同时应该dispose(可能push应该单独dispose.., 避免生命周期的重叠)
            // 需要保证切换，push，出queue的原子性，保证原子性切换到新的实例上

            // NOTE: 这里取出来的可能是另外的msg，不一定和前面进queue的是同一个.., 只是保证触发一次出queue调用
            guard let self, let msg else { return }
            // 1. 有HoldPush的时候延迟处理.
            // 2. 白名单中, 验证containerID的会等设置完了后，提前分发
            // 3. 白名单中，不需要验证containerID的，或者已经有containerID了, 需要插队直接分发..
            // NOTE: 如果未来pushQueue支持并发的话, 或者pushQueue外使用holdPush，读写的地方需要加锁. 
            if let holdPush {
                if holdPush.allowCmds(msg.cmd) {
                    if msg.revalidateContainerID && self.rustContainerID == nil {
                        // NOTE: containerID设置完后，会提前清理allowCmds的命令. 以及对应的原子性保证
                        // NOTE: Push栅栏需要在containerID设置完成后，再触发结束..
                        return cache()
                    }
                    // direct handle
                } else {
                    return cache()
                }
                func cache() {
                    holdPush.append(order: msg.id, size: msg.dataSize) { [weak self] in
                        self?.handle(msg: msg)
                    }
                }
            }
            self.handle(msg: msg)
        }
    }
    func handle(msg: PushMsg) {
        // NOTE: msgQueue只保证了msg一定被处理一次.
        // 但处理的这一次，可能因为并发dispose，而不被业务实际接收处理。
        // 转移的handle，需要尽量保证转移的原子性，以及转移前出队列的消息的到达率..
        // 考虑消息在pushQueue上barrier处理，来保证旧的消息都处理完了再转移, 且无新增消息..
        guard !self.disposed, let msg = self.dequeue(msg: msg) else { return }
        if msg.revalidateContainerID && !validContainerID(msg.rustContainerID) {
            return msg.finishMetrics(label: "Invalid ContainerID")
        }
        msg.finishInQueueTimer()

        if let metrics = msg.metrics {
            // 这里没有考虑具体handler的cancel，只能说self没有disposed和cancel. 但也没保证严格时序.
            metrics.doCallbackAndFinish(action: run)
        } else {
            run()
        }

        func run() {
            switch msg.payload {
            case .rust(let cmd, let packet):
                guard let registry = lock.withLocking(action: { rustPushRegistry[cmd] }) else { return }
                registry.run(packet: packet)
            case .server(let cmd, let packet):
                guard let registry = lock.withLocking(action: { serverPushRegistry[cmd] }) else { return }
                registry.run(pushContextID: packet.contextID, server: packet.packet)
            }
        }
    }
    /// 确保对应的日志配对不丢失
    func clearMSGOnDispose() {
        /// 可能会有并发的msg出queue还在运行，且没有实际handler处理，这时需要结合handler的cancel日志看
        pushMsgQueueLock.lock(); defer { pushMsgQueueLock.unlock() }
        for v in pushMsgQueue {
            v.finishMetrics(label: "(Cancel)")
        }
        pushMsgQueue.removeAll()
    }
}
private func mayCombindContextID(contextID: inout String, _ packetContextID: String) {
    if !packetContextID.isEmpty {
        contextID.append("-")
        contextID.append(packetContextID)
    }
}
