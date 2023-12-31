//
//  LDLabelRender.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/23.
//

import Foundation
import RichLabel
import AsyncComponent
import UniverseDesignColor

// 收敛消息卡片所有相关Prop属性
public class LabelComponentProps: ASComponentProps {
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    public var lineSpacing: CGFloat = 3.0
    public var numberOfLines: Int = 0
    public var preferMaxLayoutWidth: CGFloat = -1.0
    /// 开放平台 非 Office 场景，暂时逃逸
    // swiftlint:disable ban_linebreak_byChar
    public var lineBreakMode: NSLineBreakMode = .byCharWrapping
    // swiftlint:enable ban_linebreak_byChar
    public var backgroudColor: UIColor = .clear
    public lazy var textColor: UIColor = (UIColor.ud.N600 & UIColor.ud.rgb(0xF0F0F0)).withContext(context: self.context)
    public var content: String?
    public var outOfRangeText: NSAttributedString = NSAttributedString(string: messsageCardOutOfRangeText)
    public var attributedText: NSAttributedString?
    public var linkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textLinkNormal
    ]
    public var activeLinkAttributes: [NSAttributedString.Key: Any] = [
        LKBackgroundColorAttributeName: UIColor.ud.N200
    ]
    public var rangeLinkMap: [NSRange: URL] = [:]
    public var textLinkList: [LKTextLink] = []
    public var tapableRangeList: [NSRange] = []
    public weak var delegate: LKLabelDelegate?
    public let context: LDContext?
    init(context: LDContext?) {
        self.context = context
        let fontSize = context?.zoomFontSize(originSize: UIFont.systemFontSize) ?? UIFont.systemFontSize
        self.font = UIFont.systemFont(ofSize: fontSize)
    }
}

// 将prop属性值配置到TextParser，LinkParser，LKTextLayoutEngine,为Render做好准备
func labelRender(
    _ props: LabelComponentProps,
    textParser: inout LKTextParser,
    linkParser: inout LKLinkParserImpl,
    layoutEngine: inout LKTextLayoutEngine) {

    linkParser.defaultFont = props.font
    linkParser.linkAttributes = props.linkAttributes
    linkParser.rangeLinkMapper = props.rangeLinkMap
    linkParser.textLinkList = props.textLinkList
    linkParser.tapableRangeList = props.tapableRangeList

    textParser.defaultFont = props.font
    textParser.parse()

    linkParser.originAttrString = textParser.renderAttrString
    linkParser.parserIndicesToOriginIndices = textParser.parserIndicesToOriginIndices
    linkParser.parse()

    layoutEngine.attributedText = linkParser.renderAttrString
    layoutEngine.preferMaxWidth = props.preferMaxLayoutWidth
    layoutEngine.lineSpacing = props.lineSpacing
    layoutEngine.outOfRangeText = props.outOfRangeText
    layoutEngine.numberOfLines = props.numberOfLines
}

// 将ASComponentStyle构造成卡片渲染的属性集合
func attributedBuilder(style: ASComponentStyle,
                       lineBreakMode: NSLineBreakMode,
                       context: LDContext?,
                       textColorCustom: UIColor? = nil) -> [NSAttributedString.Key: Any] {
    let ldStyle = style as? LDStyle ?? LDStyle(context: context)
    var textColor = (ldStyle.getColor() ?? (UIColor.ud.N900 & UIColor.ud.rgb(0xF0F0F0))).withContext(context: context)
    if let _textColorCustom = textColorCustom {
        textColor = _textColorCustom
    }
    var attrbuties: [NSAttributedString.Key: Any] = [
        .foregroundColor: textColor,
        .font: ldStyle.font,
        .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            paragraphStyle.alignment = ldStyle.textAlign
            return paragraphStyle
        }()
    ]
    if let underlineStyle = ldStyle.underlineStyle {
        attrbuties[.underlineStyle] = NSNumber(value: underlineStyle.rawValue)
        attrbuties[.underlineColor] = ldStyle.getUnderlineColor() ?? textColor
    }
    if let strikethroughStyle = ldStyle.strikethroughStyle {
        attrbuties[.strikethroughStyle] = NSNumber(value: strikethroughStyle.rawValue)
        attrbuties[.strikethroughColor] = ldStyle.getStrikethroughColor() ?? textColor
    }
    #if DEBUG
    cardlog.info("TextComponent Dark \(textColor.alwaysDark.hex8) Light: \(textColor.alwaysLight.hex8)")
    if textColor.alwaysLight.hex8! == "#FFF0F0F0" {
        cardlog.info("date picker wrong color")
    }
    #endif
    return attrbuties
}
