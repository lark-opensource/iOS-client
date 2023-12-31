//
//  MinutesMessengerAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import Minutes
import MinutesNavigator
import EENavigator
import LarkAssembler
import LarkContainer
import LarkAppLinkSDK
#if MessengerMod
import LarkForward
#endif

public final class MinutesMessengerAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
       
    }

    public func registRouter(container: Container) {
    #if MessengerMod
        Navigator.shared.registerRoute.type(ShareMinutesBody.self).factory(cache: true, ShareMinutesHandler.init(resolver:))
    #endif
    }

    public func registLarkAppLink(container: Container) {
    #if MessengerMod
        LarkAppLinkSDK.registerHandler(
            path: ShareMinutesApplinkHandler.pattern,
            handler: ShareMinutesApplinkHandler.handle(applink:)
        )
    #endif
    }

    /// 用来注册AlertProvider的类型
    @_silgen_name("Lark.LarkForward_LarkForwardMessageAssembly_regist.MinutesMessengerAssembly")
    public static func providerRegister() {
    #if MessengerMod
        ForwardAlertFactory.register(type: ShareMinutesAlertProvider.self)
    #endif
    }
}
