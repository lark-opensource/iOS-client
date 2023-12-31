//
//  LarkGuideDependency.swift
//  LarkGuide
//
//  Created by zhenning on 2020/12/07.
//

import LarkAccountInterface
import Swinject

protocol LarkGuideDependency {
    // 当前的用户Id
    var userId: String { get }
}

final class LarkGuideDependencyImpl: LarkGuideDependency {
    private let resolver: Resolver
    let userId: String

    init(resolver: Resolver) {
        self.resolver = resolver
        let accountService = self.resolver.resolve(AccountService.self)!
        self.userId = accountService.currentChatterId
    }
}
