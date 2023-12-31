//
//  ShortcutsViewModel+Data.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import RustPB
import RunloopTools
import LarkModel

// MARK: 数据获取及处理
extension ShortcutsViewModel {

    /* shortcut 数据更新消息源
     1. shortcut: 包括pull和push消息
     2. feed: 仅push消息
     */

    // 拉取数据
    func loadFirstPageShortcuts() {
        FeedPerfTrack.trackFeedLoadShortcutTimeStart()
        FeedSlardarTrack.trackFeedLoadShortcutTimeStart()
        var firstResponse = true
        var loadShortcutsFromLocal = self.dependency.loadShortcuts(strategy: .local)
        var loadShortcutsFromServer = self.dependency.loadShortcuts(strategy: .forceServer)
        Observable.merge(loadShortcutsFromLocal, loadShortcutsFromServer).subscribe(onNext: { [weak self] (shortcuts: [ShortcutResult], contextID) in
            guard let `self` = self else { return }
            if firstResponse {
                // 本地拉取置顶 耗时
                firstResponse.toggle()
                FeedPerfTrack.trackFeedLoadShortcutTimeEnd()
                FeedPerfTrack.trackShortcutSetContextID(contextID: contextID)
            } else {
                // 服务器返回 ShortCut 耗时
                FeedSlardarTrack.trackFeedLoadShortcutTimeEnd()
            }
            self.handleDataFromShortcut(shortcuts, source: .load)
        }).disposed(by: disposeBag)
    }

    // Push 监听
    func subscribePushHandlers() {
        // 推给Shortcuts的更新数据，不会出现单个Shortcut，每次都是全量更新
        dependency.pushShortcuts.subscribe(onNext: { [weak self] pushShortcuts in
            self?.handleDataFromShortcut(pushShortcuts.shortcuts, source: .push)
        }).disposed(by: disposeBag)

        dependency.badgeStyleObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.handleBadgeStyle()
            }).disposed(by: disposeBag)

        dependency.pushFeedPreview.subscribe(onNext: { [weak self] (pushFeedPreview) in
            guard let self = self else { return }
            var feeds: [FeedPreview]
            let type: FeedFilterType = .shortcuts
            feeds = pushFeedPreview.updateFeeds.compactMap { (_: String, value: PushFeedInfo) -> FeedPreview? in
                let feed = value.feedPreview
                guard value.types.contains(type) else { return nil }
                return feed
            }
            if !feeds.isEmpty {
                self.handleDataFromFeed(feeds)
            }
        }).disposed(by: disposeBag)

        RunloopDispatcher.shared.addTask {
            // 监听Application通知
            self.observeApplicationNotification()
        }
    }

    // 发送信号
    func fireRefresh(_ update: ShortcutViewModelUpdate) {
        if Thread.isMainThread {
            self.refreshInMainThread(update)
        } else {
            DispatchQueue.main.async {
                self.refreshInMainThread(update)
            }
        }
    }

    // 更新ExpandMoreViewModel
    func updateExpandMoreViewModel(_ cellViewModels: [ShortcutCellViewModel]? = nil, expanded: Bool) {
        var shortcutCellViewModels: [ShortcutCellViewModel]
        if let vms = cellViewModels {
            shortcutCellViewModels = vms
        } else {
            shortcutCellViewModels = dataSource
        }

        var moreShortcuts: [ShortcutCellViewModel] = []
        let hasExpandedItems = shortcutCellViewModels.count > itemMaxNumber
        if hasExpandedItems && itemMaxNumber >= 2 {
            moreShortcuts = Array(shortcutCellViewModels.suffix(from: itemMaxNumber - 1))
        }

        expandMoreViewModel.update(moreShortcuts, expanded: expanded)
    }
}
