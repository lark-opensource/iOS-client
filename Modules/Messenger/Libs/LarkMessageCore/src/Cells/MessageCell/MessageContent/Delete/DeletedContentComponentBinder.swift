//
//  DeleteContentComponentBinder.swift
//  Action
//
//  Created by 赵冬 on 2019/8/3.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase

final class DeletedContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DeletedContentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private lazy var _component: UILabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: UILabelComponent<C> {
        return _component
    }

    private var props = UILabelComponentProps()

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? DeletedContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.text = vm.string as String
        props.font = UIFont.ud.body0
        props.textColor = UIColor.ud.textCaption
        self._component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        self._component = UILabelComponent(
            props: self.props,
            style: style,
            context: context
        )
    }
}
