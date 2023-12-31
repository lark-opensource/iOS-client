//
//  FeedServiceForDocImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/7.
//

import Foundation
import RustPB
import LarkMessengerInterface

final class FeedServiceForDocImpl: FeedSyncDispatchServiceForDoc {
    let dependency: FeedServiceForDocDependency

    init(_ dependency: FeedServiceForDocDependency) {
        self.dependency = dependency
    }

    func isFeedCardShortcut(feedId: String) -> Bool {
        return dependency.isFeedCardShortcut(feedId: feedId)
    }

}
