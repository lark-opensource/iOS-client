//
//  AtUserInputHandler.swift
//  Lark
//
//  Created by lichen on 2017/11/7.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//
import Foundation
import LarkUIKit
import EditTextView
import LarkFeatureGating

public final class AtUserInputHandler: TagInputHandler {
    private var fg: Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "messenger.input.copy_@")
    }

    let supportPasteStyle: Bool

    public init(supportPasteStyle: Bool = false) {
        self.supportPasteStyle = supportPasteStyle
        super.init(key: AtTransformer.UserIdAttributedKey)
    }

    public override func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView,
              self.fg,
              (textView.interactionHandler as? CustomTextViewInteractionHandler) != nil else {
            return
        }
        let handler = CustomSubInteractionHandler()
        /// 不支持解析at的业务，粘贴时候不会保留样式
        if self.supportPasteStyle {
            handler.supportPasteType = .at
        }
        handler.copyHandler = { (textViewInner) in
            let selectedRange = textViewInner.selectedRange
            var hasAt = false
            if selectedRange.length > 0, let attributedText = textViewInner.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                let range = NSRange(location: 0, length: subAttributedText.length)
                subAttributedText.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: range, options: [], using: { (value, _, stop) in
                    if value != nil {
                        hasAt = true
                        stop.pointee = true
                    }
                })
            }
            return hasAt
        }
        handler.cutHandler = handler.copyHandler
        handler.willAddInfoToPasteboard = { attr in
            let muattr = NSMutableAttributedString(attributedString: attr)
            muattr.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: NSRange(location: 0, length: muattr.length), options: []) { value, range, _ in
                if let value = value as? AtChatterInfo {
                    /// 如果是匿名 直接不保留样式
                    if value.isAnonymous {
                        muattr.removeAttribute(AtTransformer.UserIdAttributedKey, range: range)
                    }
                    /// 如果复制了一半 也直接丢弃
                    if range.location == 0 || range.location + range.length == attr.length {
                        let subStr = muattr.attributedSubstring(from: range).string
                        if !subStr.hasSuffix(value.name) {
                            muattr.removeAttribute(AtTransformer.UserIdAttributedKey, range: range)
                        }
                    }
                }
            }
            return muattr
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }
}
