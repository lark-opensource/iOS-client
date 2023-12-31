//
//  main.swift
//  LarkSettingsBundleDev
//
//  Created by Miaoqi Wang on 2020/3/29.
//

import Foundation
import AppContainer
import Swinject
import LarkSettingsBundle

func larkMain() {
    let delegate: AppDelegate.Type = NSClassFromString("TestAppDelegate") as? AppDelegate.Type ?? AppDelegate.self
    let config = AppConfig(env: AppConfig.default.env, respondsToSceneSelectors: false)

    BootLoader.shared.start(delegate: delegate, config: config)
    _ = Assembler(
        [DemoAssembly(),
         SettingsBundleAssembly()
    ], container: BootLoader.container)
}

larkMain()
