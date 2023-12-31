//
//  ImageTransformer+RemoteImage.swift
//  LarkRichTextCore
//
//  Created by bytedance on 6/30/22.
//

import UIKit
import Foundation
import EditTextView
import RustPB
import ByteWebImage

extension ImageTransformer {
    // nolint: duplicated_code
    func transformRemoteImageToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let figurePriority: RichTextAttrPriority = .high
        let imagePriority: RichTextAttrPriority = .content

        text.enumerateAttribute(ImageTransformer.RemoteImageAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, _) in
            if let info = value as? ImageTransformInfo {
                let imageId = InputUtil.randomId()
                var imageProperty = RustPB.Basic_V1_RichTextElement.ImageProperty()
                let originKey = info.key.isEmpty ? info.localKey : info.key
                imageProperty.token = info.token ?? originKey
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

                result.append(RichTextFragmentAttr(range, [figureAttr, imageAttr]))
            }
        }
        return result
    }
    // enable-lint: duplicated_code

    static func transformRemoteImageToImageAttr(_ content: InsertContent,
                                              attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let imageInfo = ImageTransformInfo(
            key: content.key,
            localKey: content.localKey,
            imageSize: content.imageSize,
            type: .remote,
            useOrigin: content.useOrigin,
            fromCopy: content.fromCopy,
            thumbKey: content.thumbKey,
            resizedImageSize: content.resizedSize,
            token: content.token,
            authToken: content.authToken)
        let imageView = AttachmentImageView(key: imageInfo.key, state: .success)
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        let showImageSize = ImageTransformer.imageSize(image: nil, inset: .zero, originSize: content.imageSize, editerWidth: content.editorWidth)
        var loadKey = content.key
        /// 如果原图本地有的话 优先展示原图的,否则展示缩略图
        if let thumbKey = content.thumbKey,
           !LarkImageService.shared.isCached(resource: .default(key: loadKey)) {
            loadKey = thumbKey
        }
        imageView.bt.setLarkImage(with: .default(key: loadKey),
                                  trackStart: {
            return TrackInfo(biz: .Messenger,
                             scene: .Chat,
                             isOrigin: content.useOrigin,
                             fromType: .post)
        }) { imageResult in
            if case .failure(let error) = imageResult {
                Self.logger.error("error for content.key: \(content.key)", error: error)
            }
        }
        let bounds = CGRect(x: 0, y: 0, width: showImageSize.width, height: showImageSize.height)
        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)
        let attachmentStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        attachmentStr.addAttribute(ImageTransformer.RemoteImageAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
        attachmentStr.addAttributes(attributes, range: NSRange(location: 0, length: 1))

        return attachmentStr
    }
}
