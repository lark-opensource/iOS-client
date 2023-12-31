//
//  RawData.swift
//  Moment
//
//  Created by zhuheng on 2021/1/6.
//

import Foundation
import RustPB
import ServerPB
import LarkModel
import LarkContainer
import TangramService
import LarkRustClient
import LarkSDKInterface
import LarkFeatureGating
import Darwin
import LarkSetting

public enum RawData {}

public extension RawData {
    typealias EntityType = Moments_V1_EntityType
    typealias RichText = Basic_V1_RichText
    typealias ImageSet = Basic_V1_ImageSet

    typealias MediaInfo = Moments_V1_MediaInfo
    typealias ImageInfo = Moments_V1_ImageInfo
    typealias Post = Moments_V1_Post
    typealias PostContent = Moments_V1_Post.PostContent
    typealias PostCreateStatus = Moments_V1_Post.CreateStatus
    typealias Comment = Moments_V1_Comment
    typealias CommentCreateStatus = Moments_V1_Comment.CreateStatus
    typealias Broadcast = Moments_V1_Broadcast
    typealias Entitys = Moments_V1_Entities
    typealias Circle = Moments_V1_Circle
    typealias RustMomentUser = Moments_V1_MomentUser
    typealias Follower = Moments_V1_Follower
    typealias FollowingUser = Moments_V1_FollowingUser
    typealias Media = Moments_V1_Media
    typealias PostDistributionType = Moments_V1_Post.PostDistributionType
    typealias AnonymityPolicy = Moments_V1_AnonymityPolicy
    typealias Notification = Moments_V1_Notification
    typealias ReactionList = Moments_V1_ReactionList
    typealias ReactionSet = Moments_V1_ReactionSet
    typealias CommentSet = Moments_V1_CommentSet
    typealias MomentsBadgeCount = Moments_V1_NotificationCount
    typealias TranslationStatus = Moments_V1_TranslationStatus
    typealias TranslationInfo = Moments_V1_TranslationInfo

    typealias DeletedInfoNof = Moments_V1_PushEntityDeletedLocalNotification
    typealias FollowingInfoNof = Moments_V1_PushUserFollowingChangeLocalNotification
    typealias PostStatusNof = Moments_V1_PushPostCreateStatusChangeLocalNotification
    typealias PushMomentsUserInfoNof = Moments_V1_PushMomentUsersLocalNotification
    typealias PushReactionSetNof = Moments_V1_PushReactionSetLocalNotification
    typealias CommentStatusNof = Moments_V1_PushCommentCreateStatusChangeLocalNotification
    typealias CommentSetNof = Moments_V1_PushCommentSetLocalNotification
    typealias ShareCountNof = Moments_V1_PushShareCountLocalNotification
    typealias PostDistributionNof = Moments_V1_PushPostDistributionLocalNotification
    typealias PushPostIsBoardcastNof = Moments_V1_PushPostIsBroadcastLocalNotification
    typealias UserGlobalConfigAndSettingsNof = Moments_V1_PushUserGlobalConfigAndSettingsLocalNotification
    typealias PushNewPostUpdatedNotification = Moments_V1_PushNewPostUpdatedNotification
    typealias PushNewCommentUpdatedNotification = Moments_V1_PushNewCommentUpdatedNotification
    typealias PushOfficialUserChangedNotification = RustPB.Moments_V1_PushOfficialUserChangedNotification
    typealias StorageType = Moments_V1_SetKeyValueRequest.KeyType
    typealias Error = Basic_V1_LarkError
    typealias UserCircleConfig = Moments_V1_UserCircleConfig
    typealias MomentsUserSetting = Moments_V1_UserSetting
    typealias UserConfigResponse = Moments_V1_GetUserConfigAndSettingsResponse
    typealias UserSettingResponse = Moments_V1_GetUserSettingResponse

    /// profile 相关
    typealias UserProfile = Moments_V1_UserProfile
    /// category 相关
    typealias PostTab = Moments_V1_Tab
    typealias FeedOrder = Moments_V1_FeedOrder
    typealias Category = Moments_V1_Category
    typealias CategoryStats = Moments_V1_CategoryStats
    /// 花名匿名相关
    typealias AnonymousNickname = ServerPB_Moments_entities_AnonymousNickname
    typealias HashTagResponse = ServerPB_Moments_ListHashtagsByUserInputResponse
    typealias HashTag = Moments_V1_Hashtag
    typealias HashTagStats = Moments_V1_HashtagStats

    typealias AcceptSecretChatResponse = ServerPB_Moments_AcceptSecretChatResponse

    typealias hashTagOrder = Moments_V1_ListHashtagPostsRequest.HashtagPostOrder
    /// 点踩相关
    typealias DislikeEntityType = ServerPB_Moments_entities_EntityType
    typealias DislikeReason = ServerPB_Moments_entities_DislikeReason
    ///新profile与feed
    typealias ManageMode = RustPB.Moments_V1_ManageMode
    typealias ActivityEntry = Moments_V1_ActivityEntry
    typealias UserType = Moments_V1_MomentUser.TypeEnum
    typealias NicknameProfile = ServerPB_Moments_entities_NicknameProfile
}

extension RawData.RichText {
    func canBeTranslatedInMoment(fgService: FeatureGatingService?) -> Bool {
        let fgValue = fgService?.staticFeatureGatingValue(with: "moments.client.translation") ?? false
        guard fgValue else { return false }
        let ignoreTags: [RustPB.Basic_V1_RichTextElement.Tag] = [.at,
                                                                 .emotion,
                                                                 .mention,
                                                                 .p,
                                                                 .a]
        for element in self.elements.values {
            if !ignoreTags.contains(element.tag) {
                return true
            }
        }
        //如果只有url，则有解析过的url才能翻译，没解析的不能翻译
        return hasParsedURL
    }

    //是否有解析过的url；会筛掉裸链
    var hasParsedURL: Bool {
        return self.elements.contains { (_, value) in
            return value.tag == .a &&
            value.property.anchor.textContent != value.property.anchor.href
        }
    }
}

extension RawData.Post {
    func getDisplayContent(fgService: FeatureGatingService?, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> RawData.RichText {
        return getTranstionSummerize(fgService: fgService, userGeneralSettings: userGeneralSettings, supportManualTranslate: supportManualTranslate)
        ?? postContent.content
    }

    func getTranstionSummerize(fgService: FeatureGatingService?, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> RawData.RichText? {
        if canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings, supportManualTranslate: supportManualTranslate),
           !self.translationInfo.contentTranslation.elements.isEmpty {
            return self.translationInfo.contentTranslation
        } else {
            return nil
        }
    }

    func canShowTranslation(fgService: FeatureGatingService?, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> Bool {
        return shouldShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings, supportManualTranslate: supportManualTranslate)
        && isTranslated
    }

    var translateFail: Bool {
        var translateFail = false
        if self.translationInfo.hasContentTranslation,
           self.translationInfo.contentTranslation.elements.isEmpty {
            //实体翻译过但是没有实体翻译内容，先标记为翻译失败，然后再检查url的翻译结果
            translateFail = true
            for (_, urlTranslation) in self.translationInfo.urlPreviewTranslation {
                if !urlTranslation.isEmpty {
                    //只有有一个url翻译成功，就不认为是翻译失败
                    translateFail = false
                }
            }
        }
        return translateFail
    }

    func shouldShowTranslation(fgService: FeatureGatingService?, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> Bool {
        guard fgService?.staticFeatureGatingValue(with: "moments.client.translation") ?? false else { return false }
        var hasParsedURL = self.postContent.content.hasParsedURL
        if self.contentLanguages.count == 1,
           let contentLanguages = self.contentLanguages.first,
           !hasParsedURL {
            if contentLanguages.lowercased() == "not_lang" {
                return false
            }
            if contentLanguages == self.translationInfo.targetLanguage,
               !self.translationInfo.hasContentTranslation {
                return false
            }
        }
        if !self.canBeTranslated(fgService: fgService) {
            return false
        }

        if self.translateFail {
            return false
        }

        switch self.translationInfo.translateStatus {
        case .hidden:
            return false
        case .manual:
            if supportManualTranslate {
                return true
            } else {
                return shouldAutoTranslate()
            }
        case .noOperation:
            return shouldAutoTranslate()
        @unknown default:
            assertionFailure("unknown case")
            return false
        }
        func shouldAutoTranslate() -> Bool {
            if self.isSelfOwner {
                return false
            }
            guard userGeneralSettings.translateLanguageSetting.momentsSwitch else { return false }
            if contentLanguages.isEmpty {
                //没有识别过源语言 先认为它应该被翻译
                return true
            }
            if hasParsedURL {
                //有解析的URL，跳过语言判断，认为应该翻译
                return true
            }
            let momentsScope = RustPB.Im_V1_TranslateScopeMask.moments.rawValue
            for lang in contentLanguages {
                if lang.lowercased() == "not_lang" {
                    continue
                }
                if let scope = userGeneralSettings.translateLanguageSetting.srcLanguagesConfig[lang]?.scopes {
                    if (Int(scope) & momentsScope) != 0 {
                        //只要有一个源语言要自动翻译，就要翻译
                        return true
                    }
                } else {
                    //通常来说总是能拿到scope，如果没拿到 返回true兜底
                    assertionFailure("unexpected contentLanguage")
                    return true
                }
            }
            return false
        }
    }

    var isTranslated: Bool {
        return !self.translationInfo.contentTranslation.elements.isEmpty ||
        //url翻译信息非空 且contentTranslationentity有值（即实体被翻译过，尽管翻译内容可能为空）
        (self.translationInfo.hasContentTranslation && !self.translationInfo.urlPreviewTranslation.isEmpty)
    }

    func canBeTranslated(fgService: FeatureGatingService?) -> Bool {
        if self.contentLanguages.count == 1,
           let contentLanguages = self.contentLanguages.first,
           !self.postContent.content.hasParsedURL {
            if contentLanguages.lowercased() == "not_lang" {
                return false
            }
        }
        return self.postContent.content.canBeTranslatedInMoment(fgService: fgService)
    }

    func getDisplayRule(userGeneralSettings: UserGeneralSettings) -> RustPB.Basic_V1_DisplayRule {
        return userGeneralSettings.translateLanguageSetting.languagesConf[self.contentLanguages.first ?? ""]?.rule
        ?? userGeneralSettings.translateLanguageSetting.globalConf.rule
    }
}

extension RawData.Comment {
    func getDisplayContent(fgService: FeatureGatingService, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> RawData.RichText {
        return getTranstionSummerize(fgService: fgService, userGeneralSettings: userGeneralSettings, supportManualTranslate: supportManualTranslate)
        ?? content.content
    }

    func getTranstionSummerize(fgService: FeatureGatingService, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> RawData.RichText? {
        if canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings, supportManualTranslate: supportManualTranslate),
            !self.translationInfo.contentTranslation.elements.isEmpty {
            return self.translationInfo.contentTranslation
        } else {
            return nil
        }
    }

    func canShowTranslation(fgService: FeatureGatingService, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> Bool {
        return shouldShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings, supportManualTranslate: supportManualTranslate)
        && isTranslated
    }

    var translateFail: Bool {
        var translateFail = false
        if self.translationInfo.hasContentTranslation,
           self.translationInfo.contentTranslation.elements.isEmpty {
            //实体翻译过但是没有实体翻译内容，先标记为翻译失败，然后再检查url的翻译结果
            translateFail = true
            for (_, urlTranslation) in self.translationInfo.urlPreviewTranslation {
                if !urlTranslation.isEmpty {
                    //只有有一个url翻译成功，就不认为是翻译失败
                    translateFail = false
                }
            }
        }
        return translateFail
    }

    func shouldShowTranslation(fgService: FeatureGatingService, userGeneralSettings: UserGeneralSettings, supportManualTranslate: Bool = true) -> Bool {
        guard fgService.staticFeatureGatingValue(with: "moments.client.translation") else { return false }
        let hasParsedURL = self.content.content.hasParsedURL
        if self.contentLanguages.count == 1,
           let contentLanguages = self.contentLanguages.first,
           !hasParsedURL {
            if contentLanguages.lowercased() == "not_lang" {
                return false
            }
            if contentLanguages == self.translationInfo.targetLanguage,
               !self.translationInfo.hasContentTranslation {
                return false
            }
        }
        if !self.canBeTranslated(fgService: fgService) {
            return false
        }

        if self.translateFail {
            return false
        }

        switch self.translationInfo.translateStatus {
        case .hidden:
            return false
        case .manual:
            if supportManualTranslate {
                return true
            } else {
                return shouldAutoTranslate()
            }
        case .noOperation:
            return shouldAutoTranslate()
        @unknown default:
            assertionFailure("unknown case")
            return false
        }
        func shouldAutoTranslate() -> Bool {
            if self.isSelfOwner {
                return false
            }
            guard userGeneralSettings.translateLanguageSetting.momentsSwitch else { return false }
            if contentLanguages.isEmpty {
                //没有识别过源语言 先认为它应该被翻译
                return true
            }
            if hasParsedURL {
                //有解析的URL，跳过语言判断，认为应该翻译
                return true
            }
            let momentsScope = RustPB.Im_V1_TranslateScopeMask.moments.rawValue
            for lang in contentLanguages {
                if lang.lowercased() == "not_lang" {
                    continue
                }
                if let scope = userGeneralSettings.translateLanguageSetting.srcLanguagesConfig[lang]?.scopes {
                    if (Int(scope) & momentsScope) != 0 {
                        //只要有一个源语言要自动翻译，就要翻译
                        return true
                    }
                } else {
                    //通常来说总是能拿到scope，如果没拿到 返回true兜底
                    assertionFailure("unexpected contentLanguage")
                    return true
                }
            }
            return false
        }
    }

    var isTranslated: Bool {
        return !self.translationInfo.contentTranslation.elements.isEmpty ||
        //url翻译信息非空 且contentTranslationentity有值（即实体被翻译过，尽管翻译内容可能为空）
        (self.translationInfo.hasContentTranslation && !self.translationInfo.urlPreviewTranslation.isEmpty)
    }

    func canBeTranslated(fgService: FeatureGatingService?) -> Bool {
        if self.contentLanguages.count == 1,
           let contentLanguages = self.contentLanguages.first,
           !self.content.content.hasParsedURL {
            if contentLanguages.lowercased() == "not_lang" {
                return false
            }
        }
        return self.content.content.canBeTranslatedInMoment(fgService: fgService)
    }

    func getDisplayRule(userGeneralSettings: UserGeneralSettings) -> RustPB.Basic_V1_DisplayRule {
        return userGeneralSettings.translateLanguageSetting.languagesConf[self.contentLanguages.first ?? ""]?.rule
        ?? userGeneralSettings.translateLanguageSetting.globalConf.rule
    }
}

public extension RawData {
    final class PostCategory {
        var category: RawData.Category
        var adminUsers: [MomentUser]
        init(category: RawData.Category,
             adminUsers: [MomentUser]) {
            self.category = category
            self.adminUsers = adminUsers
        }
    }

    final class PostEntity {
        var post: RawData.Post
        var user: MomentUser?
        var userExtraFields: [String]
        var circle: RawData.Circle?
        var category: RawData.PostCategory?
        /// feed页外露的评论
        var comments: [RawData.CommentEntity]
        var reactionListEntities: [RawData.ReactionListEntity]
        var inlinePreviewEntities: InlinePreviewEntityBody
        var hotComments: [RawData.CommentEntity] {
            return comments.filter { $0.comment.isHot }
        }
        var userDisplayName: String {
            guard let user = self.user else {
                return ""
            }
            return user.displayName
        }

        private var lock = pthread_rwlock_t()
        var safeContentLanguages: [String] {
            get {
                pthread_rwlock_rdlock(&lock)
                defer {
                    pthread_rwlock_unlock(&lock)
                }
                return post.contentLanguages
            }
            set {
                pthread_rwlock_wrlock(&lock)
                defer {
                    pthread_rwlock_unlock(&lock)
                }
                post.contentLanguages = newValue
            }
        }

        var canCurrentAccountComment: Bool {
            return self.post.canComment
        }
        func canCurrentAccountReaction(momentsAccountService: MomentsAccountService?) -> Bool {
            return self.post.canReaction && !(momentsAccountService?.isDisableReactionDueToAccount(user: self.user) ?? false)
        }

        var error: RawData.Error?
        init(post: RawData.Post,
             user: MomentUser?,
             userExtraFields: [String],
             circle: RawData.Circle?,
             category: RawData.PostCategory?,
             comments: [RawData.CommentEntity],
             reactionListEntities: [RawData.ReactionListEntity],
             inlinePreviewEntities: InlinePreviewEntityBody) {
            self.post = post
            self.user = user
            self.userExtraFields = userExtraFields
            self.category = category
            self.circle = circle
            self.comments = comments
            self.reactionListEntities = reactionListEntities
            self.inlinePreviewEntities = inlinePreviewEntities
        }

        func copy() -> PostEntity {
            return PostEntity(post: self.post,
                              user: self.user,
                              userExtraFields: self.userExtraFields,
                              circle: self.circle,
                              category: self.category,
                              comments: self.comments,
                              reactionListEntities: self.reactionListEntities,
                              inlinePreviewEntities: self.inlinePreviewEntities)
        }
    }

    final class CommentEntity {
        var comment: RawData.Comment
        var user: MomentUser?
        var userExtraFields: [String]
        var replyCommentEntity: CommentEntity?
        var replyUser: MomentUser?
        var reactionListEntities: [RawData.ReactionListEntity]
        var inlinePreviewEntities: InlinePreviewEntityBody
        var error: RawData.Error?

        static func empty() -> CommentEntity {
            return CommentEntity(comment: RawData.Comment())
        }
        private init (comment: RawData.Comment) {
            self.comment = comment
            self.reactionListEntities = []
            self.inlinePreviewEntities = [:]
            self.userExtraFields = []
        }

        init(comment: RawData.Comment,
             user: MomentUser?,
             userExtraFields: [String],
             replyCommentEntity: CommentEntity?,
             replyUser: MomentUser?,
             reactionListEntities: [RawData.ReactionListEntity] = [],
             inlinePreviewEntities: InlinePreviewEntityBody) {
            self.comment = comment
            self.user = user
            self.userExtraFields = userExtraFields
            self.replyCommentEntity = replyCommentEntity
            self.replyUser = replyUser
            self.reactionListEntities = reactionListEntities
            self.inlinePreviewEntities = inlinePreviewEntities
        }
        //ui层使用的名称
        var userDisplayName: String {
            return user?.displayName ?? ""
        }
    }

    final class ReactionListEntity {
        //reactionType + firstPageUserIds + ...
        let reactionList: RawData.ReactionList
        var firstPageUsers: [MomentUser]
        init(reactionList: RawData.ReactionList, firstPageUsers: [MomentUser]) {
            self.reactionList = reactionList
            self.firstPageUsers = firstPageUsers
        }
    }

    enum NoticeType {
        case unknown
        case follower(followerEntity: NoticeFollowerEntity)
        case postReaction(postReactionEntity: NoticePostReactionEntity)
        case commentReaction(commentReactionEntity: NoticeCommentReactionEntity)
        case comment(commentEntity: NoticeCommentEntity)
        case reply(replyEntity: NoticeReplyEntity)
        case atInPost(atInPostEntity: NoticeAtInPostEntity)
        case atInComment(atInCommentEntity: NoticeAtInCommentEntity)
        func getBinderData() -> Any? {
            switch self {
            case .unknown:
                return nil
            case .follower(let followerEntity):
                return followerEntity
            case .postReaction(let postReactionEntity):
                return postReactionEntity
            case .commentReaction(let commentReactionEntity):
                return commentReactionEntity
            case .comment(let commentEntity):
                return commentEntity
            case .reply(let replyEntity):
                return replyEntity
            case .atInPost(let atInPostEntity):
                return atInPostEntity
            case .atInComment(let atInCommentEntity):
                return atInCommentEntity
            }
        }
    }

    /// 通知相关
    struct NoticeEntity {
        let id: String
        let category: NoticeList.SourceType
        var noticeType: NoticeType
        let createTime: Int64
    }

    /// 有人关注了你
    final class NoticeFollowerEntity {
        let followerUser: MomentUser?
        var hadFollow: Bool
        init(followerUser: MomentUser?, hadFollow: Bool) {
            self.followerUser = followerUser
            self.hadFollow = hadFollow
        }
    }
    /// 帖子收到表情
    struct NoticePostReactionEntity {
        let postEntity: RawData.PostEntity?
        let reactionType: String
        let reactionUser: MomentUser?
    }
    /// 评论收到表情
    struct NoticeCommentReactionEntity {
        let postEntity: RawData.PostEntity?
        let comment: RawData.Comment?
        let reactionType: String
        let reactionUser: MomentUser?
    }
    /// 帖子收到评论
    struct NoticeCommentEntity {
        let postEntity: RawData.PostEntity?
        let comment: RawData.Comment?
        let user: MomentUser?
        var inlinePreviewEntities: InlinePreviewEntityBody
    }

    /// 评论收到回复
    struct NoticeReplyEntity {
        let postEntity: RawData.PostEntity?
        let comment: RawData.Comment?
        let replyComment: RawData.Comment?
        let user: MomentUser?
        var inlinePreviewEntities: InlinePreviewEntityBody
    }

    /// 帖子中@了你
    struct NoticeAtInPostEntity {
        let postEntity: RawData.PostEntity?
        let user: MomentUser?
    }

    /// 评论中@了你
    struct NoticeAtInCommentEntity {
        let postEntity: RawData.PostEntity?
        let comment: RawData.Comment?
        let user: MomentUser?
        var inlinePreviewEntities: InlinePreviewEntityBody
    }

    /// 用户实体
    struct UserProfileEntity {
        let user: MomentUser?
        let userProfile: RawData.UserProfile
    }
    /// reaction的推送消息实体
    struct ReactionSetNofEntity {
        let id: String
        let categoryIds: [String]
        let reactionEntities: [RawData.ReactionListEntity]
        let reactionSet: RawData.ReactionSet
    }

    /// 板块详情实体
    struct CategoryInfoEntity {
        var adminUsers: [MomentUser]?
        let category: RawData.Category?
        let categoryStats: RawData.CategoryStats
    }

    /// 匿名用户
    struct AnonymousUser {
        let anonymousAvatarKey: String?
        let anonymousName: String?
    }

    /// 用户匿名和花名的信息
    struct AnonymousAndNicknameUserInfo {
        var nicknameUser: MomentUser?
        let anonymousUser: AnonymousUser?
    }

    /// hashTag详情信息
    struct HashTagDetailInfo {
        let stats: RawData.HashTagStats
        let hashTag: RawData.HashTag
    }
}

/// profile 相关的处理
extension RawData {

    enum ProfileTargetEntity {
        case empty
        case post(RawData.PostEntity)
        case comment(RawData.CommentEntity)
    }

    enum ProfileActivityEntryType {
        case unknown
        case publishPost(PublishPostEntry)
        case commentToPost(CommentToPostEntry)
        case replyToComment(ReplyToCommentEntry)
        case reactionToPost(ReactionToPostEntry)
        case reactionToCommment(ReactionToCommentEntry)
        case followUser(FollowUserEntry)

        func targetEntity() -> ProfileTargetEntity {
            switch self {
            case .unknown:
                return .empty
            case .publishPost(let publishPostEntry):
                return publishPostEntry.postEntity.flatMap({ .post($0) }) ?? .empty
            case .commentToPost(let commentToPostEntry):
                return commentToPostEntry.postEntity.flatMap({ .post($0) }) ?? .empty
            case .replyToComment(let replyToCommentEntry):
                return replyToCommentEntry.replyToComment.flatMap({ .comment($0) }) ?? .empty
            case .reactionToPost(let reactionToPostEntry):
                return reactionToPostEntry.postEntity.flatMap({ .post($0) }) ?? .empty
            case .reactionToCommment(let reactionToCommmentEntry):
                return reactionToCommmentEntry.comment.flatMap({ .comment($0) }) ?? .empty
            case .followUser(let followUserEntry):
                return .empty
            }
        }

        func richText() -> RustPB.Basic_V1_RichText? {
            switch self {
            case .unknown:
                return nil
            case .publishPost(let publishPostEntry):
                return publishPostEntry.postEntity?.post.postContent.content
            case .commentToPost(let commentToPostEntry):
                return commentToPostEntry.postEntity?.post.postContent.content
            case .replyToComment(let replyToCommentEntry):
                return replyToCommentEntry.replyToComment?.comment.content.content
            case .reactionToPost(let reactionToPostEntry):
                return reactionToPostEntry.postEntity?.post.postContent.content
            case .reactionToCommment(let reactionToCommmentEntry):
                return reactionToCommmentEntry.comment?.comment.content.content
            case .followUser(let followUserEntry):
                return nil
            }
        }

        func translation(fgService: FeatureGatingService, userGeneralSettings: UserGeneralSettings) -> RustPB.Basic_V1_RichText? {
            switch self {
            case .unknown:
                return nil
            case .publishPost(let publishPostEntry):
                return publishPostEntry.postEntity?.post.getTranstionSummerize(fgService: fgService, userGeneralSettings: userGeneralSettings)
            case .commentToPost(let commentToPostEntry):
                return commentToPostEntry.postEntity?.post.getTranstionSummerize(fgService: fgService, userGeneralSettings: userGeneralSettings)
            case .replyToComment(let replyToCommentEntry):
                return replyToCommentEntry.replyToComment?.comment.getTranstionSummerize(fgService: fgService, userGeneralSettings: userGeneralSettings)
            case .reactionToPost(let reactionToPostEntry):
                return reactionToPostEntry.postEntity?.post.getTranstionSummerize(fgService: fgService, userGeneralSettings: userGeneralSettings)
            case .reactionToCommment(let reactionToCommmentEntry):
                return reactionToCommmentEntry.comment?.comment.getTranstionSummerize(fgService: fgService, userGeneralSettings: userGeneralSettings)
            case .followUser(let followUserEntry):
                return nil
            }
        }

        func getBinderData() -> Any? {
            switch self {
            case .unknown:
                return nil
            case .publishPost(let publishPostEntry):
                return publishPostEntry
            case .commentToPost(let commentToPostEntry):
                return commentToPostEntry
            case .replyToComment(let replyToCommentEntry):
                return replyToCommentEntry
            case .reactionToPost(let reactionToPostEntry):
                return reactionToPostEntry
            case .reactionToCommment(let reactionToCommmentEntry):
                return reactionToCommmentEntry
            case .followUser(let followUserEntry):
                return followUserEntry
            }
        }
    }

    /// 发布帖子
    struct PublishPostEntry {
        let postEntity: RawData.PostEntity?
    }

    struct CommentToPostEntry {
        let postEntity: RawData.PostEntity?
        let comment: RawData.CommentEntity?
    }

    struct ReplyToCommentEntry {
        let replyToComment: RawData.CommentEntity?
        let comment: RawData.CommentEntity?
    }

    struct ReactionToPostEntry {
        let reactionType: String
        let postEntity: RawData.PostEntity?
    }

    struct ReactionToCommentEntry {
        let reactionType: String
        let comment: RawData.CommentEntity?
    }

    struct FollowUserEntry {
        let followUserId: String
        let followUser: MomentUser?
    }

    final class ProfileActivityEntry: HasId {
        let activityEntry: RawData.ActivityEntry
        let currentUser: MomentUser?
        private var entryId: Int64 = 0
        var type: ProfileActivityEntryType
        var id: String { return "\(entryId)" }
        init (entryId: Int64,
              currentUser: MomentUser?,
              type: RawData.ProfileActivityEntryType,
              activityEntry: RawData.ActivityEntry) {
            self.activityEntry = activityEntry
            self.entryId = entryId
            self.type = type
            self.currentUser = currentUser
        }
    }

    enum TranslateTargetEntity {
        case post(RawData.PostEntity)
        case comment(RawData.CommentEntity)

        var type: EntityType {
            switch self {
            case .post(_):
                return .post
            case .comment(_):
                return .comment
            }
        }

        var id: String {
            switch self {
            case .post(let post):
                return post.id
            case .comment(let comment):
                return comment.id
            }
        }

        var translationInfo: TranslationInfo {
            switch self {
            case .post(let post):
                return post.post.translationInfo
            case .comment(let comment):
                return comment.comment.translationInfo
            }
        }

        var contentLanguages: [String] {
            switch self {
            case .post(let post):
                return post.safeContentLanguages
            case .comment(let comment):
                return comment.comment.contentLanguages
            }
        }

        var richText: RichText {
            switch self {
            case .post(let post):
                return post.post.postContent.content
            case .comment(let comment):
                return comment.comment.content.content
            }
        }

        var isSelfOwner: Bool {
            switch self {
            case .post(let post):
                return post.post.isSelfOwner
            case .comment(let comment):
                return comment.comment.isSelfOwner
            }
        }

        var inlinePreviewEntities: InlinePreviewEntityBody {
            switch self {
            case .post(let post):
                return post.inlinePreviewEntities
            case .comment(let comment):
                return comment.inlinePreviewEntities
            }
        }

        var urlPreviewHangPointMap: [String: Basic_V1_UrlPreviewHangPoint] {
            switch self {
            case .post(let post):
                return post.post.urlPreviewHangPointMap
            case .comment(let comment):
                return comment.comment.urlPreviewHangPointMap
            }
        }

        var translateFail: Bool {
            switch self {
            case .post(let post):
                return post.post.translateFail
            case .comment(let comment):
                return comment.comment.translateFail
            }
        }

        func getDisplayRule(userGeneralSettings: UserGeneralSettings) -> RustPB.Basic_V1_DisplayRule {
            switch self {
            case .post(let post):
                return post.post.getDisplayRule(userGeneralSettings: userGeneralSettings)
            case .comment(let comment):
                return comment.comment.getDisplayRule(userGeneralSettings: userGeneralSettings)
            }
        }
    }
}

extension RawData.ImageSet {
    func imageLocalPath() -> String {
        return self.thumbnail.urls.first ?? ""
    }
}

public struct PushMomentPostByCommentList: PushMessage {
    public let post: RawData.PostEntity

    public init(post: RawData.PostEntity) {
        self.post = post
    }
}

public extension RawData.PostTab {
    var isRecommendTab: Bool {
        return self.id == "\(RawData.PostTab.FeedTabId.feedRecommend.rawValue)"
    }

    var isFollowTab: Bool {
        return self.id == "\(RawData.PostTab.FeedTabId.feedFollowing.rawValue)"
    }

    var isCategoryTab: Bool {
        return !self.isRecommendTab && !self.isFollowTab
    }
}

extension RawData.ManageMode {
    var isRecommendOrder: Bool {
        return self == .strongIntervention || self == .recommendV2Mode
    }
}
