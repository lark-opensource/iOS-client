//
//  LDTextableAreaComponent.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/23.
//

import Foundation
import RichLabel
import LarkModel
import AsyncComponent
import LarkEmotion
import UIKit
import LarkFeatureGating

final class TextableAreaComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .textablearea
    }

    override var needChildren: Bool {
        return true
    }

    override var needRecursiveSubComponents: Bool {
        return false
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let elementStyle = (context?.wideCardMode ?? false) ? element.wideStyle: element.style

        let component = TextableAreaComponent2<C>(
            props: buildProps(element.property.textableArea, children, style, elementStyle, context, translateLocale),
            style: style,
            context: context
        )
        component.richtext = richtext
        return component

    }
    private func buildProps(_ property: RichTextElement.TextableAreaProperty,
                            _ children: [RichTextElement],
                            _ style: LDStyle,
                            _ originTextStyle: [String: String] = [:],
                            _ context: LDContext?,
                            _ translateLocale: Locale?)
        -> TextableAreaComponentProps {
        let props = TextableAreaComponentProps(context: context)
        props.lineSpacing = 3
        props.numberOfLines = Int(property.numberOfLines)
        props.outOfRangeText = NSAttributedString(string: messsageCardOutOfRangeText)
        props.textColor = (style.getColor() ?? UIColor.ud.N900).withContext(context: context)
        props.font = style.font
        props.texts = children
        props.lineBreakMode = .byWordWrapping
        props.originStyle = originTextStyle
        props.translateLocale = translateLocale
        style.paddingTop = style.paddingTop.value > 0 ? style.paddingTop : 1.5
        style.paddingBottom = style.paddingBottom.value > 0 ? style.paddingBottom : 1.5
        props.key = context?.getCopyabelComponentKey()
        return props
    }
}

final class TextableAreaComponentProps: LabelComponentProps {
    var isUserInteractionEnabled: Bool = true
    lazy var meForegroundColor: UIColor = UIColor.ud.primaryOnPrimaryFill.withContext(context: self.context)
    lazy var othersForegroundColor: UIColor = UIColor.ud.textLinkNormal.withContext(context: self.context)
    lazy var othersOutChatForegroundColor: UIColor = UIColor.ud.textCaption
    lazy var atAttributeName: UIColor = UIColor.ud.colorfulBlue.withContext(context: self.context)
    var translateLocale: Locale?
    var texts: [RichTextElement] = []
    var originStyle: [String: String] = [:]
    override init(context: LDContext?) {
        super.init(context: context)
    }
}

//为可控地进行灰度，使用新的组件换用LKSelectionLabel
class TextableAreaComponent2<C: LDContext>: ASComponent<TextableAreaComponentProps, EmptyState, LKSelectionLabel, C> {
    private var layoutEngine: LKTextLayoutEngine
    private var textParser: LKTextParser
    private var linkParser: LKLinkParserImpl
    private var atUserIdRangeMap: [String: [NSRange]] = [:]
    fileprivate var richtext: RichText?

    override init(props: TextableAreaComponentProps, style: ASComponentStyle, context: C? = nil) {
        self.layoutEngine = LKTextLayoutEngineImpl()
        self.textParser = LKTextParserImpl()
        self.linkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        super.init(props: props, style: style, context: context)
    }
    override func update(view: LKSelectionLabel) {
        super.update(view: view)
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
        view.delegate = self
        view.activeLinkAttributes = props.activeLinkAttributes
        view.linkAttributes = props.linkAttributes
        view.numberOfLines = props.numberOfLines
        view.textParser = textParser
        view.linkParser = linkParser
        view.setForceLayout(layoutEngine)

        //与原组件相比新增
        view.selectionDelegate = context?.selectionLabelDelegate
        view.options = [
            .cursorColor(UIColor.ud.colorfulBlue),
            .selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.16)),
            .cursorTouchHitTestInsets(UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25))
        ]
        //与原组件相比新增
    }

    override var isSelfSizing: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return self.layoutEngine.layout(size: size)
    }

    override func render() -> BaseVirtualNode {
        let (attrStr, urlMap, atUserIdRangeMap) = self.convertTexts2AttrStr(
            elements: self.props.texts,
            parentStyle: props.originStyle,
            context: context
        )
        self.atUserIdRangeMap = atUserIdRangeMap
        props.rangeLinkMap = urlMap
        props.tapableRangeList = atUserIdRangeMap.flatMap({ $1 })
        props.numberOfLines = props.numberOfLines
        textParser.originAttrString = attrStr
        labelRender(props, textParser: &textParser, linkParser: &linkParser, layoutEngine: &layoutEngine)

        return super.render()
    }
}

extension TextableAreaComponent2: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        let start = Date()
        context?.openLink(url, from: .innerLink()){ [weak context] error in
            context?.reportAction(
                start: start,
                trace: context?.trace.subTrace(),
                actionID: nil,
                actionType: .url,
                error: error
            )
        }
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        for (userId, ranges) in self.atUserIdRangeMap where ranges.contains(range) && userId != "all" {
            self.context?.openProfile(chatterID: userId)
            return false
        }
        return true
    }

    private func convertTexts2AttrStr(
        elements: [RichTextElement],
        startLoc: Int = 0,
        parentStyle: [String: String] = [:],
        context: LDContext?
    ) -> (NSMutableAttributedString, [NSRange: URL], [String: [NSRange]]) {
        let font = props.font
        let mutAttrStr = NSMutableAttributedString()
        var urlMap: [NSRange: URL] = [:]
        var atUserIdRangeMap: [String: [NSRange]] = [:]
        var location = startLoc
        #if DEBUG
        func logTextAttriMap(map: [NSAttributedString.Key: Any], content: String) {
            for key in map.keys {
                if let color = map[key] as? UIColor {
                    cardlog.info("TextComponent convertTexts2AttrStr add for \(content) \(key) \(color.alwaysLight.hex8) \(color.alwaysDark.hex8)")
                }
            }
        }
        #endif

        elements.compactMap { (element: RichTextElement) -> NSAttributedString? in
            var elementStyle = (context?.wideCardMode ?? false) ? element.wideStyle: element.style
            let curStyles = elementStyle.merging(parentStyle) { string, _ in string }
            let styles = StyleParser.parse(curStyles)
            let ldStyle = LDStyle(context: context, elementId: "")
            ldStyle.styleValues = styles
            switch element.tag {
            case .text:
                var map = fixDefaultColorForText(convert2Attributes(.byWordWrapping, ldStyle, font: font))
                map = fixStrikeThroughForText(map)
                let attrString = NSAttributedString(string: element.property.text.content, attributes: map)
                location += attrString.length
                #if DEBUG
                logTextAttriMap(map: map, content: element.property.text.content)
                #endif
                return attrString
            case .b:
                var map = convert2Attributes(.byWordWrapping, ldStyle, font: font)
                map[.font] = font.bold()
                let attrString = NSAttributedString(string: element.property.bold.content, attributes: map)
                location += attrString.length
                #if DEBUG
                logTextAttriMap(map: map, content: element.property.bold.content)
                #endif
                return attrString
            case .u:
                var map = fixDefaultColorForU(convert2Attributes(.byWordWrapping, ldStyle, font: font))
                map = fixStrikeThroughForText(map)
                let attrString = NSAttributedString(string: element.property.underline.content, attributes: map)
                location += attrString.length
                #if DEBUG
                logTextAttriMap(map: map, content: element.property.underline.content)
                #endif
                return attrString
            case .i:
                var map = convert2Attributes(.byWordWrapping, ldStyle, font: font)
                if map[.obliqueness] == nil {
                    map[.obliqueness] = NSNumber(value: 0.5)
                }
                let attrString = NSAttributedString(string: element.property.italic.content, attributes: map)
                location += attrString.length
                #if DEBUG
                logTextAttriMap(map: map, content: element.property.italic.content)
                #endif
                return attrString
            case .at:
                let userID = element.property.at.userID
                let atContent = element.property.at.atContent
                var map = convert2Attributes(.byWordWrapping, ldStyle, font: font)
                if self.context?.isMe(userID) == true {
                    map[.foregroundColor] = props.meForegroundColor
                    map[LKAtAttributeName] = props.atAttributeName
                } else {
                    map[.foregroundColor] = props.othersForegroundColor
                }
                map = fixDefaultColorForAt(map)
                map = fixStrikeThroughForText(map)
                var range = NSRange(location: location, length: 0)
                let attrString = NSMutableAttributedString(string: atContent, attributes: map)
                location += attrString.length
                range.length = attrString.length

                var ranges = atUserIdRangeMap[userID] ?? []
                ranges.append(range)
                atUserIdRangeMap[userID] = ranges
                #if DEBUG
                logTextAttriMap(map: map, content: atContent)
                #endif
                return attrString
            case .a:
                let anchor = element.property.anchor
                /// 开放平台 非 Office 场景，暂时逃逸
                // swiftlint:disable ban_linebreak_byChar
                var map = fixDefaultColorForA(convert2Attributes(.byCharWrapping, ldStyle, font: font))
                // swiftlint:enable ban_linebreak_byChar
                map = fixStrikeThroughForText(map)
                let attrString = NSAttributedString(string: anchor.content, attributes: map)
                if anchor.hasIosHref, let url = anchor.iosHref.possibleURL() {
                    urlMap[NSRange(location: location, length: attrString.length)] = url
                } else if element.property.anchor.hasHref, let url = anchor.href.possibleURL() {
                    urlMap[NSRange(location: location, length: attrString.length)] = url
                }
                location += attrString.length
                #if DEBUG
                logTextAttriMap(map: map, content: anchor.content)
                #endif
                return attrString
            case .emotion:
                var emojiKey = element.property.emotion.key
                emojiKey = emojiKey.lf.trimCharacters(in: ["["], postion: .lead)
                emojiKey = emojiKey.lf.trimCharacters(in: ["]"], postion: .tail)
                // 资源统一从EmotionResouce获取
                guard let icon = loadEmotion(emojiKey) else {
                    return nil
                }
                location += 1
                let styles = StyleParser.parse(curStyles)
                /// 开放平台 非 Office 场景，暂时逃逸
                // swiftlint:disable ban_linebreak_byChar
                var map = fixDefaultColorForEmotion(convert2Attributes(.byCharWrapping, ldStyle, font: font))
                // swiftlint:enable ban_linebreak_byChar
                map[LKEmojiAttributeName] = LKEmoji(icon: icon, font: (map[.font] as? UIFont) ?? font)
                #if DEBUG
                logTextAttriMap(map: map, content: emojiKey)
                #endif
                return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: map)
            case .textablearea:
                if let richtext = richtext, !element.childIds.isEmpty {
                    let childrens = element.childIds.compactMap({ richtext.elements[$0] })
                    let (attrStr, innerUrlMap, innerAtUserIdRangeMap)
                        = self.convertTexts2AttrStr(elements: childrens,
                                                    startLoc: location,
                                                    parentStyle: curStyles,
                                                    context: context)
                    urlMap.merge(innerUrlMap) { url, _ in url }
                    atUserIdRangeMap.merge(innerAtUserIdRangeMap) { ranges, _ in ranges }
                    location += attrStr.length
                    return attrStr
                }
                return nil
            case .time:
                var map = convert2Attributes(.byWordWrapping, ldStyle, font: font)
                if element.property.time.hasLink {
                    map[.foregroundColor] = UIColor.ud.textLinkNormal.withContext(context: context)
                }
                map = fixStrikeThroughForText(fixDefaultColorForText(map))
                if let timeContent = getFormatTime(formatType: element.property.time.formatType,
                                                                          timestamp: element.property.time.millisecondSince1970,
                                                                          translateLocale: props.translateLocale,
                                                                          context: context) {
                    let attrString = NSAttributedString(string: timeContent, attributes: map)
                    if element.property.time.hasLink,
                       let url = URL(string: element.property.time.link) {
                        urlMap[NSRange(location: location, length: attrString.length)] = url
                    }
                    location += attrString.length
                    #if DEBUG
                    logTextAttriMap(map: map, content: timeContent)
                    #endif
                    return attrString
                } else {
                    cardlog.error("TextableComponent getFormatTime failed")
                    return nil
                }
            @unknown default:
                return nil
            }
        }.forEach { (attrStr: NSAttributedString) -> Void in
            mutAttrStr.append(attrStr)
        }
        #if DEBUG
        cardlog.info("TextComponent convertTexts2AttrStr \(mutAttrStr)")
        #endif
        return (mutAttrStr, urlMap, atUserIdRangeMap)
    }

    private func fixDefaultColorForText(_ map: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var map = map
        let textColor = map[.foregroundColor]
            ?? map[NSAttributedString.Key(kCTForegroundColorAttributeName as String)]
            ?? self.props.textColor
        if map[.underlineStyle] != nil {
            map[.underlineColor] = map[.underlineColor] ?? textColor
        }
        if map[.strikethroughStyle] != nil {
            map[.strikethroughColor] = map[.strikethroughColor] ?? textColor
        }
        map[.foregroundColor] = map[.foregroundColor] ?? textColor
        return map
    }

    private func fixStrikeThroughForText(_ map: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var map = map
        if let strikeThroughColor = map[.strikethroughColor] as? UIColor,
           let strikeThroughStyle = map[.strikethroughStyle] as? NSNumber,
           strikeThroughStyle == (NSUnderlineStyle.single.rawValue as NSNumber) {
            map[LKLineAttributeName] = LKLineStyle( color: strikeThroughColor, position: .strikeThrough, style: .line)
            map.removeValue(forKey: .strikethroughStyle)
            map.removeValue(forKey: .strikethroughColor)
        }
        return map
    }

    private func fixDefaultColorForU(_ map: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var map = map
        if map[.underlineColor] == nil {
            map[.underlineColor] = map[.foregroundColor] ?? self.props.textColor
        }
        if map[.underlineStyle] == nil {
            map[.underlineStyle] = NSNumber(value: NSUnderlineStyle.single.rawValue)
        }
        return map
    }

    private func fixDefaultColorForAt(_ map: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var map = map
        if map[.underlineStyle] != nil {
            map.removeValue(forKey: .underlineStyle)
            map.removeValue(forKey: .underlineColor)
        }
        let textColor = map[.foregroundColor]
            ?? map[NSAttributedString.Key(kCTForegroundColorAttributeName as String)]
            ?? self.props.textColor
        if map[.strikethroughStyle] != nil {
            map[.strikethroughColor] = map[.strikethroughColor] ?? textColor
        }
        return map
    }

    private func fixDefaultColorForA(_ map: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var map = map
        if map[.underlineColor] == nil {
            map[.underlineColor] = UIColor.ud.textLinkNormal
        }
        if map[.strikethroughColor] == nil {
            map[.strikethroughColor] = UIColor.ud.textLinkNormal
        }
        map[.foregroundColor] = UIColor.ud.textLinkNormal
        return map
    }

    private func fixDefaultColorForEmotion(
        _ map: [NSAttributedString.Key: Any]
    ) -> [NSAttributedString.Key: Any] {
        return fixDefaultColorForAt(map)
    }

    private func convert2Attributes(
        _ lineBreakMode: NSLineBreakMode,
        _ style: LDStyle,
        font: UIFont
    ) -> [NSAttributedString.Key: Any] {
        var map: [NSAttributedString.Key: Any] = [:]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = lineBreakMode
        var fontWeightValue: Double = 0, fontStyleValue: Double = 0
        let styleValues = style.styleValues
        for styleValue in styleValues {
            switch styleValue {
            case .underlineColor(let color):
                map[.underlineColor] = (style.getUnderlineColor() ?? color).withContext(context: context)
            case .underlineStyle(let style):
                map[.underlineStyle] = NSNumber(value: style.rawValue)
            case .strikethroughColor(let color):
                map[.strikethroughColor] = (style.getStrikethroughColor() ?? color).withContext(context: context)
            case .strikethroughStyle(let style):
                map[.strikethroughStyle] = NSNumber(value: style.rawValue)
            case .fontSize(let size):
                let fontSize = context?.zoomFontSize(originSize: size) ?? size
                if let font = map[.font] as? UIFont {
                    map[.font] = font.withSize(fontSize)
                } else {
                    map[.font] = UIFont.systemFont(ofSize: fontSize)
                }
            case .fontWeight(let value):
                fontWeightValue = value.doubleValue
            case .fontObliqueness(let value):
                fontStyleValue = value.doubleValue
            case .color(let color):
                let dynamicColor: UIColor = (style.getColor() ?? color).withContext(context: context)
                map[.foregroundColor] = dynamicColor
            case .textAlign(let value):
                paragraphStyle.alignment = value
            case .wordBreak(let value):
                paragraphStyle.lineBreakMode = value
            default:
                continue
            }
        }

        map[.paragraphStyle] = paragraphStyle
        if map[.font] == nil {
            map[.font] = font
        }
        if let originFont = map[.font] as? UIFont {
            map[.font] = LDStyle.font(originFont: originFont, enumValue: fontStyleValue + fontWeightValue)
        }
        return map
    }
}
