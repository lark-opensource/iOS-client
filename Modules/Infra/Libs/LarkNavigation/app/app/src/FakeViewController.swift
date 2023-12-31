//
//  FakeViewController.swift
//  LarkDocs
//
//  Created by CharlieSu on 1/17/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import UIKit
import EENavigator
import LarkUIKit
import LarkNavigation
import RxSwift
import RxCocoa
import AnimatedTabBar
import LarkTab
import UniverseDesignDrawer

class FakeControllerHandler: RouterHandler {
    func handle(req: EENavigator.Request, res: Response) {
        res.end(resource: FakeViewController())
    }
}

struct FakeTab: TabRepresentable {
    var tab: Tab { Tab.feed }
}

class FakeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }
}

extension FakeViewController: TabbarItemTapProtocol, UDDrawerAddable, LarkNaviBarDelegate, LarkNaviBarAbility {
    var fromVC: UIViewController? {
        self
    }

    var contentWidth: CGFloat {
        280
    }
}

extension FakeViewController: TabRootViewController {
    var tab: Tab {
        return Tab.feed
    }

    var controller: UIViewController {
        return self
    }
}

extension FakeViewController: LarkNaviBarDataSource {
    var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: "Fake View Controller")
    }

    var isNaviBarEnabled: Bool {
        return true
    }

    var isDrawerEnabled: Bool {
        return true
    }
}
