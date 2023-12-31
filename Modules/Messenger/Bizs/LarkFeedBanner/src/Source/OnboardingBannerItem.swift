//
//  OnboardingBannerItem.swift
//  LarkFeedBanner
//
//  Created by ByteDance on 2022/9/27.
//

import UIKit
import Foundation
import LarkContainer
import UGReachSDK
import RxSwift
import RxCocoa
import UGBanner
import LarkOpenFeed

public final class OnboardingBannerItem: FeedBottomBarItem, UserResolverWrapper {
    public let userResolver: UserResolver

    @ScopedProvider var reachService: UGReachSDKService?
    static let scenarioId = "SCENE_FEED_BOTTOM"
    static let reachPointId = "RP_FEED_BOTTOM"

    private var _display = false
    private let _authKey: String
    private let commandRelay: PublishRelay<FeedBottomBarItemCommand>
    var bannerData: BannerInfo?

    public var display: Bool {
        return _display
    }

    public var authKey: String {
        return _authKey
    }

    lazy var bottomBannerReachPoint: BannerReachPoint? = {
        let bizContextProvider = UGSyncBizContextProvider(scenarioId: Self.scenarioId) { [:] }
        let reachPoint: BannerReachPoint? = reachService?.obtainReachPoint(
            reachPointId: Self.reachPointId,
            bizContextProvider: bizContextProvider
        )

        return reachPoint
    }()

    public init(userResolver: UserResolver, authKey: String, publishRelay: PublishRelay<FeedBottomBarItemCommand>) {
        self.userResolver = userResolver
        self._authKey = authKey
        self.commandRelay = publishRelay
        self.bottomBannerReachPoint?.delegate = self
        self.reachService?.tryExpose(by: Self.scenarioId, specifiedReachPointIds: [Self.reachPointId])
    }

    private func updateStatus(isDisplay: Bool) {
        _display = isDisplay
        commandRelay.accept(.render(item: self))
    }
}

extension OnboardingBannerItem: BannerReachPointDelegate {
    public func onShow(bannerView: UIView, bannerData: UGBanner.BannerInfo, reachPoint: UGBanner.BannerReachPoint) {
        self.bannerData = bannerData
        updateStatus(isDisplay: true)
    }

    public func onHide(bannerView: UIView, bannerData: UGBanner.BannerInfo, reachPoint: UGBanner.BannerReachPoint) {
        updateStatus(isDisplay: false)
    }
}
