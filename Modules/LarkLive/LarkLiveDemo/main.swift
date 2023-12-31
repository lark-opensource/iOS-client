//
//  AppDelegate.swift
//  LarkDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import RxSwift
import Swinject
import LarkPerf
import BootManager
import AppContainer
import LarkContainer
import LarkLocalizations
import LarkTab
import EENavigator
import RxCocoa
import LarkUIKit
import AnimatedTabBar
import LarkAssembler
import LarkNavigation
import LarkLaunchGuide
import LarkWebViewContainer

class NewLarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        _ = Assembler.init(assemblies: [], assemblyInterfaces: [BaseAssembly()] + [LaunchGuideAssembly()], container: BootLoader.container)
        BootLoader.assemblyLoaded = true

        BootLoader.container.register(LarkWebViewProtocol.self, factory: { _ in FakeLarkWebViewProtocolImpl() })
        TabRegistry.register(.feed) { _ in FakeTab() }
        Navigator.shared.registerRoute(plainPattern: Tab.feed.urlString) { (_, res) in
            res.end(resource: ListTableViewController())
        }

        SideBarVCRegistry.registerSideBarVC { (_) -> UIViewController? in
            MineViewController()
        }
    }
}

class FakeLarkWebViewProtocolImpl: LarkWebViewProtocol {
    func setupAjaxFetchHook(webView: LarkWebView) {}
    func ajaxFetchHookString() -> String? { nil }
}

struct FakeTab: TabRepresentable {
    var tab: Tab { Tab.feed }
}

extension ListTableViewController: TabRootViewController, LarkNaviBarDataSource, LarkNaviBarDelegate {

    var tab: Tab { Tab.feed }
    var controller: UIViewController { self }
    var titleText: BehaviorRelay<String> { BehaviorRelay(value: "Fake View Controller") }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }
}

func larkMain() {
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
        ColdStartup.shared?.do(.main)
        AppStartupMonitor.shared.start(key: .startup)
        NewBootManager.register(NewLarkMainAssembly.self)
        NewBootManager.register(SetupOPInterfaceTask.self)
        NewBootManager.register(SetupDispatcherTask.self)
        BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

larkMain()
