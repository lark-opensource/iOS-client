//
//  MockInterceptionRustClient.swift
//
//  Created by bytedance on 2020/5/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import RxSwift
import RustPB

///
/// 用于托管同任意相关的Commands，便于人工触发推送时机，模拟测试场景
/// 注意: 这块独立于原有的RustClient实现，被托管的Commands和Handlers的调用逻辑完全由使用者控制，不保证跟原RustClient行为一致，要自己模拟触发时机
///
public class MockInterceptionRustClient: RustClient {
    let commands: [ Basic_V1_Command ]

    /// - Parameters:
    ///   - commands: 需要托管的commands，会屏蔽掉RustSDK的相关消息，独立托管出来，自主模拟调用
    public init(configuration: RustClientConfiguration, commands: [ Basic_V1_Command ]) {
        self.commands = commands
        super.init(identifier: configuration.identifier, userID: configuration.userId)
        rustInit(configuration: { configuration })
    }

    ///
    /// 目前暂不支持Observable<Message>的类型，项目中仅有 .pushInitSettings在使用这种形式的调用，用到的可能性较低；未来如有需要，再补充
    ///
    override public func register<R>(pushCmd cmd: Command) -> Observable<R> where R: Message {
        if commands.contains(cmd) {
            fatalError("Oops... not supported Observables for intercepted commands.")
        }

        return super.register(pushCmd: cmd)
    }

    ///
    /// Override掉注册函数，指定Commands的Handlers会被注册到MockInterceptionManager里面，脱离原有的Rust体系，即Rust即使收到真实服务端数据，也不会触发
    ///
    override public func register(pushCmd cmd: Command, handler: @escaping (Data) -> Void) -> Disposable {
        // 如果包含需要被拦截的Commands，就转存到MockInterceptionManager里面，方便直接触发；同时屏蔽Rust的消息
        if commands.contains(cmd) {
            MockInterceptionManager.shared.registerCommand(cmd: cmd, handler: handler)

            return Disposables.create {
                // Disposable被销毁的时候，同时取消被拦截的注册
                MockInterceptionManager.shared.unregisterCommand(cmd: cmd)
            }
        }

        return super.register(pushCmd: cmd, handler: handler)
    }

    ///
    /// 取消所有注册的PushHandlers，被托管的也一并取消
    ///
    override public func unregisterPushHanlders() {
        MockInterceptionManager.shared.unregisterCommands()
        super.unregisterPushHanlders()
    }
}
