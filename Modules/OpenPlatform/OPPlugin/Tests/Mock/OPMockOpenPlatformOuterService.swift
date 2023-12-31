//
//  OPMockOpenPlatformOuterService.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/20.
//

import Foundation
import Swinject
import LarkContainer
import LarkAssembler
import LarkOPInterface

final class OpenPlatformOuterMockAssembly: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Swinject.Container) {
        
        container.register(OpenPlatformOuterService.self) {_ in
            OPMockOpenPlatformOuterService()
        }.inObjectScope(.container)
    }
}

final class OpenPlatformOuterRestoreAssembly: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Swinject.Container) {
        
        container.register(OpenPlatformOuterService.self) {_ in
            OPMockOpenPlatformOuterService()
        }.inObjectScope(.container)
    }
}

final class OPMockOpenPlatformOuterService: OpenPlatformOuterService {
    
    func enterChat(chatId: String?, showBadge: Bool, window: UIWindow?) { }
    
    func enterProfile(userId: String?, window: UIWindow?) { }
    
    func enterBot(botId: String?, window: UIWindow?) { }
}
