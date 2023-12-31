//
//  ImageAndVideoInputHandler.swift
//  LarkKeyboardView
//
//  Created by ByteDance on 2022/9/27.
//

import UIKit
import Foundation
import EditTextView

public final class ImageAndVideoInputHandler: TextViewInputProtocol {
    public enum RetransformType {
        case image
        case video
        case all
    }
    private var pasteboardRedesignFg: Bool {
        return LarkPasteboardConfig.useRedesign
    }
    public init() {}
    public func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = CustomSubInteractionHandler()
        let defaultTypingAttributes = textView.defaultTypingAttributes
        let copyAndCutHandler: ((BaseEditTextView) -> Bool) = { [weak self] (textView) in
            guard let self = self, !self.pasteboardRedesignFg else {
                return false
            }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                DispatchQueue.main.async {
                    if let pasteString = Self.retransformContentToString(subAttributedText, type: .all) {
                        UIPasteboard.general.string = pasteString.string
                    }
                }
            }
            return false
        }
        // 输入框处理拷贝回调
        handler.copyHandler = copyAndCutHandler
        // 输入框处理剪切回调
        handler.cutHandler = copyAndCutHandler
        handler.pasteboardStringHandler = { attr in
            return Self.retransformContentToString(attr, type: .all) ?? attr
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }
    public func textViewDidChange(_ textView: UITextView) {}
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool { return true }


    public static func retransformContentToString(_ text: NSAttributedString, type: RetransformType) -> NSAttributedString? {
        if let attributedText = text.mutableCopy() as? NSMutableAttributedString {
            var range: NSRange = NSRange(location: 0, length: 0)
            var copyContentMap: [NSAttributedString.Key: String] = [
                ImageTransformer.ImageAttachmentAttributedKey: BundleI18n.LarkBaseKeyboard.Lark_Legacy_ImageSummarize,
                ImageTransformer.RemoteImageAttachmentAttributedKey: BundleI18n.LarkBaseKeyboard.Lark_Legacy_ImageSummarize,
                VideoTransformer.VideoAttachmentAttributedKey: BundleI18n.LarkBaseKeyboard.Lark_Legacy_MessagePoVideo,
                VideoTransformer.RemoteVideoAttachmentAttributedKey: BundleI18n.LarkBaseKeyboard.Lark_Legacy_MessagePoVideo
            ]
            switch type {
            case .image:
                copyContentMap.removeValue(forKey: VideoTransformer.VideoAttachmentAttributedKey)
                copyContentMap.removeValue(forKey: VideoTransformer.RemoteVideoAttachmentAttributedKey)
            case .video:
                copyContentMap.removeValue(forKey: ImageTransformer.ImageAttachmentAttributedKey)
                copyContentMap.removeValue(forKey: ImageTransformer.RemoteImageAttachmentAttributedKey)
            case .all:
                break
            }

            var pair: (key: NSAttributedString.Key, value: String)?

            for item in copyContentMap {
                attributedText.enumerateAttribute(item.key, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, r, stop) in
                    if value != nil {
                        range = r
                        stop.pointee = true
                        pair = item
                    }
                }
                if pair != nil {
                    break
                }
            }

            if let pair = pair {
                attributedText.removeAttribute(pair.key, range: range)
                attributedText.removeAttribute(.attachment, range: range)
                attributedText.replaceCharacters(in: range, with: pair.value)
                return Self.retransformContentToString(attributedText, type: .all) ?? attributedText
            } else {
                return nil
            }
        }

        return nil
    }
}
