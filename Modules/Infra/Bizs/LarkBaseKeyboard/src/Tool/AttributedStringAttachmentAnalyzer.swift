//
//  AttributedStringAttachmentAnalyzer.swift
//  LarkRichTextCore
//
//  Created by liluobin on 2023/1/17.
//

import Foundation
import UIKit
import EditTextView

public class AttributedStringAttachmentAnalyzer {
    public struct Result {
        public let imageCount: Int
        public let videoCount: Int

        public var allCount: Int {
            return imageCount + videoCount
        }

        public init(imageCount: Int, videoCount: Int) {
            self.imageCount = imageCount
            self.videoCount = videoCount
        }
    }

    public enum AttachmentType {
        case image
        case video
        case imageAndVideo
    }

    public static func attachmentCountForAttributeString(_ attributedText: NSAttributedString, type: AttachmentType) -> Result {
        var imageCount: Int {
            let imageAttachments = ImageTransformer.fetchAllImageAttachemnt(attributedText: attributedText)
            let remoteImageAttachments = ImageTransformer.fetchAllRemoteImageAttachemnt(attributedText: attributedText)
            return imageAttachments.count + remoteImageAttachments.count
        }

        var videoCount: Int {
            let videoAttachments = VideoTransformer.fetchAllVideoAttachemnt(attributedText: attributedText)
            let remoteVideoAttachments = VideoTransformer.fetchAllRemoteVideoAttachemnt(attributedText: attributedText)
            return videoAttachments.count + remoteVideoAttachments.count
        }

        switch type {
        case .image:
            return Result(imageCount: imageCount, videoCount: 0)
        case .video:
            return Result(imageCount: 0, videoCount: videoCount)
        case .imageAndVideo:
            return Result(imageCount: imageCount, videoCount: videoCount)
        }
    }

    public static func separateAttachmentIfNeed(_ insertText: NSAttributedString, originText: NSAttributedString, range: NSRange) -> NSAttributedString {
        guard insertText.length > 0 else { return insertText }
        let separateKeys = [ImageTransformer.RemoteImageAttachmentAttributedKey,
                            ImageTransformer.ImageAttachmentAttributedKey,
                            VideoTransformer.RemoteVideoAttachmentAttributedKey,
                            VideoTransformer.VideoAttachmentAttributedKey]
        var headNeedSeparate = false
        insertText.enumerateAttributes(in: NSRange(location: 0, length: 1)) { attributes, range, _ in
            separateKeys.forEach { key in
                if attributes[key] != nil {
                    headNeedSeparate = true
                }
             }
        }

        var tailNeedSeparate = false
        insertText.enumerateAttributes(in: NSRange(location: insertText.length - 1, length: 1)) { attributes, range, _ in
            separateKeys.forEach { key in
                if attributes[key] != nil {
                    tailNeedSeparate = true
                }
             }
        }
        if !headNeedSeparate, !tailNeedSeparate { return insertText }

        var headInsertNewLine = false
        if headNeedSeparate, range.location > 0 {
            headInsertNewLine = (originText.string as NSString).substring(with: NSRange(location: range.location - 1,
                                                                                    length: 1)) != "\n"
        }
        let muattr = NSMutableAttributedString(string: headInsertNewLine ? "\n" : "")
        muattr.append(insertText)

        var tailInsertNewLine = false
        if tailNeedSeparate, range.location + range.length < originText.length {
            tailInsertNewLine = (originText.string as NSString).substring(with: NSRange(location: range.location + range.length,
                                                                                        length: 1)) != "\n"
        }
        if tailInsertNewLine {
            muattr.append(NSAttributedString(string: "\n"))
        }
        return muattr
    }

    public static func canPasteAttrForTextView(_ textView: LarkEditTextView, attr: NSAttributedString) -> Bool {
        let selectedRange = textView.selectedRange
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        if selectedRange.length > 0 {
            attributedText.replaceCharacters(in: selectedRange, with: attr)
        } else {
            attributedText.insert(attr, at: selectedRange.location)
        }
        return self.attachmentCountForAttributeString(attributedText, type: .video).videoCount <= 1
    }
    public static func deleVideoAttachmentForAttr(_ attr: NSAttributedString) -> NSAttributedString {
        let muattr = NSMutableAttributedString(attributedString: attr)
        var ranges: [NSRange] = []

        muattr.enumerateAttributes(in: NSRange(location: 0, length: muattr.length), options: []) { (attributes, range, _) in
            if let attachment = attributes[NSAttributedString.Key.attachment] as? CustomTextAttachment {
                if (attributes[VideoTransformer.VideoAttachmentAttributedKey] as? VideoTransformInfo != nil) ||
                   (attributes[VideoTransformer.RemoteVideoAttachmentAttributedKey] as? VideoTransformInfo != nil) {
                    ranges.append(range)
                }
            }
        }
        ranges.reversed().forEach { range in
            muattr.replaceCharacters(in: range, with: "")
        }
        return muattr
    }
}
