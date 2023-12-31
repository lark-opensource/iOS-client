//
//  TabControllerWrapper.swift
//  KATabRegistry
//
//  Created by Supeng on 2021/11/5.
//

import Foundation
import SnapKit
import LarkNavigation
import LarkUIKit
import AnimatedTabBar
import RxCocoa
import LarkTab
import UIKit
#if canImport(LKTabExternal)
import LKTabExternal
#endif

#if canImport(LKTabExternal)
final class TabControllerWrapper: UIViewController {

    private let tabConfig: KATabConfig
    private weak var innterTabController: UIViewController?

    init(tabConfig: KATabConfig) {
        self.tabConfig = tabConfig
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let childVC = tabConfig.tabViewController()
        innterTabController = childVC
        addChild(childVC)

        view.addSubview(childVC.view)
        childVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension TabControllerWrapper: TabRootViewController {
    var tab: Tab { tabConfig.larkTab }

    var controller: UIViewController { self }
}

extension TabControllerWrapper: LarkNaviBarProtocol {
    var titleText: BehaviorRelay<String> {
        BehaviorRelay(value: String(tabConfig.naviBarTitle ?? ""))
    }

    var isNaviBarEnabled: Bool { tabConfig.showNaviBar }

    var isDrawerEnabled: Bool { true }

    var isDefaultSearchButtonDisabled: Bool { true }

    func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        guard let innterTabViewController = innterTabController else { return nil }

        if case .first = type {
            return tabConfig.firstNaviBarButton?(innterTabViewController)
        } else if case .second = type {
            return tabConfig.secondNaviBarButton?(innterTabViewController)
        }
        return nil
    }
}

extension TabControllerWrapper: TabbarItemTapProtocol {
    func onTabbarItemDoubleTap() {
        tabConfig.tabDoubleClick?()
    }

    func onTabbarItemTap(_ isSameTab: Bool) {
        tabConfig.tabSingleClick?()
    }
}
#endif
