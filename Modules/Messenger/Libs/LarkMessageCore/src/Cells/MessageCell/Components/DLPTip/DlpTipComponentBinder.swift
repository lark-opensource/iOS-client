//
//  DLPTipComponentBinder.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/6/20.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import RichLabel

final class MessageDlpTipComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DlpComponentContext>: ComponentBinder<C> {
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
        guard let vm = vm as? DlpTipComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.iconSize = vm.iconSize
        props.icon = vm.icon
        props.onViewClicked = { [weak vm] in
            vm?.dlpTipDidTapped()
        }
        props.attributedText = {
            let attributedText = NSMutableAttributedString(string: vm.text)
            attributedText.addAttributes(
                [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.ud.functionDangerContentDefault
                ],
                range: NSRange(location: 0, length: attributedText.length)
            )
            return attributedText
        }()
        _component.props = props
        style.marginTop = 4
    }
}
