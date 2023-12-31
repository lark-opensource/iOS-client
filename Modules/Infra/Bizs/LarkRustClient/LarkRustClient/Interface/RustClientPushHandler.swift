//
//  RustClientPushHandler.swift
//  LarkRustClient
//
//  Created by Sylar on 2018/3/8.
//  Copyright © 2018年 linlin. All rights reserved.
//

import Foundation
import SwiftProtobuf
import RustPB
import RxSwift
import LKCommonsLogging

// swiftlint:disable missing_docs

public protocol RustPushHandler {
    /// check whether the push notification needs to be processed
    ///
    /// - Parameter payload: push notification data
    /// - Parameter packet: push notification packet
    func check(payLoad: Data, packet: Packet) -> Bool

    /// will be called when receive push notification of registered command
    ///
    /// - Parameter payload: push notification data
    func processMessage(payload: Data)
}

extension RustPushHandler {
    public func check(payLoad: Data, packet: Packet) -> Bool {
        return true
    }
}

public typealias RustPushHandlerFactory = () -> RustPushHandler

/// used by RustService.registerPushHandler
public protocol RustPushHandlerProvider {

    /// - Returns: [command: lazy load handler]
    func getPushHandlers() -> [Command: RustPushHandlerFactory]
}

// MARK: Typed Handler
public protocol ServerPushRegistable: AnyObject {
    static func register(on service: RustService, cmd: ServerCommand, factory: @escaping () throws -> Self) -> Disposable // swiftlint:disable:this all
}
public protocol RustPushRegistable: AnyObject {
    static func register(on service: RustService, cmd: Command, factory: @escaping () throws -> Self) -> Disposable
}

public protocol PushHandlerType: ServerPushRegistable, RustPushRegistable {
    /// Can be Data, T:Message, and Optional Wrapped in ServerPushPacket or RustPushPacket
    associatedtype PushType
    /// process data, throws error only log and be ignored
    func process(push: PushType) throws
}

extension PushHandlerType {
    @inlinable
    static func make(factory: @escaping () throws -> Self, store: inout Self?) -> Self? {
        // NOTE: 要求在统一队列上调用，没有做并行保护..
        if let store = store { return store }
        do {
            store = try factory()
        } catch {
            SimpleRustClient.logger.warn("Failed to create push handler", error: error)
        }
        return store
    }
    @inlinable
    func process(_ msg: PushType) {
        do {
            try process(push: msg)
        } catch {
            SimpleRustClient.logger.warn("process push \(PushType.self) error", error: error)
        }
    }
    /// 屏蔽非法泛型组合
    public static func register<R>(on service: RustService, cmd: Command, factory: @escaping () throws -> Self) -> Disposable where PushType == ServerPushPacket<R> {
        fatalError("unreachable code!!")
    }
    /// 屏蔽非法泛型组合
    public static func register<R>(on service: RustService, cmd: ServerCommand, factory: @escaping () throws -> Self) -> Disposable where PushType == RustPushPacket<R> {
        fatalError("unreachable code!!")
    }
}

// swiftlint:enable missing_docs
