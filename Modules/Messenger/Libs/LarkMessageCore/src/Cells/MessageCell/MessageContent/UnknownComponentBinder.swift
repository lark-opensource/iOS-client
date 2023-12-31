//
//  UnknownComponentBinder.swift
//  LarkMessageCore
//
//  Created by qihongye on 2020/5/17.
//

import UIKit
import Foundation
import LarkMessageBase
import AsyncComponent

final class UnknownContentComponentBinder<C: PageContext>: ComponentBinder<C> {
    private var props = UILabelComponentProps()
    private var style = ASComponentStyle()
    private lazy var _component: UILabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.text = BundleI18n.LarkMessageCore.Lark_Legacy_UnknownMessageTypeTip()
        props.textColor = context?.getColor(for: .Message_SystemText_Foreground, type: .other) ?? UIColor.ud.textCaption
        props.font = UIFont.ud.body0
        props.numberOfLines = 0
        style.backgroundColor = .clear
        self._component = UILabelComponent<C>(props: props, style: style, context: context)
    }
}

final public class UnknownContentFactory<C: PageContext>: DefaultContentFactory<C> {
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return true
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return DefaultContentViewModel(metaModel: metaModel,
                                       metaModelDependency: metaModelDependency,
                                       context: context,
                                       binder: UnknownContentComponentBinder<C>(context: context))
    }
}
