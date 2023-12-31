//
//  TitleEditTextView.swift
//  LarkCore
//
//  Created by liluobin on 2021/8/26.
//

import UIKit
import Foundation
import EditTextView
import LarkRichTextCore
import LarkKeyboardView
import LarkBaseKeyboard

public final class TitleEditView: UIView, UITextViewDelegate {
    public let textView = LarkEditTextView()
    let shouldBeginEditing: (() -> Void)?
    let endEditing: (() -> Void)?
    public var returnInputHandler: (() -> Void)?
    public var textViewDidBeginEditingCallBack: (() -> Void)?
    private var titleInputProtocolSet = TextViewInputProtocolSet()
    public init(placeholder: String,
         shouldBeginEditing: (() -> Void)?,
         endEditing: (() -> Void)?) {
        self.shouldBeginEditing = shouldBeginEditing
        self.endEditing = endEditing
        super.init(frame: .zero)
        let placeholderAttr = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: Cons.titleTypingFont,
                .foregroundColor: UIColor.ud.textPlaceholder
            ]
        )
        textView.attributedPlaceholder = placeholderAttr
        setupView()
        initInputHandler()
    }
    private func initInputHandler() {
        let returnInputHandler = ReturnInputHandler { [weak self] _ -> Bool in
            guard let `self` = self else { return true }
            self.returnInputHandler?()
            return false
        }

        let titleInputProtocolSet = TextViewInputProtocolSet([returnInputHandler])
        self.titleInputProtocolSet = titleInputProtocolSet
        self.titleInputProtocolSet.register(textView: textView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        textView.textColor = UIColor.ud.textTitle
        textView.backgroundColor = UIColor.ud.bgBody
        textView.maxHeight = 36
        textView.defaultTypingAttributes = [
            .font: Cons.titleTypingFont,
            .foregroundColor: UIColor.ud.textTitle
        ]
        textView.delegate = self
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    // MARK: - UITextViewDelegate
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        shouldBeginEditing?()
        return true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        endEditing?()
    }

    public func textViewDidChange(_ textView: UITextView) {
        self.titleInputProtocolSet.textViewDidChange(textView)
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        textViewDidBeginEditingCallBack?()
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.titleInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
}
fileprivate extension TitleEditView {
    enum Cons {
        static var titlePlaceholderFont: UIFont { UIFont.ud.title3 }
        static var titleTypingFont: UIFont { UIFont.ud.title3 }
    }
}
