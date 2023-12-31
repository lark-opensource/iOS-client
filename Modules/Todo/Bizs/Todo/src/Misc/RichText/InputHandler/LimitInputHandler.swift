//
//  LimitInputHandler.swift
//  Todo
//
//  Created by wangwanxin on 2022/1/5.
//

import Foundation

/// 处理输入字符限制
final class LimitInputHandler: TextViewInputProtocol {

    var limit: Int?
    var handler: (() -> Void)?

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let attrText = textView.attributedText, let limit = limit else {
            return true
        }
        // 删除场景
        if text.isEmpty && range.length > 0 {
            return true
        }

        let newText = MutAttrText(string: text)
        if attrText.length + newText.length > limit {
            handler?()
            return false
        }
        return true
    }

}
