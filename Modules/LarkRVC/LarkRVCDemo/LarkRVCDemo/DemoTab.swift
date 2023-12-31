//
//  DemoTab.swift
//  LarkRoomsWebView
//
//  Created by zhouyongnan on 2022/7/19.
//

import Foundation
import EENavigator
import LarkTab
import AnimatedTabBar
import LarkUIKit
import RxSwift
import RxCocoa
import LarkNavigation

public struct DemoTab {
    static var mainTabs: [Tab] {
        [Tab.test]
    }

    static var quickTabs: [Tab] {
        []
    }

    static func assembleTabs() {
        Navigator.shared.registerRoute(plainPattern: Tab.test.urlString, priority: .high) {
            TestTabHandler()
        }

        TabRegistry.register(Tab.test) { (_) -> TabRepresentable in
            return TestTab()
        }
    }
}

public extension Tab {
    static let test = Tab.contact
}

//// MARK: - PersonList
extension DemoViewController: BaseTabViewController {
    var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: self.title ?? "")
    }

    public var tab: Tab {
        .test
    }
}

public class TestTab: TabRepresentable {
    public var tab: Tab {
        .test
    }
}

public class TestTabHandler: RouterHandler {
    public func handle(req: EENavigator.Request, res: Response) {
        let vc = DemoViewController()
//        let nav = LkNavigationController(rootViewController: vc)
//        let nav = UINavigationController(rootViewController: vc)
        res.end(resource: vc)
    }
}

protocol BaseTabViewController: TabRootViewController, LarkNaviBarAbility, LarkNaviBarProtocol {
    var tab: Tab { get }

    var isNaviBarEnabled: Bool { get }
}

extension BaseTabViewController {
    var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: self.title ?? "")
    }

    var controller: UIViewController {
        self
    }

    var isNaviBarEnabled: Bool {
        return true
    }

    var isDrawerEnabled: Bool {
        return true
    }

    var isDefaultSearchButtonDisabled: Bool {
        return true
    }

    func larkNavibarBgColor() -> UIColor? {
        .white
    }
}

