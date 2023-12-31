//
//  CopyVideoInputHandler.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2023/1/18.
//
import Foundation
import UIKit
import EditTextView

public class CopyVideoInputHandler: TextViewInputProtocol {

    public init() {}

    public func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = CustomSubInteractionHandler()
        handler.supportPasteType = .video
        handler.copyHandler = { [weak self] (textView) in
            guard let self = self else { return false }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                var hasVideo = false
                let range = NSRange(location: 0, length: subAttributedText.length)
                let keys = [VideoTransformer.VideoAttachmentAttributedKey,
                            VideoTransformer.RemoteVideoAttachmentAttributedKey]
                for key in keys {
                    if hasVideo { break }
                    subAttributedText.enumerateAttribute(key, in: range) { (value, _, stop) in
                        if value != nil {
                            hasVideo = true
                            stop.pointee = true
                        }
                    }
                }
                return hasVideo
            }
            return false
        }
        handler.cutHandler = handler.copyHandler
        handler.pasteboardStringHandler = { attr in
            return ImageAndVideoInputHandler.retransformContentToString(attr, type: .video) ?? attr
        }
        handler.willAddInfoToPasteboard = { attr in
            let muattr = NSMutableAttributedString(attributedString: attr)
            muattr.enumerateAttribute(VideoTransformer.RemoteVideoAttachmentAttributedKey, in: NSRange(location: 0, length: attr.length), options: []) { value, _, _ in
                if let value = value as? VideoTransformInfo {
                    value.copyMedia = true
                    value.copyImage = true
                }
            }
            return muattr
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }
}
