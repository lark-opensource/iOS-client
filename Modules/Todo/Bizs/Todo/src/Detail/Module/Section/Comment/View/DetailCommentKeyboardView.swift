//
//  DetailCommentKeyboardView.swift
//  Todo
//
//  Created by 张威 on 2021/3/4.
//

import RxCocoa
import RxSwift
import LarkUIKit
import LarkBaseKeyboard
import UniverseDesignFont

/// Detail - Comment - KeyboardView

class DetailCommentKeyboardView: OldBaseKeyboardView {

    let baseAttributes: [AttrText.Key: Any] = [
        .foregroundColor: UIColor.ud.textTitle,
        .font: UDFont.systemFont(ofSize: 16)
    ]

    init(frame: CGRect,
                  pasteboardToken: String,
                  keyboardNewStyleEnable: Bool = true) {
        super.init(frame: frame,
                   keyboardNewStyleEnable: keyboardNewStyleEnable)
        backgroundColor = UIColor.ud.bgBody
        inputTextView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: pasteboardToken)
        self.inputPlaceHolder = I18N.Todo_Task_AddAComment
        expandType = .hide

        inputTextView.isScrollEnabled = false
        inputTextView.maxHeight = 90
        inputTextView.font = (baseAttributes[.font] as? UIFont) ?? UDFont.systemFont(ofSize: 20, weight: .medium)
        inputTextView.textColor = UIColor.ud.textTitle

        var placeholderAttrs = baseAttributes
        placeholderAttrs[.foregroundColor] = UIColor.ud.textPlaceholder
        inputTextView.attributedPlaceholder = AttrText(
            string: I18N.Todo_Task_AddAComment,
            attributes: placeholderAttrs
        )
        inputTextView.linkTextAttributes = [:]
        inputTextView.defaultTypingAttributes = baseAttributes
        inputTextView.textAlignment = .left
        inputTextView.textContainerInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

        controlContainer.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        inputTextView.enablesReturnKeyAutomatically = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if !keyboardPanel.observeKeyboard {
            keyboardPanel.resetContentHeight()
        }
        keyboardPanel.observeKeyboard = true
        return true
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }

}
