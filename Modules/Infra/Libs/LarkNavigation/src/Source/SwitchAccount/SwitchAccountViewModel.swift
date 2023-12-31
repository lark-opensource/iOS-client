//
//  SwitchAccountViewModel.swift
//  Lark
//
//  Created by Li Yuguo on 2018/12/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkAccountInterface
import UniverseDesignToast
import EENavigator
import LarkBadge
import LarkContainer

public final class SwitchAccountViewModel: SwitchAccountService, UserResolverWrapper {

    public let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(SwitchAccountViewModel.self)

    private let remoteAccountsBadgesVariable = BehaviorRelay<AccountsBadges>(value: [:])
    public var accountsBadgesDriver: Driver<AccountsBadges> {
        return remoteAccountsBadgesVariable.asDriver()
    }

    private let badgeAPI: RustAccountBadgeAPI

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.badgeAPI = RustAccountBadgeAPI(userResolver: userResolver)
    }

    // 获取所有租户Badge
    public func fetcAccountsBadge() {
        self.badgeAPI.getAccountBadge()
            .subscribe(onNext: { [weak self] (badges) in
                self?.remoteAccountsBadgesVariable.accept(badges.userBadgeMap)
                SwitchAccountViewModel.logger.info("fetch userBadgeMap \(badges.userBadgeMap)")
            }).disposed(by: disposeBag)
    }

    // 更新push来的租户的badge
    public func updateAccountBadge(with badgesMap: AccountsBadges) {
        var temp = remoteAccountsBadgesVariable.value
        badgesMap.forEach { temp[$0] = $1 }
        remoteAccountsBadgesVariable.accept(temp)
    }
}
