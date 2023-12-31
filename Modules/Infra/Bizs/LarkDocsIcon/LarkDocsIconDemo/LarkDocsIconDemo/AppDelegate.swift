//
//  AppDelegate.swift
//  LarkDocsIconDemo
//
//  Created by ByteDance on 2023/12/11.
//

import Foundation
import UIKit
import LarkContainer
import BootManager
import LarkAssembler
import LKLoadable
import Swinject
import AppContainer

class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { true }

    override func execute(_ context: BootContext) {
        let assemblies: [LarkAssemblyInterface] = [BaseAssembly()]
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
    }
}


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
//        BootLoader.container.register(LarkWebViewProtocol.self, factory: { _ in FakeLarkWebViewProtocolImpl() })
        Container.shared.canCallResolve = true
        NewBootManager.register(LarkMainAssembly.self)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        return true
    }

}
