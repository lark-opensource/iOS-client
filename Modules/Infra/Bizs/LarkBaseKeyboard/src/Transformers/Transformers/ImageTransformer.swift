//
//  ImageTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import EditTextView
import ByteWebImage
import RustPB
import LKCommonsLogging

public enum ImageTransformType: String {
    case normal // 普通大图
    case remote //远端图片
    case doc // doc类型的本地icon
    case inlineIcon // URL inline前的imageKey，不染色
    case inlineTintIcon // URL inline前的imageKey，需要染色
    case inlineUDIcon // URL inline前的UDIcon
    case inlineUnicode // URL inline前的Unicode
    case empty // 占位empty image

    public func isURLInline() -> Bool {
        return self == .inlineIcon || self == .inlineTintIcon || self == .inlineUDIcon || self == .inlineUnicode
    }
}

public final class ImageTransformInfo: NSObject {
    public var key: String
    public var localKey: String
    public var imageSize: CGSize
    public var type: ImageTransformType
    public var useOrigin: Bool
    public var fromCopy: Bool
    public var thumbKey: String?
    // 区别imageSize，imageSize记录的是original的尺寸，resizedImageSize记录是拖拽后的尺寸。目前只透传给PC，没有用于渲染
    public var resizedImageSize: CGSize?
    public var token: String?
    // 消息链接化场景富文本复制粘贴发送时，图片需要使用previewID做鉴权
    public var authToken: String?

    public init(key: String,
                localKey: String,
                imageSize: CGSize,
                type: ImageTransformType,
                useOrigin: Bool,
                fromCopy: Bool = false,
                thumbKey: String? = nil,
                resizedImageSize: CGSize? = nil,
                token: String? = nil,
                authToken: String? = nil) {
        self.key = key
        self.localKey = localKey
        self.imageSize = imageSize
        self.type = type
        self.useOrigin = useOrigin
        self.fromCopy = fromCopy
        self.thumbKey = thumbKey
        self.resizedImageSize = resizedImageSize
        self.token = token
        self.authToken = authToken
        super.init()
    }

    public init(key: String, localKey: String, imageSize: CGSize, type: ImageTransformType) {
        self.key = key
        self.localKey = localKey
        self.imageSize = imageSize
        self.type = type
        self.useOrigin = false
        self.fromCopy = false
        self.thumbKey = nil
        super.init()
    }
}

public final class ImageTransformer: RichTextTransformProtocol {
    public static var logger = Logger.log(ImageTransformer.self, category: "ImageTransformer")
    //本地上传的图片
    public static let ImageAttachmentAttributedKey = NSAttributedString.Key(rawValue: "imageAttachment")

    //远端的图片（如二次编辑场景从message里拿到的图片）
    public static let RemoteImageAttachmentAttributedKey = NSAttributedString.Key(rawValue: "remoteImageAttachment")

    public static let minAttachmentHeight: CGFloat = 30

    //本地的icon，如doc的icon
    public static let LocalIconAttachmentAttributedKey = NSAttributedString.Key(rawValue: "localIconAttachment")

    //远端拿到的icon，如url的icon
    public static let RemoteIconAttachmentAttributedKey = NSAttributedString.Key(rawValue: "remoteIconAttachment")

    public static let LocalEmptyImageKey = "local.empty.image.key"

    public static var LocalEmptyImage: NSAttributedString {
        let attachment = CustomTextAttachment(customView: EmptyPreviewableView(), bounds: .init(origin: .zero, size: .init(width: 1, height: 1)))
        let attachmentStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        let imageInfo = ImageTransformInfo(
            key: "",
            localKey: ImageTransformer.LocalEmptyImageKey,
            imageSize: .zero,
            type: .empty,
            useOrigin: false)
        attachmentStr.addAttribute(ImageTransformer.LocalIconAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        return attachmentStr
    }

    public init() {}

    public typealias InsertContent = (key: String, token: String?, localKey: String, thumbKey: String?, imageSize: CGSize, type: ImageTransformType, image: UIImage, editorWidth: CGFloat, useOrigin: Bool, fromCopy: Bool, resizedSize: CGSize?, authToken: String?)
    public static func transformContentToString(_ content: InsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        if content.type == .remote {
            return ImageTransformer.transformRemoteImageToImageAttr(content, attributes: attributes)
        } else if content.type.isURLInline() {
            return ImageTransformer.transformURLInlineIconToImageAttr(content, attributes: attributes)
        } else if ImageTransformer.imageKeyIsLocalIcon(key: content.localKey) {
            return ImageTransformer.transformLocalIconToString(content, attributes: attributes)
        } else {
            return ImageTransformer.transformImageToString(content, attributes: attributes)
        }
    }

    static func transformImageToString(_ content: InsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let imageInfo = ImageTransformInfo(
            key: content.key,
            localKey: content.localKey,
            imageSize: content.imageSize,
            type: content.type,
            useOrigin: content.useOrigin,
            fromCopy: content.fromCopy,
            resizedImageSize: content.resizedSize,
            authToken: content.authToken)
        let imageView = AttachmentImageView(key: imageInfo.localKey, state: .success)
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        let showImageSize = ImageTransformer.imageSize(image: content.image, inset: .zero, originSize: content.imageSize, editerWidth: content.editorWidth)
        imageView.image = ImageTransformer.attachmentImage(image: content.image, size: showImageSize)
        let bounds = CGRect(x: 0, y: 0, width: showImageSize.width, height: showImageSize.height)
        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)
        let attachmentStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        attachmentStr.addAttribute(ImageTransformer.ImageAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        attachmentStr.addAttributes(attributes, range: NSRange(location: 0, length: 1))

        return attachmentStr
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let element = option.element
            if downgrade {
                return Self.downgradeImageContentFor(pb: element.property, attributes: attributes)
            }
            let originKey = element.property.image.originKey
            let imageSize = CGSize(width: CGFloat(element.property.image.originWidth), height: CGFloat(element.property.image.originHeight))
            let type = element.property.image.urls.compactMap({ ImageTransformType(rawValue: $0) }).first ?? .remote

            var imageKey: String = originKey
            var localKey: String = originKey

            attachmentResult.forEach({ (key, value) in
                if value == originKey {
                    localKey = key
                    imageKey = originKey
                } else if key == originKey {
                    imageKey = value
                }
            })
            let image = ImageTransformer.imageByLocalKey(key: localKey) ?? UIImage()
            var thumbKey: String?
            var token: String?
            /// 除了复制的图片，其他场景的都可以在本地找到原图，所以所以复制场景传入thumbKey，降低资源的消耗
            if element.property.image.needCopy {
                thumbKey = element.property.image.thumbKey
                token = element.property.image.token
            }
            let resizedSize = CGSize(width: Int(element.property.image.width), height: Int(element.property.image.height))
            return [ImageTransformer.transformContentToString((imageKey, token, localKey, thumbKey, imageSize, type, image, UIScreen.main.bounds.width, element.property.image.isOriginSource, element.property.image.needCopy, resizedSize, element.property.image.resourcePreviewToken), attributes: attributes)]
        }

        return [(.img, process)]
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        return transformImageToRichText(text) + transformRemoteImageToRichText(text) + transformLocalIconToRichText(text) + transformRemoteIconToRichText(text)
    }

    // nolint: duplicated_code
    func transformImageToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let figurePriority: RichTextAttrPriority = .high
        let imagePriority: RichTextAttrPriority = .content

        text.enumerateAttribute(ImageTransformer.ImageAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: [.longestEffectiveRangeNotRequired]) { (value, range, _) in
            if let info = value as? ImageTransformInfo {
                let imageId = InputUtil.randomId()
                var imageProperty = RustPB.Basic_V1_RichTextElement.ImageProperty()
                let originKey = info.key.isEmpty ? info.localKey : info.key
                imageProperty.token = originKey
                imageProperty.thumbKey = info.thumbKey ?? originKey
                imageProperty.middleKey = info.thumbKey ?? originKey
                imageProperty.originKey = originKey
                imageProperty.originWidth = Int32(info.imageSize.width)
                imageProperty.originHeight = Int32(info.imageSize.height)
                imageProperty.urls = [info.type.rawValue]
                imageProperty.isOriginSource = info.useOrigin
                imageProperty.needCopy = info.fromCopy
                imageProperty.width = UInt32(info.resizedImageSize?.width ?? 0)
                imageProperty.height = UInt32(info.resizedImageSize?.height ?? 0)
                if let authToken = info.authToken {
                    imageProperty.resourcePreviewToken = authToken
                }
                let imageTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.img, imageId, .img(imageProperty), nil)
                let imageAttr = RichTextAttr(priority: imagePriority, tuple: imageTuple)

                let fId = InputUtil.randomId()
                let figureProperty = RustPB.Basic_V1_RichTextElement.FigureProperty()
                let figureTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.figure, fId, .figure(figureProperty), nil)
                let figureAttr = RichTextAttr(priority: figurePriority, tuple: figureTuple)
                let attributes = text.attributes(at: range.location, effectiveRange: nil)
                if attributes[NSAttributedString.Key.attachment] != nil {
                    result.append(RichTextFragmentAttr(range, [figureAttr, imageAttr]))
                }
            }
        }
        return result
    }
    // enable-lint: duplicated_code

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            return Self.downgradeImageContentFor(pb: option.element.property, attributes: [:])
        }
        return [(.img, process)]
    }

    public func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        var transform: Bool = false
        let mutable = NSMutableAttributedString(attributedString: text)
        // 处理LocalIconAttachmentAttributedKey
        text.enumerateAttribute(ImageTransformer.LocalIconAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, stop) in
            if value is ImageTransformInfo {
                transform = true
                stop.pointee = true
                mutable.replaceCharacters(in: range, with: "")
            }
        }
        // 处理RemoteIconAttachmentAttributedKey
        text.enumerateAttribute(ImageTransformer.RemoteIconAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, stop) in
            if value is ImageTransformInfo {
                transform = true
                stop.pointee = true
                mutable.replaceCharacters(in: range, with: "")
            }
        }
        if transform {
            return self.preproccessSendAttributedStr(mutable)
        } else {
            return text
        }
    }

    static func downgradeImageContentFor(pb: Basic_V1_RichTextElement.PropertySet,
                                         attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString] {
        let originKey = pb.image.originKey
        let type = pb.image.urls.compactMap({ ImageTransformType(rawValue: $0) }).first ?? .normal
        if ImageTransformer.imageKeyIsLocalIcon(key: originKey) {
            return []
        } else if type.isURLInline() { // URL inline icon处理成和docIcon一样的逻辑
            return []
        }
        return [NSAttributedString(string: "\(BundleI18n.LarkBaseKeyboard.Lark_Legacy_MsgFormatImage)", attributes: attributes)]
    }
}

extension ImageTransformer {

    // nolint: duplicated_code
    public static func insert(image: UIImage, key: String, imageSize: CGSize, textView: UITextView, useOrigin: Bool) {

        var attributes: [NSAttributedString.Key: Any] = [:]
        for (key, value) in textView.typingAttributes {
            if !FontStyleConfig.fontStyleKeys.contains(key) {
                attributes[key] = value
            }
        }
        let font: UIFont = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 15)

        let imageStr = ImageTransformer.transformContentToString(("", nil, key, nil, imageSize, .normal, image, textView.bounds.width, useOrigin, false, nil, nil), attributes: attributes)

        let range = textView.selectedRange
        let offset = textView.contentOffset
        let text: NSString = (textView.text ?? "") as NSString
        var insertReturnInFront = false
        if range.location > 0 {
            insertReturnInFront = text.substring(with: NSRange(location: range.location - 1, length: 1)) == "\n"
        } else {
            // 最前面不需要插入回车
            insertReturnInFront = true
        }
        var insertReturnInEnd = false
        if (range.location + range.length) < text.length {
            insertReturnInEnd = text.substring(with: NSRange(location: range.location + range.length, length: 1)) == "\n"
        }
        // 生成要插入的文本（前后加回车）
        let insertText = NSMutableAttributedString(string: insertReturnInFront ? "" : "\n")
        insertText.append(imageStr)
        insertText.append(NSAttributedString(string: insertReturnInEnd ? "" : "\n"))
        insertText.addAttribute(.font, value: font, range: NSRange(location: 0, length: insertText.length))

        // 插入文本
        let attributeString = textView.attributedText.mutableCopy() as? NSMutableAttributedString ?? NSMutableAttributedString(string: "")
        attributeString.insert(insertText, at: range.location)
        textView.attributedText = attributeString
        textView.selectedRange = NSRange(location: insertText.string.count + range.location, length: 0)
        textView.setContentOffset(offset, animated: false)
    }
    // enable-lint: duplicated_code

    public static func attachmentImage(image: UIImage, size: CGSize) -> UIImage {
        if image.size.width > size.width && (image as? ByteImage)?.animatedImageData == nil {
            /// 重绘图片保持原始图片比例, 并且保证高度最小为 minAttachmentHeight
            let minDrawHeight: CGFloat = minAttachmentHeight
            let drawHeight: CGFloat = max(minDrawHeight, size.width * image.size.height / image.size.width)
            let drawWidth: CGFloat = drawHeight * image.size.width / image.size.height
            let drawSize: CGSize = CGSize(width: drawWidth, height: drawHeight)
            UIGraphicsBeginImageContextWithOptions(drawSize, false, UIScreen.main.scale)
            image.draw(in: CGRect(x: 0, y: 0, width: drawWidth, height: drawHeight))
            let newImg = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
            return newImg
        } else {
            return image
        }
    }

    public static func fetchAllImageKey(attributedText: NSAttributedString) -> [String] {
        var imageKeys: [String] = []
        attributedText.enumerateAttribute(ImageTransformer.ImageAttachmentAttributedKey, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, _, _) in
            if let info = value as? ImageTransformInfo {
                imageKeys.append(info.localKey)
            }
        }
        return imageKeys
    }

    public static func fetchAllRemoteImageKey(attributedText: NSAttributedString) -> [String] {
        var imageKeys: [String] = []
        attributedText.enumerateAttribute(ImageTransformer.RemoteImageAttachmentAttributedKey, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, _, _) in
            if let info = value as? ImageTransformInfo {
                imageKeys.append(info.key)
            }
        }
        return imageKeys
    }

    public static func fetchAllImageAttachemnt(attributedText: NSAttributedString) -> [(String, CustomTextAttachment, ImageTransformInfo, NSRange)] {
        var imageAttachments: [(String, CustomTextAttachment, ImageTransformInfo, NSRange)] = []
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { (attributes, range, _) in
            if let attachment = attributes[.attachment] as? CustomTextAttachment,
                let imageInfo = attributes[ImageTransformer.ImageAttachmentAttributedKey] as? ImageTransformInfo {
                imageAttachments.append((imageInfo.localKey, attachment, imageInfo, range))
            }
        }
        return imageAttachments
    }

    public static func fetchAllRemoteImageAttachemnt(attributedText: NSAttributedString) -> [(String, CustomTextAttachment, ImageTransformInfo, NSRange)] {
        var imageAttachments: [(String, CustomTextAttachment, ImageTransformInfo, NSRange)] = []
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { (attributes, range, _) in
            if let attachment = attributes[.attachment] as? CustomTextAttachment,
                let imageInfo = attributes[ImageTransformer.RemoteImageAttachmentAttributedKey] as? ImageTransformInfo {
                imageAttachments.append((imageInfo.localKey, attachment, imageInfo, range))
            }
        }
        return imageAttachments
    }

    public static func fetchImageAttachemntMapInfo(attributedText: NSAttributedString) -> [String: (CustomTextAttachment, ImageTransformInfo, NSRange)] {
        var imageAttachments: [String: (CustomTextAttachment, ImageTransformInfo, NSRange)] = [:]
        self.fetchAllImageAttachemnt(attributedText: attributedText).forEach { value in
            imageAttachments[value.0] = (value.1, value.2, value.3)
        }
        return imageAttachments
    }

    public static func imageSize(
        image: UIImage?,
        inset: UIEdgeInsets,
        originSize: CGSize,
        editerWidth: CGFloat) -> CGSize {
        var imageSize = image?.size ?? originSize
            var imageHeight = imageSize.height
            var imageWidth = imageSize.width
        let maxWidth = (editerWidth - (inset.left + inset.right) * 2) / UIScreen.main.scale
        if imageSize.width >= maxWidth {
            imageSize.width = maxWidth
            imageSize.height = imageHeight * (maxWidth / imageWidth)
        }
        if imageSize.height > 10_000 {
            imageSize.height = 10_000
        }

        let minHeight: CGFloat = minAttachmentHeight
        if imageSize.height < minHeight &&
            imageSize.width == maxWidth {
            imageSize.height = minHeight
        }

        if imageSize.width > originSize.width ||
            imageSize.height > originSize.height {
            imageSize = originSize
        }
        return imageSize
    }
}

fileprivate final class EmptyPreviewableView: UIView, AttachmentPreviewableView {}
