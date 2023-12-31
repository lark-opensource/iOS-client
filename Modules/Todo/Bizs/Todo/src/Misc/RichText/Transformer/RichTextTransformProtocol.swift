//
//  RichTextTransformProtocol.swift
//  Todo
//
//  Created by 张威 on 2021/1/11.
//

protocol RichTextTransformProtocol {
    /// richtext 转化 编辑显示的 属性字符串
    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]?

    /// 编辑显示的 属性字符串转化为 richText
    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr]
}
