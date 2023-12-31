//
//  MessageListEngineWrapperComponent.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/3/28.
//

import AsyncComponent

public extension MessageListEngineWrapperComponent {
    final class Props: ASComponentProps {
        public var renderer: ASComponentRenderer

        public init(renderer: ASComponentRenderer) {
            self.renderer = renderer
        }
    }
}

public final class MessageListEngineWrapperComponent<C: AsyncComponent.Context>: ASComponent<MessageListEngineWrapperComponent.Props, EmptyState, MessageListEngineWrapperView, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override var isLeaf: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return props.renderer.size()
    }

    public override func create(_ rect: CGRect) -> MessageListEngineWrapperView {
        let view = super.create(rect)
        props.renderer.bind(to: view.container)
        props.renderer.render(view.container)
        return view
    }

    public override func update(view: MessageListEngineWrapperView) {
        super.update(view: view)
        // view可能被复用而不会走create，此处需要重新bind & render
        props.renderer.bind(to: view.container)
        props.renderer.render(view.container)
    }
}
