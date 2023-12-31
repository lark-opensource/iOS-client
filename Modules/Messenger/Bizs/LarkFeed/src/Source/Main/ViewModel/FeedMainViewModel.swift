//
//  FeedMainViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/23.
//

import Foundation
import RxSwift
import RxCocoa
import LKCommonsLogging
import RustPB
import LarkOpenFeed
import RunloopTools
import LarkAccountInterface
import LarkContainer
import Swinject

final class FeedMainViewModel: UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }

    let context: FeedContext
    var currentFilterType: Feed_V1_FeedFilter.TypeEnum
    let allFeedsViewModel: AllFeedListViewModel
    var filterSet = Set<Feed_V1_FeedFilter.TypeEnum>()

    var deleteListCallBack: (([Feed_V1_FeedFilter.TypeEnum]) -> Void)?
    var backFirstListCallBack: ((Feed_V1_FeedFilter.TypeEnum) -> Void)?
    var updatePosisionCallBack: ((Feed_V1_FeedFilter.TypeEnum) -> Void)?
    let dependency: FeedMainViewModelDependency
    let disposeBag = DisposeBag()
    let feedDependency: FeedDependency
    let moduleContext: FeedModuleContext

    // 获取首个tab类型值
    var firstTab: Feed_V1_FeedFilter.TypeEnum {
        return allFeedsViewModel.firstTab
    }

    // 用于识别固定栏tab的变化
    var tempFixedFilterTypes: [Feed_V1_FeedFilter.TypeEnum]?

    var userId: String { userResolver.userID }

    init(dependency: FeedMainViewModelDependency,
         allFeedsViewModel: AllFeedListViewModel,
         context: FeedContext
    ) throws {
        self.feedDependency = try dependency.resolver.resolve(assert: FeedDependency.self)
        self.dependency = dependency
        self.context = context
        self.moduleContext = FeedModuleContext(feedContext: context)
//        FeedFloatMenuModule.onLoad(context: self.moduleContext.floatMenuContext)
        //let viewModel = FeedViewModelFactory.viewModel(for: .inbox)
        self.currentFilterType = .unknown
        self.allFeedsViewModel = allFeedsViewModel
        bind()
    }

    func bind() {
        self.dependency.filtersDriver
        .drive(onNext: { [weak self] list in
            guard let self = self else { return }
            self.handleFilters(list)
        }).disposed(by: disposeBag)
    }

    private func handleFilters(_ list: [FilterItemModel]) {
        // 删除不存在的
        var deletes = [Feed_V1_FeedFilter.TypeEnum]()
        self.filterSet.forEach { type in
            let shouldDelete = !list.contains { $0.type == type }
            if shouldDelete {
                deletes.append(type)
            }
        }
        let isCurrentTabValid = list.contains { filter -> Bool in
            let founds = self.currentFilterType == filter.type
            if founds {
                return true
            }
            return false
        }

        if isCurrentTabValid {
            // filter 重新找位置
            if let task = self.updatePosisionCallBack {
                task(self.currentFilterType)
            }
        } else {
            // 回到全部
            if let task = self.backFirstListCallBack {
                task(self.currentFilterType)
            }
        }

        if let task = self.deleteListCallBack {
            task(deletes)
        }
    }

    // 埋点
    func trackPageView(dataStore: FilterDataStore) {
        if !dataStore.isFirstLoad {
            let filters = dataStore.usedFiltersDS
            FeedTracker.Main.View(filtersCount: filters.count, isFilterShow: !filters.isEmpty)
        }
    }
}

extension FeedMainViewModel {
    func sendLifeState(_ state: FeedPageState) {
        context.pageImpl.pageStateRelay.accept(state)
        allFeedsViewModel.feedContext.listeners
            .filter { $0.needListenLifeCycle }
            .map { $0.feedLifeCycleChanged(state: state, context: context) }
    }
}
