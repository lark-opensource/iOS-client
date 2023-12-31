//
//  LKListItemElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/9/24.
//

import UIKit
import Foundation

public enum ListItemType {
    case ol(OrderListType, String)
    case ul(UnOrderListType)
}

public final class LKListItemElement: LKBlockElement {
    #if DEBUG
    public override var name: String {
        return "#orderedList"
    }
    #endif

    public var listItemType: ListItemType? {
        didSet {
            guard let type = listItemType else { return }
            let textElement: LKTextElement

            switch type {
            case .ol(_, let value):
                textElement = LKTextElement(text: "\(value).")
                textElement
                    .style(LKRichStyle()
                            .font(UIFont(name: "Helvetica Neue", size: 14) ?? .systemFont(ofSize: 14))
                            .fontSize(.point(olIconSize))
                            .color(iconColor)
                    )
            case .ul(let ulType):
                switch ulType {
                case .disc:
                    textElement = LKTextElement(text: "●")
                case .circle:
                    textElement = LKTextElement(text: "○")
                case .square:
                    textElement = LKTextElement(text: "■")
                case .none:
                    assertionFailure()
                    textElement = LKTextElement(text: "")
                }
                textElement
                    .style(LKRichStyle()
                            .font(UIFont(name: "PingFangSC-Reqular", size: 14) ?? .systemFont(ofSize: 14))
                            .fontSize(.point(ulIconSize))
                            .color(iconColor)
                    )
            }

            liIconElement = textElement
        }
    }

    private let iconColor: UIColor
    private let ulIconSize: CGFloat
    private let olIconSize: CGFloat

    private var liIconElement: LKTextElement?

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
        style: LKRichStyle = LKRichStyle(),
        iconColor: UIColor = UIColor.blue,
        ulIconSize: CGFloat = 8,
        olIconSize: CGFloat = 17
    ) {
        self.iconColor = iconColor
        self.ulIconSize = ulIconSize
        self.olIconSize = olIconSize
        super.init(id: id, tagName: tagName, classNames: classNames, style: style)
    }

    public override func copy() -> Any {
        let cloned = LKListItemElement(
            id: self.id,
            tagName: self.tagName,
            classNames: self.classNames,
            /// swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle,
            /// swiftlint:disable:next force_cast
            iconColor: self.iconColor.copy() as! UIColor,
            ulIconSize: self.ulIconSize,
            olIconSize: self.olIconSize
        )
        return copyTo(node: cloned)
    }
// 不需要，保留注释是为了提醒如果有必要需要override此方法。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        if subElements.isEmpty {
            // TODO: @byt 对于空 Li 标签的处理，需要找一个更合适的方法
            addChild(LKTextElement(text: " "))
        }

        let finalStyle = mergeRenderStyle(cssEngine: cssEngine, node: self)
        let renderer = RenderList(nodeType: type, renderStyle: finalStyle, ownerElement: self)
        if let element = liIconElement {
            renderer.listRenderType = .listItem(renderer: element.createRenderer(cssEngine: cssEngine))
            renderer.listItemType = listItemType
        }
        subElements.filter { $0.shouldCreateRenderer() }.forEach {
            renderer.appendChild($0.createRenderer(cssEngine: cssEngine))
        }
        return renderer
    }

    override func getDefaultString() -> NSMutableAttributedString {
        let attr = super.getDefaultString()
        switch listItemType {
        case .ol(_, let value):
            let res = attachCopyPasteStyle(with: "\(value). ")
            res.append(attr)
            return res
        case .ul:
            let res = attachCopyPasteStyle(with: "- ")
            res.append(attr)
            return res
        case .none:
            return attr
        }
    }
}
