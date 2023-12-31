//
//  RustManager.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/8/11.
//

import Foundation
import UIKit
import SwiftProtobuf
import RustPB
import EEAtomic
import ServerPB
import RustSDK

// 内部类，不希望外界直接用。临时public
// swiftlint:disable missing_docs

/// Rust Raw Api Manager & Encapsulator
/// it's thread safe
public final class RustManager {
    /// rust is a singleton, so do RustManager
    public static var shared = RustManager()
    private let lock = UnfairLockCell()
    init() {}
    deinit {
        lock.deallocate()
        _nextRequestID.deallocate()
        pushCounter.deallocate()
    }

    /// raw command
    public typealias RawCommand = Int32

    public func extractCommand(fromRequest: SwiftProtobuf.Message) -> Command {
        if let req = fromRequest as? MessageRequest {
            return req.protoMessageCmd
        }
        return .unknownCommand
    }

    // MARK: sync invoke method
    func invokeV2(command: RawCommand, data: Data) -> LarkInvokeResponseBridge {
        let response = data.withUnsafeBytes {
            lark_sdk_invoke_v2(command, LarkBuffer($0.bindMemory(to: UInt8.self)))
        }
        return LarkInvokeResponseBridge(response)
    }

    // MARK: async invoke method, wrap context into a closure

    /// async invoke callback
    public typealias AsyncCallback = (_ data: Data?, _ hasError: Bool) -> Void
    public typealias AsyncCallbackV2 = (_ data: LarkBuffer, _ hasError: Bool, _ verifyUserID: Bool, _ userID: UInt64) -> Void
    private var requests = [Int64: AsyncCallbackV2]()
    private var _nextRequestID = AtomicInt64Cell(1)
    /// 必须使用该方法统一管理生成id，否则id可能重复。此id和FetchRequest的id一致
    func nextRequestID() -> Int64 {
        return _nextRequestID.increment(order: .relaxed)
    }
    func addRequest(for id: Int64, handler: @escaping AsyncCallbackV2) {
        lock.lock(); defer { lock.unlock() }
        assert(requests[id] == nil, "can't override exist request event handler")
        requests[id] = handler
    }
    func removeRequest(for id: Int64) -> AsyncCallbackV2? {
        lock.lock(); defer { lock.unlock() }
        return requests.removeValue(forKey: id)
    }

    /// 异步调用
    func invokeAsync(command: RawCommand, data: Data, callback: AsyncCallback?) {
        var callbackV2: AsyncCallbackV2?
        if let cb = callback {
            callbackV2 = { data, hasError, _,_ in
                cb(data.toData(), hasError) // copy the data, to ensure alive
            }
        }
        invokeAsyncV2(command: command, data: data, callback: callbackV2)
    }

    // NOTE: callback payload is valid only in callback
    func invokeAsyncV2(command: RawCommand, data: Data, callback: AsyncCallbackV2?) {
        let id = nextRequestID()
        if let cb = callback { addRequest(for: id, handler: cb) }
        data.withUnsafeBytes { (payload) -> Void in
            invoke_async_v2(
                command,
                payload.bindMemory(to: UInt8.self).baseAddress,
                payload.count,
                id) { (requestID: Int64, hasError: Bool, shouldVerifyUser: Bool, userID: UInt64, payload: UnsafePointer<UInt8>?, count: Int) -> Void in // swiftlint:disable:this all
                    // rust 没有创建自动释放池，不处理可能会有内存泄露
                    autoreleasepool {
                        // ignore no callback response.
                        guard let callback = RustManager.shared.removeRequest(for: requestID) else { return }
                        callback(LarkBuffer(data: payload, length: count),
                                 hasError,
                                 shouldVerifyUser,
                                 userID)
                    }
                }}
    }

    // MARK: event stream api
    private var streams = [Int64: Stream]()
    private func addStream(for id: Int64, stream: Stream) {
        lock.lock(); defer { lock.unlock() }
        assert(streams[id] == nil, "can't override exist stream")
        streams[id] = stream
    }
    private func stream(for id: Int64) -> Stream? {
        lock.lock(); defer { lock.unlock() }
        return streams[id]
    }
    @discardableResult
    private func removeStream(for id: Int64) -> Stream? {
        lock.lock(); defer { lock.unlock() }
        return streams.removeValue(forKey: id)
    }
    /// this class used to encapsulate eventStream callback, and manage stream state, to ensure only dispose once
    /// it's hold by RustManager, and removed when dispose
    final class Stream {
        typealias OnEvent = (Stream, Packet) -> Void

        private let taskID: Int64
        private let onEvent: OnEvent
        init(id: Int64, onEvent: @escaping OnEvent) {
            taskID = id
            self.onEvent = onEvent
        }
        deinit { _disposed.deallocate() }

        private var _disposed = AtomicBoolCell()
        var disposed: Bool {
            return _disposed.value
        }
        /// return true when first dispose
        @discardableResult
        func dispose() -> Bool {
            if _disposed.exchange(true) == false {
                RustManager.shared.removeStream(for: taskID)
                return true
            }
            return false
        }
        /// cancel will notify rust.
        /// - Returns: true if not finish and first cancel
        @discardableResult
        func cancel() -> Bool {
            if dispose() {
                var cancelNotify = CancelStreamCallbackRequest()
                cancelNotify.taskID = self.taskID
                RustManager.shared.invokeAsync(
                    command: RustManager.RawCommand(Command.cancelStreamCallback.rawValue),
                    data: (try? cancelNotify.serializedData()) ?? {
                        #if DEBUG || ALPHA
                        fatalError("unexpected serialize exception")
                        #else
                        return Data()
                        #endif
                    }() ,
                    callback: nil
                )
                return true
            }
            return false
        }

        func handle(packet: Packet) {
            if self.disposed { return } // dispose后不再发消息
            switch packet.streamStatus {
            case .finalWithPayload, .finalWithoutPayload:
                dispose()
            @unknown default: break
            }
            onEvent(self, packet)
        }
    }
    /// make a event stream, rust will callback multiple times
    ///
    /// - Parameters:
    ///   - request: the Basic_V1_RequestPacket, will fill taskID, and event stream type. caller not need to set it
    ///   - callback: callback will be hold, and call 0~N times
    /// - Returns: a observable which can be cancel
    /// - Throws: `BinaryEncodingError` if Basic_V1_RequestPacket encoding fails.
    func eventStream(command: RawCommand, request: Basic_V1_RequestPacket, callback: @escaping Stream.OnEvent)
    throws -> Stream {
        // TODO: 迁移到V2接口, 因为这里的回调是packet，所以就先不动了，等async v2彻底改造后讨论
        let id = nextRequestID()
        var req = request
        req.taskID = id
        req.isCallbackByStream = true
        let data = try req.serializedData()
        let stream = Stream(id: id, onEvent: callback)

        RustManager.shared.addStream(for: id, stream: stream)
        data.withUnsafeBytes { (payload) -> Void in
            invoke_async_v2(
                command,
                payload.bindMemory(to: UInt8.self).baseAddress,
                payload.count,
                id,
                nil)
        }
        return stream
    }

    func eventStream(handle packet: Packet) {
        guard let stream = stream(for: packet.taskID) else { return }
        stream.handle(packet: packet)
    }

    // MARK: push notify
    private var pushHandlers: [RawCommand: Set<PushHandler>] = [:]
    private func add(pushHandler: PushHandler) {
        lock.lock(); defer { lock.unlock() }
        let old = pushHandlers[pushHandler.cmd, default: []].update(with: pushHandler)
        assert(old == nil, "each handler should be unique!!")
    }
    func pushHandlers(cmd: RawCommand) -> Set<PushHandler> {
        lock.lock(); defer { lock.unlock() }
        return pushHandlers[cmd, default: []]
    }
    private func remove(pushHandler: PushHandler) {
        lock.lock(); defer { lock.unlock() }
        pushHandlers[pushHandler.cmd]?.remove(pushHandler)
    }
    class BasePushHandler: M.DisposableID {
        let cmd: RawCommand
        init(cmd: RawCommand) {
            self.cmd = cmd
        }
    }
    /// this class encapsulate the push handler environment
    final class PushHandler: BasePushHandler {
        /// handle push result
        typealias OnEvent = (PushHandler, Packet, PushContext) -> Void
        let onEvent: OnEvent
        override func onDispose() {
            RustManager.shared.remove(pushHandler: self)
        }

        init(cmd: RawCommand, onEvent: @escaping OnEvent) {
            self.onEvent = onEvent
            super.init(cmd: cmd)
        }
    }

    // MARK: Server push notify
    private var serverPushHandlers: [RawCommand: Set<ServerPushHandler>] = [:]
    private func add(pushHandler: ServerPushHandler) {
        lock.lock(); defer { lock.unlock() }
        let old = serverPushHandlers[pushHandler.cmd, default: []].update(with: pushHandler)
        assert(old == nil, "each handler should be unique!!")
    }
    func serverPushHandlers(cmd: RawCommand) -> Set<ServerPushHandler> {
        lock.lock(); defer { lock.unlock() }
        return serverPushHandlers[cmd, default: []]
    }
    private func remove(pushHandler: ServerPushHandler) {
        lock.lock(); defer { lock.unlock() }
        serverPushHandlers[pushHandler.cmd]?.remove(pushHandler)
    }
    final class ServerPushHandler: BasePushHandler {
        /// handle push result
        typealias OnEvent = (ServerPushHandler, ServerPacket, Packet, PushContext) -> Void
        let onEvent: OnEvent
        init(cmd: RawCommand, onEvent: @escaping OnEvent) {
            self.onEvent = onEvent
            super.init(cmd: cmd)
        }
        override func onDispose() {
            RustManager.shared.remove(pushHandler: self)
        }
    }

    /// 注册一个通知处理, 同一cmd可以注册多个处理方法，都会被调用但不保证顺序
    ///
    /// - Parameters:
    ///   - cmd: 要处理的Command
    ///   - handler: 处理回调，不应该占用过长时间
    /// - Returns: 可被取消的handler
    func register(cmd: RawCommand, handler: @escaping PushHandler.OnEvent) -> PushHandler {
        let handler = RustManager.PushHandler(cmd: cmd, onEvent: handler)
        add(pushHandler: handler)
        return handler
    }
    func registerServerPush(cmd: RawCommand, handler: @escaping ServerPushHandler.OnEvent) -> ServerPushHandler {
        let handler = RustManager.ServerPushHandler(cmd: cmd, onEvent: handler)
        add(pushHandler: handler)
        return handler
    }

    /// use to cache and avoid serial data to msg multiple times. used for one packet once
    final class Cache {
        var store: [ObjectIdentifier: (Result<Any, Error>, Data)] = [:]
        func onSerial<R: Message>(data: Data) throws -> R {
            let key = ObjectIdentifier(R.self)
            if let msg = store[key] {
                #if ALPHA || DEBUG
                precondition(msg.1 == data, "should be same data for reuse cache msg")
                printVerbose("reuse message for \(R.protoMessageName)")
                #endif
                if let v = try msg.0.get() as? R { return v }
                #if DEBUG || ALPHA
                fatalError("cache storage should be isolate by same type!")
                #endif
            }
            let result = Result { try R(serializedData: data, options: .discardUnknownFieldsOption) }
            store[key] = (result.map { $0 }, data)
            return try result.get()
        }
    }
    struct PushContext {
        var cache = Cache()
        let counter: UInt64
    }
    /// rust的push应该是串行的，不过这里再加一层保护
    let pushCounter = AtomicUInt64Cell(1)
    func push(handle packet: Packet) {
        var context = PushContext(counter: pushCounter.increment())
        #if ALPHA
        // 保证cache的线程安全，没有被其他线程持有
        defer { precondition(isKnownUniquelyReferenced(&context.cache), "push cache should used directly") }
        #endif

        if packet.cmd == .passThroughPush {
            // 透传push
            guard let serverPushPacket = try? ServerPB.ServerPB_Improto_Packet(serializedData: packet.payload) else {
                SimpleRustClient.logger.info("server push serialization failed")
                return
            }
            let handlers = serverPushHandlers(cmd: RustManager.RawCommand(serverPushPacket.command))
            for handler in handlers {
                if handler.disposed { continue }
                handler.onEvent(handler, serverPushPacket, packet, context)
            }
            return
        }
        for handler in pushHandlers(cmd: RustManager.RawCommand(packet.cmd.rawValue)) {
            if handler.disposed { continue }
            handler.onEvent(handler, packet, context)
        }
    }
}

/// some RustPB API encapsulate
extension RustManager {
    /// must call this method before call other methods
    ///
    /// NOTE: if call multiple times, rust will overwrite the configuration.
    ///
    /// - Returns: 0 if success
    /// - Throws: `BinaryEncodingError` if encoding fails.
    func initialize(config: InitSDKRequest) throws -> Int {
        return try config.serializedData().withUnsafeBytes {
            Int(lark_sdk_init($0.bindMemory(to: UInt8.self).baseAddress, $0.count, process(push:length:)))
        }
    }
}


/// NOTE: 多用户框架下，rust的push需要按containerID一致进行分发.
/// 另外端上需要等初始化过后才能开始正常处理push，需要保证初始化过程中的push不丢. 甚至rust保活跨状态容器的消息也不丢
/// 而全局的push于用户无关，不应该拦截..
/// 因此考虑到跨容器状态，需要统一的拦截和缓存机制..
func process(push payload: UnsafePointer<UInt8>?, length: size_t) {
  // rust 没有创建自动释放池，不处理可能会有内存泄露
  autoreleasepool {
    guard let payload = payload else { return }
    let start = CACurrentMediaTime()
    let theData = Data(bytes: payload, count: length)
    do {
        let packet = try Packet(serializedData: theData, options: .discardUnknownFieldsOption)

        if packet.hasTaskID {
            // 事件流的封装实现
            RustManager.shared.eventStream(handle: packet)
        } else {
            // 推送处理
            RustManager.shared.push(handle: packet)
            let end = CACurrentMediaTime()
            SimpleRustClient.logger.info("""
                pushMessageProcessCallback \(packet.cmd)[\(packet.userID)][\(packet.userContainerID)] \
                executionTime: \(String(format: "%.4f", end - start))
                """)
        }
    } catch {
        SimpleRustClient.logger.error("pushMessageProcessCallback wrapp data failed.", error: error)
    }
  }
}

struct LarkInvokeResponseBridge {
    var code: UInt32
    var meta: Data?
    var payload: Data?
    init(_ response: LarkInvokeResponse) {
        code = response.status_code
        meta = response.meta.takeOwnedData()
        payload = response.payload.takeOwnedData()
    }
}

extension LarkBuffer {
    init(_ pointer: UnsafeBufferPointer<UInt8>) {
        self.init(data: pointer.baseAddress, length: pointer.count)
    }

    var isEmpty: Bool { return self.length == 0 || self.data == nil }

    /// copy to ensure a valid data
    @inlinable
    func toData() -> Data? {
        if let data = self.data {
            return Data(bytes: data, count: self.length)
        }
        return nil
    }
    func asBuffer() -> UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer(start: self.data, count: self.length)
    }
    /// convert to data representation, without copy buffer
    /// NOTE: return data not own the buffer, and only valid same as buffer.
    /// so it's only readable in same scope. async usage should use toData()
    /// you can use Data($0) to copy to a owned data
    func asData() -> Data? {
        if let data = self.data {
            return Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: data), count: self.length, deallocator: .none)
        }
        return nil
    }
    // 转移Buffer所有权，返回Swift管理的Data类型, 不会copy.
    func takeOwnedData() -> Data? {
        /// NOTE: rust的空vec会返回0x1的非法指针值，但length=0可以避免其被访问..
        /// 所以只要指针非空就认为是有效的值，可以序列化为空PB response..
        if let data = self.data {
            printVerbose("takeOwnedData: \(data)")
            return Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: data), count: self.length,
                        deallocator: .custom {
                        printVerbose("takeOwnedData:release: \($0)")
                        free_rust($0.bindMemory(to: UInt8.self, capacity: $1), UInt32($1)) })
        }
        return nil
    }
}

// DEBUG Only Switch
@inlinable
func printVerbose(_ items: Any...) {
    // print(items.map { String.init(reflecting: $0) }.joined(separator: ", "))
}

// swiftlint:enable missing_docs
