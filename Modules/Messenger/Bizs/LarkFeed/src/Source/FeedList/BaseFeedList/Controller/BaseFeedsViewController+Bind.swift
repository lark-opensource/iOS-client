//
//  BaseFeedsViewController+Bind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/20.
//

import Foundation
import RunloopTools
import RxSwift
import RxCocoa

extension BaseFeedsViewController {
    func bind() {
        self.feedsViewModel.feedsRelay.asDriver()
            .drive(onNext: { [weak self] section in
                guard let self = self else { return }
                guard self.tableView.window != nil else {
                    // if view is not in view hierarchy, performing batch updates will crash the app
                    self.setItems([section], originalRenderType: section.renderType)
                    return
                }
                switch section.renderType {
                case .reload:
                    self.setItems([section], originalRenderType: section.renderType)
                case .animate(let renderType):
                    self.diff(section: section, renderType: renderType)
                case .none:
                    self.diff(section: section, renderType: nil)
                case .ignore:
                    break
                }
            }).disposed(by: self.disposeBag)
        // 侧滑设置发生变化时：1. 隐藏action视图；2. 重置左右action视图配置
        self.feedsViewModel.swipeSettingChanged.drive(onNext: {[weak self] _ in
            guard let self = self else { return }
            self.swipingCell?.hideSwipe(animated: false)
            Self.leftOrientation = nil
            Self.rightOrientation = nil
        }).disposed(by: self.disposeBag)

        // 触发TableView刷新之后，需要检查一下是否添加空态页
        feedsViewModel.showEmptyViewObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] showEmptyView in
                guard let self = self else { return }
                self.showOrRemoveEmptyView(showEmptyView)
            }).disposed(by: disposeBag)

        // 响应信号是否要支持底部的加载更多菊花
        var timecost: TimeInterval = 0
        feedsViewModel.feedLoadMoreRelay.asDriver().distinctUntilChanged().drive(onNext: { [weak self] hasMore in
            guard let self = self else { return }
            if !hasMore {
                // 如果是无需加载更多，并且加载更多已存在，但是未处于loading的状态，则主动取消掉
                if let bottomLoadMore = self.tableView.bottomLoadMoreView, bottomLoadMore.state == .none {
                    self.tableView.enableBottomLoadMore(false)
                }
            } else {
                // 需要添加loadMore的菊花: 这里只需要添加菊花即可，不需要触发loadMore
                // 因为在willDisplay的时候会触发loadMore，这里是为了防止滚动过快，滚到底的时候
                // 需要显示菊花
                self.tableView.pullUpStateChangeBlock = { [weak self] (last, next) in
                    guard let `self` = self, last == .loading, next == .none else { return }
                    // 底部菊花结束显示的时机
                    FeedPerfTrack.trackFeedLoadingMore(bizType: self.feedsViewModel.bizType, isStart: false)
                    if (self.feedsViewModel.bizType == .inbox
                       || self.feedsViewModel.bizType == .done),
                       timecost > 0,
                       let key = self.loadMoreCostKey {
                        // 记录显示菊花的埋点
                        FeedPerfTrack.trackFeedLoadMoreEnd(key: key,
                                                           getFeedCards: timecost)
                        self.loadMoreCostKey = nil
                        timecost = 0
                    }
                }

                self.tableView.addBottomLoadMoreView { [weak self] in
                    guard let `self` = self else { return }
                    FeedTeaTrack.trackFeedLoadingMore()
                    FeedPerfTrack.trackFeedLoadingMore(bizType: self.feedsViewModel.bizType, isStart: true)
                    if self.feedsViewModel.bizType == .inbox || self.feedsViewModel.bizType == .done {
                        self.feedsViewModel.isRecordLoadMore = false
                        self.loadMoreCostKey = FeedPerfTrack.trackFeedLoadMoreStart()
                    }
                }
            }
        }).disposed(by: disposeBag)

        // 打点 for loadmore
        feedsViewModel.recordRelay.asDriver().drive(onNext: { [weak self] cost in
            guard let self = self, cost > 0.0 else { return }
            if (self.feedsViewModel.bizType == .inbox
               || self.feedsViewModel.bizType == .done),
               self.feedsViewModel.isRecordLoadMore {
                if let bottomLoadMoreView = self.tableView.bottomLoadMoreView, bottomLoadMoreView.state == .loading {
                } else {
                    // 记录不显示菊花的埋点
                    self.feedsViewModel.isRecordLoadMore = false
                    FeedPerfTrack.trackFeedLoadMoreTimecost(getFeedCards: cost)
                }
            }
        }).disposed(by: disposeBag)

        if AllFeedListViewModel.getFirstTabs().contains(feedsViewModel.getFilterType()) {
            // 只有首tab会异步绑定
            RunloopDispatcher.shared.addTask(priority: .emergency) {
                self.asyncBinds()
            }
        } else {
            self.asyncBinds()
        }
    }

    private func asyncBinds() {
        // 监听选中态
        subscribeSelect()

        // 监听截屏事件，打log
        screenShot()
    }

    func setItems(_ sections: [SectionHolder], originalRenderType: FeedRenderType) {
        let result = sections.first
        FeedContext.log.info("feedlog/dataStream/render/fullReloadData. \(self.feedsViewModel.listContextLog), \(result?.trace.description ?? "trace is empty"), origin: \(originalRenderType)")
        self.trace = result?.trace ?? FeedListTrace.genDefault()
        self.feedsViewModel.setItems(sections)
        self.tableView.reloadData()
        self.feedsViewModel.feedsUpdated.onNext(())
    }
}
