//
//  VideoTransformer.swift
//  Pods
//
//  Created by 李晨 on 2019/6/18.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import EditTextView
import RustPB
import ByteWebImage

public final class VideoTransformInfo: NSObject {
    public var name: String
    public var duration: Int32
    public var size: Int64
    public var compressPath: String
    public var originPath: String
    public var imageRemoteKeys: (originKey: String, middleKey: String, thumbnailKey: String)?
    public var imageLocalKey: String
    public var imageSize: CGSize
    public var imageData: Data
    public var uploadID: String?
    public var cryptoToken: String?
    public var key: String?
    public var copyImage: Bool
    public var copyMedia: Bool
    // 消息链接化场景富文本复制粘贴发送时，图片需要使用previewID做鉴权
    public var authToken: String?

    public var imageRemoteKey: String {
        //目前使用thumbnailKey渲染图片会渲染不出来，初步判断是sdk的历史bug；因此这里优先拿middleKey；如果thumbnailKey和middleKey都不存在，会被判断为本地视频
        if let imageRemoteKeys = imageRemoteKeys {
            return imageRemoteKeys.middleKey.isEmpty ? imageRemoteKeys.thumbnailKey : imageRemoteKeys.middleKey
        }
        return ""
    }

    public init(
        name: String,
        duration: Int32,
        size: Int64,
        compressPath: String,
        originPath: String,
        imageRemoteKeys: (originKey: String, middleKey: String, thumbnailKey: String)?,
        imageLocalKey: String,
        imageSize: CGSize,
        imageData: Data,
        uploadID: String?,
        cryptoToken: String?,
        key: String?,
        copyImage: Bool,
        copyMedia: Bool,
        authToken: String?) {
        self.name = name
        self.duration = duration
        self.size = size
        self.originPath = originPath
        self.compressPath = compressPath
        self.imageRemoteKeys = imageRemoteKeys
        self.imageLocalKey = imageLocalKey
        self.imageSize = imageSize
        self.imageData = imageData
        self.uploadID = uploadID
        self.cryptoToken = cryptoToken
        self.key = key
        self.copyImage = copyImage
        self.copyMedia = copyMedia
        self.authToken = authToken
        super.init()
    }
}

public final class VideoTransformer: RichTextTransformProtocol {
    public static let VideoAttachmentAttributedKey = NSAttributedString.Key(rawValue: "VideoAttachment")
    public static let RemoteVideoAttachmentAttributedKey = NSAttributedString.Key(rawValue: "RemoteVideoAttachment")

    public init() {}

    public typealias InsertContent = (info: VideoTransformInfo, image: UIImage, editorWidth: CGFloat)
    public static func transformContentToString(_ content: InsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        if content.info.imageRemoteKey.isEmpty {
            return VideoTransformer.transformVideoToString(content, attributes: attributes)
        }
        return VideoTransformer.transformRemoteVideoToString(content, attributes: attributes)
    }

    static func transformVideoToString(_ content: InsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let videoInfo = content.info
        let imageView = self.attachmentImageView(videoInfo: videoInfo)
        imageView.contentMode = .scaleAspectFill
        let showImageSize = VideoTransformer.imageSize(image: content.image, inset: .zero, originSize: videoInfo.imageSize, editerWidth: content.editorWidth)
        imageView.image = VideoTransformer.attachmentImage(image: content.image, size: showImageSize)
        let bounds = CGRect(x: 0, y: 0, width: showImageSize.width, height: showImageSize.height)
        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)
        let attachmentStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        attachmentStr.addAttribute(VideoTransformer.VideoAttachmentAttributedKey, value: videoInfo, range: NSRange(location: 0, length: 1))
        attachmentStr.addAttributes(attributes, range: NSRange(location: 0, length: 1))

        return attachmentStr
    }
    
    // 发送消息时预处理属性字符串
    public func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString {

        text.enumerateAttribute(VideoTransformer.VideoAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, _) in
            // 目前rust不希望赋值这个值， 发送前重置为空
            if let info = value as? VideoTransformInfo {
                info.imageLocalKey = ""
            }
        }
        return text
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
            if downgrade {
                return [NSAttributedString(string: BundleI18n.LarkBaseKeyboard.Lark_Legacy_MessagePoVideo, attributes: attributes)]
            }
            let element = option.element
            let image: UIImage = (try? ByteImage(element.property.media.imageData)) ?? UIImage()
            return [VideoTransformer.transformContentToString((Self.transformMediaElement(element.property.media), image, UIScreen.main.bounds.width), attributes: attributes)]
        }

        return [(.media, process)]
    }

    public static func transformMediaElement(_ element: Basic_V1_RichTextElement.MediaProperty) -> VideoTransformInfo {
        let remoteKeys: (originKey: String, middleKey: String, thumbnailKey: String) =
        (originKey: element.image.origin.key,
         middleKey: element.image.middle.key,
         thumbnailKey: element.image.thumbnail.key)
        let thumbnailKey = element.image.thumbnail.key
        let localKey = element.image.key
        let imageSize = thumbnailKey.isEmpty ? CGSize(
            width: CGFloat(element.width),
            height: CGFloat(element.height)
        ) : CGSize(
            width: CGFloat(element.image.thumbnail.width),
            height: CGFloat(element.image.thumbnail.height)
        )
        let uploadID = element.mediaUploadID
        let cryptoToken = element.cryptoToken
        let key = element.key
        let videoInfo = VideoTransformInfo(
            name: element.name,
            duration: element.duration,
            size: element.size,
            compressPath: element.compressPath,
            originPath: element.originPath,
            imageRemoteKeys: remoteKeys,
            imageLocalKey: localKey,
            imageSize: imageSize,
            imageData: element.imageData,
            uploadID: uploadID.isEmpty ? nil : uploadID,
            cryptoToken: cryptoToken.isEmpty ? nil : cryptoToken,
            key: key.isEmpty ? nil : key,
            copyImage: element.needCopyImg,
            copyMedia: element.needCopyMedia,
            authToken: element.resourcePreviewToken
        )
        return videoInfo
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        return transformVideoToRichText(text) + transformRemoteVideoToRichText(text)
    }

    func transformVideoToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let figurePriority: RichTextAttrPriority = .high
        let mediaPriority: RichTextAttrPriority = .content

        text.enumerateAttribute(VideoTransformer.VideoAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, _) in
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
                if let uploadID = info.uploadID {
                    mediaProperty.mediaUploadID = uploadID
                }
                if let cryptoToken = info.cryptoToken {
                    mediaProperty.cryptoToken = cryptoToken
                }
                if let authToken = info.authToken {
                    mediaProperty.resourcePreviewToken = authToken
                }
                var imageSet = ImageSet()
                imageSet.key = info.imageLocalKey
                imageSet.origin.key = info.imageRemoteKeys?.originKey ?? ""
                imageSet.middle.key = info.imageRemoteKeys?.middleKey ?? ""
                imageSet.thumbnail.key = info.imageRemoteKeys?.thumbnailKey ?? ""
                mediaProperty.image = imageSet
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

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { _ -> [NSAttributedString] in
            return [NSAttributedString(string: BundleI18n.LarkBaseKeyboard.Lark_Legacy_MessagePoVideo)]
        }

        return [(.media, process)]
    }
}

extension VideoTransformer {

    public static func insert(content: InsertContent, textView: UITextView) {

        var attributes: [NSAttributedString.Key: Any] = [:]
        for (key, value) in textView.typingAttributes {
            if !FontStyleConfig.fontStyleKeys.contains(key) {
                attributes[key] = value
            }
        }
        let font: UIFont = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 15)

        let imageStr = VideoTransformer.transformContentToString(content, attributes: attributes)

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
        insertText.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: insertText.length))

        // 插入文本
        let attributeString = textView.attributedText.mutableCopy() as? NSMutableAttributedString ?? NSMutableAttributedString(string: "")
        attributeString.insert(insertText, at: range.location)
        textView.attributedText = attributeString
        textView.selectedRange = NSRange(location: insertText.string.count + range.location, length: 0)
        textView.setContentOffset(offset, animated: false)
    }

    public static func attachmentImage(image: UIImage, size: CGSize) -> UIImage {
        return ImageTransformer.attachmentImage(image: image, size: size)
    }

    public static func fetchAllVideoKey(attributedText: NSAttributedString) -> [String] {
        var imageKeys: [String] = []
        attributedText.enumerateAttribute(VideoTransformer.VideoAttachmentAttributedKey, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, _, _) in
            if let info = value as? VideoTransformInfo {
                imageKeys.append(info.imageLocalKey)
            }
        }
        return imageKeys
    }

    public static func fetchAllRemoteVideoKey(attributedText: NSAttributedString) -> [String] {
        var imageKeys: [String] = []
        attributedText.enumerateAttribute(VideoTransformer.RemoteVideoAttachmentAttributedKey, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, _, _) in
            if let info = value as? VideoTransformInfo {
                imageKeys.append(info.imageRemoteKey)
            }
        }
        return imageKeys
    }


    public static func fetchAllVideoAttachemnt(attributedText: NSAttributedString) -> [(String, CustomTextAttachment, VideoTransformInfo, NSRange)] {
        var imageAttachments: [(String, CustomTextAttachment, VideoTransformInfo, NSRange)] = []
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { (attributes, range, _) in
            if let attachment = attributes[NSAttributedString.Key.attachment] as? CustomTextAttachment,
                let videoInfo = attributes[VideoTransformer.VideoAttachmentAttributedKey] as? VideoTransformInfo {
                imageAttachments.append((videoInfo.imageLocalKey, attachment, videoInfo, range))
            }
        }
        return imageAttachments
    }

    public static func fetchVideoAttachemntMapInfo(attributedText: NSAttributedString) -> [String: (CustomTextAttachment, VideoTransformInfo, NSRange)] {
        var imageAttachments: [String: (CustomTextAttachment, VideoTransformInfo, NSRange)] = [:]
        self.fetchAllVideoAttachemnt(attributedText: attributedText).forEach { value in
            imageAttachments[value.0] = (value.1, value.2, value.3)
        }
        return imageAttachments
    }

    public static func fetchAllRemoteVideoAttachemnt(attributedText: NSAttributedString) -> [(String, CustomTextAttachment, VideoTransformInfo, NSRange)] {
        var imageAttachments: [(String, CustomTextAttachment, VideoTransformInfo, NSRange)] = []
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { (attributes, range, _) in
            if let attachment = attributes[NSAttributedString.Key.attachment] as? CustomTextAttachment,
                let videoInfo = attributes[VideoTransformer.RemoteVideoAttachmentAttributedKey] as? VideoTransformInfo {
                imageAttachments.append((videoInfo.imageLocalKey, attachment, videoInfo, range))
            }
        }
        return imageAttachments
    }

    public static func imageSize(
        image: UIImage?,
        inset: UIEdgeInsets,
        originSize: CGSize,
        editerWidth: CGFloat) -> CGSize {

        return ImageTransformer.imageSize(
            image: image,
            inset: inset,
            originSize: originSize,
            editerWidth: editerWidth
        )
    }

    static func attachmentImageView(videoInfo: VideoTransformInfo) -> AttachmentImageView {
        let imageView = AttachmentImageView(key: videoInfo.imageLocalKey, state: .success)
        imageView.layer.masksToBounds = true
        let timeLabel = VideoTimeView()
        timeLabel.setDuration(videoInfo.duration)
        imageView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
            maker.right.bottom.equalToSuperview().offset(-12)
        }
        return imageView
    }
}
