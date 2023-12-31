//
//  ThreadDetailSystemCellComponentBinder.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/21.
//

import Foundation
import AsyncComponent
import LarkMessageCore
import LarkMessageBase

final class ThreadDetailSystemCellComponentBinder: ComponentBinder<ThreadDetailContext> {
    private let style = ASComponentStyle()
    private let props = ThreadDetailSystemCellComponent.Props()
    private var _component: ComponentWithContext<ThreadDetailContext>!

    override var component: ComponentWithContext<ThreadDetailContext> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadDetailSystemCellViewModel else {
            assertionFailure()
            return
        }
        props.labelAttrText = vm.labelAttrText
        props.textLinks = vm.textLinks
    }

    override func buildComponent(key: String? = nil, context: ThreadDetailContext? = nil) {
        _component = ThreadDetailSystemCellComponent(
            props: props,
            style: style,
            context: context
        )
    }
}
