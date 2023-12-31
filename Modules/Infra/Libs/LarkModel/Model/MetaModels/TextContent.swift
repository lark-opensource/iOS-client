//
//  TextContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public typealias PreviewUrlContent = RustPB.Basic_V1_PreviewUrlContent
public typealias PreviewVideo = RustPB.Basic_V1_PreviewVideo
public typealias VideoSite = RustPB.Basic_V1_PreviewVideo.Site

public struct TextContent: MessageContent, HasAtUsers {
    public typealias PBModel = RustPB.Basic_V1_Message
    public typealias TranslatePBModel = RustPB.Basic_V1_TranslateInfo

    public let text: String
    public let previewUrls: [PreviewUrlContent]
    public var richText: RustPB.Basic_V1_RichText
    /// for NER(Named-entity recognition)
    public var typedElementRefs: [String: RustPB.Basic_V1_ElementRefs]?
    public var abbreviation: RustPB.Basic_V1_Abbreviation?
    public var docEntity: RustPB.Basic_V1_DocEntity?
    // URL InlinePreview，key: previewID
    public var inlinePreviewEntities: [String: InlinePreviewEntity] = [:]
    /// 消息的参考引用链接
    public var contentReferences: [Basic_V1_Content.Reference] = []
    public var botIds: [String] = []

    public init(
        text: String,
        previewUrls: [PreviewUrlContent],
        richText: RustPB.Basic_V1_RichText,
        docEntity: RustPB.Basic_V1_DocEntity?,
        abbreviation: RustPB.Basic_V1_Abbreviation?,
        typedElementRefs: [String: RustPB.Basic_V1_ElementRefs]?
    ) {
        self.text = text
        self.previewUrls = previewUrls
        self.richText = richText
        self.docEntity = docEntity
        self.abbreviation = abbreviation
        self.typedElementRefs = typedElementRefs
    }

    public static func transform(pb: PBModel) -> TextContent {
        return TextContent(
            text: pb.content.text,
            previewUrls: pb.content.previewUrls,
            richText: pb.content.richText,
            docEntity: pb.content.hasDocEntity ? pb.content.docEntity : nil,
            abbreviation: pb.content.hasAbbreviation ? pb.content.abbreviation : nil,
            typedElementRefs: pb.content.typedElementRefs
        )
    }

    public static func transform(pb: TranslatePBModel) -> TextContent {
        return TextContent(
            text: pb.content.text,
            previewUrls: pb.content.previewUrls,
            richText: pb.content.richText,
            docEntity: pb.content.hasDocEntity ? pb.content.docEntity : nil,
            abbreviation: pb.content.hasAbbreviation ? pb.content.abbreviation : nil,
            typedElementRefs: pb.content.typedElementRefs
        )
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let translatePB = entity.translateMessages[message.id] {
            message.translateState = .translated
            message.atomicExtra.unsafeValue.translateContent = TextContent.transform(pb: translatePB)
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
    }
}
