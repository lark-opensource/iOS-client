//
//  LKContentFixAssembly.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/8.
//

import Foundation
import Swinject
import BootManager
import LarkContainer
import LarkRustClient
import LarkAssembler

public final class LKContentFixAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        // 注册启动任务
        NewBootManager.register(LKContentFixTask.self)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushSettings, LKContentFixPushHandler.init(resolver:))
    }    
}
