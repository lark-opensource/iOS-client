//
//  MessageDetailPlaceholderTipCellViewModel.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/11/16.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class MessageDetailPlaceholderTipCellViewModel: MessageDetailCellViewModel {
    override var identifier: String {
        return "messageDetail-PlaceholderTip"
    }

    let copyWriting: String

    init(copyWriting: String, context: MessageDetailContext) {
        self.copyWriting = copyWriting
        super.init(
            context: context,
            binder: MessageDetailPlaceholderTipCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class MessageDetailPlaceholderTipCellComponentBinder: ComponentBinder<MessageDetailContext> {
    private let props = MessageDetailPlaceholderTipCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: MessageDetailPlaceholderTipCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<MessageDetailContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: MessageDetailContext? = nil) {
        _component = MessageDetailPlaceholderTipCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MessageDetailPlaceholderTipCellViewModel else {
            return
        }
        props.copyWriting = vm.copyWriting
        _component.props = props
    }
}
