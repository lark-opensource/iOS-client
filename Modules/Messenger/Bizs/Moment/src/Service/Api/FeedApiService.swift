//
//  FeedApiService.swift
//  Moment
//
//  Created by zhuheng on 2021/1/6.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkModel
import TangramService

enum FeedApi { }
struct FeedApiResponseData {

    let nextPageToken: String

    private let _lastNewRecommendPostID: String

    var lastNewRecommendPostID: String? {
        /// 如果是最后一页的最后一条下面 不应该展示分割线（该条下面有没有更多内容的提示）
        if nextPageToken.isEmpty, posts.last?.id == _lastNewRecommendPostID {
            return nil
        }
        if _lastNewRecommendPostID.isEmpty {
            return nil
        }
        return _lastNewRecommendPostID
    }

    let posts: [RawData.PostEntity]

    let trackerInfo: MomentsTrackerInfo

    init(nextPageToken: String,
         lastNewRecommendPostID: String = "",
         posts: [RawData.PostEntity],
         trackerInfo: MomentsTrackerInfo) {
        self.nextPageToken = nextPageToken
        self._lastNewRecommendPostID = lastNewRecommendPostID
        self.posts = posts
        self.trackerInfo = trackerInfo
    }
}
extension FeedApi {
    typealias RxGetFeed = Observable<FeedApiResponseData>
    typealias RxListNotifications = Observable<(nextPageToken: String, notifications: [RawData.Notification])>
}

/// FEED 相关API
protocol FeedApiService {
    /// 推荐Tab, 时间序Feed
    func getRecommendFeed(byCount count: Int32,
                          useLocal: Bool,
                          pageToken: String,
                          tabID: String,
                          feedOrder: RawData.FeedOrder?,
                          manageMode: Moments_V1_ManageMode,
                          isIOSMock: Bool) -> FeedApi.RxGetFeed
    /// 关注Tab, 关注Feed
    func getFollowingFeed(byCount count: Int32, pageToken: String) -> FeedApi.RxGetFeed

    /// 获取所有轮播
    func listBroadcasts(mock: Bool) -> Observable<[RawData.Broadcast]>

    /// 分页获取通知
    func listNotifications(byCount count: Int32, pageToken: String) -> FeedApi.RxListNotifications
}

extension RustApiService {
    static func getPostEntity(postID: String, entities: RawData.Entitys) -> RawData.PostEntity? {
        if let post = entities.posts[postID] {
            return getPostEntity(post: post, entities: entities)
        }
        return nil
    }

    static func getPostEntity(post: RawData.Post, entities: RawData.Entitys) -> RawData.PostEntity {
        let user = entities.users[post.userID]
        let userExtraFields = entities.userExtraInfos[post.userID]?.profileFields ?? []
        let circle = entities.circles[post.circleID]
        var comments: [RawData.CommentEntity] = []
        post.commentSet.commentIds.forEach { (commitId) in
            if let comment = entities.comments[commitId],
               entities.users[comment.userID] != nil {
                let commentEntity = MomentsDataConverter.convertCommentToCommentEntitiy(entities: entities, comment: comment)
                comments.append(commentEntity)
            }

        }

        let reactionEntities = MomentsDataConverter.convertReactionsToReactionListEntities(entityId: post.id,
                                                                                           entities: entities,
                                                                                           reactions: post.reactionSet.reactions)
        if user == nil {
            Self.logger.warn("getPostEntity miss user \(post.id) \(post.userID)")
        }
        let categoryId = post.categoryIds.first ?? ""
        var inlineEntities = InlinePreviewEntityBody()
        if let inlinePair = entities.previewEntities[post.id] {
            inlineEntities = InlinePreviewEntity.transform(from: inlinePair)
        }
        let category = categoryId.isEmpty ? nil : entities.categories[categoryId]
        var postCategory: RawData.PostCategory?
        if let category = category {
            let adminUsers: [MomentUser] = category.adminUserIds.compactMap({ userId in
                return entities.users[userId]
            })
            postCategory = .init(category: category, adminUsers: adminUsers)
        }
        return RawData.PostEntity(post: post,
                                  user: user,
                                  userExtraFields: userExtraFields,
                                  circle: circle,
                                  category: postCategory,
                                  comments: comments,
                                  reactionListEntities: reactionEntities,
                                  inlinePreviewEntities: inlineEntities)
    }
}

extension RustApiService: FeedApiService {

    func getRecommendFeed(byCount count: Int32,
                          useLocal: Bool,
                          pageToken: String,
                          tabID: String,
                          feedOrder: RawData.FeedOrder?,
                          manageMode: Moments_V1_ManageMode,
                          isIOSMock: Bool) -> FeedApi.RxGetFeed {
        guard !isIOSMock else {
            return FeedApiMocker().getRecommendFeed(byCount: count, pageToken: pageToken)
        }

        var request = Moments_V1_GetTabFeedRequest()
        request.count = count
        request.useLocal = useLocal
        request.pageToken = pageToken
        request.tabID = tabID
        request.manageMode = manageMode
        if let feedOrder = feedOrder {
            request.feedOrder = feedOrder
        }

        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_GetTabFeedResponse) -> FeedApiResponseData in
                let cost = CACurrentMediaTime() - start
                var postEntitys: [RawData.PostEntity] = []
                guard !response.entities.users.isEmpty else {
                    return FeedApiResponseData(nextPageToken: "String",
                                               lastNewRecommendPostID: "",
                                               posts: [],
                                               trackerInfo: MomentsTrackerInfo(timeCost: cost))
                }
                response.entryList.forEach { (feedEntity) in
                    if let postEntity = RustApiService.getPostEntity(postID: feedEntity.postID, entities: response.entities) {
                        postEntitys.append(postEntity)
                    }
                }
                var lastNewRecommendPostID = ""
                if response.hasIsRecommend, response.isRecommend {
                    lastNewRecommendPostID = response.lastNewRecommendPostID
                }
                return FeedApiResponseData(nextPageToken: response.nextPageToken,
                                           lastNewRecommendPostID: lastNewRecommendPostID,
                                           posts: postEntitys,
                                           trackerInfo: MomentsTrackerInfo(timeCost: cost))

            }
    }

    func getFollowingFeed(byCount count: Int32, pageToken: String) -> FeedApi.RxGetFeed {
        var request = Moments_V1_GetFollowingFeedRequest()
        request.count = count
        request.pageToken = pageToken
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_GetFollowingFeedResponse) -> FeedApiResponseData in
                let cost = CACurrentMediaTime() - start
                var postEntitys: [RawData.PostEntity] = []
                response.entryList.forEach { (feedEntity) in
                    if let postEntity = RustApiService.getPostEntity(postID: feedEntity.postID, entities: response.entities) {
                        postEntitys.append(postEntity)
                    }
                }
                return FeedApiResponseData(nextPageToken: response.nextPageToken,
                                           posts: postEntitys,
                                           trackerInfo: MomentsTrackerInfo(timeCost: cost))
            }
    }

    func listNotifications(byCount count: Int32, pageToken: String) -> FeedApi.RxListNotifications {
        var request = Moments_V1_ListNotificationsRequest()
        request.count = count
        request.pageToken = pageToken
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListNotificationsResponse) -> (nextPageToken: String, comment: [RawData.Notification]) in
                return (response.nextPageToken, response.notifications)
            }
    }

    func listBroadcasts(mock: Bool) -> Observable<[RawData.Broadcast]> {
        if mock {
            func generateMockData(id: String, title: String) -> RawData.Broadcast {
                var data = RawData.Broadcast()
                data.postID = id
                data.title = title
                return data
            }
            var result: [RawData.Broadcast] = []
            result.append(generateMockData(id: "1", title: "test1"))
            result.append(generateMockData(id: "2", title: "test2"))
            result.append(generateMockData(id: "3", title: "test3"))
            return .just(result)
        } else {
            let request = Moments_V1_ListBroadcastsRequest()
            return client.sendAsyncRequest(request)
                .map { (response: Moments_V1_ListBroadcastsResponse) -> [RawData.Broadcast] in
                    return response.broadcasts
                }
        }
    }
}
