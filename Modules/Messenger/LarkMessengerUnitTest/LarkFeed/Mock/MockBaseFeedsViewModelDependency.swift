//
//  MockBaseFeedsViewModelDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/7.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
@testable import LarkFeed

// 公用BaseFeedsViewModelDependency Mock，如果需要对某个方法进行特化处理的话，可以通过builder的形式暴露出去
class MockBaseFeedsViewModelDependency: BaseFeedsViewModelDependency {
    var preloadFeedCardsBuilder: ((_ ids: [String]) -> Observable<Void>)!
    var preloadDocFeedBuilder: ((_ url: String) -> Void)!
    var setSelectedBuilder: ((_ feedId: String?) -> Void)!
    var getSelectedBuilder: (() -> String?)!
    var moveToDoneBuilder: ((_ feedId: String, _ entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void>)?
    var createShortcutsBuilder: ((_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>)?
    var deleteShortcutsBuilder: ((_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>)?
    var markFeedCardBuilder: ((_ id: String, _ isDelayed: Bool) -> Observable<FeedPreview>)?

    var isAllLogEnabled: Bool {
        true
    }

    func moveToDone(feedId: String, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        return moveToDoneBuilder!(feedId, entityType)
    }

    func createShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        return createShortcutsBuilder!(shortcuts)
    }

    func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        return deleteShortcutsBuilder!(shortcuts)
    }

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedPreview> {
        markFeedCardBuilder!(id, isDelayed)
    }

    /// 预加载Chat
    func preloadFeedCards(by ids: [String]) -> Observable<Void> {
        preloadFeedCardsBuilder(ids)
    }

    /// 预加载Doc
    func preloadDocFeed(_ url: String) {
        preloadDocFeedBuilder(url)
    }

    /// iPad选中态监听
    func observeSelect() -> Observable<String?> {
        .just(nil)
    }

    /// 设置Feed选中
    func setSelected(feedId: String?) {
        setSelectedBuilder(feedId)
    }

    /// 获取上一次选中的 ID
    func selectedRecordID(prev: Bool) -> String? {
        return nil
    }

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String? {
        getSelectedBuilder()
    }
}
