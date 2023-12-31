//
//  V3VerifyCodeTextField.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/12/11.
//

import UIKit
import SnapKit

class V3VerifyCodeTextField: UIView, UITextFieldDelegate {

    public typealias SelectCodeBlock = (String) -> Void

    private var codeBlock: SelectCodeBlock?

    public var text: String? {
        return textFieldView.text
    }

    public init(beginEdit: Bool = true, selectCodeBlock CodeBlock: @escaping SelectCodeBlock) {
        super.init(frame: .zero)
        self.codeBlock = CodeBlock
        setupInputViews()
        if beginEdit {
            self.beginEdit()
        }
        updateInputViews(textFieldView.text ?? "")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var textFieldView: NoActionTextField = {
        let tf = NoActionTextField()
        tf.tintColor = UIColor.clear
        tf.backgroundColor = UIColor.clear
        tf.textColor = UIColor.clear
        tf.delegate = self
        tf.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        tf.keyboardType = .numberPad
        tf.autoresizingMask = .flexibleWidth
        return tf
    }()

    private let inputNum: Int = V3VerifyCodeControl.maxInputNum
    // inputViews contains cursor & label
    private var inputViews: [V3InputView] = []
    private let leftInputViewContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()
    private let rightInputViewContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()

    private let splitView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.textTitle
        return v
    }()

    func setupInputViews() {
        addSubview(textFieldView)
        addSubview(leftInputViewContainer)
        addSubview(rightInputViewContainer)
        textFieldView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let splitContainer = UIView()
        addSubview(splitContainer)
        splitContainer.addSubview(splitView)
        splitView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(Layout.splitViewSize)
            make.top.left.greaterThanOrEqualToSuperview()
            make.bottom.right.lessThanOrEqualToSuperview()
        }
        splitContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        leftInputViewContainer.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.right.equalTo(splitContainer.snp.left)
        }
        rightInputViewContainer.snp.makeConstraints { make in
            make.left.equalTo(splitContainer.snp.right)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        let numberLeft = Int(ceil(Double(inputNum) / 2.0))
        let numberRight = Int(floor(Double(inputNum) / 2.0))
        func addInputView(number: Int, container: UIView) {
            var leftTarget = container.snp.left
            var previousWidthTarget: ConstraintItem?
            for i in 0..<number {
                let inputView = V3InputView(needBorder: true)
                inputView.label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
                container.addSubview(inputView)
                inputViews.append(inputView)
                inputView.snp.makeConstraints { make in
                    make.left.equalTo(leftTarget)
                    make.top.bottom.equalToSuperview()
                    make.width.lessThanOrEqualTo(Layout.inputViewMaxWidth).priority(.required) // 屏幕宽的时候 控制方格大小不要超过48 打破 space 的宽度的约束变化
                    make.height.equalTo(inputView.snp.width).multipliedBy(Layout.inputViewWidthHeightRatio)
                    if let widthTarget = previousWidthTarget {
                        make.width.equalTo(widthTarget)
                    }
                    if i == number - 1 {
                        make.right.equalToSuperview()
                    }
                }

                if i != number - 1 {
                    let space = UIView()
                    container.addSubview(space)
                    space.snp.makeConstraints { (make) in
                        make.top.bottom.equalToSuperview()
                        make.left.equalTo(inputView.snp.right)
                        // splitContainerWidth = space * 30 / 18 + Layout.splitViewSize.width
                        // space = splitContainerWidth * 18/30 -  Layout.splitViewSize.width * 18 / 30
                        make.width.equalTo(splitContainer)
                            .multipliedBy(Layout.splitContainerRatio)
                            .offset(-Layout.splitViewSize.width * Layout.splitContainerRatio)
                        make.width.equalTo(Layout.inputViewMinSpace).priority(.high) // 屏幕窄的时候控制space宽度 方格根据屏幕宽度变化
                    }
                    leftTarget = space.snp.right
                }
                previousWidthTarget = inputView.snp.width
            }
        }
        addInputView(number: numberLeft, container: leftInputViewContainer)
        addInputView(number: numberRight, container: rightInputViewContainer)
    }

    // MARK: - UITextFieldDelegate

    private func updateInputViews(_ text: String) {
        inputViews.enumerated().forEach { index, inputView in
            if index < text.count {
                let content = text.substring(from: index).substring(to: 1)
                inputView.update(focusOn: false, animated: true, editing: true, content: content)
            } else if index == text.count {
                inputView.update(focusOn: true, animated: true, editing: true, content: "")
            } else {
                inputView.update(focusOn: false, animated: true, editing: true, content: "")
            }
        }
    }

    func processInput() -> String {
        // need uppercase
        let inputText = textFieldView.text
        guard var text = inputText else { return "" }
        if text.count > inputNum {
            let dropText = text.substring(to: inputNum)
            textFieldView.text = dropText
            text = dropText
        }
        return text
    }

    private func callbackTextChange() {
        if self.codeBlock != nil {
            self.codeBlock?(textFieldView.text ?? "")
        }
    }

    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "" {
           return true
        }
        let characterSet = CharacterSet(charactersIn: "0123456789")
        if let _ = string.rangeOfCharacter(from: characterSet, options: .caseInsensitive) {
            return true
        } else {
            return false
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // 解决 iPad 点击 tab 验证码无法输入的问题
        if textField.isFirstResponder {
            return false
        }
        return true
    }

    @objc
    func textFieldEditingChanged(_ textView: UITextField) {
        let text = processInput()
        callbackTextChange()
        updateInputViews(text)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateInputViews(textFieldView.text ?? "")
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateInputViews(textFieldView.text ?? "")
    }

    // 开始编辑
    func beginEdit() {
        textFieldView.becomeFirstResponder()
    }

    // 结束编辑
    func endEdit() {
        textFieldView.resignFirstResponder()
    }

    func resetView() {
        textFieldView.text = nil
        updateInputViews(textFieldView.text ?? "")
    }

}

extension V3VerifyCodeTextField {
    struct Layout {
        static let inputViewMinSpace: CGFloat = 6.0
        static let splitViewSize: CGSize = CGSize(width: 10, height: 2)
        static let splitViewInsetLeft: CGFloat = 10.5
        static let splitViewInsetRight: CGFloat = 10.5
        static let inputViewWidthHeightRatio: CGFloat = 50.0 / 48.0

        static let inputViewMaxWidth: CGFloat = 48
        static let splitContainerRatio: CGFloat = 18 / 30
    }
}

/// remove select / paste / copy .etc actions
class NoActionTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
