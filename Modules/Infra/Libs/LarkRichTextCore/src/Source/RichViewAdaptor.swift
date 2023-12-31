//
//  RichViewAdaptor.swift
//  LarkMessageCore
//
//  Created by qihongye on 2021/10/4.
//

import Foundation
import RustPB
import LKRichView
import LarkModel
import LarkEmotion
import LarkUIKit
import UniverseDesignFont
import UniverseDesignTheme
import UniverseDesignColor
import UIKit
import LKCommonsLogging
import LarkSetting

// disable-lint: magic number

public struct RichViewAdaptor {
    static let logger = Logger.log(RichViewAdaptor.self, category: "LarkMessageCore.RichViewAdaptor")

    public enum Tag: Int8, LKRichElementTag {
        case p
        case figure
        case a
        case at
        case emotion
        case span
        case quote
        case ul
        case ol
        case li
        case point // Read/Unread point
        case edited //二次编辑后的“已编辑”标签

        public var typeID: Int8 {
            return rawValue
        }
    }

    public struct ClassName {
        // H1
        static let h1 = "h1"
        // H2...H6，样式一样用一个name
        static let h2 = "h2"
        public static let text = "text" // 暂时废弃
        static let docs = "docs"
        public static let atMe = "atMe"
        static let atAll = "atAll"
        public static let atInnerGroup = "atInnerGroup"
        static let atOuterGroup = "atOuterGroup"
        static let atRead = "atRead"
        static let atUnread = "atUnread"
        static let bold = "bold"
        static let italic = "italic"
        static let underline = "underline"
        static let lineThrough = "lineThrough"
        static let emotion = "emotion"
        public static let attachment = "attachment"
        public static let tool = "tool"
        public static let abbreviation = "abbreviation"
        public static let availableMention = "availableMention"
        public static let unavailableMention = "unavailableMention"
        public static let phoneNumber = "phoneNumber"
    }

    public struct Config {
        public let normalFont: UIFont
        public let atColor: AtColor
        public let figurePadding: LKRichStyleValue<Edges>?
        public init(normalFont: UIFont,
                    atColor: AtColor) {
            self.normalFont = normalFont
            self.atColor = atColor
            self.figurePadding = nil
        }

        public init(normalFont: UIFont,
                    atColor: AtColor,
                    figurePadding: LKRichStyleValue<Edges>) {
            self.normalFont = normalFont
            self.atColor = atColor
            self.figurePadding = figurePadding
        }
    }

    public static func createStyleSheets(config: Config) -> [CSSStyleSheet] {
        let styleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: Tag.p), [
                StyleProperty.font(.init(.value, config.normalFont)),
                StyleProperty.fontSize(.init(.point, config.normalFont.pointSize)),
                StyleProperty.minHeight(.init(.em, 1)) // 空p标签给行高
            ]),
            // h1和p的区别：字体大1号、加粗、最小行高1.3倍字体高度
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.h1), [
                StyleProperty.font(.init(.value, config.normalFont)),
                StyleProperty.fontSize(.init(.point, config.normalFont.pointSize + 1.auto())),
                StyleProperty.fontWeigth(.init(.value, UDFontAppearance.isCustomFont ? .medium : .bold)),
                // lineHeight处理多行间间隔（最外层LKBlockElement已经有设置），minHeight处理单行情况最小高度
                StyleProperty.minHeight(.init(.em, 1.3))
            ]),
            // h2...h6和h1的区别，字体小1号
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.h2), [
                StyleProperty.font(.init(.value, config.normalFont)),
                StyleProperty.fontSize(.init(.point, config.normalFont.pointSize)),
                StyleProperty.fontWeigth(.init(.value, UDFontAppearance.isCustomFont ? .medium : .bold)),
                // lineHeight处理多行间间隔（最外层LKBlockElement已经有设置），minHeight处理单行情况最小高度
                StyleProperty.minHeight(.init(.em, 1.3))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.figure), [
                StyleProperty.lineHeight(.init(.auto, nil)),
                StyleProperty.padding(config.figurePadding ?? .init(.value, .init(.point(8), .point(0))))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.li), [
                StyleProperty.padding(.init(.value, Edges(.point(1), .point(0), .point(3), .point(0))))
            ]),
            // MARK: DOCS
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.docs), [
                StyleProperty.color(.init(.value, UIColor.ud.textLinkNormal))
            ]),
            // MARK: ANCHOR
            CSSStyleRule.create(CSSSelector(value: Tag.a), [
                StyleProperty.color(.init(.value, UIColor.ud.textLinkNormal)),
                StyleProperty.textDecoration(.init(.value, .none))
            ]),
            // MARK: AT
            CSSStyleRule.create(CSSSelector(value: Tag.at), [
                StyleProperty.display(.init(.value, .inline))
            ]),
            /// AT ME
            CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atMe)], [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.backgroundColor(.init(.value, config.atColor.MeAttributeNameColor)),
                StyleProperty.color(.init(.value, config.atColor.MeForegroundColor)),
                StyleProperty.padding(.init(.value, Edges(.point(1), .point(4)))),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
            ]),
            /// AT ALL
            CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atAll)], [
                StyleProperty.color(.init(.value, config.atColor.AllForegroundColor)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
            ]),
            /// AT INNERGROUP
            CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atInnerGroup)], [
                StyleProperty.color(.init(.value, config.atColor.OtherForegroundColor)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
            ]),
            /// AT OUTERGROUP
            CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atOuterGroup)], [
                StyleProperty.color(.init(.value, config.atColor.OuterForegroundColor)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
            ]),
            /// AT Read/Unread point
            CSSStyleRule.create(CSSSelector(value: Tag.point), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.verticalAlign(.init(.value, .top)),
                StyleProperty.width(.init(.point, 4)),
                StyleProperty.height(.init(.point, 4)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .point(2), height: .point(2)))))
            ]),
            /// AT NOT ME Read
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.atRead), [
                StyleProperty.width(.init(.point, 6)),
                StyleProperty.height(.init(.point, 6)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .point(3), height: .point(3))))),
                StyleProperty.backgroundColor(.init(.value, config.atColor.ReadBackgroundColor))
            ]),
            /// AT NOT ME Unread
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.atUnread), [
                StyleProperty.border(.init(.value, Border(.init(style: .solid, width: .point(1), color: config.atColor.UnReadRadiusColor))))
            ]),
            // MARK: QUOTE
            CSSStyleRule.create(CSSSelector(value: Tag.quote), [
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.color(.init(.value, UIColor.ud.N600)),
                StyleProperty.padding(.init(.value, Edges(.point(0), .point(0), .point(0), .point(12)))),
                StyleProperty.margin(.init(.value, Edges(.point(4), .point(0)))),
                StyleProperty.border(.init(.value, Border(nil, nil, nil, BorderEdge(style: .solid, width: .point(2), color: UIColor.ud.udtokenQuoteBarBg))))
            ]),
            // MARK: TEXT
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.bold), [
                StyleProperty.fontWeigth(.init(.value, .bold))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.italic), [
                StyleProperty.fontStyle(.init(.value, .italic))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.underline), [
                StyleProperty.textDecoration(
                    .init(.value, TextDecoration(line: .underline, style: .solid, thickness: 1))
                )
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.lineThrough), [
                StyleProperty.textDecoration(
                    .init(.value, TextDecoration(line: .lineThrough, style: .solid, thickness: 1))
                )
            ]),
            // MARK: EMOTION
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.emotion), [
                StyleProperty.height(.init(.em, 1.2)),
                StyleProperty.padding(.init(.value, .init(.point(0), .point(1), .point(0), .point(1)))),
                StyleProperty.verticalAlign(.init(.value, .baseline))
            ]),
            // MARK: ABBREVIATION
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.abbreviation), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.verticalAlign(.init(.value, .baseline)),
                StyleProperty.border(.init(.value, Border(nil, nil, BorderEdge(style: .dashed, width: .point(1), color: UIColor.ud.N900.withAlphaComponent(0.60)), nil)))
            ]),
            // MARK: MENTION
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.availableMention), [
                StyleProperty.color(.init(.value, UIColor.ud.textLinkNormal))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.unavailableMention), [
                StyleProperty.color(.init(.value, UIColor.ud.N650))
            ])
        ])
        return [styleSheet]
    }

    typealias RichElementOptionType = RichTextOptionsType<Node>

    static func parseRichTextStyleToRichElementStyle(_ style: [String: String]) -> LKRichStyle {
        let richStyle = LKRichStyle()
        if let value = style[RichTextStyleKey.fontWeight.rawValue],
           value == RichTextStyleValue.bold.rawValue {
            if UDFontAppearance.isCustomFont {
                richStyle.fontWeight(.medium)
            } else {
                richStyle.fontWeight(.bold)
            }
        }
        if let value = style[RichTextStyleKey.fontStyle.rawValue],
           value == RichTextStyleValue.italic.rawValue {
            richStyle.fontStyle(.italic)
        }
        if let value = style[RichTextStyleKey.textDecoration.rawValue] {
            let isUnderline = value.contains(RichTextStyleValue.underline.rawValue)
            let isLineThrough = value.contains(RichTextStyleValue.lineThrough.rawValue)

            if isUnderline && isLineThrough {
                richStyle.textDecoration(.init(line: [.underline, .lineThrough], style: .solid))
            } else if isUnderline {
                richStyle.textDecoration(.init(line: [.underline], style: .solid))
            } else if isLineThrough {
                richStyle.textDecoration(.init(line: [.lineThrough], style: .solid))
            }
        }
        return richStyle
    }

    private static var fix15_4CrashLock = os_unfair_lock_s()
    private static var myAIToolFG: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.my_ai.plugin"))
    }

    // swiftlint:disable large_tuple
    public static func parseRichTextToRichElement(
        richText: Basic_V1_RichText,
        isFromMe: Bool = false,
        isShowReadStatus: Bool = true,
        checkIsMe: ((_ userId: String) -> Bool)?,
        botIDs: [String] = [],
        readAtUserIDs: [String] = [],
        defaultTextColor: UIColor = UIColor.ud.N900,
        maxLines: Int = 0,
        maxCharLine: Int = defaultMaxChatLine(),
        abbreviationInfo: [String: AbbreviationInfoWrapper]? = nil,
        mentions: [String: Basic_V1_HashTagMentionEntity]? = nil,
        imageAttachmentProvider: ((Basic_V1_RichTextElement.ImageProperty) -> LKRichAttachment)? = nil,
        toolAttachmentProvider: ((Basic_V1_RichTextElement.MyAIToolProperty) -> LKRichAttachment)? = nil,
        mediaAttachmentProvider: ((Basic_V1_RichTextElement.MediaProperty) -> LKRichAttachment)? = nil,
        urlPreviewProvider: ((String) -> (imageNode: LKAttachmentElement?, titleNode: Node?, tagNode: LKAttachmentElement?, clickURL: String?)?)? = nil,
        hashTagProvider: ((Basic_V1_RichTextElement.MentionProperty ) -> Node?)? = nil,
        phoneNumberAndLinkProvider: ((String, String) -> [PhoneNumberAndLinkParser.ParserResult])? = nil, //本地识别phoneNumber和url
        edited: Bool = false, //被二次编辑过
        codeParseConfig: CodeParseConfig = CodeParseConfig() // 代码块处理配置
    ) -> LKRichElement {
        // 当前总共处理了多少个字符，用来判断截断逻辑
        var location: Int = 0

        let buildText: RichElementOptionType = { option in
            let textContent = option.element.property.text.content
            if textContent.isEmpty { return option.results }
            location += textContent.count
            var node: [Node]

            let phoneNumberAndLinks = phoneNumberAndLinkProvider?(option.elementId, textContent) ?? []
            let abbrRefs = abbreviationInfo?[option.elementId]?.refs ?? []

            os_unfair_lock_lock(&Self.fix15_4CrashLock)
            // Doc 文本
            if Self.isDocTitle(elementID: option.elementId) {
                node = [LKTextElement(classNames: [ClassName.docs], text: textContent)]
            }
            // 电话号码 & 企业词典
            else if !phoneNumberAndLinks.isEmpty || !abbrRefs.isEmpty {
                let mergeResults = mergeDetectorAndAbbr(phoneNumberAndLink: phoneNumberAndLinks, abbrRefs: abbrRefs)
                let splitResults = split(mergeResults: mergeResults, content: textContent)
                node = splitResults.map { (resultType, content) in
                    switch resultType {
                    case .phoneNumber(let number):
                        return LKAnchorElement(
                            tagName: Tag.a,
                            classNames: [ClassName.phoneNumber],
                            style: parseRichTextStyleToRichElementStyle(option.element.style),
                            text: content,
                            href: number
                        )
                    case .link(let url):
                        return LKAnchorElement(
                            tagName: Tag.a,
                            style: parseRichTextStyleToRichElementStyle(option.element.style),
                            text: content,
                            href: url.absoluteString
                        )
                    case .abbreviation(let abbr):
                        if abbr.matchedWord != content {
                            return LKTextElement(
                                classNames: [ClassName.text],
                                style: parseRichTextStyleToRichElementStyle(option.element.style),
                                text: content
                            )
                        } else {
                            let textElement = LKTextElement(
                                style: parseRichTextStyleToRichElementStyle(option.element.style),
                                text: abbr.matchedWord
                            )
                            return LKInlineBlockElement(id: option.elementId, tagName: Tag.span, classNames: [ClassName.abbreviation]).addChild(textElement)
                        }
                    case .other:
                        return LKTextElement(
                            classNames: [ClassName.text],
                            style: parseRichTextStyleToRichElementStyle(option.element.style),
                            text: content
                        )
                    }
                }
            }
            // 普通文本
            else {
                node = [LKTextElement(
                    classNames: [ClassName.text],
                    style: parseRichTextStyleToRichElementStyle(option.element.style),
                    text: textContent
                )]
            }
            os_unfair_lock_unlock(&Self.fix15_4CrashLock)
            return node
        }

        let buildAnchor: RichElementOptionType = { option in
            let anchor = option.element
            var href = anchor.property.anchor.hasIosHref ? anchor.property.anchor.iosHref : anchor.property.anchor.href
            // 自定义链接不再参与URL中台解析：https://bytedance.feishu.cn/docx/doxcn155EbNTAcbaTQgYgc1fvMd
            let copyAnchorKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.anchor.tag.key")
            let elementIdKey = NSAttributedString.Key("message.copy.anchor.element.id.key")
            // 添加一个随机数，处理两个anchor挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "anchor.random.key")
            if !anchor.property.anchor.isCustom,
               let node = urlPreviewProvider?(option.elementId) {
                var children = [Node]()
                if let imageNode = node.imageNode {
                    location += 1
                    imageNode.classNames.append(ClassName.attachment)
                    // imageNode是一个inline，暂时不支持设置左右间距，需要包一层InlineBlock
                    let imageContainer = LKInlineBlockElement(tagName: Tag.p).addChild(imageNode)
                    imageContainer.classNames.append(ClassName.attachment)
                    imageContainer.style.padding(right: .point(4))
                    children.append(imageContainer)
                }
                if let titleNode = node.titleNode {
                    children.append(titleNode)
                }
                if let tagNode = node.tagNode {
                    location += 1
                    tagNode.classNames.append(ClassName.attachment)
                    children.append(tagNode)
                }
                if !children.isEmpty {
                    href = (node.clickURL ?? href).trimmingCharacters(in: .whitespacesAndNewlines)
                    let container = LKAnchorElement(
                        tagName: Tag.a,
                        style: parseRichTextStyleToRichElementStyle(option.element.style),
                        text: "",
                        href: href,
                        config: AnchorConfig([copyAnchorKeyAttributedKey: anchor,
                                                            elementIdKey: option.elementId,
                                              randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"]
                                            )).children(children)
                    return [container]
                }
            }
            var content = ""
            if !anchor.property.anchor.textContent.isEmpty {
                content = anchor.property.anchor.textContent
            } else {
                content = anchor.property.anchor.content
            }
            href = href.trimmingCharacters(in: .whitespacesAndNewlines)
            location += content.count
            return [
                LKAnchorElement(
                    tagName: Tag.a,
                    style: parseRichTextStyleToRichElementStyle(option.element.style),
                    text: content,
                    href: href,
                    config: AnchorConfig([copyAnchorKeyAttributedKey: anchor,
                                          randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"]))
            ]
        }

        let buildLink: RichElementOptionType = { option in
            let link = option.element
            var href = link.property.link.url
            if link.property.link.hasIosURL {
                href = link.property.link.iosURL
            }
            return [
                LKAnchorElement(
                    tagName: Tag.a,
                    style: parseRichTextStyleToRichElementStyle(option.element.style),
                    text: "",
                    href: href
                ).children(option.results)
            ]
        }

        let buildUnderline: RichElementOptionType = { option in
            if let phoneNumberAndLinks = phoneNumberAndLinkProvider?(option.elementId, option.element.property.underline.content), !phoneNumberAndLinks.isEmpty {
                location += option.element.property.underline.content.count
                let mergeResults = phoneNumberAndLinks.map { (type, range) in
                    (ResultType.transform(phoneNumberAndLinkType: type), range)
                }
                let splitResults = split(mergeResults: mergeResults, content: option.element.property.underline.content)
                let node: [Node] = splitResults.map { resultType, content in
                    switch resultType {
                    case .phoneNumber(let phoneNumber):
                        return LKAnchorElement(
                            tagName: Tag.a,
                            classNames: [ClassName.phoneNumber, ClassName.underline],
                            text: content,
                            href: phoneNumber
                        )
                    case .link(let url):
                        return LKAnchorElement(
                            tagName: Tag.a,
                            classNames: [ClassName.underline],
                            text: content,
                            href: url.absoluteString
                        )
                    case .abbreviation(_), .other:
                        return LKTextElement(classNames: [ClassName.underline], text: content)
                    }
                }
                return node
            }
            return [LKTextElement(classNames: [ClassName.underline], text: option.element.property.underline.content)]
        }

        let buildParagraph: RichElementOptionType = { option in
            let element = LKBlockElement(tagName: Tag.p).children(option.results)
            element.isLineBreak = true
            return [element]
        }

        let buildHeading: RichElementOptionType = { option in
            let element = LKBlockElement(tagName: Tag.p, classNames: [(option.element.tag == .h1) ? ClassName.h1 : ClassName.h2]).children(option.results)
            element.isLineBreak = true
            return [element]
        }

        let buildFigure: RichElementOptionType = { option in
            let element = LKBlockElement(tagName: Tag.figure).children(option.results)
            element.isLineBreak = true
            return [element]
        }

        let buildEmotion: RichElementOptionType = { option in
            location += 1
            let emotion = option.element
            if let icon = EmotionResouce.shared.imageBy(key: emotion.property.emotion.key) {
                // copy from ModelServiceImpl-docRichTextCopyConvertOptions-emotion
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key(rawValue: "message.copy"): EmotionResouce.shared.i18nBy(key: option.element.property.emotion.key) ?? option.element.property.emotion.key,
                    NSAttributedString.Key(rawValue: "message.copy.emoji.key"): option.element.property.emotion.key,
                    NSAttributedString.Key(rawValue: "message.copy.uniquely"): "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"
                ]
                let element = LKImgElement(
                    classNames: [ClassName.emotion],
                    img: icon.cgImage,
                    config: ImgConfig(attributes)
                )
                let emojiText = EmotionResouce.shared.i18nBy(key: emotion.property.emotion.key) ?? emotion.property.emotion.key
                element.defaultString = "[\(emojiText)]"
                return [element]
            }
            // 如果表情违规的话需要显示违规提示文案
            if EmotionResouce.shared.isDeletedBy(key: emotion.property.emotion.key) {
                let illegaText = EmotionResouce.shared.getIllegaDisplayText()
                let textElement = LKTextElement(text: "[\(illegaText)]")
                textElement.style.color(UIColor.ud.N500)
                return [textElement]
            }
            return [LKTextElement(text: "[\(emotion.property.emotion.key)]")]
        }

        let buildAt: RichElementOptionType = { option in
            let at = option.element
            let atUserID = at.property.at.userID
            let hasAtChar = at.property.at.content.hasPrefix("@")
            var atPropertyContent = hasAtChar ? at.property.at.content : "@\(at.property.at.content)"
            location += atPropertyContent.count
            let textElement = LKTextElement(
                classNames: [ClassName.text],
                style: parseRichTextStyleToRichElementStyle(option.element.style),
                text: atPropertyContent
            )
            let copyAtKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.at.tag.key")
            // 添加一个随机数，处理两个图片挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "at.random.key")
            let extraAttributes: [NSAttributedString.Key: Any] = [copyAtKeyAttributedKey: at,
                                                                  randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"]
            if at.property.at.isOuter { // AT OUTERGROUP
                return [LKInlineElement(id: option.elementId,
                                        tagName: Tag.at,
                                        classNames: [ClassName.atOuterGroup],
                                        config: LKInlineElement.InlineConfig(extraAttributes)).addChild(textElement)]
            } else if atUserID == "all" { // AT ALL
                return [LKInlineElement(id: option.elementId,
                                        tagName: Tag.at,
                                        classNames: [ClassName.atAll],
                                        config: LKInlineElement.InlineConfig(extraAttributes)).addChild(textElement)]
            } else { // AT INNERGROUP
                // AT ME
                if let checkIsMe = checkIsMe, checkIsMe(atUserID) {
                    return [LKInlineBlockElement(id: option.elementId,
                                                 tagName: Tag.at,
                                                 config: LKInlineBlockElement.InlineConfig(extraAttributes),
                                                 classNames: [ClassName.atMe]).addChild(textElement)]
                }
                let isAtBot = botIDs.contains(atUserID)
                let isAtRead = readAtUserIDs.contains(atUserID)
                let children: [Node]
                if isShowReadStatus, isFromMe, !isAtBot {
                    let lastChar = String(atPropertyContent.removeLast())
                    let lastCharElement = LKTextElement(
                        classNames: [ClassName.text],
                        style: parseRichTextStyleToRichElementStyle(option.element.style),
                        text: lastChar
                    )
                    let prefixElement = LKTextElement(
                        classNames: [ClassName.text],
                        style: parseRichTextStyleToRichElementStyle(option.element.style),
                        text: atPropertyContent
                    )
                    let point = LKInlineBlockElement(tagName: Tag.point, classNames: [isAtRead ? ClassName.atRead : ClassName.atUnread])
                    // 已读未读的point需要和最后一个字包一层inlineBlock，否则不能一起折行
                    let tailBreakElement = LKInlineBlockElement(tagName: Tag.span)
                        .style(LKRichStyle().isBlockSelection(true))
                        .children([lastCharElement, point])
                    children = [prefixElement, tailBreakElement]
                } else {
                    children = [textElement]
                }
                return [LKInlineElement(id: option.elementId,
                                        tagName: Tag.at,
                                        classNames: [ClassName.atInnerGroup],
                                        config: LKInlineElement.InlineConfig(extraAttributes)).children(children)]
            }
        }

        let buildTool: RichElementOptionType = { option in
            guard Self.myAIToolFG else {
                return option.results
            }
            let tool = option.element
            let toolName = tool.property.myAiTool.localToolName
            // 使用中
            let usingName = toolName.isEmpty ?
            BundleI18n.LarkRichTextCore.MyAI_IM_UsingExtention_Text :
            BundleI18n.LarkRichTextCore.MyAI_IM_UsingSpecificExtention_Text(toolName)
            // 已使用
            let usedName = toolName.isEmpty ?
            BundleI18n.LarkRichTextCore.MyAI_IM_UsedExtention_Text :
            BundleI18n.LarkRichTextCore.MyAI_IM_UsedSpecificExtention_Text(toolName)
            if let attachmentProvider = toolAttachmentProvider {
                location += 1
                // 添加message.copy.myAiTool.key，以便粘贴到输入框是一个整体
                let copyImageKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.myAiTool.key")
                // 添加一个随机数，处理两个Tool挨在一起的情况
                let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "myAiTool.random.key")
                let element = LKAttachmentElement(classNames: [ClassName.tool], attachment: attachmentProvider(tool.property.myAiTool), config: AttachmentConfig([
                    copyImageKeyAttributedKey: tool.property.myAiTool,
                    randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"
                ]))
                element.defaultString = tool.property.myAiTool.status == .runing ? usingName : usedName
                // 需要自己再包装一层，设置padding，和图片、视频保持一致：渲染时，和上下内容有间隔
                let contentElement = LKInlineBlockElement(tagName: Tag.span).children([element])
                contentElement.style.padding(top: .point(0), right: .point(0), bottom: .point(8), left: .point(0))
                return [contentElement]
            }
            let content = tool.property.myAiTool.status == .runing ? usingName : usedName
            location += content.count
            return [LKTextElement(classNames: [ClassName.text], text: content)]
        }

        let buildImage: RichElementOptionType = { option in
            if let attachmentProvider = imageAttachmentProvider {
                let img = option.element
                location += 1
                // 添加message.copy.image.key，以便粘贴到输入框是一个整体
                let copyImageKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.image.key")
                // 添加一个随机数，处理两个图片挨在一起的情况
                let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "image.random.key")
                let element = LKAttachmentElement(classNames: [ClassName.attachment], attachment: attachmentProvider(img.property.image), config: AttachmentConfig([
                    copyImageKeyAttributedKey: img.property.image,
                    randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"
                ]))
                element.defaultString = BundleI18n.LarkRichTextCore.Lark_Legacy_ImageSummarize
                return [element]
            }
            let content = BundleI18n.LarkRichTextCore.Lark_Legacy_ImageSummarize
            location += content.count
            return [LKTextElement(classNames: [ClassName.text], text: content)]
        }

        let buildMedia: RichElementOptionType = { option in
            let media = option.element
            if let attachmentProvider = mediaAttachmentProvider {
                let media = option.element
                location += 1
                // 添加message.copy.video.key，以便粘贴到输入框是一个整体
                let copyVideoKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.video.key")
                // 添加一个随机数，处理两个视频挨在一起的情况
                let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "video.random.key")
                let element = LKAttachmentElement(classNames: [ClassName.attachment], attachment: attachmentProvider(media.property.media), config: AttachmentConfig([
                    copyVideoKeyAttributedKey: media.property.media,
                    randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"
                ]))
                element.defaultString = BundleI18n.LarkRichTextCore.Lark_Legacy_VideoSummarize
                return [element]
            }
            let content = BundleI18n.LarkRichTextCore.Lark_Legacy_VideoSummarize
            location += content.count
            return [LKTextElement(classNames: [ClassName.text], text: content)]
        }

        let buildMention: RichElementOptionType = { option in
            let mention = option.element.property.mention
            if let node = hashTagProvider?(mention) {
                return [node]
            }
            let entity = mentions?[mention.item.id]
            var content = mention.content
            var isAvailable = false
            if let entity = entity {
                content = entity.name.defaultContent
                isAvailable = entity.name.style.isAvailable
            }
            switch mention.item.type {
            case .unknownMentionType:
                break
            case .hashTag:
                let hasMentionChar = content.hasPrefix("#")
                content = hasMentionChar ? content : "#\(content)"
            @unknown default: assertionFailure("unknow type")
            }
            let element: LKTextElement
            if isAvailable {
                element = LKTextElement(classNames: [ClassName.availableMention], text: content)
            } else {
                element = LKTextElement(classNames: [ClassName.unavailableMention], text: content)
            }
            let node = LKInlineElement(id: option.elementId, tagName: Tag.span).addChild(element)
            location += content.count
            return [node]
        }

        let buildUnOrderList: RichElementOptionType = { option in
            location += 1
            let type: UnOrderListType
            switch option.element.property.ul.type {
            case .disc:
                type = .disc
            case .circle:
                type = .circle
            case .square:
                type = .square
            case .none:
                type = .none
            @unknown default:
                type = .none
            }
            return [LKUnOrderedListElement(tagName: Tag.ul, ulType: type).children(option.results)]
        }

        let buildOrderList: RichElementOptionType = { option in
            location += 1
            let type: OrderListType
            switch option.element.property.ol.type {
            case .number:
                type = .number
            case .lowercaseA:
                type = .lowercaseA
            case .uppercaseA:
                type = .uppercaseA
            case .lowercaseRoman:
                type = .lowercaseRoman
            case .uppercaseRoman:
                type = .uppercaseRoman
            case .none:
                type = .none
            @unknown default:
                type = .none
            }
            let start = Int(option.element.property.ol.start)
            return [LKOrderedListElement(tagName: Tag.ol, start: start, olType: type).children(option.results)]
        }

        let buildListItem: RichElementOptionType = { option in
            location += 1
            let element = LKListItemElement(
                tagName: Tag.li,
                iconColor: UIColor.ud.colorfulBlue,
                ulIconSize: 8,
                olIconSize: 17
            ).children(option.results)
            element.isLineBreak = true
            return [element]
        }

        let buildQuote: RichElementOptionType = { option in
            location += 1
            return [LKBlockElement(tagName: Tag.quote).children(option.results)]
        }

        // 代码块
        let buildCode: RichElementOptionType = { option in
            // 因为是整体选中，所以这里算成长度1即可
            location += 1
            let codeElement = CodeParseUtils.parseToLKRichElement(property: option.element.property.codeBlockV2, elementId: option.elementId, config: codeParseConfig)
            // 需要自己再包装一层，设置padding，和图片、视频保持一致：渲染时，和上下内容有间隔
            let contentElement = LKBlockElement(tagName: Tag.p).children([codeElement])
            contentElement.style.padding(top: .point(8), right: .point(0), bottom: .point(8), left: .point(0))
            return [contentElement]
        }

        /// RustPB.Basic_V1_RichText 截断条件
        let endConditionHandler: () -> Bool = {
            if maxLines == 0 {
                return false
            }
            // Jira：https://jira.bytedance.com/browse/SUITE-52473
            // reason、solution：https://bytedance.feishu.cn/space/doc/doccnqcEy7WTJgsK3ByfoX5io2f
            // fix version：3.12.0
            return location > maxLines * maxCharLine
        }

        var elements: [Node] = richText.lc.walker(
            options: [
                .h1: buildHeading, .h2: buildHeading, .h3: buildHeading, .h4: buildHeading, .h5: buildHeading, .h6: buildHeading,
                .p: buildParagraph,
                .figure: buildFigure,
                .docs: buildParagraph,
                .text: buildText,
                .emotion: buildEmotion,
                .a: buildAnchor,
                .link: buildLink,
                .u: buildUnderline,
                .ul: buildUnOrderList,
                .ol: buildOrderList,
                .li: buildListItem,
                .at: buildAt,
                .img: buildImage,
                .media: buildMedia,
                .mention: buildMention,
                .quote: buildQuote,
                .codeBlockV2: buildCode,
                .myAiTool: buildTool
            ],
            endCondition: endConditionHandler
        )
        if edited {
            let text = BundleI18n.LarkRichTextCore.Lark_IM_EditMessage_Edited_Label
            let textElement = LKTextElement(
                classNames: [ClassName.text],
                text: text
            )
            textElement.style.color(.ud.textCaption).fontSize(.point(12 * UniverseDesignFont.UDZoom.currentZoom.scale))
            let node = LKInlineBlockElement(tagName: Self.Tag.edited).addChild(textElement)
            if let element = elements.last {
                //如果是图片/视频，则换行展示"已编辑"，否则在末尾拼接“已编辑”；这里为什么取subElements.last，因为图片/视频是会包裹在LKBlockElement中
                if let lastElement = element.subElements.last, lastElement.classNames.contains(ClassName.attachment) {
                    elements.append(node)
                } else {
                    element.addChild(node)
                }
            } else {
                // 如果elements为空（只有title，二次编辑把内容全删除），也要展示“已编辑”
                elements.append(node)
            }
        }

        let document = LKBlockElement(tagName: Tag.p)
        // 全局默认，优先级最低
        document.style.color(defaultTextColor).lineHeight(.em(1.3))
        document.children(elements)
        // trim
        var leafNodes = document.getLeafNodesByOrder()
        while !leafNodes.isEmpty {
            let lastElement = leafNodes.popLast()
            if let textElement = lastElement as? LKTextElement {
                textElement.text = textElement.text.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .tail)
                if textElement.text.isEmpty {
                    lastElement?.prun()
                    continue
                }
            } else if let paragraph = lastElement as? LKBlockElement, paragraph.subElements.isEmpty {
                lastElement?.prun()
                continue
            }
            break
        }
        return document
    }
    // swiftlint:enable large_tuple

    private static var elementIDIndex: Int = 0
    private static let richViewIdentifier = "richView"
    public static func parseUnknownTagToText(richText: Basic_V1_RichText) -> Basic_V1_RichText {
        var richText = richText
        let elements = richText.elements
        elements.forEach { (elementID, element) in
            if element.tag == .li {
                let textElementID = elementID + richViewIdentifier + "\(elementIDIndex)"
                elementIDIndex += 1
                var textElement = RustPB.Basic_V1_RichTextElement()
                textElement.tag = RustPB.Basic_V1_RichTextElement.Tag.text
                var textProperty = RustPB.Basic_V1_RichTextElement.TextProperty()
                textProperty.content = "- "
                textElement.property.text = textProperty

                // 避免重复添加前缀
                element.childIds.filter({ $0.contains(richViewIdentifier) }).forEach({ richText.elements[$0] = nil })
                let originIDs = element.childIds.filter({ !$0.contains(richViewIdentifier) })
                richText.elements[textElementID] = textElement
                richText.elements[elementID]?.childIds = [textElementID] + originIDs
            }
        }
        return richText
    }

    public static func defaultMaxChatLine() -> Int {
        if Display.pad {
            let maxWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            /// 1 字符 16 size font 宽度约为 7.2， 取整为 8
            let oneNumberWidth: CGFloat = 8
            return Int(maxWidth / oneNumberWidth)
        } else {
            return 40
        }
    }
    public static func isDocTitle(elementID: String) -> Bool {
        return elementID.hasSuffix(LarkRichTextCore.Resources.customTitle)
    }
}

// MARK: - Merge PhoneNumberAndLink & Abbr
extension RichViewAdaptor {
    enum ResultType {
        case phoneNumber(String)
        case link(URL)
        case abbreviation(Basic_V1_Ref)
        case other

        static func transform(phoneNumberAndLinkType: PhoneNumberAndLinkParser.ResultType) -> ResultType {
            switch phoneNumberAndLinkType {
            case .phoneNumber(let number): return .phoneNumber(number)
            case .link(let link): return .link(link)
            case .other: return .other
            }
        }
    }

    typealias MergeResult = (resultType: ResultType, range: NSRange)
    typealias SplitResult = (resultType: ResultType, content: String)

    /// 企业词典和本地识别Merge，优先级：企业词典 >  本地识别
    static func mergeDetectorAndAbbr(phoneNumberAndLink: [PhoneNumberAndLinkParser.ParserResult], abbrRefs: [Basic_V1_Ref]) -> [MergeResult] {
        if phoneNumberAndLink.isEmpty, abbrRefs.isEmpty {
            return []
        }
        var phoneNumberAndLinkResult: [MergeResult] = phoneNumberAndLink.map { (type, range) in
            (ResultType.transform(phoneNumberAndLinkType: type), range)
        }
        var abbrResult: [MergeResult] = abbrRefs.map { ref in
            let start = Int(ref.span.start)
            let end = Int(ref.span.end)
            return (ResultType.abbreviation(ref), NSRange(location: start, length: end - start))
        }
        if phoneNumberAndLinkResult.isEmpty {
            return abbrResult
        }
        if abbrResult.isEmpty {
            return phoneNumberAndLinkResult
        }

        // sort by range：由大到小
        phoneNumberAndLinkResult.sort(by: { $0.range.location > $1.range.location })
        abbrResult.sort(by: { $0.range.location > $1.range.location })
        var result: [MergeResult] = []
        while !phoneNumberAndLinkResult.isEmpty || !abbrResult.isEmpty {
            let phoneNumberAndLink = phoneNumberAndLinkResult.popLast()
            let abbr = abbrResult.popLast()
            if phoneNumberAndLink == nil {
                if let abbr = abbr {
                    result.append(abbr)
                    abbrResult.reverse()
                    result.append(contentsOf: abbrResult)
                    break
                }
            } else if abbr == nil {
                if let phoneNumberAndLink = phoneNumberAndLink {
                    result.append(phoneNumberAndLink)
                    phoneNumberAndLinkResult.reverse()
                    result.append(contentsOf: phoneNumberAndLinkResult)
                    break
                }
            } else if let phoneNumberAndLink = phoneNumberAndLink, let abbr = abbr {
                if NSIntersectionRange(phoneNumberAndLink.range, abbr.range).length > 0 { // 二者有交集，优先取abbr
                    result.append(abbr)
                } else if phoneNumberAndLink.range.upperBound <= abbr.range.lowerBound {
                    result.append(phoneNumberAndLink)
                    abbrResult.append(abbr)
                } else {
                    result.append(abbr)
                    phoneNumberAndLinkResult.append(phoneNumberAndLink)
                }
            }
        }

        return result
    }

    static func split(mergeResults: [MergeResult], content: String) -> [SplitResult] {
        guard !mergeResults.isEmpty, !content.isEmpty else { return [] }
        var mergeResults = mergeResults
        mergeResults.sort(by: { $0.range.location < $1.range.location })
        var pointerIndex: Int = 0
        var splitResults = [SplitResult]()
        for (resultType, range) in mergeResults {
            if range.location > pointerIndex {
                if let subStr = content.utf16SubString(from: pointerIndex, length: range.location - pointerIndex) {
                    splitResults.append((.other, subStr))
                    pointerIndex = range.location
                } else {
                    logger.error("split phoneNumberAndUrl & abbr error -> \(content.utf16.count) -> \(range) -> \(pointerIndex)")
                    return [(.other, content)]
                }
            }
            if let subStr = content.utf16SubString(from: range.location, length: range.length) {
                splitResults.append((resultType, subStr))
                pointerIndex = range.location + range.length
            } else {
                logger.error("split phoneNumberAndUrl & abbr error -> \(content.utf16.count) -> \(range) -> \(pointerIndex)")
                return [(.other, content)]
            }
        }
        // 最后剩下的text
        if pointerIndex < content.utf16.count, let subStr = content.utf16SubString(from: pointerIndex, length: content.utf16.count - pointerIndex) {
            splitResults.append((.other, subStr))
        } else if pointerIndex < content.utf16.count {
            logger.error("split phoneNumberAndUrl & abbr error -> \(content.utf16.count) -> \(pointerIndex)")
            return [(.other, content)]
        }
        return splitResults
    }
}

private extension String {
    func utf16SubString(from: Int, length: Int) -> String? {
        guard from < self.utf16.count, from + length <= self.utf16.count else { return nil }
        let start = self.utf16.index(utf16.startIndex, offsetBy: from)
        let end = self.utf16.index(utf16.startIndex, offsetBy: from + length)
        let subStr = self.utf16[start..<end]
        return String(subStr)
    }
}

// enable-lint: magic number
