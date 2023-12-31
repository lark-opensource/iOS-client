//
//  LinearLayout.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/4/1.
//

import TangramLayoutKit

// https://bytedance.feishu.cn/wiki/wikcnYd5xqVdb800qlkD8ryfKVi
public struct LinearLayoutComponentProps: Props {
    public var direction: Direction = .ltr
    public var orientation: Orientation = .row
    public var justify: Justify = .start
    public var align: Align = .top
    public var padding: Padding = .zero
    public var wrapWidth: CGFloat = 0
    public var spacing: CGFloat = 0

    public init() {}

    public func clone() -> LinearLayoutComponentProps {
        return self
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? LinearLayoutComponentProps else { return false }
        return direction == old.direction &&
            orientation == old.orientation &&
            justify == old.justify &&
            align == old.align &&
            padding == old.padding &&
            wrapWidth == old.wrapWidth &&
            spacing == old.spacing
    }
}

public class LinearLayoutComponent: LayoutComponent<LinearLayoutComponentProps, EmptyContext> {
    public override func render() -> BaseVirtualNode {
        // props是struct，且全部都是值变量，因此这里不用clone()
        let vnode = LinearLayoutVirtualNode(componentKey: componentKey, isSelfSizing: isSelfSizing,
                                            props: props, style: style,
                                            ability: self, children: self.children.map({ $0.render() }))
        return vnode
    }
}

public class LinearLayoutVirtualNode: LayoutVirtualNode {
    public override func render() -> TLNodeRef {
        guard let props = props as? LinearLayoutComponentProps else { return TLNodeNew()! }
        let node = TLLinearLayoutNodeNew()!
        // sync props
        TLNodeSetLinearLayoutPropsDirection(node, props.direction.value)
        TLNodeSetLinearLayoutPropsOrientation(node, props.orientation.value)
        TLNodeSetLinearLayoutPropsMainAxisJustify(node, props.justify.value)
        TLNodeSetLinearLayoutPropsCrossAxisAlign(node, props.align.value)
        TLNodeSetLinearLayoutPropsWrapWidth(node, Float(props.wrapWidth))
        TLNodeSetLinearLayoutPropsSpacing(node, Float(props.spacing))
        TLNodeSetLinearLayoutPropsPadding(node, TLEdges(top: Float(props.padding.top),
                                                          right: Float(props.padding.right),
                                                          bottom: Float(props.padding.bottom),
                                                          left: Float(props.padding.left)))

        // sync style
        style.sync(to: node)

        // set context
        let context: UnsafeMutableRawPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        TLNodeSetContext(node, context)

        // sync children
        let children: [TLNodeRef?] = self.children.map { $0.render() }
        TLNodeSetChildren(node, children, UInt32(children.count))

        return node
    }

    public override func layout(_ size: CGSize) -> CGSize {
        let node = render()
        TLCaculateLayout(node, Float(size.width), Float(size.height), nil)
        syncFrame(from: node, to: self)
        TLNodeDeepFree(node)
        return frame.size
    }
}
