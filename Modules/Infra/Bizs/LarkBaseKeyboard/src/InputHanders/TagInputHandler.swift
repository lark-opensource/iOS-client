//
//  TagInputHandler.swift
//  LarkCore
//
//  Created by 李晨 on 2019/4/3.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import EditTextView

/// 删除Tag的时候，业务可以根据需要配置删除的需求
public protocol TagDeleteConfigProtocol: AnyObject {
    var allDeleFromTail: Bool { get }
}

extension TagDeleteConfigProtocol {
    var allDeleFromTail: Bool { true }
}

open class TagInputHandler: TextViewInputProtocol {
    let key: NSAttributedString.Key

    open var deleteAtTagBlock: ((_ textView: UITextView, _ range: NSRange, _ text: String) -> Void)?

    public init(key: NSAttributedString.Key) {
        self.key = key
    }

    open func register(textView: UITextView) {}

    open func textViewDidChange(_ textView: UITextView) {}

    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 处理删除操作
        if text.isEmpty && range.length != 0,
           !handleDelete(textView: textView, range: range) {
            self.deleteAtTagBlock?(textView, range, text)
            return false
        }

        // 处理输入操作
        if !text.isEmpty {
            handleInput(textView: textView, range: range)
        }
        return true
    }

    // 处理删除操作
    // 返回 true 代表同意输入框删除操作
    // 返回 false 代表不执行删除操作，在方法内部执行自定义删除方法
    private func handleDelete(textView: UITextView, range: NSRange) -> Bool {
        if let attributedText = textView.attributedText {
            var needRemoveAt = false
            attributedText.enumerateAttribute(self.key, in: NSRange(location: 0, length: attributedText.length), options: [], using: { (value, r, stop) in
                /// 是否需要从尾部删除的时候整体删除 默认都是true
                let allDeleFromTail = (value as? TagDeleteConfigProtocol)?.allDeleFromTail ?? true
                if value != nil &&
                    range.location + range.length == r.location + r.length,
                   range.length <= r.length, allDeleFromTail {
                    // 若果是从最后开始删除，需要全部删除
                    let selectedRange: NSRange = textView.selectedRange
                    let newAttributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                    newAttributedText.deleteCharacters(in: r)
                    textView.attributedText = newAttributedText
                    let interactionHandler = (textView as? LarkEditTextView)?.interactionHandler as? CustomTextViewInteractionHandler
                    interactionHandler?.didChange?()
                    /// 当selectedRange.length > 0 && range == selectedRange 删除的是选中的文字 光标需要计算选中的区域的range.length
                    /// 否则 只需要减去r.length即可
                    let dis: Int
                    if selectedRange.length > 0, range == selectedRange {
                        dis = r.length - range.length
                    } else {
                        dis = r.length
                    }
                    textView.selectedRange = NSRange(location: selectedRange.location - dis, length: 0)
                    needRemoveAt = true
                    stop.pointee = true
                } else if value != nil &&
                    NSIntersectionRange(range, r).length > 0 {
                    // 判断是否需要删除 tag 样式
                    let selectedRange: NSRange = textView.selectedRange
                    let newAttributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                    newAttributedText.removeAttribute(self.key, range: r)
                    newAttributedText.removeAttribute(.foregroundColor, range: r)
                    if let editText = textView as? LarkEditTextView {
                        newAttributedText.setAttributes(editText.defaultTypingAttributes, range: r)
                    }
                    textView.attributedText = newAttributedText
                    textView.selectedRange = selectedRange
                }
            })

            if needRemoveAt {
                return false
            }
        }
        return true
    }

    // 处理输入操作
    private func handleInput(textView: UITextView, range: NSRange) {
        if let attributedText = textView.attributedText {
            var hadRemoveAttribute: Bool = false
            attributedText.enumerateAttribute(self.key, in: NSRange(location: 0, length: attributedText.length), options: [], using: { (userId, r, stop) in
                let shouldRemoveAttribute = range.length > 0 ? (NSIntersectionRange(range, r).length > 0) : (r.contains(range.location) && range.location > r.location)
                if userId != nil && shouldRemoveAttribute {
                    let newAttributedText = NSMutableAttributedString(attributedString: attributedText)
                    newAttributedText.removeAttribute(self.key, range: r)
                    newAttributedText.removeAttribute(.foregroundColor, range: r)
                    if let editText = textView as? LarkEditTextView {
                        if let value = editText.defaultTypingAttributes[.foregroundColor] {
                            newAttributedText.addAttributes([.foregroundColor: value], range: r)
                        } else {
                            newAttributedText.setAttributes(editText.defaultTypingAttributes, range: r)
                        }
                    }
                    let selectedRange: NSRange = textView.selectedRange
                    textView.attributedText = newAttributedText
                    textView.selectedRange = selectedRange
                    hadRemoveAttribute = true
                    stop.pointee = true
                }
            })
            if hadRemoveAttribute {
                handleInput(textView: textView, range: range)
            }
        }
    }
}
