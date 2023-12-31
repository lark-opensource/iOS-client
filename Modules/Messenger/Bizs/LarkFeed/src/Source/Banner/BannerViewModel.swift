//
//  BannerViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/1.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkModel
import LarkAccountInterface
import LarkBadge
import LarkFeedBanner
import LarkOpenFeed

/// 为了接入LarkFeedBanner，需要中转一层
final class BannerViewModel: FeedHeaderItemViewModelProtocol {
    private let disposeBag = DisposeBag()

    var bannerView: UIView?
    private var bannerHeight: CGFloat = 0

    var viewHeight: CGFloat {
        return bannerHeight
    }

    var type: FeedHeaderItemType {
        .banner
    }

    var display: Bool {
        displayRelay.value
    }

    // 是否显示
    private var displayRelay = BehaviorRelay<Bool>(value: false)
    var displayDriver: Driver<Bool> {
        return displayRelay.asDriver()
    }

    // 高度变化
    private var updateHeightRelay = BehaviorRelay<CGFloat>(value: 0)
    var updateHeightDriver: Driver<CGFloat> {
        return updateHeightRelay.asDriver()
    }

    private var bannerService: FeedBannerService

    init(bannerService: FeedBannerService) {
        self.bannerService = bannerService
        bannerService.bannerObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (banner) in
            guard let self = self else { return }
            guard let (view, height) = banner else {
                // 不显示: 重置
                self.bannerView = nil
                self.bannerHeight = 0
                self.displayRelay.accept(false)
                self.updateHeightRelay.accept(0)
                return
            }
            self.bannerView = view
            self.bannerHeight = height
            self.displayRelay.accept(true)
            self.updateHeightRelay.accept(height)
        }).disposed(by: disposeBag)
    }

    /// LarkBanner限制，需要显示触发一次width信号
    func fireWidth(_ width: CGFloat) {
        bannerService.fireWidth(width)
    }
}
