//
//  MergeForwardSignDateCellViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import Foundation
import LarkMessageCore
import AsyncComponent
import LarkMessageBase
import LarkExtensions

final class MergeForwardSignDateCellViewModel: MergeForwardCellViewModel {
    override var identifier: String {
        return "message-sign-date"
    }

    private let signDate: TimeInterval

    var dateText: String {
        return signDate.lf.cacheFormat("n_sign_date", formater: { $0.lf.formatedDate() })
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    init(signDate: TimeInterval, context: MergeForwardContext) {
        self.signDate = signDate
        super.init(context: context, binder: MergeForwardDateSignCellComponentBinder(context: context))
        self.calculateRenderer()
    }
}

final class MergeForwardDateSignCellComponentBinder: ComponentBinder<MergeForwardContext> {
    private lazy var _component: MergeForwardDateSignCellComponent = .init(props: .init(), style: .init(), context: nil)
    private var props = MergeForwardDateSignCellComponent.Props()
    private var style = ASComponentStyle()

    final override var component: ComponentWithContext<MergeForwardContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: MergeForwardContext? = nil) {
        _component = MergeForwardDateSignCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MergeForwardSignDateCellViewModel else {
            assertionFailure()
            return
        }
        props.dateText = vm.dateText
        props.chatComponentTheme = vm.chatComponentTheme
        _component.props = props
    }
}
