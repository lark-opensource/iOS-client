//
//  AllFeedListViewModel+Shortcut.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/9/17.
//

import Foundation
import LarkModel
import RxSwift
import RxCocoa

extension AllFeedListViewModel {
    func updateShortcut(_ feeds: [FeedPreview]) {
        // TODO: 需要rust一起优化
        let shortcuts = feeds.compactMap { feed -> FeedPreview? in
            guard feed.basicMeta.isShortcut else { return nil }
            return feed
        }
        if !shortcuts.isEmpty {
            feedPreviewSubject.onNext(shortcuts)
        }
    }
}
