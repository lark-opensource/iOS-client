//
//  DefaultContentCompoenntBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/2.
//

import UIKit
import Foundation
import AsyncComponent
import RichLabel

final public class DefaultContentCompoenntBinder<C: ViewModelContext>: ComponentBinder<C> {
    private var props = UILabelComponentProps()
    private var style = ASComponentStyle()
    private lazy var _component: UILabelComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.text = BundleI18n.LarkMessageBase.Lark_Legacy_UnknownMessageTypeTip()
        props.textColor = UIColor.ud.N500
        props.font = UIFont.systemFont(ofSize: 16)
        props.numberOfLines = 0
        style.backgroundColor = .clear
        self._component = UILabelComponent<C>(props: props, style: style, context: context)
    }
}
