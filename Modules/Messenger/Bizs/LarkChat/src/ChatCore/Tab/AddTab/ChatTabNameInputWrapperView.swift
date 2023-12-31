//
//  ChatTabNameInputWrapperView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/1.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import EditTextView
import UIKit

enum ChatTabEditStatus {
    case limit /// 字数超限或为空
    case normal
}

final class ChatTabNameInputWrapperView: UIView, UITextViewDelegate {

    private var editStatusChanged: ((ChatTabEditStatus) -> Void)?
    private var maxLength = 80

    var inputText: String {
        return (self.inputTextView.text ?? "").trimmingCharacters(in: .whitespaces)
    }

    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.cornerRadius = 10
        return containerView
    }()

    private lazy var inputTextView: LarkEditTextView = {
        let inputTextView = LarkEditTextView()
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle
        ]
        inputTextView.defaultTypingAttributes = [.font: UIFont.systemFont(ofSize: 16),
                                                 .foregroundColor: UIColor.ud.textTitle]
        inputTextView.isScrollEnabled = false
        inputTextView.delegate = self
        inputTextView.textContainerInset = .zero
        inputTextView.maxHeight = 108
        inputTextView.backgroundColor = UIColor.clear
        return inputTextView
    }()

    private lazy var inputCountLabel: UILabel = {
        let inputCountLabel = UILabel()
        inputCountLabel.font = UIFont.systemFont(ofSize: 12)
        inputCountLabel.textAlignment = .right
        inputCountLabel.textColor = UIColor.ud.textPlaceholder
        return inputCountLabel
    }()

    private lazy var inputTipLabel: UILabel = {
        let inputTipLabel = UILabel()
        inputTipLabel.font = UIFont.systemFont(ofSize: 14)
        inputTipLabel.textColor = UIColor.ud.textPlaceholder
        return inputTipLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview()
        }
        containerView.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.right.equalToSuperview().inset(42)
            make.top.bottom.equalToSuperview().inset(14)
            make.height.greaterThanOrEqualTo(20)
            make.height.lessThanOrEqualTo(108)
        }
        containerView.addSubview(inputCountLabel)
        inputCountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(17)
            make.right.equalToSuperview().inset(16)
        }
        self.addSubview(inputTipLabel)
        inputTipLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(containerView.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }
    }

    func showKeyboard() {
        inputTextView.becomeFirstResponder()
    }

    func set(inputText: String, editStatusChanged: @escaping (ChatTabEditStatus) -> Void) {
        self.editStatusChanged = editStatusChanged
        if getLength(forText: inputText) > maxLength {
            let trimmedText = getPrefix(maxLength, forText: inputText)
            inputTextView.text = trimmedText
            updateTextCount(trimmedText)
        } else {
            inputTextView.text = inputText
            updateTextCount(inputText)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textViewDidChange(_ textView: UITextView) {
        let limit = maxLength
        var selectedCount = 0
        if let range = textView.markedTextRange {
            selectedCount = textView.text(in: range)?.count ?? 0
        }
        let contentLength = textView.text.count - selectedCount
        let validText = String(textView.text.prefix(contentLength))
        if let undoManager = textView.undoManager,
           undoManager.isUndoing || undoManager.isRedoing {
            /// 系统撤销会调用 textViewDidChange()
            /// textViewDidChange() 内部存在字数限制，需要去修改当前 text
            /// 系统记录完文本操作历史后又产生了新的、不被记录的文本变化，于是最终执行 undo 时数据前后不匹配，crash
            updateTextCount(validText)
            return
        }
        if getLength(forText: validText) > limit {
            let trimmedText = getPrefix(limit, forText: textView.text)
            textView.text = trimmedText
            updateTextCount(trimmedText)
        } else {
            updateTextCount(validText)
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        /// 端上限制字符数时，如果进行撤销操作可能导致 range 越界，此时继续返回 true 会造成 crash
        if NSMaxRange(range) > textView.text.utf16.count {
            return false
        }
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    private func updateTextCount(_ text: String) {
        let textCount = getLength(forText: text)
        let displayCount = Int(ceil(Float(textCount) / 2))
        let limitCount = Int(ceil(Float(maxLength) / 2))
        inputCountLabel.text = "\(displayCount)"
        if displayCount == 0 || text.trimmingCharacters(in: .whitespaces).isEmpty {
            inputTipLabel.text = BundleI18n.LarkChat.Lark_IM_Tabs_RecommendedWordCount_Text_Mobile(8)
            editStatusChanged?(.limit)
            return
        }
        if displayCount >= limitCount {
            inputTipLabel.text = BundleI18n.LarkChat.Lark_IM_Tabs_WordLimit_Text_Mobile(limitCount)
            editStatusChanged?(.normal)
            return
        }
        inputTipLabel.text = BundleI18n.LarkChat.Lark_IM_Tabs_RecommendedWordCount_Text_Mobile(8)
        editStatusChanged?(.normal)
    }

    // 按照特定字符计数规则，获取字符串长度
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }

    // 按照特定字符计数规则，截取字符串
    private func getPrefix(_ maxLength: Int, forText text: String) -> String {
        guard maxLength >= 0 else { return "" }
        var currentLength: Int = 0
        var maxIndex: Int = 0
        for (index, char) in text.enumerated() {
            guard currentLength <= maxLength else { break }
            currentLength += min(char.utf8.count, 2)
            maxIndex = index
        }
        return String(text.prefix(maxIndex))
    }
}
