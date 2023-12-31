//
//  EventShareBinder.swift
//  Pods
//
//  Created by zoujiayi on 2019/6/27.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import AsyncComponent
import EEFlexiable

final class LarkEventShareBinder<M: CellMetaModel, D: CellMetaModelDependency, C: EventShareViewModelContext>: ComponentBinder<C> {
    private lazy var _component: ShareCardComponent<C> = ShareCardComponent(props: .init(), style: .init(), context: nil)

    private let style = ASComponentStyle()
    private var props = ShareCardComponentProps()
    private var borderGetter: (() -> Border)?
    private var cornerRadiusGetter: (() -> CGFloat)?

    override var component: ComponentWithContext<C> {
        return _component
    }

    required init(key: String? = nil, context: C? = nil, borderGetter: (() -> Border)? = nil, cornerRadiusGetter: (() -> CGFloat)? = nil) {
        self.borderGetter = borderGetter
        self.cornerRadiusGetter = cornerRadiusGetter
        super.init(key: key, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? EventShareViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        _component.style.width = CSSValue(cgfloat: vm.contentWidth)
        _component.props = vm.eventShareComponentProps
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        if let border = borderGetter?() {
            style.border = border
        }

        if let cornerRadius = cornerRadiusGetter?() {
            style.cornerRadius = cornerRadius
        }

        _component = ShareCardComponent(props: props, style: style, context: context)
    }
}
