//
//  DemoAppAssembly.swift
//  LarkTourDev
//
//  Created by Meng on 2020/5/22.
//

import UIKit
import Foundation
import Swinject
import AppContainer
import EENavigator
import LarkNavigation
import AnimatedTabBar
import Logger
import LarkTab

let demoUnsupportHint: String = "LarkTour中暂不支持此功能"

class TempAppender: Appender {
    static func identifier() -> String { "" }
    static func persistentStatus() -> Bool { false }
    func doAppend(_ event: LogEvent) {}
    func persistent(status: Bool) {}
}

class DemoAssembly: Assembly {
    func assemble(container: Container) {
        Logger.add(appender: TempAppender())

        Navigator.shared.navigationProvider = {
            return RootNavigationController.shared
        }

        Navigator.shared.tabProvider = {
            return RootNavigationController.shared
        }

        Navigator.shared.defaultSchemes = ["lark", "feishu"]

        SideBarVCRegistry.registerSideBarVC { (_) -> UIViewController? in
            FakeSidebarViewController()
        }

        assembleFakeTabs(container: container)
    }

    private func assembleFakeTabs(container: Container) {
        let tabs: [Tab] = [
            .feed, .calendar, .contact, .doc, .appCenter,
            .mail, .thread, .wiki, .allPin, .byteview
        ]
        tabs.forEach { tab in
            TabRegistry.register(tab) { _ in FakeTab(tab: tab) }
            Navigator.shared.registerRoute(plainPattern: tab.urlString) {
                FakeTabControllerHandler(tab: tab)
            }
        }
    }
}
