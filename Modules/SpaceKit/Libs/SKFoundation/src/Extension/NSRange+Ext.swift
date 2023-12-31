//
//  NSRange+Ext.swift
//  SpaceKit
//
//  Created by nine on 2018/11/28.
//

import Foundation
/*
extension NSRange {
    /// Emoji 在 NSString 中长度为2，在String中长度为1，该方法为消除NSRange中的长度影响
    public func removeEmojiRange(with textView: UITextView) -> NSRange {
        // https://www.objc.io/issues/9-strings/unicode/
        var range = self
        range.location = (textView.text as NSString).substring(to: range.location).count
        range.length = (textView.text as NSString).substring(with: range).count
        return range
    }
}
*/
