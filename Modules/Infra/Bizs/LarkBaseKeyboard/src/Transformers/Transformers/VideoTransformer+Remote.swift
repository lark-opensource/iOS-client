//
//  VideoTransformer+Remote.swift
//  LarkRichTextCore
//
//  Created by bytedance on 7/1/22.
//

import UIKit
import Foundation
import LarkModel
import EditTextView
import RustPB
import ByteWebImage

extension VideoTransformer {
    // nolint: duplicated_code
    func transformRemoteVideoToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let figurePriority: RichTextAttrPriority = .high
        let mediaPriority: RichTextAttrPriority = .content

        text.enumerateAttribute(VideoTransformer.RemoteVideoAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, _) in
            if let info = value as? VideoTransformInfo {
                let mediaId = InputUtil.randomId()
                var mediaProperty = RustPB.Basic_V1_RichTextElement.MediaProperty()
                mediaProperty.name = info.name
                mediaProperty.duration = info.duration
                mediaProperty.size = info.size
                mediaProperty.source = .lark
                mediaProperty.compressPath = info.compressPath
                mediaProperty.originPath = info.originPath
                mediaProperty.width = Int32(info.imageSize.width)
                mediaProperty.height = Int32(info.imageSize.height)
                mediaProperty.imageData = info.imageData
                mediaProperty.needCopyImg = info.copyImage
                mediaProperty.needCopyMedia = info.copyMedia
                if let key = info.key {
                    mediaProperty.key = key
                }
                if let cryptoToken = info.cryptoToken {
                    mediaProperty.cryptoToken = cryptoToken
                }
                if let authToken = info.authToken {
                    mediaProperty.resourcePreviewToken = authToken
                }
                if let imageRemoteKeys = info.imageRemoteKeys {
                    var imageSet = ImageSet()
                    imageSet.key = imageRemoteKeys.middleKey.isEmpty ? imageRemoteKeys.thumbnailKey : imageRemoteKeys.middleKey
                    imageSet.middle.key = imageRemoteKeys.middleKey
                    imageSet.middle.width = Int32(info.imageSize.width)
                    imageSet.middle.height = Int32(info.imageSize.height)
                    imageSet.thumbnail.key = imageRemoteKeys.thumbnailKey
                    imageSet.thumbnail.width = Int32(info.imageSize.width)
                    imageSet.thumbnail.height = Int32(info.imageSize.height)
                    mediaProperty.image = imageSet
                }

                let mediaTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.media, mediaId, .media(mediaProperty), nil)
                let mediaAttr = RichTextAttr(priority: mediaPriority, tuple: mediaTuple)

                let fId = InputUtil.randomId()
                let figureProperty = RustPB.Basic_V1_RichTextElement.FigureProperty()
                let figureTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.figure, fId, .figure(figureProperty), nil)
                let figureAttr = RichTextAttr(priority: figurePriority, tuple: figureTuple)

                result.append(RichTextFragmentAttr(range, [figureAttr, mediaAttr]))
            }
        }
        return result
    }
    // enable-lint: duplicated_code

    static func transformRemoteVideoToString(_ content: InsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let videoInfo = content.info
        let imageView = self.attachmentImageView(videoInfo: videoInfo)
        imageView.contentMode = .scaleAspectFill
        let showImageSize = VideoTransformer.imageSize(image: nil, inset: .zero, originSize: videoInfo.imageSize, editerWidth: content.editorWidth)
        imageView.bt.setLarkImage(with: .default(key: videoInfo.imageRemoteKey),
                                  trackStart: {
            return TrackInfo(biz: .Messenger,
                             scene: .Chat,
                             isOrigin: false,
                             fromType: .post)
        })
        let bounds = CGRect(x: 0, y: 0, width: showImageSize.width, height: showImageSize.height)
        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)
        let attachmentStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        attachmentStr.addAttribute(VideoTransformer.RemoteVideoAttachmentAttributedKey, value: videoInfo, range: NSRange(location: 0, length: 1))
        attachmentStr.addAttributes(attributes, range: NSRange(location: 0, length: 1))

        return attachmentStr
    }
}
