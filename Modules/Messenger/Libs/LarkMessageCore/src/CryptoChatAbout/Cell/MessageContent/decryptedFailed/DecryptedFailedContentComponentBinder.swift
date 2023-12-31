//
//  DecryptedFailedContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/4/12.
//

import Foundation
import AsyncComponent
import RichLabel
import LarkMessageBase
import EEFlexiable

final class DecryptedFailedContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DecryptedFailedContentContext>: ComponentBinder<C> {
    private var _component: ASLayoutComponent<C>?
    public override var component: ASLayoutComponent<C> {
        return _component ?? ASLayoutComponent<C>(style: ASComponentStyle(), [])
    }

    private let richLabelProps = RichLabelProps()
    private lazy var contentComponent: RichLabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return RichLabelComponent(props: self.richLabelProps, style: style)
    }()

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? DecryptedFailedContentViewModel<M, D, C> else {
            return
        }
        self.richLabelProps.preferMaxLayoutWidth = vm.preferMaxLayoutWidth
        self.richLabelProps.attributedText = vm.attributedString
        self.richLabelProps.font = vm.labelFont
        self.contentComponent.props = self.richLabelProps
        // 需要自己设置一次maxWidth，防止绘制超出气泡
        self.contentComponent.style.maxWidth = CSSValue(cgfloat: vm.preferMaxLayoutWidth)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        // RichLabelComponent需要包一层，因为在ChatMessageCellComponent等处，会对最外层Component.style重新设置maxWidth，如果不包一层，
        // 最外层Component就是RichLabelComponent，而因为RichLabelComponent的特殊性，RichLabelComponent需要自己设置一次style.maxWidth
        // 防止渲染超出气泡，而这两处设置的值可能不相同，包一层是为了避免ChatMessageCellComponent等处修改RichLabelComponent.style
        self._component = ASLayoutComponent<C>(style: ASComponentStyle(), [self.contentComponent])
    }
}
