//
//  FeedListViewController+EETroubleKiller.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import EETroubleKiller
import LarkFeedBase

/// 截屏/录屏日志
extension FeedListViewController: CaptureProtocol & DomainProtocol {
    var domainKey: [String: String] {
        guard let tabVM = feedsViewModel as? FeedListViewModel else { return [:] }
        return ["type": "",
            "feedCount": "\(tabVM.allItems().count)",
            "badgeStyle": "\(FeedBadgeBaseConfig.badgeStyle)"]
    }
}
