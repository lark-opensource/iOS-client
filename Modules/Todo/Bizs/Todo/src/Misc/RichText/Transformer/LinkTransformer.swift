//
//  LinkTransformer.swift
//  Todo
//
//  Created by 张威 on 2021/1/9.
//

class LinkTransformer: RichTextTransformProtocol {

    class AttrValue: NSObject {
        var link: Rust.RichText.Element.LinkProperty
        init(link: Rust.RichText.Element.LinkProperty) {
            self.link = link
            super.init()
        }
    }

    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [AttrText] in
            let linkProperty = option.element.property.link
            if let url = URL(string: linkProperty.url) {
                let wrapper = AttrValue(link: linkProperty)
                return option.results.map { attr -> AttrText in
                    let attr = MutAttrText(attributedString: attr)
                    let range = NSRange(location: 0, length: attr.length)
                    attr.addAttribute(.rtlink, value: wrapper, range: range)
                    return attr
                }
            } else {
                return option.results
            }
        }

        return [(.link, process)]
    }

    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr] {
        return []
    }

}
