//
//  DocFeedCardDependency.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2023/8/8.
//
#if MessengerMod

import Foundation
import LarkAccountInterface
import LarkSDKInterface
import LarkOpenFeed
import LarkMessengerInterface
import LarkContainer
import RxSwift

protocol DocFeedCardDependency: UserResolverWrapper {
    var currentTenantId: String { get }

    var accountType: PassportUserType { get }

    func changeMute(feedId: String, to state: Bool) -> Single<Void>

    var iPadStatus: String? { get }
}

final class DocFeedCardDependencyImpl: DocFeedCardDependency {
    let userResolver: UserResolver

    @ScopedInjectedLazy var docApi: DocAPI?
    let passportUserService: PassportUserService

    var accountType: PassportUserType {
        return passportUserService.user.type
    }

    var currentTenantId: String {
        return passportUserService.userTenant.tenantID
    }

    let feedThreeBarService: FeedThreeBarService
    var iPadStatus: String? {
        if let unfold = feedThreeBarService.padUnfoldStatus {
            return unfold ? "unfold" : "fold"
        }
        return nil
    }

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.feedThreeBarService = try resolver.resolve(assert: FeedThreeBarService.self)
    }

    func changeMute(feedId: String, to state: Bool) -> Single<Void> {
        return (docApi?.updateDocFeed(feedId: feedId, isRemind: state) ?? Observable.just(()))
        .asSingle()
    }
}
#endif
