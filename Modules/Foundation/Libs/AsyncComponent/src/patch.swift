//
//  patch.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/1/29.
//

import UIKit
import Foundation
import UniverseDesignTheme

struct RenderTree<TreeNode: AnyObject> {
    var node: TreeNode
    var children: [RenderTree<TreeNode>] = []

    init(node: TreeNode) {
        self.node = node
    }
}

struct ViewTree {
    struct LayerInfo {
        var reflactingTag: Int
        var viewTagIdx: Int
        var stable: Bool
        var isASCreated: Bool

        init(_ reflactingTag: Int, _ viewTagIdx: Int, _ stable: Bool, _ isASCreated: Bool) {
            self.reflactingTag = reflactingTag
            self.viewTagIdx = viewTagIdx
            self.stable = stable
            self.isASCreated = isASCreated
        }
    }
    // tag to view index
    var viewTagMap: [Int: [Int]] = [:]
    // index to layer
    var subviews: [Int] = []
    // reflactingTag, viewIndex, stable, isASCreated
    private var sublayers: [LayerInfo] = []
    private let view: UIView

    init(_ view: UIView) {
        self.view = view
        self.buildViewTagMap()
    }

    private mutating func buildViewTagMap() {
        guard let sublayers = view.layer.sublayers else {
            return
        }
        for i in 0..<sublayers.count {
            guard let subview = sublayers[i].delegate as? UIView else {
                self.sublayers.append(LayerInfo(0, -1, false, false))
                continue
            }

            if !subview.isASCreated {
                self.sublayers.append(LayerInfo(0, -1, false, false))
            } else {
                let tag = subview.reflectingTag.hashValue
                var indecies = viewTagMap[tag] ?? []
                indecies.append(self.subviews.count)
                self.sublayers.append(LayerInfo(tag, indecies.count - 1, false, true))
                viewTagMap[tag] = indecies
            }

            self.subviews.append(i)
        }
    }

    mutating func exchangeSubview(at: Int, withSubviewAt: Int) {
        guard at < subviews.count, withSubviewAt < subviews.count else {
            return
        }
        // view index to layer index
        let layerAt = subviews[at]
        let withSublayerAt = subviews[withSubviewAt]
        guard sublayers[layerAt].isASCreated, sublayers[withSublayerAt].isASCreated else {
            return
        }
        let tupleA = sublayers[withSublayerAt]
        let tupleB = sublayers[layerAt]
        if tupleA.stable || tupleB.stable {
            return
        }
        view.exchangeSubview(at: layerAt, withSubviewAt: withSublayerAt)
        if var indecies = viewTagMap[tupleA.reflactingTag] {
            indecies[tupleA.viewTagIdx] = at
            viewTagMap[tupleA.reflactingTag] = indecies
        }
        if var indecies = viewTagMap[tupleB.reflactingTag] {
            indecies[tupleB.viewTagIdx] = withSubviewAt
            viewTagMap[tupleB.reflactingTag] = indecies
        }
        sublayers[layerAt] = tupleA
        sublayers[withSublayerAt] = tupleB
    }

    mutating func insertSubview(subview: UIView, at: Int) {
        // view index to layer index
        let layerIdx = subviews[at]
        for i in layerIdx..<sublayers.count {
            if var indecies = viewTagMap[sublayers[i].reflactingTag], sublayers[i].viewTagIdx < indecies.count {
                indecies[sublayers[i].viewTagIdx] += 1
                viewTagMap[sublayers[i].reflactingTag] = indecies
            }
        }
        for i in at..<subviews.count {
            subviews[i] += 1
        }
        view.insertSubview(subview, at: layerIdx)
        sublayers.insert(LayerInfo(subview.reflectingTag.hashValue, at, true, true), at: layerIdx)
        subviews.insert(layerIdx, at: at)
    }

    mutating func insertSubviewV2(subview: UIView, at: Int) {
        let reflectingTag = subview.reflectingTag.hashValue
        guard at < subviews.count else {
            view.addSubview(subview)
            var indecies = viewTagMap[reflectingTag] ?? []
            indecies.append(subviews.count)
            viewTagMap[reflectingTag] = indecies
            subviews.append(sublayers.count)
            sublayers.append(LayerInfo(reflectingTag, indecies.count - 1, true, true))
            return
        }
        // view index to layer index
        let layerIdx = subviews[at]
        for i in layerIdx..<sublayers.count {
            if var indecies = viewTagMap[sublayers[i].reflactingTag], sublayers[i].viewTagIdx < indecies.count {
                indecies[sublayers[i].viewTagIdx] += 1
                viewTagMap[sublayers[i].reflactingTag] = indecies
            }
        }
        for i in at..<subviews.count {
            subviews[i] += 1
        }
        view.insertSubview(subview, at: layerIdx)
        sublayers.insert(LayerInfo(reflectingTag, at, true, true), at: layerIdx)
        subviews.insert(layerIdx, at: at)
    }

    mutating func makeIndexStable(_ index: Int) {
        // view index to layer index
        let at = subviews[index]
        if sublayers[at].isASCreated {
            sublayers[at].stable = true
        }
    }

    func findAvalibleViewIndex(_ reflactingTag: Int) -> Int? {
        guard let indecies = viewTagMap[reflactingTag],
              let index = indecies
                .first(where: { sublayers[subviews[$0]].isASCreated && !sublayers[subviews[$0]].stable }) else {
                return nil
        }
        return index
    }
}

func applyPatchToView(_ renderTree: RenderTree<BaseVirtualNode>, view: UIView, rootView: UIView?) {
    guard renderTree.node.canAttach(view) else {
        return
    }
    assert(Thread.isMainThread, "Must in main thread.")
    // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
    // view.asRootBindView = rootView
    renderTree.node.updateView(view)
    if renderTree.node.isLeaf && renderTree.node.isComplex {
        return
    }
    var count = min(renderTree.children.count, view.subviews.count)
    var viewTree = ViewTree(view)
    for i in 0..<count {
        let subNode = renderTree.children[i].node
        let tag = subNode.tag
        if let index = viewTree.findAvalibleViewIndex(tag) {
            if i != index {
                viewTree.exchangeSubview(at: index, withSubviewAt: i)
            }
            viewTree.makeIndexStable(i)
            subNode.didMount(view.subviews[i])
        } else if let subView = subNode.createView() {
            // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
            // view.asRootBindView = rootView
            viewTree.insertSubview(subview: subView, at: i)
            subNode.didMount(subView)
        }
    }
    var i = count
    while i < view.subviews.count {
        if !view.subviews[i].isHidden {
            view.subviews[i].removeFromSuperview()
            continue
        }
        i += 1
    }
    for i in count..<renderTree.children.count {
        let subNode = renderTree.children[i].node
        if let subView = subNode.createView() {
            // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
            // view.asRootBindView = rootView
            if i < view.subviews.count {
                view.insertSubview(subView, at: i)
            } else {
                view.addSubview(subView)
            }
            subNode.didMount(subView)
        }
    }

//    assert(renderTree.children.count == view.subviews.count, "Node tree is not equal to view tree.")
    count = min(renderTree.children.count, view.subviews.count)

    for i in 0..<count {
        applyPatchToView(renderTree.children[i], view: view.subviews[i], rootView: rootView)
    }
}

func applyPatchToViewV2(_ renderTree: RenderTree<BaseVirtualNode>, view: UIView, rootView: UIView?) {
    guard renderTree.node.canAttach(view) else {
        return
    }
    assert(Thread.isMainThread, "Must in main thread.")
    // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
    // view.asRootBindView = rootView
    renderTree.node.updateView(view)
    if renderTree.node.isLeaf && renderTree.node.isComplex {
        return
    }
    var count = renderTree.children.count
    var viewTree = ViewTree(view)
    for i in 0..<count {
        let subNode = renderTree.children[i].node
        let tag = subNode.tag
        if let index = viewTree.findAvalibleViewIndex(tag) {
            if i != index {
                viewTree.exchangeSubview(at: index, withSubviewAt: i)
            }
            viewTree.makeIndexStable(i)
            subNode.didMount(view.subviews[i])
        } else if let subView = subNode.createView() {
            // TODO: @qhy, this can fix view reuse bug when DarkMode supported `isTraitObserver`.
            // view.asRootBindView = rootView
            viewTree.insertSubviewV2(subview: subView, at: i)
            subNode.didMount(subView)
        }
    }
    var i = count
    while i < view.subviews.count {
        if !view.subviews[i].isHidden {
            view.subviews[i].removeFromSuperview()
            continue
        }
        i += 1
    }

//    assert(renderTree.children.count == view.subviews.count, "Node tree is not equal to view tree.")
    count = min(renderTree.children.count, view.subviews.count)

    for i in 0..<count {
        applyPatchToViewV2(renderTree.children[i], view: view.subviews[i], rootView: rootView)
    }
}

func patchRenderTree(_ lhs: BaseVirtualNode, _ rhs: BaseVirtualNode) -> BaseVirtualNode {
    return rhs
}

func buildRenderTree(_ node: BaseVirtualNode) -> RenderTree<BaseVirtualNode> {
    var renderTree: RenderTree<BaseVirtualNode> = RenderTree(node: node)
    var children = node.children
    var idx = 0
    while idx < children.count {
        if !children[idx].isLayoutContainer {
            idx += 1
            continue
        }
        if children[idx].children.isEmpty {
            children.remove(at: idx)
        } else if children[idx].children.count == 1 {
            children[idx].children[0].parentOrigin = children[idx].boundingRect.origin
            if children[idx].isHidden {
                children[idx].children[0].isHidden = true
            }
            children[idx] = children[idx].children[0]
        } else {
            fixParentOriginAndIsHidden(&children[idx])
            children.replaceSubrange(idx..<(idx + 1), with: children[idx].children)
        }
    }

    for child in children where !child.isHidden {
        renderTree.children.append(buildRenderTree(child))
    }

    return renderTree
}

@inline(__always)
func fixParentOriginAndIsHidden(_ node: inout BaseVirtualNode) {
    for i in 0..<node.children.count {
        node.children[i].parentOrigin = node.boundingRect.origin
        if node.isHidden {
            node.children[i].isHidden = true
        }
    }
}

func renderTreeSnapshot(_ renderTree: RenderTree<BaseVirtualNode>) -> RenderTree<BaseVirtualNode> {
    var tree = RenderTree(node: renderTree.node.clone())
    tree.children = renderTree.children.map(renderTreeSnapshot)
    return tree
}

func + (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

private var _reflectingTagKey = "_reflectingTagKey"
private var _componentKey = "_componentKey"
private var _asRootBindView = "_asRootBindView"
extension UIView {
    var isASCreated: Bool {
        return componentKey != nil
    }

    var asRootBindView: UIView? {
        get {
            return objc_getAssociatedObject(self, &_asRootBindView) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &_asRootBindView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var reflectingTag: ObjectIdentifier {
        if let tag = objc_getAssociatedObject(self, &_reflectingTagKey) as? ObjectIdentifier {
            return tag
        }
        let tag = ObjectIdentifier(type(of: self))
        objc_setAssociatedObject(self, &_reflectingTagKey, tag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return tag
    }

    public var componentKey: String? {
        get {
            return objc_getAssociatedObject(self, &_componentKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &_componentKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func getASComponentKey() -> String? {
        return self.componentKey
    }
}
