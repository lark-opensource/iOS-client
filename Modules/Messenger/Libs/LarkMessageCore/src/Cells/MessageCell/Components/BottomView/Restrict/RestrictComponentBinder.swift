//
//  RestrictComponentBinder.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/12/29.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import RichLabel

final public class RestrictComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: RestrictComponentContext>: ComponentBinder<C> {
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
        guard let vm = vm as? RestrictComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.iconSize = vm.iconSize
        props.icon = vm.icon
        props.attributedText = {
            let attributedText = NSMutableAttributedString(string: vm.text)
            attributedText.addAttributes(
                [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.ud.functionWarningContentDefault
                ],
                range: NSRange(location: 0, length: attributedText.length)
            )
            return attributedText
        }()
        _component.props = props
        style.marginTop = 4
    }
}
