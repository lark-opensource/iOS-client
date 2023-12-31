//
//  FeedbackAssembly.swift
//  Lark
//
//  Created by bytedance on 2021/3/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Swinject
import BootManager
import LarkAccountInterface
import AppContainer
import LKCommonsLogging
import RxSwift
import LarkAssembler

public class FeedbackAssembly: Assembly, LarkAssemblyInterface {

    public init() {}

    public func assemble(container: Container) {
        registLaunch(container: container)
        registContainer(container: container)
        registLauncherDelegate(container: container)
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(NewInitFeedbackTask.self)
    }

    public func registContainer(container: Container) {
        container.register(FeedbackLauncherDelegateService.self) { _ in
            return FeedbackDelegate()
        }
    }

    public func registLauncherDelegate(container: Container) {
        let resolver = container
        LauncherDelegateRegistery.register(factory: LauncherDelegateFactory(delegateProvider: {
            resolver.resolve(FeedbackLauncherDelegateService.self)!
        }), priority: .low)
    }
}

// 注册监听账号登录、登出
private protocol FeedbackLauncherDelegateService: LauncherDelegate {}

private class FeedbackDelegate: FeedbackLauncherDelegateService, FeedbackAccessibility {

    static let logger = Logger.log(FeedbackDelegate.self, category: "BDFeedback")
    public var name: String = "BDFeedback+AccountService"

    public func afterLoginSucceded(_ context: LauncherContext) {
        verifyFeedbackAccessibility()
    }

    public func beforeSwitchAccout() {
        clearFeedbackState(with: "beforeSwitchAccout")
    }

    func beforeLogout() {
        clearFeedbackState(with: "beforeLogout")
    }
}

// 注册低优先级启动事件，初始化 BDFeedBack 鉴权
private class InitFeedbackTask: FlowLaunchTask, Identifiable, FeedbackAccessibility {
    static let logger = Logger.log(InitFeedbackTask.self, category: "BDFeedback")

    static var identify: TaskIdentify = "InitFeedbackTask"

    override var scheduler: Scheduler { return .main }

    override func execute(_ context: BootContext) {
        verifyFeedbackAccessibility()
    }
}

private class NewInitFeedbackTask: FlowBootTask, Identifiable, FeedbackAccessibility {
    static let logger = Logger.log(InitFeedbackTask.self, category: "BDFeedback")

    static var identify: TaskIdentify = "InitFeedbackTask"

    override var scheduler: Scheduler { return .main }

    override func execute(_ context: BootContext) {
        verifyFeedbackAccessibility()
    }
}
