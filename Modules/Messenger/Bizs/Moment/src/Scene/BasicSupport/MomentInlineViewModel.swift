//
//  MomentInlineViewModel.swift
//  Moment
//
//  Created by 袁平 on 2021/6/28.
//

import UIKit
import Foundation
import TangramService
import LarkContainer
import RichLabel
import LarkCore
import LarkModel

public final class MomentInlineViewModel {
    static let iconColorKey = NSAttributedString.Key("moment.inline.iconColor")
    static let tagTypeKey = NSAttributedString.Key("moment.inline.tagType")

    public typealias RefreshTask = (_ push: URLPreviewPush) -> Void

    private let inlinePreviewService: InlinePreviewService
    public var refreshTask: RefreshTask?

    private var defaultFont: UIFont {
        return UIFont.systemFont(ofSize: 17, weight: .regular)
    }

    public init() {
        inlinePreviewService = InlinePreviewService()
    }

    public func subscribePush(refreshTask: RefreshTask? = nil) {
        self.refreshTask = refreshTask
        inlinePreviewService.subscribePush(ability: self)
    }

    public func getSummerizeAttrAndURL(elementID: String,
                                       commentEntity: RawData.CommentEntity,
                                       useTranslation: Bool = false,
                                       customAttributes: [NSAttributedString.Key: Any] = [:]) -> (NSMutableAttributedString?, String?)? {
        func getTranslationTitle(id: String) -> String? {
            guard useTranslation else { return nil }
            let translationTitle: String? = commentEntity.comment.translationInfo.urlPreviewTranslation[id]
            if translationTitle?.isEmpty == false {
                return translationTitle
            }
            return nil
        }

        let hangPoint = commentEntity.comment.urlPreviewHangPointMap
        if let point = hangPoint[elementID], let inlineEntity = commentEntity.inlinePreviewEntities[point.previewID] {
            let attr = getSummerizeAttr(inlineEntity: inlineEntity, customAttributes: customAttributes, title: getTranslationTitle(id: point.previewID))
            let clickURL = inlineEntity.url?.tcURL
            return (attr, clickURL)
        }
        if let translationTitle = getTranslationTitle(id: "\(commentEntity.id)-\(elementID)") {
            return (NSMutableAttributedString(string: translationTitle, attributes: customAttributes), nil)
        }
        return nil
    }

    public func getSummerizeAttrAndURL(elementID: String,
                                       postEntity: RawData.PostEntity,
                                       useTranslation: Bool = false,
                                       customAttributes: [NSAttributedString.Key: Any] = [:]) -> (NSMutableAttributedString?, String?)? {
        func getTranslationTitle(id: String) -> String? {
            guard useTranslation else { return nil }
            let translationTitle: String? = postEntity.post.translationInfo.urlPreviewTranslation[id]
            if translationTitle?.isEmpty == false {
                return translationTitle
            }
            return nil
        }

        let hangPoint = postEntity.post.urlPreviewHangPointMap
        if let point = hangPoint[elementID], let inlineEntity = postEntity.inlinePreviewEntities[point.previewID] {
            let attr = getSummerizeAttr(inlineEntity: inlineEntity, customAttributes: customAttributes, title: getTranslationTitle(id: point.previewID))
            let clickURL = inlineEntity.url?.tcURL
            return (attr, clickURL)
        }
        if let translationTitle = getTranslationTitle(id: "\(postEntity.id)-\(elementID)") {
            return (NSMutableAttributedString(string: translationTitle, attributes: customAttributes), nil)
        }
        return nil
    }

    public func getSummerizeAttrAndURL(elementID: String,
                                       comment: RawData.Comment,
                                       inlinePreviewEntities: InlinePreviewEntityBody,
                                       useTranslation: Bool = false,
                                       customAttributes: [NSAttributedString.Key: Any] = [:]) -> (NSMutableAttributedString?, String?)? {
        func getTranslationTitle(id: String) -> String? {
            guard useTranslation else { return nil }
            let translationTitle: String? = comment.translationInfo.urlPreviewTranslation[id]
            if translationTitle?.isEmpty == false {
                return translationTitle
            }
            return nil
        }

        let hangPoint = comment.urlPreviewHangPointMap
        if let point = hangPoint[elementID], let inlineEntity = inlinePreviewEntities[point.previewID] {
            let attr = getSummerizeAttr(inlineEntity: inlineEntity, customAttributes: customAttributes, title: getTranslationTitle(id: point.previewID))
            let clickURL = inlineEntity.url?.tcURL
            return (attr, clickURL)
        }
        if let translationTitle = getTranslationTitle(id: "\(comment.id)-\(elementID)") {
            return (NSMutableAttributedString(string: translationTitle, attributes: customAttributes), nil)
        }
        return nil
    }

    public func getSummerizeAttr(inlineEntity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any], title: String? = nil) -> NSMutableAttributedString? {
        // 三端对齐，title为空时不进行替换
        guard let title = title ?? inlineEntity.title, !title.isEmpty else { return nil }
        let summerize = NSMutableAttributedString()
        if let imageAttr = getImageAttr(inlineEntity: inlineEntity, customAttributes: customAttributes) {
            summerize.append(imageAttr)
        }
        summerize.append(NSAttributedString(string: title, attributes: customAttributes))
        if let tagAttr = getTagAttr(entity: inlineEntity, customAttributes: customAttributes) {
            summerize.append(tagAttr)
        }
        return summerize
    }

    public func getImageAttr(inlineEntity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard inlinePreviewService.hasIcon(entity: inlineEntity) else { return nil }
        let font = customAttributes[.font] as? UIFont ?? defaultFont
        let iconColor = (customAttributes[Self.iconColorKey] as? UIColor) ?? customAttributes[.foregroundColor] as? UIColor
        let inlineService = inlinePreviewService
        let attachMent = LKAsyncAttachment(viewProvider: {
            return inlineService.iconView(entity: inlineEntity, iconColor: iconColor)
        }, size: CGSize(width: font.pointSize, height: font.pointSize * 0.95))
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        attachMent.margin = UIEdgeInsets(top: 1, left: 2, bottom: 0, right: 4)
        let imageAttr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                           attributes: [LKAttachmentAttributeName: attachMent])
        return imageAttr
    }

    public func getTagAttr(entity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard inlinePreviewService.hasTag(entity: entity) else { return nil }
        let tag = entity.tag ?? ""
        let tagType = customAttributes[MomentInlineViewModel.tagTypeKey] as? TagType ?? .link
        let font = customAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 10)
        let inlineService = inlinePreviewService
        let attachMent = LKAsyncAttachment(viewProvider: {
            let tagView = inlineService.tagView(text: tag, titleFont: font, type: tagType)
            return tagView ?? UIView()
        }, size: inlinePreviewService.tagViewSize(text: tag, titleFont: font))
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        attachMent.margin = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 2)
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachMent])
    }
}

extension MomentInlineViewModel: InlinePreviewServiceAbility {
    public func update(push: URLPreviewPush) {
        refreshTask?(push)
    }
}

// MARK: - update entity
extension MomentInlineViewModel {
    /// return PostEntity if updated or nil with no update
    public func update(postEntity: RawData.PostEntity, pair: InlinePreviewEntityPair) -> RawData.PostEntity? {
        var needUpdate = false
        if let body = pair.inlinePreviewEntities[postEntity.post.id] {
            needUpdate = true
            postEntity.inlinePreviewEntities += body
        }
        for index in 0..<postEntity.comments.count {
            let comment = postEntity.comments[index]
            if let newComment = update(commentEntity: comment, pair: pair) {
                needUpdate = true
                // CommentEntity视为struct处理
                postEntity.comments[index] = newComment
            }
        }
        return needUpdate ? postEntity : nil
    }

    /// return CommentEntity if updated or nil with no update
    public func update(commentEntity: RawData.CommentEntity, pair: InlinePreviewEntityPair) -> RawData.CommentEntity? {
        var needUpdate = false
        if let body = pair.inlinePreviewEntities[commentEntity.comment.id] {
            needUpdate = true
            commentEntity.inlinePreviewEntities += body
        }
        if let replyEntity = commentEntity.replyCommentEntity,
           let newReply = update(commentEntity: replyEntity, pair: pair) {
            commentEntity.replyCommentEntity = newReply
            needUpdate = true
        }
        return needUpdate ? commentEntity : nil
    }
}
