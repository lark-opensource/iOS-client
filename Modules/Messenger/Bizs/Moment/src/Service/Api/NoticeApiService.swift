//
//  NoticeApiService.swift
//  Moment
//
//  Created by bytedance on 2021/2/25.
//
import UIKit
import Foundation
import RustPB
import RxSwift
import ServerPB
import LarkModel
import TangramService

enum NoticeApi { }
extension NoticeApi {
    typealias RxGetNotice = Observable<(nextPageToken: String, entitys: [RawData.NoticeEntity], trackerInfo: MomentsTrackerInfo)>
}
/// Notic 相关API
protocol NoticeApiService {
    func getListNotificationsWithType(_ type: NoticeList.SourceType, pageToken: String, count: Int32) -> NoticeApi.RxGetNotice
    func sendReadNotificationsRequest(category: NoticeList.SourceType, notificationID: String) -> Observable<Void>
    func getBadgeRequest() -> Observable<MomentsBadgeInfo>
}

extension RustApiService: NoticeApiService {
    func getListNotificationsWithType(_ categoryType: NoticeList.SourceType, pageToken: String, count: Int32) -> NoticeApi.RxGetNotice {
        var request = Moments_V1_ListNotificationsRequest()
        request.pageToken = pageToken
        request.count = count
        if categoryType == .message {
            request.notificationCategory = Moments_V1_Notification.Category.messageCategory
        } else if categoryType == .reaction {
            request.notificationCategory = Moments_V1_Notification.Category.reactionCategory
        }
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListNotificationsResponse) -> (nextPageToken: String, posts: [RawData.NoticeEntity], trackerInfo: MomentsTrackerInfo) in
                let cost = CACurrentMediaTime() - start
                var postEntitys: [RawData.NoticeEntity] = []
                response.notifications.forEach { [weak self] (not: RawData.Notification) in
                    if let noticeEntity = self?.transformNotToNoticeEntity(not: not, response: response, categoryType: categoryType) {
                        postEntitys.append(noticeEntity)
                    }
                }
                return (response.nextPageToken, postEntitys, MomentsTrackerInfo(timeCost: cost))
            }
    }

    func sendReadNotificationsRequest(category: NoticeList.SourceType, notificationID: String) -> Observable<Void> {
        var request = RustPB.Moments_V1_PutReadNotificationsRequest()
        request.notificationID = notificationID
        switch category {
        case .message:
            request.notificationCategory = .messageCategory
        case.reaction:
            request.notificationCategory = .reactionCategory
        }
        return client.sendAsyncRequest(request).map { (_) -> Void in
            return
        }
    }
    func getBadgeRequest() -> Observable<MomentsBadgeInfo> {
        let request = ServerPB.ServerPB_Moments_GetBadgeRequest()
        let ob: Observable<ServerPB.ServerPB_Moments_GetBadgeResponse> = client.sendPassThroughAsyncRequest(request, serCommand: .momentsGetBadge)
        return ob.map { [weak self] (response) -> MomentsBadgeInfo in
            guard let self = self else {
                return MomentsBadgeInfo(personalUserBadge: .init(), officialUsersBadge: [:])
            }
            var result = MomentsBadgeInfo(personalUserBadge: self.transfromMomentsBadgeCountFromServerPBToRustPB(response.notificationCount),
                                          officialUsersBadge: response.officialUserNotificationCounts.compactMapValues({ notificationCount in
                return self.transfromMomentsBadgeCountFromServerPBToRustPB(notificationCount)
            }))
            return result
        }
    }

    private func transfromMomentsBadgeCountFromServerPBToRustPB(_ originData: ServerPB_Moments_entities_NotificationCount) -> RawData.MomentsBadgeCount {
        var result = RawData.MomentsBadgeCount()
        result.messageCount = originData.messageCount
        result.messageReadTs = originData.messageReadTs
        result.reactionCount = originData.reactionCount
        result.reactionReadTs = originData.reactionReadTs
        return result
    }

    func transformNotToNoticeEntity(not: RawData.Notification, response: Moments_V1_ListNotificationsResponse, categoryType: NoticeList.SourceType) -> RawData.NoticeEntity? {
        if not.type == .follower {
            let user = response.entities.users[not.followerData.followerID]
            let followerEntity = RawData.NoticeFollowerEntity(followerUser: user,
                                                              hadFollow: user?.isCurrentUserFollowing ?? false)
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .follower(followerEntity: followerEntity),
                                        createTime: not.createTimeMsec)
        } else if not.type == .postReaction {
            let postEntity = RustApiService.getPostEntity(postID: not.postReactionData.postID, entities: response.entities)
            let postReactionEntity = RawData.NoticePostReactionEntity(postEntity: postEntity,
                                                                      reactionType: not.postReactionData.actionType,
                                                                      reactionUser: response.entities.users[not.postReactionData.reactionUserID])
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .postReaction(postReactionEntity: postReactionEntity),
                                        createTime: not.createTimeMsec)
        } else if not.type == .commentReaction {
            let postEntity = RustApiService.getPostEntity(postID: not.commentReactionData.postID, entities: response.entities)
            let commentReactionEntity = RawData.NoticeCommentReactionEntity(postEntity: postEntity,
                                                                            comment: response.entities.comments[not.commentReactionData.commentID],
                                                                            reactionType: not.commentReactionData.actionType,
                                                                            reactionUser: response.entities.users[not.commentReactionData.reactionUserID])
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .commentReaction(commentReactionEntity: commentReactionEntity),
                                        createTime: not.createTimeMsec)

        } else if not.type == .comment {
            let postEntity = RustApiService.getPostEntity(postID: not.commentData.postID, entities: response.entities)
            var inlineEntities = InlinePreviewEntityBody()
            if let inlinePair = response.entities.previewEntities[not.commentData.commentID] {
                inlineEntities += InlinePreviewEntity.transform(from: inlinePair)
            }
            let commentEntity = RawData.NoticeCommentEntity(postEntity: postEntity,
                                                            comment: response.entities.comments[not.commentData.commentID],
                                                            user: response.entities.users[not.commentData.userID],
                                                            inlinePreviewEntities: inlineEntities)
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .comment(commentEntity: commentEntity),
                                        createTime: not.createTimeMsec)

        } else if not.type == .reply {
            let postEntity = RustApiService.getPostEntity(postID: not.replyData.postID, entities: response.entities)
            var inlineEntities = InlinePreviewEntityBody()
            if let postID = postEntity?.post.id, let inlinePair = response.entities.previewEntities[postID] {
                inlineEntities += InlinePreviewEntity.transform(from: inlinePair)
            }
            if let inlinePair = response.entities.previewEntities[not.replyData.commentID] {
                inlineEntities += InlinePreviewEntity.transform(from: inlinePair)
            }
            if let inlinePair = response.entities.previewEntities[not.replyData.replyCommentID] {
                inlineEntities += InlinePreviewEntity.transform(from: inlinePair)
            }
            let replyEntity = RawData.NoticeReplyEntity(postEntity: postEntity,
                                                        comment: response.entities.comments[not.replyData.commentID],
                                                        replyComment: response.entities.comments[not.replyData.replyCommentID],
                                                        user: response.entities.users[not.replyData.userID],
                                                        inlinePreviewEntities: inlineEntities)
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .reply(replyEntity: replyEntity),
                                        createTime: not.createTimeMsec)

        } else if not.type == .atInPost {
            let postEntity = RustApiService.getPostEntity(postID: not.atInPostData.postID, entities: response.entities)
            let atInPostEntity = RawData.NoticeAtInPostEntity(postEntity: postEntity,
                                                              user: response.entities.users[not.atInPostData.postUserID])
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .atInPost(atInPostEntity: atInPostEntity),
                                        createTime: not.createTimeMsec)
        } else if not.type == .atInComment {
            let postEntity = RustApiService.getPostEntity(postID: not.atInCommentData.postID, entities: response.entities)
            var inlineEntities = InlinePreviewEntityBody()
            if let inlinePair = response.entities.previewEntities[not.atInCommentData.commentID] {
                inlineEntities += InlinePreviewEntity.transform(from: inlinePair)
            }
            let atInCommentEntity = RawData.NoticeAtInCommentEntity(postEntity: postEntity,
                                                                    comment: response.entities.comments[not.atInCommentData.commentID],
                                                                    user: response.entities.users[not.atInCommentData.commentUserID],
                                                                    inlinePreviewEntities: inlineEntities)
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .atInComment(atInCommentEntity: atInCommentEntity),
                                        createTime: not.createTimeMsec)
        } else if not.type == .unknown {
            return RawData.NoticeEntity(id: not.id,
                                        category: categoryType,
                                        noticeType: .unknown,
                                        createTime: not.createTimeMsec)
        }
        return nil
    }
}

struct MomentsBadgeInfo {
    var personalUserBadge: RawData.MomentsBadgeCount
    var officialUsersBadge: [String: RawData.MomentsBadgeCount]
}
