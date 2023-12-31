//
//  AnchorTransformer.swift
//  Todo
//
//  Created by 张威 on 2021/1/9.
//

// Anchor 标签
// ┌──────────────────┐
// | icon │   title   |
// └──────────────────┘  渲染的元素
// --------------------------------
//        └── anchor ─┘  挂载的 attr
// └─── tap, span ────┘

class AnchorTransformer: RichTextTransformProtocol {

    typealias Extra = InputController.AnchorExtra

    var extraGetter: ((_ anchor: Rust.RichText.Element.AnchorProperty) -> Extra?)?
    var iconTextGetter: ((_ extra: Extra, _ attrs: [AttrText.Key: Any]) -> MutAttrText)?

    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { [weak self] option -> [AttrText] in
            let anchor = option.element.property.anchor
            var extra: Extra?
            var iconGetter: ((Extra) -> MutAttrText)?
            if let e = self?.extraGetter?(anchor) {
                extra = e
                if let attrText = self?.iconTextGetter?(e, attributes) {
                    iconGetter = { _ in attrText }
                }
            }
            let ret = Self.makeAttrText(
                with: anchor,
                extra: extra,
                iconGetter: iconGetter,
                attrs: attributes
            )
            return [ret]
        }

        return [(.a, process)]
    }

    static func makeAttrText(
        with anchor: Rust.RichText.Element.AnchorProperty,
        extra: Extra?,
        iconGetter: ((Extra) -> MutAttrText)?,
        attrs: [AttrText.Key: Any]
    ) -> MutAttrText {
        var iconText: MutAttrText?
        if let extra = extra, let iconGetter = iconGetter {
            iconText = iconGetter(extra)
        }
        let titleText = MutAttrText(string: plainText(from: anchor, with: extra), attributes: attrs)
        titleText.addAttributes(
            [
                .anchor: AttrText.AnchorAttrValue(text: titleText.string, anchor: anchor),
                .foregroundColor: UIColor.ud.textLinkNormal
            ],
            range: NSRange(location: 0, length: titleText.length)
        )
        let totalText: MutAttrText
        if let iconText = iconText {
            totalText = iconText
            totalText.append(titleText)
        } else {
            totalText = titleText
        }
        totalText.addAttributes(
            [
                .tap: AttrText.TapAttrValue(item: .anchor(anchor)),
                .span: AttrText.SpanAttrValue()
            ],
            range: NSRange(location: 0, length: totalText.length)
        )
        return totalText
    }

    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let fullRange = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(.anchor, in: fullRange, options: []) { (info, range, _) in
            guard let attrValue = info as? AttrText.AnchorAttrValue else { return }
            let curText = text.attributedSubstring(from: range).string
            let id = Utils.RichText.randomId()
            let tuple: RichTextParseHelper.RichTextAttrTuple
            if attrValue.text == curText {
                tuple = (Rust.RichText.Element.Tag.a, id, .a(attrValue.anchor), [:])
            } else {
                Detail.assertionFailure("逻辑异常；anchor 结构被破坏了，退化为 text")
                var textProperty = Rust.RichText.Element.TextProperty()
                textProperty.content = curText
                tuple = (Rust.RichText.Element.Tag.text, id, .text(textProperty), [:])
            }
            result.append(.init(range, [RichTextAttr(priority: .content, tuple: tuple)]))
        }
        return result
    }

    private static func plainText(
        from property: Rust.RichText.Element.AnchorProperty,
        with extra: Extra?
    ) -> String {
        var content = property.textContent.isEmpty ? property.content : property.textContent
        if content.isEmpty {
            content = property.href
        }
        switch extra {
        case .hangEntity(let hangEntity):
            if !hangEntity.serverTitle.isEmpty {
                content = hangEntity.serverTitle
            } else if !hangEntity.sdkTitle.isEmpty {
                content = hangEntity.sdkTitle
            }
        case .hangPoint, .none:
            break
        }
        return content
    }

}
