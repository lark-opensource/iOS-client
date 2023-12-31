//
//  PostContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public struct PostContent: MessageContent, HasAtUsers {
    public typealias PBModel = RustPB.Basic_V1_Message
    public typealias TranslatePBModel = RustPB.Basic_V1_TranslateInfo

    public let title: String
    public let text: String
    public let isGroupAnnouncement: Bool
    public var botIds: [String] = []
    public let previewUrls: [PreviewUrlContent]
    public var docEntity: RustPB.Basic_V1_DocEntity?
    // URL InlinePreview，key: previewID
    public var inlinePreviewEntities: [String: InlinePreviewEntity] = [:]
    // 消息链接化场景需要使用previewID做资源鉴权
    public var authToken: String?
    /// 消息的参考引用链接
    public var contentReferences: [Basic_V1_Content.Reference] = []
    public var richText: RustPB.Basic_V1_RichText
    /// for NER(Named-entity recognition)
    public var abbreviation: RustPB.Basic_V1_Abbreviation?
    public var typedElementRefs: [String: RustPB.Basic_V1_ElementRefs]?
    // 富文本消息内部的图片翻译信息
    public var imageTranslationInfo: Basic_V1_ImageTranslationInfo?

    public init(
        title: String,
        text: String,
        isGroupAnnouncement: Bool,
        richText: RustPB.Basic_V1_RichText,
        previewUrls: [PreviewUrlContent],
        docEntity: RustPB.Basic_V1_DocEntity?,
        abbreviation: RustPB.Basic_V1_Abbreviation?,
        typedElementRefs: [String: RustPB.Basic_V1_ElementRefs]?
    ) {
        self.title = title
        self.text = text
        self.isGroupAnnouncement = isGroupAnnouncement
        self.richText = richText
        self.abbreviation = abbreviation
        self.previewUrls = previewUrls
        self.docEntity = docEntity
        self.typedElementRefs = typedElementRefs
    }

    public static func transform(pb: PBModel) -> PostContent {
        return PostContent(
            title: pb.content.title,
            text: pb.content.text,
            isGroupAnnouncement: pb.content.isGroupAnnouncement,
            richText: pb.content.richText,
            previewUrls: pb.content.previewUrls,
            docEntity: pb.content.hasDocEntity ? pb.content.docEntity : nil,
            abbreviation: pb.content.hasAbbreviation ? pb.content.abbreviation : nil,
            typedElementRefs: pb.content.typedElementRefs
        )
    }

    public static func transform(pb: RustPB.Basic_V1_TranslateInfo) -> PostContent {
        // server不会主动替换富文本中的图片节点，图片节点对应的译图信息需要端上从imageTranslationInfo取出手动替换
        var richText = pb.content.richText
        var leafs: [String: RustPB.Basic_V1_RichTextElement] = [:]
        PostContent.parseRichText(elements: richText.elements,
                                  elementIds: richText.elementIds,
                                  leafs: &leafs)
        for (elementId, element) in leafs {
            /// 只替换图片节点即可
            if element.tag == .img {
                let imageProperty = element.property.image
                let fixedImageKey = fixedTranslatedImageKey(originKey: imageProperty.originKey)
                if let imageSet = pb.imageTranslationInfo.translatedImages[fixedImageKey]?.translatedImageSet {
                    /// 替换 image property
                    let newImageProperty = imageProperty.modifiedImageProperty(imageSet)
                    richText.elements[elementId]?.property.image = newImageProperty
                }
            }
        }
        var content = PostContent(
            title: pb.content.title,
            text: pb.content.text,
            isGroupAnnouncement: pb.content.isGroupAnnouncement,
            richText: richText,
            previewUrls: pb.content.previewUrls,
            docEntity: pb.content.hasDocEntity ? pb.content.docEntity : nil,
            abbreviation: pb.content.hasAbbreviation ? pb.content.abbreviation : nil,
            typedElementRefs: pb.content.typedElementRefs
        )
        content.imageTranslationInfo = pb.imageTranslationInfo

        return content
    }

    /// 解析RustPB.Basic_V1_RichText,将所有叶子结点有序输出
    public static func parseRichText(elements: [String: RustPB.Basic_V1_RichTextElement], elementIds: [String], leafs: inout [String: RustPB.Basic_V1_RichTextElement]) {
        for elementId in elementIds {
            if let element = elements[elementId] {
                if element.childIds.isEmpty {
                    leafs[elementId] = element
                } else {
                    parseRichText(elements: elements, elementIds: element.childIds, leafs: &leafs)
                }
            }
        }
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let translatePB = entity.translateMessages[message.id] {
            message.translateState = .translated
            message.atomicExtra.unsafeValue.translateContent = PostContent.transform(pb: translatePB)
        }

        if let pb = entity.messages[message.id] ?? entity.ephemeralMessages[message.id] {
            let entities = InlinePreviewEntity.transform(entity: entity, pb: pb)
            self.inlinePreviewEntities = entities
            self.contentReferences = pb.content.contentReferences
        }
    }

    public mutating func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message) {
        if let id = Int64(message.id), let pb = messageLink.entities[id]?.message {
            self.inlinePreviewEntities = InlinePreviewEntity.transform(messageLink: messageLink, pb: pb)
        }
        self.authToken = previewID
    }

    /// server下发下来的译图信息的key是不带品质前缀的，妥协历史原因，这里需要特殊处理下
    private static func fixedTranslatedImageKey(originKey: String) -> String {
        /// 待截断的图片品质前缀范围
        let imageQualityPrefixs = ["origin:", "middle:", "thumbnail:"]
        var fixedKey = originKey
        for prefix in imageQualityPrefixs {
            fixedKey = fixedKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
        }
        return fixedKey
    }
}
