//
//  RichTextAbilityParser.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import UIKit
import Foundation
import RustPB
import LarkMessageBase
import LarkCore
import LarkRichTextCore
import RichLabel
import EENavigator
import LarkMessengerInterface
import UniverseDesignFont
import LarkContainer

protocol RichTextAbilityParserDependency {
    var currentUserID: String { get }
    var maxWidth: CGFloat { get }
    func getColor(for key: ColorKey, type: Type) -> UIColor
    func openURL(url: URL)
}

final class RichTextAbilityParser {
    let userResolver: UserResolver
    var richText: RustPB.Basic_V1_RichText
    var showMoreCallBack: ((Bool) -> Void)?
    let dependency: RichTextAbilityParserDependency?
    let font: UIFont
    let textColor: UIColor
    let numberOfLines: Int
    let richTextSenderId: String?
    let contentLineSpacing: CGFloat
    let needNewLine: Bool
    let needCheckFromMe: Bool

    init(userResolver: UserResolver,
         dependency: RichTextAbilityParserDependency? = nil,
         richText: RustPB.Basic_V1_RichText,
         font: UIFont,
         textColor: UIColor = UIColor.ud.N900,
         numberOfLines: Int = 0,
         richTextSenderId: String? = nil,
         needNewLine: Bool = true,
         needCheckFromMe: Bool = true
         ) {
        self.userResolver = userResolver
        self.richText = richText
        self.dependency = dependency
        self.font = font
        self.textColor = textColor
        self.numberOfLines = numberOfLines
        self.richTextSenderId = richTextSenderId
        self.needNewLine = needNewLine
        self.needCheckFromMe = needCheckFromMe
        self.contentLineSpacing = font.figmaHeight - font.rowHeight
    }

    var attributedString: NSMutableAttributedString {
        let attrStr: NSMutableAttributedString = attributeElement.attriubuteText
        return attrStr
    }

    lazy var attributeElement: ParseRichTextResult = {
        return getAttributeElement(maxCharLine: getMaxCharCountAtOneLine())
    }()

    /// 文本内容检查
    public lazy var textCheckingDetecotor: NSRegularExpression? = {
        return RichLabel.DataCheckDetector
    }()

    /// 链接按压态样式
    public lazy var activeLinkAttributes: [NSAttributedString.Key: Any] = {
        if let color = self.dependency?.getColor(for: .Message_Text_ActionPressed, type: self.isFromMe ? .mine : .other) {
            return [LKBackgroundColorAttributeName: color]
        }
        return [:]
    }()

    /// 链接样式
    public lazy var linkAttributes: [NSAttributedString.Key: Any] = {
        return [.foregroundColor: UIColor.ud.textLinkNormal]
    }()

    /// 是不是我发的消息
    private lazy var isFromMe: Bool = {
        guard let richTextSenderId = self.richTextSenderId else { return false }
        return dependency?.currentUserID == richTextSenderId
    }()

    func checkIsFromMe(userId: String) -> Bool {
        return dependency?.currentUserID == userId
    }

    public let calculateMaxCharCountAtOneLine: (CGFloat) -> Int = { maxContentWidth in
        let oneNumberWidth: CGFloat = 7
        return Int(maxContentWidth / oneNumberWidth)
    }

    func openURL(_ url: String) {
        do {
            let url = try URL.forceCreateURL(string: url)
            dependency?.openURL(url: url)
        } catch {
        }
    }

    /// 内容的最大宽度
    public var contentMaxWidth: CGFloat? {
        return dependency?.maxWidth
    }

    /// 计算一行最多可以展示的字符数量
    private func getMaxCharCountAtOneLine() -> Int? {
        if let width = self.contentMaxWidth {
            return self.calculateMaxCharCountAtOneLine(width)
        }
        return nil
    }

    lazy var textLinkList: [LKTextLink] = {
        var textLinkList: [LKTextLink] = []
        self.attributeElement.textUrlRangeMap.forEach { (range, url) in
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { [weak self] (_, _) in
                self?.openURL(url)
            }
            textLinkList.append(textLink)
        }
        return textLinkList
    }()

    private func getAttributeElement(maxCharLine: Int?) -> ParseRichTextResult {
        var parseResult: ParseRichTextResult
        let paragraph = NSMutableParagraphStyle()
        let font = self.font
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: self.textColor,
            .font: font,
            .paragraphStyle: paragraph
        ]
        var atColor = AtColor()
        if let dependency = self.dependency {
            atColor.UnReadRadiusColor = dependency.getColor(for: .Message_At_UnRead, type: isFromMe ? .mine : .other)
            atColor.MeForegroundColor = dependency.getColor(for: .Message_At_Foreground_Me, type: isFromMe ? .mine : .other)
            atColor.MeAttributeNameColor = dependency.getColor(for: .Message_At_Background_Me, type: isFromMe ? .mine : .other)
            atColor.OtherForegroundColor = dependency.getColor(for: .Message_At_Foreground_InnerGroup, type: isFromMe ? .mine : .other)
            atColor.AllForegroundColor = dependency.getColor(for: .Message_At_Foreground_All, type: isFromMe ? .mine : .other)
            atColor.OuterForegroundColor = dependency.getColor(for: .Message_At_Foreground_OutterGroup, type: isFromMe ? .mine : .other)
            atColor.AnonymousForegroundColor = dependency.getColor(for: .Message_At_Foreground_Anonymous, type: isFromMe ? .mine : .other)
        }
        let textDocsVMResult = TextDocsViewModel(
            userResolver: userResolver,
            richText: self.richText,
            docEntity: nil
        )
        /// 替换richText
        self.richText = textDocsVMResult.richText

        /// 处理richText得到(NSMutableAttributedString, urlRangeMap, atRangeMap, textUrlRangeMap, abbreviarionRangeMap)
        parseResult = textDocsVMResult.parseRichText(
            isFromMe: self.isFromMe,
            isShowReadStatus: false,
            checkIsMe: self.needCheckFromMe ? self.checkIsFromMe : nil,
            botIds: [],
            maxLines: self.numberOfLines,
            maxCharLine: maxCharLine ?? 40,
            atColor: atColor,
            needNewLine: self.needNewLine,
            iconColor: UIColor.ud.textLinkNormal,
            customAttributes: attributes,
            abbreviationInfo: nil
        )
        return parseResult
    }
}
