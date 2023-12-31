//
//  ActionableTextView.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/6/7.
//

import UIKit

/// 支持部分文字可以响应点击
class ActionableTextView: UITextView, UITextViewDelegate {
    var actionableText: String = ""
    var action: (() -> Void)? = nil
    var actionTextColor: UIColor = .ud.colorfulBlue

    private let dummyDelgate = DummyDelegate()
    static let kURLString = "https://www.dummy.com"

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        dummyDelgate.delegate = self
        self.delegate = dummyDelgate
        self.isEditable = false
        self.isSelectable = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAttributes() {
        let attributedOriginalText = NSMutableAttributedString(attributedString: attributedText)

        let linkRange = attributedOriginalText.mutableString.range(of: actionableText)
        attributedOriginalText.addAttributes([.link: Self.kURLString], range: linkRange)
        self.attributedText = attributedOriginalText
        self.linkTextAttributes = [.foregroundColor: actionTextColor]
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == ActionableTextView.kURLString {
            action?()
        }
        return false
    }
}

private final class DummyDelegate: NSObject, UITextViewDelegate {
    weak var delegate: UITextViewDelegate?

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) == true
    }
}


extension ActionableTextView {
    static func alertWithLinkTextView(text: String, actionableText: String, action: (() -> Void)?) -> ActionableTextView {
        let textView = ActionableTextView(frame: .zero)
        textView.isScrollEnabled = false
        textView.actionTextColor = UIColor.ud.textLinkNormal
        textView.backgroundColor = .clear
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 6
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                          NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                          NSAttributedString.Key.paragraphStyle: paraph]
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        textView.actionableText = actionableText
        textView.action = action
        textView.updateAttributes()
        return textView
    }
}
