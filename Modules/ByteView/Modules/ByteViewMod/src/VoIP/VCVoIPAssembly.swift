//
//  VCVoIPAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//
import Foundation
import Swinject
import LarkVoIP
import EENavigator
import LarkAccountInterface
import ByteView
import BootManager
import LarkAssembler
import AppContainer
#if LarkLiveMod
import LarkLiveInterface
#endif
#if MessengerMod
import LarkSDKInterface
#endif
#if LarkMod
import LarkWaterMark
#endif
import LKCommonsLogging

final class VCVoIPAssembly: LarkAssemblyInterface {
    private static let logger = Logger.log(VCVoIPAssembly.self, category: "LarkVoIP.Assembly")

    func registContainer(container: Container) {
        let user = container.inObjectScope(.vcUser)
        user.register(VoIPWaterMarkService.self) { r in
            #if LarkMod
            if let service = try? r.resolve(assert: WaterMarkService.self) {
                return VoIPWaterMarkServiceImpl(waterMarkProxy: service)
            } else {
                Self.logger.error("WaterMarkService not found")
                return DefaultVoIPWaterMarkService()
            }
            #else
            return DefaultVoIPWaterMarkService()
            #endif
        }

        user.register(VoIPLiveService.self) { r in
            #if LarkLiveMod
            return VoIPLiveServiceImpl(liveServiceProxy: try r.resolve(assert: LarkLiveService.self))
            #else
            return DefaultVoIPLiveService()
            #endif
        }

        user.register(WindowDependency.self) { _ in
            #if LarkMod
            return VoIPWindowDependency()
            #else
            return DefaultVoIPWindowDependency()
            #endif
        }

        user.register(VoIPConfigService.self) { r in
            #if MessengerMod
            return MessengerVoIPConfigService(setting: try? r.resolve(assert: UserGeneralSettings.self))
            #else
            return DefaultVoIPConfigService()
            #endif
        }

        user.register(VoIPChatService.self) { r in
            #if MessengerMod
            return MessengerVoIPChatService(chat: try? r.resolve(assert: ChatAPI.self), chatter: try? r.resolve(assert: ChatterAPI.self))
            #else
            return DefaultVoIPChatService()
            #endif
        }

        user.register(VoipTerminationMonitorType.self) {
            VoIPTerminationMonitorImpl(service: try $0.resolve(assert: TerminationMonitor.self))
        }
    }

    func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(CallVoIPBody.self).factory(CallVoIPHandler.init(resolver:))
        Navigator.shared.registerRoute.type(PullVoIPCallBody.self).factory(PullVoIPCallHandler.init(resolver:))
    }

    func registBootLoader(container: Container) {
        (VoIPApplicationDelegate.self, DelegateLevel.default)
    }

    func registPassportDelegate(container: Container) {
        (PassportDelegateFactory { VoIPPassportDelegate.shared }, PassportDelegatePriority.middle)
    }

    func registLaunch(container: Container) {
        NewBootManager.register(VoIPSetupBootTask.self)
    }

    func getSubAssemblies() -> [LarkAssemblyInterface]? {
        VoIPAssembly()
    }
}
