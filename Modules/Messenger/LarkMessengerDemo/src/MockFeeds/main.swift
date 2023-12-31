//
//  main.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by bytedance on 2020/5/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import Swinject
import LarkAccount
import LarkDebug
import AppContainer
import RxSwift
import LarkAppConfig
import LarkSDK
import LarkMessenger
import LarkMessengerInterface
import LarkPerf
import LarkAppLinkSDK
import LarkBaseService
import LarkExtensionCommon
import LarkWebCache
import LarkQRCode
import LarkGuide
import LarkNavigation
import LarkPushTokenUploader
import LarkLeanMode
import LarkSnsShare
import LarkAccountInterface
import SuiteLogin
import LarkBanner
import LarkSettingsBundle
import BootManager
import LarkShareContainer
import LarkRustClientAssembly

class LarkMainAssembly: FlowLaunchTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        _ = Assembler(assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
    }

    private let assemblies: [Assembly] = [
        LarkBaseServiceAssembly(),
        LarkPushTokenUploaderAssembly(),
        AccountMockAssembly { _ in DemoAccountDependencyImpl() },
        AccountAssembly(),
        NavigationAssembly(),
        NavigationMockAssembly { r in DemoNavigationDependencyImpl(resolver: r) },
        // 这里主要是替换掉了FeedAPI.self和RustService.self注册的factories，用于本地模拟Feeds相关动作
        MockFeedsAssembly(),
        SDKMockAssembly { r in SDKDependencyImpl(resolver: r) },
        MessengerAssembly(),
        MessengerMockAssembly(),
        WebCacheAssembly(),
        AppLinkAssembly(),
        LeanModeMockAssembly { _ in DemoLeanModeDependencyImp() },
        LeanModeAssembly(),
        LarkSnsShareBaseAssembly(),
        LarkSnsShareAssembly(),
        LarkBannerAssembly(),
        SettingsBundleAssembly(),
        LarkShareContainerAssembly(),
        RustClientDependencyAssembly(),
        RustClientAssembly()
    ]
}

func larkMain() {
    ColdStartup.shared?.do(.main)
    AppStartupMonitor.shared.start(key: .startup)

    BootManager.register(LarkMainAssembly.self)
    BootManager.shared.dependency = BootManagerDependency()
    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

larkMain()
