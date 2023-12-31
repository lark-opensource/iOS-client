//
//  LarkRichTextCoreUtils.swift
//  LarkRichTextCore
//
//  Created by chengzhipeng-bytedance on 2018/6/15.
//

// swiftlint:disable all
// disable-lint: magic number

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkFoundation
import LarkExtensions
import RichLabel
import RustPB
import LarkEmotion
import UniverseDesignIcon
import UniverseDesignColor
import LarkFeatureGating

public extension LarkRichTextCoreUtils {

    public static func fileIcon(with fileName: String) -> UIImage {
        let defaultIconSize = CGSize(width: 48, height: 48)
        switch getFileType(fileName: fileName) {
        case .ae:
            return UDIcon.getIconByKey(.fileAeColorful, size: defaultIconSize)
        case .ai:
            return UDIcon.getIconByKey(.fileAiColorful, size: defaultIconSize)
        case .apk:
            return UDIcon.getIconByKey(.fileAndroidColorful, size: defaultIconSize)
        case .audio:
            return UDIcon.getIconByKey(.fileAudioColorful, size: defaultIconSize)
        case .excel:
            return UDIcon.getIconByKey(.fileExcelColorful, size: defaultIconSize)
        case .image:
            return UDIcon.getIconByKey(.fileImageColorful, size: defaultIconSize)
        case .pdf:
            return UDIcon.getIconByKey(.filePdfColorful, size: defaultIconSize)
        case .ppt:
            return UDIcon.getIconByKey(.filePptColorful, size: defaultIconSize)
        case .psd:
            return UDIcon.getIconByKey(.filePsColorful, size: defaultIconSize)
        case .sketch:
            return UDIcon.getIconByKey(.fileSketchColorful, size: defaultIconSize)
        case .txt:
            return UDIcon.getIconByKey(.fileTextColorful, size: defaultIconSize)
        case .video:
            return UDIcon.getIconByKey(.fileVideoColorful, size: defaultIconSize)
        case .word:
            return UDIcon.getIconByKey(.fileWordColorful, size: defaultIconSize)
        case .zip:
            return UDIcon.getIconByKey(.fileZipColorful, size: defaultIconSize)
        case .keynote:
            return UDIcon.getIconByKey(.fileKeynoteColorful, size: defaultIconSize)
        case .eml:
            return UDIcon.getIconByKey(.fileEmlColorful, size: defaultIconSize)
        case .msg:
            return UDIcon.getIconByKey(.fileMsgColorful, size: defaultIconSize)
        case .pages:
            return UDIcon.getIconByKey(.filePagesColorful, size: defaultIconSize)
        case .numbers:
            return UDIcon.getIconByKey(.fileNumbersColorful, size: defaultIconSize)
        default:
            return UDIcon.getIconByKey(.fileUnknowColorful, size: defaultIconSize)
        }
    }

    public static func fileIconColorful(with fileName: String, size: CGSize) -> UIImage {
        switch getFileType(fileName: fileName) {
        case .ae:
            return UDIcon.getIconByKey(.fileAeColorful, size: size)
        case .ai:
            return UDIcon.getIconByKey(.fileAiColorful, size: size)
        case .apk:
            return UDIcon.getIconByKey(.fileAndroidColorful, size: size)
        case .audio:
            return UDIcon.getIconByKey(.fileAudioColorful, size: size)
        case .excel:
            return UDIcon.getIconByKey(.fileExcelColorful, size: size)
        case .image:
            return UDIcon.getIconByKey(.fileImageColorful, size: size)
        case .pdf:
            return UDIcon.getIconByKey(.filePdfColorful, size: size)
        case .ppt:
            return UDIcon.getIconByKey(.filePptColorful, size: size)
        case .psd:
            return UDIcon.getIconByKey(.filePsColorful, size: size)
        case .sketch:
            return UDIcon.getIconByKey(.fileSketchColorful, size: size)
        case .txt:
            return UDIcon.getIconByKey(.fileTextColorful, size: size)
        case .video:
            return UDIcon.getIconByKey(.fileVideoColorful, size: size)
        case .word:
            return UDIcon.getIconByKey(.fileWordColorful, size: size)
        case .zip:
            return UDIcon.getIconByKey(.fileZipColorful, size: size)
        case .keynote:
            return UDIcon.getIconByKey(.fileKeynoteColorful, size: size)
        case .eml:
            return UDIcon.getIconByKey(.fileEmlColorful, size: size)
        case .msg:
            return UDIcon.getIconByKey(.fileMsgColorful, size: size)
        case .pages:
            return UDIcon.getIconByKey(.filePagesColorful, size: size)
        case .numbers:
            return UDIcon.getIconByKey(.fileNumbersColorful, size: size)
        default:
            return UDIcon.getIconByKey(.fileUnknowColorful, size: size)
        }
    }

    @available(*, deprecated, message: "use fileIcon(with:) instead")
    public static func wikiFileIcon(with fileName: String) -> UIImage {
        return fileIcon(with: fileName)
    }

    public static func isVideoFile(with fileName: String) -> Bool {
        switch getFileType(fileName: fileName) {
        case .video:
            return true
        default:
            return false
        }
    }

    public static func fileLadderIcon(with fileName: String) -> UIImage {
        return fileLadderIcon(with: fileName, size: CGSize(width: 70, height: 70))
    }

    public static func fileLadderIcon(with fileName: String, size: CGSize) -> UIImage {
        switch getFileType(fileName: fileName) {
        case .ae:
            return UDIcon.getIconByKey(.fileAeColorful, size: size)
        case .ai:
            return UDIcon.getIconByKey(.fileAiColorful, size: size)
        case .apk:
            return UDIcon.getIconByKey(.fileAndroidColorful, size: size)
        case .audio:
            return UDIcon.getIconByKey(.fileAudioColorful, size: size)
        case .excel:
            return UDIcon.getIconByKey(.fileExcelColorful, size: size)
        case .image:
            return UDIcon.getIconByKey(.fileImageColorful, size: size)
        case .pdf:
            return UDIcon.getIconByKey(.filePdfColorful, size: size)
        case .ppt:
            return UDIcon.getIconByKey(.filePptColorful, size: size)
        case .psd:
            return UDIcon.getIconByKey(.filePsColorful, size: size)
        case .sketch:
            return UDIcon.getIconByKey(.fileSketchColorful, size: size)
        case .txt:
            return UDIcon.getIconByKey(.fileTextColorful, size: size)
        case .video:
            return UDIcon.getIconByKey(.fileVideoColorful, size: size)
        case .word:
            return UDIcon.getIconByKey(.fileWordColorful, size: size)
        case .zip:
            return UDIcon.getIconByKey(.fileZipColorful, size: size)
        case .keynote:
            return UDIcon.getIconByKey(.fileKeynoteColorful, size: size)
        case .eml:
            return UDIcon.getIconByKey(.fileEmlColorful, size: size)
        case .msg:
            return UDIcon.getIconByKey(.fileMsgColorful, size: size)
        case .pages:
            return UDIcon.getIconByKey(.filePagesColorful, size: size)
        case .numbers:
            return UDIcon.getIconByKey(.fileNumbersColorful, size: size)
        default:
            return UDIcon.getIconByKey(.fileUnknowColorful, size: size)
        }
    }

    public static func docIcon(feedDocType: RustPB.Basic_V1_DocFeed.TypeEnum, fileName: String) -> UIImage {
        let docType: RustPB.Basic_V1_Doc.TypeEnum
        switch feedDocType {
        case .bitable:
            docType = .bitable
        case .doc:
            docType = .doc
        case .sheet:
            docType = .sheet
        case .file:
            docType = .file
        case .mindnote:
            docType = .mindnote
        case .slide:
            docType = .slide
        case .docx:
            docType = .docx
        case .wiki:
            docType = .wiki
        case .folder:
            docType = .folder
        case .catalog:
            docType = .catalog
        case .unknown:
            docType = .unknown
        case .slides:
            docType = .slides
        case .shortcut:
            docType = .unknown
        @unknown default:
            assert(false, "new value")
            docType = .unknown
        }
        return LarkRichTextCoreUtils.docIcon(docType: docType, fileName: fileName)
    }

    public static func docIconColorful(docType: RustPB.Basic_V1_Doc.TypeEnum, fileName: String) -> UIImage {
        let defaultIconSize = CGSize(width: 48, height: 48)
        switch docType {
        case .unknown:
            return Resources.doc_unknow_icon
        case .doc:
            return UDIcon.getIconByKey(.fileDocColorful, size: defaultIconSize)
        case .sheet:
            return UDIcon.getIconByKey(.fileSheetColorful, size: defaultIconSize)
        case .bitable:
            return UDIcon.getIconByKey(.fileBitableColorful, size: defaultIconSize)
        case .mindnote:
            return UDIcon.getIconByKey(.fileMindnoteColorful, size: defaultIconSize)
        case .slide:
            return UDIcon.getIconByKey(.fileSlideColorful, size: defaultIconSize)
        case .file:
            return LarkRichTextCoreUtils.fileIconColorful(with: fileName, size: defaultIconSize)
        case .docx:
            return UDIcon.getIconByKey(.fileDocxColorful, size: defaultIconSize)
        case .wiki:
            return UDIcon.getIconByKey(.fileDocColorful, size: defaultIconSize)
        case .folder:
            return UDIcon.getIconByKey(.fileFolderColorful, size: defaultIconSize)
        case .catalog:
            return UDIcon.getIconByKey(.fileFolderColorful, size: defaultIconSize)
        case .slides:
            return UDIcon.getIconByKey(.wikiSlidesColorful, size: defaultIconSize)
        case .shortcut:
            assert(false, "new value")
            return UDIcon.getIconByKey(.fileUnknowColorful, size: defaultIconSize)
        @unknown default:
            assert(false, "new value")
            return UDIcon.getIconByKey(.fileUnknowColorful, size: defaultIconSize)
        }
    }

    @available(*, deprecated, message: "Use docIcon(docType:, fileName:) instead")
    public static func wikiIcon(docType: RustPB.Basic_V1_Doc.TypeEnum, fileName: String) -> UIImage {
        return docIcon(docType: docType, fileName: fileName)
    }

    @available(*, deprecated, message: "Use docIconColorful(docType:, fileName:) instead")
    public static func wikiIconColorful(docType: RustPB.Basic_V1_Doc.TypeEnum, fileName: String) -> UIImage {
        return docIconColorful(docType: docType, fileName: fileName)
    }

    public static func docUrlIcon(docType: RustPB.Basic_V1_Doc.TypeEnum) -> UIImage {
        // 兜底用 doc icon
        var image = Resources.docUrlIcon_doc_icon
        switch docType {
        case .unknown:
            image = Resources.docUrlIcon_doc_icon
        case .doc:
            image = Resources.docUrlIcon_doc_icon
        case .sheet:
            image = Resources.docUrlIcon_sheet_icon
        case .bitable:
            image = Resources.docUrlIcon_bitable_icon
        case .mindnote:
            image = Resources.docUrlIcon_mindnote_icon
        case .slide:
            image = Resources.docUrlIcon_slide_icon
        case .file:
            image = Resources.docUrlIcon_file_icon
        case .docx:
            image = Resources.docUrlIcon_docx_icon
        case .wiki:
            image = Resources.docUrlIcon_doc_icon
        case .folder:
            image = Resources.docUrlIcon_folder_icon
        case .catalog:
            // 产品决策先用 doc 的 icon
            // image = Resources.docUrlIcon_folder_icon
            image = Resources.docUrlIcon_doc_icon
        case .slides:
            image = Resources.docUrlIcon_slides_icon
        case .shortcut:
            assert(false, "new value")
            image = Resources.docUrlIcon_doc_icon
        @unknown default:
            assert(false, "new value")
            image = Resources.docUrlIcon_doc_icon
        }
        return image.ud.withTintColor(UIColor.ud.textLinkNormal)
    }
}

// MARK: - 解析 richText.
public struct ParseRichTextResult {
    public var attriubuteText: NSMutableAttributedString

    public var urlRangeMap: [NSRange: URL]

    public var atRangeMap: [String: [NSRange]]

    /// 1. 有些字符串服务端认为是链接, 但无法转化成真正 URL
    /// 2. 也包含url转换后的可点击title
    public var textUrlRangeMap: [NSRange: String]

    /// range -> NER Abbreviations
    /// 实体识别：缩写词range -> 缩写词的释义列表
    public var abbreviationRangeMap: [NSRange: AbbreviationInfoWrapper]

    public var mentionsRangeMap: [NSRange: Basic_V1_HashTagMentionEntity]

    public var hashTagMap: [NSRange: Basic_V1_RichTextElement.MentionProperty]
}

// @人的richText颜色
public struct AtColor {
    /// @其他人已读时的颜色
    public var ReadBackgroundColor: UIColor = UIColor.ud.T400 & UIColor.ud.T500
    /// @其他人未读时的圆圈颜色
    public var UnReadRadiusColor: UIColor = UIColor.ud.N500
    /// @自己文本颜色
    public var MeForegroundColor: UIColor = UIColor.ud.primaryOnPrimaryFill
    /// @自己背景颜色
    public var MeAttributeNameColor: UIColor = UIColor.ud.functionInfoContentDefault
    /// @其他人文本颜色
    public var OtherForegroundColor: UIColor = UIColor.ud.textLinkNormal
    /// @all文本颜色
    public var AllForegroundColor: UIColor = UIColor.ud.textLinkNormal
    /// @群外的人文本颜色
    public var OuterForegroundColor: UIColor = UIColor.ud.textCaption
    /// @匿名用的颜色
    public var AnonymousForegroundColor: UIColor = UIColor.ud.N900

    public init() {}
}

public struct AbbreviationInfoWrapper {
    public var refs: [RustPB.Basic_V1_Ref]?
    public var abbres: [Basic_V1_Abbreviation.entity]?

    public init() {}
}

public extension LarkRichTextCoreUtils {
    /// attr: InlinePreview
    /// clickURL: 点击url，使用默认href时可不传
    typealias URLPreviewProvider = (_ elementID: String, _ customAttributes: [NSAttributedString.Key: Any]) -> (attr: NSAttributedString?, clickURL: String?)?

    static func defaultMaxChatLine() -> Int {
        if Display.pad {
            let maxWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            /// 1 字符 16 size font 宽度约为 7.2， 取整为 8
            let oneNumberWidth: CGFloat = 8
            return Int(maxWidth / oneNumberWidth)
        } else {
            return 40
        }
    }

    static let anchorKey = NSAttributedString.Key("LarkRichTextCoreUtils.anchor.key")

    /// needNewLine：是否需要在内容中添加换行符，有的场景不进行换行显示，比如：话题列表->某个话题回复区域
    static func parseRichText(richText: RustPB.Basic_V1_RichText,
                              isFromMe: Bool = false,
                              isShowReadStatus: Bool = true,
                              checkIsMe: ((_ userId: String) -> Bool)?,
                              botIds: [String] = [],
                              maxLines: Int = 0,
                              maxCharLine: Int = LarkRichTextCoreUtils.defaultMaxChatLine(),
                              atColor: AtColor = AtColor(),
                              needNewLine: Bool = true,
                              customAttributes: [NSAttributedString.Key: Any],
                              abbreviationInfo: [String: AbbreviationInfoWrapper]? = nil,
                              mentions: [String: Basic_V1_HashTagMentionEntity]? = nil,
                              imageAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.ImageProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              mediaAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.MediaProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              urlPreviewProvider: URLPreviewProvider? = nil,
                              hashTagProvider: ((RichTextWalkerOption<NSMutableAttributedString>, UIFont) -> NSMutableAttributedString)?
    ) -> ParseRichTextResult {
        // Character processing length
        // 当前总共处理了多少个字符，用来判断截断逻辑
        var location: Int = 0
        var urlRangeMap: [NSRange: URL] = [:]
        var atRangeMap: [String: [NSRange]] = [:]
        var textUrlRangeMap: [NSRange: String] = [:]
        var abbreviationRangeMap: [NSRange: AbbreviationInfoWrapper] = [:]

        // 取到用户自定义字体
        let customFont = (customAttributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 16)
        var mentionsRangeMap: [NSRange: Basic_V1_HashTagMentionEntity] = [:]
        var hashTagRangeMap: [NSRange: Basic_V1_RichTextElement.MentionProperty] = [:]

        /// 处理纯文本
        let buildAttributeText: AttributedStringOptionType = { option in
            let text = option.element
            var attrStr = NSMutableAttributedString(string: text.property.text.content, attributes: customAttributes)
            // 企业辞典
            if let wrapper = abbreviationInfo?[option.elementId] {
                let textContent = text.property.text.content
                let attri: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.ud.N900,
                    .font: customFont,
                    LKLineAttributeName: LKLineStyle(color: UIColor.ud.N900.withAlphaComponent(0.60),
                                                     style: .dash(width: 1.5, space: 2.0))
                ]
                var isV2Failed = false
                if let refs = wrapper.refs {
                    if !refs.isEmpty {
                        for ref in refs {
                            let start = Int(ref.span.start)
                            let end = Int(ref.span.end)
                            let textContentNSString = textContent as NSString
                            if start >= 0,
                                start < textContentNSString.length,
                                end > start,
                                end - start <= textContentNSString.length {
                                if ref.matchedWord != textContentNSString.substring(with: NSRange(location: start, length: end - start)) {
                                    isV2Failed = true
                                    break
                                } else {
                                    attrStr.addAttributes(attri, range: NSRange(location: start, length: end - start))
                                    abbreviationRangeMap[NSRange(location: location + start, length: end - start)] = wrapper
                                }
                            } else {
                                isV2Failed = true
                                break
                            }
                        }
                    }
                } else {
                    isV2Failed = true
                }
                if isV2Failed {
                    attrStr = NSMutableAttributedString(string: text.property.text.content, attributes: attri)
                    abbreviationRangeMap[NSRange(location: location, length: attrStr.length)] = wrapper
                }

            }
            location += attrStr.length
            return [attrStr]
        }

        /// 处理A
        let buildAttributeAnchor: AttributedStringOptionType = { option in
            let anchor = option.element
            var content = ""
            if anchor.property.anchor.hasTextContent {
                content = anchor.property.anchor.textContent
            } else {
                content = anchor.property.anchor.content
            }

            let attrStr: NSMutableAttributedString
            // 自定义链接不再参与URL中台解析：https://bytedance.feishu.cn/docx/doxcn155EbNTAcbaTQgYgc1fvMd
            let urlPreview = anchor.property.anchor.isCustom ? nil : urlPreviewProvider?(option.elementId, customAttributes)
            if let attr = urlPreview?.attr {
                attrStr = NSMutableAttributedString(attributedString: attr)
            } else {
                attrStr = NSMutableAttributedString(string: content, attributes: customAttributes)
            }
            /// 这里加个随机数 确保同样的数据 可以区分开
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "at.random.key")
            attrStr.addAttributes([Self.anchorKey: anchor.property.anchor,
                           randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"], range: NSRange(location: 0, length: attrStr.length))
            // 有时候服务端给的url前后会多出空白内容，需要去掉
            let href = (urlPreview?.clickURL ?? anchor.property.anchor.href).trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                let url = try URL.forceCreateURL(string: href)
                urlRangeMap[NSRange(location: location, length: attrStr.length)] = url
            } catch {
                textUrlRangeMap[NSRange(location: location, length: attrStr.length)] = href
            }
            location += attrStr.length
            return [attrStr]
        }

        /// 处理U
        let buildAttributeUnderline: AttributedStringOptionType = { option in
            let underline = option.element
            let content = underline.property.underline.content
            let attrStr = NSMutableAttributedString(string: content, attributes: customAttributes)
            location += attrStr.length
            return [attrStr]
        }

        // 处理link
        let buildAttributeLink: AttributedStringOptionType = { option in
            let children = option.results
            let link = option.element
            var length = 0
            for attributeStr in children {
                length += attributeStr.length
            }
            let range = NSRange(location: max(location - length, 0), length: length)
            do {
                let url = try URL.forceCreateURL(string: link.property.link.url)
                urlRangeMap[range] = url
            } catch {
                textUrlRangeMap[range] = link.property.link.url
            }
            return children
        }

        /// 处理<p>标签
        let buildAttributeParagraph: AttributedStringOptionType = { option in
            guard needNewLine else { return option.results }

            location += 1
            return option.results + [NSMutableAttributedString(string: "\n")]
        }
        /// 处理<figure>标签
        let buildAttributeFigure: AttributedStringOptionType = { option in
            guard needNewLine else { return option.results }

            location += 1
            return option.results + [NSMutableAttributedString(string: "\n")]
        }

        /// 处理 emotion 表情
        let buildAttributeEmotion: AttributedStringOptionType = { option in
            let emotion = option.element
            if let icon = EmotionResouce.shared.imageBy(key: emotion.property.emotion.key) {
                // emoji之间距离要调整成2
                // Spacing between emojis needs to be 2pt.
                let emoji = LKEmoji(icon: icon, font: customFont, spacing: 1)
                let attrStr = NSMutableAttributedString(
                    string: LKLabelAttachmentPlaceHolderStr,
                    attributes: [
                        LKEmojiAttributeName: emoji,
                        .kern: 20
                    ]
                )
                location += 1
                return [attrStr]
            }

            let attrStr = NSMutableAttributedString(string: "[\(emotion.property.emotion.key)]", attributes: customAttributes)
            location += attrStr.length
            return [attrStr]
        }

        /// 处理图片
        let buildAttributeImage: AttributedStringOptionType = { option in
            let img = option.element
            if let attachmentViewProvider = imageAttachmentViewProvider {
                let attrStr = NSMutableAttributedString(
                    string: LKLabelAttachmentPlaceHolderStr,
                    attributes: [LKAttachmentAttributeName: attachmentViewProvider(img.property.image, customFont)]
                )
                location += 1
                return [attrStr]
            }

            let attrStr = NSMutableAttributedString(string: BundleI18n.LarkRichTextCore.Lark_Legacy_ImageSummarize, attributes: customAttributes)
            location += attrStr.length
            return [attrStr]
        }

        /// 处理视频(media)标签
        let buildAttributeMedia: AttributedStringOptionType = { option in
            let media = option.element
            if let attachmentViewProvider = mediaAttachmentViewProvider {
                let attrStr = NSMutableAttributedString(
                    string: LKLabelAttachmentPlaceHolderStr,
                    attributes: [LKAttachmentAttributeName: attachmentViewProvider(media.property.media, customFont)]
                )
                location += 1
                return [attrStr]
            }

            let attrStr = NSMutableAttributedString(string: BundleI18n.LarkRichTextCore.Lark_Legacy_VideoSummarize, attributes: customAttributes)
            location += attrStr.length
            return [attrStr]
        }

        /// 处理代码块，LKLabel不支持渲染代码块，代码块目前只能由LKRichView渲染
        let buildCode: AttributedStringOptionType = { option in
            let attrStr = NSMutableAttributedString(string: BundleI18n.LarkRichTextCore.Lark_IM_CodeBlockQuote_Text, attributes: customAttributes)
            location += attrStr.length
            return [attrStr]
        }

        /// 处理MyAITool，LKLabel不支持渲染MyAITool气泡，MyAITool气泡目前只能由LKRichView渲染
        let buildTool: AttributedStringOptionType = { option in
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
            let content = tool.property.myAiTool.status == .runing ? usingName : usedName
            let attrStr = NSMutableAttributedString(string: content, attributes: customAttributes)
            location += attrStr.length
            return [attrStr]
        }

        /// 处理 at
        let buildAttributeAt: AttributedStringOptionType = { option in
            let at = option.element
            var attributeStr = NSMutableAttributedString(string: "")

            let hasAtChar = at.property.at.content.hasPrefix("@")
            let atPropertyContent = hasAtChar ? at.property.at.content : "@\(at.property.at.content)"

            // @自己的
            if let checkIsMe = checkIsMe, checkIsMe(at.property.at.userID) {
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key(kCTForegroundColorAttributeName as String): atColor.MeForegroundColor.cgColor,
                    .font: customFont,
                    LKAtAttributeName: atColor.MeAttributeNameColor
                ]
                attributeStr = NSMutableAttributedString(string: "\(atPropertyContent)", attributes: attributes)
                // 非匿名用户才有点击事件和跳转
                if !at.property.at.isAnonymous {
                    var ranges = atRangeMap[at.property.at.userID] ?? []
                    ranges.append(NSRange(location: location, length: attributeStr.length))
                    atRangeMap[at.property.at.userID] = ranges
                }
                location += attributeStr.length
                return [attributeStr]
            }
            // @群外人
            if at.property.at.isOuter {
                attributeStr = NSMutableAttributedString(
                    string: atPropertyContent,
                    attributes: [
                        .foregroundColor: atColor.OuterForegroundColor,
                        .font: customFont
                    ]
                )
            } else if at.property.at.userID == "all" {
                // @all
                attributeStr = NSMutableAttributedString(
                    string: atPropertyContent,
                    attributes: [
                        .foregroundColor: atColor.AllForegroundColor,
                        .font: customFont
                    ]
                )
            } else {
                // @群内其他人
                attributeStr = NSMutableAttributedString(
                    string: atPropertyContent,
                    attributes: [
                        .foregroundColor: atColor.OtherForegroundColor,
                        .font: customFont
                    ]
                )
            }

            /// 已读未读点，默认设置为未读样式
            let isAtBot = botIds.contains(at.property.at.userID)
            if at.property.at.userID != "all", isShowReadStatus, isFromMe, attributeStr.length > 0, !isAtBot {
                if !at.property.at.isOuter {
                    attributeStr.addAttributes(
                        [LKPointAttributeName: atColor.UnReadRadiusColor,
                         LKPointRadiusAttributeName: 2.5.auto(),
                         LKPointInnerRadiusAttributeName: (2.5 - 0.8).auto()],
                        range: NSRange(location: attributeStr.length - 1, length: 1)
                    )
                }
            }

            var ranges = atRangeMap[at.property.at.userID] ?? []
            ranges.append(NSRange(location: location, length: attributeStr.length))
            atRangeMap[at.property.at.userID] = ranges

            location += attributeStr.length
            return [attributeStr]
        }

        /// 处理 #
        let buildAttributeMention: AttributedStringOptionType = { option in
            let mention = option.element.property.mention
            var attributeStr = NSMutableAttributedString(string: "")
            if let hashTagProvider = hashTagProvider {
                attributeStr = hashTagProvider(option, customFont)
                hashTagRangeMap[NSRange(location: location, length: attributeStr.length)] = mention
            } else {
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

                if isAvailable {
                    attributeStr = NSMutableAttributedString(
                        string: content,
                        attributes: [
                            .foregroundColor: UIColor.ud.B700,
                            .font: customFont
                        ]
                    )
                } else {
                    attributeStr = NSMutableAttributedString(
                        string: content,
                        attributes: [
                            .foregroundColor: UIColor.ud.N650,
                            .font: customFont
                        ]
                    )
                }
                if let entity = entity {
                    mentionsRangeMap[NSRange(location: location, length: attributeStr.length)] = entity
                }
            }
            location += attributeStr.length
            return [attributeStr]
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

        let buildAttributeUnOrderList: AttributedStringOptionType = { option in
            return option.results
        }

        let buildAttributeOrderList: AttributedStringOptionType = { option in
            return option.results
        }

        let buildAttributeQuote: AttributedStringOptionType = { option in
            return option.results
        }

        /// 对 RustPB.Basic_V1_RichText 各个切片进行不同处理
        let attrStrs = richText.lc.walker(
            options: [
                .text: buildAttributeText,
                .a: buildAttributeAnchor,
                .u: buildAttributeUnderline,
                .p: buildAttributeParagraph,
                // head标签在LKLabel场景渲染降级为p
                .h1: buildAttributeParagraph, .h2: buildAttributeParagraph, .h3: buildAttributeParagraph, .h4: buildAttributeParagraph, .h5: buildAttributeParagraph, .h6: buildAttributeParagraph,
                .figure: buildAttributeFigure,
                .emotion: buildAttributeEmotion,
                .img: buildAttributeImage,
                .at: buildAttributeAt,
                .link: buildAttributeLink,
                .media: buildAttributeMedia,
                .mention: buildAttributeMention,
                .docs: buildAttributeParagraph,
                .ul: buildAttributeUnOrderList,
                .ol: buildAttributeOrderList,
                .li: buildAttributeParagraph,
                .quote: buildAttributeQuote,
                .codeBlockV2: buildCode,
                .myAiTool: buildTool
            ],
            endCondition: endConditionHandler
        )

        // splicing the content, remove the blank at the end of the content
        // 拼接内容，删除末尾的换行和空白字符（PM要求）
        let attr = attrStrs.reduce(NSMutableAttributedString(string: ""), +).lf.trimmedAttributedString(
            set: CharacterSet.whitespacesAndNewlines,
            position: .trail
        )

        let result = ParseRichTextResult(
            attriubuteText: NSMutableAttributedString(attributedString: attr),
            urlRangeMap: urlRangeMap,
            atRangeMap: atRangeMap,
            textUrlRangeMap: textUrlRangeMap,
            abbreviationRangeMap: abbreviationRangeMap,
            mentionsRangeMap: mentionsRangeMap,
            hashTagMap: hashTagRangeMap
        )
        return result

    }

    /// needNewLine：是否需要在内容中添加换行符，有的场景不进行换行显示，比如：话题列表->某个话题回复区域
    static func parseRichText(richText: RustPB.Basic_V1_RichText,
                              isFromMe: Bool = false,
                              isShowReadStatus: Bool = true,
                              checkIsMe: ((_ userId: String) -> Bool)?,
                              botIds: [String] = [],
                              maxLines: Int = 0,
                              maxCharLine: Int = LarkRichTextCoreUtils.defaultMaxChatLine(),
                              atColor: AtColor = AtColor(),
                              needNewLine: Bool = true,
                              customAttributes: [NSAttributedString.Key: Any],
                              abbreviationInfo: [String: AbbreviationInfoWrapper]? = nil,
                              mentions: [String: Basic_V1_HashTagMentionEntity]? = nil,
                              imageAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.ImageProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              mediaAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.MediaProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              urlPreviewProvider: URLPreviewProvider? = nil
                            ) -> ParseRichTextResult {
        return parseRichText(richText: richText,
                             isFromMe: isFromMe,
                             isShowReadStatus: isShowReadStatus,
                             checkIsMe: checkIsMe,
                             botIds: botIds,
                             maxLines: maxLines,
                             maxCharLine: maxCharLine,
                             atColor: atColor,
                             needNewLine: needNewLine,
                             customAttributes: customAttributes,
                             abbreviationInfo: abbreviationInfo,
                             mentions: mentions,
                             imageAttachmentViewProvider: imageAttachmentViewProvider,
                             mediaAttachmentViewProvider: mediaAttachmentViewProvider,
                             urlPreviewProvider: urlPreviewProvider,
                             hashTagProvider: nil)
    }
}

// enable-lint: magic number
// swiftlint:enable all
