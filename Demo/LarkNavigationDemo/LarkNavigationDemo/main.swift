//
//  main.swift
//  LarkNavigationDemo
//
//  Created by Supeng on 2021/1/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import BootManager
import AppContainer
import LarkAccount
import Swinject
import LarkRustClientAssembly
import RustPB
import LarkAppConfig
import LarkLaunchGuide
import EENavigator
import LarkNavigation
import LarkTab
import LarkLeanMode
import AnimatedTabBar
import LarkGuide
import LarkUIKit
import RxCocoa
import LarkDebug
import LarkMine
import LarkMessengerInterface
import LarkSDK
import LarkSetting
import LarkCore
import TangramService

var contextID: String?

class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override func execute(_ context: BootContext) {
        _ = Assembler([LaunchGuideAssembly(),
                       DefaultAccountDependencyAssembly(),
                       AccountAssembly(),
                       RustClientAssembly(),
                       ConfigAssembly(),
                       LarkDebug.DebugAssembly(),
                       SettingAssembly(),
                       LeanModeMockAssembly(),
                       LeanModeAssembly(),
                       LarkGuideAssembly(),
                       NavigationMockAssembly(),
                       NavigationAssembly(),
                       MineAssembly(),
                       CoreAssembly(),
                       TangramAssembly(),
                       SDKAssembly(),
                       SDKMockAssembly()],
                      container: BootLoader.container)

        BootLoader.assemblyLoaded = true
        TabRegistry.register(.feed) { _ in FakeTab() }

        SideBarVCRegistry.registerSideBarVC { vc -> UIViewController? in
            let body = MineMainBody(hostProvider: vc)
            let response = Navigator.shared.response(for: body)
            return response.resource as? UIViewController
        }

        MineAssembly().assembleRequestHandler(container: BootLoader.container)

        Navigator.shared.registerRoute(plainPattern: Tab.feed.urlString) { (_, res) in
            res.end(resource: FakeViewController())
        }

        contextID = context.contextID
    }
}

struct FakeTab: TabRepresentable {
    var tab: Tab { Tab.feed }
}

class FakeViewController: BaseUIViewController, TabRootViewController, LarkNaviBarDataSource, LarkNaviBarDelegate {

    var tab: Tab { Tab.feed }
    var controller: UIViewController { self }
    var titleText: BehaviorRelay<String> { BehaviorRelay(value: "Fake View Controller") }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red

        isNavigationBarHidden = true

        DispatchQueue.main.async {
            NewBootManager.shared.trigger(with: .afterFirstRender, contextID: contextID!)
        }
    }
}

NewBootManager.register(LarkMainAssembly.self)
BootLoader.shared.start(delegate: AppContainer.AppDelegate.self, config: .default)
