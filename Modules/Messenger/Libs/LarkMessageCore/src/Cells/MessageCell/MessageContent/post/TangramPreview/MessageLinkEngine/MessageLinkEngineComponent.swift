//
//  MessageLinkEngineComponent.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/11.
//

import AsyncComponent
import TangramComponent
import UniverseDesignColor

final class MessageLinkEngineComponentProps: Props {
    var renderer: EquatableWrapper<ASComponentRenderer?> = .init(value: nil)

    func clone() -> MessageLinkEngineComponentProps {
        let clone = MessageLinkEngineComponentProps()
        clone.renderer = renderer
        return clone
    }

    func equalTo(_ old: Props) -> Bool {
        guard let old = old as? MessageLinkEngineComponentProps else { return false }
        return renderer == old.renderer
    }
}

final class MessageLinkEngineComponent<C: TangramComponent.Context>: RenderComponent<MessageLinkEngineComponentProps, MessageListEngineWrapperView, C> {
    override var isSelfSizing: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return props.renderer.value?.size() ?? .zero
    }

    override func update(_ view: MessageListEngineWrapperView) {
        super.update(view)
        // view可能被复用而不会走create，此处需要重新bind & render
        props.renderer.value?.bind(to: view.container)
        props.renderer.value?.render(view.container)
    }
}

final class MessageLinkWrapperComponentProps: Props {
    var renderer: EquatableWrapper<ASComponentRenderer?> = .init(value: nil)
    var showMoreTapped: EquatableWrapper<(() -> Void)?> = .init(value: nil)
    var backgroundColor: UIColor = UDColor.bgBody

    func clone() -> MessageLinkWrapperComponentProps {
        let clone = MessageLinkWrapperComponentProps()
        clone.renderer = renderer
        clone.showMoreTapped = showMoreTapped
        clone.backgroundColor = backgroundColor.copy() as? UIColor ?? UDColor.bgBody
        return clone
    }

    func equalTo(_ old: Props) -> Bool {
        guard let old = old as? MessageLinkWrapperComponentProps else { return false }
        return renderer == old.renderer &&
        showMoreTapped == old.showMoreTapped &&
        backgroundColor == old.backgroundColor
    }
}

// MessageLinkEngineComponent负责需要设置最大高度进行截断，需要和底部的「查看详情」再包一层
final class MessageLinkWrapperComponent<C: TangramComponent.Context>: RenderComponent<MessageLinkWrapperComponentProps, TouchView, C> {
    private lazy var messageLink: MessageLinkEngineComponent<C> = {
        let style = RenderComponentStyle()
        style.maxHeight = TCValue(cgfloat: MessageLinkEngineConfig.contentMaxHeight)
        return MessageLinkEngineComponent(props: MessageLinkEngineComponentProps(), style: style)
    }()

    private lazy var bottomView: MessageLinkBottomComponent<C> = {
        return MessageLinkBottomComponent(props: MessageLinkBottomComponentProps(), style: .init())
    }()

    private lazy var rootLayout: LinearLayoutComponent = {
        var rootLayoutProps = LinearLayoutComponentProps()
        rootLayoutProps.orientation = .column
        return LinearLayoutComponent(children: [messageLink, bottomView], props: rootLayoutProps)
    }()

    init(props: MessageLinkWrapperComponentProps) {
        let style = RenderComponentStyle()
        style.maxWidth = TCValue(cgfloat: MessageLinkEngineConfig.contentMaxWidth)
        super.init(layoutComponent: nil, props: props, style: style)
        setLayout(rootLayout)
    }

    override func update(_ view: TouchView) {
        super.update(view)
        view.onTapped = { [weak self] _ in
            self?.props.showMoreTapped.value?()
        }
    }

    func setup(props: MessageLinkWrapperComponentProps) {
        messageLink.props.renderer.value = props.renderer.value
        bottomView.props.showMask = (props.renderer.value?.size() ?? .zero).height > MessageLinkEngineConfig.contentMaxHeight
        bottomView.props.backgroundColor = props.backgroundColor
        self.props = props
    }
}
