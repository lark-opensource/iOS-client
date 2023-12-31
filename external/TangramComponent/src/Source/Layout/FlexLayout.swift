//
//  FlexLayout.swift
//  TangramComponent
//
//  Created by Ping on 2023/7/26.
//

import TangramLayoutKit

// https://bytedance.feishu.cn/docx/KFYmdDH8PoNZDexEbGdcs9SMnTg
public struct FlexLayoutComponentProps: Props {
    public var orientation: Orientation = .row
    public var justify: Justify = .start
    public var align: Align = .top
    public var flexWrap: FlexWrap = .noWrap
    public var padding: Padding = .zero
    public var mainAxisSpacing: CGFloat = 0
    public var crossAxisSpacing: CGFloat = 0

    public init() {}

    public func clone() -> FlexLayoutComponentProps {
        return self
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? FlexLayoutComponentProps else { return false }
        return orientation == old.orientation &&
        justify == old.justify &&
        align == old.align &&
        flexWrap == old.flexWrap &&
        padding == old.padding &&
        mainAxisSpacing == old.mainAxisSpacing &&
        crossAxisSpacing == old.crossAxisSpacing
    }
}

public class FlexLayoutComponent: LayoutComponent<FlexLayoutComponentProps, EmptyContext> {
    public override func render() -> BaseVirtualNode {
        // props是struct，且全部都是值变量，因此这里不用clone()
        let vnode = FlexLayoutVirtualNode(componentKey: componentKey, isSelfSizing: isSelfSizing,
                                          props: props, style: style,
                                          ability: self, children: self.children.map({ $0.render() }))
        return vnode
    }
}

public class FlexLayoutVirtualNode: LayoutVirtualNode {
    public override func render() -> TLNodeRef {
        guard let props = props as? FlexLayoutComponentProps else { return TLNodeNew()! }
        let node = TLFlexLayoutNodeNew()!
        // sync props
        TLNodeSetFlexLayoutPropsOrientation(node, props.orientation.value)
        TLNodeSetFlexLayoutPropsMainAxisJustify(node, props.justify.value)
        TLNodeSetFlexLayoutPropsCrossAxisAlign(node, props.align.value)
        TLNodeSetFlexLayoutPropsFlexWrap(node, props.flexWrap.value)
        TLNodeSetFlexLayoutPropsMainAxisSpacing(node, Float(props.mainAxisSpacing))
        TLNodeSetFlexLayoutPropsCrossAxisSpacing(node, Float(props.crossAxisSpacing))
        TLNodeSetFlexLayoutPropsPadding(node, TLEdges(top: Float(props.padding.top),
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
