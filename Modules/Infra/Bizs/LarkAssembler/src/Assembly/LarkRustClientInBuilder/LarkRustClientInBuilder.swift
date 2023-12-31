//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import LarkRustClient

// swiftlint:disable missing_docs

@resultBuilder
public struct PushHandlerFactory {
    public static func buildBlock(_ components: [Command: RustPushHandlerFactory]...) {
        components.forEach { compent in
            PushHandlerRegistry.shared.register(pushHandlers: compent)
        }
    }
}

@resultBuilder
public struct ServerPushHandlerFactory {
    public static func buildBlock(_ components: [ServerCommand: RustPushHandlerFactory]...) {
        components.forEach { compent in
            ServerPushHandlerRegistry.shared.register(pushHandlers: compent)
        }
    }
}

import LarkContainer

@resultBuilder
public struct UserRustPushHandlerRegistryBuilder {
    let action: () -> Void
    public static func buildExpression<T: UserPushHandler>(
        _ expression: (Command, (UserResolver) throws -> T)
    ) -> Self {
        return .init {
            RustPushHandlerRegistry.register(pushCmd: expression.0, factory: expression.1)
        }
    }
    public static func buildBlock(_ components: Self...) {
        components.forEach { $0.action() }
    }
}

@resultBuilder
public struct UserServerPushHandlerRegistryBuilder {
    let action: () -> Void
    public static func buildExpression<T: UserPushHandler>(
        _ expression: (ServerCommand, (UserResolver) throws -> T)
    ) -> Self {
        return .init {
            ServerPushHandlerRegistry.register(serverPushCmd: expression.0, factory: expression.1)
        }
    }
    public static func buildBlock(_ components: Self...) {
        components.forEach { $0.action() }
    }
}

@resultBuilder
public struct UserRustBgPushHandlerRegistryBuilder {
    let action: () -> Void
    public static func buildExpression<T: UserPushHandler>(
        _ expression: (Command, (UserResolver) throws -> T)
    ) -> Self {
        return .init {
            RustPushHandlerRegistry.registerForBackground(pushCmd: expression.0, factory: expression.1)
        }
    }
    public static func buildBlock(_ components: Self...) {
        components.forEach { $0.action() }
    }
}

@resultBuilder
public struct UserServerBgPushHandlerRegistryBuilder {
    let action: () -> Void
    public static func buildExpression<T: UserPushHandler>(
        _ expression: (ServerCommand, (UserResolver) throws -> T)
    ) -> Self {
        return .init {
            ServerPushHandlerRegistry.registerForBackground(serverPushCmd: expression.0, factory: expression.1)
        }
    }
    public static func buildBlock(_ components: Self...) {
        components.forEach { $0.action() }
    }
}
