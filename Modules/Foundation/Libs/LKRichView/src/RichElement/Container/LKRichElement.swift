//
//  LKRichElement.swift
//  LKRichView
//
//  Created by qihongye on 2019/8/27.
//

import Foundation
import UIKit

open class LKRichElement: Node {
    #if DEBUG
    public override var name: String {
        return "#Element"
    }
    #endif

    public let tagName: LKRichElementTag
    public override var tag: Int8 {
        tagName.typeID
    }

    public init(
        id: String = "",
        tagName: LKRichElementTag,
        classNames: [String] = [],
        style: LKRichStyle = LKRichStyle()
    ) {
        self.tagName = tagName
        super.init(id: id, classNames: classNames, style: style)
    }

    public override func copy() -> Any {
        let cloned = LKRichElement(
            id: self.id,
            tagName: self.tagName,
            classNames: self.classNames,
            // swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle
        )
        return copyTo(node: cloned)
    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        let finalStyle = mergeRenderStyle(cssEngine: cssEngine, node: self)

        guard let display = finalStyle.display.value else {
            return RenderObject(nodeType: type, renderStyle: finalStyle, ownerElement: self)
        }
        switch display {
        case .inlineBlock:
            let renderer = RenderInlineBlock(nodeType: type, renderStyle: finalStyle, ownerElement: self)
            subElements.filter { $0.shouldCreateRenderer() }.forEach {
                renderer.appendChild($0.createRenderer(cssEngine: cssEngine))
            }
            return renderer
        case .inline:
            let renderer = RenderInline(nodeType: type, renderStyle: finalStyle, ownerElement: self)
            subElements.filter { $0.shouldCreateRenderer() && $0.isInline }.forEach {
                renderer.appendChild($0.createRenderer(cssEngine: cssEngine))
            }
            return renderer
        case .block:
            let renderer = RenderBlock(nodeType: type, renderStyle: finalStyle, ownerElement: self)
            subElements.filter { $0.shouldCreateRenderer() }.forEach {
                renderer.appendChild($0.createRenderer(cssEngine: cssEngine))
            }
            return renderer
        case .none:
            return RenderObject(nodeType: type, renderStyle: finalStyle, ownerElement: self)
        }
    }
}

open class Node: LKCopying {
    public let id: String
    public var classNames: [String] {
        didSet {
            classNameSet = Set(classNames)
        }
    }
    private var classNameSet: Set<String>
    public private(set) var style: LKRichStyle

    public var type: TypeEnum {
        subElements.isEmpty ? .element : .container
    }
    var isInline: Bool {
        style.display == .inline || style.display == .inlineBlock
    }
    var isBlock: Bool {
        style.display == .block || style.display == .inlineBlock
    }
    public var tag: Int8 {
        assertionFailure("Must be overrided.")
        return 0
    }

    /// 用于 copy/paste 时，本 Element 给出的降级文案
    public var defaultString = ""

    // MARK: - tree implement variable

    public weak var parent: Node?
    public weak var prevSibling: Node?
    public weak var nextSibling: Node?
    public private(set) var subElements: [Node] = []

    var indexWithinParent: Int = 0

    // MARK: - debug

    #if DEBUG
    public var name: String {
        "#node"
    }
    #endif
    var debugOptions: ConfigOptions?

    open var defaultStyleProperties: StyleProperties {
        return StyleProperties([])
    }

    public init(
        id: String,
        classNames: [String],
        style: LKRichStyle = LKRichStyle()
    ) {
        self.id = id
        self.classNames = classNames
        self.classNameSet = Set(classNames)
        self.style = style
    }

    @discardableResult
    public func style(_ style: LKRichStyle) -> Self {
        self.style = style
        return self
    }

    @discardableResult
    open func addChild(_ child: Node) -> Self {
        child.parent = self
        if let last = subElements.last {
            last.nextSibling = child
            child.prevSibling = subElements.last
        }
        subElements.append(child)
        return self
    }

    @discardableResult
    open func children(_ elements: [Node]) -> Self {
        subElements = elements
        var prev: Node?
        for subElement in subElements {
            subElement.prevSibling = prev
            prev?.nextSibling = subElement
            subElement.parent = self
            prev = subElement
        }
        subElements.last?.nextSibling = nil
        return self
    }

    open func removeFromParent() {
        parent?.remove(self)
    }

    @discardableResult
    open func remove(_ element: Node) -> Bool {
        if subElements.contains(where: { $0 === element }) {
            let pre = element.prevSibling
            let next = element.nextSibling
            pre?.nextSibling = next
            next?.prevSibling = pre
            subElements.removeAll(where: { $0 === element })
            return true
        }
        return false
    }

    open func shouldCreateRenderer() -> Bool {
        assertionFailure("Must be overrided!")
        return false
    }

    open func prun() {
        let tmpParent = parent
        removeFromParent()
        let parentSub = tmpParent?.subElements ?? []
        if parentSub.isEmpty {
            tmpParent?.prun()
        }
    }

    open func getLeafNodesByOrder() -> [Node] {
        if subElements.isEmpty {
            return [self]
        }
        return subElements.flatMap({ $0.getLeafNodesByOrder() })
    }

    @inline(__always)
    public func hasClassName(_ className: String) -> Bool {
        return classNameSet.contains(className)
    }

    func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        assertionFailure("Must be overrided!")
        return RenderObject(nodeType: type, renderStyle: style.storage, ownerElement: nil)
    }

    func getDefaultString() -> NSMutableAttributedString {
        let res = NSMutableAttributedString()
        for element in subElements {
            res.append(element.getDefaultString())
        }
        if res.string.isEmpty {
            return attachCopyPasteStyle(with: defaultString)
        }
        return res
    }

    func defaultStringAttributes() -> [NSAttributedString.Key: Any] {
        return [:]
    }

    func attachCopyPasteStyle(with text: String) -> NSMutableAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [:]
        /// All `defaultStringAttributes` of parents should be caclulated.
        var allDefaultAttrsNodes: [Node] = [self]
        while let node = allDefaultAttrsNodes.last?.parent {
            allDefaultAttrsNodes.append(node)
        }
        while let node = allDefaultAttrsNodes.popLast() {
            let attrs = node.defaultStringAttributes()
            if !attrs.isEmpty {
                attributes.merge(attrs, uniquingKeysWith: { $1 })
            }
        }
        if style.fontStyle == .italic {
            attributes[NSAttributedString.Key(rawValue: "italic")] = "italic"
        }
        if style.fontWeight == .bold {
            attributes[NSAttributedString.Key(rawValue: "bold")] = "bold"
        }
        if let line = style.textDecoration?.line {
            if line.contains(.lineThrough) {
                attributes[NSAttributedString.Key(rawValue: "strikethrough")] = NSNumber(value: NSUnderlineStyle.single.rawValue)
            }
            if line.contains(.underline) {
                attributes[NSAttributedString.Key(rawValue: "underline")] = NSNumber(value: NSUnderlineStyle.single.rawValue)
            }
        }
        return NSMutableAttributedString(string: text, attributes: attributes)
    }

    func copyTo(node: Node) -> Node {
        node.debugOptions = self.debugOptions
        node.defaultString = self.defaultString
        node.indexWithinParent = self.indexWithinParent
        return node
    }

    open func copy() -> Any {
        if let style = style.copy() as? LKRichStyle {
            return copyTo(node: Node(id: id, classNames: classNames, style: style))
        }
        return copyTo(node: Node(id: id, classNames: classNames))
    }
}

extension Node {
    public enum TypeEnum: Int8 {
        /// 叶子节点类型，属于占位节点，依托于外部处理
        case element
        /// 叶子节点类型，只有文本需要处理
        case text
        /// 叶子节点类型，依托于外部实现绘制逻辑
        case canvas
        /// 容器节点类型
        case container
    }
}

public protocol LKRichElementTag {
    var typeID: Int8 { get }
}

enum PrivateTags: Int8, LKRichElementTag {
    case text = -1
    case img = -2
    case attachment = -3

    public var typeID: Int8 {
        return rawValue
    }
}

@inline(__always)
func mergeRenderStyle<E: Node>(cssEngine: CSSStyleEngine?, node: E) -> LKRenderRichStyle {
    guard let cssEngine = cssEngine else {
        node.defaultStyleProperties.applyToRenderStyle(node)
        return node.style.storage
    }
    return cssEngine.createRenderStyle(node: node)
}
