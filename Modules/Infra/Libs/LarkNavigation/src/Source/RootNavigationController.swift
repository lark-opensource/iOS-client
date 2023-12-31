//
//  RootNavigationController.swift
//  LarkNavigationDemo
//
//  Created by liuwanlin on 2018/9/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxCocoa
import RxSwift
import SnapKit
import AnimatedTabBar
import LarkTab
import LKCommonsLogging
import UniverseDesignColor

public final class RootNavigationController: LkNavigationController {
    private static let aLogger = Logger.log(RootNavigationController.self, category: "ALog.")
    private static let log = Logger.log(RootNavigationController.self, category: "LarkNavigation.RootNavigationController")
    public static var shared = RootNavigationController()

    var tabbar: MainTabbarController? {
        return self.viewControllers.first as? MainTabbarController
    }

    public var isLoading: Bool = false {
        didSet {
            showLoadingView(isLoading)
        }
    }

    public var loadingText: String = "" {
        didSet {
            self.loadingView.text = loadingText
        }
    }

    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.left]
    }

    private lazy var loadingView: LoadingPlaceholderView = {
        let view = LoadingPlaceholderView(frame: .zero)
        view.isHidden = !isLoading
        return view
    }()

    private func showLoadingView(_ show: Bool) {
        self.loadingView.isHidden = !show
        self.loadingView.removeFromSuperview()
        if show {
            self.view.addSubview(loadingView)
            self.loadingView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.isHidden = true
        view.backgroundColor = UIColor.ud.bgBase
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    public func clear() {
        Self.aLogger.info("clear viewControllers -> \(self.viewControllers)")
        Self.log.info("clear viewControllers -> \(self.viewControllers)")
        self.viewControllers = []
        self.dismiss(animated: false, completion: nil)
    }

    public func reset(with tabbar: UITabBarController) {
        Self.aLogger.info("reset with tabbar -> \(tabbar) -> \(self.viewControllers)")
        Self.log.info("reset with tabbar -> \(tabbar) -> \(self.viewControllers)")
        if let controller = self.viewControllers.first as? UITabBarController {
            /// 避免MainTabbarViewController没释放，被 MainTabbarViewController 持有的vc也没被释放，强制做一次清空
            /// 直接设置空数组不生效，但是放一个 UIViewController 就可以了...
            controller.setViewControllers([UIViewController()], animated: false)
        }
        self.viewControllers = [tabbar]
    }
}

extension RootNavigationController: TabbarService {
    public func badgeDriver(for tab: Tab) -> Driver<LarkTab.BadgeType> {
        return TabRegistry.resolve(tab)?.badge?.asDriver() ?? .empty()
    }
}

extension RootNavigationController {
    /// 切换到搜索tab，暂时放这里，后面重构后需要用通用办法
    public func switchToSearchTab(vc: UIViewController) {
        self.tabbar?.enterSearch(vc: vc)
    }
}
