//
//  RustService.swift
//  LarkRustClient
//
//  Created by Sylar on 2018/3/25.
//  Copyright © 2018年 linlin. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import SwiftProtobuf
import ServerPB

// swiftlint:disable missing_docs line_length
public protocol LarkServerPushHandlerRegistry {
    /// Thread safe not guaranteed
    func register(pushHandlers: [ServerCommand: RustPushHandlerFactory])
    /// Thread safe not guaranteed
    func getPushHandlers() -> [[ServerCommand: RustPushHandlerFactory]]
}

/// Rust接口Stage定义
public enum Stage {
    case startup // 冷启动立即执行
    case firstScreen // 冷启动首屏后执行
    case oneMinuteAfterFirstScreen // 冷启动首屏1分钟后执行
}

/// rust任务结构体，业务侧可以指定运行时机
public struct StageTask<Context> {
    public let stage: Stage
    public let context: Context
    public let block: (Context) -> Void
}

public enum ServerPushHandlerRegistry {
    /// App切换时自动注册的push handler
    /// NOTE: 需要在账户登录前的流程里一次性注册
    @available(*, deprecated, message: "should migrate to UserSpace API, see UserAPI.swift")
    public static var shared: LarkServerPushHandlerRegistry = LarkServerPushHandlerRegistryImpl()
}

final class LarkServerPushHandlerRegistryImpl: LarkServerPushHandlerRegistry {
    fileprivate var pushHandlers: [[ServerCommand: RustPushHandlerFactory]] = []

    func register(pushHandlers: [ServerCommand: RustPushHandlerFactory]) {
        self.pushHandlers.append(pushHandlers)
    }

    func getPushHandlers() -> [[ServerCommand: RustPushHandlerFactory]] {
        return pushHandlers
    }
}

public protocol LarkRustPushHandlerRegistry {
    /// Thread safe not guaranteed
    func register(pushHandlers: [Command: RustPushHandlerFactory])
    /// Thread safe not guaranteed
    func getPushHandlers() -> [[Command: RustPushHandlerFactory]]
}

public enum PushHandlerRegistry {
    /// App切换时自动注册的push handler
    /// NOTE: 需要在账户登录前的流程里一次性注册
    @available(*, deprecated, message: "should migrate to UserSpace API, see UserAPI.swift")
    public static var shared: LarkRustPushHandlerRegistry = LarkRustPushHandlerRegistryImpl()
}

final class LarkRustPushHandlerRegistryImpl: LarkRustPushHandlerRegistry {
    fileprivate var pushHandlers: [[Command: RustPushHandlerFactory]] = []

    func register(pushHandlers: [Command: RustPushHandlerFactory]) {
        self.pushHandlers.append(pushHandlers)
    }

    func getPushHandlers() -> [[Command: RustPushHandlerFactory]] {
        return pushHandlers
    }
}

/// deprecated, use Response instead
public struct ContextResponse<R> {
    public let contextID: String
    public let response: R

    // need to define for public init. (default internal)
    public init(contextID: String, response: R) {
        self.contextID = contextID
        self.response = response
    }
    init(response: ResponsePacket<R>) throws {
        self.response = try response.result.get()
        self.contextID = response.contextID
    }
}

/// deprecated, use Response instead
public struct EventStreamContextResponse<R> {
    public var contextID: String
    public var response: Result<R, Error>
    public init(contextID: String, response: Result<R, Error>) {
        self.contextID = contextID
        self.response = response
    }
    init(response: ResponsePacket<R>) {
        self.response = response.result
        self.contextID = response.contextID
    }
}

public typealias SerialToken = UInt64
/// message request params
public struct RequestPacket {
    /// unknownCommand means try get command from Message name
    public var command: Command = .unknownCommand
    /// 服务端透传接口使用,对应服务端command值,避免与rust pb request混用
    public var serCommand: ServerPB_Improto_Command?
    /// the request message
    public var message: Message

    // MARK: 以下是context相关可选参数

    /// parent contextID, use to trace some request
    public var parentID: String?
    /// callback when contextID is generated
    public var contextIdGenerationCallback: (String) -> Void = { _ in }
    public var bizConfig: Basic_V1_RequestPacket.BizConfig?
    /// https://bytedance.feishu.cn/docs/doccnXUY2u1HuX3SZkT5YbCngWc#
    /// rust max_age, set > 0 to use cache. 绝对时间 ms 缓存有效时间
    public var cacheAge: Int = 0
    /// if allow sync request in main thread
    public var allowOnMainThread: Bool = false
    /// if the request barrier other message request
    public var barrier: Bool = false
    /// 相同的serialToken，会保证异步发送的顺序
    public var serialToken: SerialToken = 0
    /// 异步发送消息，保证接收顺序的最大延迟
    /// NOTE: 临时处理手段，不要真的依赖延时来保证顺序
    public var serialDelay: TimeInterval = 0
    /// 获取一个唯一的token
    public static func nextSerialToken() -> SerialToken {
        // reuse a number generator.
        UInt64(bitPattern: RustManager.shared.nextRequestID())
    }
    /// 用于接入OpenTracing，需要传递给Rust的spanID（可空）
    public var spanID: UInt64?
    public var collectTrace: Bool?
    public var mailAccountId: String?
    public var enableStartUpControl: Bool = false

    /// 用于限定该请求在RustSDK侧的优先级，缺省为firstScreen
    /// https://bytedance.feishu.cn/wiki/wikcn8cnj0V87oSOZTDkplHCUWh
    public var stage: Stage = .firstScreen

    // TODO: 加上MessageRequest的限制，但是会打破二进制兼容性...,
    // 另外多一套泛型的限制API会多很多接口.., 增加维护成本..
    // 而以前的Message还要保留着（serverPB需要，应该没有配置..）
    // 另外直接使用MessageRequest的泛型方法不行，会报歧义。这里怎么不选匹配度更高的实现了？
    public init(message: Message) {
        // not use the optional params, which will break api compatiblility when change
        self.message = message
    }

    public init(message: Message, mailAccountId: String?) {
        self.message = message
        self.mailAccountId = mailAccountId
    }

    public init(message: Message, spanID: UInt64?, collectTrace: Bool? = false) {
        self.message = message
        self.spanID = spanID
        self.collectTrace = collectTrace
    }
}

/// 使用已经序列化好的PB message和rust交互, 用于js等需要透传数据的场景
public struct RawRequestPacket {
    public var command: Command = .unknownCommand
    public var serCommand: ServerPB_Improto_Command?
    public var message: Data
    public var parentID: String?
    public var cacheAge: Int = 0
    public var serialToken: SerialToken = 0
    public var spanID: UInt64?
    public var collectTrace: Bool?
    public var mailAccountId: String?
    public var enableStartUpControl: Bool = false
    /// callback when contextID is generated
    public var contextIdGenerationCallback: (String) -> Void = { _ in }
    public init(command: Command, message: Data) {
        self.command = command
        self.message = message
    }
    public init(serCommand: ServerPB_Improto_Command, message: Data) {
        self.serCommand = serCommand
        self.message = message
    }
}

/// message response and context
public struct ResponsePacket<R> {
    public var contextID: String
    public var result: Result<R, Error>
    public init(
        contextID: String,
        result: Result<R, RCError>
    ) {
        self.contextID = contextID
        self.result = result.mapError { $0 }
    }
}

/// push的回调结构体
public struct RustPushPacket<MSG> {
    public var cmd: Command
    public var contextID: String
    public var packet: Packet
    public var payload: Data { packet.payload }
    public var body: MSG
    public func map<R>(_ mapper: (Self) throws -> R) rethrows -> RustPushPacket<R> {
        let body = try mapper(self)
        return RustPushPacket<R>(
            cmd: cmd, contextID: contextID, packet: packet, body: body
        )
    }
}

/// server push的回调环境
public struct ServerPushPacket<MSG> {
    public var cmd: ServerCommand
    public var contextID: String
    public var packet: ServerPacket
    public var payload: Data { packet.payload }
    public var body: MSG
    public func map<R>(_ mapper: (Self) throws -> R) rethrows -> ServerPushPacket<R> {
        let body = try mapper(self)
        return ServerPushPacket<R>(
            cmd: cmd, contextID: contextID, packet: packet, body: body
        )
    }
}

/// NOTE: 需要区分使用用户或者全局对应的实例。
/// Resolver.resolve(RustService.self) 对应的是用户生命的实例
/// Resolver.resolve(GlobalRustService.self) 对应的是全局实例(依赖rust初始化)
/// 另外GlobalRustService.shared也可以用于全局实例(不依赖rust初始化)
///
/// 大部分情况下业务方本身都是用户生命周期的，所以使用
/// Resolver.resolve(RustService.self)
/// 就可以了。全局单例才需要使用对应的全局实例
public protocol RustService {
    // MARK: Core API

    /// optional bind with a user. no user means global instance
    var userID: String? { get }

    /// 同步调用接口
    @discardableResult
    func sync(_ request: RequestPacket) -> ResponsePacket<Void>
    func sync<R: Message>(_ request: RequestPacket) -> ResponsePacket<R>

    /// 异步调用接口，需要保证有一次回调.
    /// NOTE: 异步回调是并发的，不保证回调线程和顺序.
    func async(_ request: RequestPacket, callback: @escaping (ResponsePacket<Void>) -> Void)
    func async<R: Message>(_ request: RequestPacket, callback: @escaping (ResponsePacket<R>) -> Void)
    func async(_ request: RawRequestPacket, callback: @escaping (ResponsePacket<Data>) -> Void)

    /// 事件流接口, server端可多次回调
    ///
    /// PS: event normally happen on a service queue. since it's a concurrency between dispose and deal event, dispose
    /// will not cancel a on-going event immediately. but if dispose and dispatch event on same queue, will guarantee
    /// no more event after dispose.
    ///
    /// - Parameters:
    ///   - event: (Result<Message, Error>?, isFinish), result may be nil when finish
    func eventStream<R: Message>(
        _ request: RequestPacket, event handler: @escaping (ResponsePacket<R>?, _ finish: Bool) -> Void
    ) -> Disposable

    /// Register push hander
    ///
    /// NOTE: if dispose not on the same queue of handler, will not cancel push immediately.
    ///
    /// - Parameter cmd: the push cmd wait to observe
    /// - Parameter onCancel: called when RustService disposed and terminate push
    /// - Returns: a Disposable which can use to cancel push.
    @discardableResult
    func register(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (RustPushPacket<Data>) -> Void) -> Disposable
    @discardableResult
    func register<R: Message>(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (RustPushPacket<R>) -> Void) -> Disposable
    @discardableResult
    func register(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (Data) -> Void) -> Disposable
    @discardableResult
    func register<R: Message>(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (R) -> Void) -> Disposable

    /// Register server push hander
    /// register a server push handler for specified cmd
    ///
    /// NOTE: if dispose not on the same queue of handler, will not cancel push immediately.
    ///
    /// - Parameter serverPushCmd: the cmd wait to observe
    /// - Parameter onCancel: called when RustService disposed and terminate push
    /// - Returns: a Disposable which can use to cancel push.
    @discardableResult
    func register(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (ServerPushPacket<Data>) -> Void) -> Disposable
    @discardableResult
    func register<R: Message>(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (ServerPushPacket<R>) -> Void) -> Disposable
    @discardableResult
    func register(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (Data) -> Void) -> Disposable
    @discardableResult
    func register<R: Message>(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (R) -> Void) -> Disposable

    /// after dispose, the rust service is unusable, and all send will report error
    func dispose()

    /// a async barrier action, which will block all send and callback.
    /// NOTE:
    /// - Parameters:
    ///   - allowRequest: other request allow to send when in barrier
    ///   - enter: callback when enter barrier. you must call leave once, or the block will wait forever
    func barrier(
        allowRequest: @escaping (RequestPacket) -> Bool,
        enter: @escaping (_ leave: @escaping () -> Void) -> Void
    )
    /// wait until initialize finish
    func wait(callback: @escaping () -> Void)

    // MARK: optional method
    func sendAsyncRequest(_ request: SwiftProtobuf.Message) -> Observable<Void>
    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<R>
    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) -> Observable<U>
    /// Asynchronous Event Stream
    ///
    /// PS1: the middle error also finish the event stream, as RxSwift doesn't support middle error directly
    /// if need to deal middle error, use the EventStreamContextResponse
    ///
    /// PS2: event normally happen on a service queue. since it's a concurrency between dispose and deal event, dispose
    /// will not cancel a on-going event immediately. but if dispose and dispatch event on same queue, will guarantee
    /// no more event after dispose.
    ///
    /// - Parameters:
    ///   - request: request base on SwiftProtobuf.Message
    /// - Returns: A observable event stream. may send 0-N response.
    /// - throws: RCError
    func eventStream<R: SwiftProtobuf.Message>(
        request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?
    ) -> Observable<R>
    func eventStream<R: SwiftProtobuf.Message>(
        request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?, spanID: UInt64?
    ) -> Observable<R>

    /// Asynchronous Event Stream
    ///
    /// this one differ from privous, as the EventStreamContextResponse provide more request and response context infos.
    ///
    /// NOTE: since error is encapsulated into response, this eventStream is never throw a Observable Error.
    func eventStream<R: SwiftProtobuf.Message>(
        request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?
    ) -> Observable<EventStreamContextResponse<R>>
    func eventStream<R: SwiftProtobuf.Message>(
        request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?, spanID: UInt64?
    ) -> Observable<EventStreamContextResponse<R>>

    /**
     * 注册冷启动任务接口；
     * @param task 需调度的冷启动任务
     * @return 任务添加成功返回任务id，添加失败返回-1
     */
    func addScheduler<Context>(task: StageTask<Context>)
}

/// Global的实例不允许收发用户消息, 先占一个类型位，以后替换接口进行限制..
public protocol GlobalRustService: RustService {}

/// 一个独立的命名空间，方便调用一些Rust相关的简单FFI接口封装
public enum Rust {}
