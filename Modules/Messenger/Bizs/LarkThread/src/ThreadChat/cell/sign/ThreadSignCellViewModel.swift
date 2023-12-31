//
//  ThreadSignCellViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import LarkMessageBase
import LarkFeatureGating
import LarkMessengerInterface

final class ThreadSignCellViewModel: SignCellViewModel<ThreadContext> {
    override var identifier: String {
        return "sign"
    }

    final override var centerText: String {
        return BundleI18n.LarkThread.Lark_Legacy_NewMessageSign
    }

    final override var backgroundColor: UIColor {
        return UIColor.clear
    }

    final override var textColor: UIColor {
        return UIColor.ud.B600
    }

    final override var lineColor: UIColor {
        return UIColor.ud.B600
    }

    init(context: ThreadContext) {
        super.init(context: context, binder: ThreadSignCellComponentBinder<ThreadContext>(context: context))
    }
}

final class ThreadSignCellComponentBinder<C: SignCellContext>: ComponentBinder<C> {
    private lazy var _component: SignCellComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private var props: SignCellComponentProps = .init()

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadSignCellViewModel else {
            assertionFailure()
            return
        }
        props.centerText = vm.centerText
        props.textFont = vm.textFont
        props.styleColor = vm.lineColor
        props.textColor = vm.textColor
        props.backgroundColor = vm.backgroundColor
        _component.style.paddingTop = 2
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        props = SignCellComponentProps()
        _component = SignCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
    }
}
