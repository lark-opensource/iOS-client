//
//  RenderObject.swift
//  LKRichView
//
//  Created by qihongye on 2019/9/2.
//

import UIKit
import Foundation

enum RenderRunBox {
    case normal(RunBox?)
    case split([RunBox])

    mutating func appendSplitVal(origin: RunBox, lhs: RunBox, rhs: RunBox) {
        switch self {
        case .normal:
            self = .split([lhs, rhs])
        case .split(var list):
            guard !list.isEmpty, let index = list.firstIndex(where: { $0 === origin }) else {
                assertionFailure()
                self = .split([lhs, rhs])
                return
            }

            list[index] = rhs
            list.insert(lhs, at: index)
            self = .split(list)
        }
    }
}

open class RenderObject {
    weak var ownerElement: LKRichElement?

    let nodeType: Node.TypeEnum
    var renderStyle: RenderStyleOM
    var isChildrenInline: Bool {
        var firstRenderElement: RenderObject?
        for child in children {
            if !child.isNeedRender {
                continue
            }
            if firstRenderElement == nil {
                firstRenderElement = child
            }
            if !(child.isRenderInline && child.isRenderBlock) {
                return child.isRenderInline
            }
        }
        return firstRenderElement?.isRenderInline ?? false
    }
    var isChildrenBlock: Bool {
        var firstRenderElement: RenderObject?
        for child in children {
            if !child.isNeedRender {
                continue
            }
            if firstRenderElement == nil {
                firstRenderElement = child
            }
            if !(child.isRenderInline && child.isRenderBlock) {
                return child.isRenderBlock
            }
        }
        return firstRenderElement?.isRenderBlock ?? false
    }
    var shouldAddSubview: Bool {
        nodeType == .element
    }

    var runBox: RenderRunBox = .normal(nil)

    /// 当前RenderObject渲染内容的范围
    var renderContextLocation: Int = 0
    var renderContextLength: Int = 1

    private var _debugOptions: ConfigOptions?
    var debugOptions: ConfigOptions? {
        get {
            if root === self { return _debugOptions }
            return _debugOptions ?? root?.debugOptions
        }
        set {
            _debugOptions = newValue
        }
    }

    // MARK: - Rect variables，runBox = .normal(RunBox)值才可信，否则占用的CGRect为.split([RunBox]).map{ $0.fullLineGlobalRext }

    /// 去掉padding、borderEdge后，实际内容的CGSize
    var contentSize: CGSize = .zero {
        didSet {
            if contentSize != oldValue {
                _contentRect = .null
            }
        }
    }

    var boxOrigin: CGPoint = .zero {
        didSet {
            if boxOrigin != oldValue {
                _contentRect = .null
            }
        }
    }

    /// 去掉padding、borderEdge后，实际内容的CGRect
    var contentRect: CGRect {
        guard _contentRect == .null else {
            return _contentRect
        }
        _contentRect = CGRect(
            origin: CGPoint(
                x: boxOrigin.x + renderStyle.padding.left + (renderStyle.borderEdgeInsets?.left ?? 0),
                y: boxOrigin.y + renderStyle.padding.bottom + (renderStyle.borderEdgeInsets?.bottom ?? 0)
            ),
            size: contentSize
        )
        return _contentRect
    }
    private var _contentRect: CGRect = .null {
        didSet {
            if _contentRect != oldValue {
                _boxRect = .null
            }
        }
    }

    var _linesCount = 0

    /// 标识内容是否可以全部被放下，如果不能被放下，则需要出现scroll
    /// `isContentScroll` will be true when content-size is large than container-size.
    public var isContentScroll = false

    public var boxRect: CGRect {
        guard _boxRect == .null else {
            return _boxRect
        }
        _boxRect = paddingRect
        if let borderInsets = renderStyle.borderEdgeInsets {
            _boxRect = addInCoreTextCoordinate(_boxRect, borderInsets)
        }
        return _boxRect
    }
    private var _boxRect: CGRect = .null

    var paddingRect: CGRect {
        addInCoreTextCoordinate(contentRect, renderStyle.padding)
    }

    // MARK: - tree implement variable

    weak var root: RenderObject?
    weak var parent: RenderObject? {
        didSet {
            renderStyle.parent = parent?.renderStyle
        }
    }
    weak var prevSibling: RenderObject?
    weak var nextSibling: RenderObject?
    private(set) var children = [RenderObject]()

    // MARK: - open variable

    open var isNeedRender: Bool {
        renderStyle.storage.display.value != Display.none
    }
    open var isRenderFloat: Bool {
        false
    }

    open var isRenderInline: Bool {
        guard isNeedRender else {
            return false
        }
        if let display = renderStyle.storage.display.value,
           display == .inline || display == .inlineBlock {
            return true
        }
        return false
    }

    open var isRenderBlock: Bool {
        guard isNeedRender else {
            return false
        }
        if let display = renderStyle.storage.display.value,
           display == .block || display == .inlineBlock {
            return true
        }
        return false
    }

    /// - description  The entire lines count of all children.
    open var linesCount: Int {
        return _linesCount
    }

    init(nodeType: Node.TypeEnum, renderStyle: LKRenderRichStyle, ownerElement: LKRichElement?) {
        self.nodeType = nodeType
        self.renderStyle = RenderStyleOM(renderStyle)
        self.ownerElement = ownerElement
    }

    open func paint(_ paintInfo: PaintInfo) { }

    open func layout(_ size: CGSize, context: LayoutContext?) -> CGSize { .zero }

    public func appendChild(_ child: RenderObject) {
        if isRenderBlock {
            if !isChildrenInline, !isChildrenBlock {
                return _appendChild(child)
            }
            if isChildrenBlock, child.isRenderBlock {
                return _appendChild(child)
            }
            if isChildrenInline, child.isRenderInline {
                return _appendChild(child)
            }
        }
        if isRenderInline, child.isRenderInline {
            return _appendChild(child)
        }
    }

    public func removeChild(idx: Int) {
        guard idx >= 0, idx < children.count else { return }
        let removedElement = children.remove(at: idx)
        removedElement.parent = nil
        removedElement.prevSibling = nil
        removedElement.nextSibling = nil
    }

    func render(_ paintInfo: PaintInfo) {
        guard isNeedRender else { return }
        paint(paintInfo)
    }

    private func _appendChild(_ child: RenderObject) {
        child.parent = self
        if let last = children.last {
            last.nextSibling = child
            child.prevSibling = last
        }
        children.append(child)
    }

// MARK: - findRenderObject

    func point(inside point: CGPoint) -> Bool {
        switch runBox {
        case .normal(let runbox):
            if let rb = runbox, rb.globalRect.contains(point) {
                return true
            }
        case .split(let runboxs):
            for runbox in runboxs where runbox.globalRect.contains(point) {
                return true
            }
        }
        return false
    }

    func findRenderObjectByDFS(walker: (RenderObject) -> Bool) -> RenderObject? {
        for child in children {
            if let target = child.findRenderObjectByDFS(walker: walker) {
                return target
            }
        }
        return walker(self) ? self : nil
    }

    func findRenderObjectByBFS(walker: (RenderObject) -> Bool) -> RenderObject? {
        var queue = [self]
        var index = 0
        while index < queue.count {
            let head = queue[index]
            index += 1
            if walker(head) {
                return head
            }
            queue.append(contentsOf: head.children)
        }
        return nil
    }

// MARK: - 定位节点

    // 这里应该被性能优化，可以用四叉树来做。
    func findLeafNode(by point: CGPoint) -> RunBox? {
        // 没有 Children，则自身为叶子节点，直接返回
        guard !children.isEmpty else {
            switch runBox {
            case .normal(let runbox):
                return runbox
            case .split(let boxs):
                if let box = boxs.first(where: { $0.globalRect.contains(point) }) {
                    return box
                }
                return nil
            }
        }

        // 有 children，则直接向 children 继续递归
        for child in children {
            switch child.runBox {
            case .normal(let runbox):
                if let box = runbox, box.globalRect.contains(point) {
                    if child.renderStyle.isBlockSelection {
                        return box
                    }
                    return child.findLeafNode(by: point)
                }
            case .split(let boxs):
                if boxs.contains(where: { $0.globalRect.contains(point) }) {
                    return child.findLeafNode(by: point)
                }
            }
        }

        /// 有 children，但 point 没有被 Children 捕获，而是落在了某个空白地方（可能是 Border、Margin、Padding 等）
        /// 需要寻找这个 Point 最近的元素（不是实际意义上的最近，而是行优先，其次是列）

        var point = point
        switch runBox {
        case .normal(let runbox):
            func getLineInfo() -> (lineRect: CGRect, subRunBoxs: [RunBox], runBox: RunBox)? {
                guard let runbox = runbox, let box = runbox as? ContainerRunBox else {
                    return nil
                }
                let lineInfos = box.selectionLineInfo()
                if lineInfos.isEmpty {
                    return nil
                }
                if lineInfos.count == 1 {
                    return (box.globalRect, lineInfos[0].subRunBoxs, runbox)
                }
                for index in 1..<lineInfos.count {
                    let preLine = lineInfos[index - 1]
                    let line = lineInfos[index]

                    if index == 1 && point.y >= preLine.lineRect.minY {
                        return preLine
                    }
                    if index == lineInfos.count - 1 && point.y <= line.lineRect.maxY {
                        return line
                    }

                    if preLine.lineRect.containsY(point) {
                        return preLine
                    }
                    if line.lineRect.containsY(point) {
                        return line
                    }

                    if point.y <= preLine.lineRect.minY && point.y >= line.lineRect.maxY {
                        if preLine.lineRect.minY - point.y <= point.y - line.lineRect.maxY {
                            point.y = preLine.lineRect.minY
                            return preLine
                        } else {
                            point.y = line.lineRect.maxY
                            return line
                        }
                    }
                }
                return nil
            }

            guard let info = getLineInfo() else {
                return runbox
            }
            let resBox = info.subRunBoxs.first(where: { $0.globalRect.containsX(point) })
            if let renderer = resBox?.ownerRenderObject, let box = renderer.findLeafNode(by: point) {
                return box
            }
            if let resBox = resBox {
                return resBox
            }
            /// horizon line only, expect vertical line
            if point.x > info.runBox.fullLineGlobalRect.centerX {
                // 距离边界很近才会选择容器元素
                if point.x >= info.runBox.fullLineGlobalRect.maxX - 1 {
                    return info.runBox
                }
                return info.subRunBoxs.last ?? info.runBox
            }
            if point.x <= info.runBox.fullLineGlobalRect.minX + 1 {
                return info.runBox
            }
            return info.subRunBoxs.first ?? info.runBox
        case .split(let boxs):
            return boxs.first { $0.fullLineGlobalRect.containsNearly(point) } ?? boxs.last
        }
    }
}

extension RenderObject: Hashable {
    public static func == (lhs: RenderObject, rhs: RenderObject) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

public protocol PaintInfoHostView: UIView {
    func commitDisplayTask(task: @escaping (UIView) -> Void)
}

public final class PaintInfo {

    let debugOptions: ConfigOptions?

    public let graphicsContext: CGContext

    public let contextRect: CGRect

    weak var hostView: PaintInfoHostView?

    init(context: CGContext, rect: CGRect, hostView: PaintInfoHostView?, debugOptions: ConfigOptions?) {
        graphicsContext = context
        contextRect = rect
        self.hostView = hostView
        self.debugOptions = debugOptions
    }

    public func addSubView(renderObject: RenderObject, _ viewProvider: @escaping () -> UIView) {
        guard renderObject.shouldAddSubview else { return }
        let contextRect = self.contextRect
        let renderObjectID = ObjectIdentifier(renderObject).hashValue
        hostView?.commitDisplayTask { hostView in
            let oldView = hostView.subviews.first(where: { $0.attachmentID == renderObjectID })
            guard oldView == nil else {
                oldView?.frame.origin = renderObject.boxRect
                    .convertCoreText2UIViewCoordinate(contextRect).origin
                oldView?.isValid = true
                oldView?.isHidden = false
                return
            }
            // renderObject use coretext coordinate, so convert to uiview coordinate
            let view = viewProvider()
            view.isValid = true
            view.isHidden = false
            if !hostView.subviews.contains(view) {
                hostView.addSubview(view)
            }
            view.frame.origin = renderObject.boxRect
                .convertCoreText2UIViewCoordinate(contextRect).origin
        }
    }
}

func isNumbericDefinited(_ value: LKRichStyleValue<CGFloat>) -> Bool {
    switch value.type {
    case .em, .percent, .point, .value: return true
    case .inherit, .auto, .unset: return false
    }
}

@inline(__always)
func addInCoreTextCoordinate(_ rect: CGRect, _ insets: UIEdgeInsets) -> CGRect {
    return CGRect(
        x: rect.origin.x - insets.left, y: rect.origin.y - insets.bottom,
        width: rect.width + insets.left + insets.right,
        height: rect.height + insets.top + insets.bottom
    )
}
