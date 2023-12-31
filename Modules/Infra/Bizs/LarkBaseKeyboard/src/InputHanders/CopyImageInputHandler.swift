//
//  CopyImageInputHandler.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2023/1/18.
//
import Foundation
import UIKit
import EditTextView

public class CopyImageInputHandler: TextViewInputProtocol {

    public init() {}

    public func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = CustomSubInteractionHandler()
        handler.supportPasteType = .image
        handler.copyHandler = { [weak self] (textView) in
            guard let self = self else { return false }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                var hasImage = false
                let range = NSRange(location: 0, length: subAttributedText.length)
                let keys = [ImageTransformer.ImageAttachmentAttributedKey,
                            ImageTransformer.RemoteImageAttachmentAttributedKey]
                for key in keys {
                    if hasImage { break }
                    subAttributedText.enumerateAttribute(key, in: range) { (value, _, stop) in
                        if value != nil {
                            hasImage = true
                            stop.pointee = true
                        }
                    }
                }
                return hasImage
            }
            return false
        }
        handler.cutHandler = handler.copyHandler
        handler.pasteboardStringHandler = { attr in
            return ImageAndVideoInputHandler.retransformContentToString(attr, type: .image) ?? attr
        }
        handler.willAddInfoToPasteboard = { attr in
            let muattr = NSMutableAttributedString(attributedString: attr)
            muattr.enumerateAttribute(ImageTransformer.ImageAttachmentAttributedKey, in: NSRange(location: 0, length: attr.length), options: []) { value, _, _ in
                if let value = value as? ImageTransformInfo {
                    value.fromCopy = true
                    /// 如果图片还没有key的话 说明图片还没有上传成功，不能设置为远程图片
                    value.type = value.key.isEmpty ? .normal : .remote
                }
            }

            muattr.enumerateAttribute(ImageTransformer.RemoteIconAttachmentAttributedKey, in: NSRange(location: 0, length: attr.length), options: []) { value, _, _ in
                if let value = value as? ImageTransformInfo {
                    value.fromCopy = true
                    if value.type != .remote { assertionFailure("error type")}
                }
            }
            return muattr
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }
}
