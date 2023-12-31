//
//  FilterContainerViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/1/5.
//

import Foundation
import UIKit
import UniverseDesignTabs
import LarkUIKit
import RxSwift
import RxCocoa
import LarkMessengerInterface
import LarkNavigation
import EENavigator
import RunloopTools
import LarkContainer

final class FilterContainerViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    let filterFixedViewModel: FilterFixedViewModel
    let dataStore: FilterDataStore
    let styleService: Feed3BarStyleService?

    // 是否显示
    private var displayRelay = BehaviorRelay<Bool>(value: false)
    var displayDriver: Driver<Bool> {
        return displayRelay.asDriver().distinctUntilChanged()
    }
    var display: Bool {
        displayRelay.value
    }
    var viewHeight: CGFloat {
        display ? FilterContainerView.FilterViewHeight : 0
    }

    private let isSupportCeilingRelay = BehaviorRelay<Bool>(value: false)
    var isSupportCeilingDriver: Driver<Bool> {
        return isSupportCeilingRelay.asDriver().distinctUntilChanged()
    }
    var isSupportCeiling: Bool {
        return isSupportCeilingRelay.value
    }

    init(resolver: UserResolver,
         dataStore: FilterDataStore,
         filterFixedViewModel: FilterFixedViewModel) {
        self.userResolver = resolver
        self.dataStore = dataStore
        self.filterFixedViewModel = filterFixedViewModel
        self.styleService = try? resolver.resolve(assert: Feed3BarStyleService.self)
        self.bind()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    func bind() {
        filterFixedViewModel.filterShowDriver.drive(onNext: { [weak self] (isShowFilter) in
            guard let self = self else { return }
            FeedContext.log.info("feedlog/filter/tabContainer. isShowFilter: \(isShowFilter)")
            // 隐藏filterTabBar
            self.displayRelay.accept(isShowFilter)
            self.isSupportCeilingRelay.accept(isShowFilter) //设置吸顶状态
        }).disposed(by: disposeBag)
    }

    func isOverMaxWidth(maxWidth: CGFloat, filertContentWidth: CGFloat, pcContentWidth: CGFloat) -> Bool {
        let settingContentWidth = FilterContainerView.FilterViewHeight
        if filertContentWidth + pcContentWidth + settingContentWidth < maxWidth {
            // 筛选器没有超过宽度：设置入口在右侧
            return false
        }
        return true
    }
}
