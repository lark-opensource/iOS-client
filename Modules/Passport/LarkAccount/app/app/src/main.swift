//
//  AppDelegate.swift
//  LarkDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import AppContainer
import LarkAccount
import Swinject
import LarkAccountInterface

import EENavigator
import LarkLocalizations
import LarkFoundation
import LarkDebugExtensionPoint
import LarkRustClientAssembly
import LarkAppConfig
import LarkContainer

#if !SIMPLE
import BootManager
#endif

func larkMain() {
    BootLoader.shared.start(delegate: DemoAppDelegate.self, config: .default)
}

class DemoAppDelegate: AppContainer.AppDelegate {

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setUp()
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        LanguageManager.supportLanguages = [.zh_CN, .ja_JP, .en_US]

        #if SIMPLE
        print("simple mode")
        AccountServiceAdapter.shared.setup()
        LoginService.shared.login(window: window)
        #endif

        return result
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return DemoUrlHandler.handle(url: url)
    }

    func setUp() {

        let assemblies: [Assembly] = [
            DefaultAccountDependencyAssembly(),
            AccountAssembly(),
            ConfigAssembly(),
            DefaultRustClientDependencyAssembly(),
            RustClientAssembly(),
            DemoAssembly()
        ]

        _ = Assembler(assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true

        UIStatusBarHookManager.hookTapEvent()

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(openDebugVC),
                         name: NSNotification.Name(rawValue: "statusBarTappedNotification"),
                         object: nil
            )
    }

    @objc
    func openDebugVC(noti: NSNotification) {
        if noti.userInfo?["statusBarTappedCount"] as? Int == 5 {
            UIApplication.shared.keyWindow?.rootViewController?
                .present(DebugViewController(), animated: true, completion: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

larkMain()
