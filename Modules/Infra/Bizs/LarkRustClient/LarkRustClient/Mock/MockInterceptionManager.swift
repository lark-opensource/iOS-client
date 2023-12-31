//
// Created by bytedance on 2020/5/17.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import RustPB
import EEAtomic

///
/// 用于模拟相关的推送消息交互
///
public class MockInterceptionManager {
    ///
    /// 单例，供mock场景调用触发推送消息
    ///
    public static let shared = MockInterceptionManager()

    // 添加和移除commands时加锁保护
    private let lock = UnfairLockCell()

    ///
    /// Command -> Handler
    /// 只以最后注册的 command 要执行的 handler 为准，向其post所模拟的messages
    /// 备注：因为业务代码中RustClient非单例，所以可能出现不同client实例注册不同commands的情况，所以发布mock message时只考虑command
    ///
    lazy private var commandHandlerMap = { [ Basic_V1_Command: (Data) -> Void ]() }()

    init() { }

    deinit { lock.deallocate() }

    ///
    /// Internal func, 便于单测校验
    ///
    func getRegisteredHandlersCount() -> Int {
        return commandHandlerMap.count
    }

    func registerCommand(cmd: Basic_V1_Command, handler: @escaping (Data) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        // 目前Mock不支持同一个command同时对应多个handlers，如果触发就fatal掉...
        if commandHandlerMap[cmd] != nil {
            fatalError("""
                    Only support 1:1 mocking now... unregister the previous one
                    or redesign your usage with this mocking class.
                    """)
        }

        commandHandlerMap[cmd] = handler
    }

    func unregisterCommands() {
        lock.lock()
        defer { lock.unlock() }
        commandHandlerMap.removeAll()
    }

    func unregisterCommand(cmd: Basic_V1_Command) {
        lock.lock()
        defer { lock.unlock() }
        _ = commandHandlerMap.removeValue(forKey: cmd)
    }

    ///
    /// 即时发送消息给已注册的handlers，但是用锁限制串行调用handler
    ///
    public func postMessage(command: Basic_V1_Command, message: SwiftProtobuf.Message) {
        lock.lock()
        defer { lock.unlock() }

        guard let handler = commandHandlerMap[command] else {
            // 未找到符合条件的handler，直接返回
            return
        }

        do {
            handler(try message.serializedData())
        } catch {
            fatalError("Invalid mock message data.")
        }
    }
}
