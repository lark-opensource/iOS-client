//
//  AppDelegate.swift
//  LarkInlineAIDemo
//
//  Created by huayufan on 2023/4/25.
//  


import UIKit
import BootManager
import LarkAssembler
import AppContainer
import LKLoadable
import LarkContainer
import Swinject
import LarkWebViewContainer

final class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }
    

    override func execute(_ context: BootContext) {
        let assemblies: [LarkAssemblyInterface] = [
            BaseAssembly(),
        ]
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
        
//        BootLoader.container.register(LarkWebViewProtocol.self, factory: { _ in FakeLarkWebViewProtocolImpl() })
    }
}

class FakeLarkWebViewProtocolImpl: LarkWebViewProtocol {
    func setupAjaxFetchHook(webView: LarkWebView) {}
    func ajaxFetchHookString() -> String? { nil }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LKLoadableManager.run(didFinishLaunch)
        NewBootManager.register(LarkMainAssembly.self)

        BootLoader.container.register(LarkWebViewProtocol.self, factory: { _ in FakeLarkWebViewProtocolImpl() })
        Container.shared.canCallResolve = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        return true
    }

}

