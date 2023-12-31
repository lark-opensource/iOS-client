//
//  ImageTransformer+Local.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/4/3.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import EditTextView
import RustPB
import ByteWebImage
import LarkRichTextCore

extension ImageTransformer {
    public static func docTypeIconKey(_ docType: RustPB.Basic_V1_Doc.TypeEnum, fileName: String, customKey: String) -> String {
        return Resources.docIconOriginKey(type: docType, filename: fileName, customKey: customKey)
    }

    public static func docTypeFrom(_ key: String) -> (RustPB.Basic_V1_Doc.TypeEnum, String)? {

        if let docInfo = Resources.parseDocInfoBy(originKey: key) {
            return docInfo
        }

        if !key.hasPrefix("doc/type/") {
            return nil
        }
        let valueStr = key.replacingOccurrences(of: "doc/type/", with: "")
        let components = valueStr.components(separatedBy: "/")
        guard let value = Int(components.first ?? ""),
            let type = RustPB.Basic_V1_Doc.TypeEnum(rawValue: value),
            let fileName = components.last?.removingPercentEncoding else {
                return nil
        }
        return (type, fileName)
    }

    public static func imageKeyIsLocalIcon(key: String) -> Bool {
        if docTypeFrom(key) != nil { return true }
        if key == ImageTransformer.LocalEmptyImageKey { return true }
        return false
    }

    public static func imageByLocalKey(key: String) -> UIImage? {
        if let docInfo = docTypeFrom(key) {
            return LarkRichTextCoreUtils.docUrlIcon(docType: docInfo.0)
        }
        return nil
    }

    public static func localImageSizeByKey(key: String) -> CGSize {
        if docTypeFrom(key) != nil {
            return CGSize(width: 25, height: 17)
        }
        return .zero
    }

    public static func transformDocTypeToString(
        _ docType: RustPB.Basic_V1_Doc.TypeEnum,
        _ docName: String,
        _ customKey: String,
        attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {

        let docIcon = LarkRichTextCoreUtils.docUrlIcon(docType: docType)
        let docKey = ImageTransformer.docTypeIconKey(docType, fileName: docName, customKey: customKey)
        let docIconSize = ImageTransformer.localImageSizeByKey(key: docKey)

        let imageInfo = ImageTransformInfo(
            key: customKey,
            localKey: docKey,
            imageSize: docIconSize,
            type: .doc,
            useOrigin: false)

        // 生成attachment
        let imageView = AttachmentImageView(key: imageInfo.localKey, state: .success)
        imageView.contentMode = .scaleAspectFit
        imageView.previewImage = { nil }
        imageView.bt.setLarkImage(with: .default(key: customKey),
                                  placeholder: docIcon,
                                  cacheName: LarkImageService.shared.thumbCache.name)
        let bounds = CGRect(x: 0, y: 0, width: docIconSize.width, height: docIconSize.height)
        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)

        if let font = attributes[.font] as? UIFont {
            let descent = (docIconSize.height - font.ascender - font.descender) / 2
            attachment.bounds = CGRect(x: 0, y: -descent, width: docIconSize.width, height: docIconSize.height)
        }

        let attachmentStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        attachmentStr.addAttribute(ImageTransformer.LocalIconAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        attachmentStr.addAttributes(attributes, range: NSRange(location: 0, length: 1))

        return attachmentStr
    }

    public static func transformLocalIconToString(_ content: InsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {

        let imageSize = ImageTransformer.localImageSizeByKey(key: content.localKey)
        let imageInfo = ImageTransformInfo(
            key: content.key,
            localKey: content.localKey,
            imageSize: imageSize,
            type: content.type,
            useOrigin: content.useOrigin,
            fromCopy: content.fromCopy,
            resizedImageSize: content.resizedSize)

        // 生成attachment
        let imageView = AttachmentImageView(key: imageInfo.localKey, state: .success)
        imageView.contentMode = .scaleAspectFit
        imageView.previewImage = { nil }
        imageView.image = content.image
        var bounds = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)

        if let font = attributes[.font] as? UIFont {
            let descent = (bounds.height - font.ascender - font.descender) / 2
            bounds = CGRect(x: 0, y: -descent, width: bounds.width, height: bounds.height)
        }

        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)

        let attachmentStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        attachmentStr.addAttribute(ImageTransformer.LocalIconAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        attachmentStr.addAttributes(attributes, range: NSRange(location: 0, length: 1))

        return attachmentStr
    }

    func transformLocalIconToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let imagePriority: RichTextAttrPriority = .content

        text.enumerateAttribute(ImageTransformer.LocalIconAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, _) in
            if let info = value as? ImageTransformInfo,
                info.key != ImageTransformer.LocalEmptyImageKey {
                let imageId = InputUtil.randomId()
                var imageProperty = RustPB.Basic_V1_RichTextElement.ImageProperty()
                let originKey = info.key.isEmpty ? info.localKey : info.key
                imageProperty.token = originKey
                imageProperty.thumbKey = originKey
                imageProperty.middleKey = originKey
                imageProperty.originKey = originKey
                imageProperty.urls = [info.type.rawValue]
                imageProperty.originWidth = Int32(info.imageSize.width)
                imageProperty.originHeight = Int32(info.imageSize.height)
                imageProperty.width = UInt32(info.resizedImageSize?.width ?? 0)
                imageProperty.height = UInt32(info.resizedImageSize?.height ?? 0)
                let imageTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.img, imageId, .img(imageProperty), nil)
                let imageAttr = RichTextAttr(priority: imagePriority, tuple: imageTuple)
                result.append(RichTextFragmentAttr(range, [imageAttr]))
            }
        }
        return result
    }
}
