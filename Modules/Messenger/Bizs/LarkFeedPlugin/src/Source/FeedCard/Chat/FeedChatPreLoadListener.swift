//
//  FeedChatPreLoadListener.swift
//  LarkFeedPlugin
//
//  Created by chaishenghua on 2023/2/8.
//

import Foundation
import LarkModel
import LarkSDKInterface
import RxSwift
import LarkOpenFeed

final class FeedChatPreLoadListener: FeedListenerItem {
    let disposeBag = DisposeBag()
    let needListenListState: Bool = true

    func feedListStateChanged(feeds: [FeedPreview], state: FeedListState, context: FeedContextService?) {
        switch state {
        case .stopScrolling(_), .switchFilterTab, .firstLoad, .viewAppear:
            guard let feedAPI = try? context?.userResolver.resolve(assert: FeedAPI.self) else { return }
            let chatIds = feeds.filter({ $0.basicMeta.feedPreviewPBType == .chat })
                .map({ $0.id })
            var feedPosition: Int32?
            if case .stopScrolling(let position) = state, let position = position {
                feedPosition = Int32(position)
            }
            feedAPI.preloadFeedCards(by: chatIds, feedPosition: feedPosition)
                .subscribe()
                .disposed(by: self.disposeBag)
        case .startScrolling:
            break
        @unknown default:
            break
        }
    }
}
