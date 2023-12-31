//
//  DLPFeedbackComponentBinder.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/18.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import RichLabel

final class DLPFeedbackComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DlpComponentContext>: ComponentBinder<C> {

    private let style = ASComponentStyle()
    private let props = DLPFeedBackComponentProps()
    private var _component: DLPFeedBackComponent<C>?

    public override var component: DLPFeedBackComponent<C> {
        return _component ?? DLPFeedBackComponent<C>(props: props,
                                                     style: style,
                                                     context: nil)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = DLPFeedBackComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? DLPFeedbackComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        let info = vm.getAttrbuteTextInfo()
        props.attributedText = info.0
        props.linkList = info.1
        props.iconSize = vm.iconSize
        component.props = props
    }
}
