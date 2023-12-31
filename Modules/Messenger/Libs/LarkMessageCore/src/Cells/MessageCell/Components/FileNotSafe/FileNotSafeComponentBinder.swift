//
//  FileNotSafeComponentBinder.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/11/14.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import RichLabel
import LKCommonsLogging

final class FileNotSafeComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: FileNotSafeComponentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = IconViewComponentProps()
    private lazy var _component: IconViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: IconViewComponent<C> {
        return _component
    }

    var logger = Logger.log(FileNotSafeComponentBinder.self)

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.numberOfLines = 0
        _component = IconViewComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? FileNotSafeComponentViewModel<M, D, C> else {
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
