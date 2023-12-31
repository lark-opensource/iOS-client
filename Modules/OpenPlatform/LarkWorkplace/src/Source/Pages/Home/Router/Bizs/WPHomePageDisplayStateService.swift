//
//  WPHomePageDisplayStateService.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/8/29.
//

import Foundation
import RxSwift
import RxRelay
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import LarkContainer

enum WPHomePageDisplayState: String {
    case initial
    case selected
    case show
    case hide
    case unselected
}

protocol WPHomePageDisplayStateService: AnyObject {
    func subscribePageState() -> Observable<WPHomePageDisplayState>
    func notifyPageAppear()
    func notifyPageDisappear()
}

final class WPHomePageDisplayStateServiceImpl: WPHomePageDisplayStateService {
    static let logger = Logger.log(WPHomePageDisplayStateService.self)

    private let pageStateRelay: BehaviorRelay<WPHomePageDisplayState> = BehaviorRelay(value: .initial)

    /// 主导航状态
    private let navigationService: NavigationService

    private let disposeBag = DisposeBag()

    init(navigationService: NavigationService) {
        self.navigationService = navigationService
        registerStatusChange()
    }

    func subscribePageState() -> Observable<WPHomePageDisplayState> {
        return pageStateRelay.distinctUntilChanged()
    }

    func notifyPageAppear() {
        Self.logger.info("notify page appear")
        pageStateRelay.accept(.show)
    }

    func notifyPageDisappear() {
        Self.logger.info("notify page disappear")
        pageStateRelay.accept(.hide)
    }

    private func registerStatusChange() {
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                let animatedTabBar = RootNavigationController.shared.viewControllers.first as? AnimatedTabBarController

                Self.logger.info("will resign active", additionalData: [
                    "currentTab": "\(animatedTabBar?.currentTab?.key ?? "")"
                ])
                guard let currentTab = animatedTabBar?.currentTab,
                      currentTab == .appCenter else {
                    return
                }
                self?.pageStateRelay.accept(.hide)
            })
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                let animatedTabBar = RootNavigationController.shared.viewControllers.first as? AnimatedTabBarController

                Self.logger.info("did become active", additionalData: [
                    "currentTab": "\(animatedTabBar?.currentTab?.key ?? "")"
                ])
                guard let currentTab = animatedTabBar?.currentTab,
                      currentTab == .appCenter else {
                    return
                }
                self?.pageStateRelay.accept(.show)
            })
            .disposed(by: disposeBag)
        navigationService.tabDriver.drive { [weak self](oldTab, newTab) in
            Self.logger.info("receive tab change", additionalData: [
                "oldTab": "\(oldTab?.key ?? "")",
                "newTab": "\(newTab?.key ?? "")"
            ])
            guard let old = oldTab, let new = newTab else {
                return
            }
            if old != .appCenter, new == .appCenter {
                // 其他 tab 切换至工作台
                self?.pageStateRelay.accept(.selected)
            } else if old == .appCenter, new != .appCenter {
                // 工作台切换至其他 tab
                self?.pageStateRelay.accept(.unselected)
            }
        }.disposed(by: disposeBag)
    }
}
