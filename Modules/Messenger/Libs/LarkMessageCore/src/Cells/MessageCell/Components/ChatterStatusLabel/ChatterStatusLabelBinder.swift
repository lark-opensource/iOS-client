//
//  ChatterStatusLabelBinder.swift
//  Action
//
//  Created by KT on 2019/6/3.
//

import Foundation
import AsyncComponent
import LarkMessageBase

final class ChatterStatusLabelBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ChatterStatusLabelViewModelContext & ChatterStatusLabelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private lazy var props: ChatterStatusLabelProps = {
        return ChatterStatusLabelProps(key: "chat-cell-chatterstatuslabel")
    }()
    private var _component: ChatterStatusLabelCompontent<C>!

    public override var component: ChatterStatusLabelCompontent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ChatterStatusLabelCompontent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ChatterStatusLabelViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.attriubuteText = vm.attriubuteText
        props.rangeLinkMap = vm.urlRangeMap
        props.invaildLinkMap = vm.textLinkList
        props.linkAttributesColor = vm.linkAttributesColor
        props.image = vm.icon
        props.showIcon = vm.icon != nil
        props.showText = vm.showText
        props.delegate = vm
        _component.props = props
    }
}
