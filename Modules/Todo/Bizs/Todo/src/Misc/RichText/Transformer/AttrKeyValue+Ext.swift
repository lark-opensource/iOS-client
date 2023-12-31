//
//  AttrKeyValue+Ext.swift
//  Todo
//
//  Created by 张威 on 2021/2/22.
//

extension AttrText.Key {
    // span 对应的内容，是一个编辑整体（即删除时，要整个删除掉）
    static let span = AttrText.Key(rawValue: "lark.todo.richText.span")
    // tap 对应的内容，可点击
    static let tap = AttrText.Key(rawValue: "lark.todo.richText.tap")
    // 对应 RichText 的节点
    static let anchor = AttrText.Key(rawValue: "lark.todo.richText.anchor")
    static let at = AttrText.Key(rawValue: "lark.todo.richText.at")
    static let mention = AttrText.Key(rawValue: "lark.todo.richText.mention")
    static let image = AttrText.Key(rawValue: "lark.todo.richText.image")
    static let media = AttrText.Key(rawValue: "lark.todo.richText.media")

    // 表示 link 标签，实际没有用到
    static let rtlink = AttrText.Key(rawValue: "lark.todo.richText.link")

    // 表示空白 image
    static var emptyImage = AttrText.Key(rawValue: "lark.todo.richText.empty.image")
    // 表示 anchor icon
    static var anchorIcon = AttrText.Key(rawValue: "lark.todo.richText.anchor.icon")
}

extension AttrText {
    typealias AnchorIconAttrValue = RichTextImageTransformInfo
    typealias EmptyImageAttrValue = RichTextImageTransformInfo
    typealias RichIdAttrValue = NSString
}

// MARK: Span

extension AttrText {

    class SpanAttrValue: NSObject {
        var identifier: String
        override init() {
            self.identifier = UUID().uuidString
            super.init()
        }
    }

}

// MARK: Tap

extension AttrText {

    class TapAttrValue: NSObject {
        enum Item {
            case at(Rust.RichText.Element.AtProperty)
            case anchor(Rust.RichText.Element.AnchorProperty)
            case image(Rust.RichText.Element.ImageProperty)
        }
        var item: Item

        init(item: Item) {
            self.item = item
            super.init()
        }
    }

}

// MARK: Anchor

extension AttrText {

    class AnchorAttrValue: NSObject {
        var text: String
        var anchor: Rust.RichText.Element.AnchorProperty
        init(text: String, anchor: Rust.RichText.Element.AnchorProperty) {
            self.text = text
            self.anchor = anchor
            super.init()
        }
    }

}

// MARK: AtUrl

extension AttrText {

    class AtAttrValue: NSObject {
        var text: String
        var at: Rust.RichText.Element.AtProperty
        init(text: String, at: Rust.RichText.Element.AtProperty) {
            self.text = text
            self.at = at
            super.init()
        }
    }

}

// MARK: Mention

extension AttrText {

    class MentionAttrValue: NSObject {
        var text: String
        var mention: Rust.RichText.Element.MentionProperty
        init(text: String, mention: Rust.RichText.Element.MentionProperty) {
            self.text = text
            self.mention = mention
            super.init()
        }
    }

}

// MARK: Image

extension AttrText {

    class ImageAttrValue: NSObject {
        var text: String
        var image: Rust.RichText.Element.ImageProperty
        init(text: String, image: Rust.RichText.Element.ImageProperty) {
            self.text = text
            self.image = image
            super.init()
        }
    }

}

// MARK: Media

extension AttrText {

    class MediaAttrValue: NSObject {
        var text: String
        var media: Rust.RichText.Element.MediaProperty
        init(text: String, media: Rust.RichText.Element.MediaProperty) {
            self.text = text
            self.media = media
            super.init()
        }
    }

}
