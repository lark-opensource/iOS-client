//
//  TextViewInputProtocolSet.swift
//  EditTextView-EditTextViewAuto
//
//  Created by liluobin on 2023/3/6.
//

import UIKit
// 输入框编辑过程中对输入内容的操作
public protocol TextViewInputProtocol: AnyObject {
    func register(textView: UITextView)
    func textViewDidChange(_ textView: UITextView)
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
}

public extension TextViewInputProtocol {
    func register(textView: UITextView) {}
    func textViewDidChange(_ textView: UITextView) {}
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool { return true }
}

public final class TextViewInputProtocolSet: TextViewInputProtocol {
    private var items: [TextViewInputProtocol] = []

    public init(_ items: [TextViewInputProtocol] = []) {
        self.append(items)
    }

    public func append(_ items: [TextViewInputProtocol]) {
        self.items.append(contentsOf: items)
    }

    public func append(_ item: TextViewInputProtocol) {
        self.items.append(item)
    }

    public func register(textView: UITextView) {
        self.items.forEach { (item) in
            item.register(textView: textView)
        }
    }
    public func textViewDidChange(_ textView: UITextView) {
        self.items.forEach { (item) in
            item.textViewDidChange(textView)
        }
    }
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        for item in self.items {
            if !item.textView(textView, shouldChangeTextIn: range, replacementText: text) {
                return false
            }
        }
        return true
    }
}
