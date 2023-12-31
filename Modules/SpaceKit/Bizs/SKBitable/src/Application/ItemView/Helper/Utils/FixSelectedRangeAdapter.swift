//
//  FixSelectedRangeAdapter.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/16.
//  


import UIKit

final class FixSelectedRangeAdapter {
    
    /// 适配光标选中区域，让有富文本的地方不被切断
    /// - Parameters:
    ///   - textView: 对应的 textView
    ///   - lastSelectedRange: 上次记录的已选中的区域
    ///   - currenSelectedRange: 本次原来的选中的区域
    ///   - attributedString: 富文本
    ///   - attributedStringKey: 富文本对应key
    static func fixSelectedRange(textView: UITextView,
                                 lastSelectedRange: NSRange,
                                 currenSelectedRange: NSRange,
                                 attributedString: NSAttributedString,
                                 attributedStringKey: NSAttributedString.Key) {
        
        attributedString.enumerateAttribute(attributedStringKey,
                                            in: NSRange(location: 0,
                                                        length: attributedString.length),
                                            options: .reverse) { (attrs, atRange, _) in
//            debugPrint("getFixSelectedRange currentRange: \(currenSelectedRange), atRnage: \(atRange) key: \(attributedStringKey), attrs: \(attrs)")
            
            if let fixRange = getFixSelectedRange(lastSelectedRange: lastSelectedRange,
                                                  currenSelectedRange: currenSelectedRange,
                                                  atRange: atRange,
                                                  attrs: attrs) {
                textView.selectedRange = fixRange
            }
        }
    }
    
    static private func getFixSelectedRange(lastSelectedRange: NSRange,
                                            currenSelectedRange: NSRange,
                                            atRange: NSRange,
                                            attrs: Any?) -> NSRange? {
        
        var resultRange: NSRange?
        let curHeadLocation = currenSelectedRange.location
        let curTailLocation = currenSelectedRange.location + currenSelectedRange.length
        let atHeadLocation = atRange.location
        let atTailLocation = atRange.location + atRange.length
        // 头部在富文本范围里
        let isHeadInAtRange = atRange.contains(curHeadLocation)
        // 尾部在富文本范围里
        let isTailinAtRange = atRange.contains(curTailLocation)
        
        //有属性富文本，且当前光标在范围内
        guard attrs != nil && (isHeadInAtRange || isTailinAtRange) else {
            return nil
        }
        
//        debugPrint("getFixSelectedRange in atRnage currentRange: \(currenSelectedRange), atRnage: \(atRange)")
        
        /// 光标模式
        if currenSelectedRange.length == 0 {
            if lastSelectedRange.location < currenSelectedRange.location {
                resultRange = NSRange(location: atRange.location + atRange.length, length: 0)
            } else {
                resultRange = NSRange(location: atRange.location, length: 0)
            }
        } else {
            let headLocation = min(curHeadLocation, atHeadLocation)
            let tailLocation = max(curTailLocation, atTailLocation)
            resultRange = NSRange(location: headLocation, length: tailLocation - headLocation)
        }
//        debugPrint("getFixSelectedRange resultRange: \(String(describing: resultRange))")
        return resultRange
    }
}
