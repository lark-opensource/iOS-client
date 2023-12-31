//
//  AppStateSDK+Strategy.swift
//  LarkAppStateSDK
//
//  Created by  bytedance on 2020/9/27.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkMessageCore
import LarkMessengerInterface
import LarkRustClient
import RustPB
import RxSwift
import Swinject
import EEMicroAppSDK
import LarkContainer

/// from需求「应用不可用的引导优化」
extension AppStateSDK {

    /// 注册小程序引擎生命周期监听
    func registerMicroAppLifeCycleV2(resolver: UserResolver) {
        let microAppService = try? resolver.resolve(assert: MicroAppService.self)
        guard let microAppService = microAppService else {
            Self.logger.error("AppStateSDK: microAppService is nil")
            return
        }
        microAppService.addLifeCycleListener(listener: microAppLifeCycleListenerV2)
    }
}
