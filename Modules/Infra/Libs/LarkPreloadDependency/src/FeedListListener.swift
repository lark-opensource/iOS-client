//
//  FeedListListener.swift
//  LarkPreloadDependency
//
//  Created by huanglx on 2023/5/15.
//

import Foundation
import LarkOpenFeed
import LarkModel
import LarkPreload

final class FeedListListener: FeedListenerItem {
    var needListenListState: Bool = true
    func feedListStateChanged(feeds: [FeedPreview], state: FeedListState, context: FeedContextService?) {
        if case .startScrolling = state {   //开始滚动
            CoreSceneMointor.feedIsScrolling = true
        } else if case .stopScrolling(_) = state {   //停止滚动
            CoreSceneMointor.feedIsScrolling = false
        } else {
            CoreSceneMointor.feedIsScrolling = false
        }
    }
}
