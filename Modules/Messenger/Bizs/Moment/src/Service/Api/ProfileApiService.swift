//
//  ProfileApiService.swift
//  Moment
//
//  Created by bytedance on 2021/3/9.
//

import Foundation
import UIKit
import RxSwift
import RustPB
import ServerPB

enum ProfileApi { }
extension ProfileApi {
    typealias RxGetPost = Observable<(nextPageToken: String, posts: [RawData.PostEntity], trackerInfo: MomentsTrackerInfo)>
    typealias RxFollowResponse = Observable<(nextPageToken: String, users: [MomentUser])>
    typealias RxProfileResponse = Observable<(profile: RawData.UserProfileEntity, users: [MomentUser], trackerInfo: MomentsTrackerInfo)>
    typealias RxGetActivityEntry = Observable<(nextPageToken: String, activityEntry: [RawData.ProfileActivityEntry])>
}

/// profile页 相关API
protocol ProfileApiService {
    func getUserPost(byCount count: Int32, pageToken: String, userId: String) -> ProfileApi.RxGetPost
    func getUserFollowersList(byCount count: Int32, userId: String, pageToken: String) -> ProfileApi.RxFollowResponse
    func getUserFollowingsList(byCount count: Int32, userId: String, pageToken: String) -> ProfileApi.RxFollowResponse
    func getUserProfile(userId: String, useLocal: Bool) -> ProfileApi.RxProfileResponse
    func updateProfileBackgroundImageBy(key: String) -> Observable<Void>
    func getActivityEntry(byCount count: Int32,
                          pageToken: String,
                          userId: String,
                          userType: RawData.UserType) -> ProfileApi.RxGetActivityEntry
    func getGetNicknameProfileFor(userID: String) -> Observable<RawData.NicknameProfile>
}
///TODO：李洛斌 这个是否合理 是否需要清空 写在vc里面
private var baseIndex: Int64 = 0
extension RustApiService: ProfileApiService {
    /// 当前cell的Index
    func getUserPost(byCount count: Int32, pageToken: String, userId: String) -> ProfileApi.RxGetPost {
        var request = Moments_V1_ListUserPostsRequest()
        request.count = count
        request.pageToken = pageToken
        request.userID = userId
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListUserPostsResponse) -> (nextPageToken: String, posts: [RawData.PostEntity], trackerInfo: MomentsTrackerInfo) in
                let cost = CACurrentMediaTime() - start
                var postEntitys: [RawData.PostEntity] = []
                response.entryList.forEach { (feedEntity) in
                    if let postEntity = RustApiService.getPostEntity(postID: feedEntity.postID, entities: response.entities) {
                        postEntitys.append(postEntity)
                    }
                }
                return (response.nextPageToken, postEntitys, MomentsTrackerInfo(timeCost: cost))
            }
    }

    /// 被关注的人
    func getUserFollowersList(byCount count: Int32, userId: String, pageToken: String) -> ProfileApi.RxFollowResponse {
        var request = Moments_V1_ListUserFollowersRequest()
        request.count = count
        request.userID = userId
        request.pageToken = pageToken
        return client.sendAsyncRequest(request).map { (response: Moments_V1_ListUserFollowersResponse) -> (nextPageToken: String, users: [MomentUser]) in
            var users: [MomentUser] = []
            response.followers.forEach { (follower: Moments_V1_Follower) in
                if let user = response.entities.users[follower.userID] {
                    users.append(user)
                }
            }
            return (response.nextPageToken, users)
        }
    }

    /// 关注的人
    func getUserFollowingsList(byCount count: Int32, userId: String, pageToken: String) -> ProfileApi.RxFollowResponse {
        var request = Moments_V1_ListUserFollowingsRequest()
        request.count = count
        request.userID = userId
        request.pageToken = pageToken
        return client.sendAsyncRequest(request).map { (response: Moments_V1_ListUserFollowingsResponse) -> (nextPageToken: String, users: [MomentUser]) in
            var users: [MomentUser] = []
            response.followingUsers.forEach { (follower: Moments_V1_FollowingUser) in
                if let user = response.entities.users[follower.userID] {
                    users.append(user)
                }
            }
            return (response.nextPageToken, users)
        }
    }

    /// 获取用户的profile
    func getUserProfile(userId: String, useLocal: Bool) -> ProfileApi.RxProfileResponse {
        var request = Moments_V1_GetUserProfileRequest()
        request.userID = userId
        request.useLocal = useLocal
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request).map { (reponse: Moments_V1_GetUserProfileResponse) -> (profile: RawData.UserProfileEntity,
                                                                                                       users: [MomentUser],
                                                                                                       trackerInfo: MomentsTrackerInfo) in
            let cost = CACurrentMediaTime() - start
            var users: [MomentUser] = []
            reponse.followingUsers.forEach { (user) in
                if let user = reponse.entities.users[user.userID] {
                    users.append(user)
                }
            }
            let entity = RawData.UserProfileEntity(user: reponse.entities.users[userId],
                                                   userProfile: reponse.profile)
            return (entity, users, MomentsTrackerInfo(timeCost: cost))
        }
    }

    /// 上传图片
    func updateProfileBackgroundImageBy(key: String) -> Observable<Void> {
        var request = Moments_V1_UpdateProfileBackgroundImageRequest()
        request.profileBackgroundImageKey = key
        return client.sendAsyncRequest(request).map { (_) -> Void in
            return
        }
    }

    func getActivityEntry(byCount count: Int32,
                          pageToken: String,
                          userId: String,
                          userType: RawData.UserType) -> ProfileApi.RxGetActivityEntry {
        var request = RustPB.Moments_V1_ListUserActivitiesRequest()
        request.count = count
        request.userType = userType
        request.pageToken = pageToken
        request.userID = userId
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListUserActivitiesResponse) -> (nextPageToken: String, activityEntry: [RawData.ProfileActivityEntry]) in
                var activityEntrys: [RawData.ProfileActivityEntry] = []
                let currentUser = response.entities.users[userId]
                response.entryList.forEach { obj in
                    let entry = RawData.ProfileActivityEntry(entryId: baseIndex,
                                                             currentUser: currentUser,
                                                             type: RustApiService.getProfileEntryType(response: response,
                                                                                                      activityEntry: obj),
                                                             activityEntry: obj)
                    activityEntrys.append(entry)
                    baseIndex += 1
                }
                return (response.nextPageToken, activityEntrys)
            }
    }

    /// 获取花名信息
    func getGetNicknameProfileFor(userID: String) -> Observable<RawData.NicknameProfile> {
        var request = ServerPB.ServerPB_Moments_GetNicknameProfileRequest()
        request.userID = userID
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsGetNicknameProfile).map { (response: ServerPB_Moments_GetNicknameProfileResponse) -> RawData.NicknameProfile in
            return response.profile
        }
    }
}
extension RustApiService {
    static func getProfileEntryType(response: Moments_V1_ListUserActivitiesResponse, activityEntry: RawData.ActivityEntry) -> RawData.ProfileActivityEntryType {
         var type: RawData.ProfileActivityEntryType = .unknown
         switch activityEntry.type {
         case .unknown:
             type = .unknown
         case .publishPost:
             let postEntity = RustApiService.getPostEntity(postID: activityEntry.publishPostData.postID,
                                                           entities: response.entities)
             type = .publishPost(RawData.PublishPostEntry(postEntity: postEntity))
         case .commentToPost:
             let postEntity = RustApiService.getPostEntity(postID: activityEntry.commentToPostData.postID,
                                                           entities: response.entities)
             var commentEntitiy: RawData.CommentEntity?
             if let comment = response.entities.comments[activityEntry.commentToPostData.commentID] {
                 commentEntitiy = MomentsDataConverter.convertCommentToCommentEntitiy(entities: response.entities,
                                                                                   comment: comment)
             }
             let entry = RawData.CommentToPostEntry(postEntity: postEntity,
                                                    comment: commentEntitiy)
             type = .commentToPost(entry)
         case .replyToComment:
             var commentEntitiy: RawData.CommentEntity?
             if let comment = response.entities.comments[activityEntry.replyToCommentData.commentID] {
                 commentEntitiy = MomentsDataConverter.convertCommentToCommentEntitiy(entities: response.entities,
                                                                                   comment: comment)
             }
             var replyCommentEntitiy: RawData.CommentEntity?
             if let comment = response.entities.comments[activityEntry.replyToCommentData.targetCommentID] {
                 replyCommentEntitiy = MomentsDataConverter.convertCommentToCommentEntitiy(entities: response.entities,
                                                                                   comment: comment)
             }
             let entry = RawData.ReplyToCommentEntry(replyToComment: replyCommentEntitiy,
                                                     comment: commentEntitiy)
             type = .replyToComment(entry)
         case .reactionToPost:
             let postEntity = RustApiService.getPostEntity(postID: activityEntry.reactionToPostData.postID,
                                                           entities: response.entities)
             let entry = RawData.ReactionToPostEntry(reactionType: activityEntry.reactionToPostData.reactionType,
                                                     postEntity: postEntity)
             type = .reactionToPost(entry)
         case .reactionToComment:
             var commentEntitiy: RawData.CommentEntity?
             if let comment = response.entities.comments[activityEntry.reactionToCommentData.commentID] {
                 commentEntitiy = MomentsDataConverter.convertCommentToCommentEntitiy(entities: response.entities,
                                                                                   comment: comment)
             }
             let entry = RawData.ReactionToCommentEntry(reactionType: activityEntry.reactionToCommentData.reactionType,
                                                        comment: commentEntitiy)
             type = .reactionToCommment(entry)
         case .followUser:
             let userID = activityEntry.followUserData.targetUserID
             let user = response.entities.users[userID]
             let entry = RawData.FollowUserEntry(followUserId: userID,
                                                 followUser: user)
             type = .followUser(entry)
         @unknown default:
             assertionFailure("unknown case")
             type = .unknown
         }
         return type
     }

}
