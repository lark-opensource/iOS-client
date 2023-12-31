//
//  FeedPassportDelegate.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2021/1/10.
//

import Foundation
import LarkAccountInterface
import LKCommonsLogging
import RxSwift
import RxCocoa

public final class FeedPassportDelegate: PassportDelegate {
    public var name: String = "FeedPassportDelegate"

    // 监听账号切换后的信号
    public var onAccountSwitched = BehaviorRelay<Bool>(value: false)

    public func userDidOnline(state: PassportState) {
        if state.action == .switch {
            onAccountSwitched.accept(true)
            FeedContext.log.info("feedlog/tenement. swichAccount success")
        }
    }

    public func userDidOffline(state: PassportState) {
        if state.action == .switch {
            Feed.Feature.beforeSwitchAccount()
        }
    }
}

public final class FeedLauncherDelegate: LauncherDelegate {
    public var name: String = "FeedLauncherDelegate"

    // 监听账号切换后的信号
    public var onAccountSwitched = BehaviorRelay<Bool>(value: false)

    init() {}

    /// 切租户
    public func beforeSwitchAccout() {
        Feed.Feature.beforeSwitchAccount()
    }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        guard error == nil else {
            onAccountSwitched.accept(false)
            return .just(())
        }
        onAccountSwitched.accept(true)
        FeedContext.log.info("feedlog/tenement. swichAccount success")
        return .just(())
    }
}
