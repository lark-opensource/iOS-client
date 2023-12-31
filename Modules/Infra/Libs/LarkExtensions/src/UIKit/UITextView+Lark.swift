//
//  UITextView+Lark.swift
//  Lark
//
//  Created by lichen on 2017/11/7.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkCompatible

public extension LarkUIKitExtension where BaseType: UITextView {
    func insert(attributedString string: NSAttributedString) {
        let textView = self.base
        guard let attributedText = textView.attributedText.mutableCopy() as? NSMutableAttributedString else { return }
        let selectedRange = textView.selectedRange
        attributedText.replaceCharacters(in: selectedRange, with: string)
        textView.attributedText = attributedText
        textView.selectedRange = NSRange(location: selectedRange.location + string.length, length: 0)
        textView.layoutIfNeeded()
    }
}
