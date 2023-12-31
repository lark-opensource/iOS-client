//
//  ChatTimeCellViewModel.swift
//  LarkNewChat
//
//  Created by qihongye on 2019/4/21.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageCore
import EEFlexiable
import LarkCore
import LarkMessageBase
import LarkExtensions

final class ChatTimeCellViewModel: ChatCellViewModel {
    override var identifier: String {
        return "message-time"
    }
    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }
    let time: TimeInterval

    init(time: TimeInterval, context: ChatContext) {
        self.time = time
        super.init(
            context: context,
            binder: ChatTimeCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class ChatTimeCellComponentBinder: ComponentBinder<ChatContext> {
    private let props = ChatTimeCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ChatTimeCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: ChatContext? = nil) {
        style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        _component = ChatTimeCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ChatTimeCellViewModel else {
            assertionFailure()
            return
        }
        props.chatComponentTheme = vm.chatComponentTheme
        props.timeString = Date(timeIntervalSince1970: vm.time).lf.formatedTime_v2()
        _component.props = props
    }
}
