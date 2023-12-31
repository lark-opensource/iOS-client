//
//  DocsFeedPreloadService.swift
//  SKCommon
//
//  Created by GuoXinyi on 2023/2/7.
//

import Foundation
import LarkOpenFeed
import SKFoundation
import LarkModel
import RunloopTools
import SKCommon
import SpaceInterface

final class FeedDocPreLoadListener: FeedListenerItem {
    private var preloadedDocsFeeds: ThreadSafeSet<String> = ThreadSafeSet<String>()
    public static var docHasInit: Bool = false
    var needListenListState: Bool = true

    func feedListStateChanged(feeds: [FeedPreview], state: FeedListState, context: FeedContextService?) {
        func _preload(feeds: [FeedPreview], state: FeedListState, context: FeedContextService?) {
            switch state {
            case .stopScrolling(_), .firstLoad, .switchFilterTab, .viewAppear:
                // firstLoad场景低端机不触发
                if case .firstLoad = state,
                    (UserScopeNoChangeFG.GXY.docsFeedFirstLoadPreloadEnable == false
                     || MobileClassify.mobileClassType == .lowMobile
                     || MobileClassify.mobileClassType == .unClassify) {
                    return
                }
                let urls = feeds.filter { $0.type == .docFeed }.map { $0.docURL }
                urls.forEach { url in
                    if !self.preloadedDocsFeeds.contains(url) {
                        self.preloadedDocsFeeds.insert(url)
                        if let docUrl = URL(string: url) {
                            (try? context?.userResolver.resolve(assert: DocSDKAPI.self))?
                                .preloadDocFeed(docUrl.absoluteString, from: FromSource.docsFeed.rawValue)
                        }
                    }
                }
            case .startScrolling:
                break
            @unknown default:
                break
            }
        }
        if FeedDocPreLoadListener.docHasInit == false {
            DispatchQueue.main.async {
                if UserScopeNoChangeFG.GXY.docsFeedPreloadIdleTaskEnable {
                    RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
                        guard self != nil else { return }
                        _preload(feeds: feeds, state: state, context: context)
                    }
                } else {
                    RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
                        guard self != nil else { return }
                        _preload(feeds: feeds, state: state, context: context)
                    }.waitCPUFree()
                }
            }
        } else {
            _preload(feeds: feeds, state: state, context: context)
        }
    }
}
