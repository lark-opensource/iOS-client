//
//  MergeForwardTimeCellViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageCore
import EEFlexiable
import LarkCore
import LarkMessageBase
import LarkExtensions

final class MergeForwardTimeCellViewModel: MergeForwardCellViewModel {
    override var identifier: String {
        return "message-time"
    }
    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    let time: TimeInterval

    init(time: TimeInterval, context: MergeForwardContext) {
        self.time = time
        super.init(context: context, binder: MergeForwardTimeCellComponentBinder(context: context))
        super.calculateRenderer()
    }
}

final class MergeForwardTimeCellComponentBinder: ComponentBinder<MergeForwardContext> {
    private let props = MergeForwardTimeCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: MergeForwardTimeCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<MergeForwardContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: MergeForwardContext? = nil) {
        style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        _component = MergeForwardTimeCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MergeForwardTimeCellViewModel else {
            assertionFailure()
            return
        }
        props.timeString = Date(timeIntervalSince1970: vm.time).lf.formatedTime_v2()
        props.chatComponentTheme = vm.chatComponentTheme
        _component.props = props
    }
}
