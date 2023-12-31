//
//  AtTransformer.swift
//  Todo
//
//  Created by 张威 on 2021/1/9.
//

import LarkRichTextCore

// At 标签
// ┌─────────────────┐
// │      title      |
// └─────────────────┘  渲染的元素
// --------------------------------
// └─ at, tap, span ─┘  挂载的 attr
import LarkBaseKeyboard
class AtTransformer: RichTextTransformProtocol {

    static func makeAttrText(from user: User, isOuter: Bool, with attrs: [AttrText.Key: Any]) -> MutAttrText {
        var atProperty = Rust.RichText.Element.AtProperty()
        atProperty.content = user.name
        atProperty.userID = user.chatterId
        atProperty.isOuter = isOuter
        return innerMakeAttrText(from: atProperty, with: attrs)
    }

    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [AttrText] in
            return [Self.innerMakeAttrText(from: option.element.property.at, with: attributes)]
        }
        return [(.at, process)]
    }

    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let fullRange = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(.at, in: fullRange, options: []) { (info, range, _) in
            guard let attrValue = info as? AttrText.AtAttrValue else { return }
            let curText = text.attributedSubstring(from: range).string
            let id = Utils.RichText.randomId()
            let tuple: RichTextParseHelper.RichTextAttrTuple
            if attrValue.text == curText {
                tuple = (Rust.RichText.Element.Tag.at, id, .at(attrValue.at), [:])
            } else {
                var textProperty = Rust.RichText.Element.TextProperty()
                textProperty.content = curText
                tuple = (Rust.RichText.Element.Tag.text, id, .text(textProperty), [:])
            }
            result.append(.init(range, [RichTextAttr(priority: .content, tuple: tuple)]))
        }
        return result
    }

    private static func innerMakeAttrText(
        from atProperty: Rust.RichText.Element.AtProperty,
        with attrs: [AttrText.Key: Any]
    ) -> MutAttrText {
        let content = Utils.RichText.atText(from: atProperty)
        let titleText = MutAttrText(string: content, attributes: attrs)
        titleText.addAttributes(
            [
                .at: AttrText.AtAttrValue(text: content, at: atProperty),
                .tap: AttrText.TapAttrValue(item: .at(atProperty)),
                .span: AttrText.SpanAttrValue()
            ],
            range: NSRange(location: 0, length: titleText.length)
        )
        return titleText
    }

}

class ImageTransformer: RichTextTransformProtocol {

    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let element = option.element
            let originKey = element.property.image.originKey
            let imageSize = CGSize(width: CGFloat(element.property.image.originWidth), height: CGFloat(element.property.image.originHeight))
            let type = element.property.image.urls.compactMap({ ImageTransformType(rawValue: $0) }).first ?? .remote

            let imageKey: String = originKey
            let localKey: String = originKey

            let image = UIImage()
            var thumbKey: String?
            /// 除了复制的图片，其他场景的都可以在本地找到原图，所以所以复制场景传入thumbKey，降低资源的消耗
            if element.property.image.needCopy {
                thumbKey = element.property.image.thumbKey
            }
            let resizedSize = CGSize(width: Int(element.property.image.width), height: Int(element.property.image.height))
            let attr = LarkBaseKeyboard.ImageTransformer.transformContentToString((imageKey, nil, localKey, thumbKey, imageSize, type, image, UIScreen.main.bounds.width, element.property.image.isOriginSource, element.property.image.needCopy, resizedSize, element.property.image.resourcePreviewToken), attributes: attributes)
            let text = MutAttrText(attributedString: attr)
            text.addAttributes(
                [
                    .tap: AttrText.TapAttrValue(item: .image(element.property.image)),
                    .span: AttrText.SpanAttrValue()
                ],
                range: NSRange(location: 0, length: attr.length)
            )
            return [text]
        }
        return [(.img, process)]
    }

    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let figurePriority: RichTextAttrPriority = .high
        let imagePriority: RichTextAttrPriority = .content

        text.enumerateAttribute(LarkBaseKeyboard.ImageTransformer.RemoteImageAttachmentAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (value, range, _) in
            if let info = value as? ImageTransformInfo {
                let imageId = InputUtil.randomId()
                var imageProperty = Rust.RichText.Element.ImageProperty()
                let originKey = info.key.isEmpty ? info.localKey : info.key
                imageProperty.token = originKey
                imageProperty.thumbKey = info.thumbKey ?? originKey
                imageProperty.middleKey = info.thumbKey ?? originKey
                imageProperty.originKey = originKey
                imageProperty.originWidth = Int32(info.imageSize.width)
                imageProperty.originHeight = Int32(info.imageSize.height)
                imageProperty.urls = [info.type.rawValue]
                imageProperty.isOriginSource = info.useOrigin
                imageProperty.needCopy = info.fromCopy
                imageProperty.width = UInt32(info.resizedImageSize?.width ?? 0)
                imageProperty.height = UInt32(info.resizedImageSize?.height ?? 0)
                let imageTuple: RichTextParseHelper.RichTextAttrTuple = (Rust.RichText.Element.Tag.img, imageId, .img(imageProperty), nil)
                let imageAttr = RichTextAttr(priority: imagePriority, tuple: imageTuple)

                let fId = InputUtil.randomId()
                let figureProperty = Rust.RichText.Element.FigureProperty()
                let figureTuple: RichTextParseHelper.RichTextAttrTuple = (Rust.RichText.Element.Tag.figure, fId, .figure(figureProperty), nil)
                let figureAttr = RichTextAttr(priority: figurePriority, tuple: figureTuple)

                result.append(RichTextFragmentAttr(range, [figureAttr, imageAttr]))
            }
        }
        return result
    }
}

class MediaTransformer: RichTextTransformProtocol {

    func transformFromRichText(
        attributes: [AttrText.Key: Any],
        attachmentResult: [String: String]
    ) -> [(Rust.RichText.Element.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [AttrText] in
            return [Self.innerMakeAttrText(from: option.element.property.media, with: attributes)]
        }
        return [(.media, process)]
    }

    func transformToRichText(_ text: AttrText) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let fullRange = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(.image, in: fullRange, options: []) { (info, range, _) in
            guard let attrValue = info as? AttrText.MediaAttrValue else { return }
            let curText = text.attributedSubstring(from: range).string
            let id = Utils.RichText.randomId()
            let tuple: RichTextParseHelper.RichTextAttrTuple
            if attrValue.text == curText {
                tuple = (Rust.RichText.Element.Tag.media, id, .media(attrValue.media), [:])
            } else {
                var textProperty = Rust.RichText.Element.TextProperty()
                textProperty.content = curText
                tuple = (Rust.RichText.Element.Tag.text, id, .text(textProperty), [:])
            }
            result.append(.init(range, [RichTextAttr(priority: .content, tuple: tuple)]))
        }
        return result
    }

    private static func innerMakeAttrText(
        from mediaProperty: Rust.RichText.Element.MediaProperty,
        with attrs: [AttrText.Key: Any]
    ) -> MutAttrText {
        let content = I18N.Lark_Legacy_MessagePoVideo
        let mutAttrText = MutAttrText(string: content, attributes: attrs)
        mutAttrText.addAttributes(
            [
                .image: AttrText.MediaAttrValue(text: content, media: mediaProperty),
                .foregroundColor: UIColor.ud.textCaption,
                .span: AttrText.SpanAttrValue()
            ],
            range: NSRange(location: 0, length: mutAttrText.length)
        )
        return mutAttrText
    }

}
