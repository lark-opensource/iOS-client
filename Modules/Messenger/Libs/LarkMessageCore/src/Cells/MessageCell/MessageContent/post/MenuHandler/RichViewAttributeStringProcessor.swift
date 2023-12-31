//
//  RichViewAttributeStringProcessor.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/10/12.
//

import UIKit
import LarkModel
import RustPB
import LarkBaseKeyboard
import LarkCore
import ByteWebImage
import LKCommonsLogging

/// 由于消息部分，未来会直接提供richText，未来这个类会废弃
/// 这个类只是对CopyToPasteboardManager里面公共的方法做了抽离 不做大的改动&设计

class RichViewAttributeStringProcessor {
    private static let logger = Logger.log(RichViewAttributeStringProcessor.self, category: "RichViewAttributeStringProcessor")
    let message: Message?
    let originAttr: NSAttributedString
    private let formAttr: NSMutableAttributedString
    private let toAttr: NSMutableAttributedString

    var targeAttr: NSMutableAttributedString {
        return Self.deleStringForRemoveKey(attr: toAttr)
    }

    init(fromMessage: Message?, attr: NSAttributedString) {
        self.message = fromMessage
        self.originAttr = attr
        self.formAttr = NSMutableAttributedString(attributedString: attr)
        self.toAttr = NSMutableAttributedString(attributedString: attr)
    }

    func handPartialAllTag(canCopy: Bool = true) -> NSAttributedString {
        _ = self.handleEmoji()
        _ = self.handleCodeBlock()
        _ = self.handleImageAndVideo(canCopy: true)
        _ = self.handleAnchorAndLink()
        _ = self.handlePartialAt()
        _ = self.handlePartialAnchor()
        return targeAttr
    }

    /// - Returns: 是否处理了Emoji节点
    func handleEmoji() -> Bool {
        var needHandle = false
        let copyEmojiKey: String = "message.copy.emoji.key"
        let copyEmojiKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: copyEmojiKey)
        formAttr.enumerateAttribute(copyEmojiKeyAttributedKey, in: NSRange(location: 0, length: formAttr.length), options: .longestEffectiveRangeNotRequired) { value, range, _ in
            if let emojiKey = value as? String {
                toAttr.removeAttribute(copyEmojiKeyAttributedKey, range: range)
                let attributeStrValue = EmotionTransformer.attributeStrValueForKey("[\(emojiKey)]")
                toAttr.addAttributes([EmotionTransformer.EmojiAttributedKey: attributeStrValue], range: range)
                needHandle = true
            }
        }
        return needHandle
    }

    func handleCodeBlock() -> Bool {
        let copyCodeKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.code.key")
        // 指定longestEffectiveRangeNotRequired，使相邻的代码块分开进行返回
        let placeholder = "[code_block]"
        var ranges: [NSRange] = []
        var needHandle = false
        formAttr.enumerateAttribute(copyCodeKeyAttributedKey, in: NSRange(location: 0, length: formAttr.length), options: [.longestEffectiveRangeNotRequired]) { info, range, _ in
            // enumerateAttribute会遍历所有Range，并且都会输出，所以这里要做判断
            if let info = info as? Basic_V1_RichTextElement.CodeBlockV2Property {
                toAttr.removeAttribute(copyCodeKeyAttributedKey, range: range)
                toAttr.addAttributes([CodeTransformer.editCodeKey: info], range: range)
                ranges.append(range)
                Self.addRemoveKeyForNextNewLineCharacter(attr: toAttr, range: range)
                needHandle = true
            }
        }
        /// 需要保持formAttr & toAttr一致
        ranges.reversed().forEach { range in
            formAttr.replaceCharacters(in: range, with: placeholder)
            toAttr.replaceCharacters(in: range, with: placeholder)
        }
        return needHandle
    }

    func handleImageAndVideo(canCopy: Bool) -> (needHandle: Bool, interceptCopyResource: Bool) {
        var needHandle = false
        let copyImageKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.image.key")
        var interceptCopyResource = false
        formAttr.enumerateAttribute(copyImageKeyAttributedKey, in: NSRange(location: 0,
                                                                           length: formAttr.length),
                                    options: [.longestEffectiveRangeNotRequired],
                                    using: { info, range, _  in
            if let info = info as? Basic_V1_RichTextElement.ImageProperty {
                if canCopy {
                    let size = CGSize(width: CGFloat(info.originWidth), height: CGFloat(info.originHeight))
                    let thumbKey = ImageItemSet.transform(imageProperty: info).getThumbKey()
                    let imageInfo = ImageTransformInfo(key: info.originKey,
                                                       localKey: info.originKey,
                                                       imageSize: size,
                                                       type: .remote,
                                                       useOrigin: info.isOriginSource,
                                                       fromCopy: true,
                                                       thumbKey: thumbKey,
                                                       resizedImageSize: CGSize(width: Int(info.width), height: Int(info.height)),
                                                       token: info.token,
                                                       authToken: getAuthToken())
                    toAttr.removeAttribute(copyImageKeyAttributedKey, range: range)
                    toAttr.addAttributes([ImageTransformer.RemoteImageAttachmentAttributedKey: imageInfo], range: range)
                    Self.addRemoveKeyForNextNewLineCharacter(attr: toAttr, range: range)
                    needHandle = true
                } else {
                    interceptCopyResource = true
                }
            }
        })
        Self.logger.info("CopyToPasteboardManager copyData copyMessage localStatus:\(self.message?.localStatus) \(canCopy) \(self.message?.id) -\(self.message?.channel.id)")
        let copyVideoKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.video.key")
        let localStatus = self.message?.localStatus ?? .success
        formAttr.enumerateAttribute(copyVideoKeyAttributedKey,
                                    in: NSRange(location: 0, length: formAttr.length),
                                    options: [.longestEffectiveRangeNotRequired], using: { info, range, _  in
            if localStatus == .success, var info = info as? Basic_V1_RichTextElement.MediaProperty {
                if canCopy {
                    info.needCopyImg = !info.cryptoToken.isEmpty
                    info.needCopyMedia = !info.cryptoToken.isEmpty
                    let videoInfo = VideoTransformer.transformMediaElement(info)
                    videoInfo.authToken = getAuthToken()
                    toAttr.removeAttribute(copyVideoKeyAttributedKey, range: range)
                    toAttr.addAttributes([VideoTransformer.RemoteVideoAttachmentAttributedKey: videoInfo], range: range)
                    Self.addRemoveKeyForNextNewLineCharacter(attr: toAttr, range: range)
                    needHandle = true
                } else {
                    interceptCopyResource = true
                }
            }
        })
        return (needHandle, interceptCopyResource)
    }

    func handleAnchorAndLink() -> (needHandle: Bool, isSingleUrlInLine: Bool) {
        let defaultFont = UIFont.systemFont(ofSize: 17)
        var needHandle = false
        var isSingleUrlInLine: Bool = false
        let copyAnchorKey: String = "message.copy.anchor.key"
        let inLineKey = NSAttributedString.Key("message.copy.url.inline")
        originAttr.enumerateAttribute(inLineKey, in: NSRange(location: 0, length: originAttr.length)) { value, range, stop in
            if value != nil, range.location == 0, range.length == originAttr.length {
                isSingleUrlInLine = true
            } else {
                stop.pointee = true
            }
        }
        let copyAnchorKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: copyAnchorKey)
        formAttr.enumerateAttribute(copyAnchorKeyAttributedKey, in: NSRange(location: 0, length: formAttr.length), options: [.reverse, .longestEffectiveRangeNotRequired]) { value, range, _ in
            if let element = value as? RustPB.Basic_V1_RichTextElement {
                let anchor = element.property.anchor
                if let copyMessage = self.message {
                    let inlineValue = (formAttr.attributedSubstring(from: range).attributes(at: 0, effectiveRange: nil)[inLineKey]) as? String
                    let subAttr = MessageInlineViewModel.pasteAnchorInlineProcessProvider(message: copyMessage,
                                                                                          anchor: anchor,
                                                                                          elementId: inlineValue,
                                                                                          fontInfo: (element.style, defaultFont))
                    toAttr.replaceCharacters(in: range, with: subAttr)
                    formAttr.replaceCharacters(in: range, with: subAttr)
                    needHandle = true
                } else {
                    let attr = AnchorTransformer.transformToURLAttributedString(anchor: anchor,
                                                                                style: element.style,
                                                                                attributes: [.font: defaultFont])
                    toAttr.replaceCharacters(in: range, with: attr)
                    formAttr.replaceCharacters(in: range, with: attr)
                    needHandle = true
                }
            }
        }
        /// 目前只有边写编译的详情页有这样的数据结构
        let copyAttributedLinkKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.link.key")
        let copyImageKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.image.key")
        formAttr.enumerateAttribute(copyAttributedLinkKey, in: NSRange(location: 0, length: formAttr.length), options: [.reverse, .longestEffectiveRangeNotRequired]) { value, range, _ in
            if let element = value as? RustPB.Basic_V1_RichTextElement {
                let link = element.property.link
                let subAttr = formAttr.attributedSubstring(from: range)
                let attributes = subAttr.attributes(at: 0, effectiveRange: nil)
                var imageRanges: [NSRange] = []
                subAttr.enumerateAttribute(copyImageKeyAttributedKey, in: NSRange(location: 0, length: subAttr.length)) { value, range, _ in
                    if value != nil, range.location == 0 {
                        imageRanges.append(range)
                    }
                }
                if !imageRanges.isEmpty,
                   let imagePB = attributes[copyImageKeyAttributedKey] as? RustPB.Basic_V1_RichTextElement.ImageProperty {
                    let imageRange = imageRanges[0]
                    let title = NSMutableAttributedString(attributedString: subAttr)
                    title.replaceCharacters(in: imageRange, with: "")
                    if let attr = LinkTransformer.transformToAttrWith(link,
                                                                      imagePB: imagePB,
                                                                      title: title.string,
                                                                      style: element.style,
                                                                      attributes: [.font: defaultFont]) {
                        toAttr.replaceCharacters(in: range, with: attr)
                        formAttr.replaceCharacters(in: range, with: attr)
                        needHandle = true
                    }
                }
            }
        }
        return (needHandle, isSingleUrlInLine)
    }

    func handleAt() -> Bool {
        let defaultFont = UIFont.systemFont(ofSize: 17)
        var needHandle = false
        let copyAtKey: String = "message.copy.at.key"
        let copyAtKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: copyAtKey)
        formAttr.enumerateAttribute(copyAtKeyAttributedKey,
                                    in: NSRange(location: 0, length: formAttr.length),
                                    options: [.reverse]) { value, range, _ in
            if let element = value as? RustPB.Basic_V1_RichTextElement,
               !element.property.at.isAnonymous {
                toAttr.removeAttribute(copyAtKeyAttributedKey, range: range)
                let atInfo = element.property.at
                let chatterInfo = AtChatterInfo(id: atInfo.userID,
                                                name: atInfo.content,
                                                isOuter: atInfo.isOuter,
                                                actualName: atInfo.content,
                                                isAnonymous: atInfo.isAnonymous)
                let attr = AtTransformer.transformContentToString(chatterInfo,
                                                                  style: element.style,
                                                                  attributes: [.font: defaultFont])
                toAttr.replaceCharacters(in: range, with: attr)
                formAttr.replaceCharacters(in: range, with: attr)
                needHandle = true
            }
        }
        return needHandle
    }

    /// 这里为什么有个handlePartialAnchorAndLink
    /// 因为之前消息的复制不支持局部复制@和anchor，所以局部引用为了不影响原来的逻辑
    /// 给局部复制的anchor和@给了单独的key 确保不影响到线上的逻辑
    /// 等将来时间允许，会把局部复制的key和全局的key统一，然后来fix局部复制的逻辑问题
    func handlePartialAnchor() -> Bool {
        let defaultFont = UIFont.systemFont(ofSize: 17)
        var needHandle = false
        let copyAnchorKey: String = "message.copy.anchor.tag.key"
        let elementIdKey = NSAttributedString.Key("message.copy.anchor.element.id.key")
        let copyAnchorKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: copyAnchorKey)
        formAttr.enumerateAttribute(copyAnchorKeyAttributedKey, in: NSRange(location: 0, length: formAttr.length), options: [.reverse, .longestEffectiveRangeNotRequired]) { value, range, _ in
            if let element = value as? RustPB.Basic_V1_RichTextElement {
                let displayText = formAttr.attributedSubstring(from: range).string
                if displayText.isEmpty { return }
                var anchor = element.property.anchor
                if let message = self.message,
                   let elementId = (formAttr.attributedSubstring(from: range).attributes(at: 0, effectiveRange: nil)[elementIdKey]) as? String {
                    var entities: [String: InlinePreviewEntity] = [:]
                    if message.type == .text, let content = message.content as? TextContent {
                        entities = content.inlinePreviewEntities
                    } else if message.type == .post, let content = message.content as? PostContent {
                        entities = content.inlinePreviewEntities
                    }
                    let hangPoint = message.urlPreviewHangPointMap
                    if !entities.isEmpty,
                       let point = hangPoint[elementId],
                       let title = entities[point.previewID]?.title {
                        anchor.content = title
                        anchor.textContent = title
                    }
                }
                guard displayText == anchor.href || displayText == anchor.content || displayText == anchor.textContent else {
                    return
                }
                let attr = AnchorTransformer.transformToURLAttributedString(anchor: anchor,
                                                                            style: element.style,
                                                                            attributes: [.font: defaultFont])
                toAttr.replaceCharacters(in: range, with: attr)
                formAttr.replaceCharacters(in: range, with: attr)
                needHandle = true
            }
        }
        return needHandle
    }

    func handlePartialAt(supportAnonymous: Bool = true) -> Bool {
        let defaultFont = UIFont.systemFont(ofSize: 17)
        var needHandle = false
        let copyAtKey: String = "message.copy.at.tag.key"
        let copyAtKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: copyAtKey)
        formAttr.enumerateAttribute(copyAtKeyAttributedKey,
                                    in: NSRange(location: 0, length: formAttr.length),
                                    options: [.reverse]) { value, range, _ in
            if let element = value as? RustPB.Basic_V1_RichTextElement {
                toAttr.removeAttribute(copyAtKeyAttributedKey, range: range)
                let displayText = formAttr.attributedSubstring(from: range).string
                if supportAnonymous || !element.property.at.isAnonymous {
                    let atInfo = element.property.at
                    var content = atInfo.content
                    /// 如果没有@需要往前拼接一个
                    if !content.hasPrefix("@") {
                        content = "@\(content)"
                    }
                    /// 校验一下数据的完整性，如果@的信息不全，当做普通文字处理
                    /// todo: 李洛斌 这里要不要在补个逻辑
                    guard content == displayText else {
                        return
                    }
                    let chatterInfo = AtChatterInfo(id: atInfo.userID,
                                                    name: atInfo.content,
                                                    isOuter: atInfo.isOuter,
                                                    actualName: atInfo.content,
                                                    isAnonymous: atInfo.isAnonymous)
                    let attr = AtTransformer.transformContentToString(chatterInfo,
                                                                      style: element.style,
                                                                      attributes: [.font: defaultFont])
                    toAttr.replaceCharacters(in: range, with: attr)
                    formAttr.replaceCharacters(in: range, with: attr)
                    needHandle = true
                }
            }
        }
        return needHandle
    }

    private static func addRemoveKeyForNextNewLineCharacter(attr: NSMutableAttributedString, range: NSRange) {
        let removeKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.remove")
        let removeValue = "remove"
        let nextCharacterRange = NSRange(location: range.location + range.length, length: 1)
        if nextCharacterRange.location + nextCharacterRange.length < attr.length,
           attr.attributedSubstring(from: nextCharacterRange).string == "\n" {
            attr.addAttributes([removeKey: removeValue], range: nextCharacterRange)
        }
    }

    private static func deleStringForRemoveKey(attr: NSMutableAttributedString) -> NSMutableAttributedString {
        var ranges: [NSRange] = []
        let removeKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.remove")
        attr.enumerateAttribute(removeKey, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if value != nil {
                ranges.append(range)
            }
        }
        ranges.reversed().forEach { range in
            attr.replaceCharacters(in: range, with: "")
        }
        return attr
    }

    private func getAuthToken() -> String? {
        guard let content = message?.content as? PostContent else { return nil }
        return content.authToken
    }
}
