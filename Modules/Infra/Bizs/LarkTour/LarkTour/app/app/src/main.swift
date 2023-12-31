//
//  AppDelegate.swift
//  LarkDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
// import LarkAccount
import Swinject
import LarkAccountInterface
import Logger
import LarkContainer
import LarkAppConfig
import LarkNavigation
import LarkLocalizations
import LarkLeanMode
import LarkTour
import LarkTourInterface
import RxSwift
// import LarkAppLinkSDK
import BootManager

func larkMain() {
    LanguageManager.supportLanguages = [.en_US, .zh_CN, .ja_JP]

    BootManager.preloadBootConfig()
    BootLoader.shared.registerApplication(
        delegate: VideoEngineApplicationDelegate.self,
        level: .default)
    BootLoader.shared.registerApplication(
        delegate: DemoApplicationDelegate.self,
        level: .default)
    _ = Assembler([
//        AccountAssembly(),
        NavigationAssembly(),
        NavigationMockAssembly { _ in DemoAppNavigationMockDependency() },
        LeanModeAssembly(),
        LeanModeMockAssembly(),
//        AppLinkAssembly(),
        TourAssembly(),
        TourMockAssembly(),
        DemoAssembly()
    ], container: BootLoader.container)
    BootLoader.assemblyLoaded = true
    BootManager.shared.dependency = BootManagerDependency()
    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

larkMain()
