//
//  AccountAssemblyTask.swift
//  LarkAccount
//
//  Created by sniperj on 2021/5/28.
//

import Foundation
import BootManager
import LarkDebugExtensionPoint
import LarkAccountInterface
import AppContainer
import LarkSettingsBundle
import Swinject
import LKCommonsLogging
import LarkSetting

/// 子线程初始化登录依赖的Service
class AccountAssemblyTask: FlowBootTask, Identifiable { // user:checked (boottask)
    
    static var identify = "AccountAssemblyTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        
        PassportDebugEntrance().setup()
    
        User.validateUserID = {
            return FeatureGatingManager.shared.featureGatingValue(with: "ios.account.validate_user_id")
        }
        
        let container = BootLoader.container

        #if LarkAccount_RUST
        BaseSessionManager.httpUrlProtocols = [ApiRustHTTPURLProtocol.self]
        RustPluginAssembly().assemblePushHandler(container: container)
        assembleRegisterRustDynamicDomain()
        #endif
        assembleRegisterNativeDynamicDomain()

        assembleResetWork(container: container)

        // FeatureSwitch实现
        PassportConf.shared.featureSwitch = RustFeatureSwitch()

        // AppConfigService 实现
        PassportConf.shared.appConfig = AppConfigImp()

        #if LarkAccount_APPSFLYERFRAMEWORK
        DispatchQueue.global().async {
            PassportConf.shared.appsFlyerUID = AppsFlyerTracker.shared().getAppsFlyerUID()
        }
        #endif

        //logger 初始化
        Logger.setupPassportLog { (type, category) -> Log in
            return Logger.log(type, category: "Passport." + category)
        }
    }

    // register dynamic domain
    private func assembleRegisterRustDynamicDomain() {
        DomainProviderRegistry.register(value: RustDynamicDomainProvider(), priority: .medium)
        URLProviderRegistry.register(value: RustDynamicURLProvider(), priority: .medium)
        URLProviderRegistry.register(value: RustStaticURLProvider(), priority: .low)
    }

    private func assembleRegisterNativeDynamicDomain() {
        DomainProviderRegistry.register(value: NativeStaticDomainProvider(), priority: .lowest)
        URLProviderRegistry.register(value: NativeInjectURLProvider(), priority: .high)
        URLProviderRegistry.register(value: NativeStaticURLProvider(), priority: .lowest)
    }
    
    private func assembleResetWork(container: Container) {
        ResetTaskManager.register { (complete) in
            DispatchQueue.main.async {
                // AccountService need be resolved on main
                do {
                    let launcher = try container.resolve(assert: Launcher.self)
                    if !launcher.isLogin {
                        let loginService = try container.resolve(assert: V3LoginService.self)
                        loginService.reset()
                    }
                    complete()
                } catch {
                    #if ALPHA || DEBUG
                    fatalError("resolve launcher error.")
                    #else
                    assertionFailure("resolve launcher error.")
                    #endif
                }
            }
        }
    }
}
