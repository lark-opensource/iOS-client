//
//  LarkBadgeDelegate.swift
//  Lark
//
//  Created by KT on 2019/4/24.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkBadge
import RxSwift
import LarkAccountInterface
import LarkUIKit

public final class LarkBadgeDelegate: LauncherDelegate {
    public var name = "LarkBadge"

    private let resolver: Resolver

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func afterLogout(_ context: LauncherContext) {
        // 退出登录 清空Badge
        BadgeManager.forceClearAll()
        ApplicationBadgeNumber.shared.setIconBadgeNumber(0)
    }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        // 切换账户 清空Badge
        BadgeManager.forceClearAll()
        return .just(())
    }
}
