//
//  CallContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/18.
//

import Foundation
import AsyncComponent
import LarkMessageBase

final class CallContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: CallContentContext>: ComponentBinder<C> {
    private let richLabelProps = RichLabelProps()

    private lazy var _component: RichLabelComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return self._component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CallContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        self.richLabelProps.preferMaxLayoutWidth = vm.preferMaxLayoutWidth
        self.richLabelProps.attributedText = vm.attributedString
        self.richLabelProps.tapableRangeList = [vm.atRange]
        self.richLabelProps.font = vm.labelFont
        self.richLabelProps.delegate = vm
        self._component.props = self.richLabelProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        self._component = RichLabelComponent(
            props: self.richLabelProps,
            style: style,
            context: context
        )
    }
}
