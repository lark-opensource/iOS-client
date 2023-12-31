//
//  BlockTransformer.swift
//  Todo
//
//  Created by 张威 on 2021/9/27.
//

class BlockTransformer: RichTextTransformProtocol {

    let tag: Rust.RichText.Element.Tag
    init(tag: Rust.RichText.Element.Tag) {
        #if DEBUG
        let availableTags: Set<Rust.RichText.Element.Tag> = [.p, .figure, .ol, .ul]
        assert(availableTags.contains(tag))
        #endif
        self.tag = tag
    }

    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [AttrText] in
            // 如果末尾已经有换行符了，则不额外添加加换行符
            if let tailStr = option.results.reversed().first(where: { $0.length > 0 })?.string,
               tailStr.hasSuffix("\n") {
                return option.results
            } else {
                return option.results + [AttrText(string: "\n", attributes: attributes)]
            }
        }
        return [(tag, process)]
    }

    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr] {
        return []
    }

    func transformToTextFromRichText() -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        return [(tag, { $0.results })]
    }

}
