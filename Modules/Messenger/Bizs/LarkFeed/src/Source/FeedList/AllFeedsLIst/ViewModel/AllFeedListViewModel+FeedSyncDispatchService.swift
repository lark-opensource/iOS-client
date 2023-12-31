//
//  AllFeedListViewModel+FeedSyncDispatchService.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

/// 支持FeedSyncDispatchService，获取内存中Main Feed列表所有Feed
/// 后续业务移除或者接口变更，可直接移除此实现
import Foundation
extension AllFeedListViewModel {
    func currentFeedsCellVM() -> [FeedCardCellViewModel] {
        provider.getItemsArray()
    }
}
