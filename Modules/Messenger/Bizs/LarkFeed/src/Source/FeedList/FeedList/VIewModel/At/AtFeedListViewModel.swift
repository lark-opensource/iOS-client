//
//  AtFeedListViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/10.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB
import LarkOpenFeed

final class AtFeedListViewModel: FeedListViewModel {
    private let atDependency: AtViewModelDependency
    private var showAtAllInAtFilter: Bool?

    init(filterType: Feed_V1_FeedFilter.TypeEnum,
         atDependency: AtViewModelDependency,
         dependency: FeedListViewModelDependency,
         baseDependency: BaseFeedsViewModelDependency,
         feedContext: FeedContextService) {
        self.atDependency = atDependency
        super.init(filterType: filterType,
                   dependency: dependency,
                   baseDependency: baseDependency,
                   feedContext: feedContext)
        getFilters()
        bind()
    }

    private func getFilters() {
        atDependency.getAtFilterSetting()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] showAtAllInAtFilter in
                guard let self = self else { return }
                self.updateAtSetting(showAtAllInAtFilter)
            }, onError: { _ in
            }).disposed(by: disposeBag)
    }

    private func updateAtSetting(_ showAtAllInAtFilter: Bool) {
        self.showAtAllInAtFilter = showAtAllInAtFilter
    }

    private func bind() {
        atDependency.pushFeedFilterSettings
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] filtersModel in
            guard let self = self else { return }
            self.handle(filtersModel.showAtAllInAtFilter)
        }).disposed(by: disposeBag)
    }

    private func handle(_ showAtAllInAtFilter: Bool) {
        guard let oldShowAll = self.showAtAllInAtFilter, oldShowAll != showAtAllInAtFilter else { return }
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .reset)
        FeedContext.log.info("feedlog/dataStream/filter/at. \(self.listBaseLog), \(trace.description), oldShowAll: \(oldShowAll), showAtAllInAtFilter: \(showAtAllInAtFilter)")
        updateAtSetting(showAtAllInAtFilter)
        reset(trace: trace)
    }

    private func reset(trace: FeedListTrace) {
        self.removeAllFeeds(renderType: .reload, trace: trace)
        let task = { [weak self] in
            guard let self = self else { return }
            self.dirtyFeeds.removeAll()
            self.tempRemoveIds.removeAll()
            self.updateNextCursor(nil, trace: trace)
        }
        commit(task)
        super.getFeedCards()
    }
}
