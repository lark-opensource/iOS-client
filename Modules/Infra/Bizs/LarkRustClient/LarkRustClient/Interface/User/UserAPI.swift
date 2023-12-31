//
//  UserAPI.swift
//  LarkRustClient
//
//  Created by SolaWing on 2022/9/7.
//

import Foundation
import LarkContainer
import RxSwift
import RustPB
import ServerPB

// swiftlint:disable missing_docs line_length

public typealias UserPushHandler = _UserPushHandler & PushHandlerType

extension ServerPushHandlerRegistry {
    static public private(set) var serverUserPushHandlers: [(ServerCommand, RustServiceUserRegistable)] = []
    static public private(set) var serverBackgroundUserPushHandlers: [(ServerCommand, RustServiceUserRegistable)] = []
    /// Register a server push cmd into user handler
    ///
    /// only register user push message into the user space RustService.
    /// global push msg should be registered into global instance directly.
    /// register global push msg in a user space, may receive multiple times.
    ///
    /// - Parameters:
    ///   - cmd: server push cmd
    ///   - factory: lazy created handler
    public static func register<T: UserPushHandler>(serverPushCmd cmd: ServerCommand, factory: @escaping (UserResolver) throws -> T) {
        serverUserPushHandlers.append(makeRegistry(serverPushCmd: cmd, factory: factory))
    }
    public static func registerForBackground<T: UserPushHandler>(serverPushCmd cmd: ServerCommand, factory: @escaping (UserResolver) throws -> T) {
        serverBackgroundUserPushHandlers.append(makeRegistry(serverPushCmd: cmd, factory: factory))
    }
    static func makeRegistry<T: UserPushHandler>(serverPushCmd cmd: ServerCommand, factory: @escaping (UserResolver) throws -> T) -> (ServerCommand, RustServiceUserRegistable) {
        #if ALPHA || DEBUG
        precondition(Thread.isMainThread, "should occur on main thread!")
        precondition(!RustPushHandlerRegistry.frozen, "should call before loginFlow")
        #endif
        return (
            cmd, { service, getUserResolver in
                T.register(on: service, cmd: cmd, factory: {
                    let resolver = try getUserResolver({ T.compatibleMode })
                    return try factory(resolver)
                })
            })
    }
}

public enum RustPushHandlerRegistry {
    #if ALPHA || DEBUG
    static public var frozen = false
    #endif
    static public private(set) var rustUserPushHandlers: [(Command, RustServiceUserRegistable)] = []
    static public private(set) var rustBackgroundUserPushHandlers: [(Command, RustServiceUserRegistable)] = []
    /// Register a rust push cmd into user handler
    ///
    /// only register user push message into the user space RustService.
    /// global push msg should be registered into global instance directly.
    /// register global push msg in a user space, may receive multiple times.
    ///
    /// - Parameters:
    ///   - cmd: rust push cmd
    ///   - factory: lazy created handler
    public static func register<T: UserPushHandler>(pushCmd cmd: Command, factory: @escaping (UserResolver) throws -> T) {
        Self.rustUserPushHandlers.append(makeRegistry(pushCmd: cmd, factory: factory))
    }
    public static func registerForBackground<T: UserPushHandler>(pushCmd cmd: Command, factory: @escaping (UserResolver) throws -> T) {
        Self.rustBackgroundUserPushHandlers.append(makeRegistry(pushCmd: cmd, factory: factory))
    }
    static func makeRegistry<T: UserPushHandler>(pushCmd cmd: Command, factory: @escaping (UserResolver) throws -> T) -> (Command, RustServiceUserRegistable) {
        #if ALPHA || DEBUG
        precondition(Thread.isMainThread, "should occur on main thread!")
        precondition(!frozen, "should call before loginFlow")
        #endif
        return (
            cmd, { service, getUserResolver in
                T.register(on: service, cmd: cmd, factory: {
                    let resolver = try getUserResolver({ T.compatibleMode })
                    return try factory(resolver)
                })
            })
    }
}

open class _UserPushHandler: UserResolverWrapper { // swiftlint:disable:this type_name
    /// 覆盖可以指定是否对userResolver启用兼容模式, 比如可以用FG控制
    open class var compatibleMode: Bool { false }
    public let userResolver: UserResolver
    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }
}

/// UserPushHandler Type, provider a default init(resolver:) initializer
public typealias RustServiceUserRegistable = (
    RustService,
    @escaping ( () -> Bool ) throws -> UserResolver // (compatibleMode) -> UserResolver
) -> Disposable
