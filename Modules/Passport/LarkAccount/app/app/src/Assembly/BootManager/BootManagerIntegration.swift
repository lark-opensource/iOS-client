//
//  BootManagerIntegration.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2021/3/29.
//

import Foundation
import LarkAccountInterface
import Swinject

#if !SIMPLE
import BootManager

class BootManagerAssembly: Assembly {
    func assemble(container: Container) {
        BootManager.register(LarkMainAssembly.self)
        BootManager.shared.dependency = MockBootManagerDependency()

        LauncherDelegateRegistery.register(factory: LauncherDelegateFactory(delegateProvider: {
            DemoDelegate()
        }), priority: .middle)

        registerTask()
    }

    func registerTask() {
        BootManager.register(SetupDemoMainTabTask.self)
        BootManager.register(SetupDispatcherTask.self)
    }
}

class BootManagerDelegate: LauncherDelegate {
    let name: String = "BootManagerDelegate"

    func afterAccountLoaded(_ context: LauncherContext) {
        let fakeVC = UIViewController()
        fakeVC.view.backgroundColor = .red
        BootManager.shared.connectedContexts.values.first?.window?.rootViewController = fakeVC
    }
}

class MockBootManagerDependency: BootDependency {
    func tabStringToBizScope(_ tabString: String) -> BizScope? {
        return nil
    }

    func launchOptionToBizScope(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BizScope? {
        return .specialLaunch
    }

    var eventObserver: EventMonitorProtocol? {
        return nil
    }
}

class DemoDelegate: LauncherDelegate {
        let name: String = "Container"

        func afterAccountLoaded(_ context: LauncherContext) {
            let fakeVC = UIViewController()
            fakeVC.view.backgroundColor = .red
            BootManager.shared.connectedContexts.values.first?.window?.rootViewController = fakeVC
        }

    }
#endif
