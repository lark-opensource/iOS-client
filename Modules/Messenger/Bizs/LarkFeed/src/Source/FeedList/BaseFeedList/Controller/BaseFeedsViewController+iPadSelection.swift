//
//  BaseFeedsViewController+iPadSelection.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/3.
//

import UIKit
import Foundation
import RxSwift
import EENavigator
import LarkSplitViewController
import LarkUIKit

/// For iPad Selection
extension BaseFeedsViewController {

    /// 选中态
    func subscribeSelect() {
        guard FeedSelectionEnable else {
            return
        }
        self.feedsViewModel.observeSelect()
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] feedId in
                guard let self = self else { return }
                // R视图下且feedId为nil, 需要展示占位VC
                var isCollapsed: Bool
                if let larkSplitViewController = self.larkSplitViewController {
                    isCollapsed = larkSplitViewController.isCollapsed
                } else {
                    isCollapsed = self.view.horizontalSizeClass != .regular
                }
                if !isCollapsed, feedId == nil {
                    self.navigator.showDetail(SplitViewController.defaultDetailController(), from: self)
                }
                // reset
                self.feedsViewModel.provider.resetSelectedState(feedId)
                let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .selected)
                self.feedsViewModel.updateFeeds([], renderType: .reload, trace: trace)
            }).disposed(by: disposeBag)

        // 监听 split 切换 detail 页面信号
        NotificationCenter.default.rx
            .notification(SplitViewController.SecondaryControllerChange).subscribe(onNext: { [weak self] (noti) in
            if let splitVC = noti.object as? SplitViewController,
               let currentSplitVC = self?.larkSplitViewController,
               splitVC == currentSplitVC,
               let detail = splitVC.viewController(for: .secondary) {
                var topVC = detail
                if let nav = detail as? UINavigationController,
                   let firstVC = nav.realViewControllers.first {
                    topVC = firstVC
                }
                /// 首页为默认 default 页面, 取消选中态
                if topVC is DefaultDetailVC {
                    self?.feedsViewModel.setSelected(feedId: nil)
                }
            }
        }).disposed(by: disposeBag)
    }

    // MARK: - VC LifeCyle For iPad

    /// VC viewWillTransition
    /// CR切换, 触发刷新
    func viewWillTransitionForPad(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard FeedSelectionEnable else { return }
        coordinator.animate(alongsideTransition: nil, completion: { context in
            if !context.isCancelled, !context.isInterruptible {
                guard let sizeClass = self.view.horizontalSizeClass else { return }
                // R/C视图切换时刷新一下UI
                let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .viewWillTransitionForPad)
                self.feedsViewModel.updateFeeds([], renderType: .reload, trace: trace)
            }
        })
    }

    /// 当前选中Cell被move to done时，会自动选中下一个Cell
    /// Params:
    ///     - feedId: 当前被选中的Feed Id, feedId = nil表示清空选中态
    func selectNextFeedIfNeeded(feedId: String?) {
        if FeedSelectionEnable {
            guard let feedId = feedId else {
                self.feedsViewModel.setSelected(feedId: nil)
                return
            }
            guard let vm = self.feedsViewModel.allItems().first(where: { $0.feedPreview.id == feedId }),
                vm.selected else {
                    return
            }
            let nextId = self.feedsViewModel.findNextSelectFeed(feedId: feedId)
            // asyncAfter是为了等Cell动画做完
            DispatchQueue.main.asyncAfter(deadline: .now() + FeedSelectionCons.delaySecond) {
                // R视图才生效，C视图表现同iPhone
                var isCollapsed: Bool
                if let larkSplitViewController = self.larkSplitViewController {
                    isCollapsed = larkSplitViewController.isCollapsed
                } else {
                    isCollapsed = self.view.horizontalSizeClass != .regular
                }
                guard let nextId = nextId, !isCollapsed else {
                    // 找不到下一个可选的Feed: 清除当前选中态
                    self.feedsViewModel.setSelected(feedId: nil)
                    return
                }
                // 有效的下一个可选Feed: 模拟点击跳转
                // 上一个Feed的选中态会在BaseFeedsViewModel.subscribePadHandlers中被清除
                if let index = self.feedsViewModel.allItems().firstIndex(where: { $0.feedPreview.id == nextId }) {
                    self.tableView.delegate?.tableView?(self.tableView,
                                                        didSelectRowAt: IndexPath(row: index, section: 0))
                }
            }
        }
    }

    enum FeedSelectionCons {
        static let delaySecond: CGFloat = 0.3
    }
}
