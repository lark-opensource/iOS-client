//
//  AtInfo.swift
//  SpaceKit
//
//  Created by Songwen Ding on 2018/3/12.
//  Copyright © 2018年 Bytedance. All rights reserved.
//  swiftlint:disable file_length

import UIKit
import RxRelay
import RxSwift
import SwiftyJSON
import ThreadSafeDataStructure
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit
import SpaceInterface
import LarkDocsIcon
import LarkContainer

extension AtType {
    /// 埋点
    public var strForMentionSubType: String {
        switch self {
        case .doc:
            return "doc"
        case .docx:
            return "docX"
        case .sheet:
            return "sheet"
        case .slides:
            return "slides"
        case .file:
            return "file"
        case .mindnote:
            return "mindnote"
        case .wiki:
            return "wiki"
        default:
            return ""
        }
    }
    /// 埋点
    public var strForMentionType: String {
        switch self {
        case .user:
            return "user"
        case .doc, .sheet, .docx, .bitable, .mindnote, .file, .slides, .wiki:
            return "link_file"
        case .chat:
            return "chat"
        default:
            spaceAssertionFailure("暂不支持")
            return ""
        }
    }

    public var makeDocsType: DocsType {
        switch self {
        case .doc: return .doc
        case .folder: return .folder
        case .sheet: return .sheet
        case .bitable: return .bitable
        case .mindnote: return .mindnote
        case .file: return .file
        case .slides: return .slides
        case .wiki: return .wiki
        case .docx: return .docX
        default:
            spaceAssertionFailure("Unsupported")
            return .unknownDefaultType
        }
    }

    public var prefixImage: UIImage? {
        var image: UIImage?
        switch self {
        case .doc, .wiki: // FIXME: 后期优化为按照 wiki 实际类型显示图标
            image = UDIcon.fileLinkWordOutlined
        case .docx:
            image = UDIcon.fileLinkDocxOutlined
        case .sheet:
            image = UDIcon.fileLinkSheetOutlined
        case .bitable:
            image = UDIcon.fileLinkBitableOutlined
        case .mindnote:
            image = UDIcon.fileLinkMindnoteOutlined
        case .file:
            image = UDIcon.fileLinkOtherfileOutlined
        case .slides:
            image = UDIcon.fileLinkSlidesOutlined
        case .sheetAttachment:
            image = UDIcon.attachmentOutlined
        case .whiteboard:
            image = UDIcon.vcWhiteboardOutlined
        default:
            DocsLogger.verbose("unsupport type")
        }
        return image
    }

    var isNeedPrefixImage: Bool {
        let needPrefixImage: [AtType] = [.doc, .docx, .sheet, .bitable, .mindnote, .file, .slides, .wiki, .sheetAttachment, .whiteboard]
        return needPrefixImage.contains(self)
    }
}

extension AtInfo {

    /// 渲染出来的@自己的富文本，用以提高性能。不要每次都渲染
    static var atSelfAttributedStrings: SafeDictionary<String, NSAttributedString> = SafeDictionary()

    public func hrefURL() -> URL? {
        guard type != .user else { return nil }
        if let url = URL(string: href) {
            return url.docs.addQuery(parameters: ["from": FromSource.atInfo.rawValue])
        } else {
            if type.makeDocsType.isSupportedType {
                return DocsUrlUtil.url(type: type.makeDocsType, token: token)
                    .docs.addQuery(parameters: ["from": FromSource.atInfo.rawValue])
            } else {
                DocsLogger.error("openDocs error type:\(type) is unsupported")
                return nil
            }
        }
    }

    public func updateUserId(_ userId: String) {
        self.userId = userId
    }
    
    var encodeString: String {
        if type == .user || type == .group {
            return "<at type=\"\(type.rawValue)\" href=\"\" token=\"\(token)\">@\(at)</at>"
        }
        //这里的iconStr主要之前文档旧的自定义图标功能加的，已经下线，后续进行删除
        var iconStr = ""
        if let iconInfo = self.iconInfo {
            iconStr = " icon='{\"type\":\(iconInfo.typeValue),\"key\":\"\(iconInfo.key)\",\"fs_unit\":\"\(iconInfo.fsunit)\"}'"
        }
        var iconInfoStr = ""
        if UserScopeNoChangeFG.HZK.customIconPart, let iconInfoMeta = self.iconInfoMeta {
            iconInfoStr = " icon_info=\"\(iconInfoMeta.urlEncoded())\""
        }
        if type == .wiki,
           let subType = subType {
            return "<at type=\"\(type.rawValue)\" sub_type=\"\(subType.rawValue)\" href=\"\(href)\" token=\"\(token)\"\(iconInfoStr)\(iconStr)>\(at)</at>"
        } else {
            return "<at type=\"\(type.rawValue)\" href=\"\(href)\" token=\"\(token)\"\(iconInfoStr)\(iconStr)>\(at)</at>"
        }
    }
    
   public static var mentionRegex: NSRegularExpression? = {
        let pattern = "<at(\n|.)*?>(\n|.)*?</at>"
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            return nil
        }
        return regex
    }()

    // 可被转化为 @人、doc、sheet 等链接的内容
    static public let attributedStringAtInfoKey = NSAttributedString.Key(rawValue: "at")
    static public let attributedStringAtInfoKeyStart = NSAttributedString.Key(rawValue: "atStart")
    // 不可被转化的外部链接，例如 www.baidu.com
    static public let attributedStringURLKey = NSAttributedString.Key(rawValue: "Doc-URL")
    static public let attributedStringPanoKey = NSAttributedString.Key(rawValue: "Pano")
    static public let attributedStringAttachmentKey = NSAttributedString.Key(rawValue: "Attach")
}

extension AtInfo {
    /// convert atinfo to attrbute str
    public func attributedString(attributes: [NSAttributedString.Key: Any], lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSAttributedString {
        // build attstr
        let attrString: NSMutableAttributedString
        var finalColor = UDColor.colorfulBlue & UIColor.ud.primaryContentDefault.alwaysDark
        if !hasPermission {
            finalColor = UIColor.ud.N600
        }
        let bound = CGRect(x: 0, y: -2, width: 14, height: 14)
        let prefix = NSTextAttachment()
        prefix.bounds = bound
        if let iconInfo = self.iconInfo, iconInfo.typeIsCurSupported {
            prefix.image = type.prefixImage?.ud.withTintColor(finalColor)
            iconInfo.image.bind { [weak self] (image) in
                prefix.image = image ?? self?.type.prefixImage
                if self?.hasPermission == false { prefix.image = prefix.image?.grayedOut() }
            }.disposed(by: disposeBag)
            attrString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: prefix))
        } else if type.isNeedPrefixImage {
            
            if UserScopeNoChangeFG.HZK.customIconPart,
               let iconInfoMeta = self.iconInfoMeta,
               !iconInfoMeta.isEmpty,
               let iconManager = Container.shared.getCurrentUserResolver().resolve(DocsIconManager.self) {
                
                //先显示默认图标，再异步刷新，要不会先显示一个空白的白色图标
                if UserScopeNoChangeFG.HYF.commentWikiIcon,
                   type == .wiki,
                   let subType = self.subType {
                    prefix.image = subType.prefixImage?.ud.withTintColor(finalColor)
                } else {
                    prefix.image = type.prefixImage?.ud.withTintColor(finalColor)
                }
                
                
                iconManager.getDocsIconImageAsync(iconInfo: iconInfoMeta,
                                                  url: self.href,
                                                  shape: .OUTLINE,
                                                  container: nil)
                .subscribe(onNext: { image in
                    var image = image
                    if image.renderingMode == .alwaysTemplate {
                        image = image.ud.withTintColor(finalColor)
                    }
                    prefix.image = image
                })
                .disposed(by: self.disposeBag)
                
            } else {
                if UserScopeNoChangeFG.HYF.commentWikiIcon,
                   type == .wiki,
                   let subType = self.subType {
                    prefix.image = subType.prefixImage?.ud.withTintColor(finalColor)
                } else {
                    prefix.image = type.prefixImage?.ud.withTintColor(finalColor)
                }
            }
            attrString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: prefix))
            attrString.append(NSMutableAttributedString(attributedString: NSAttributedString(string: " ", attributes: [.foregroundColor: finalColor])))
        } else if type == .unknown {
            attrString = NSMutableAttributedString()
        } else {
            attrString = NSMutableAttributedString(string: "@", attributes: [.foregroundColor: finalColor])
        }
        attrString.append(NSMutableAttributedString(string: at, attributes: [.foregroundColor: finalColor]))
        // 不使用外面设置的颜色
        var newAttributes = attributes
        newAttributes[.foregroundColor] = nil
        let range = NSRange(location: 0, length: attrString.length)
        if let style = newAttributes[.paragraphStyle] as? NSMutableParagraphStyle {
            style.lineBreakMode = lineBreakMode
            newAttributes[.paragraphStyle] = style
            attrString.addAttributes(newAttributes, range: range)
        } else {
            attrString.addAttributes(newAttributes, range: range)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            attrString.addAttributes([.paragraphStyle: paragraphStyle], range: range)
        }
        attrString.addAttribute(AtInfo.attributedStringAtInfoKey, value: self, range: range)
        attrString.addAttribute(AtInfo.attributedStringAtInfoKeyStart, value: "start", range: NSRange(location: 0, length: 1))
        return attrString
    }

    func getAtSelfAttributedToken(atString: String, font: UIFont) -> String {
        return "\(atString)_\(font.lineHeight)"
    }

    /// 当@自己时，返回富文本
    ///
    /// - Parameter attributes: 额外的attribute
    /// - Returns: 富文本，有圆角
    public func attributeStringForAtSelf(attributes: [NSAttributedString.Key: Any], useSelfCache: Bool, selfNameMaxWidth: CGFloat = 0, yOffset: CGFloat? = nil) -> NSAttributedString {
        guard isCurrentUser else {
            spaceAssertionFailure("不是自己的@信息")
            return NSAttributedString()
        }
        var imageLabelFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        if let font = attributes[NSAttributedString.Key.font] as? UIFont {
            imageLabelFont = font
        }
        //避免重复渲染
        var renderd: NSAttributedString?
        synchronized(self) {
            let token = getAtSelfAttributedToken(atString: at, font: imageLabelFont)
            renderd = AtInfo.atSelfAttributedStrings[token]
        }

        if useSelfCache, let renderd = renderd, AtInfo.prevSelfAtString == at {
            return renderd
        }

        let image: UIImage = {
            let imageCreator: () -> UIImage = {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 15, height: imageLabelFont.figmaHeight))
                label.lineBreakMode = .byClipping
                label.textAlignment = .center
                label.textColor = UDColor.primaryOnPrimaryFill
                label.layer.cornerRadius = imageLabelFont.figmaHeight / 2.0
                label.layer.masksToBounds = true
                let color = UDColor.colorfulBlue & UIColor.ud.primaryContentDefault.alwaysDark
                label.layer.ud.setBackgroundColor(color)
                label.backgroundColor = color
                let text = "@" + self.at
                label.text = text
                label.font = imageLabelFont
                label.sizeToFit()
                var labelWidth = label.bounds.size.width + 8
                if selfNameMaxWidth > 0, labelWidth > selfNameMaxWidth {
                    labelWidth = selfNameMaxWidth
                    label.text = " " + text
                    label.lineBreakMode = .byTruncatingTail
                }
                label.bounds = CGRect(x: 0, y: 0, width: labelWidth, height: imageLabelFont.figmaHeight)
                var renderSize = CGSize(width: label.bounds.size.width, height: label.bounds.size.height + 1) // 避免上下两行atinfo看起来粘在一起
                if renderSize.width == 0 { renderSize.width = 1 }
                if renderSize.height == 0 { renderSize.height = 1 }
                UIGraphicsBeginImageContextWithOptions(renderSize, false, SKDisplay.scale)
                label.layer.allowsEdgeAntialiasing = true
                UIGraphicsGetCurrentContext().flatMap { label.layer.render(in: $0) }                
                let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
                UIGraphicsEndImageContext()
                return image

            }
            var image: UIImage?
            if Thread.isMainThread {
                image = imageCreator()
            } else {
                DispatchQueue.main.sync {
                    image = imageCreator()
                }
            }
            return image ?? UIImage()
        }()

        let attachment = NSTextAttachment()
        attachment.additionalInfo = self
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: yOffset ?? -6, width: attachment.image?.size.width ?? 0, height: attachment.image?.size.height ?? 0)

        let attributeStr = NSMutableAttributedString(string: "@" + at, attributes: [.font: UIFont.systemFont(ofSize: 0) ])
        attributeStr.append(NSAttributedString(attachment: attachment))
        if useSelfCache {
            synchronized(self) {
                AtInfo.atSelfAttributedStrings.removeAll()
                let token = getAtSelfAttributedToken(atString: at, font: imageLabelFont)
                AtInfo.atSelfAttributedStrings[token] = attributeStr
                //更新缓存  at是自己当前的name，如果name修改以后需要更新更新缓存
                AtInfo.prevSelfAtString = at
                DocsLogger.info("AtInfo at 更新self name: \(at)")
            }
        }
        return attributeStr
    }

    /// convert attributed string to encode string
    public static func encodedString(attributedString: NSAttributedString) -> String {
        var string = ""
        var shouldAppendAt = false

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { (attributes, range, _) in
            let str: String
            if attributes[AtInfo.attributedStringAtInfoKeyStart] != nil {
                shouldAppendAt = true
            }
            if let at = attributes[AtInfo.attributedStringAtInfoKey] as? AtInfo {
                if shouldAppendAt {
                    let atStr = at.encodeString
                    string.append(atStr)
                    shouldAppendAt = false
                }
            } else {
                str = attributedString.attributedSubstring(from: range).string
                string.append(str)
            }
        }
        // 参考case https://bytedance.feishu.cn/docs/doccnsg495JbCR4o8SMe835dVuC
        string = string.replacingOccurrences(of: "\u{fffc}", with: "")
        return string
    }
}

extension AtInfo {

    public var isCurrentUser: Bool {
        let currentUserId = userId ?? User.current.info?.userID
        return type == .user && token == currentUserId
    }

    public enum AtInfoOrString {
        case atInfo(AtInfo)
        case string(String)
    }

    // 根据text和匹配规则，解析字符串，返回Atinfo或string的数组
    ///
    /// - Parameters:
    ///   - text: 要解析的字符串
    ///   - pattern: AtInfo的匹配规则
    /// - Returns: 一个数组，每一个元素，或者是atinfo，或者是字符串
    public static func baseParseMessageContent(in text: String, pattern: NSRegularExpression) -> [AtInfoOrString] {
        let value = try? parseMessageContent(in: text, pattern: pattern, makeInfo: AtInfo.makeInfoForMessageContent)
        return value ?? []
    }

   public typealias AtinfoParseFunction = (NSTextCheckingResult, NSString) throws -> AtInfo?
    
   public static func parseMessageContent(in text: String, pattern: NSRegularExpression, makeInfo: AtinfoParseFunction) throws -> [AtInfoOrString] {
        let input: NSString = text as NSString
        var output: [AtInfoOrString] = []
        var currentPosition = 0
        try
        pattern.matches(in: text, range: NSRange(location: 0, length: input.length)).forEach { result in
            let range = result.range
            if range.location != currentPosition {
                let unMatchedRange = NSRange(location: currentPosition, length: range.location - currentPosition)
                let unmatchedString = String(input.substring(with: unMatchedRange))
                output.append(AtInfoOrString.string(unmatchedString))
            }
            currentPosition = range.location + range.length
            let matchStr = input.substring(with: range) as NSString
            do {
                let atInfo: AtInfo? = try makeInfo(result, input)
                if let atInfo = atInfo {
                    output.append(.atInfo(atInfo))
                } else {
                    output.append(.string(matchStr as String))
                }
            } catch {
                throw error
            }
        }
        //处理尾部未匹配字符串
        if currentPosition < input.length {
            let unMatchedRange = NSRange(location: currentPosition, length: input.length - currentPosition)
            let unmatchedStr = input.substring(with: unMatchedRange) as String
            output.append(.string(unmatchedStr))
        }
        return output
    }

    // 实际并不会throw, 是为了兼容xml解析方法失败后的降级
    static func makeInfoForMessageContent(result: NSTextCheckingResult, input: NSString) throws -> AtInfo? {
        //解析atinfo
        let numberOfRanges = result.numberOfRanges
        guard numberOfRanges > 6 else { return nil }
        var currentRange = result.range(at: 1)
        guard currentRange.location != NSNotFound else {
            return nil
        }
        let atTypeInt = Int(String(input.substring(with: currentRange))) ?? 999
        let atType = AtType(rawValue: atTypeInt) ?? .unknown
        currentRange = result.range(at: 2)
        guard currentRange.location != NSNotFound else { return nil }
        let href = String(input.substring(with: currentRange))

        currentRange = result.range(at: 3)
        guard currentRange.location != NSNotFound else { return nil }
        let token = String(input.substring(with: currentRange))

        currentRange = result.range(at: 5)
        let icon: RecommendData.IconInfo? = {
            if currentRange.location != NSNotFound {
                let iconInfoString = String(input.substring(with: currentRange))
                return AtInfo.makeIconInfo(with: iconInfoString)
            } else {
                return nil
            }
        }()

        currentRange = result.range(at: 6)
        guard currentRange.location != NSNotFound else { return nil }
        var at = String(input.substring(with: currentRange))
        if atType == .user {
            at = String(at.dropFirst())
        }
        let atInfo = AtInfo(type: atType, href: href, token: token, at: at)
        atInfo.iconInfo = icon
        return atInfo
    }
}


// MARK: - statistics
extension AtInfo {

    var recommendGroup: String {
        if keyword?.isEmpty == false {
            return "search_recommend"
        } else {
            return "default_recomment"
        }
    }

}

extension DocsType {
    
    // mention文档的int定义和文档接口类型int定义不一样！，需要手动转换
   public var toAtType: AtType {
        switch self {
        case .folder:
            return .folder
        case .doc:
            return .doc
        case .sheet:
            return .sheet
        case .bitable:
            return .bitable
        case .wiki:
            return .wiki
        case .docX:
            return .docx
        case .mindnote:
            return .mindnote
        case .file:
            return .file
        case .slides:
            return .slides
        default:
            return .unknown
        }
    }
}
