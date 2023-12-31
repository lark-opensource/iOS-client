//
//  ShortcutsViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import LarkSDKInterface
import LarkModel
import LKCommonsLogging
import RustPB
import RunloopTools
import LarkAccountInterface
import LarkContainer
import LarkOpenFeed

enum ShortcutUpdateSource {
    case load
    case push
}

final class ShortcutsViewModel: UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }
    @ScopedInjectedLazy var feedCardModuleManager: FeedCardModuleManager?

    // 私有缓存数据源
    private var dataCache: [ShortcutCellViewModel] = []
    // 缓存数据源字典, 用来提高feed push更新效率
    private var dataCacheDict: [String: ShortcutCellViewModel] = [:]

    // UI数据源: 与UI数据一致
    private var dataRelay = BehaviorRelay<ShortcutViewModelUpdate>(value: ShortcutViewModelUpdate.empty())
    // 对外部开放的UI数据
    var dataSource: [ShortcutCellViewModel] {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        return dataRelay.value.snapshot
    }

    var update: ShortcutViewModelUpdate {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        return dataRelay.value
    }

    var dataDriver: Driver<ShortcutViewModelUpdate> {
        return dataRelay.asDriver()
    }

    // UI上可见的置顶数量
    var visibleCount: Int {
        // 收起状态 && 置顶个数超出单行，这时候只展示第一行
        Self.computeVisibleCount(dataSource.count, expanded: expanded, itemMaxNumber: itemMaxNumber)
    }

    // 是否显示
    var displayRelay = BehaviorRelay<Bool>(value: false)
    // 高度变化
    var updateHeightRelay = BehaviorRelay<CGFloat>(value: 0)

    var expandMoreViewModel = ShortcutExpandMoreViewModel()
    // 展开收起的操作类型
    var expandCollapseType: ShortcutExpandCollapseType = .none

    // blocking：当用户操作UI时，使用串行OperationQueue挂起刷新UI的任务
    let queue = OperationQueue()

    // 收起/展开的状态相关
    var expanded: Bool {
        get {
            expandMoreViewModel.isExpanded
        }
        set {
            guard expandMoreViewModel.display else { return }
            updateExpandMoreViewModel(expanded: newValue)
            fireViewHeight()
            if newValue { preloadChatFeed() }
            FeedTeaTrack.trackShorcutFold(type: expandCollapseType) // 埋点
        }
    }

    // 用于计算 layout
    var containerWidth: CGFloat = 0 {
        didSet {
            if containerWidth != oldValue {
                fullReload()
            }
        }
    }

    var isFirstExpand = false

    let disposeBag: DisposeBag = DisposeBag()
    let dependency: ShortCutViewModelDependency
    var userId: String { dependency.userResolver.userID }

    init(dependency: ShortCutViewModelDependency) {
        self.dependency = dependency
        setup()
    }

    private func setup() {
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        loadShortcutsCache()
        subscribePushHandlers()
        loadFirstPageShortcuts()
    }
}

// 应该放在ShortcutsViewModel+Data文件里，但是因为dataCache权限的问题，只能放在主类文件里了
extension ShortcutsViewModel {
    // shortcut的load或push
    func handleDataFromShortcut(_ shortcutResults: [ShortcutResult], source: ShortcutUpdateSource) {
        queue.addOperation { [weak self] in
            guard let `self` = self else { return }
            let newViewModels = shortcutResults.compactMap({ [weak self] result -> ShortcutCellViewModel? in
                guard let self = self else { return nil }
                if FeedPreviewCheckerService.checkIfInvalidFeed(result.preview.id,
                                                        result.preview.basicMeta.checker,
                                                        self.userResolver.userID) {
                    return nil
                }
                if let feedCardModuleManager = self.feedCardModuleManager {
                    return ShortcutCellViewModel(
                        result: result,
                        userResolver: self.userResolver,
                        feedCardModuleManager: feedCardModuleManager)
                }
                return nil
            })

            // 更新容器构造逻辑
            var update: ShortcutViewModelUpdate
            switch source {
            case .push:
                // 在FG开启的情况下shortcut push走自动diff
                update = ShortcutViewModelUpdate.autoDiffing(newViewModels)
            default:
                // shortcut load或FG关闭走全量刷新
                update = ShortcutViewModelUpdate.full(newViewModels)
            }

            // 替换数据源
            self.dataCache = newViewModels
            // 生成新的数据源字典
            self.dataCacheDict.removeAll(keepingCapacity: true)
            newViewModels.forEach { self.dataCacheDict[$0.id] = $0 }
            self.fireRefresh(update)
        }
    }

    // feed列表过来的数据
    func handleDataFromFeed(_ feeds: [FeedPreview]) {
        guard !feeds.isEmpty else { return }
        queue.addOperation { [weak self] in
            guard let `self` = self else { return }
            var changedIndices: [Int] = []
            for feed in feeds {
                if FeedPreviewCheckerService.checkIfInvalidFeed(feed.id, feed.basicMeta.checker, self.userResolver.userID) {
                    continue
                }
                // 先前置判断push是否命中shortcut, 如有必要再之后获取下标
                guard let shortcut = self.dataCacheDict[feed.id],
                    let index = self.dataCache.firstIndex(where: { $0.id == feed.id }) else {
                    continue
                }
                let oldFeed = shortcut.preview
                if feed.basicMeta.updateTime < oldFeed.basicMeta.updateTime {
                    continue
                }
                changedIndices.append(index)
                if let feedCardModuleManager = self.feedCardModuleManager {
                    let newShortcut = shortcut.update(feedPreview: feed, feedCardModuleManager: feedCardModuleManager)
                    self.dataCacheDict[feed.id] = newShortcut
                    self.dataCache[index] = newShortcut
                }
            }

            // 更新容器构造逻辑
            var update: ShortcutViewModelUpdate
            // feed push走手动diff
            let changeset = ShortcutViewModelUpdate.Changeset(
                reload: ShortcutViewModelUpdate.convertIntToIndexPath(changedIndices),
                insert: [],
                delete: []
            )
            if !changedIndices.isEmpty {
                FeedContext.log.info("feedlog/shortcut/dataflow/diff/manual. changeset reload: \(changeset.reload)")
            }
            update = ShortcutViewModelUpdate.manualDiffing(snapshot: self.dataCache, changeset: changeset)
            self.fireRefresh(update)
        }
    }

    func handleBadgeStyle() {
        // badgeStyle push走全量
        fullReload()
    }
}

extension ShortcutsViewModel {

    func fullReload() {
        queue.addOperation { [weak self] in
            guard let self = self else { return }
            let update = ShortcutViewModelUpdate.full(self.dataCache)
            self.fireRefresh(update)
        }
    }

    func refreshInMainThread(_ update: ShortcutViewModelUpdate) {
        FeedContext.log.info("feedlog/shortcut/dataflow/output. totalCount: \(update.snapshot.count)")
        var newExpanded = expanded
        // 更新命令生成逻辑
        // 保存之前的可见置顶数, 因为后续逻辑会修改expanded状态
        let formerVisibleCount = visibleCount

        // 通过是否需要自动收起区分更新逻辑
        if shouldAutomaticallyCollapse(update) {
            newExpanded = false
            // 特化：设定空刷新命令, 因为在expanded由true变false会触发fullReload()
            FeedContext.log.info("feedlog/shortcut/dataflow/output. set empty command because of automatic collapse")
            update.setEmptyReloadCommand()
        } else {
            // 生成刷新命令, 为diff传递需要的数据参数
            let currentVisibleCount = Self.computeVisibleCount(update.snapshot.count,
                                                               expanded: expanded,
                                                               itemMaxNumber: itemMaxNumber)
            update.generateReloadCommand(formerSnapshot: dataSource,
                                        formerVisibleCount: formerVisibleCount,
                                        currentVisibleCount: currentVisibleCount)
        }

        // 将最新快照连带刷新命令一起发出
        self.dataRelay.accept(update)

        // 更新展开/收起相关逻辑
        updateExpandMoreViewModel(update.snapshot, expanded: newExpanded)

        let isDisplay = !update.snapshot.isEmpty
        if !isDisplay {
            // 重置
            self.expandCollapseType = .none
        }
        self.displayRelay.accept(isDisplay)
        self.fireViewHeight()
    }

    /// 判断数据源刷新后置顶是否不再超过一行, 需要自动收起
    private func shouldAutomaticallyCollapse(_ update: ShortcutViewModelUpdate) -> Bool {
        if self.expanded && update.snapshot.count <= self.itemMaxNumber {
            // 需要自动收起，返回true：如果是展开状态，并且数据源只能单行展示了，需要设置expanded = false
            FeedContext.log.info("feedlog/shortcut/dataflow/autoCollapse")
            return true
        }
        // 无需自动收起
        return false
    }
}

/// For iPad
extension ShortcutsViewModel {
    // 是否需要跳过: 避免重复跳转
    func shouldSkip(feedId: String, traitCollection: UIUserInterfaceSizeClass?) -> Bool {
        return false
    }
}
