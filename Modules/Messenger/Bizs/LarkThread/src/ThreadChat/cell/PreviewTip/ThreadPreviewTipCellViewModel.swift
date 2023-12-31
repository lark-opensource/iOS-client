//
//  ThreadPreviewTipCellViewModel.swift
//  LarkThread
//
//  Created by ByteDance on 2022/10/9.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class ThreadPreviewTipCellViewModel: ThreadCellViewModel {
    override var identifier: String {
        return "thread-previewTip"
    }

    let copyWriting: String

    init(copyWriting: String, context: ThreadContext) {
        self.copyWriting = copyWriting
        super.init(
            context: context,
            binder: ThreadPreviewCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class ThreadPreviewCellComponentBinder: ComponentBinder<ThreadContext> {
    private let props = ThreadPreviewTipCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ThreadPreviewTipCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<ThreadContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: ThreadContext? = nil) {
        _component = ThreadPreviewTipCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadPreviewTipCellViewModel else {
            return
        }
        props.copyWriting = vm.copyWriting
        _component.props = props
    }
}
