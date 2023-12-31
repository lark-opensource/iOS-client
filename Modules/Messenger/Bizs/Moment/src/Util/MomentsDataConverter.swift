//
//  MomentsDataConverter.swift
//  Moment
//
//  Created by liluobin on 2021/1/26.
//

import Foundation
import UIKit
import LarkModel
import LarkMessageCore
import LarkCore
import LKCommonsLogging
import TangramService
import LarkSDKInterface
import LarkEmotion
import RichLabel
import RustPB
import LarkContainer
import LarkSetting

final class MomentsDataConverter {
    static let logger = Logger.log(MomentsDataConverter.self, category: "Module.Moments.MomentsDataConverter ")
    static func convertReactionsToReactionListEntities(entityId: String, entities: RawData.Entitys, reactions: [RawData.ReactionList]) -> [RawData.ReactionListEntity] {
        reactions.map { (reactionInfo) -> RawData.ReactionListEntity in
            let firstPageUsers = reactionInfo.firstPageUserIds.compactMap { (userId) -> MomentUser? in
                return entities.users[userId]
            }
            if firstPageUsers.count != reactionInfo.firstPageUserIds.count {
                Self.logger.warn("convertReactionsToReactionListEntities miss reaction user \(entityId) \(reactionInfo.firstPageUserIds.count) \(firstPageUsers.count)")
            }
            return RawData.ReactionListEntity(reactionList: reactionInfo, firstPageUsers: firstPageUsers)
        }
    }

    static func convertCommentToCommentEntitiy(entities: RawData.Entitys, comment: RawData.Comment, replyComment: RawData.Comment? = nil) -> RawData.CommentEntity {
        let user = entities.users[comment.userID]
        let userExtraFields = entities.userExtraInfos[comment.userID]?.profileFields ?? []
        let reactionListEntities = convertReactionsToReactionListEntities(entityId: comment.id, entities: entities, reactions: comment.reactionSet.reactions)

        /// 回复的消息存在的时候
        let replyUser = entities.users[comment.replyCommentUserID]
        let replyComment = replyComment ?? entities.comments[comment.replyCommentID]
        var replayCommentEntity: RawData.CommentEntity?
        if let replyUser = replyUser, let replyComment = replyComment {
            var replyInlineEntities = InlinePreviewEntityBody()
            if let pair = entities.previewEntities[replyComment.id] {
                replyInlineEntities = InlinePreviewEntity.transform(from: pair)
            }
            replayCommentEntity = RawData.CommentEntity(comment: replyComment,
                                                        user: replyUser,
                                                        userExtraFields: userExtraFields,
                                                        replyCommentEntity: nil,
                                                        replyUser: nil,
                                                        inlinePreviewEntities: replyInlineEntities)
        }
        if user == nil {
            Self.logger.warn("commentEntitiy miss user \(comment.id) \(comment.userID)")
        }
        var inlineEntities = InlinePreviewEntityBody()
        if let pair = entities.previewEntities[comment.id] {
            inlineEntities = InlinePreviewEntity.transform(from: pair)
        }
        return RawData.CommentEntity(comment: comment,
                                     user: user,
                                     userExtraFields: userExtraFields,
                                     replyCommentEntity: replayCommentEntity,
                                     replyUser: replyUser,
                                     reactionListEntities: reactionListEntities,
                                     inlinePreviewEntities: inlineEntities)
    }

    static func convertCommentToAttributedStringWith(userResolver: UserResolver,
                                                     comment: RawData.CommentEntity?,
                                                     userGeneralSettings: UserGeneralSettings,
                                                     fgService: FeatureGatingService,
                                                     lineBreakMode: NSLineBreakMode = .byWordWrapping,
                                                     ignoreTranslation: Bool = false) -> NSAttributedString? {
        if let comment = comment {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            let font = UIFont.systemFont(ofSize: 14)
            let textColor = UIColor.ud.N500
            let textAttribute: [NSAttributedString.Key: Any] = [
                .foregroundColor: textColor,
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
            // 如果评论被删除了 直接展示文案
            if comment.comment.isDeleted {
                return NSAttributedString(string: BundleI18n.Moment.Lark_Community_TheCommentHasBeenDeleted, attributes: textAttribute)
            }
            let displayName = comment.userDisplayName
            let richText = ignoreTranslation ? comment.comment.content.content : comment.comment.getDisplayContent(fgService: fgService, userGeneralSettings: userGeneralSettings)
            let useTranslation = ignoreTranslation ? false : comment.comment.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
            let urlPreviewProvider: LarkCoreUtils.URLPreviewProvider = { elementID, customAttributes in
                let inlinePreviewVM = MomentInlineViewModel()
                return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                              commentEntity: comment,
                                                              useTranslation: useTranslation,
                                                              customAttributes: customAttributes)
            }
            let parser = RichTextAbilityParser(userResolver: userResolver,
                                               richText: richText,
                                               font: font,
                                               showTranslatedTag: useTranslation,
                                               textColor: textColor,
                                               iconColor: textColor,
                                               tagType: .normal,
                                               needNewLine: false,
                                               needCheckFromMe: false,
                                               urlPreviewProvider: urlPreviewProvider)
            let contentAttrStr = parser.attributedString
            contentAttrStr.addAttributes(textAttribute, range: NSRange(location: 0, length: contentAttrStr.length))
            let mutableAttributedString: NSMutableAttributedString = NSMutableAttributedString(string: "\(displayName): ", attributes: textAttribute)
            mutableAttributedString.append(contentAttrStr)
            if comment.comment.content.hasImageSet {
                mutableAttributedString.append(NSAttributedString(string: BundleI18n.Moment.Lark_Community_Picture, attributes: textAttribute))
            }
            return mutableAttributedString
        }
        return nil
    }

    static func addAttributesForAttributeString(_ attr: NSMutableAttributedString,
                                                font: UIFont,
                                                textColor: UIColor) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        let textAttribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        attr.addAttributes(textAttribute, range: NSRange(location: 0, length: attr.length))
        return attr
    }

    static func getImageSetThumbnailKey(imageSet: RawData.ImageSet) -> String {
        if !imageSet.thumbnail.key.isEmpty {
            return imageSet.thumbnail.key
        }
        if !imageSet.middle.key.isEmpty {
            return imageSet.middle.key
        }
        if !imageSet.origin.key.isEmpty {
            return imageSet.origin.key
        }
        return ""
    }

    static func attributedStringWithReactionTypes(_ types: [String], font: UIFont = UIFont.systemFont(ofSize: 16)) -> NSAttributedString {
        let attachments = Self.asyncAttachmentsWithReactionTypes(types, font: font)
        let attr = NSMutableAttributedString()
        attachments.forEach { (attachment) in
            attr.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [
                LKAttachmentAttributeName: attachment
            ]))
        }
        return attr
    }

    static func asyncAttachmentsWithReactionTypes(_ types: [String], font: UIFont = UIFont.systemFont(ofSize: 16)) -> [LKAsyncAttachment] {
        return types.map { (type) -> LKAsyncAttachment in
            var image = EmotionResouce.placeholder
            if let icon = EmotionResouce.shared.imageBy(key: type) {
                image = icon
            }
            let width = image.size.width / (image.size.height / font.lineHeight)
            let newSize = CGSize(width: width, height: font.lineHeight)
            let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
                let imageView = UIImageView()
                imageView.image = image
                return imageView
            }, size: newSize)
            attachment.fontAscent = font.ascender
            attachment.fontDescent = font.descender
            return attachment
        }
    }

    static func widthForString(_ string: String, font: UIFont) -> CGFloat {
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }

    static func heightForString(_ string: String, onWidth: CGFloat, font: UIFont) -> CGFloat {
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: onWidth, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.height)
    }

    static func transformSenceToPageSource(_ sence: MomentContextScene) -> MomentsDetialPageSource? {
        var source: MomentsDetialPageSource?
        switch sence {
        case .feed:
            source = .feed
        case .profile:
            source = .profile
        case .postDetail, .categoryDetail, .hashTagDetail, .unknown:
            break
        }
        return source
    }

    static func asyncTrans(imageMediaInfos: [PostImageMediaInfo]?,
                           finish: @escaping ([RawData.ImageInfo]?, RawData.MediaInfo?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            var imageInfos: [RawData.ImageInfo] = []
            var mediaInfos: [RawData.MediaInfo] = []
            if let imageMediaInfos = imageMediaInfos {
                for item in imageMediaInfos {
                    if let imageItem = item.imageInfo {
                        var imageInfo = RawData.ImageInfo()
                        imageInfo.width = Int32(imageItem.width)
                        imageInfo.height = Int32(imageItem.height)
                        imageInfo.token = imageItem.token
                        imageInfo.localPath = imageItem.localPath
                        imageInfos.append(imageInfo)
                    }

                    if let videoItem = item.videoInfo {
                        var imageInfo = RawData.ImageInfo()
                        imageInfo.width = Int32(videoItem.corveImage.width)
                        imageInfo.height = Int32(videoItem.corveImage.height)
                        imageInfo.token = videoItem.corveImage.token
                        imageInfo.localPath = videoItem.corveImage.localPath

                        var videoInfo = RawData.MediaInfo()
                        videoInfo.width = Int32(videoItem.videoInfo.width)
                        videoInfo.height = Int32(videoItem.videoInfo.height)
                        videoInfo.driveToken = videoItem.videoInfo.token
                        videoInfo.localPath = videoItem.videoInfo.localPath
                        videoInfo.cover = imageInfo
                        videoInfo.durationSec = Int32(videoItem.videoDurationSec)
                        mediaInfos.append(videoInfo)
                    }
                }
            }
            let imageList: [RawData.ImageInfo]? = !imageInfos.isEmpty ? imageInfos : nil
            let mediaInfo: RawData.MediaInfo? = !mediaInfos.isEmpty ? mediaInfos.first : nil
            finish(imageList, mediaInfo)
        }
    }
}
