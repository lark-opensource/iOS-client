//
//  SpanInputHandler.swift
//  Todo
//
//  Created by 张威 on 2021/1/21.
//

class SpanInputHandler: TextViewInputProtocol {

    var onSpanAttrWillRemove: ((_ mutAttrText: MutAttrText, _ range: NSRange) -> MutAttrText)?

    func register(textView: UITextView) {}

    func textViewDidChange(_ textView: UITextView) {}

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let onWillRemove = onSpanAttrWillRemove
        guard let attrText = textView.attributedText else {
            return true
        }

        var targetSpan: AttrText.SpanAttrValue?
        if range.location >= 0 && range.length >= 0 && NSMaxRange(range) < attrText.length {
            targetSpan = attrText.attribute(.span, at: range.location, effectiveRange: nil) as? AttrText.SpanAttrValue
        }

        // 处理删除操作
        if text.isEmpty && range.length > 0 {
            var needRemoveSpan = false
            let fullRange = NSRange(location: 0, length: attrText.length)
            attrText.enumerateAttribute(.span, in: fullRange, options: []) { (value, r, stop) in
                guard let curSpan = value as? AttrText.SpanAttrValue else { return }
                if let targetSpan = targetSpan, targetSpan.identifier != curSpan.identifier {
                    return
                }
                /// 当删除尾部为连续整体时，将一并删除
                if range.location + range.length == r.location + r.length {
                    // 如果是在最后一位删除，需要删除整段文字
                    let selectedRange = textView.selectedRange
                    var newAttrText = MutAttrText(attributedString: attrText)
                    if let onWillRemove = onWillRemove {
                        newAttrText = onWillRemove(newAttrText, r)
                    }
                    newAttrText.deleteCharacters(in: r)
                    textView.attributedText = newAttrText
                    // point代表删除整体后，光标所在的位置
                    var point = selectedRange.location + selectedRange.length - r.length
                    point = point > 0 ? point : 0
                    textView.selectedRange = NSRange(location: point, length: 0)
                    needRemoveSpan = true
                    stop.pointee = true
                } else if NSIntersectionRange(range, r).length > 0 {
                    let selectedRange = textView.selectedRange
                    var newAttrText = MutAttrText(attributedString: attrText)
                    if let onWillRemove = onWillRemove {
                        newAttrText = onWillRemove(newAttrText, r)
                    }
                    newAttrText.removeAttribute(.span, range: r)
                    textView.attributedText = newAttrText
                    textView.selectedRange = selectedRange
                }
            }

            if needRemoveSpan {
                return false
            }
        }

        // 处理输入操作
        if !text.isEmpty {
            let fullRange = NSRange(location: 0, length: attrText.length)
            attrText.enumerateAttribute(.span, in: fullRange, options: []) { (value, r, _) in
                guard let curSpan = value as? AttrText.SpanAttrValue else { return }
                if let targetSpan = targetSpan, targetSpan.identifier != curSpan.identifier {
                    return
                }
                let shouldRemoveSpan: Bool
                if range.length > 0 {
                    shouldRemoveSpan = NSIntersectionRange(range, r).length > 0
                } else {
                    shouldRemoveSpan = r.contains(range.location) && range.location > r.location
                }
                if shouldRemoveSpan {
                    var newAttrText = MutAttrText(attributedString: attrText)
                    if let onWillRemove = onWillRemove {
                        newAttrText = onWillRemove(newAttrText, r)
                    }
                    newAttrText.removeAttribute(.span, range: r)
                    let selectedRange: NSRange = textView.selectedRange
                    textView.attributedText = newAttrText
                    textView.selectedRange = selectedRange
                }
            }
        }
        return true
    }
}
