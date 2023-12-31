//
//  BTAttributeTextUtil.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/10/11.
//  


import SKFoundation
import SKCommon
import SpaceInterface


struct BTAttributedTextUtil {
    
    /// 查找文本改变区域是不是在独立的连续区域内（例如 at 信息）， 如果删除的是的话需要整块都移除掉。
    static func getIndivisibleAttrRanges(attributedString: NSAttributedString, changedRange: NSRange) -> [NSRange] {
        let range = changedRange
        let enumerationEnd = range.location + range.length
        var indivisibleAttrRanges = [NSRange]()
        var prevRange = NSRange(location: 0, length: 0)
        var prevBTAtModel: BTAtModel?
        attributedString.enumerateAttribute(BTRichTextSegmentModel.attrStringBTAtInfoKey, in: NSRange(location: 0, length: enumerationEnd), options: []) { (attrs, attrRange, _) in
            var augmentedRange = attrRange
            if let attrs = attrs as? BTAtModel {
                if prevBTAtModel == attrs && (prevRange.location + prevRange.length) == augmentedRange.location {
                    augmentedRange = NSRange(location: prevRange.location, length: prevRange.length + augmentedRange.length)
                }
                
                if augmentedRange != attrRange {
                    indivisibleAttrRanges.removeLast()
                }
                
                indivisibleAttrRanges.append(augmentedRange)
                prevRange = augmentedRange
                prevBTAtModel = attrs
            }
        }

        var prevBTEmbeddedImageModel: BTEmbeddedImageModel?
        attributedString.enumerateAttribute(BTRichTextSegmentModel.attrStringBTEmbeddedImageKey, in: NSRange(location: 0, length: enumerationEnd), options: []) { (attrs, attrRange, _) in
            var augmentedRange = attrRange
            if let attrs = attrs as? BTEmbeddedImageModel {
                if prevBTEmbeddedImageModel == attrs && (prevRange.location + prevRange.length) == augmentedRange.location {
                    augmentedRange = NSRange(location: prevRange.location, length: prevRange.length + augmentedRange.length)
                }

                if augmentedRange != attrRange {
                    indivisibleAttrRanges.removeLast()
                }

                indivisibleAttrRanges.append(augmentedRange)
                prevRange = augmentedRange
                prevBTEmbeddedImageModel = attrs
            }
        }
        
        var prevAtModel: AtInfo? //粘贴到textView解析的链接
        attributedString.enumerateAttribute(AtInfo.attributedStringAtInfoKey, in: NSRange(location: 0, length: enumerationEnd), options: []) { (attrs, attrRange, _) in
            var augmentedRange = attrRange
            if let attrs = attrs as? AtInfo {
                if prevAtModel == attrs && (prevRange.location + prevRange.length) == augmentedRange.location {
                    augmentedRange = NSRange(location: prevRange.location, length: prevRange.length + augmentedRange.length)
                }
                
                if augmentedRange != attrRange {
                    indivisibleAttrRanges.removeLast()
                }
                
                indivisibleAttrRanges.append(augmentedRange)
                prevRange = augmentedRange
                prevAtModel = attrs
            }
        }
        return indivisibleAttrRanges
    }
    
    /// 文本选中状态
    static func textViewDidChangeSelection(_ textView: UITextView,
                                           lastTextViewSelectedRange: NSRange,
                                           editable: Bool,
                                           attributedKeys: [NSAttributedString.Key]) -> NSRange {
        guard let attributedString = textView.attributedText else {
            return lastTextViewSelectedRange
        }
        let currentRange = textView.selectedRange
        if lastTextViewSelectedRange.location == currentRange.location { // 相同位置不做处理
            return lastTextViewSelectedRange
        }
        /// 这里的处理是不让光标停留在中间
        if editable {
            // 所有链接类型的 attribute key 见 BTRichTextSegmentModel.linkAttributes
            for key in attributedKeys {
                FixSelectedRangeAdapter.fixSelectedRange(textView: textView,
                                                         lastSelectedRange: lastTextViewSelectedRange,
                                                         currenSelectedRange: currentRange,
                                                         attributedString: attributedString,
                                                         attributedStringKey: key)
            }
        }
        return textView.selectedRange
    }

    /// 判断富文本属性中是否包含某个 token 的 atInfo 信息。
    static func isAttributes(_ attrs: [NSAttributedString.Key: Any], containAtInfoOf token: String) -> Bool {
        guard let atInfo = attrs[BTRichTextSegmentModel.attrStringBTAtInfoKey] as? BTAtModel,
              !atInfo.token.isEmpty else {
            return false
        }
        return token == atInfo.token
    }

}
