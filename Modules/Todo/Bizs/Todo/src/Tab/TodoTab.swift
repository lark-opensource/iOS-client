//
//  TodoTab.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/10.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkTab
import LKCommonsLogging

final class TodoTab: TabRepresentable, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var badgePush: ListBadgeNoti?

    private var _badge: BehaviorRelay<BadgeType> = BehaviorRelay<BadgeType>(value: .none)
    private let disposeBag = DisposeBag()

    var tab: Tab { .todo }

    init(resolver: UserResolver) {
        self.userResolver = resolver
        fetchApi?.getTodoBadgeNumber()
            .subscribe(onNext: { [weak self] count in
                TodoTab.logger.info("[NavigationTabBadge] init badge number is \(count)")
                self?.setBadgeNumber(number: count)
            })
            .disposed(by: disposeBag)
        badgePush?.rxListBadge
            .subscribe(onNext: { [weak self] count in
                TodoTab.logger.info("[NavigationTabBadge] push badge number is \(count)")
                self?.setBadgeNumber(number: count)
            })
            .disposed(by: disposeBag)
    }

    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return BehaviorRelay<BadgeRemindStyle>(value: .strong)
    }

    var badge: BehaviorRelay<BadgeType>? {
        return self._badge
    }

    func setBadgeNumber(number: Int32) {
        var badge: BadgeType
        if number <= 0 {
            badge = .none
        } else {
            badge = .number(Int(number))
        }
        self._badge.accept(badge)
    }
}

extension TodoTab {
    static let logger = Logger.log(TodoTab.self, category: "TodoTab")
}
