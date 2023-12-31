//
//  LKUnOrderedListElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/9/20.
//

import Foundation

public enum UnOrderListType {
    /// 实心圆
    case disc
    /// 空心圆
    case circle
    /// 方块
    case square
    /// 表示没有任何前缀占位
    case none
}

public final class LKUnOrderedListElement: LKBlockElement {
    #if DEBUG
    public override var name: String {
        return "#unOrderedList"
    }
    #endif

    private let ulType: UnOrderListType

    /// children如果为LKOrderedListElement/LKUnOrderedListElement，则children.needOffset = YES
    var needOffset = false

    override var isBlock: Bool {
        if style.display == nil {
            return true
        }
        return super.isBlock
    }

    public init(
        id: String = "",
        tagName: LKRichElementTag,
        classNames: [String] = [],
        ulType: UnOrderListType,
        style: LKRichStyle = LKRichStyle()
    ) {
        self.ulType = ulType
        super.init(id: id, tagName: tagName, classNames: classNames, style: style)
    }

    public override func addChild(_ element: Node) -> Self {
        assertionFailure("please use children")
        super.addChild(element)
        return self
    }

    public override func children(_ elements: [Node]) -> Self {
        let elements = elements.map { item -> Node in
            if let listItem = item as? LKListItemElement {
                listItem.listItemType = .ul(ulType)
            } else if let ul = item as? LKUnOrderedListElement {
                ul.needOffset = true
            } else if let ol = item as? LKOrderedListElement {
                ol.needOffset = true
            } else if !(item is LKBlockElement) {
                // 必须接收 Block 元素，此处套一层防止其他端发来的数据异常
                return LKBlockElement(tagName: tagName).children([item])
            }
            return item
        }
        super.children(elements)
        return self
    }

    public override func copy() -> Any {
        let cloned = LKUnOrderedListElement(
            id: self.id,
            tagName: self.tagName,
            classNames: self.classNames,
            /// swiftlint:disable:next force_cast
            ulType: self.ulType,
            /// swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle
        )
        return copyTo(node: cloned)
    }
// 不需要，保留注释是为了提醒如果有必要需要override此方法。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        let finalStyle = mergeRenderStyle(cssEngine: cssEngine, node: self)
        let renderer = RenderList(nodeType: type, renderStyle: finalStyle, ownerElement: self)
        if needOffset {
            renderer.listRenderType = .listContainer
        }
        subElements.filter { $0.shouldCreateRenderer() }.forEach {
            renderer.appendChild($0.createRenderer(cssEngine: cssEngine))
        }
        return renderer
    }
}
