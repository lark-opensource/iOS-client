//
//  ImageTransformer+Remote.swift
//  LarkRichTextCore
//
//  Created by 袁平 on 2021/6/24.
//

import UIKit
import Foundation
import TangramService
import EditTextView
import RustPB
import LarkModel
import LarkDocsIcon
import UniverseDesignColor
import UniverseDesignTheme

/// 输入框里的CustomTextAttachment需要提供previewImage
final class AttachmentIconImageView: UIImageView, AttachmentPreviewableView {
    /// 缓存一份，UIGraphicsImageRenderer构造失败时使用
    private var cachePreviewImage: UIImage?

    public lazy var previewImage: () -> UIImage? = { [weak self] in
        guard let `self` = self else { return nil }
        let rendererImage = UIGraphicsImageRenderer(bounds: self.bounds).image { context in
            self.layer.render(in: context.cgContext)
        }
        if rendererImage.cgImage != nil {
            self.cachePreviewImage = rendererImage
            return rendererImage
        }
        return self.cachePreviewImage
    }

    var needupdateImage: Bool = false

    var followSuperViewBackgroundColor: Bool {
        return needupdateImage
    }
}

/// URL中台Inline Icon使用
extension ImageTransformer {

    public static func transformToIconAttrFrom(imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty,
                                       iconColor: UIColor = UIColor.ud.textLinkNormal,
                                       attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let type = imageProperty.urls.compactMap({ ImageTransformType(rawValue: $0) }).first ?? .inlineTintIcon
        let info = ImageTransformInfo(
            key: imageProperty.origin.key,
            localKey: "",
            imageSize: CGSize(width: CGFloat(imageProperty.originWidth),
                              height: CGFloat(imageProperty.originHeight)),
            type: type
        )
        let attr = transformIconToImageAttr(key: imageProperty.origin.key,
                                            localImage: nil,
                                            iconColor: iconColor,
                                            attributes: attributes)
        attr.addAttributes([ImageTransformer.RemoteIconAttachmentAttributedKey: info], range: NSRange(location: 0, length: attr.length))
        return attr
    }

    func transformRemoteIconToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let imagePriority: RichTextAttrPriority = .content

        text.enumerateAttribute(ImageTransformer.RemoteIconAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, _) in
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
                if let authToken = info.authToken {
                    imageProperty.resourcePreviewToken = authToken
                }
                let imageTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.img, imageId, .img(imageProperty), nil)
                let imageAttr = RichTextAttr(priority: imagePriority, tuple: imageTuple)
                result.append(RichTextFragmentAttr(range, [imageAttr]))
            }
        }
        return result
    }

    public static func transformToURLIconAttr(
        entity: InlinePreviewEntity,
        iconColor: UIColor = UIColor.ud.textLinkNormal,
        attributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString? {
        let (attr, imageInfo) = transformToURLInlineIconAttr(entity: entity, iconColor: iconColor, attributes: attributes)
        attr?.addAttribute(ImageTransformer.RemoteIconAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        return attr
    }

    public static func transformToURLIconAttrInDesCription(
        entity: InlinePreviewEntity,
        iconColor: UIColor = UIColor.ud.textLinkNormal,
        attributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString? {
        let (attr, imageInfo) = transformToURLInlineIconAttr(entity: entity, iconColor: iconColor, attributes: attributes)
        attr?.addAttribute(ImageTransformer.RemoteImageAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        return attr
    }

    private static func transformToURLInlineIconAttr(
        entity: InlinePreviewEntity,
        iconColor: UIColor,
        attributes: [NSAttributedString.Key: Any]
    ) -> (NSMutableAttributedString?, ImageTransformInfo) {
        let bounds = urlInlineIconBounds(font: attributes[.font] as? UIFont)
        let imageView = AttachmentIconImageView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        imageView.contentMode = .scaleAspectFit
        var attr: NSMutableAttributedString?
        let size = urlInlineIconBounds(font: attributes[.font] as? UIFont).size
        let imageInfo = ImageTransformInfo(key: "", localKey: "", imageSize: size, type: .inlineIcon, useOrigin: false)
        if entity.useColorIcon, let header = entity.unifiedHeader, header.hasIcon {
            let colorIcon = header.icon
            // 彩色icon是否染色由业务方配置
            if let localImage = colorIcon.udIcon.unicodeImage {
                imageInfo.key = colorIcon.udIcon.unicode
                imageInfo.type = .inlineUnicode
                attr = transformIconToImageAttr(localImage: localImage, iconColor: nil, attributes: attributes)
            } else if let localImage = colorIcon.udIcon.udImage {
                imageInfo.key = colorIcon.udIcon.key
                imageInfo.type = .inlineUDIcon
                attr = transformIconToImageAttr(localImage: localImage, iconColor: nil, attributes: attributes)
            } else if !colorIcon.icon.key.isEmpty {
                imageInfo.key = colorIcon.icon.key
                imageInfo.type = .inlineIcon
                attr = transformIconToImageAttr(key: colorIcon.icon.key, iconColor: colorIcon.iconColor.color, attributes: attributes)
            } else if !colorIcon.faviconURL.isEmpty {
                imageInfo.key = colorIcon.faviconURL
                imageInfo.type = .inlineIcon
                attr = transformIconToImageAttr(key: colorIcon.faviconURL, iconColor: colorIcon.iconColor.color, attributes: attributes)
            }
        }
        if attr == nil {
            if let localImage = entity.udIcon?.unicodeImage {
                imageInfo.key = entity.udIcon?.unicode ?? ""
                imageInfo.type = .inlineUnicode
                attr = transformIconToImageAttr(localImage: localImage, iconColor: nil, attributes: attributes)
            } else if let localImage = entity.udIcon?.udImage {
                // inline icon需要染色
                imageInfo.key = entity.udIcon?.key ?? ""
                imageInfo.type = .inlineUDIcon
                attr = transformIconToImageAttr(localImage: localImage, iconColor: iconColor, attributes: attributes)
            } else if let key = entity.iconKey ?? entity.iconUrl, !key.isEmpty {
                imageInfo.key = key
                imageInfo.type = .inlineTintIcon
                attr = transformIconToImageAttr(key: key, iconColor: iconColor, attributes: attributes)
            }
        }
        return (attr, imageInfo)
    }

    static func transformURLInlineIconToImageAttr(_ content: InsertContent,
                                                  iconColor: UIColor = UIColor.ud.textLinkNormal,
                                                  attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let imageInfo = ImageTransformInfo(key: content.key, localKey: "", imageSize: content.imageSize, type: content.type, useOrigin: content.useOrigin, fromCopy: content.fromCopy, resizedImageSize: content.resizedSize)
        var attr: NSMutableAttributedString?
        switch content.type {
        case .inlineIcon:
            attr = transformIconToImageAttr(key: content.key, iconColor: nil, attributes: attributes)
        case .inlineTintIcon:
            attr = transformIconToImageAttr(key: content.key, iconColor: iconColor, attributes: attributes)
        case .inlineUDIcon:
            let udIcon = URLPreviewUDIcon.getIconByKey(content.key)
            attr = transformIconToImageAttr(localImage: udIcon, iconColor: iconColor, attributes: attributes)
        case .inlineUnicode:
            let unicodeIcon = DocsIconManager.changeEmojiKeyToImage(key: content.key)
            attr = transformIconToImageAttr(localImage: unicodeIcon, iconColor: nil, attributes: attributes)
        default: break
        }
        attr?.addAttribute(ImageTransformer.RemoteIconAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        return attr ?? NSAttributedString(string: "")
    }

    /// 优先级：localImage > key
    private static func transformIconToImageAttr(key: String? = nil,
                                                 localImage: UIImage? = nil,
                                                 iconColor: UIColor?,
                                                 attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        let bounds = urlInlineIconBounds(font: attributes[.font] as? UIFont)
        let imageView = AttachmentIconImageView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        imageView.contentMode = .scaleAspectFit
        let placeholder = Resources.inline_icon_placeholder.ud.withTintColor(iconColor ?? UIColor.ud.textLinkNormal)
        var needUpdateImage = false
        if var localImage = localImage {
            if let iconColor = iconColor { localImage = localImage.ud.withTintColor(iconColor) }
            imageView.image = localImage
        } else if let key = key {
            needUpdateImage = true
            imageView.bt.setLarkImage(.default(key: key), placeholder: placeholder, completion: { [weak imageView] res in
                if case .success(let imageResult) = res {
                    imageView?.setImage(imageResult.image, tintColor: iconColor)
                    needUpdateImage = false
                }
            })
        } else {
            imageView.image = placeholder
        }
        /**
         这里为什么要有个needupdateImage的参数呢：
         正常我们只需要保证imageView的背景色不透明，就可以遮住底部的图片，确保上层ImageView的图片发生变变化，底部不能及时变化的问题
         但是这个时候不透明的View，会遮住光标的一部分【无法获取系统_containerView的方式导致的问题】
         所以这里会判断一下 是否用了本地图片，如果用了就无需不透明的图片【这个感觉解决方式也不好。但是整体上需要些优化】
         问题是7.0引入 后续再做整体的优化
         */
        imageView.needupdateImage = needUpdateImage
        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)
        let attr = NSMutableAttributedString(attachment: attachment)
        attr.addAttributes(attributes, range: NSRange(location: 0, length: 1))
        return attr
    }

    private static func urlInlineIconBounds(font: UIFont?) -> CGRect {
        var bounds = CGRect(x: 0, y: 0, width: 25, height: 17) // same size from doc
        if let font = font {
            let descent = (bounds.height - font.ascender - font.descender) / 2
            bounds = CGRect(x: 0, y: -descent, width: bounds.width, height: bounds.height)
        }
        return bounds
    }
}
