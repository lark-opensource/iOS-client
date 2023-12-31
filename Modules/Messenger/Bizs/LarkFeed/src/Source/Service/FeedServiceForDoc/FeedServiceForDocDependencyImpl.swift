//
//  FeedServiceForDocDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/7.
//

import Foundation
final class FeedServiceForDocDependencyImpl: FeedServiceForDocDependency {
    let shortcutsViewModelProvider: () -> ShortcutsViewModel?
    lazy var shortcutsViewModel: ShortcutsViewModel? = {
        shortcutsViewModelProvider()
    }()

    init(shortcutsViewModelProvider: @escaping () -> ShortcutsViewModel?) {
        self.shortcutsViewModelProvider = shortcutsViewModelProvider
    }

    func isFeedCardShortcut(feedId: String) -> Bool {
        assert(Thread.isMainThread, "Must in main thread.")
        guard shortcutsViewModel?.dataSource.first(where: { $0.feedID == feedId }) != nil else { return false }
        return true
    }
}
