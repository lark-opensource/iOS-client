//
//  SearchAttributeString.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/20.
//

import Foundation
import UIKit
import RustPB
import RichLabel
import UniverseDesignIcon
import LarkRichTextCore
#if canImport(LarkSetting)
import LarkSetting
#endif

// Use the clear placeholder image first, and refresh the image after downloaded.
// Only isWebImage == true && !image.isEmpty should refresh
public final class SearchTextAttachment: NSTextAttachment {
    public var isWebImage: Bool = false
    public var imageKey: String = ""
    public var originImage: UIImage?
}

/// Search Attribute String from Search API
public class SearchAttributeString {
    let content: XML.Document
    public var text: String { content.root.innerText }
    let buffer = NSMutableAttributedString()
    var modifierStack = [Attribute]()

    static let colorMapping: [String: UIColor] = [
        "grey": UIColor.ud.textPlaceholder
    ]

    private var enableSupportURLIconInline: Bool =  false
    public init(searchHighlightedString: String, enableSupportURLIconInline: Bool =  false) {
#if canImport(LarkSetting)
        self.enableSupportURLIconInline = FeatureGatingManager.shared.featureGatingValue(with: "lark.search.url_icon.support_more_types") //Global UI相关，改动成本有些高，先不改
#else
        self.enableSupportURLIconInline = enableSupportURLIconInline
#endif
        guard let data = "<r>\(searchHighlightedString)</r>".data(using: .utf8) else {
            content = XML.Document(root: XML.Element(name: "r"))
            assertionFailure("invalid searchHighlightedString: \(searchHighlightedString)")
            ListItemLogger.shared.error(module: ListItemLogger.Module.convert, event: "invalid searchHighlightedString: \(searchHighlightedString)")
            return
        }
        do {
            content = try XML.Document(data: data)
        } catch {
            content = XML.Document(root: XML.Element(name: "r"))
            ListItemLogger.shared.error(module: ListItemLogger.Module.convert, event: "pass xml with error: \(error)")
        }
    }

    // NOTE: 如果嵌套，外面的（后设置）tag属性会覆盖里面的。应该里面的优先
    // 下面是深度优先递归，所以里面的先进栈，保证其后生效
    func append(element: XML.Element) {
        for i in element.items {
            switch i {
            case .text(let v): buffer.append(NSAttributedString(string: v))
            case .element(let v):
                switch v.name {
                case "h":
                    let start = buffer.length
                    defer {
                        let end = buffer.length
                        if end > start {
                            modifierStack.append(.init(
                                name: .foregroundColor,
                                value: UIColor.ud.primaryContentDefault,
                                range: NSRange(location: start, length: end - start)))
                        }
                    }
                    append(element: v)
                case "b":
                    let start = buffer.length
                    defer {
                        let end = buffer.length
                        if end > start {
                            modifierStack.append(.init(
                                name: .foregroundColor,
                                value: UIColor.ud.textCaption,
                                range: NSRange(location: start, length: end - start)))
                            modifierStack.append(.init(
                                name: .font,
                                value: UIFont.ud.body1,
                                range: NSRange(location: start, length: end - start)))
                        }
                    }
                    append(element: v)
                case "hb":
                    let start = buffer.length
                    defer {
                        let end = buffer.length
                        if end > start {
                            modifierStack.append(.init(
                                name: .foregroundColor,
                                value: UIColor.ud.primaryContentDefault,
                                range: NSRange(location: start, length: end - start)))
                            modifierStack.append(.init(
                                name: .font,
                                value: UIFont.ud.body1,
                                range: NSRange(location: start, length: end - start)))
                        }
                    }
                    append(element: v)
                case "di":
                    var iconColor = UIColor.ud.textPlaceholder
                    if let colorString = v.attributes["color"], let color = Self.colorMapping[colorString] {
                        iconColor = color
                    }
                    if let typeString = v.attributes["type"], let type = Int(typeString), let docType = Basic_V1_Doc.TypeEnum(rawValue: type) {
                        let image = LarkRichTextCoreUtils.docUrlIcon(docType: docType, size: CGSize(width: 14, height: 14)).ud.colorize(color: iconColor)
                        buffer.addImageAttachment(image: image, font: UIFont.systemFont(ofSize: 16))
                        buffer.append(NSAttributedString(string: " ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]))
                    }
                    append(element: v)
                case "style":
                    let start = buffer.length
                    defer {
                        let end = buffer.length
                        if let colorString = v.attributes["color"], let color = Self.colorMapping[colorString] {
                            if end > start {
                                modifierStack.append(.init(
                                    name: .foregroundColor,
                                    value: color,
                                    range: NSRange(location: start, length: end - start)))
                            }
                        }
                    }
                    append(element: v)
                case "pi":
                    if self.enableSupportURLIconInline {
                        var image: UIImage?
                        //默认font是14，颜色是UIcolor.ud.textPlaceholder, 提供对外的方法统一改大小，改字体颜色
                        let defaultFont = UIFont.systemFont(ofSize: 14)
                        let defaultColor = UIColor.ud.textPlaceholder
                        var isWebImage = false
                        var webImageKey = ""
                        if let ud = v.attributes["ud"], !ud.isEmpty {
                            image = UDIcon.getIconByString(ud, iconColor: defaultColor)
                        } else if let icon = v.attributes["icon"], !icon.isEmpty {
                            //icon is webImage
                            image = UIImage() //没有内容的UIImage为网图占位
                            isWebImage = true
                            webImageKey = icon
                        }
                        if image == nil {
                            image = UDIcon.getIconByKey(.globalLinkOutlined).ud.withTintColor(defaultColor)
                            isWebImage = false
                        }
                        if let _image = image {
                            buffer.addSearchImageAttachment(image: _image, font: defaultFont, imageKey: webImageKey, isWebImage: isWebImage)
                        }
                    }
                    append(element: v)
                default:
                    append(element: v)
                }
            }
        }
    }

    /// attribute text for show in search result
    public var attributeText: NSAttributedString {
        append(element: content.root)
        while let attr = modifierStack.popLast() {
            buffer.addAttribute(attr.name, value: attr.value, range: attr.range)
        }
        return buffer.copy() as! NSAttributedString // swiftlint:disable:this all
    }

    public var mutableAttributeText: NSMutableAttributedString {
        append(element: content.root)
        while let attr = modifierStack.popLast() {
            buffer.addAttribute(attr.name, value: attr.value, range: attr.range)
        }
        return buffer
    }

    struct Attribute {
        var name: NSAttributedString.Key
        var value: Any
        var range: NSRange
    }

    public var hitTerms: [String] {
        var buffer = [String]()
        func append(element: XML.Element) {
            for i in element.items {
                switch i {
                case .element(let v):
                    if v.name == "h" {
                        buffer.append(v.innerText)
                    } else {
                        append(element: v)
                    }
                default: break
                }
            }
        }
        append(element: content.root)
        return buffer
    }
}

extension NSMutableAttributedString {
    public func addImageAttachment(image: UIImage, font: UIFont) {
        let attachment = NSTextAttachment()
        attachment.image = image
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachment.bounds = CGRect(x: 0, y: CGFloat(roundf(Float(font.capHeight - image.size.height))) / 2.0, width: image.size.width, height: image.size.height)
        self.append(attachmentString)
    }

    public func addSearchImageAttachment(image: UIImage, font: UIFont, imageKey: String, isWebImage: Bool) {
        var attachment = SearchTextAttachment()
        if isWebImage && !imageKey.isEmpty {
            attachment.isWebImage = true
            attachment.imageKey = imageKey
        }
        attachment.originImage = image
        reSizeImageAttachment(font: font, padding: 2, imageAttachment: &attachment)
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        self.append(attachmentString)
    }

    public func updateSearchImage(font: UIFont, tintColor: UIColor) -> NSMutableAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        self.enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.length)) { attachment, range, _ in
            if let _attachment = attachment as? SearchTextAttachment, var _image = _attachment.originImage {
                var imageAttachment = SearchTextAttachment()
                if !_attachment.isWebImage {
                    _image = _image.ud.withTintColor(tintColor)
                }
                imageAttachment.isWebImage = _attachment.isWebImage
                imageAttachment.imageKey = _attachment.imageKey
                imageAttachment.originImage = _image
                reSizeImageAttachment(font: font, padding: 2, imageAttachment: &imageAttachment)
                result.replaceCharacters(in: range, with: NSMutableAttributedString(attachment: imageAttachment))
            }
        }
        return result
    }

    public var searchWebImageKeysInAttachment: [String] {
        var result: [String] = []
        self.enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.length)) { attachment, _, _ in
            if let _attachment = attachment as? SearchTextAttachment,
                _attachment.isWebImage,
               !_attachment.imageKey.isEmpty, !result.contains(_attachment.imageKey) {
                result.append(_attachment.imageKey)
            }
        }
        return result
    }

    public func updateSearchWebImageView(withImageResource: [(String, UIImage?)], font: UIFont, tintColor: UIColor = UIColor.ud.textPlaceholder) -> NSMutableAttributedString {
        func getImage(with imageKey: String) -> UIImage {
            for (key, value) in withImageResource {
                if imageKey.elementsEqual(key), let _vaule = value {
                    return _vaule.ud.withTintColor(tintColor)
                }
            }
            return UDIcon.getIconByKey(.globalLinkOutlined, size: CGSize(width: font.pointSize, height: font.pointSize)).ud.withTintColor(tintColor)
        }

        let result = NSMutableAttributedString(attributedString: self)
        self.enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.length)) { attachment, range, _ in
            if let _attachment = attachment as? SearchTextAttachment,
                _attachment.isWebImage,
               !_attachment.imageKey.isEmpty {
                let image = getImage(with: _attachment.imageKey)
                var imageAttachment = SearchTextAttachment()
                imageAttachment.originImage = image
                reSizeImageAttachment(font: font, padding: 2, imageAttachment: &imageAttachment)
                result.replaceCharacters(in: range, with: NSMutableAttributedString(attachment: imageAttachment))
            }
        }
        return result
    }

    //由于某些场景富文本会根据字体，网图对富文本刷新，防止图片多次加padding，需使用originImage计算图片尺寸
    private func reSizeImageAttachment(font: UIFont, padding: CGFloat, imageAttachment: inout SearchTextAttachment) {
        var imageRatio: CGFloat = 1
        var originImage: UIImage
        if let _originImage = imageAttachment.originImage {
            originImage = _originImage
            if originImage.size.width > 0 && originImage.size.height > 0 {
                imageRatio = originImage.size.width / originImage.size.height
            }
        } else {
            //实际不会走到这里，防crash，防异常
            originImage = UIImage()
            imageAttachment.originImage = originImage
        }
        let height = font.pointSize
        let width = font.pointSize * imageRatio
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width + padding * 2, height: height), false, UIScreen.main.scale)
        originImage.draw(in: CGRect(x: padding, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - height) / 2.0, width: width + padding * 2, height: height)
        imageAttachment.image = newImage
    }
}
