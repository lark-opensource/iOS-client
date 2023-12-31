//
//  LarkMailAssembly.swift
//  Lark
//
//  Created by NewPan on 2021/8/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkAssembler
import LarkContainer
import LarkSetting
import LarkOpenSetting
import LarkNavigation
import MailSDK
import LarkOpenFeed

#if MessengerMod
import LarkForward
#endif

public final class LarkMailAssembly: LarkAssemblyInterface {

    public init() { }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(MailUserScope.userScope)
#if MessengerMod
        user.register(LarkMailShareInterface.self) { r -> LarkMailShareInterface in
            return LarkMailShareInterfaceImpl(resolver: r)
        }
#endif
      
    }
    
    @_silgen_name("Lark.OpenSetting.LarkMailAssembly")
    public static func pageFactoryRegister() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.mailEntry.moduleKey, provider: { userResolver in
            guard let navigationService = try? userResolver.resolve(assert: NavigationService.self) else { return nil }
            guard navigationService.checkInTabs(for: .mail) else { return nil }
            return GeneralBlockModule(
                userResolver: userResolver,
                title: MailSettingManagerInterface.mailSettingTitle(), onClickBlock: { (userResolver, vc) in
                let dependency = try? userResolver.resolve(assert: LarkMailService.self)
                dependency?.navigator.push(body: EmailSettingBody(), from: vc)
            })
        })
    }
    
    @_silgen_name("Lark.Feed.FeedCard.Mail")
    static public func registOpenFeed() {
        FeedCardModuleManager.register(moduleType: MailFeedCardModule.self)
        FeedActionFactoryManager.register(factory: { MailFeedActionJumpFactory() })
    }
}

enum MailUserScope {
    static let enableUserScope: Bool = {
        let flag = FeatureGatingManager.shared.featureGatingValue(with: "larkmail.cli.mail.ios_user_container")
        return flag
    }()

    static var userScopeCompatibleMode: Bool { !enableUserScope }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。旧的注册没有指定 scope 的默认为 .graph
    static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
