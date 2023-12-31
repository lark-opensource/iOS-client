//
//  ParseRichTextAbility.swift
//  Moment
//
//  Created by zc09v on 2021/1/8.
//
import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkFoundation
import LarkCore
import LarkRichTextCore
import LarkMessageCore
import LarkContainer
import RichLabel
import ByteWebImage
import LarkMessengerInterface
import LarkUIKit
import LarkSDKInterface
import TangramService
import EENavigator
import RustPB

protocol RichTextAbilityParserDependency {
    var targetVC: UIViewController? { get }
    var maxWidth: CGFloat { get }
    func getColor(for key: ColorKey, type: Type) -> UIColor
}

final class RichTextAbilityParser {
    let userResolver: UserResolver
    var richText: RustPB.Basic_V1_RichText
    var showTranslatedTag: Bool
    var showMoreCallBack: ((Bool) -> Void)?
    var didClickHashTag: (((String, String)) -> Void)?
    let dependency: RichTextAbilityParserDependency?
    let font: UIFont
    let textColor: UIColor
    let iconColor: UIColor
    let tagType: TagType
    let numberOfLines: Int
    let richTextSenderId: String?
    let contentLineSpacing: CGFloat
    let needNewLine: Bool
    let needCheckFromMe: Bool
    var urlPreviewProvider: LarkCoreUtils.URLPreviewProvider?

    init(userResolver: UserResolver,
         dependency: RichTextAbilityParserDependency? = nil,
         richText: RustPB.Basic_V1_RichText,
         font: UIFont,
         showTranslatedTag: Bool = false,
         textColor: UIColor = UIColor.ud.N900,
         iconColor: UIColor = UIColor.ud.N900,
         tagType: TagType = .normal,
         numberOfLines: Int = 0,
         richTextSenderId: String? = nil,
         contentLineSpacing: CGFloat = 4,
         needNewLine: Bool = true,
         needCheckFromMe: Bool = true,
         urlPreviewProvider: LarkCoreUtils.URLPreviewProvider? = nil
         ) {
        self.userResolver = userResolver
        self.richText = richText
        self.showTranslatedTag = showTranslatedTag
        self.dependency = dependency
        self.font = font
        self.textColor = textColor
        self.iconColor = iconColor
        self.tagType = tagType
        self.numberOfLines = numberOfLines
        self.richTextSenderId = richTextSenderId
        self.contentLineSpacing = contentLineSpacing
        self.needNewLine = needNewLine
        self.needCheckFromMe = needCheckFromMe
        self.urlPreviewProvider = urlPreviewProvider
    }

    var attributedString: NSMutableAttributedString {
        //【译】标签后面加个空格
        var translateTagString = showTranslatedTag ? "\(BundleI18n.Moment.Moments_TranslatedMoments_Tag) " : ""
        var attrStr = NSMutableAttributedString(string: translateTagString, attributes: elementAttributes)
        attrStr.append(attributeElement.attriubuteText)
        return attrStr
    }

    lazy var attributeElement: ParseRichTextResult = {
        return getAttributeElement(maxCharLine: getMaxCharCountAtOneLine())
    }()

    /// 文本内容检查 这里只解析number 不解析 URL 
    public lazy var textCheckingDetecotor: NSRegularExpression? = {
        return RichLabel.NumberCheckDetector
    }()

    /// 链接按压态样式
    public lazy var activeLinkAttributes: [NSAttributedString.Key: Any] = {
        if let color = self.dependency?.getColor(for: .Message_Text_ActionPressed, type: self.isFromMe ? .mine : .other) {
            return [LKBackgroundColorAttributeName: color]
        }
        return [:]
    }()

    public lazy var linkAttributes: [NSAttributedString.Key: Any] = {
        return [.foregroundColor: UIColor.ud.textLinkNormal]
    }()

    /// 是不是我发的消息
    private lazy var isFromMe: Bool = {
        guard let richTextSenderId = self.richTextSenderId else { return false }
        return userResolver.userID == richTextSenderId
    }()

    func checkIsFromMe(userId: String) -> Bool {
        return userResolver.userID == userId
    }

    public let calculateMaxCharCountAtOneLine: (CGFloat) -> Int = { maxContentWidth in
        let oneNumberWidth: CGFloat = 7
        return Int(maxContentWidth / oneNumberWidth)
    }

    func openURL(_ url: String) {
        do {
            guard let targetVC = dependency?.targetVC else {
                return
            }
            let url = try URL.forceCreateURL(string: url)
            userResolver.navigator.push(url, from: targetVC)
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

    func updateRichText(_ richText: RustPB.Basic_V1_RichText) {
        self.richText = richText
        self.attributeElement = getAttributeElement(maxCharLine: getMaxCharCountAtOneLine())
    }

    var elementAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        let font = self.font
        return [
            .foregroundColor: self.textColor,
            .font: font,
            .paragraphStyle: paragraph,
            MomentInlineViewModel.iconColorKey: iconColor,
            MomentInlineViewModel.tagTypeKey: tagType
        ]
    }

    private func getAttributeElement(maxCharLine: Int?) -> ParseRichTextResult {
        var parseResult: ParseRichTextResult
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
            iconColor: iconColor,
            customAttributes: elementAttributes,
            abbreviationInfo: nil,
            urlPreviewProvider: urlPreviewProvider,
            hashTagProvider: { (option, suggestFont) in
                let content = option.element.property.mention.content
                return NSMutableAttributedString(
                    string: content,
                    attributes: [
                        .foregroundColor: UIColor.ud.textLinkNormal,
                        .font: suggestFont
                    ]
                )
            }
        )
        return parseResult
    }

    func update(richText: RustPB.Basic_V1_RichText? = nil,
                urlPreviewProvider: LarkCoreUtils.URLPreviewProvider? = nil,
                showTranslatedTag: Bool? = nil) {
        if let richText = richText {
            self.richText = richText
        }
        if let provider = urlPreviewProvider {
            self.urlPreviewProvider = provider
        }
        if let showTranslatedTag = showTranslatedTag {
            self.showTranslatedTag = showTranslatedTag
        }
        self.attributeElement = getAttributeElement(maxCharLine: getMaxCharCountAtOneLine())
    }
}

extension RichTextAbilityParser: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        if let httpUrl = url.lf.toHttpUrl(), let targetVC = dependency?.targetVC {
            userResolver.navigator.push(httpUrl, from: targetVC)
        }
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        guard let targetVC = dependency?.targetVC else {
            return
        }
        userResolver.navigator.open(body: OpenTelBody(number: phoneNumber), from: targetVC)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let targetVC = self.dependency?.targetVC else {
            return true
        }
        let attributeElement = self.attributeElement
        let atUserIdRangeMap = attributeElement.atRangeMap
        for (userID, ranges) in atUserIdRangeMap where ranges.contains(range) && userID != "all" {
            MomentsNavigator.pushUserAvatarWith(userResolver: userResolver,
                                                userID: userID,
                                                from: targetVC,
                                                source: nil,
                                                trackInfo: nil)
            return false
        }
        for (ran, mention) in attributeElement.mentionsRangeMap where ran == range {
            switch mention.clickAction.actionType {
            case .none:
                break
            case .redirect:
                if let url = URL(string: mention.clickAction.redirectURL) {
                    userResolver.navigator.open(url, from: targetVC)
                }
            @unknown default: assertionFailure("unknow type")
            }
            return false
        }
        for (ran, mention) in attributeElement.hashTagMap where (ran == range && !mention.item.id.isEmpty) {
            var body = MomentsHashTagDetialByIDBody(hashTagID: mention.item.id, content: mention.content)
            if let pageAPI = targetVC as? PageAPI,
               pageAPI.childVCMustBeModalView {
                body.isPresented = true
                userResolver.navigator.present(body: body,
                                         wrap: LkNavigationController.self,
                                         from: pageAPI) { vc in
                    vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
                }
            } else {
                userResolver.navigator.push(body: body, from: targetVC)
            }
            didClickHashTag?((mention.item.id, mention.content))
            return false
        }
        return true
    }
    /// 当前行数下是否可以展示完全
    public func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {
        self.showMoreCallBack?(isShowMore)
    }

    /// 点击...全文调用
    func tapShowMore(_ label: RichLabel.LKLabel) {
    }

}
