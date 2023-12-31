//
//  MessageDetailMessageInVisibleTipCellViewModel.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/5/11.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class MessageDetailMessageInVisibleTipCellViewModel: MessageDetailCellViewModel {
    override var identifier: String {
        return "messageDetail-MessageInVisibleTip"
    }

    let copyWriting: String

    init(copyWriting: String, context: MessageDetailContext) {
        self.copyWriting = copyWriting
        super.init(
            context: context,
            binder: MessageDetailMessageInVisibleTipCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class MessageDetailMessageInVisibleTipCellComponentBinder: ComponentBinder<MessageDetailContext> {
    private let props = MessageDetailMessageInVisibleTipCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: MessageDetailMessageInVisibleTipCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<MessageDetailContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: MessageDetailContext? = nil) {
        _component = MessageDetailMessageInVisibleTipCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MessageDetailMessageInVisibleTipCellViewModel else {
            return
        }
        props.copyWriting = vm.copyWriting
        _component.props = props
    }
}
