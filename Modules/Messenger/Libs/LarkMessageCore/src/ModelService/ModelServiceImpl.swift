//
//  ModelServiceImpl.swift
//  Lark
//
//  Created by lichen on 2018/8/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkCore
import LarkRichTextCore
import LarkFoundation
import LarkExtensions
import LarkContainer
import Swinject
import LarkMessengerInterface
import LarkSetting
import RustPB
import LarkEmotion
import LarkBaseKeyboard
import LarkMessageBase

/// 复制了Emotion、图片、视频
private let copyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy")
/// 复制了EmojiKey
private let copyEmojiKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.emoji.key")
/// 复制了Doc url
private let copyDocsAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.docs")
/// 复制了URL预览
private let copyURLInlineAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.url.inline")
/// 原始的URL，URL的点击事件与发送的URL可能不是同一个，复制时使用原始URL，点击时使用Inline里的URL
private let originURLAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.url.origin")
/// 复制时属性设置唯一的标识，用于enumerateAttributes区分
private let copyAttributedUniquelyKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.uniquely")

/// 复制时属性设置唯一的标识，用于标识link节点
private let copyAttributedLinkKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.link.key")

public protocol ModelServiceImplDependency {
    func eventTimeDescription(start: Int64, end: Int64, isAllDay: Bool) -> String
}

/// 获取message的纯文本描述，比如图片会被复制成[图片]等
final class ModelServiceImpl: ModelService, UserResolverWrapper {
    let userResolver: UserResolver

    @ScopedInjectedLazy var messageBurnService: MessageBurnService?
    private lazy var lynxcardRenderFG: Bool = {
        return self.userResolver.fg.staticFeatureGatingValue(with: "lynxcard.client.render.enable")
    }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func messageSummerize(_ message: Message) -> String {
        return getSummarize(message: message)
    }

    func messageSummerize(_ message: Message, partialReplyInfo: PartialReplyInfo?) -> String {
        return getSummarize(message: message, partialReplyInfo: partialReplyInfo)
    }

    func copyMessageSummerize(_ message: Message, selectType: CopyMessageSelectedType, copyType: CopyMessageType) -> String {
        return copyMessageSummerizeAttr(
            message,
            selectType: selectType,
            copyType: copyType
        ).string
    }

    func copyMessageSummerizeAttr(_ message: Message, selectType: CopyMessageSelectedType, copyType: CopyMessageType) -> NSAttributedString {
        // (如果copy的是译文维度)
        let isTranslate: Bool
        switch copyType {
        case .translate: isTranslate = true
        case .message: isTranslate = (message.displayRule == .onlyTranslation)
        default: isTranslate = false
        }
        let urlPreviewProvider: URLPreviewProvider = { elementID, originURL in
            let inlinePreviewVM = MessageInlineViewModel()
            if let attr = inlinePreviewVM.getCopySummerizeAttr(elementID: elementID, message: message, isOrigin: !isTranslate) {
                attr.addAttributes([
                    copyURLInlineAttributedKey: elementID,
                    originURLAttributedKey: originURL
                ],
                range: NSRange(location: 0, length: attr.length))
                return attr
            }
            return nil
        }
        let copyValueProvider: CopyValueProvider = { currentSubStr, attrs in
            guard let elementID = attrs[copyURLInlineAttributedKey] as? String else { return nil }
            let inlinePreviewVM = MessageInlineViewModel()
            return inlinePreviewVM.copy(elementID: elementID,
                                        message: message,
                                        subString: currentSubStr,
                                        originURL: attrs[originURLAttributedKey] as? String)
        }
        var content: MessageContent? = message.content
        /// (如果copy的是译文维度) || (copy的是message维度 && 只显示译文)
        if isTranslate {
            if let translateContent = message.translateContent {
                content = translateContent
            }
        }

        switch message.type {
        case .text:
            guard let textContent = content as? TextContent else {
                return NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError)
            }
            return copyStringAttr(richText: textContent.richText,
                              docEntity: textContent.docEntity,
                              selectType: selectType,
                              urlPreviewProvider: urlPreviewProvider,
                              hangPoint: message.urlPreviewHangPointMap,
                              copyValueProvider: copyValueProvider,
                              userResolver: self.userResolver)
        case .post:
            guard let postContent = content as? PostContent else {
                return NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError)
            }
            let attr: NSAttributedString = copyStringAttr(richText: postContent.richText,
                              docEntity: postContent.docEntity,
                              selectType: selectType,
                              urlPreviewProvider: urlPreviewProvider,
                              hangPoint: message.urlPreviewHangPointMap,
                              copyValueProvider: copyValueProvider,
                              userResolver: self.userResolver)
            return attr.string.isEmpty ? NSAttributedString(string: postContent.title) : attr
        case .card:
            if let copySummerize = (message.content as? CardContent)?.summary {
               return NSAttributedString(string: copySummerize)
            }
        assertionFailure("cardContent no summerize!")
        return NSAttributedString()
        case .file, .folder, .audio, .image, .system,
             .shareGroupChat, .shareUserCard, .sticker, .email,
             .calendar, .generalCalendar, .mergeForward, .media,
             .shareCalendarEvent, .hongbao, .commercializedHongbao, .videoChat, .unknown, .location, .todo, .diagnose, .vote:
            assertionFailure("not support copy!")
            return NSAttributedString()
        @unknown default:
            assertionFailure("not support copy!")
            return NSAttributedString()
        }
    }

    func getEventTimeSummerize(_ message: Message) -> String {
        if let content = message.content as? EventShareContent {
            return (try? userResolver.resolve(assert: ModelServiceImplDependency.self).eventTimeDescription(start: content.startTime,
                                                                                                            end: content.endTime,
                                                                                                            isAllDay: content.isAllDay ?? false)) ?? ""
        } else if let content = message.content as? RoundRobinCardContent {
            return (try? userResolver.resolve(assert: ModelServiceImplDependency.self).eventTimeDescription(start: content.startTime,
                                                                                                            end: content.endTime,
                                                                                                            isAllDay: false)) ?? ""
        } else if let content = message.content as? SchedulerAppointmentCardContent {
            return (try? userResolver.resolve(assert: ModelServiceImplDependency.self).eventTimeDescription(start: content.startTime,
                                                                                                            end: content.endTime,
                                                                                                            isAllDay: false)) ?? ""
        } else {
            if let content = message.content as? GeneralCalendarEventRSVPContent {
                return (try? userResolver.resolve(assert: ModelServiceImplDependency.self).eventTimeDescription(start: content.startTime,
                                                                                                                end: content.endTime,
                                                                                                                isAllDay: content.isAllDay)) ?? ""
            }
            return ""
        }
    }

    func getCalendarBotTimeSummerize(_ message: Message) -> String {
        guard let content = message.content as? CalendarBotCardContent,
              let startTime = content.startTime,
              let endTime = content.endTime else { return "" }
        return (try? userResolver.resolve(assert: ModelServiceImplDependency.self).eventTimeDescription(start: startTime, end: endTime, isAllDay: content.isInvalid)) ?? ""
    }

    public func copyString(richText: RustPB.Basic_V1_RichText,
                           docEntity: RustPB.Basic_V1_DocEntity?,
                           selectType: CopyMessageSelectedType,
                           urlPreviewProvider: URLPreviewProvider?,
                           hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint],
                           copyValueProvider: CopyValueProvider?) -> String {
        return copyStringAttr(
            richText: richText,
            docEntity: docEntity,
            selectType: selectType,
            urlPreviewProvider: urlPreviewProvider,
            hangPoint: hangPoint,
            copyValueProvider: copyValueProvider,
            userResolver: self.userResolver
        ).string
    }

    /// 会把docsUrl转为title处理
    public func copyStringAttr(
        richText: RustPB.Basic_V1_RichText,
        docEntity: RustPB.Basic_V1_DocEntity?,
        selectType: CopyMessageSelectedType,
        urlPreviewProvider: URLPreviewProvider?,
        hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint],
        copyValueProvider: CopyValueProvider?,
        userResolver: UserResolver
    ) -> NSAttributedString {
        let richText = RichViewAdaptor.parseUnknownTagToText(richText: richText)
        // 对richText进行处理，把docsURL转为icon+title
        let docsVM = TextDocsViewModel(userResolver: userResolver, richText: richText, docEntity: docEntity, hangPoint: hangPoint)
        let options = self.docRichTextCopyConvertOptions(replaceToLinkMap: docsVM.replaceToLinkMap, urlPreviewProvider: urlPreviewProvider)
        var result = docsVM.richText.lc.walker(options: options).reduce(NSAttributedString(string: ""), +)

        // 文本总范围
        let allRange = NSRange(location: 0, length: result.length)
        switch selectType {
        case .all, .richView:
            break
        case .from(let index):
            if index > 0 && index < allRange.length {
                result = result.attributedSubstring(from: NSRange(location: index, length: allRange.length - index))
            }
        case .to(let index):
            if index > 0 && index < allRange.length {
                result = result.attributedSubstring(from: NSRange(location: 0, length: index))
            }
        case .range(let range):
            if range.location >= allRange.location &&
                (range.location + range.length) <= (allRange.location + allRange.length) {
                result = result.attributedSubstring(from: range)
            }
        }

        // 存放结果
        var resultAttr = NSMutableAttributedString()
        // 遍历result中所有的属性，进行相应的替换，为什么这么做呢？因为复制消息时，图片、视频等长度是1，而我们复制的内容是[图片]、[视频]
        // 所以selectType对于图片、视频的长度是1，我们richText.lc.walker时就需要把图片、视频处理成长度为1的占位符，然后后续再把占位符替换为[图片]、[视频]
        result.enumerateAttributes(in: NSRange(location: 0, length: result.length), options: []) { (attributes, range, _) in
            let currResultString = (result.string as NSString).substring(with: range)
            let helpString: String
            if let copyValue = copyValueProvider?(currResultString, attributes) {
                helpString = copyValue
            } else if let copyValue = attributes[copyAttributedKey] as? String { // 如果是复制了图片、视频、表情，需要进行替换
                helpString = copyValue
            } else if let linkElementId = attributes[copyDocsAttributedKey] as? String, let replaceInfo = docsVM.replaceToLinkMap[linkElementId] {
                // 获取linkElement中的textElement
                let element = docsVM.richText.elements[replaceInfo.result.childIds[replaceInfo.result.childIds.count - 1]]
                // 如果完整复制了docsurl转为的icon+title，需要进行替换为url，+1是因为icon图片长度为1
                if let textElement = element, textElement.tag == RustPB.Basic_V1_RichTextElement.Tag.text, currResultString.count == textElement.property.text.content.count + 1 {
                    helpString = replaceInfo.origin.property.anchor.textContent
                } else {
                    helpString = currResultString
                }
            } else {
                // 其他情况直接追加内容
                helpString = currResultString
            }
            resultAttr.append(NSAttributedString(string: helpString, attributes: attributes))
        }
        // 去掉前后的空白字符和换行符（和PM@李质勤确认）
        Self.trimCharacters(for: resultAttr, in: .whitespacesAndNewlines)
        return resultAttr
    }

    private static func trimCharacters(for attr: NSMutableAttributedString, in set: CharacterSet) {
        var range = (attr.string as NSString).rangeOfCharacter(from: set)

        // Trim leading characters from character set.
        while range.length != 0 && range.location == 0 {
            attr.replaceCharacters(in: range, with: "")
            range = (attr.string as NSString).rangeOfCharacter(from: set)
        }

        // Trim trailing characters from character set.
        range = (attr.string as NSString).rangeOfCharacter(from: set, options: .backwards)
        while range.length != 0 && NSMaxRange(range) == attr.length {
            attr.replaceCharacters(in: range, with: "")
            range = (attr.string as NSString).rangeOfCharacter(from: set, options: .backwards)
        }
    }

    private func docRichTextCopyConvertOptions(replaceToLinkMap: [String: TextDocsViewModel.ReplaceInfo],
                                               urlPreviewProvider: URLPreviewProvider?) -> [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess] {
        // 复制时属性设置唯一的标识，用于enumerateAttributes区分
        var copyAttributedUniquelyIdentifies: Int = 0

        var options: [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess] = [:]
        let pElementProcess: RichTextElementProcess = { option -> [NSAttributedString] in return option.results + [NSAttributedString(string: "\n")] }
        options[.p] = pElementProcess
        // head1...6复制降级为p
        options[.h1] = pElementProcess; options[.h2] = pElementProcess; options[.h3] = pElementProcess; options[.h4] = pElementProcess; options[.h5] = pElementProcess; options[.h6] = pElementProcess
        options[.text] = { option -> [NSAttributedString] in
            return [NSMutableAttributedString(
                string: option.element.property.text.content,
                attributes: Self.parseRichTextStyleToAttrs(option.element.style)
            )]
        }
        // 图片 => [图片]
        options[.img] = { option -> [NSAttributedString] in
            let imageStr = NSMutableAttributedString(
                string: " ",
                attributes: [copyAttributedKey: BundleI18n.LarkMessageCore.Lark_Legacy_MessagePhoto,
                             copyAttributedUniquelyKey: copyAttributedUniquelyIdentifies]
            )
            // 添加message.copy.image.key，以便粘贴到输入框是一个整体
            let copyImageKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.image.key")
            imageStr.addAttributes([copyImageKeyAttributedKey: option.element.property.image], range: NSRange(location: 0, length: imageStr.length))
            // 添加一个随机数，处理两个图片挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "image.random.key")
            imageStr.addAttribute(randomKeyAttributedKey, value: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))", range: NSRange(location: 0, length: imageStr.length))
            copyAttributedUniquelyIdentifies += 1
            return [imageStr]
        }
        // 视频 => [视频]
        options[.media] = { option -> [NSAttributedString] in
            let mediaStr = NSMutableAttributedString(
                string: " ",
                attributes: [copyAttributedKey: BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoVideo,
                             copyAttributedUniquelyKey: copyAttributedUniquelyIdentifies]
            )
            // 添加message.copy.video.key，以便粘贴到输入框是一个整体
            let copyVideoKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.video.key")
            mediaStr.addAttributes([copyVideoKeyAttributedKey: option.element.property.media], range: NSRange(location: 0, length: mediaStr.length))
            // 添加一个随机数，处理两个视频挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "video.random.key")
            mediaStr.addAttribute(randomKeyAttributedKey, value: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))", range: NSRange(location: 0, length: mediaStr.length))
            copyAttributedUniquelyIdentifies += 1
            return [mediaStr]
        }
        // 代码块 => 具体的代码
        options[.codeBlockV2] = { option -> [NSAttributedString] in
            let resultString = NSMutableAttributedString(string: CodeParseUtils.parseToString(property: option.element.property.codeBlockV2))
            // 添加message.copy.code.key，以便粘贴到输入框是一个整体
            let copyCodeKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.code.key")
            resultString.addAttributes([copyCodeKeyAttributedKey: option.element.property.codeBlockV2], range: NSRange(location: 0, length: resultString.length))
            // 添加一个随机数，处理两个代码块挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "code.random.key")
            resultString.addAttribute(randomKeyAttributedKey, value: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))", range: NSRange(location: 0, length: resultString.length))
            return [resultString]
        }
        options[.figure] = { option -> [NSAttributedString] in
            return option.results + [NSAttributedString(string: "\n")]
        }
        options[.at] = { option -> [NSAttributedString] in
            var userName = option.element.property.at.content
            if !userName.hasPrefix("@") { userName = "@\(userName)" }
            let atAttr = NSMutableAttributedString(string: userName)
            let copyAtAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.at.key")
            atAttr.addAttributes([copyAtAttributedKey: option.element], range: NSRange(location: 0, length: atAttr.length))
            // 添加一个随机数，处理两个at挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "at.random.key")
            atAttr.addAttribute(randomKeyAttributedKey, value: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))", range: NSRange(location: 0, length: atAttr.length))
            return [atAttr]
        }
        options[.mention] = { option -> [NSAttributedString] in
            var content = option.element.property.mention.content
            if !content.hasPrefix("#") { content = "#\(content)" }
            return [NSMutableAttributedString(string: content)]
        }
        options[.myAiTool] = { option -> [NSAttributedString] in
            let status = option.element.property.myAiTool.status
            let toolName = option.element.property.myAiTool.localToolName
            // 使用中
            let usingName = toolName.isEmpty ?
            BundleI18n.LarkMessageCore.MyAI_IM_UsingExtention_Text :
            BundleI18n.LarkMessageCore.MyAI_IM_UsingSpecificExtention_Text(toolName)
            // 已使用
            let usedName = toolName.isEmpty ?
            BundleI18n.LarkMessageCore.MyAI_IM_UsedExtention_Text :
            BundleI18n.LarkMessageCore.MyAI_IM_UsedSpecificExtention_Text(toolName)
            let content = status == .runing ? usingName : usedName
            return [NSMutableAttributedString(string: content)]
        }
        options[.a] = { option -> [NSAttributedString] in
            let element = option.element
            var content = ""
            if option.element.property.anchor.hasTextContent {
                content = element.property.anchor.textContent
            } else {
                content = element.property.anchor.content
            }
            let muAttr = NSMutableAttributedString(string: "")
            // 自定义链接不再参与URL中台解析
            if !element.property.anchor.isCustom,
               let attr = urlPreviewProvider?(option.elementId, content) {
                muAttr.append(attr)
            } else {
                let attr = NSAttributedString(
                    string: content,
                    attributes: Self.parseRichTextStyleToAttrs(option.element.style)
                )
                muAttr.append(attr)
            }
            let copyAnchorAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.anchor.key")
            muAttr.addAttributes([copyAnchorAttributedKey: element], range: NSRange(location: 0, length: muAttr.length))
            // 添加一个随机数，处理两个anchor挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "anchor.random.key")
            muAttr.addAttribute(randomKeyAttributedKey, value: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))", range: NSRange(location: 0, length: muAttr.length))
            return [muAttr]
        }
        options[.b] = { _ -> [NSAttributedString] in return [] }
        options[.i] = { _ -> [NSAttributedString] in return [] }
        options[.u] = { _ -> [NSAttributedString] in return [] }
        // 表情换成对应的名字，比如：😁 => [微笑] 并且 记录下该表情对应的emojiKey，比如：😁 => MediumDarkThumbsup
        options[.emotion] = { option -> [NSAttributedString] in
            let emojiText = EmotionResouce.shared.i18nBy(key: option.element.property.emotion.key) ?? option.element.property.emotion.key
            let emojiKey = option.element.property.emotion.key
            let emotionStr = NSAttributedString(
                string: " ",
                attributes: [copyAttributedKey: "[\(emojiText)]",
                             copyEmojiKeyAttributedKey: emojiKey,
                             copyAttributedUniquelyKey: copyAttributedUniquelyIdentifies]
            )
            copyAttributedUniquelyIdentifies += 1
            return [emotionStr]
        }
        options[.link] = { option -> [NSAttributedString] in
            // 如果是docsurl转为的icon+title，需要加上特殊标记：elementId，并清除option.results原有属性，这样复制icon部分就会变为" "（和PM@李质勤确认）
            if replaceToLinkMap[option.elementId] != nil {
                let childsAttrs = NSMutableAttributedString(
                    string: option.results.reduce(NSAttributedString(string: ""), +).string,
                    attributes: Self.parseRichTextStyleToAttrs(option.element.style)
                )
                childsAttrs.addAttributes(
                    [copyDocsAttributedKey: option.elementId,
                    copyAttributedUniquelyKey: copyAttributedUniquelyIdentifies],
                    range: NSRange(location: 0, length: childsAttrs.length)
                )
                copyAttributedUniquelyIdentifies += 1
                return [childsAttrs]
            }
            let attrArr = option.results.map { result in
                let mutAttr = NSMutableAttributedString(attributedString: result)
                mutAttr.addAttributes([copyAttributedLinkKey: option.element,
                                       copyAttributedUniquelyKey: copyAttributedUniquelyIdentifies],
                                      range: NSRange(location: 0, length: result.length))
                return mutAttr
            }
            copyAttributedUniquelyIdentifies += 1
            return attrArr
        }
        options[.docs] = { option -> [NSAttributedString] in return option.results + [NSAttributedString(string: "\n")] }
        options[.ul] = { option -> [NSAttributedString] in return option.results }
        options[.ol] = { option -> [NSAttributedString] in return option.results }
        options[.li] = { option -> [NSAttributedString] in return option.results + [NSAttributedString(string: "\n")] }
        options[.quote] = { option -> [NSAttributedString] in return option.results }
        return options
    }

    private static func parseRichTextStyleToAttrs(_ style: [String: String]) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let value = style[RichTextStyleKey.fontWeight.rawValue],
           value == RichTextStyleValue.bold.rawValue {
            attributes[NSAttributedString.Key(rawValue: "bold")] = "bold"
        }
        if let value = style[RichTextStyleKey.fontStyle.rawValue],
           value == RichTextStyleValue.italic.rawValue {
            attributes[NSAttributedString.Key(rawValue: "italic")] = "italic"
        }
        if let value = style[RichTextStyleKey.textDecoration.rawValue] {
            if value.contains(RichTextStyleValue.underline.rawValue) {
                attributes[FontStyleConfig.underlineAttributedKey] = FontStyleConfig.underlineAttributedValue
            }
            if value.contains(RichTextStyleValue.lineThrough.rawValue) {
                attributes[FontStyleConfig.strikethroughAttributedKey] = FontStyleConfig.strikethroughAttributedValue
            }
        }
        return attributes
    }

    private func getSummarize(message: Message, partialReplyInfo: PartialReplyInfo? = nil) -> String {
        return MessageSummarizeUtil.getSummarize(
            message: message,
            isBurned: messageBurnService?.isBurned(message: message) ?? false,
            partialReplyInfo: partialReplyInfo,
            lynxcardRenderFG: self.lynxcardRenderFG
        )
    }
}

extension LarkModel.SystemContent {
    func parseContent() -> String {
        var contentStr = ""

        switch systemType {
        case .userCallE2EeVoiceOnCancell:
            contentStr = "\(BundleI18n.LarkMessageCore.Lark_Legacy_FeedVoIPSummerize) \(BundleI18n.LarkMessageCore.Lark_View_Canceled)"
        case .userCallE2EeVoiceOnMissing:
            contentStr = "\(BundleI18n.LarkMessageCore.Lark_Legacy_FeedVoIPSummerize) \(BundleI18n.LarkMessageCore.Lark_View_NoResponse)"
        case .userCallE2EeVoiceDuration:
            let systemStr = self.decode()
            contentStr = "\(BundleI18n.LarkMessageCore.Lark_Legacy_FeedVoIPSummerize) \(systemStr)"
        case .userCallE2EeVoiceWhenRefused:
            contentStr = "\(BundleI18n.LarkMessageCore.Lark_Legacy_FeedVoIPSummerize) \(BundleI18n.LarkMessageCore.Lark_View_Declined)"
        case .userCallE2EeVoiceWhenOccupy:
            contentStr = "\(BundleI18n.LarkMessageCore.Lark_Legacy_FeedVoIPSummerize) \(BundleI18n.LarkMessageCore.Lark_View_Unavailable)"
        @unknown default:
            contentStr = self.decode()
        }
        return contentStr
    }
}
