//
//  CardContent.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import RustPB

extension Basic_V1_UniversalCardEntity {
    public func getConfig() -> Basic_V1_UniversalCardEntity.Config {
        return content.config
    }
}

public struct UniversalCardContent: Equatable {
    public typealias CardJSON = String

    public let card: CardJSON
    public let attachment:Attachment

    public init(card: CardJSON, attachment: Attachment) {
        self.card = card
        self.attachment = attachment
    }

    public static func transform(pb: Basic_V1_UniversalCardEntity.Content) -> UniversalCardContent {
        return UniversalCardContent(
            card: pb.card,
            attachment: Attachment.transform(pb: pb.attachment)
        )
    }

    public static func == (left: UniversalCardContent, right: UniversalCardContent) -> Bool {
        return left.card == right.card && left.attachment == right.attachment
    }

}

extension UniversalCardContent {
    public struct Attachment: Equatable {
        // 暂时无用
        // public var summary: Basic_V1_UniversalCardEntity.SummaryContent
        public let images: Dictionary<String,Basic_V1_RichTextElement.ImageProperty>
        public let atUsers: Dictionary<String,Basic_V1_RichTextElement.AtProperty>
        public let characters: Dictionary<String,Basic_V1_UniversalCardEntity.Character>
        public let ignoreAtRemind: Bool
        public let previewImageKeyList: [String]

        public static func transform(pb: Basic_V1_UniversalCardEntity.Attachment) -> Attachment {
            return Attachment(
                images: pb.images,
                atUsers: pb.atUsers,
                characters: pb.characters,
                ignoreAtRemind: pb.ignoreAtRemind,
                previewImageKeyList: pb.previewImageKeyList
            )
        }

        public init(
            images: Dictionary<String, Basic_V1_RichTextElement.ImageProperty>,
            atUsers: Dictionary<String, Basic_V1_RichTextElement.AtProperty>,
            characters: Dictionary<String, Basic_V1_UniversalCardEntity.Character>,
            ignoreAtRemind: Bool,
            previewImageKeyList: [String]
        ) {
            self.images = images
            self.atUsers = atUsers
            self.characters = characters
            self.ignoreAtRemind = ignoreAtRemind
            self.previewImageKeyList = previewImageKeyList
        }
    }
}
