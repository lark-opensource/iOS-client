//
//  MergeForwardCardItem.swift
//  LarkCore
//
//  Created by liluobin on 2021/6/21.
//
import Foundation
import UIKit
import LarkModel
import RustPB
import ByteWebImage
import LarkMessengerInterface

public struct MergeForwardCardItem {
    public let title: String
    public let content: String
    public let imageKey: String
    public let fromTitle: String
    public let fromAvatarKey: String
    public let fromAvatarEntityId: String
    /// 是否是群成员
    public let isGroupMember: Bool
    public let previewPermission: (Bool, ValidateResult?)
    public init(title: String,
         content: String,
         imageKey: String,
         fromTitle: String,
         fromAvatarKey: String,
                fromAvatarEntityId: String,
         isGroupMember: Bool,
                previewPermission: (Bool, ValidateResult?) = (true, nil)) {
        self.title = title
        self.content = content
        self.imageKey = imageKey
        self.fromTitle = fromTitle
        self.fromAvatarKey = fromAvatarKey
        self.fromAvatarEntityId = fromAvatarEntityId
        self.isGroupMember = isGroupMember
        self.previewPermission = previewPermission
    }
    static public func getImageKeyForMergeForwardMessage(_ message: Message) -> String? {
        guard let item = getImageSetForMergeForwardMessage(message) else {
            return nil
        }
        return item.thumbnail?.key
    }

    static public func getImageSetForMergeForwardMessage(_ message: Message) -> ImageItemSet? {
        guard let content = message.content as? MergeForwardContent else {
            return nil
        }
        if let rootMessage = content.messages.first,
           rootMessage.type == .post,
           let richText = (rootMessage.content as? PostContent)?.richText,
           let firstImageID = richText.imageIds.first,
           let element = richText.elements[firstImageID]?.property.image {
            return ImageItemSet.transform(imageProperty: element)
        }
        return nil
    }

    static public func getImagePropertyForMergeForwardMessage(_ message: Message) -> RustPB.Basic_V1_RichTextElement.ImageProperty? {
        guard let content = message.content as? MergeForwardContent else {
            return nil
        }
        if let rootMessage = content.messages.first,
           rootMessage.type == .post,
           let richText = (rootMessage.content as? PostContent)?.richText,
           let firstImageID = richText.imageIds.first {
            return richText.elements[firstImageID]?.property.image
        }
        return nil
    }

}
