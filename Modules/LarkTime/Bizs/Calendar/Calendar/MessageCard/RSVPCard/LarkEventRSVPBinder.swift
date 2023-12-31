//
//  LarkEventRSVPBinder.swift
//  Calendar
//
//  Created by pluto on 2023/1/15.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import AsyncComponent
import EEFlexiable

final class LarkEventRSVPBinder<M: CellMetaModel, D: CellMetaModelDependency, C: EventRSVPViewModelContext>: ComponentBinder<C> {
    private lazy var _component: RSVPCardComponent<C> = RSVPCardComponent(props: .init(), style: .init(), context: nil)

    private let style = ASComponentStyle()
    private var props = RSVPCardComponentProps()
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
        guard let vm = vm as? EventRSVPViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        
        _component.style.width = CSSValue(cgfloat: vm.contentWidth)
        _component.props = vm.eventRSVPComponentProps
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        if let border = borderGetter?() {
            style.border = border
        }

        if let cornerRadius = cornerRadiusGetter?() {
            style.cornerRadius = cornerRadius
        }

        _component = RSVPCardComponent(props: props, style: style, context: context)
    }
}
