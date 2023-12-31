//
//  TopBarViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/22.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkModel
import LarkAccountInterface
import LarkBadge
import LKCommonsLogging
import LarkContainer

final class TopBarViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    // 是否显示
    var displayRelay = BehaviorRelay<Bool>(value: false)

    // 高度变化
    var updateHeightRelay = BehaviorRelay<CGFloat>(value: 0)

    // 是否显示「网络状态」
    private let netStatusRelay = BehaviorRelay<NetworkState>(value: .normal)
    var netStatusDriver: Driver<NetworkState> {
        return netStatusRelay.asDriver().distinctUntilChanged()
    }
    var netStatus: NetworkState {
        return netStatusRelay.value
    }

    private let disposeBag: DisposeBag = DisposeBag()
    private let dependency: TopBarViewModelDependency

    init(resolver: UserResolver, dependency: TopBarViewModelDependency) {
        self.userResolver = resolver
        self.dependency = dependency

        // 网络状态
        self.dependency.pushDynamicNetStatus.observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] push in
            guard let self = self else { return }
            /// 判断网络、服务问题
            var netStatus: NetworkState = .normal
            switch push.dynamicNetStatus {
            case .offline:
                netStatus = .noNetwork
            case .serviceUnavailable, .netUnavailable:
                netStatus = .serviceUnavailable
            case .excellent, .evaluating, .weak:
                break
            @unknown default:
                assert(false, "new value")
                break
            }
            let isShowNet = !(netStatus == .normal)
            FeedContext.log.info("feedlog/header/topbar. pushDynamicNetStatus: isShowNet = \(isShowNet), netStatus = \(netStatus), push = \(push)")
            self.netStatusRelay.accept(netStatus)
            self.displayRelay.accept(isShowNet)
            self.updateHeightRelay.accept(self.viewHeight)
            }).disposed(by: disposeBag)
    }
}
