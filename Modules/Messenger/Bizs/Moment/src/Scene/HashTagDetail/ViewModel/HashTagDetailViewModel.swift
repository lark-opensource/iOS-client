//
//  HashTagDetailViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/6/30.
//

import Foundation
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging
import LarkMessageCore

final class HashTagDetailViewModel: PostListDetailViewModel {
    let hashTagOrder: RawData.hashTagOrder
    @ScopedInjectedLazy private var hashTagApi: HashTagApiService?
    let hashTagId: String
    private var lastDataFirstPostId: String?

    init(userResolver: UserResolver,
         hashTagOrder: RawData.hashTagOrder,
         manageMode: RawData.ManageMode,
         hashTagId: String,
         context: BaseMomentContext,
         userPushCenter: PushNotificationCenter) {
        self.hashTagOrder = hashTagOrder
        self.hashTagId = hashTagId
        super.init(userResolver: userResolver,
                   context: context,
                   manageMode: manageMode,
                   userPushCenter: userPushCenter)
    }
    override func fetchPosts(pageToken: String = "", count: Int32 = FeedList.pageCount) -> FeedApi.RxGetFeed {
        return hashTagApi?.getHashTagListPost(byCount: count, pageToken: pageToken, hashTagId: hashTagId, hashTagOrder: hashTagOrder) ?? .empty()
    }

    override func businessType() -> String {
        return "hash tag detail"
    }

    override func getPageType() -> MomentsTracer.PageType {
        return .hashtag(hashTagId)
    }

    override func willRefreshPostData(posts: [RawData.PostEntity], byUserAction: Bool) -> PostTipStyle? {
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "moments.new.refresh") else { return nil }
        guard !posts.isEmpty else {
            return byUserAction ? .empty : nil
        }
        Self.logger.info("willRefreshPostData -- lastDataFirstPostId \(self.lastDataFirstPostId) - new \(posts.first?.postId) - \(byUserAction)")
        if let lastDataFirstPostId = self.lastDataFirstPostId {
            let sameData = lastDataFirstPostId == (posts.first?.postId ?? "")
            self.lastDataFirstPostId = posts.first?.postId
            let res: PostTipStyle = !sameData ? .success : .empty
            if res == .empty, !byUserAction {
                return nil
            }
            return res
        } else {
            ///hashtag 第一次进入 不给提示
            self.lastDataFirstPostId = posts.first?.postId
            return nil
        }
    }
    override func getPageDetail() -> MomentsTracer.PageDetail? {
        switch hashTagOrder {
        case .participateCount:
            return .hashtag_hot
        case .createTimeDesc:
            return .hashtag_new
        case .recommend, .recommendV2:
            return .hashtag_recommend
        case .unknown:
            return nil
        @unknown default:
            return nil
        }
    }

    override func getFeedUpdateItem(isRefresh: Bool) -> MomentsFeedUpdateItem {
        let item = MomentsFeedUpdateItem(biz: .Moments,
                                         scene: .MoFeed,
                                         event: isRefresh ? .refreshFeed : .loadMoreFeed,
                                         page: "hashtag")
        item.order = hashTagOrder.rawValue
        return item
    }

    override func showPostFromCategory() -> Bool {
        return true
    }
}
