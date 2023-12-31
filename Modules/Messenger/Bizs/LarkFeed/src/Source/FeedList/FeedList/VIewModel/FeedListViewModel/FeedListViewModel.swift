//
//  FeedListViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import RxDataSources
import AnimatedTabBar
import RxCocoa
import ThreadSafeDataStructure
import LarkNavigation
import LarkModel
import LarkTab
import LarkMonitor
import LarkUIKit
import LarkContainer
import LarkOpenFeed
import UniverseDesignIcon

class FeedListViewModel: BaseFeedsViewModel {

    func feedType() -> Basic_V1_FeedCard.FeedType {
        return .inbox
    }

    override var bizType: FeedBizType {
        return .inbox
    }

    // 当前的filter类型
    var filterType: Feed_V1_FeedFilter.TypeEnum
    var isActive: Bool = false
    var isFetchUnreading: Bool = false

    var selectedID: String?

    // nextCursor存在多线程访问，目前cursors的更新都在queue里面，串行访问线程安全
    var nextCursor: FeedCursor?

    // 当某条消息变成已读后暂时保留，用户离开当前tab后再回来才自动清除
    var dirtyFeeds: Set<String> = []
    // updateOrRemove action 依赖于 temp，所以 tempRemoveIds 始终是 dirtyFeeds 的子集。用于切tab移除feed
    var tempRemoveIds: Set<String> = []

    let dependency: FeedListViewModelDependency

    init(filterType: Feed_V1_FeedFilter.TypeEnum,
         dependency: FeedListViewModelDependency,
         baseDependency: BaseFeedsViewModelDependency,
         feedContext: FeedContextService) {
        self.dependency = dependency
        self.filterType = filterType
        super.init(baseDependency: baseDependency, feedContext: feedContext)
        setup()
    }

    private func setup() {
        subscribePushFeedPreview()
        getFeedCards()
    }

    func willActive() {
        isActive = true
        // 切换后的vm强制resume queue，防止数据不上屏
        changeQueueState(false, taskType: .switchFilterTab)
    }

    func willResignActive() {
        isActive = false
        if Feed.Feature(userResolver).groupSettingEnable {
            removeTempFeed()
        } else {
            removeDirtyFeed()
        }
        storeSelectedId()
    }

    // TODO: 端上不需要过滤数据
    override func displayFilter(_ item: FeedCardCellViewModel) -> Bool {
        return item.isShow
    }

    override func hasMoreFeeds() -> Bool {
        return checkHasMoreFeeds(cursor: getLocalCursor())
    }

    override func loadMore(trace: FeedListTrace) -> Observable<Bool> {
        return _loadMore(trace: trace)
    }

    func getFeedCards() {
        _getFeedCards()
    }

    func authData(verifyKey: String, trace: FeedListTrace) -> Bool {
        return true
    }

    // 记录当前filter下，被选中的feedID
    func storeSelectedId() {
        guard FeedSelectionEnable else { return }
        selectedID = self.findCurrentSelectedVM()?.feedPreview.id
    }
}
