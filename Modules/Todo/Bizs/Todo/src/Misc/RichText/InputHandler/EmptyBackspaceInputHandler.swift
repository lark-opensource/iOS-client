//
//  EmptyBackspaceInputHandler.swift
//  Todo
//
//  Created by baiyantao on 2022/8/2.
//

import Foundation

final class EmptyBackspaceInputHandler: TextViewInputProtocol {

    var handler: (() -> Void)?

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let attrText = textView.attributedText else {
            return true
        }
        if text.isEmpty && range.length == 0 {
            handler?()
            return false
        }
        return true
    }

}
