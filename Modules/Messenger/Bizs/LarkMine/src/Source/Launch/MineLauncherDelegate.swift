//
//  MineLauncherDelegate.swift
//  LarkMine
//
//  Created by liuxianyu on 2021/12/9.
//

import Foundation
import LarkAccountInterface
import LKCommonsLogging
import RxSwift
import RxCocoa
import Swinject
import BootManager
import LarkContainer

public final class MineLauncherDelegate: LauncherDelegate {
    public let name: String = "MineLauncherDelegate"
    static let log = Logger.log(MineLauncherDelegate.self, category: "LarkMine")

    let resolver: Resolver
    // 监听账号切换后的信号
    public var onAccountSwitched = BehaviorRelay<Bool>(value: false)

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        guard error == nil else {
            onAccountSwitched.accept(false)
            return .just(())
        }
        onAccountSwitched.accept(true)
        Self.log.info("Mine SwichAccount success")

        _ = try? resolver.resolve(type: MineSettingBadgeDependency.self) // 提前初始化badge数据
        return .just(())
    }
}
