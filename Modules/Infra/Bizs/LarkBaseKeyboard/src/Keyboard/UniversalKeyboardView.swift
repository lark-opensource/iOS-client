//
//  UniversalKeyboardView.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/12.
//

import UIKit
import LarkKeyboardView
import EditTextView
/**
公司圈和TODO的键盘理论上都可以被这个键盘替换
但是本期没有测试，暂不替换&删除oldBaseKeyboardView
 */
public protocol UniversalKeyboardDelegate: LKKeyboardViewDelegate {
    func inputTextViewWillSend()
    func inputTextViewSend(attributedText: NSAttributedString)
}

class UniversalKeyboardView: LKKeyboardView {
    public var keyboardDelegate: UniversalKeyboardDelegate? {
        return self.delegate as? UniversalKeyboardDelegate
    }

    public init(frame: CGRect, keyboardNewStyleEnable: Bool = false) {
        let config = KeyboardLayouConfig(phoneStyle: InputAreaStyle(inputWrapperMargin: 0,
                                                                        inputCanvasInset: .zero,
                                                                        inputStackInset: .zero),
                                             padStyle: InputAreaStyle(inputWrapperMargin: 20,
                                                                      inputCanvasInset: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0),
                                                                      inputStackInset: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)))
        super.init(frame: frame,
                   config: config,
                   keyboardNewStyleEnable: keyboardNewStyleEnable)
        self.updateTextViewConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configInputTextView() {
        inputTextView.defaultTypingAttributes = [
            .font: Cons.textFont,
            .foregroundColor: UIColor.ud.textTitle
        ]
        inputTextView.backgroundColor = UIColor.ud.bgBody
        // 输入框
        inputTextView.pasteDelegate = self
        inputTextView.delegate = self
        inputTextView.textDelegate = self
        if !keyboardNewStyleEnable {
            inputTextView.returnKeyType = .send
            inputTextView.enablesReturnKeyAutomatically = true
        }
    }

    override func configKeyboardView() {
        super.configKeyboardView()
        self.backgroundColor = UIColor.ud.bgBody
    }

    private func updateTextViewConstraints() {
        inputTextView.snp.remakeConstraints({ make in
            make.left.equalTo(15)
            make.top.equalTo(macInputStyle ? Cons.macStyleTextFieldTopMargin : Cons.textFieldTopMargin)
            make.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(Cons.textFieldMinHeight)
            make.height.lessThanOrEqualTo(Cons.textFieldMaxHeight)
            make.right.equalTo(self.controlContainer).offset(-15)
        })
    }

    open func sendMessage() {
        self.keyboardDelegate?.inputTextViewWillSend()
        var attributedText = inputTextView.attributedText ?? NSAttributedString()
        attributedText = KeyboardStringTrimTool.trimTailAttributedString(attr: attributedText, set: .whitespaces)
        self.keyboardDelegate?.inputTextViewSend(attributedText: attributedText)
    }
}
extension UniversalKeyboardView {
    enum Cons {
        static var textFont: UIFont { UIFont.ud.body0 }
        static var textFieldMinHeight: CGFloat { 35.auto() }
        static var textFieldMaxHeight: CGFloat { 125 }
        static var textFieldTopMargin: CGFloat { 5 }
        static var macStyleTextFieldTopMargin: CGFloat { 0 }
    }
}
