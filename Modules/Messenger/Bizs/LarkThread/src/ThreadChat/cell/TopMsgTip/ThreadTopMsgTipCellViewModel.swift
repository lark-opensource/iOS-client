//
//  ThreadTopMsgTipCellViewModel.swift
//  LarkThread
//
//  Created by zhaojiachen on 2021/12/2.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class ThreadTopMsgTipCellViewModel: ThreadCellViewModel {
    override var identifier: String {
        return "thread-topMsgTip"
    }

    let tip: String

    init(tip: String, context: ThreadContext) {
        self.tip = tip
        super.init(
            context: context,
            binder: ThreadTopMsgTipCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class ThreadTopMsgTipCellComponentBinder: ComponentBinder<ThreadContext> {
    private let props = ThreadTopMsgTipCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ThreadTopMsgTipCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<ThreadContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: ThreadContext? = nil) {
        _component = ThreadTopMsgTipCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadTopMsgTipCellViewModel else {
            return
        }
        props.tip = vm.tip
        _component.props = props
    }
}
