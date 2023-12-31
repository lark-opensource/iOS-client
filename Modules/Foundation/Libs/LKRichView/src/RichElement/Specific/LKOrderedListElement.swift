//
//  LKOrderedListElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/9/20.
//

import Foundation

public enum OrderListType {
    /// 数字
    case number
    /// 小写字母
    case lowercaseA
    /// 大写字母
    case uppercaseA
    /// 小写罗马数字
    case lowercaseRoman
    /// 大写罗马数字
    case uppercaseRoman
    /// 表示没有任何前缀占位符
    case none
}

public final class LKOrderedListElement: LKBlockElement {
    #if DEBUG
    public override var name: String {
        return "#orderedList"
    }
    #endif

    private let start: Int
    private let olType: OrderListType

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
        start: Int,
        olType: OrderListType,
        style: LKRichStyle = LKRichStyle()
    ) {
        self.start = start
        self.olType = olType
        super.init(id: id, tagName: tagName, classNames: classNames, style: style)
    }

    public override func addChild(_ element: Node) -> Self {
        assertionFailure("please use children")
        super.addChild(element)
        return self
    }

    @discardableResult
    public override func children(_ elements: [Node]) -> Self {
        var index = self.start
        let elements = elements.map { item -> Node in
            if let listItem = item as? LKListItemElement {
                listItem.listItemType = .ol(olType, getDisplayValue(by: index))
                index += 1
            } else if let ol = item as? LKOrderedListElement {
                ol.needOffset = true
            } else if let ul = item as? LKUnOrderedListElement {
                ul.needOffset = true
            } else if !(item is LKBlockElement) {
                // 必须接收 Blick 元素，此处套一层防止其他端发来的数据异常
                return LKBlockElement(tagName: tagName).children([item])
            }
            return item
        }
        super.children(elements)
        return self
    }

    public override func copy() -> Any {
        let cloned = LKOrderedListElement(
            id: self.id,
            tagName: self.tagName,
            classNames: self.classNames,
            start: self.start,
            olType: self.olType,
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

    private func getDisplayValue(by index: Int) -> String {
        switch olType {
        case .number:
            return String(index)
        case .lowercaseA:
            return index.charNumeralLowercase()
        case .uppercaseA:
            return index.charNumeralUppercase()
        case .lowercaseRoman:
            return index.romanNumeralLowercase()
        case .uppercaseRoman:
            return index.romanNumeralUppercase()
        case .none:
            assertionFailure()
            return ""
        }
    }
}

fileprivate extension Int {
    func romanNumeralUppercase() -> String {
        // 罗马数字不能表示 0 或者 负数
        // 罗马数字超过 3999 以后，就需要加横了，当前场景 3999 够用，直接限制范围
        guard self > 0, self < 4000 else {
            assertionFailure()
            return self <= 0 ? "I" : "MMMCMXCIX"
        }

        let M = ["", "M", "MM", "MMM"]
        let C = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"]
        let X = ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"]
        let I = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
        return M[self / 1000] + C[(self % 1000) / 100] + X[(self % 100) / 10] + I[self % 10]
    }

    func romanNumeralLowercase() -> String {
        guard self > 0, self < 4000 else {
            assertionFailure()
            return self <= 0 ? "i" : "mmmcmxcix"
        }

        let M = ["", "m", "mm", "mmm"]
        let C = ["", "c", "cc", "ccc", "cd", "d", "dc", "dcc", "dccc", "cm"]
        let X = ["", "x", "xx", "xxx", "xl", "l", "lx", "lxx", "lxxx", "xc"]
        let I = ["", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix"]
        return M[self / 1000] + C[(self % 1000) / 100] + X[(self % 100) / 10] + I[self % 10]
    }

    func charNumeralUppercase() -> String {
        guard self > 0 else {
            return "A"
        }

        let chars = [
            "Z",
            "A", "B", "C", "D", "E", "F", "G",
            "H", "I", "J", "K", "L", "M", "N",
            "O", "P", "Q", "R", "S", "T", "U",
            "V", "W", "X", "Y"
        ]
        return chars[self % 26]
    }

    func charNumeralLowercase() -> String {
        guard self > 0 else {
            return "a"
        }

        let chars = [
            "z",
            "a", "b", "c", "d", "e", "f", "g",
            "h", "i", "j", "k", "l", "m", "n",
            "o", "p", "q", "r", "s", "t", "u",
            "v", "w", "x", "y"
        ]
        return chars[self % 26]
    }
}
