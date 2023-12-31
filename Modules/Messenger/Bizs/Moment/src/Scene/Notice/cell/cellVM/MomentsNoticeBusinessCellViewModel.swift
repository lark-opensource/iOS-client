//
//  MomentsNoticeBusinessCellViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/2/28.
//

import Foundation
import UIKit
import EENavigator
import RxSwift
import UniverseDesignToast
import LarkContainer
import Swinject

final class MomentsNoticefollowCellViewModel: MomentsNoticeBaseCellViewModel {

    private var followRequesting: Bool = false
    @ScopedInjectedLazy private var userAPI: UserApiService?
    var followable: Bool = true

    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        guard let followerEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeFollowerEntity else {
            return
        }
        user = followerEntity.followerUser
        title = getTitleAttributeStringWithText(BundleI18n.Moment.Lark_Community_NotificationFollowYou)
        reuseIdentifier = MomentUserNoticeFollowCell.getCellReuseIdentifier()
    }

    override func didSelected() {
        super.pushToUserAvatar()
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category, clickType: .followMsg)
    }

    override func maxTitleWidth() -> CGFloat {
        return 0
    }
    /// 关注用户
    func followUserWith(finish: ( @escaping (_ isFollowed: Bool) -> Void)) {
        trackCommunityNotificationEntryClick()
        switch self.noticeEntity.noticeType {
        case .follower(let followerEntity):
            guard !self.followRequesting, let pageAPI = self.context.pageAPI, let userAPI else {
                return
            }
            self.followRequesting = true
            let userID = followerEntity.followerUser?.userID ?? ""
            Tracer.trackCommunityTabFollow(source: .notification, action: !followerEntity.hadFollow, followId: userID)
            MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category,
                                                         followUserId: userID,
                                                         clickType: followerEntity.hadFollow ? .followCancel : .follow)
            if  followerEntity.hadFollow {
                userAPI.unfollowUser(byId: userID)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (_) in
                        self?.followRequesting = false
                        finish(false)
                        self?.context.dataSourceAPI?.reloadDataForFollowStatusChange(userID: userID, hadFollow: false)
                    }, onError: { [weak self] (_) in
                        finish(true)
                        self?.followRequesting = false
                        UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToUnfollow, on: pageAPI.view)
                    }).disposed(by: self.disposeBag)
            } else {
                userAPI.followUser(byId: userID)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (_) in
                        self?.followRequesting = false
                        finish(true)
                        self?.context.dataSourceAPI?.reloadDataForFollowStatusChange(userID: userID, hadFollow: true)
                    }, onError: { [weak self] (_) in
                        self?.followRequesting = false
                        UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FollowFailed, on: pageAPI.view)
                        finish(false)
                    }).disposed(by: self.disposeBag)
            }
            break
        default:
            assert(false, "该类型cell上不应该触发关注接口")
            return
        }
    }
}

final class MomentsNoticePostReactionCellViewModel: MomentsNoticeBaseCellViewModel {
    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        guard let postReactionEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticePostReactionEntity else {
            return
        }
        user = postReactionEntity.reactionUser
        title = getTitleAttributeStringWithText(BundleI18n.Moment.Lark_Community_NotificationReactYourMoment)
        let reactionType = postReactionEntity.reactionType
        appendAttachment(asyncAttachmentWithReactionType(reactionType))
        /// 如果当前帖子被删
        if postReactionEntity.postEntity?.post.isDeleted ?? false {
            showRightDeleContent()
            return
        }
        if let info = imageInfoForPost(postReactionEntity.postEntity?.post) {
            rightImageInfo = info
            reuseIdentifier = MomentUserNoticeImageCell.getCellReuseIdentifier()
        } else {
            //这里不翻译
            rightText = convertRichTextToString(richText: postReactionEntity.postEntity?.post.postContent.content,
                                                showTranslatedTag: false)
            reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
        }
    }

    override func didSelected() {
        super.didSelected()
        guard let postReactionEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticePostReactionEntity,
              let postEntity = postReactionEntity.postEntity
        else {
            return
        }
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category,
                                                     clickType: .postReaction,
                                                     circleId: postEntity.circle?.id,
                                                     postId: postEntity.postId,
                                                     pageIdInfo: .pageId(postEntity.post.categoryIds.first))
        if showPostDeleTipsIfNeedForPost(postEntity.post) {
            return
        }
        guard let from = getNavFromForPush() else { return }
        let body = MomentPostDetailByPostBody(post: postEntity, scrollState: nil, source: .notification)
        userResolver.navigator.push(body: body, from: from)
    }
}

final class MomentsNoticeCommentReactionCellViewModel: MomentsNoticeBaseCellViewModel {
    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        guard let commentReactionEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeCommentReactionEntity else {
            return
        }
        user = commentReactionEntity.reactionUser
        title = getTitleAttributeStringWithText(BundleI18n.Moment.Lark_Community_NotificationReactYourComment)
        let reactionType = commentReactionEntity.reactionType
        appendAttachment(asyncAttachmentWithReactionType(reactionType))
        if commentReactionEntity.comment?.isDeleted ?? false {
            showRightDeleContent()
            return
        }
        if let key = imageKeyForComment(commentReactionEntity.comment) {
            rightImageInfo = (false, key)
            reuseIdentifier = MomentUserNoticeImageCell.getCellReuseIdentifier()
        } else {
            //这里不翻译
            rightText = convertRichTextToString(richText: commentReactionEntity.comment?.content.content,
                                                showTranslatedTag: false)
            reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
        }

    }
    override func didSelected() {
        super.didSelected()
        guard let commentReactionEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeCommentReactionEntity,
              let postEntity = commentReactionEntity.postEntity
        else {
            return
        }
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category, clickType: .commentReaction)
        /// 当前帖子被删 给出提示
        if showPostDeleTipsIfNeedForPost(postEntity.post) {
            return
        }
        guard let from = getNavFromForPush() else { return }
        let body = MomentPostDetailByPostBody(post: postEntity,
                                              scrollState: .toCommentId(commentReactionEntity.comment?.id),
                                              source: .notification)
        userResolver.navigator.push(body: body, from: from)
    }

}
final class MomentsNoticeCommentCellViewModel: MomentsNoticeBaseCellViewModel {
    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        guard let commentEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeCommentEntity, let userGeneralSettings, let fgService else {
            return
        }
        user = commentEntity.user
        title = getTitleAttributeStringWithText(BundleI18n.Moment.Lark_Community_NotificationReplyYourMoment)
        let useTranslation = commentEntity.comment?.canShowTranslation(fgService: fgService,
                                                                       userGeneralSettings: userGeneralSettings,
                                                                       supportManualTranslate: false) ?? false
        content = contentAttrWith(comment: commentEntity.comment, userID: user?.userID ?? "", urlPreviewProvider: { elementID, customAttributes in
            guard let comment = commentEntity.comment else { return nil }
            let inlinePreviewVM = MomentInlineViewModel()
            return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                          comment: comment,
                                                          inlinePreviewEntities: commentEntity.inlinePreviewEntities,
                                                          useTranslation: useTranslation,
                                                          customAttributes: customAttributes)
        })
        if commentEntity.postEntity?.post.isDeleted ?? false {
            showRightDeleComment()
            return
        }
        if let info = imageInfoForPost(commentEntity.postEntity?.post) {
            rightImageInfo = info
            reuseIdentifier = MomentUserNoticeImageCell.getCellReuseIdentifier()
        } else {
            //这里不翻译
            rightText = convertRichTextToString(richText: commentEntity.postEntity?.post.postContent.content,
                                                showTranslatedTag: false)
            reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
        }
    }
    override func didSelected() {
        super.didSelected()
        guard let commentEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeCommentEntity,
              let postEntity = commentEntity.postEntity

        else {
            return
        }
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category,
                                                     clickType: .postReply,
                                                     circleId: postEntity.circle?.id,
                                                     postId: postEntity.postId,
                                                     pageIdInfo: .pageId(postEntity.post.categoryIds.first))
        /// 当前帖子被删 给出提示
        if showPostDeleTipsIfNeedForPost(postEntity.post) {
            return
        }
        guard let from = getNavFromForPush() else { return }
        let body = MomentPostDetailByPostBody(post: postEntity, scrollState: .toCommentId(commentEntity.comment?.id), source: .notification)
        userResolver.navigator.push(body: body, from: from)
    }
}

final class MomentsNoticeReplyCellViewModel: MomentsNoticeBaseCellViewModel {
    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        guard let replyEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeReplyEntity, let userGeneralSettings, let fgService else {
            return
        }
        user = replyEntity.user
        title = getTitleAttributeStringWithText(BundleI18n.Moment.Lark_Community_NotificationReplyYourComment)
        let useTranslation = replyEntity.comment?.canShowTranslation(fgService: fgService,
                                                                     userGeneralSettings: userGeneralSettings,
                                                                     supportManualTranslate: false) ?? false
        content = contentAttrWith(comment: replyEntity.comment, userID: user?.userID ?? "", urlPreviewProvider: { elementID, customAttributes in
            guard let comment = replyEntity.comment else { return nil }
            let inlinePreviewVM = MomentInlineViewModel()
            return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                          comment: comment,
                                                          inlinePreviewEntities: replyEntity.inlinePreviewEntities,
                                                          useTranslation: useTranslation,
                                                          customAttributes: customAttributes)
        })
        if replyEntity.replyComment?.isDeleted ?? false {
            showRightDeleComment()
            return
        }
        if let key = imageKeyForComment(replyEntity.replyComment) {
            rightImageInfo = (false, key)
            reuseIdentifier = MomentUserNoticeImageCell.getCellReuseIdentifier()
        } else {
            //这里不翻译
            rightText = convertRichTextToString(richText: replyEntity.replyComment?.content.content,
                                                showTranslatedTag: false)
            reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
        }
    }
    override func didSelected() {
        super.didSelected()
        guard let replyEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeReplyEntity,
              let postEntity = replyEntity.postEntity
        else {
            return
        }
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category, clickType: .commentReply)
        /// 当前帖子被删 给出提示
        if showPostDeleTipsIfNeedForPost(postEntity.post) {
            return
        }
        guard let from = getNavFromForPush() else { return }
        let body = MomentPostDetailByPostBody(post: postEntity, scrollState: .toCommentId(replyEntity.comment?.id), source: .notification)
        userResolver.navigator.push(body: body, from: from)
    }

}

final class MomentsNoticeAtInPostCellViewModel: MomentsNoticeBaseCellViewModel {
    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        guard let atInPostEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeAtInPostEntity, let userGeneralSettings, let fgService else {
            return
        }
        user = atInPostEntity.user
        title = getTitleAttributeStringWithText(BundleI18n.Moment.Lark_Community_NotificationMomentMention)
        let isDelete = atInPostEntity.postEntity?.post.isDeleted ?? false
        let useTranslation = atInPostEntity.postEntity?.post.canShowTranslation(fgService: fgService,
                                                                                userGeneralSettings: userGeneralSettings,
                                                                                supportManualTranslate: false) ?? false
        content = contentAttrWith(richText: atInPostEntity.postEntity?.post.getDisplayContent(fgService: fgService,
                                                                                              userGeneralSettings: userGeneralSettings,
                                                                                             supportManualTranslate: false),
                                  userID: user?.userID ?? "",
                                  isDelete: isDelete,
                                  showTranslatedTag: useTranslation,
                                  urlPreviewProvider: { elementID, customAttributes in
                                    guard let postEntity = atInPostEntity.postEntity else { return nil }
                                    let inlinePreviewVM = MomentInlineViewModel()
                                    return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                  postEntity: postEntity,
                                                                                  useTranslation: useTranslation,
                                                                                  customAttributes: customAttributes)
                                  })
        if isDelete {
            showRightDeleContent()
            return
        }
        if let info = imageInfoForPost(atInPostEntity.postEntity?.post) {
            rightImageInfo = info
            reuseIdentifier = MomentUserNoticeImageCell.getCellReuseIdentifier()
        } else {
            reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
            //这里不翻译
            rightText = convertRichTextToString(richText: atInPostEntity.postEntity?.post.postContent.content,
                                                showTranslatedTag: false)
        }
    }
    override func didSelected() {
        super.didSelected()
        guard let atInPostEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeAtInPostEntity,
              let postEntity = atInPostEntity.postEntity
        else {
            return
        }
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category,
                                                     clickType: .postMention,
                                                     circleId: postEntity.circle?.id,
                                                     postId: postEntity.postId,
                                                     pageIdInfo: .pageId(postEntity.post.categoryIds.first))
        /// 当前帖子被删 给出提示
        if showPostDeleTipsIfNeedForPost(postEntity.post) {
            return
        }
        guard let from = getNavFromForPush() else { return }
        let body = MomentPostDetailByPostBody(post: postEntity, scrollState: nil, source: .notification)
        userResolver.navigator.push(body: body, from: from)
    }

}

final class MomentsNoticeAtInCommentCellViewModel: MomentsNoticeBaseCellViewModel {
    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        guard let atInCommentEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeAtInCommentEntity, let userGeneralSettings, let fgService else {
            return
        }
        user = atInCommentEntity.user
        title = getTitleAttributeStringWithText(BundleI18n.Moment.Lark_Community_NotificationCommentMention)
        let useTranslation = atInCommentEntity.comment?.canShowTranslation(fgService: fgService,
                                                                           userGeneralSettings: userGeneralSettings,
                                                                           supportManualTranslate: false) ?? false
        content = contentAttrWith(richText: atInCommentEntity.comment?.getDisplayContent(fgService: fgService,
                                                                                         userGeneralSettings: userGeneralSettings,
                                                                                        supportManualTranslate: false),
                                  userID: user?.userID ?? "",
                                  isDelete: atInCommentEntity.comment?.isDeleted ?? false,
                                  showTranslatedTag: useTranslation,
                                  urlPreviewProvider: { elementID, customAttributes in
                                    guard let comment = atInCommentEntity.comment else { return nil }
                                    let inlinePreviewVM = MomentInlineViewModel()
                                    return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                  comment: comment,
                                                                                  inlinePreviewEntities: atInCommentEntity.inlinePreviewEntities,
                                                                                  useTranslation: useTranslation,
                                                                                  customAttributes: customAttributes)
                                  })
        if atInCommentEntity.postEntity?.post.isDeleted ?? false {
            showRightDeleContent()
            return
        }
        if let info = imageInfoForPost(atInCommentEntity.postEntity?.post) {
            rightImageInfo = info
            reuseIdentifier = MomentUserNoticeImageCell.getCellReuseIdentifier()
        } else {
            //这里不翻译
            rightText = convertRichTextToString(richText: atInCommentEntity.postEntity?.post.postContent.content,
                                                showTranslatedTag: false)
            reuseIdentifier = MomentUserNoticeTextCell.getCellReuseIdentifier()
        }
    }

    override func didSelected() {
        super.didSelected()
        guard let atInCommentEntity = self.noticeEntity.noticeType.getBinderData() as? RawData.NoticeAtInCommentEntity,
              let postEntity = atInCommentEntity.postEntity
        else {
            return
        }
        MomentsTracer.trackNotificationPageClickWith(type: noticeEntity.category, clickType: .commentMention)
        /// 当前帖子被删 给出提示
        if showPostDeleTipsIfNeedForPost(postEntity.post) {
            return
        }
        guard let from = getNavFromForPush() else { return }
        let body = MomentPostDetailByPostBody(post: postEntity,
                                              scrollState: .toCommentId(atInCommentEntity.comment?.id),
                                              source: .notification)
        userResolver.navigator.push(body: body, from: from)
    }
}

final class MomentsNoticePostUnknownCellViewModel: MomentsNoticeBaseCellViewModel {
    override func handleNoticeEntityData() {
        super.handleNoticeEntityData()
        let attribute = attributesWith(font: UIFont.systemFont(ofSize: 17), color: UIColor.ud.textTitle)
        content = NSAttributedString(string: BundleI18n.Moment.Lark_Community_IncludeUnsupportedContentTypes,
                                     attributes: attribute)
        reuseIdentifier = MomentNoticeUnknownCell.getCellReuseIdentifier()
    }
    override func hadContent() -> Bool {
        return true
    }
}
