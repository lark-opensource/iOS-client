//
//  PostApiService.swift
//  Moment
//
//  Created by zhuheng on 2020/12/30.
//
import Foundation
import RxSwift
import RustPB
import LarkContainer
import ServerPB

enum ReportType {
    case post(String)
    case comment(String)
    var id: String {
        switch self {
        case .post(let id), .comment(let id):
            return id
        default:
            return ""
        }
    }
}

protocol PostApiService {
    /// 发帖
    func createPost(byID circleID: String,
                    categoryId: String?,
                    isAnonymous: Bool,
                    content: RawData.RichText?,
                    images: [RawData.ImageInfo]?,
                    mediaInfo: RawData.MediaInfo?) -> Observable<RawData.PostEntity>
    /// 删帖
    func deletePost(byID postID: String, categoryIds: [String]) -> Observable<Void>
    /// 创建评论
    func createComment(byID postID: String,
                       replyComment: RawData.Comment?,
                       isAnonymous: Bool,
                       content: RawData.RichText?,
                       image: RawData.ImageInfo?,
                       postOriginCommentSet: RawData.CommentSet) -> Observable<RawData.CommentEntity>
    /// 删除评论
    /// postId: 所属postId
    /// originCommentSet: post
    func deleteComment(byID commentID: String, postId: String, postOriginCommentSet: RawData.CommentSet, categoryIds: [String]) -> Observable<Void>

    /// 上传视频
    func uploadVideoInfo(byLocalPath path: String, fileName: String, mountNodePoint: String, mountPoint: String) -> Observable<String>
    /// 创建 Reaction
    func createReaction(byID entityID: String,
                        entityType: RawData.EntityType,
                        reactionType: String,
                        originalReactionSet: RawData.ReactionSet,
                        categoryIds: [String],
                        isAnonymous: Bool) -> Observable<Void>
    /// 删除 Reaction
    func deleteReaction(byID entityID: String,
                        entityType: RawData.EntityType,
                        reactionType: String,
                        originalReactionSet: RawData.ReactionSet,
                        categoryIds: [String],
                        isAnonymous: Bool) -> Observable<Void>

    /// 拉取某个评论下具体点赞人
    func reactionsList(byID entityID: String, reactionType: String, pageToken: String, count: Int32) -> Observable<(nextPageToken: String, users: [MomentUser], anonymousUserCount: Int32)>

    func allReactions(byID entityID: String) -> Observable<[RawData.ReactionList]>

    func sharePost(to chatIds: [String], postId: String, replyText: String?, originShareCount: Int32, categoryIds: [String]) -> Observable<Void>

    func retryCreatePost(postId: String) -> Observable<Void>

    func retryCreateComment(commentId: String) -> Observable<Void>

    func report(type: ReportType, reason: String) -> Observable<Void>

    //置顶
    func setboardcast(boardcast: RawData.Broadcast, relpacePostId: String?) -> Observable<Void>

    //取消置顶
    func unBoardcast(postId: String) -> Observable<Void>

    //进入详情页后通过接口上报，后台有实时展示浏览数据的需求，普通埋点无法满足需求
    func uploadPostView(postId: String) -> Observable<Void>
}

extension RustApiService: PostApiService {
    func createPost(byID circleID: String,
                    categoryId: String?,
                    isAnonymous: Bool,
                    content: RawData.RichText?,
                    images: [RawData.ImageInfo]?,
                    mediaInfo: RawData.MediaInfo?) -> Observable<RawData.PostEntity> {
        var request = Moments_V1_CreatePostRequest()
        //        request.circleID = circleID
        request.isAnonymous = isAnonymous
        if let categoryId = categoryId {
            request.categoryIds = [categoryId]
        }
        if let content = content {
            request.content = content
        }
        if let images = images {
            request.imageInfoList = images
        }
        if let mediaInfo = mediaInfo {
            request.mediaInfo = mediaInfo
        }
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_CreatePostResponse) -> RawData.PostEntity in
                return RustApiService.getPostEntity(post: response.post, entities: response.entities)
            }
    }

    func deletePost(byID postID: String, categoryIds: [String]) -> Observable<Void> {
        var request = Moments_V1_DeletePostRequest()
        request.postID = postID
        request.pushCategoryIds = categoryIds
        return client.sendAsyncRequest(request)
            .map { (_: Moments_V1_DeletePostResponse) -> Void in
                return
            }
    }

    func createComment(byID postID: String,
                       replyComment: RawData.Comment?,
                       isAnonymous: Bool,
                       content: RawData.RichText?,
                       image: RawData.ImageInfo?,
                       postOriginCommentSet: RawData.CommentSet) -> Observable<RawData.CommentEntity> {
        var request = Moments_V1_CreateCommentRequest()
        request.postID = postID
        request.isAnonymous = isAnonymous
        request.originalCommentSet = postOriginCommentSet

        if var replyComment = replyComment {
            if replyComment.translationInfo.hasContentTranslation,
               !replyComment.translationInfo.contentTranslation.hasInnerText {
                //rust里innerText是required的
                replyComment.translationInfo.contentTranslation.innerText = ""
            }
            request.replyComment = replyComment
        }

        if let content = content {
            request.content = content
        }

        if let image = image {
            request.imageInfo = image
        }

        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_CreateCommentResponse) -> RawData.CommentEntity in
                /// 回复的消息存在的时候
                /// 这里response的entity里不会包含comments（也就是convertCommentToCommentEntitiy无法拿到replyComment），所以replyComment要传进去
                return MomentsDataConverter.convertCommentToCommentEntitiy(entities: response.entities, comment: response.comment, replyComment: replyComment)
            }
    }

    /// - Parameter path: 本地路径
    func uploadVideoInfo(byLocalPath path: String, fileName: String, mountNodePoint: String, mountPoint: String ) -> Observable<String> {
        var request = Space_Drive_V1_UploadRequest()
        request.localPath = path
        request.fileName = fileName
        request.mountNodePoint = mountNodePoint
        request.mountPoint = mountPoint
        return client.sendAsyncRequest(request).map { (response: Space_Drive_V1_UploadResponse) -> String in
            return response.key
        }
    }

    func deleteComment(byID commentID: String, postId: String, postOriginCommentSet: RawData.CommentSet, categoryIds: [String]) -> Observable<Void> {
        var request = Moments_V1_DeleteCommentRequest()
        request.commentID = commentID
        request.parentEntityID = postId
        request.originalCommentSet = postOriginCommentSet
        request.pushCategoryIds = categoryIds
        return client.sendAsyncRequest(request)
            .map { (_: Moments_V1_DeleteCommentResponse) -> Void in
                return
            }
    }

    func createReaction(byID entityID: String,
                        entityType: RawData.EntityType,
                        reactionType: String,
                        originalReactionSet: RawData.ReactionSet,
                        categoryIds: [String],
                        isAnonymous: Bool) -> Observable<Void> {
        var request = Moments_V1_CreateReactionRequest()
        request.entityID = entityID
        request.reactionType = reactionType
        request.originalReactionSet = originalReactionSet
        request.entityType = entityType
        request.pushCategoryIds = categoryIds
        request.isAnonymous = isAnonymous
        return client.sendAsyncRequest(request)
            .map { (_: Moments_V1_CreateReactionResponse) -> Void in
                return
            }
    }

    func deleteReaction(byID entityID: String,
                        entityType: RawData.EntityType,
                        reactionType: String,
                        originalReactionSet: RawData.ReactionSet,
                        categoryIds: [String],
                        isAnonymous: Bool) -> Observable<Void> {
        var request = Moments_V1_DeleteReactionRequest()
        request.entityID = entityID
        request.reactionType = reactionType
        request.originalReactionSet = originalReactionSet
        request.entityType = entityType
        request.pushCategoryIds = categoryIds
        request.isAnonymous = isAnonymous
        return client.sendAsyncRequest(request)
            .map { (_: Moments_V1_DeleteReactionResponse) -> Void in
                return
            }
    }

    func reactionsList(byID entityID: String, reactionType: String, pageToken: String, count: Int32) -> Observable<(nextPageToken: String, users: [MomentUser], anonymousUserCount: Int32)> {
        var request = Moments_V1_ListReactionsRequest()
        request.count = count
        request.pageToken = pageToken
        request.reactionType = reactionType
        request.entityID = entityID
        return client.sendAsyncRequest(request) { (res: Moments_V1_ListReactionsResponse) -> (nextPageToken: String, users: [MomentUser], anonymousUserCount: Int32) in
            let users = res.reactions.compactMap { (reaction) -> MomentUser? in
                return res.entities.users[reaction.userID]
            }
            if users.count != res.reactions.count {
                Self.logger.warn("get reactionsList miss user \(entityID) \(res.reactions.count) \(users.count)")
            }
            return (nextPageToken: res.nextPageToken, users: users, anonymousUserCount: res.anonymousUserCount)
        }
    }

    func allReactions(byID entityID: String) -> Observable<[RawData.ReactionList]> {
        var request = Moments_V1_PullReactionsSetRequest()
        request.entityID = entityID
        return client.sendAsyncRequest(request) { (res: Moments_V1_PullReactionsSetResponse) -> [RawData.ReactionList] in
            return res.reactions
        }
    }

    func sharePost(to chatIds: [String],
                   postId: String,
                   replyText: String?,
                   originShareCount: Int32,
                   categoryIds: [String]) -> Observable<Void> {
        var request = Moments_V1_SharePostRequest()
        request.chatIds = chatIds
        request.postID = postId
        request.pushCategoryIds = categoryIds
        request.originalShareCount = originShareCount
        if let replyText = replyText {
            request.replyMessage = replyText
        }
        return client.sendAsyncRequest(request) { (_: Moments_V1_SharePostResponse) -> Void in
            return
        }
    }

    func retryCreatePost(postId: String) -> Observable<Void> {
        var request = Moments_V1_RetryCreatePostRequest()
        request.postID = postId
        return client.sendAsyncRequest(request).map { (_: Moments_V1_RetryCreatePostResponse) -> Void in
            return
        }
    }

    func retryCreateComment(commentId: String) -> Observable<Void> {
        var request = Moments_V1_RetryCreateCommentRequest()
        request.commentID = commentId
        return client.sendAsyncRequest(request).map { (_: Moments_V1_RetryCreateCommentResponse) -> Void in
            return
        }
    }

    func report(type: ReportType, reason: String) -> Observable<Void> {
        var request = ServerPB_Moments_ReportRequest()
        switch type {
        case .post(let id):
            request.postID = id
        case .comment(let id):
            request.commentID = id
        }
        request.reason = reason
        /// 举报走透传接口
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsReport)
    }

    func unBoardcast(postId: String) -> Observable<Void> {
        var request = Moments_V1_ReplaceBroadcastRequest()
        request.unsetPostID = postId
        return client.sendAsyncRequest(request).map { (_: Moments_V1_ReplaceBroadcastResponse) -> Void in
            return
        }
    }

    func setboardcast(boardcast: RawData.Broadcast, relpacePostId: String?) -> Observable<Void> {
        var request = Moments_V1_ReplaceBroadcastRequest()
        request.newBroadcast = boardcast
        if let relpacePostId = relpacePostId {
            request.unsetPostID = relpacePostId
        }
        return client.sendAsyncRequest(request).map { (_: Moments_V1_ReplaceBroadcastResponse) -> Void in
            return
        }
    }

    func uploadPostView(postId: String) -> Observable<Void> {
        var request = ServerPB_Moments_MomentsCountOperationRequest()
        request.cid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        var postViewData = ServerPB_Moments_MomentsCountOperationRequest.RecordPostViewData()
        postViewData.postID = postId
        request.recordPostViewData = postViewData
        request.type = .recordPostView
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsCountOperation).map { (_: ServerPB_Moments_MomentsCountOperationResponse) -> Void in
            return
        }
    }
}
