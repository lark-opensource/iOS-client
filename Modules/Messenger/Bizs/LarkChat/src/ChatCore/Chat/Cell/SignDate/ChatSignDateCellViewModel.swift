//
//  ChatSignDateCellViewModel.swift
//  LarkNewChat
//
//  Created by zc09v on 2019/4/1.
//

import Foundation
import LarkMessageCore
import AsyncComponent
import LarkMessageBase
import LarkExtensions

final class ChatSignDateCellViewModel: ChatCellViewModel {
    override var identifier: String {
        return "message-sign-date"
    }
    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    private let signDate: TimeInterval

    var dateText: String {
        return signDate.lf.cacheFormat("n_sign_date", formater: { $0.lf.formatedDate() })
    }

    init(signDate: TimeInterval, context: ChatContext) {
        self.signDate = signDate
        super.init(
            context: context,
            binder: DateSignCellComponentBinder(context: context)
        )
        self.calculateRenderer()
    }
}

final class DateSignCellComponentBinder: ComponentBinder<ChatContext> {
    private lazy var _component: DateSignCellComponent = .init(props: .init(), style: .init(), context: nil)
    private var props = DateSignCellComponent.Props()
    private var style = ASComponentStyle()

    final override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: ChatContext? = nil) {
        _component = DateSignCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ChatSignDateCellViewModel else {
            assertionFailure()
            return
        }
        props.dateText = vm.dateText
        props.chatComponentTheme = vm.chatComponentTheme
        _component.props = props
    }
}
