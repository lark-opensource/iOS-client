//
//  FakeTab.swift
//  LarkTourDev
//
//  Created by Meng on 2020/9/29.
//

import UIKit
import Foundation
import AnimatedTabBar
import LarkNavigation
import EENavigator
import RxSwift
import LarkTourInterface
import LarkContainer
import LarkUIKit
import RxCocoa
import RoundedHUD
import LarkTab

struct FakeTab: TabRepresentable {
    private let _tab: Tab
    var tab: Tab { return _tab }

    init(tab: Tab) {
        self._tab = tab
    }
}

class FakeTabController: UIViewController {
    private let _tab: Tab

    init(tab: Tab) {
        self._tab = tab
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var tabName: String {
        return "Fake Tab"
    }

    var tabInstance: Tab {
        return _tab
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = Colors.random()
    }
}

extension FakeTabController: LarkNaviBarAbility {}
extension FakeTabController: LarkNaviBarDataSource {
    var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: tabName)
    }

    var isNaviBarEnabled: Bool {
        return true
    }

    var isDrawerEnabled: Bool {
        return true
    }
}
extension FakeTabController: LarkNaviBarDelegate {
    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        RoundedHUD.showTips(with: demoUnsupportHint)
    }
}
extension FakeTabController: DrawerAddable {}
extension FakeTabController: TabRootViewController {
    var tab: Tab {
        return tabInstance
    }

    var controller: UIViewController {
        return self
    }

    func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        switch type {
        case .first: return UIImage(named: "conversation_plus_light")
        default: return nil
        }
    }
}
extension FakeTabController: TabbarItemTapProtocol {}
