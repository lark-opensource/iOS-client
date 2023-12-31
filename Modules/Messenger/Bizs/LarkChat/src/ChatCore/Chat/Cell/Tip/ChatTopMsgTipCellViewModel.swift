//
//  ChatTopTipCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2021/11/4.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import LarkMessageCore

final class ChatTopMsgTipCellViewModel: ChatCellViewModel {
    override var identifier: String {
        return "message-MessageInVisibleTip"
    }
    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    let tip: String

    init(tip: String, context: ChatContext) {
        self.tip = tip
        super.init(
            context: context,
            binder: ChatTopMsgTipCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class ChatTopMsgTipCellComponentBinder: ComponentBinder<ChatContext> {
    private let props = ChatTopMsgTipCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ChatTopMsgTipCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: ChatContext? = nil) {
        _component = ChatTopMsgTipCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ChatTopMsgTipCellViewModel else {
            return
        }
        props.tip = vm.tip
        props.chatComponentTheme = vm.chatComponentTheme
        _component.props = props
    }
}
