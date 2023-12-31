//
//  LarkMeegoServiceImpl+Message.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/4/9.
//

import Foundation
import LarkModel
import RustPB
import LarkEmotion

private enum Agreement {
    enum MessageKey {
        static let messages = "messages"
        static let messageId = "message_id"
        static let senderName = "sender_name"
        static let time = "time"
        static let type = "type"
        static let text = "text"
        static let key = "key"
        static let width = "width"
        static let height = "height"
        static let size = "size"
        static let name = "name"
        static let mime = "mime"
        static let title = "title"
        static let elements = "elements"
        static let content = "content"
        static let url = "url"
    }
    enum ContentType: String {
        case text
        case image
        case link
        case media
    }
}

// 各类型的 Message 和 Chat 的内容提取，统一返回约定的信息结构
extension LarkMeegoServiceImpl {
    func getTextContext(message: Message) -> [String: Any] {
        if let content = message.content as? TextContent {
            let parsedText = getAgreementContexts(content.richText).compactMap { element in
                if let type = element[Agreement.MessageKey.type] as? String, type == Agreement.ContentType.text.rawValue {
                    return element[Agreement.MessageKey.content] as? String ?? ""
                }
                if let type = element[Agreement.MessageKey.type] as? String, type == Agreement.ContentType.link.rawValue {
                    return element[Agreement.MessageKey.url] as? String ?? ""
                }
                return nil
            }.joined(separator: "")

            return [
                Agreement.MessageKey.senderName: message.fromChatter?.displayName ?? "",
                Agreement.MessageKey.time: message.createTime,
                Agreement.MessageKey.type: MessageContentType.text.rawValue,
                Agreement.MessageKey.content: [
                    Agreement.MessageKey.text: parsedText
                ]
            ]
        }
        return [:]
    }

    func getImageContext(message: Message) -> [String: Any] {
        if let content = message.content as? ImageContent {
            return [
                Agreement.MessageKey.senderName: message.fromChatter?.displayName ?? "",
                Agreement.MessageKey.time: message.createTime,
                Agreement.MessageKey.type: MessageContentType.image.rawValue,
                Agreement.MessageKey.content: [
                    Agreement.MessageKey.key: content.image.origin.key,
                    Agreement.MessageKey.width: content.image.origin.width,
                    Agreement.MessageKey.height: content.image.origin.height
                ]
            ]
        }
        return [:]
    }

    func getPostContext(message: Message) -> [String: Any] {
        if let content = message.content as? PostContent {
            let agreementContexts = getAgreementContexts(content.richText)
            return [
                Agreement.MessageKey.senderName: message.fromChatter?.displayName ?? "",
                Agreement.MessageKey.time: message.createTime,
                Agreement.MessageKey.type: MessageContentType.post.rawValue,
                Agreement.MessageKey.content: [
                    Agreement.MessageKey.title: content.title,
                    Agreement.MessageKey.elements: agreementContexts
                ]
            ]
        }
        return [:]
    }

    func getAudioContext(message: Message) -> [String: Any] {
        if let content = message.content as? AudioContent {
            return [
                Agreement.MessageKey.senderName: message.fromChatter?.displayName ?? "",
                Agreement.MessageKey.time: message.createTime,
                Agreement.MessageKey.type: MessageContentType.audio.rawValue,
                Agreement.MessageKey.content: [
                    Agreement.MessageKey.key: content.key,
                    Agreement.MessageKey.size: content.size
                ]
            ]
        }
        return [:]
    }

    func getMediaContext(message: Message) -> [String: Any] {
        if let content = message.content as? MediaContent {
            return [
                Agreement.MessageKey.senderName: message.fromChatter?.displayName ?? "",
                Agreement.MessageKey.time: message.createTime,
                Agreement.MessageKey.type: MessageContentType.media.rawValue,
                Agreement.MessageKey.content: [
                    Agreement.MessageKey.key: content.key,
                    Agreement.MessageKey.name: content.name,
                    Agreement.MessageKey.size: content.size
                ]
            ]
        }
        return [:]
    }

    func getFileContext(message: Message) -> [String: Any] {
        if let content = message.content as? FileContent {
            return [
                Agreement.MessageKey.senderName: message.fromChatter?.displayName ?? "",
                Agreement.MessageKey.time: message.createTime,
                Agreement.MessageKey.type: MessageContentType.file.rawValue,
                Agreement.MessageKey.content: [
                    Agreement.MessageKey.key: content.key,
                    Agreement.MessageKey.name: content.name,
                    Agreement.MessageKey.size: content.size,
                    Agreement.MessageKey.mime: content.mime
                ]
            ]
        }
        return [:]
    }

    func getAgreementContexts(_ richText: RustPB.Basic_V1_RichText) -> [[String: Any]] {
        // 按序遍历富文本树，提取有序的叶子节点
        func pickup(
            from elements: [String: RustPB.Basic_V1_RichTextElement],
            elementIds: [String],
            leafs: inout [Basic_V1_RichTextElement]
        ) {
            for elementId in elementIds {
                guard let element = elements[elementId] else {
                    break
                }
                if element.childIds.isEmpty {
                    leafs.append(element)
                } else {
                    pickup(
                        from: elements,
                        elementIds: element.childIds,
                        leafs: &leafs
                    )
                }
            }
        }

        var sortedLeafs: [Basic_V1_RichTextElement] = []
        pickup(
            from: richText.elements,
            elementIds: richText.elementIds,
            leafs: &sortedLeafs
        )

        var agreementContexts: [[String: Any]] = []

        for element in sortedLeafs.filter { $0.hasProperty } {
            switch element.tag {
            case .text where element.property.hasText:
                agreementContexts.append([
                    Agreement.MessageKey.content: element.property.text.content,
                    Agreement.MessageKey.type: Agreement.ContentType.text.rawValue
                ])
            case .i where element.property.hasItalic:
                agreementContexts.append([
                    Agreement.MessageKey.content: element.property.italic.content,
                    Agreement.MessageKey.type: Agreement.ContentType.text.rawValue
                ])
            case .b where element.property.hasBold:
                agreementContexts.append([
                    Agreement.MessageKey.content: element.property.bold.content,
                    Agreement.MessageKey.type: Agreement.ContentType.text.rawValue
                ])
            case .u where element.property.hasUnderline:
                agreementContexts.append([
                    Agreement.MessageKey.content: element.property.underline.content,
                    Agreement.MessageKey.type: Agreement.ContentType.text.rawValue
                ])
            case .at where element.property.hasAt:
                agreementContexts.append([
                    Agreement.MessageKey.content: element.property.at.content,
                    Agreement.MessageKey.type: Agreement.ContentType.text.rawValue
                ])
            case .emotion where element.property.hasEmotion:
                let emojiText = EmotionResouce.shared.i18nBy(key: element.property.emotion.key) ?? element.property.emotion.key
                agreementContexts.append([
                    Agreement.MessageKey.content: "[\(emojiText)]",
                    Agreement.MessageKey.type: Agreement.ContentType.text.rawValue
                ])
            case .img where element.property.hasImage:
                agreementContexts.append([
                    Agreement.MessageKey.key: element.property.image.originKey,
                    Agreement.MessageKey.width: element.property.image.originWidth,
                    Agreement.MessageKey.height: element.property.image.originHeight,
                    Agreement.MessageKey.type: Agreement.ContentType.image.rawValue
                ])
            case .link where element.property.hasLink:
                agreementContexts.append([
                    Agreement.MessageKey.url: element.property.link.url,
                    Agreement.MessageKey.type: Agreement.ContentType.link.rawValue
                ])
            case .a where element.property.hasAnchor:
                agreementContexts.append([
                    Agreement.MessageKey.url: element.property.anchor.content,
                    Agreement.MessageKey.type: Agreement.ContentType.link.rawValue
                ])
            case .media where element.property.hasMedia:
                agreementContexts.append([
                    Agreement.MessageKey.key: element.property.media.key,
                    Agreement.MessageKey.name: element.property.media.name,
                    Agreement.MessageKey.size: element.property.media.size,
                    Agreement.MessageKey.mime: element.property.media.mime,
                    Agreement.MessageKey.type: Agreement.ContentType.media.rawValue
                ])
            default:
                break
            }
        }

        return agreementContexts
    }
}
