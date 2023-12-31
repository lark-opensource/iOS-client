//
//  ThreadDetailPreviewTipCellViewModel.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/4.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class ThreadDetailPreviewTipCellViewModel: ThreadDetailCellViewModel {
    override var identifier: String {
        return "thread-previewTip"
    }

    let copyWriting: String

    init(copyWriting: String, context: ThreadDetailContext) {
        self.copyWriting = copyWriting
        super.init(
            context: context,
            binder: ThreadDetailPreviewTipCellComponentBinder(context: context)
        )
        super.calculateRenderer()
    }
}

final class ThreadDetailPreviewTipCellComponentBinder: ComponentBinder<ThreadDetailContext> {
    private let props = ThreadDetailPreviewTipCellComponent.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ThreadDetailPreviewTipCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<ThreadDetailContext> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: ThreadDetailContext? = nil) {
        _component = ThreadDetailPreviewTipCellComponent(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadDetailPreviewTipCellViewModel else {
            return
        }
        props.copyWriting = vm.copyWriting
        _component.props = props
    }
}
