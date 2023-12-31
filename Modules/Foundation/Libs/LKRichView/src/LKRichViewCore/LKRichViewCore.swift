//
//  LKRichViewCore.swift
//  LKRichView
//
//  Created by qihongye on 2020/1/21.
//

import UIKit
import Foundation

public struct LayoutContext {
    public let lineCamp: LineCamp?

    public init(lineCamp: LineCamp?) {
        self.lineCamp = lineCamp
    }
}

public final class LKRichViewCore {
    private var cssEngine: CSSStyleEngine?
    private var renderer: RenderObject?
    private var rwlock = pthread_rwlock_t()
    private var commonAncestorDic: [RenderObject: RenderObject] = [:]

    public var isLayoutFinished = false

    // 选区相关缓存值
    private var startTuple: (box: RunBox, index: Int)?
    private var endTuple: (box: RunBox, index: Int)?
    private var commonAncestor: RenderObject?
    private var globalStartIndex: Int?
    private var globalEndIndex: Int?

    // 分片缓存是否合法
    public var isTiledCacheValid = true

    /// 标识内容是否可以全部被放下，如果不能被放下，则需要出现scroll
    /// `isContentScroll` will be true when content-size is large than container-size.
    public private(set) var isContentScroll = false

    public var isRendererReady: Bool {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        return renderer != nil
    }

    public var size: CGSize {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        return renderer?.boxRect.size ?? .zero
    }

    public init(_ renderer: RenderObject? = nil, styleSheets: [CSSStyleSheet] = []) {
        self.cssEngine = CSSStyleEngine(styleSheets)
        self.renderer = renderer
        pthread_rwlock_init(&rwlock, nil)
    }

    public func getRenderer<T>(_ flatMap: @escaping (RenderObject) -> T) -> T? {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        guard let renderer = renderer else {
            return nil
        }
        return flatMap(renderer)
    }

    @discardableResult
    public func createRenderer(_ element: Node) -> RenderObject? {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        if element.shouldCreateRenderer() {
            let renderer = element.createRenderer(cssEngine: cssEngine)
            setRootForChildren(root: renderer)
            return renderer
        }
        return nil
    }

    public func load(renderer: RenderObject?) {
        pthread_rwlock_wrlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        self.renderer = renderer
        self.isLayoutFinished = false
    }

    public func load(styleSheets: [CSSStyleSheet]) {
        pthread_rwlock_wrlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        if cssEngine == nil {
            cssEngine = CSSStyleEngine(styleSheets)
            return
        }
        for sheet in styleSheets {
            cssEngine?.load(sheet: sheet)
        }
    }

    public func setRendererDebugOptions(_ debugOptions: ConfigOptions?) {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        renderer?.debugOptions = debugOptions
    }

    public func layout(_ size: CGSize) -> CGSize? {
        pthread_rwlock_wrlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        guard let renderer = renderer else {
            return nil
        }
        // 用RenderObject树生成一颗RunBox树，进行布局计算
        let size = renderer.layout(size, context: nil)
        self.isContentScroll = renderer.isContentScroll
        self.isLayoutFinished = true
        return size
    }

    func render(_ paintInfo: PaintInfo) {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        renderer?.render(paintInfo)
    }

    func getRenderRunBoxs() -> [RunBox] {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        guard let runBox = renderer?.runBox else { return [] }
        switch runBox {
        case .normal(let unwrapped):
            if let unwrapped = unwrapped { return [unwrapped] }
        case .split(let splits):
            return splits
        }
        return []
    }
}

extension LKRichViewCore {
    public func findElement(by tag: LKRichElementTag) -> [(element: LKRichElement, rect: CGRect)] {
        guard let renderer = renderer else {
            return []
        }
        var res = [(element: LKRichElement, rect: CGRect)]()

        // dfs
        var stack: [RenderObject] = [renderer]
        while let node = stack.popLast() {
            stack += node.children.reversed()

            if !(node is RenderText),
                let element = node.ownerElement,
                element.tagName.typeID == tag.typeID {
                res.append((element, node.boxRect))
            }
        }
        return res
    }

    public func findRender(by point: CGPoint) -> RenderObject? {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        let unwrappedRunBox = renderer?.findLeafNode(by: point)
        guard let runBox = unwrappedRunBox else {
            assertionFailure()
            return nil
        }

        return runBox.ownerRenderObject
    }

    @inline(__always)
    func findRenderObjectByDFS(walker: (RenderObject) -> Bool) -> RenderObject? {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        return renderer?.findRenderObjectByDFS(walker: walker)
    }

    @inline(__always)
    func findRenderObjectByBFS(walker: (RenderObject) -> Bool) -> RenderObject? {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        return renderer?.findRenderObjectByBFS(walker: walker)
    }

// MARK: - 选区

    func isSelectAll() -> Bool {
        guard let startIndex = startTuple?.index, let endIndex = endTuple?.index,
              let globalStartIndex = globalStartIndex, let globalEndIndex = globalEndIndex else {
            return true
        }
        return startIndex <= globalStartIndex && endIndex >= globalEndIndex
    }

    func resetGlobalStartEnd() {
        globalStartIndex = nil
        globalEndIndex = nil
    }

    // 入口方法
    public func getSeletedRects(start: CGPoint, end: CGPoint) -> (rects: [CGRect], writingMode: WritingMode, needExchange: Bool) {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        guard let renderer = renderer else {
            return ([], .horizontalTB, false)
        }

        let start = fixPoint(start)
        let end = fixPoint(end)

        let unwrappedStartRunBox = renderer.findLeafNode(by: start)
        let unwrappedEndRunBox = renderer.findLeafNode(by: end)
        guard let startRunBox = unwrappedStartRunBox, let endRunBox = unwrappedEndRunBox else {
            return ([], .horizontalTB, false)
        }

        let (startLhs, startChs, startRhs, startLocation, startLength) = getRectOfRunBox(by: start, from: startRunBox)
        let (endLhs, endChs, endRhs, endLocation, endLength) = getRectOfRunBox(by: end, from: endRunBox)

        if startLocation == endLocation {
            return ([], .horizontalTB, false)
        }

        /// finalLhs指的start对应的，finalRhs指的end对应的
        let finalLhs: CGRect, finalRhs: CGRect
        let finalStartRunBox: RunBox, finalEndRunBox: RunBox
        let finalStartIndex: Int, finalEndIndex: Int
        let needExchange = startLocation > endLocation

        if needExchange {
            if startLhs == nil, let startRunBox = startRunBox as? ContainerRunBox,
                let minX = startRunBox.children.map({ $0.globalRect.minX }).min(),
                start.x <= minX {
                finalRhs = CGRect(x: startChs.x, y: startChs.y, width: 1, height: startChs.height)
            } else {
                finalRhs = CGRect(x: startLhs?.x ?? startChs.x, y: startChs.y, width: startChs.width + (startLhs?.width ?? 0), height: startChs.height)
            }
            if endRhs == nil, let endRunBox = endRunBox as? ContainerRunBox,
                let maxX = endRunBox.children.map({ $0.globalRect.maxX }).max(),
                end.x >= maxX {
                finalLhs = CGRect(x: endChs.maxX, y: endChs.y, width: 1, height: endChs.height)
            } else {
                finalLhs = CGRect(x: endChs.x, y: endChs.y, width: endChs.width + (endRhs?.width ?? 0), height: endChs.height)
            }
            (finalStartRunBox, finalEndRunBox) = (endRunBox, startRunBox)
            (finalStartIndex, finalEndIndex) = (endLocation, startLocation + startLength)
        } else {
            if startLhs == nil, let startRunBox = startRunBox as? ContainerRunBox,
                let maxX = startRunBox.children.map({ $0.globalRect.maxX }).max(),
                start.x >= maxX {
                finalLhs = CGRect(x: startChs.maxX, y: startChs.y, width: 1, height: startChs.height)
            } else {
                finalLhs = CGRect(x: startChs.x, y: startChs.minY, width: startChs.width + (startRhs?.width ?? 0), height: startChs.height)
            }
            if endRhs == nil, let endRunBox = endRunBox as? ContainerRunBox,
                let minX = endRunBox.children.map({ $0.globalRect.minX }).min(),
                end.x <= minX {
                finalRhs = CGRect(x: endChs.x, y: endChs.y, width: 1, height: endChs.height)
            } else {
                finalRhs = CGRect(x: endLhs?.x ?? endChs.x, y: endChs.minY, width: endChs.width + (endLhs?.width ?? 0), height: endChs.height)
            }
            (finalStartRunBox, finalEndRunBox) = (startRunBox, endRunBox)
            (finalStartIndex, finalEndIndex) = (startLocation, endLocation + endLength)
        }

        // 在同一个 RunBox 下，rects 仅有两个值，取这两个值的交集
        if finalStartRunBox === finalEndRunBox {
            guard finalRhs.width > 0, finalLhs.width > 0 else {
                return ([], .horizontalTB, false)
            }
            let intersection = finalRhs.intersection(finalLhs)
            startTuple = (finalStartRunBox, finalStartIndex)
            endTuple = (finalEndRunBox, finalEndIndex)
            return (intersection.isNull ? [] : [intersection], renderer.renderStyle.writingMode, needExchange)
        }

        var rects = [CGRect]()

        // 处理 start Point 和 end Point 之间的 runBox
        switch getSelectedRectsNoLock(startRunBox: finalStartRunBox, endRunBox: finalEndRunBox) {
        case .success(let array):
            // 处理 start Point 落在的 runBox
            if finalLhs.width > 0, finalRhs.height > 0 {
                rects.append(finalLhs)
            }
            rects += array
            // 处理 end Point 落在的 runBox
            if finalRhs.width > 0, finalRhs.height > 0 {
                rects.append(finalRhs)
            }
        case .ancestor(ancestor: _, children: let children):
            // 当start、end其中一个为另一个的ancestor时，取
            rects = children
        case .failure:
            return ([], .horizontalTB, false)
        }

        startTuple = (finalStartRunBox, finalStartIndex)
        endTuple = (finalEndRunBox, finalEndIndex)

        return (fixRectsWithLineHeight(rects), renderer.renderStyle.writingMode, needExchange)
    }

    public func getAllSelectedRects() -> ([CGRect], WritingMode) {
        pthread_rwlock_rdlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        guard let renderer = renderer else {
            return ([], .horizontalTB)
        }

        /// 这里为了优化下面的选区不准情况而做的优化。
        ///         Block
        ///         /        \
        ///   InlineBlock    Text
        ///     /        \
        ///  Text   InlineBlock
        var unwrappedFirstLeaf: RenderObject?
        var helpRenderer: RenderObject = renderer
        var latestInlineBlock: RenderObject?
        while let firstChild = helpRenderer.children.first, !firstChild.renderStyle.isBlockSelection {
            helpRenderer = firstChild
            if helpRenderer.isRenderBlock, helpRenderer.isRenderInline {
                latestInlineBlock = helpRenderer
            }
        }
        unwrappedFirstLeaf = latestInlineBlock ?? helpRenderer

        var unwrappedLastLeaf: RenderObject?
        latestInlineBlock = nil
        helpRenderer = renderer
        while let lastChild = helpRenderer.children.last, !lastChild.renderStyle.isBlockSelection {
            helpRenderer = lastChild
            if helpRenderer.isRenderBlock, helpRenderer.isRenderInline {
                latestInlineBlock = helpRenderer
            }
        }
        unwrappedLastLeaf = latestInlineBlock ?? helpRenderer

        guard let firstLeaf = unwrappedFirstLeaf, let lastLeaf = unwrappedLastLeaf else {
            return ([], .horizontalTB)
        }

        var unwrappedFirstRunBox: RunBox?
        switch firstLeaf.runBox {
        case .normal(let box):
            unwrappedFirstRunBox = box
        case .split(let boxs):
            unwrappedFirstRunBox = boxs.first
        }

        var unwrappedLastRunBox: RunBox?
        switch lastLeaf.runBox {
        case .normal(let box):
            unwrappedLastRunBox = box
        case .split(let boxs):
            unwrappedLastRunBox = boxs.last
        }

        guard let firstRunBox = unwrappedFirstRunBox, let lastRunBox = unwrappedLastRunBox else {
            return ([], .horizontalTB)
        }

        var rects = [CGRect]()
        rects.append(firstRunBox.globalRect)
        switch getSelectedRectsNoLock(startRunBox: firstRunBox, endRunBox: lastRunBox) {
        case .success(let array):
            rects += array
        case .ancestor(ancestor: _, children: let children):
            rects += children
        case .failure:
            return ([], .horizontalTB)
        }
        rects.append(lastRunBox.globalRect)

        let startIdx = firstRunBox.renderContextLocation
        let endIdx = lastRunBox.renderContextLocation + lastRunBox.renderContextLength

        globalStartIndex = startIdx
        globalEndIndex = endIdx
        startTuple = (firstRunBox, startIdx)
        endTuple = (lastRunBox, endIdx)

        return (fixRectsWithLineHeight(rects), renderer.renderStyle.writingMode)
    }

    private func fixPoint(_ point: CGPoint) -> CGPoint {
        guard let rect = renderer?.contentRect, !rect.contains(point) else {
            return point
        }
        var res = point
        if point.x >= rect.maxX {
            res.x = rect.maxX - 1
        }
        if point.x <= rect.minX {
            res.x = rect.minX + 1
        }

        if point.y >= rect.maxY {
            res.y = rect.maxY - 1
        }
        if point.y <= rect.minY {
            res.y = rect.minY + 1
        }
        return res
    }

    private func fixRectsWithLineHeight(_ rects: [CGRect]) -> [CGRect] {
        guard let renderer = renderer else {
            return rects
        }
        let offset = renderer.renderStyle.lineHeight - renderer.renderStyle.fontSize
        return rects.map { val -> CGRect in
            var rect = val
            rect.size.height += offset
            rect.origin.y -= offset / 2
            return rect
        }
    }

    private func getSelectedRectsNoLock(startRunBox: RunBox, endRunBox: RunBox) -> SelectResult {
        guard let startRenderObj = startRunBox.ownerRenderObject,
              let endRenderObj = endRunBox.ownerRenderObject else {
            assertionFailure()
            return .failure
        }

        // 在同一个 renderObj 下，提前结束
        guard !(startRenderObj === endRenderObj) else {
            switch startRenderObj.runBox {
            case .split(let splitRunBoxs):
                guard let startIndex = splitRunBoxs.firstIndex(where: { $0 === startRunBox }),
                      let endIndex = splitRunBoxs.firstIndex(where: { $0 === endRunBox }),
                      startIndex + 1 < splitRunBoxs.count, endIndex - 1 >= 0,
                      startIndex + 1 <= endIndex - 1 else {
                    return .success([])
                }
                return .success(splitRunBoxs[startIndex + 1...endIndex - 1].map { $0.fullLineGlobalRect })
            case .normal:
                return .success([startRenderObj.boxRect])
            }
        }

        // 寻找最低公共祖先
        guard let lowestAncestor = lowestCommonAncestor(startRenderObj, endRenderObj) else {
            return .failure
        }

        var commonAncestor: RenderObject
        var res = [CGRect]()

        switch lowestAncestor {
        case .contains(ancestor: let ancestor, ancestorChild: let ancestorChild):
            commonAncestor = ancestor
            self.commonAncestor = ancestor
            // 祖先是其中之一
            if ancestor === startRenderObj {
                for child in ancestor.children {
                    switch child.runBox {
                    case .split(let runboxs):
                        res += runboxs.map { $0.fullLineGlobalRect }
                    case .normal:
                        res.append(child.boxRect)
                    }
                    if child === ancestorChild {
                        break
                    }
                }
                return .ancestor(ancestor: startRunBox, children: res)
            }
            if ancestor === endRenderObj {
                for child in ancestor.children.reversed() {
                    switch child.runBox {
                    case .split(let runboxs):
                        res += runboxs.map { $0.fullLineGlobalRect }
                    case .normal:
                        res.append(child.boxRect)
                    }
                    if child === ancestorChild {
                        break
                    }
                }
                return .ancestor(ancestor: endRunBox, children: res)
            }
        case .shared(ancestor: let ancestor):
            commonAncestor = ancestor
            self.commonAncestor = ancestor
        }

        switch startRenderObj.runBox {
        case .split(let splitRunBoxs):
            guard let index = splitRunBoxs.firstIndex(where: { $0 === startRunBox }) else {
                assertionFailure()
                return .failure
            }
            let endIndex = splitRunBoxs.endIndex
            if index + 1 < endIndex {
                res += splitRunBoxs[index + 1..<endIndex].map { $0.fullLineGlobalRect }
            }
        case .normal:
            break
        }
        traverse(start: startRenderObj, end: endRenderObj, ancestor: commonAncestor) {
            switch $0.runBox {
            case .split(let splitRunBoxs):
                res += splitRunBoxs.map { $0.fullLineGlobalRect }
            case .normal:
                res.append($0.boxRect)
            }
        }
        // 处理 endRunBox，如果是 split 的，需要把同级的前面的 runBox 也加进来
        switch endRenderObj.runBox {
        case .split(let splitRunBoxs):
            guard let index = splitRunBoxs.firstIndex(where: { $0 === endRunBox }) else {
                assertionFailure()
                return .failure
            }
            let startIndex = splitRunBoxs.startIndex
            if index - 1 >= startIndex {
                res += splitRunBoxs[startIndex...index - 1].map { $0.fullLineGlobalRect }
            }
        case .normal:
            break
        }

        return .success(res)
    }

    private func traverse(start: RenderObject, end: RenderObject, ancestor: RenderObject, callBack: (RenderObject) -> Void) {
        // 分别从 start 和 end 向上回溯至公共父节点的孩子层
        let ancestorLhsChild = traceBack(to: ancestor, fromStart: start, callBack: callBack)

        // 从 end 回溯得到的元素先临时存起来，等处理完公共节点的孩子以后再调用 callback
        var rhsRes = [RenderObject]()
        let ancestorRhsChild = traceBack(to: ancestor, fromEnd: end) {
            rhsRes.append($0)
        }

        // 当start是公共父节点，且第一个子节点不是end的父节点，则第一个子节点也需要callback
        if ancestor === start, let lhs = ancestorLhsChild, lhs !== ancestorRhsChild {
            callBack(lhs)
        }

        // 回溯到公共父节点的孩子层以后，两个节点中间的 RenderObj 也需要被处理
        let children = ancestor.children
        if let startIndex = children.firstIndex(where: { $0 === ancestorLhsChild }),
           let endIndex = children.firstIndex(where: { $0 === ancestorRhsChild }),
           startIndex + 1 < children.count, endIndex - 1 >= 0,
           startIndex + 1 <= endIndex - 1 {
            for child in children[startIndex + 1...endIndex - 1] {
                callBack(child)
            }
        }

        rhsRes.reversed().forEach { callBack($0) }

        // 当end是公共父节点，且最后一个子节点不是start的父节点，则最后一个子节点也需要callback
        if ancestor === end, let rhs = ancestorRhsChild, rhs !== ancestorLhsChild {
            callBack(rhs)
        }
    }

    enum Ancestor {
        case shared(ancestor: RenderObject)
        case contains(ancestor: RenderObject, ancestorChild: RenderObject)
    }

    private func lowestCommonAncestor(_ p: RenderObject, _ q: RenderObject) -> Ancestor? {
        var pathSet = Set<RenderObject>()
        var current = p
        pathSet.insert(current)
        while let pParent = current.parent {
            if pParent === q {
                return .contains(ancestor: q, ancestorChild: current)
            }
            pathSet.insert(pParent)
            current = pParent
        }

        current = q
        while !pathSet.contains(current) {
            guard let qParent = current.parent else {
                assertionFailure()
                return nil
            }
            if qParent === p {
                return .contains(ancestor: p, ancestorChild: current)
            }
            current = qParent
        }

        return .shared(ancestor: current)
    }

    private func traceBack(
        to ancestor: RenderObject,
        fromStart start: RenderObject,
        callBack: (RenderObject) -> Void
    ) -> RenderObject? {
        if ancestor === start {
            return start.children.first
        }

        guard let parent = start.parent else {
            assertionFailure()
            return nil
        }

        // 到达公共祖先的孩子层，退出递归
        if parent === ancestor {
            return start
        }

        // 处理当前层级的后面的兄弟节点
        let endIndex = parent.children.endIndex
        if let index = parent.children.firstIndex(where: { $0 === start }),
           index + 1 < endIndex {
            parent.children[index + 1..<endIndex].forEach { callBack($0) }
        }
        // 递归到父节点
        return traceBack(to: ancestor, fromStart: parent, callBack: callBack)
    }

    private func traceBack(to ancestor: RenderObject, fromEnd end: RenderObject, callBack: (RenderObject) -> Void) -> RenderObject? {
        if ancestor === end {
            return end.children.last
        }

        guard let parent = end.parent else {
            assertionFailure()
            return nil
        }

        // 到达公共祖先的孩子层，退出递归
        if parent === ancestor {
            return end
        }

        // 处理当前层级的前面的兄弟节点
        let startIndex = 0
        if let index = parent.children.firstIndex(where: { $0 === end }),
           index - 1 >= startIndex {
            parent.children[startIndex...index - 1].reversed().forEach { callBack($0) }
        }
        // 递归到父节点
        return traceBack(to: ancestor, fromEnd: parent, callBack: callBack)
    }
}

// MARK: - 选区边界

extension LKRichViewCore {
    private func getRectOfRunBox(
        by position: CGPoint,
        from runBox: RunBox
    ) -> (lhs: CGRect?, chs: CGRect, rhs: CGRect?, contextLocation: Int, contextLength: Int) {
        if let textRun = runBox as? TextRunBox {
            let line = textRun.textLine

            line.origin = textRun.globalOrigin
            let runIndex = getRunIndex(by: position, from: line)

            guard runIndex != kCFNotFound, runIndex < line.runs.count else {
                assertionFailure()
                return (nil, .zero, nil, kCFNotFound, 0)
            }

            let run = line.runs[runIndex]
            let (beforeIndex, afterIndex) = run.glyphPoints.map({ $0.x })
                .lf_bsearch(position.x - line.origin.x, comparable: ({ Int($0 - $1) }))

            guard beforeIndex >= -1, beforeIndex < run.glyphPoints.count,
                  afterIndex >= 0, afterIndex <= run.glyphPoints.count else {
                assertionFailure()
                return (nil, .zero, nil, kCFNotFound, 0)
            }

            let lineLocation = line.range.location

            let beforePoint: CGPoint
            let beforeStrIndex: CFIndex
            if beforeIndex == -1 {
                beforePoint = run.origin
                beforeStrIndex = run.range.location - lineLocation
            } else {
                beforePoint = run.glyphPoints[beforeIndex]
                beforeStrIndex = run.indices[beforeIndex] - lineLocation
            }

            let afterPoint: CGPoint
            let afterStrIndex: CFIndex
            if afterIndex == run.glyphPoints.count {
                afterPoint = .init(x: run.origin.x + run.width, y: run.origin.y)
                afterStrIndex = run.range.location + run.range.length - lineLocation
            } else {
                afterPoint = run.glyphPoints[afterIndex]
                afterStrIndex = run.indices[afterIndex] - lineLocation
            }

            let (l, c, r) = splitRect(
                x1: beforePoint.x + line.origin.x, x2: afterPoint.x + line.origin.x, from: textRun.fullLineGlobalRect
            )
            return (l, c, r, textRun.renderContextLocation + beforeStrIndex, afterStrIndex - beforeStrIndex)
        } else {
            // runBox是findLeafNode(by: point)得到的，我们这里直接使用即可，但是这样修改会导致取消后无法选中了，并且选中范围的蓝色遮罩也会漏掉一些
            // return (nil, runBox.fullLineGlobalRext, runBox.renderContextLocation)
            let rect = runBox.fullLineGlobalRect
            return (nil, rect, nil, runBox.renderContextLocation, runBox.renderContextLength)
        }
    }

    private func getRunIndex(by position: CGPoint, from line: TextLine) -> CFIndex {
        let lineFrame = line.rect
        guard lineFrame.containsX(position) else {
            if position.x <= lineFrame.minX {
                return 0
            }
            if position.x >= lineFrame.maxX {
                return line.runs.count - 1
            }
            return kCFNotFound
        }
        var position = position
        if !lineFrame.contains(position) {
            position.y = lineFrame.centerY
        }
        guard let pointAtRunIdx = bsearchPointAt(position - lineFrame.origin, frames: line.runs.map { $0.frame }) else {
            return kCFNotFound
        }
        return pointAtRunIdx
    }

    private func splitRect(x1: CGFloat, x2: CGFloat, from rect: CGRect) -> (lhs: CGRect, chs: CGRect, rhs: CGRect) {
        let start = min(x1, x2)
        let end = max(x1, x2)
        if end < rect.minX {
            return (.zero, .zero, rect)
        }
        if start > rect.maxX {
            return (rect, .zero, .zero)
        }

        let lhs = CGRect(x: rect.minX, y: rect.minY, width: max(start - rect.minX, 0), height: rect.height)
        let chs = CGRect(x: start, y: rect.minY, width: end - start, height: rect.height)
        let rhs = CGRect(x: end, y: rect.minY, width: max(rect.maxX - end, 0), height: rect.height)
        return (lhs, chs, rhs)
    }

    /// 返回point是否在一堆有序列的frames中
    /// 从左至右寻找
    ///
    /// - Parameters:
    ///   - point: CGPoint
    ///   - frmaes: 一组有顺序的frames
    /// - Returns: Index
    private func bsearchPointAt(_ point: CGPoint, frames: [CGRect]) -> Int? {
        var start = 0
        var end = frames.count - 1
        var select = 0
        let handler: (Int, inout Int, inout Int, [CGRect], CGPoint) -> Void = { (select, start, end, frames, point) in
            if frames[select].right < point.x {
                start = select + 1
                return
            }
            if frames[select].left > point.x {
                end = select - 1
                return
            }
            start = end + 1
        }
        while end >= start {
            select = (start + end) / 2
            if frames[select].containsX(point) {
                return select
            }
            handler(select, &start, &end, frames, point)
        }

        return nil
    }
}

// MARK: - copy paste

extension LKRichViewCore {
    // Should call after `getSelectedRectsNoLock()` called.
    func copyElementsNoLock(leftLeafNode: Node, rightLeafNode: Node) -> Node? {
        if leftLeafNode === rightLeafNode {
            return deepCopyLeafToRoot(leftLeafNode)?.root
        }

        guard let ancestorRenderObj = commonAncestor,
              let ancestor = ancestorRenderObj.ownerElement,
              let cloneAncestor = ancestor.copy() as? Node else {
            return nil
        }
        /// Copy subtree upon the ancestor.
        var cloneRoot: Node = cloneAncestor
        while let cloneParent = cloneRoot.parent?.copy() as? Node {
            /// Use `node.addChild` because this function has higher performance when deal with onc child.
            cloneParent.addChild(cloneRoot)
            cloneRoot = cloneParent
        }
        /// Copy subtree under the ancestor.
        /// BFS
        deepCloneWithinBoundary(
            source: ancestor,
            boundary: getBoundary(ancestor: ancestor, leftLeaf: leftLeafNode, rightLeaf: rightLeafNode),
            cloned: cloneAncestor
        )

        return cloneRoot
    }

    // Should be private function, only internal for unit tests.
    func getBoundary(ancestor: Node, leftLeaf: Node, rightLeaf: Node) -> [(left: Node?, right: Node?)] {
        var leftLeafNode = leftLeaf
        var rightLeafNode = rightLeaf
        var leftChildren: [Node] = []
        var rightChildren: [Node] = []
        var boundary: [(left: Node?, right: Node?)] = []

        /// Get the right boundary.
        while rightLeafNode !== ancestor, let parent = rightLeafNode.parent {
            rightChildren.append(rightLeafNode)
            rightLeafNode = parent
        }
        /// Get the left boundary.
        while leftLeafNode !== ancestor, let parent = leftLeafNode.parent {
            leftChildren.append(leftLeafNode)
            leftLeafNode = parent
        }
        while !(leftChildren.isEmpty && rightChildren.isEmpty) {
            boundary.append((left: leftChildren.popLast(), right: rightChildren.popLast()))
        }
        return boundary
    }

    // Should be private function, only internal for unit tests.
    func deepCloneWithinBoundary(source: Node, boundary: [(left: Node?, right: Node?)], cloned: Node) {
        // Map with Nodes, Map[idx] means there are some nodes in idx floor.
        // [
        //     [(root, [0, 1])],
        //     [(child1, [0, 1, 2]), (child2, [3])]
        //     [(child11, []), (child12, []), (child13, []), (child21, [])]
        // ]
        var nodeMap = [[(node: source, childIdxes: [Int]())]]
        var floorIdx = 0
        var nodeIdx = 0
        var canClone = false

        while floorIdx < nodeMap.count {
            var children: [(node: Node, childIdxes: [Int])] = []
     label: while nodeIdx < nodeMap[floorIdx].count {
                for child in nodeMap[floorIdx][nodeIdx].node.subElements {
                    let boundary = getBoundary(boundary, by: floorIdx)
                    if canClone == false {
                        canClone = boundary?.left == nil || boundary?.left === child
                    }
                    if canClone {
                        nodeMap[floorIdx][nodeIdx].childIdxes.append(children.count)
                        children.append((child, []))
                    }
                    if boundary?.right != nil && boundary?.right === child {
                        canClone = false
                        break label
                    }
                }
                nodeIdx += 1
            }
            if children.isEmpty {
                break
            }
            nodeMap.append(children)
            canClone = false
            nodeIdx = 0
            floorIdx += 1
        }
        nodeIdx = 0
        floorIdx = 0
        /// clone all children.
        nodeMap[floorIdx][nodeIdx].node = cloned
        while floorIdx + 1 < nodeMap.count {
            while nodeIdx < nodeMap[floorIdx].count {
                for i in nodeMap[floorIdx][nodeIdx].childIdxes {
                    // swiftlint:disable:next force_cast
                    let cloneNode = nodeMap[floorIdx + 1][i].node.copy() as! Node
                    nodeMap[floorIdx + 1][i].node = cloneNode
                    nodeMap[floorIdx][nodeIdx].node.addChild(cloneNode)
                }
                nodeIdx += 1
            }
            nodeIdx = 0
            floorIdx += 1
        }
    }

    @inline(__always)
    private func getBoundary(_ boundary: [(left: Node?, right: Node?)], by idx: Int) -> (left: Node?, right: Node?)? {
        if idx >= boundary.count {
            return nil
        }
        return boundary[idx]
    }

    ///
    func getCopyString() -> NSAttributedString? {
        guard let startRenderObj = startTuple?.box.ownerRenderObject,
              let startIndex = startTuple?.index,
              let endRenderObj = endTuple?.box.ownerRenderObject,
              let endIndex = endTuple?.index else {
            assertionFailure()
            return nil
        }

        if startRenderObj === endRenderObj {
            guard let element = startRenderObj.ownerElement else {
                assertionFailure()
                return nil
            }
            if let renderText = startRenderObj as? RenderText {
                guard startIndex < endIndex,
                    startIndex >= renderText.renderContextLocation,
                    endIndex <= renderText.renderContextLocation + renderText.renderContextLength else {
                    assertionFailure()
                    return nil
                }
                let str = renderText.text
                let startOffset = startIndex - renderText.renderContextLocation
                let endOffset = endIndex - renderText.renderContextLocation

                if startOffset > str.utf16.count {
                    return nil
                }
                if endOffset > str.utf16.count {
                    return element.getDefaultString()
                }
                let start = str.utf16.index(str.startIndex, offsetBy: startOffset)
                let end = str.utf16.index(str.startIndex, offsetBy: endOffset)

                return element.attachCopyPasteStyle(with: String(str[start..<end]))
            } else {
                assert(startRenderObj.renderContextLength == 1)
                return element.getDefaultString()
            }
        }

        let res = NSMutableAttributedString()

        if let renderText = startRenderObj as? RenderText, let element = renderText.ownerElement {
            guard startIndex >= startRenderObj.renderContextLocation,
                  startIndex <= startRenderObj.renderContextLocation + startRenderObj.renderContextLength else {
                assertionFailure()
                return nil
            }
            let str = renderText.text
            let startOffset = startIndex - renderText.renderContextLocation
            if startOffset > str.utf16.count {
                return nil
            }
            let start = str.utf16.index(str.startIndex, offsetBy: startOffset)
            res.append(element.attachCopyPasteStyle(with: String(str.suffix(from: start))))
        } else {
            if startRenderObj !== commonAncestor, let attr = startRenderObj.ownerElement?.getDefaultString() {
                res.append(attr)
            }
        }

        guard let ancestor = commonAncestor else {
            assertionFailure()
            return nil
        }
        traverse(start: startRenderObj, end: endRenderObj, ancestor: ancestor) {
            guard let element = $0.ownerElement else {
                assertionFailure()
                return
            }
            res.append(element.getDefaultString())
        }

        if let renderText = endRenderObj as? RenderText, let element = renderText.ownerElement {
            guard endIndex >= endRenderObj.renderContextLocation,
                  endIndex <= endRenderObj.renderContextLocation + endRenderObj.renderContextLength else {
                assertionFailure()
                return res
            }
            let str = renderText.text
            let endOffset = endIndex - renderText.renderContextLocation
            if endOffset > str.utf16.count {
                res.append(element.attachCopyPasteStyle(with: str))
            } else if endOffset > 0 {
                let end = str.utf16.index(str.startIndex, offsetBy: endOffset)
                res.append(element.attachCopyPasteStyle(with: String(str.prefix(upTo: end))))
            }
        } else {
            if endRenderObj !== commonAncestor, let attr = endRenderObj.ownerElement?.getDefaultString() {
                res.append(attr)
            }
        }

        return res
    }

    // 前面是否有更多内容可选中
    func canSelectMoreAhead() -> Bool {
        if let startIndex = startTuple?.index, let globalStartIndex = globalStartIndex {
            return startIndex > globalStartIndex
        }
        return true
    }

    // 后面是否有更多内容可选中
    func canSelectMoreAftwards() -> Bool {
        if let endIndex = endTuple?.index, let globalEndIndex = globalEndIndex {
            return endIndex < globalEndIndex
        }
        return true
    }

    private func setRootForChildren(root: RenderObject) {
        var stack = [root]
        while !stack.isEmpty {
            let child = stack.removeLast()
            child.root = root
            stack.append(contentsOf: child.children)
        }
    }

    private func copyElementChildren(_ element: Node) -> [Node] {
        return element.subElements.compactMap { element in
            guard let clone = element.copy() as? Node else {
                return nil
            }
            return clone.children(copyElementChildren(element))
        }
    }

    private func deepCopyLeafToRoot(_ element: Node) -> (root: Node, cur: Node)? {
        guard let clone = element.copy() as? Node else {
            return nil
        }
        var node = element.parent
        var prevNode = clone
        while let _clone = node?.copy() as? Node {
            _clone.children([prevNode])
            prevNode = _clone
            node = node?.parent
        }

        return (prevNode, clone)
    }
}

private enum SelectResult {
    case success([CGRect])
    case ancestor(ancestor: RunBox, children: [CGRect])
    case failure
}
