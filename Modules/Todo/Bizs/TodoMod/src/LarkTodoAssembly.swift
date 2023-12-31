//
//  LarkTodoAssembly.swift
//  TodoMod
//
//  Created by wangwanxin on 2021/4/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkAssembler
import BootManager
import TodoInterface
import Todo
import LarkSetting
import EENavigator
import LarkContainer

#if MessengerMod
import LarkMessageCore
import LarkMessageBase
import LarkForward
import LarkOpenChat
import LarkFlag
import LarkOpenSetting
import LarkNavigation
#endif

final public class LarkTodoAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        // register dependency
        let user = container.inObjectScope(TodoUserScope.userScope)
        user.register(MessengerDependency.self) { r -> MessengerDependency in
            return MessengerDependencyImpl(resolver: r)
        }
        user.register(RouteDependency.self) { r -> RouteDependency in
            return RouteDependencyImpl(resolver: r)
        }
        user.register(DriveDependency.self) { r -> DriveDependency in
            return DriveDependencyImpl(resolver: r)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(TodoSetupTask.self)
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        TodoAssembly()
    }

    #if MessengerMod

    @_silgen_name("Lark.ChatCellFactory.Todo")
    static public func cellFactoryRegister() {
        MessageEngineSubFactoryRegistery.register(ChatCardComponentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinCardComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ChatCardComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(ChatCardComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(ChatCardComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ChatCardComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(ChatCardComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ChatCardComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ChatCardComponentFactory.self)
        PinMessageSubFactoryRegistery.register(PinCardComponentFactory.self)
    }

    @_silgen_name("Lark.LarkFlag_LarkFlagAssembly_regist.Todo")
    public static func todoFlagCellFactoryRegister() {
        FlagListMessageSubFactoryRegistery.register(PinCardComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(ChatCardComponentFactory.self)
    }

    @_silgen_name("Lark.LarkForward_LarkForwardMessageAssembly_regist.Todo")
    public static func providerRegister() {
        ForwardAlertFactory.register(type: ShareTodoAlertProvider.self)
    }

    @_silgen_name("Lark.OpenChat.Todo")
    static public func openChatRegister() {
        ChatTabModule.register(ChatTabTaskModule.self)
    }
    
    @_silgen_name("Lark.OpenSetting.TodoMineSetting")
    static public func registMineSetting() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.todoEntry.moduleKey, provider: { userResolver in
            guard let navigationService = try? userResolver.resolve(assert: NavigationService.self) else { return nil }
            let hasTodo = navigationService.checkInTabs(for: .todo)
            guard hasTodo else { return nil }
            return GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Todo_Task_Tasks,
                                                onClickBlock: { (userResolver, vc) in
                userResolver.navigator.push(body: TodoSettingBody(), from: vc)
            })
        })
    }

    #endif
}
