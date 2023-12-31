//
//  FeedBannerService.swift
//  LarkFeedBanner
//
//  Created by 袁平 on 2020/6/16.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import RustPB
import Swinject
import LKCommonsLogging
import UGReachSDK
import UGBanner
import LarkContainer
import SnapKit
import LarkAccountInterface

public protocol FeedBannerService {
    /// 用于外部监听Banner改变: nil 表示没有Banner
    /// 与UI确认，Banner需要适配多语言，所以无法固定高度
    var bannerObservable: Observable<(UIView, CGFloat)?> { get }

    /// 外部传入宽度
    func fireWidth(_ width: CGFloat)
}

final class FeedBannerServiceImpV2: FeedBannerService, BannerReachPointDelegate, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(FeedBannerServiceImpV2.self,
                                   category: "LarkFeedBanner.FeedBannerServiceImpV2")

    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var reachService: UGReachSDKService?
    private let bannerSubject: PublishSubject<(UIView, CGFloat)?>
    private var currentBannerData: UGBanner.BannerInfo?

    lazy var bannerReachPoint: BannerReachPoint? = {
        let reachPoint: BannerReachPoint? = reachService?.obtainReachPoint(
            reachPointId: "RP_FEED_TOP",
            bizContextProvider: nil
        )
        reachPoint?.delegate = self
        reachPoint?.register(bannerName: NotificaitionBannerHandler.bannerName,
                             for: NotificaitionBannerHandler())
        return reachPoint
    }()

    init(resolver: UserResolver) {
        self.userResolver = resolver
        bannerSubject = PublishSubject()
    }

    deinit {
        reachService?.recycleReachPoint(reachPointId: "RP_FEED_TOP", reachPointType: BannerReachPoint.reachPointType)
    }

    var bannerObservable: Observable <(UIView, CGFloat)?> {
        return bannerSubject.asObservable()
    }

    func fireWidth(_ width: CGFloat) {
        guard let bannerView = bannerReachPoint?.bannerView else {
            return
        }
        let newFrame = CGRect(x: bannerView.frame.minX, y: bannerView.frame.minY, width: width, height: bannerView.frame.height)
        bannerView.frame = newFrame
    }

    func onShow(bannerView: UIView, bannerData: UGBanner.BannerInfo, reachPoint: BannerReachPoint) {
        currentBannerData = bannerData
        bannerSubject.onNext((bannerView, bannerView.intrinsicContentSize.height))
    }

    func onHide(bannerView: UIView, bannerData: UGBanner.BannerInfo, reachPoint: BannerReachPoint) {
        bannerSubject.onNext(nil)
    }
}
