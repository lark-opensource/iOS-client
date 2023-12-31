//
//  AnchorInputHandler.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/8/1.
//

import UIKit
import EditTextView

public final class AnchorInputHandler: TagInputHandler {
    public init() {
        super.init(key: AnchorTransformer.AnchorAttributedKey)
    }

    public override func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView, TextViewCustomPasteConfig.useNewPasteFG else { return }
        let handler = CustomSubInteractionHandler()
        handler.supportPasteType = .anchor
        handler.copyHandler = { (textView) in
            let selectedRange = textView.selectedRange
            var hasAnchor = false
            if selectedRange.length > 0, let attributedText = textView.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                let range = NSRange(location: 0, length: subAttributedText.length)
                subAttributedText.enumerateAttribute(AnchorTransformer.AnchorAttributedKey, in: range, options: [], using: { (value, _, stop) in
                    if value != nil {
                        hasAnchor = true
                        stop.pointee = true
                    }
                })
            }
            return hasAnchor
        }

        handler.cutHandler = handler.copyHandler

        handler.willAddInfoToPasteboard = { attr in
            let muAttr = NSMutableAttributedString(attributedString: attr)
            muAttr.enumerateAttribute(AnchorTransformer.AnchorAttributedKey, in: NSRange(location: 0, length: muAttr.length), options: []) { value, range, _ in
                if let value = value as? AnchorTransformInfo {
                    if range.location == 0 || range.location + range.length == muAttr.length {
                        if range.length < value.contentLength {
                            muAttr.removeAttribute(AnchorTransformer.AnchorAttributedKey, range: range)
                        }
                    }
                }
            }
            return muAttr
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }
}
