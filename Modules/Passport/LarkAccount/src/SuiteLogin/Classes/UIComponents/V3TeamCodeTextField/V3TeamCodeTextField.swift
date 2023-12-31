//
//  V3TeamCodeTextField.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/1/4.
//

import Foundation
import SnapKit

class V3InputView: UIView {

    private let needBorder: Bool

    init(needBorder: Bool = false) {
        self.needBorder = needBorder
        super.init(frame: .zero)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 内容
    let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        return label
    }()

    // 光标
    let cursor: V3CursorView = V3CursorView()

    lazy var borderContainer: V3BorderView = {
        return V3BorderView()
    }()

    func setupSubViews() {
        isUserInteractionEnabled = false
        addSubview(label)
        addSubview(cursor)
        if needBorder {
            addSubview(borderContainer)
        }
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
        }
        cursor.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(V3CursorView.Layout.cursorWidth)
            make.top.equalToSuperview().offset(V3CursorView.Layout.topPadding)
            make.bottom.equalToSuperview().offset(-V3CursorView.Layout.bottomPadding)
        }
        if needBorder {
            borderContainer.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    func update(focusOn: Bool, animated: Bool, editing: Bool, content: String) {
        let cursorShow = focusOn && editing
        cursor.update(show: cursorShow, animated: animated)
        label.text = content
        if needBorder {
            borderContainer.update(highlight: focusOn || !content.isEmpty)
        }
    }

}

class V3TeamCodeTextField: UIView, UITextFieldDelegate {

    var currentText: String? {
        return textFieldView.text
    }

    lazy var textFieldView: UITextField = {
        let textView = AllowPasteTextField()
        textView.tintColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.clear
        textView.autocorrectionType = .no
        textView.delegate = self
        textView.addTarget(
            self,
            action: #selector(textFieldEditingChanged),
            for: .editingChanged
        )
        textView.keyboardType = .asciiCapable
        return textView
    }()

    let inputNum: Int = 8

    let leftInputViewContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()
    let rightInputViewContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()

    // inputViews contains cursor & label
    var inputViews: [V3InputView] = []

    // cursor for empty content
    let emptyCursor: V3CursorView = V3CursorView()
    // returnBtn click
    var returnBtnClicked: ((V3TeamCodeTextField) -> Void)?

    init() {
        super.init(frame: .zero)
        setupSubviews()
        setupInputViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupInputViews() {
        addSubview(leftInputViewContainer)
        addSubview(rightInputViewContainer)
        leftInputViewContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(30)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(rightInputViewContainer)
        }
        rightInputViewContainer.snp.makeConstraints { make in
            make.left.equalTo(leftInputViewContainer.snp.right).offset(20)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(30)
        }
        let numberLeft = Int(ceil(Double(inputNum) / 2.0))
        let numberRight = Int(floor(Double(inputNum) / 2.0))
        func addInputView(number: Int, container: UIView) {
            var leftTarget = container.snp.left
            for _ in 0..<number {
                let inputView = V3InputView()
                container.addSubview(inputView)
                inputViews.append(inputView)
                inputView.snp.makeConstraints { make in
                    make.left.equalTo(leftTarget)
                    make.top.bottom.equalToSuperview()
                    make.width.equalToSuperview().multipliedBy(1 / CGFloat(number))
                }
                leftTarget = inputView.snp.right
            }
        }
        addInputView(number: numberLeft, container: leftInputViewContainer)
        addInputView(number: numberRight, container: rightInputViewContainer)
    }

    func setupSubviews() {
        addSubview(borderView)
        addSubview(textFieldView)
        addSubview(emptyCursor)
        borderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        textFieldView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }
        emptyCursor.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(V3CursorView.Layout.cursorWidth)
            make.top.equalToSuperview().offset(V3CursorView.Layout.topPadding)
            make.bottom.equalToSuperview().offset(-V3CursorView.Layout.bottomPadding)
            make.left.equalTo(self.snp.left).offset(Layout.emptyCursorSpace)
        }
    }

    override func becomeFirstResponder() -> Bool {
        return textFieldView.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return textFieldView.resignFirstResponder()
    }

    // MARK: - UITextFieldDelegate

    private func updateInputViews(_ text: String) {
        if text.isEmpty, textFieldView.isEditing {
            emptyCursor.update(show: true, animated: true)
        } else {
            emptyCursor.update(show: false, animated: true)
        }
        inputViews.enumerated().forEach { index, inputView in
            if index < text.count {
                let content = text.substring(from: index).substring(to: 1)
                inputView.update(focusOn: false, animated: true, editing: textFieldView.isEditing, content: content)
            } else if index == text.count, !text.isEmpty {
                inputView.update(focusOn: true, animated: true, editing: textFieldView.isEditing, content: "")
            } else {
                inputView.update(focusOn: false, animated: true, editing: textFieldView.isEditing, content: "")
            }
        }
    }

    func processInput() -> String {
        // need uppercase
        let rawInputText = textFieldView.text?.uppercased()
        let inputText = rawInputText?.replacingOccurrences(of: "[^0-9A-Za-z]", with: "", options: .regularExpression)

        guard var text = inputText else { return "" }
        if text.count > inputNum {
            let dropText = text.substring(to: inputNum)
            textFieldView.text = dropText
            text = dropText
        } else {
            textFieldView.text = text
        }
        return text
    }

    @objc
    func textFieldEditingChanged(_ textView: UITextField) {
        let text = processInput()
        updateInputViews(text)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        borderView.update(highlight: true)
        updateInputViews(textFieldView.text ?? "")
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        borderView.update(highlight: false)
        updateInputViews(textFieldView.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        returnBtnClicked?(self)
        return true
    }

    // MARK: border
    lazy var borderView: V3BorderView = {
        return V3BorderView()
    }()

}

extension V3TeamCodeTextField {
    struct Layout {
        static let emptyCursorSpace: CGFloat = 14.0
    }
}

extension String {
    public func substring(from index: Int) -> String {
        if self.count > index {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[startIndex..<self.endIndex]

            return String(subString)
        } else {
            return self
        }
    }

    public func substring(to index: Int) -> String {
        if self.count > index {
            let endIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[..<endIndex]

            return String(subString)
        } else {
            return self
        }
    }

    func substring(in range: NSRange) -> String? {
        if range.lowerBound >= self.count {
            return nil
        }
        if range.upperBound >= self.count {
            return substring(from: range.lowerBound)
        }
        return substring(from: range.lowerBound).substring(to: range.length)
    }
}
