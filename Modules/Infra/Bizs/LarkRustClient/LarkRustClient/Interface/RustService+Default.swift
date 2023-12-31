//
//  RustService+Default.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/11/29.
//

import Foundation
import RxSwift
import RustPB
import SwiftProtobuf
import ServerPB

// swiftlint:disable missing_docs

/// RustService default implementation and helper wrapper
public extension RustService {

    // MARK: Synchronous

    /// return the R message directly. for those not need the response context
    func sync<R: Message>(_ request: RequestPacket) throws -> R {
        return try sync(request).result.get()
    }
    func sync<R: Message>(message: Message, parentID: String? = nil, allowOnMainThread: Bool = false) throws -> R {
        var req = RequestPacket(message: message)
        req.parentID = parentID
        req.allowOnMainThread = allowOnMainThread
        return try sync(req).result.get()
    }

    /// - parameter request: Reqeust base on SwiftProtobuf.Message
    /// - parameter transform: A function used to create a new type response
    ///
    /// - returns: Response with type inferred from defined return value
    /// - throws: `RCError`
    func sendSyncRequest(_ request: SwiftProtobuf.Message) throws {
        try self.sync(RequestPacket(message: request)).result.get()
    }
    func sendSyncRequest(_ request: SwiftProtobuf.Message, spanID: UInt64?) throws {
        try self.sync(RequestPacket(message: request, spanID: spanID)).result.get()
    }

    /// sync request and can send on main thread.
    /// NOTE: use this function is discourage
    func sendSyncRequest(_ request: SwiftProtobuf.Message, allowOnMainThread: Bool) throws {
        var req = RequestPacket(message: request); req.allowOnMainThread = allowOnMainThread
        try self.sync(req).result.get()
    }
    func sendSyncRequest(_ request: SwiftProtobuf.Message,
                         allowOnMainThread: Bool,
                         spanID: UInt64?) throws {
        var req = RequestPacket(message: request,
                                spanID: spanID)
        req.allowOnMainThread = allowOnMainThread
        try self.sync(req).result.get()
    }

    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) throws -> R {
        return try self.sync(RequestPacket(message: request)).result.get()
    }
    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                   spanID: UInt64?) throws -> R {
        return try self.sync(RequestPacket(message: request, spanID: spanID)).result.get()
    }

    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) throws -> ContextResponse<R> {
        let req = RequestPacket(message: request)
        let res: ResponsePacket<R> = self.sync(req)
        return ContextResponse(contextID: res.contextID, response: try res.result.get())
    }
    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                   spanID: UInt64?) throws -> ContextResponse<R> {
        let req = RequestPacket(message: request, spanID: spanID)
        let res: ResponsePacket<R> = self.sync(req)
        return ContextResponse(contextID: res.contextID, response: try res.result.get())
    }

    /// sync request and can send on main thread.
    /// NOTE: use this function is discourage
    func sendSyncRequest<R: SwiftProtobuf.Message>(
        _ request: SwiftProtobuf.Message,
        allowOnMainThread: Bool
    ) throws -> ContextResponse<R> {
        var req = RequestPacket(message: request)
        req.allowOnMainThread = allowOnMainThread
        return try ContextResponse(response: self.sync(req))
    }
    func sendSyncRequest<R: SwiftProtobuf.Message>(
        _ request: SwiftProtobuf.Message,
        allowOnMainThread: Bool,
        spanID: UInt64?) throws -> ContextResponse<R> {
        var req = RequestPacket(message: request, spanID: spanID)
        req.allowOnMainThread = allowOnMainThread
        return try ContextResponse(response: self.sync(req))
    }

    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) throws -> U {
        return try M.transform(self.sync(RequestPacket(message: request)).result.get(),
                               for: request,
                               by: transform)
    }
    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U,
        spanID: UInt64?
    ) throws -> U {
        return try M.transform(self.sync(RequestPacket(message: request, spanID: spanID)).result.get(),
                               for: request,
                               by: transform)
    }

    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) throws -> U {
        return try M.transform(ContextResponse(response: self.sync(RequestPacket(message: request))),
                               for: request,
                               by: transform)
    }
    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(ContextResponse<R>) throws -> U,
        spanID: UInt64?
    ) throws -> U {
        return try M.transform(ContextResponse(response: self.sync(RequestPacket(message: request,
                                                                                 spanID: spanID))),
                              for: request,
                              by: transform)
    }

    // MARK: Push handler
    @discardableResult
    func register(pushCmd cmd: Command, handler: @escaping (Data, Packet) -> Void) -> Disposable {
        register(pushCmd: cmd, handler: { (packet: RustPushPacket<Data>) in
            handler(packet.body, packet.packet)
        })
    }
    /// Register push hander
    ///
    /// - parameter factories: Handler factories array
    @discardableResult
    func registerPushHandler(factories: [Command: RustPushHandlerFactory]) -> Disposable {
        let disposable = CompositeDisposable()
        for (cmd, factory) in factories {
            var cache: RustPushHandler?
            let v = register(pushCmd: cmd) { (data, packet) in
                /// 这个缓存实现会要求回调是串行的.. 否则可能有并发问题(不过机率不大)
                let handler = cache ?? { cache = factory(); return cache ?? factory() }()
                if handler.check(payLoad: data, packet: packet) {
                    handler.processMessage(payload: data)
                }
            }
            disposable.insert(v)
        }
        return disposable
    }

    /// Register server push hander
    ///
    /// - parameter factories: Handler factories array
    @discardableResult
    func registerPushHandler(factories: [ServerCommand: RustPushHandlerFactory]) -> Disposable {
        let disposable = CompositeDisposable()
        for (cmd, factory) in factories {
            var cache: RustPushHandler?
            let v = register(serverPushCmd: cmd) { (data: Data) in
                /// 这个缓存实现会要求回调是串行的.. 否则可能有并发问题(不过机率不大)
                let handler = cache ?? { cache = factory(); return cache ?? factory() }()
                handler.processMessage(payload: data)
            }
            disposable.insert(v)
        }
        return disposable
    }

    func register<T: RustPushRegistable>(pushCmd cmd: Command, factory: @escaping () throws -> T) -> Disposable {
        T.register(on: self, cmd: cmd, factory: factory)
    }
    func register<T: ServerPushRegistable>(serverPushCmd cmd: ServerCommand, factory: @escaping () throws -> T) -> Disposable {
        T.register(on: self, cmd: cmd, factory: factory)
    }

    /**
     * 注册冷启动任务接口；
     * @param task 需调度的冷启动任务
     * @return 任务添加成功返回任务id，添加失败返回-1
     */
    func addScheduler<Context>(task: StageTask<Context>) { task.block(task.context) }
}
