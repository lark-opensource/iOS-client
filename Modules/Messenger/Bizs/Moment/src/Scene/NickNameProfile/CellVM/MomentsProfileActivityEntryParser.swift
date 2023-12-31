//
//  MomentsProfileActivityEntryParser.swift
//  Moment
//
//  Created by ByteDance on 2022/7/29.
//

import Foundation
import LarkUIKit
import RichLabel
import LarkEmotion
import LarkContainer
import Swinject
import RxSwift
import SnapKit
import LarkBizAvatar
import UIKit

struct ProfileActivityTitleConfig {
    let nameFont: UIFont
    let nameColor: UIColor
    let contentFont: UIFont
    let contentColor: UIColor
    static func defaultConfig() -> ProfileActivityTitleConfig {
        return ProfileActivityTitleConfig(nameFont: UIFont.systemFont(ofSize: 17, weight: .medium),
                                          nameColor: UIColor.ud.textTitle,
                                          contentFont: UIFont.systemFont(ofSize: 17, weight: .medium),
                                          contentColor: UIColor.ud.textPlaceholder)
    }
}

final class MomentsProfileActivityEntryParser: NSObject {

    static func titleParseFor(_ activityEntry: RawData.ProfileActivityEntry,
                              user: MomentUser?,
                              config: ProfileActivityTitleConfig = ProfileActivityTitleConfig.defaultConfig(),
                              avatarTap: ((MomentUser?) -> Void)? = nil) -> NSAttributedString {
        guard let user = user else {
            assertionFailure("keep current sence")
            return NSAttributedString()
        }
        let placeholderText = "&&*&&"
        let placeholderView = "##*##"
        let userName = "\(user.displayName)"
        let nameAttribteStr = NSAttributedString(string: userName, attributes: [.foregroundColor: config.nameColor,
                                                                                .font: config.nameFont])
        switch activityEntry.type {
        case .unknown:
            return NSAttributedString(string: BundleI18n.Moment.Moments_UnableToViewUpdateToLatestVersion_Text,
                                      attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                   .font: UIFont.systemFont(ofSize: 17)])
        case .publishPost(let publishPostEntry):
            return NSAttributedString()
        case .commentToPost(let commentToPostEntry):
            let text = BundleI18n.Moment.Moments_ProfilePagePosts_NameCommented_Text(placeholderText)
            var title = NSMutableAttributedString(string: text, attributes: [.foregroundColor: config.contentColor,
                                                                                      .font: config.contentFont])
            let range = (text as NSString).range(of: placeholderText)
            title.replaceCharacters(in: range, with: nameAttribteStr)
            return title
        case .replyToComment(let replyToCommentEntry):
            let text = BundleI18n.Moment.Moments_ProfilePagePosts_NameRepliedComment_Text(placeholderText)
            var title = NSMutableAttributedString(string: text, attributes: [.foregroundColor: config.contentColor,
                                                                                      .font: config.contentFont])
            let range = (text as NSString).range(of: placeholderText)
            title.replaceCharacters(in: range, with: nameAttribteStr)
            return title
        case .reactionToPost(let reactionToPostEntry):
            let text = BundleI18n.Moment.Moments_ProfilePagePosts_NameReactedPost_Text(placeholderText, placeholderView)
            let textRange = (text as NSString).range(of: placeholderText)
            var title = NSMutableAttributedString(string: text, attributes: [.foregroundColor: config.contentColor,
                                                                                      .font: config.contentFont])
            title.replaceCharacters(in: textRange, with: nameAttribteStr)
            let viewRange = (title.string as NSString).range(of: placeholderView)
            title.replaceCharacters(in: viewRange, with: asyncAttachmentWithReactionType(reactionToPostEntry.reactionType, font: config.contentFont))
            return title
        case .reactionToCommment(let reactionToCommmentEntry):
            let text = BundleI18n.Moment.Moments_ProfilePagePosts_NameReactedComment_Text(placeholderText, placeholderView)
            var title = NSMutableAttributedString(string: text, attributes: [.foregroundColor: config.contentColor,
                                                                                      .font: config.contentFont])
            let textRange = (text as NSString).range(of: placeholderText)
            title.replaceCharacters(in: textRange, with: nameAttribteStr)
            let viewRange = (title.string as NSString).range(of: placeholderView)
            title.replaceCharacters(in: viewRange, with: asyncAttachmentWithReactionType(reactionToCommmentEntry.reactionType, font: config.contentFont))
            return title
        case .followUser(let followUserEntry):
            let text = BundleI18n.Moment.Moments_ProfilePagePosts_NameFollowed_Text(placeholderText, placeholderView)
            var title = NSMutableAttributedString(string: text, attributes: [.foregroundColor: config.contentColor,
                                                                                      .font: config.contentFont])
            let textRange = (text as NSString).range(of: placeholderText)
            title.replaceCharacters(in: textRange, with: nameAttribteStr)
            let followAttr = NSMutableAttributedString()
            followAttr.append(asyncAttachmentWithUser(followUserEntry.followUser, avatarTap: avatarTap, font: config.nameFont))
            followAttr.append(NSAttributedString(string: "\(followUserEntry.followUser?.displayName ?? "")",
                                                 attributes: [.foregroundColor: config.nameColor,
                                                               .font: config.nameFont]))
            let viewRange = (title.string as NSString).range(of: placeholderView)
            title.replaceCharacters(in: viewRange, with: followAttr)
            return title
        }
    }

    static func asyncAttachmentWithReactionType(_ type: String, font: UIFont = UIFont.systemFont(ofSize: 16)) -> NSAttributedString {
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
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [LKAttachmentAttributeName:
                                                                                            attachment])
    }

    static func asyncAttachmentWithUser(_ user: MomentUser?,
                                        avatarTap: ((MomentUser?) -> Void)?,
                                        font: UIFont = UIFont.systemFont(ofSize: 16)) -> NSAttributedString {
        guard let user = user else {
            return NSAttributedString()
        }

        let size = CGSize(width: 24, height: 24)
        let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
            let avatarView = BizAvatar()
            avatarView.setAvatarByIdentifier(user.userID,
                                             avatarKey: user.avatarKey,
                                             scene: .Moments,
                                             avatarViewParams: .init(sizeType: .size(size.width)))
            avatarView.onTapped = { _ in
                avatarTap?(user)
            }
            return avatarView
        }, size: size)
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName:
                                               attachment])
    }

}
