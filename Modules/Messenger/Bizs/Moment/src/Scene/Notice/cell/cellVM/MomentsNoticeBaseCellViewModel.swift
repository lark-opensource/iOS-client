//
//  MomentsNoticeBaseCellViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/2/23.
//

import Foundation
import LarkUIKit
import RustPB
import LarkCore
import LarkSDKInterface
import LarkContainer
import Swinject
import RxSwift
import EENavigator
import LarkMessengerInterface
import RichLabel
import LarkEmotion
import UniverseDesignToast
import UniverseDesignColor
import UIKit
import TangramService
import LarkSetting
import LarkModel

class MomentsNoticeBaseCellViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    /// 用户
    var user: MomentUser?
    /// title
    var title: NSAttributedString?
    /// content
    var content: NSAttributedString?
    /// right
    var rightImageInfo: (isVideo: Bool, key: String?)?
    var rightText: NSAttributedString?
    /// time
    var time: String = ""
    var reuseIdentifier: String = ""
    /// 内容实体
    var noticeEntity: RawData.NoticeEntity
    let disposeBag: DisposeBag = DisposeBag()

    let context: NoticeContext

    @ScopedInjectedLazy var fgService: FeatureGatingService?
    @ScopedInjectedLazy var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var translateService: MomentsTranslateService?
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?

    init(userResolver: UserResolver, noticeEntity: RawData.NoticeEntity, context: NoticeContext) {
        self.userResolver = userResolver
        self.noticeEntity = noticeEntity
        self.context = context
        handleNoticeEntityData()
    }

    func handleNoticeEntityData() {
        /// 帖子的创建时间
        let createTime = TimeInterval(noticeEntity.createTime / 1000)
        let date = Date(timeIntervalSince1970: createTime)
        self.time = MomentsTimeTool.displayTimeForDate(date)
    }

    func showRightDeleContent() {
        rightText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_NotificationContentDeleted, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.ud.textPlaceholder
        ])
        reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
    }

    func showRightDeleComment() {
        rightText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_TheCommentHasBeenDeleted, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.ud.textPlaceholder
        ])
        reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
    }

    func contentAttrWith(comment: RawData.Comment?, userID: String, urlPreviewProvider: LarkCoreUtils.URLPreviewProvider?) -> NSAttributedString? {
        guard let comment = comment, let userGeneralSettings, let fgService = fgService else {
            return nil
        }
        /// 如果删除了 直接返回
        if comment.isDeleted {
            return NSAttributedString(string: BundleI18n.Moment.Lark_Community_TheCommentHasBeenDeleted,
                                      attributes: attributesWith(font: UIFont.systemFont(ofSize: 17), color: UIColor.ud.textTitle))
        }
        /// 如果文字存在，优先返回文字
        if let attr = contentAttrWith(richText: comment.getDisplayContent(fgService: fgService,
                                                                          userGeneralSettings: userGeneralSettings,
                                                                         supportManualTranslate: false),
                                      userID: userID,
                                      isDelete: false,
                                      showTranslatedTag: comment.canShowTranslation(fgService: fgService,
                                                                                    userGeneralSettings: userGeneralSettings,
                                                                                   supportManualTranslate: false),
                                      urlPreviewProvider: urlPreviewProvider),
           attr.length > 0 {
            return attr
        }

        /// 如果文字不存在 返回图片
        if !comment.content.imageSet.origin.key.isEmpty {
            return NSAttributedString(string: BundleI18n.Moment.Lark_Community_Picture, attributes: attributesWith(color: UIColor.ud.textTitle))
        }
        return nil
    }

    func contentAttrWith(richText: RustPB.Basic_V1_RichText?,
                         userID: String,
                         isDelete: Bool,
                         showTranslatedTag: Bool,
                         urlPreviewProvider: LarkCoreUtils.URLPreviewProvider?) -> NSAttributedString? {
        if isDelete {
            return deleteContent()
        }
        if let richText = richText {
            let richTextParser = RichTextAbilityParser(userResolver: userResolver,
                                                       dependency: self.context,
                                                       richText: richText,
                                                       font: UIFont.systemFont(ofSize: 17, weight: .regular),
                                                       showTranslatedTag: showTranslatedTag,
                                                       numberOfLines: 1,
                                                       richTextSenderId: userID,
                                                       contentLineSpacing: 2,
                                                       urlPreviewProvider: urlPreviewProvider)
            return richTextParser.attributedString
        }
        return nil
    }

    func deleteContent() -> NSAttributedString {
        let attribute = attributesWith(font: UIFont.systemFont(ofSize: 17), color: UIColor.ud.textTitle)
        return NSAttributedString(string: BundleI18n.Moment.Lark_Community_NotificationContentDeleted, attributes: attribute)
    }

    func imageInfoForPost(_ post: RawData.Post?) -> (Bool, String?)? {
        guard let post = post else {
            return nil
        }
        var isVideo = false
        if post.postContent.hasMedia, !post.postContent.media.driveURL.isEmpty {
            isVideo = true
            return (isVideo, post.postContent.media.cover.thumbnail.key)
        }
        if !post.postContent.imageSetList.isEmpty {
            return (isVideo, post.postContent.imageSetList.first?.thumbnail.key ?? "")
        }
        return nil
    }

    func imageKeyForComment(_ comment: RawData.Comment?) -> String? {
        guard let comment = comment else {
            return nil
        }
        if comment.content.hasImageSet, !comment.content.imageSet.thumbnail.key.isEmpty {
            return comment.content.imageSet.thumbnail.key
        }
        return nil
    }

    func convertRichTextToString(richText: RustPB.Basic_V1_RichText?,
                                 showTranslatedTag: Bool) -> NSAttributedString {
        guard let richText = richText else {
            return NSAttributedString()
        }
        return RichTextAbilityParser(userResolver: userResolver,
                                     dependency: self.context,
                                     richText: richText,
                                     font: UIFont.systemFont(ofSize: 12),
                                     showTranslatedTag: showTranslatedTag,
                                     textColor: UIColor.ud.textPlaceholder,
                                     numberOfLines: 3,
                                     contentLineSpacing: 2).attributedString
    }

    func hadContent() -> Bool {
        if self.noticeEntity.category == .reaction {
            return false
        }
        switch self.noticeEntity.noticeType {
        case .follower:
            return false
        default:
            return true
        }
    }

    func asyncAttachmentWithReactionType(_ type: String, font: UIFont = UIFont.systemFont(ofSize: 16)) -> LKAsyncAttachment {
        var image = EmotionResouce.placeholder
        if let icon = EmotionResouce.shared.imageBy(key: type) {
            image = icon
        }
        let width = image.size.width / (image.size.height / 20)
        let newSize = CGSize(width: width, height: 20)
        let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
            let imageView = UIImageView()
            imageView.image = image
            return imageView
        }, size: newSize)
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        return attachment
    }

    /// 拼接表情
    func appendAttachment(_ attachment: LKAsyncAttachment) {
        guard let attributedText = self.title else {
            return
        }
        let tmpAttributeText = NSMutableAttributedString(attributedString: attributedText)
        tmpAttributeText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [
            LKAttachmentAttributeName: attachment
        ]))
        self.title = tmpAttributeText
    }

    func maxTitleWidth() -> CGFloat {
        guard let pageAPI = self.context.pageAPI else {
            return UIScreen.main.bounds.width - 78 - 72
        }
        return pageAPI.view.bounds.width - 78 - 72
    }

    func getTitleAttributeStringWithText(_ text: String) -> NSAttributedString {
        var name = ""
        if let user = user {
            if user.momentUserType == .anonymous {
                name = BundleI18n.Moment.Lark_Community_AnonymousUser
            } else {
                name = user.displayName
            }
        }
        let attr = NSMutableAttributedString(string: name, attributes: attributesWith(color: UIColor.ud.textTitle))
        attr.append(NSAttributedString(string: " ", attributes: attributesWith(color: UIColor.clear)))
        attr.append(NSAttributedString(string: text, attributes: attributesWith(color: UIColor.ud.textPlaceholder)))
        return attr
    }

    func attributesWith(font: UIFont = UIFont.systemFont(ofSize: 16), color: UIColor) -> [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: color,
            .font: font
        ]
    }

    /// 跳转逻辑
    func didSelected() {
        trackCommunityNotificationEntryClick()
    }

    func onAvatarTapped() {
        pushToUserAvatar()
        trackCommunityNotificationEntryClick()
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category, clickType: .otherProfile)
    }

    func pushToUserAvatar() {
        guard let targetVC = self.context.pageAPI, let user = self.user else { return }
        MomentsNavigator.pushAvatarWith(userResolver: userResolver, user: user, from: targetVC, source: .notification, trackInfo: nil)
    }

    func trackCommunityNotificationEntryClick() {
        var type = Tracer.NotificationCellType.follow
        switch self.noticeEntity.noticeType {
        case .unknown:
            type = .unknown
        case .follower:
            type = .follow
        case .postReaction:
            type = .postReaction
        case .commentReaction:
            type = .commentReaction
        case .comment:
            type = .postReply
        case .reply:
            type = .commentReply
        case .atInPost:
            type = .postMention
        case .atInComment:
            type = .commentMention
        }
        Tracer.trackCommunityNotificationEntryClick(type: type)
    }

    func showPostDeleTipsIfNeedForPost(_ post: RawData.Post) -> Bool {
        guard let pageAPI = context.pageAPI, post.isDeleted else {
            return false
        }
        UDToast.showTips(with: BundleI18n.Moment.Lark_Community_ThisActivityHasBeenDeleted, on: pageAPI.view, delay: 1.5)
        return true
    }

    func getNavFromForPush() -> NavigatorFrom? {
        if Display.pad {
            context.pageAPI?.dismiss(animated: true)
            return context.navFromForPad
        } else {
            return context.pageAPI
        }
    }

    private var displaying = false
    func willDisplay() {
        guard !displaying, let translateService else { return }
        displaying = true
        func autoTranslateIfNeed(post: RawData.Post?, inlinePreviewEntities: InlinePreviewEntityBody?) {
            guard let post = post,
                  let inlinePreviewEntities = inlinePreviewEntities else { return }
            translateService.autoTranslateIfNeed(entityId: post.id,
                                                 entityType: .post,
                                                 contentLanguages: post.contentLanguages,
                                                 currentTranslateInfo: post.translationInfo,
                                                 richText: post.postContent.content,
                                                 inlinePreviewEntities: inlinePreviewEntities,
                                                 urlPreviewHangPointMap: post.urlPreviewHangPointMap,
                                                 isSelfOwner: post.isSelfOwner)
        }

        func autoTranslateIfNeed(comment: RawData.Comment?, inlinePreviewEntities: InlinePreviewEntityBody?) {
            guard let comment = comment,
                  let inlinePreviewEntities = inlinePreviewEntities else { return }
            translateService.autoTranslateIfNeed(entityId: comment.id,
                                                 entityType: .comment,
                                                 contentLanguages: comment.contentLanguages,
                                                 currentTranslateInfo: comment.translationInfo,
                                                 richText: comment.content.content,
                                                 inlinePreviewEntities: inlinePreviewEntities,
                                                 urlPreviewHangPointMap: comment.urlPreviewHangPointMap,
                                                 isSelfOwner: comment.isSelfOwner)
        }

        switch self.noticeEntity.noticeType {
        case .atInComment(let atInCommentEntity):
            autoTranslateIfNeed(comment: atInCommentEntity.comment,
                                inlinePreviewEntities: atInCommentEntity.inlinePreviewEntities)
            autoTranslateIfNeed(post: atInCommentEntity.postEntity?.post,
                                inlinePreviewEntities: atInCommentEntity.inlinePreviewEntities)
        case .follower(followerEntity: let followerEntity):
            break
        case .postReaction(postReactionEntity: let postReactionEntity):
            autoTranslateIfNeed(post: postReactionEntity.postEntity?.post,
                                inlinePreviewEntities: postReactionEntity.postEntity?.inlinePreviewEntities)
        case .commentReaction(commentReactionEntity: let commentReactionEntity):
            autoTranslateIfNeed(comment: commentReactionEntity.comment,
                                inlinePreviewEntities: commentReactionEntity.postEntity?.inlinePreviewEntities)
            autoTranslateIfNeed(post: commentReactionEntity.postEntity?.post,
                                inlinePreviewEntities: commentReactionEntity.postEntity?.inlinePreviewEntities)
        case .comment(commentEntity: let commentEntity):
            autoTranslateIfNeed(comment: commentEntity.comment,
                                inlinePreviewEntities: commentEntity.inlinePreviewEntities)
            autoTranslateIfNeed(post: commentEntity.postEntity?.post,
                                inlinePreviewEntities: commentEntity.inlinePreviewEntities)
        case .reply(replyEntity: let replyEntity):
            autoTranslateIfNeed(comment: replyEntity.comment,
                                inlinePreviewEntities: replyEntity.inlinePreviewEntities)
            autoTranslateIfNeed(comment: replyEntity.replyComment,
                                inlinePreviewEntities: replyEntity.inlinePreviewEntities)
            autoTranslateIfNeed(post: replyEntity.postEntity?.post,
                                inlinePreviewEntities: replyEntity.inlinePreviewEntities)
        case .atInPost(atInPostEntity: let atInPostEntity):
            autoTranslateIfNeed(post: atInPostEntity.postEntity?.post,
                                inlinePreviewEntities: atInPostEntity.postEntity?.inlinePreviewEntities)
        case .unknown:
            break
        }
    }

    func didEndDisplay() {
        displaying = false
    }

    //返回值：是否需要update
    func updateNoticeEntityIfNeed(targetCommentId: String, doUpdate: (RawData.Comment) -> RawData.Comment?) -> Bool {
        var needToUpdate = false
        switch noticeEntity.noticeType {
        case .atInComment(let atInCommentEntity):
            if let comment = atInCommentEntity.comment,
               comment.id == targetCommentId {
                noticeEntity.noticeType = .atInComment(atInCommentEntity: .init(postEntity: atInCommentEntity.postEntity,
                                                                                comment: doUpdate(comment),
                                                                                user: atInCommentEntity.user,
                                                                                inlinePreviewEntities: atInCommentEntity.inlinePreviewEntities))
                needToUpdate = true
            }
        case .follower(followerEntity: let followerEntity):
            break
        case .postReaction(postReactionEntity: let postReactionEntity):
            break
        case .commentReaction(commentReactionEntity: let commentReactionEntity):
            if let comment = commentReactionEntity.comment,
               comment.id == targetCommentId {
                noticeEntity.noticeType = .commentReaction(commentReactionEntity: .init(postEntity: commentReactionEntity.postEntity,
                                                                                        comment: doUpdate(comment),
                                                                                        reactionType: commentReactionEntity.reactionType,
                                                                                        reactionUser: commentReactionEntity.reactionUser))
                needToUpdate = true
            }
        case .comment(commentEntity: let commentEntity):
            if let comment = commentEntity.comment,
               comment.id == targetCommentId {
                noticeEntity.noticeType = .comment(commentEntity: .init(postEntity: commentEntity.postEntity,
                                                                        comment: doUpdate(comment),
                                                                        user: commentEntity.user,
                                                                        inlinePreviewEntities: commentEntity.inlinePreviewEntities))
                needToUpdate = true
            }
        case .reply(replyEntity: let replyEntity):
            if let comment = replyEntity.comment,
               comment.id == targetCommentId {
                noticeEntity.noticeType = .reply(replyEntity: .init(postEntity: replyEntity.postEntity,
                                                                    comment: doUpdate(comment),
                                                                    replyComment: replyEntity.replyComment,
                                                                    user: replyEntity.user,
                                                                    inlinePreviewEntities: replyEntity.inlinePreviewEntities))
                needToUpdate = true
            } else if let replyComment = replyEntity.replyComment,
                      replyComment.id == targetCommentId {
                noticeEntity.noticeType = .reply(replyEntity: .init(postEntity: replyEntity.postEntity,
                                                                    comment: replyEntity.comment,
                                                                    replyComment: doUpdate(replyComment),
                                                                    user: replyEntity.user,
                                                                    inlinePreviewEntities: replyEntity.inlinePreviewEntities))
                needToUpdate = true
            }
        case .atInPost(atInPostEntity: let atInPostEntity):
            break
        case .unknown:
            break
        }

        if needToUpdate {
            handleNoticeEntityData()
        }
        return needToUpdate
    }

    //返回值：是否需要update
    func updateNoticeEntityIfNeed(targetPostId: String, doUpdate: (RawData.PostEntity) -> RawData.PostEntity?) -> Bool {
        var needToUpdate = false
        switch noticeEntity.noticeType {
        case .atInComment(let atInCommentEntity):
            if let post = atInCommentEntity.postEntity,
               post.id == targetPostId {
                noticeEntity.noticeType = .atInComment(atInCommentEntity: .init(postEntity: doUpdate(post),
                                                                                comment: atInCommentEntity.comment,
                                                                                user: atInCommentEntity.user,
                                                                                inlinePreviewEntities: atInCommentEntity.inlinePreviewEntities))
                needToUpdate = true
            }
        case .follower(followerEntity: let followerEntity):
            break
        case .postReaction(postReactionEntity: let postReactionEntity):
            if let post = postReactionEntity.postEntity,
               post.id == targetPostId {
                noticeEntity.noticeType = .postReaction(postReactionEntity: .init(postEntity: doUpdate(post),
                                                                                  reactionType: postReactionEntity.reactionType,
                                                                                  reactionUser: postReactionEntity.reactionUser))
                needToUpdate = true
            }
        case .commentReaction(commentReactionEntity: let commentReactionEntity):
            if let post = commentReactionEntity.postEntity,
               post.id == targetPostId {
                noticeEntity.noticeType = .commentReaction(commentReactionEntity: .init(postEntity: doUpdate(post),
                                                                                        comment: commentReactionEntity.comment,
                                                                                        reactionType: commentReactionEntity.reactionType,
                                                                                        reactionUser: commentReactionEntity.reactionUser))
                needToUpdate = true
            }
        case .comment(commentEntity: let commentEntity):
            if let post = commentEntity.postEntity,
               post.id == targetPostId {
                noticeEntity.noticeType = .comment(commentEntity: .init(postEntity: doUpdate(post),
                                                                        comment: commentEntity.comment,
                                                                        user: commentEntity.user,
                                                                        inlinePreviewEntities: commentEntity.inlinePreviewEntities))
                needToUpdate = true
            }
        case .reply(replyEntity: let replyEntity):
            if let post = replyEntity.postEntity,
               post.id == targetPostId {
                noticeEntity.noticeType = .reply(replyEntity: .init(postEntity: doUpdate(post),
                                                                    comment: replyEntity.comment,
                                                                    replyComment: replyEntity.replyComment,
                                                                    user: replyEntity.user,
                                                                    inlinePreviewEntities: replyEntity.inlinePreviewEntities))
                needToUpdate = true
            }
        case .atInPost(atInPostEntity: let atInPostEntity):
            if let post = atInPostEntity.postEntity,
               post.id == targetPostId {
                noticeEntity.noticeType = .atInPost(atInPostEntity: .init(postEntity: doUpdate(post),
                                                                          user: atInPostEntity.user))
                needToUpdate = true
            }
        case .unknown:
            break
        }

        if needToUpdate {
            handleNoticeEntityData()
        }
        return needToUpdate
    }
}
