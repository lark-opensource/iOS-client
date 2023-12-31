//
//  AutoResizeTextView.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/24.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation

final class AutoResizeTextView: UITextView {
    private static let maxHeight = CGFloat.greatestFiniteMagnitude
    override var contentSize: CGSize {
        get { super.contentSize }
        set {
            invalidateIntrinsicContentSize()
            super.contentSize = newValue
        }
    }

    override var intrinsicContentSize: CGSize {
        guard contentSize.height <= Self.maxHeight else {
            var size = contentSize
            size.height = Self.maxHeight
            return size
        }
        return contentSize
    }
}
#endif
