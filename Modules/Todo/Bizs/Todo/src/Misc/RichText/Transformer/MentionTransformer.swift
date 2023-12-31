//
//  MentionTransformer.swift
//  Todo
//
//  Created by 张威 on 2021/1/24.
//

class MentionTransformer: RichTextTransformProtocol {

    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [AttrText] in
            let mentionProperty = option.element.property.mention
            var content = Utils.RichText.mentionText(from: mentionProperty)
            let mutAttrText = MutAttrText(string: content, attributes: attributes)
            let range = NSRange(location: 0, length: mutAttrText.length)
            let attrValue = AttrText.MentionAttrValue(text: content, mention: mentionProperty)
            mutAttrText.addAttribute(.mention, value: attrValue, range: range)
            return [mutAttrText]
        }
        return [(.mention, process)]
    }

    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let fullRange = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(.mention, in: fullRange, options: []) { (info, range, _) in
            guard let attrValue = info as? AttrText.MentionAttrValue else { return }
            let curText = text.attributedSubstring(from: range).string
            let id = Utils.RichText.randomId()
            let tuple: RichTextParseHelper.RichTextAttrTuple
            if attrValue.text == curText {
                tuple = (Rust.RichText.Element.Tag.a, id, .mention(attrValue.mention), [:])
            } else {
                var textProperty = Rust.RichText.Element.TextProperty()
                textProperty.content = curText
                tuple = (Rust.RichText.Element.Tag.text, id, .text(textProperty), [:])
            }
            result.append(.init(range, [RichTextAttr(priority: .content, tuple: tuple)]))
        }
        return result
    }

}
