//
//  EntityNumInputHandler.swift
//  LarkBaseKeyboard
//
//  Created by wangwanxin on 2023/4/17.
//

import Foundation
import EditTextView
import LarkEMM
import LarkSensitivityControl
import LarkSetting
import LarkContainer

/// 套件number 目前只用于Task业务, 未来可能全业务线支持
public final class EntityNumInputHandler: TextViewInputProtocol {
    // 用于分割字符串的key
    private static let token = "LARK-PSDA-entity_number_input_handler"
    public init() {}
    public func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = CustomSubInteractionHandler()
        let entity = URLHanderEntity { str in
            return URLInputManager.checkURLType(str) == .entityNum
        } handerBlock: { str, _, attributes  in
            if let entityNum = URLInputManager.entityNumber(str) {
                var targetAttributes = attributes
                targetAttributes[AnchorTransformer.AnchorAttributedKey] = AnchorTransformInfo(isCustom: true,
                                                                                              scene: .copyPasteText,
                                                                                              contentLength: entityNum.utf16.count,
                                                                                              href: str)
                let numAttrText = NSMutableAttributedString(string: entityNum, attributes: targetAttributes)
                numAttrText.append(NSAttributedString(string: " "))
                // 标记蓝色
                numAttrText.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: numAttrText.length))
                return numAttrText
            }
            return NSAttributedString(string: str)
        }
        handler.handerPasteTextType = .url(.entityNum(entity))
        handler.pasteHandler = { [weak self] textView in
            guard let self = self else { return false }
            return self.numberPasteHandler(textView: textView)
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }
    
    private func numberPasteHandler(textView: UITextView) -> Bool {
        let config = PasteboardConfig(token: Token(Self.token))
        if let string = SCPasteboard.general(config).string?.trimmingCharacters(in: .whitespacesAndNewlines),
           URLInputManager.checkURLType(string) == .entityNum,
           let entityNum = URLInputManager.entityNumber(string) {
            insertNum(entityNum, in: textView, with: string)
            return true
        }
        return false
    }
    
    private func insertNum(_ entityNum: String, in textView: UITextView, with url: String) {
        guard let textView = textView as? LarkEditTextView else { return }
        var attributes = textView.typingAttributes
        let textViewAttr = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        attributes[AnchorTransformer.AnchorAttributedKey] = AnchorTransformInfo(isCustom: true,
                                                                                scene: .copyPasteText,
                                                                                contentLength: entityNum.utf16.count,
                                                                                href: url)

        let numAttrText = NSMutableAttributedString(string: entityNum, attributes: attributes)
        numAttrText.append(NSAttributedString(string: " "))
        // 标记蓝色
        numAttrText.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: numAttrText.length))

        let cursorLocation: Int
        let range = (textViewAttr.string as NSString).range(of: url)
        if range.location != NSNotFound && range.length > 0 {
            textViewAttr.replaceCharacters(in: range, with: numAttrText)
            cursorLocation = range.location
        } else {
            cursorLocation = textView.selectedRange.location
            textViewAttr.insert(numAttrText, at: cursorLocation)
        }
        textView.attributedText = textViewAttr
        textView.selectedRange = NSRange(location: cursorLocation + numAttrText.length, length: 0)
    }
}
