//
//  TranslatedByReceiverCompententBinder.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/17.
//

import Foundation
import AsyncComponent
import LarkMessageBase

final class TranslatedByReceiverCompententBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewComponentBinder<M, D, C> {
    let translatedViewModel: TranslatedByReceiverCompententViewModel<M, D, C>?
    let props = TranslatedByReceiverCompentent<C>.Props()
    let style = ASComponentStyle()
    private var _component: TranslatedByReceiverCompentent<C>
    public override var component: TranslatedByReceiverCompentent<C> {
        return _component
    }

    init(
        key: String? = nil,
        context: C? = nil,
        translatedViewModel: TranslatedByReceiverCompententViewModel<M, D, C>?
    ) {
        self.translatedViewModel = translatedViewModel
        style.position = TranslateIconStyle.position
        style.width = TranslateIconStyle.width
        style.height = TranslateIconStyle.height
        style.bottom = TranslateIconStyle.bottom
        style.right = TranslateIconStyle.right
        _component = TranslatedByReceiverCompentent(props: props, style: style, context: context)
        super.init(key: key, context: context, viewModel: translatedViewModel, actionHandler: nil)
    }

    override func syncToBinder(key: String?) {
        props.tapHandler = { [weak self] in
            self?.translatedViewModel?.autoTranslateTapHandler()
        }
        _component.props = props
    }
}
