//
//  MomentTab.swift
//  Moment
//
//  Created by bytedance on 2021/2/26.
//

import Foundation
import Swinject
import LarkTab
import LarkNavigation
import LarkRustClient
import LarkContainer
import RxSwift
import RxCocoa
import ServerPB
import LKCommonsLogging

///MomentTab 遵守TabRepresentable
final class MomentTab: TabRepresentable, UserResolverWrapper {
    static let logger = Logger.log(MomentTab.self, category: "Module.Moment")

    lazy var userResolver: UserResolver = Container.shared.getCurrentUserResolver()
    private let _badge: BehaviorRelay<BadgeType> = BehaviorRelay<BadgeType>(value: .none)
    private let _badgeStyle: BehaviorRelay<LarkTab.BadgeRemindStyle> = BehaviorRelay<LarkTab.BadgeRemindStyle>(value: .strong)
    private let disposeBag = DisposeBag()
    private var badgeNumber: Int = 0 {
        didSet {
            updateBadge()
        }
    }
    private var redDotShowing: Bool = false {
        didSet {
            updateBadge()
        }
    }
    @ScopedInjectedLazy private var badgeNoti: MomentBadgePushNotification?
    @ScopedInjectedLazy private var redDotNotifyService: RedDotNotifyService?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?

    var tab: Tab { .moment }
    var badge: BehaviorRelay<LarkTab.BadgeType>? {
        return _badge
    }
    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return _badgeStyle
    }

    static let maxBadgeCount = 999

    init() {
        self.addObservers()
    }

    func updateBadge() {
        if self.badgeNumber > 0 {
            Self.logger.info("[NavigationTabBadge] Moment Tab update badge: \(badgeNumber)")
            self._badge.accept(BadgeType.number(badgeNumber))
        } else if self.redDotShowing {
            Self.logger.info("[NavigationTabBadge] Moment Tab update badge dot")
            self._badge.accept(BadgeType.dot(0))
        } else {
            Self.logger.info("[NavigationTabBadge] Moment Tab update badge none")
            self._badge.accept(BadgeType.none)
        }
    }

    /// 监听badge的变化
    private func addObservers() {
        self.badgeNoti?.badgePush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                guard let self = self else { return }
                let number = self.momentsAccountService?.getAllUsersTotalCount(info) ?? 0
                self.badgeNumber = number
            }).disposed(by: self.disposeBag)

        self.redDotNotifyService?.showDot
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (show) in
                self?.redDotShowing = show
            }).disposed(by: self.disposeBag)
    }

    static func tabTitle() -> String {
        // 远程名字不存在 取本地默认的
        return Tab.moment.remoteName ?? Tab.moment.tabName
    }
}
