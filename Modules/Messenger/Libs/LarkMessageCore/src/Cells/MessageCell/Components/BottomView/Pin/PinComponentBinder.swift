//
//  PinComponentBinder.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/3.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase

final class PinComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PinComponentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = IconViewComponentProps()
    private lazy var _component: IconViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: IconViewComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.numberOfLines = 0
        _component = IconViewComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.iconSize = vm.iconSize
        props.icon = vm.icon
        props.attributedText = vm.attributeText
        _component.props = props
        style.marginTop = 4
    }
}

final class ThreadPinComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PinComponentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = IconViewComponentProps()
    private lazy var _component: IconViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: IconViewComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.iconAndLabelSpacing = 4
        props.numberOfLines = 0
        _component = IconViewComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadPinComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.iconSize = CGSize(width: 14, height: 14)
        props.icon = vm.icon
        props.attributedText = vm.attributeText
        _component.props = props
    }
}
