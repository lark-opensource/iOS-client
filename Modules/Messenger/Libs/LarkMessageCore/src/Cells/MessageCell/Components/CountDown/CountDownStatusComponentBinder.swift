//
//  CountDownStatusComponentBinder.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2021/5/18.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase

final class CountDownStatusComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: CountDownContext>: ComponentBinder<C> {
    lazy var props: UILabelComponentProps = {
        let props = UILabelComponentProps()
        props.font = .systemFont(ofSize: 12.0)
        props.textColor = UIColor.ud.textPlaceholder
        return props
    }()

    lazy var style: ASComponentStyle = {
        let style = ASComponentStyle()
        style.height = 14
        style.backgroundColor = .clear
        style.marginTop = 4
        return style
    }()

    private lazy var _component: UILabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CountDownStatusViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        props.text = vm.burnTimeText
        self._component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "CountDown"
        self._component = UILabelComponent(props: props, style: style, context: context)
    }
}

final class MessageDetailCountDownStatusComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: CountDownContext>: ComponentBinder<C> {
    lazy var props: UILabelComponentProps = {
        let props = UILabelComponentProps()
        props.font = .systemFont(ofSize: 12.0)
        props.textColor = UIColor.ud.textPlaceholder
        props.lineBreakMode = .byTruncatingTail
        props.textAlignment = .right
        return props
    }()

    lazy var style: ASComponentStyle = {
        let style = ASComponentStyle()
        style.width = 80
        style.height = 14
        style.flexShrink = 0
        style.backgroundColor = .clear
        return style
    }()

    private lazy var _component: UILabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CountDownStatusViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        props.text = vm.burnTimeText
        self._component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "CountDown"
        self._component = UILabelComponent(props: props, style: style, context: context)
    }
}
