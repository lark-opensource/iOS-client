//
//  TranslateStatusComponentBinder.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/17.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

/// 翻译相关icon 统一style
struct TranslateIconStyle {
    static let position: CSSPosition = .absolute
    static var width: CSSValue {
        return (16).auto()
    }
    static var height: CSSValue {
        return (16).auto()
    }
    static var bottom: CSSValue {
        return (1).auto()
    }
    static var right: CSSValue {
        return (1).auto()
    }
}

final class TranslateStatusComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewComponentBinder<M, D, C> {
    let translateStatusViewModel: TranslateStatusComponentViewModel<M, D, C>?
    let props = TranslateStatusCompentent<C>.Props()
    let style = ASComponentStyle()
    private var _component: TranslateStatusCompentent<C>
    public override var component: TranslateStatusCompentent<C> {
        return _component
    }

    init(
        key: String? = nil,
        context: C? = nil,
        translateStatusViewModel: TranslateStatusComponentViewModel<M, D, C>?
    ) {
        self.translateStatusViewModel = translateStatusViewModel
        style.position = TranslateIconStyle.position
        style.width = TranslateIconStyle.width
        style.height = TranslateIconStyle.height
        style.bottom = TranslateIconStyle.bottom
        style.right = TranslateIconStyle.right
        _component = TranslateStatusCompentent(props: props, style: style, context: context)
        super.init(key: key, context: context, viewModel: translateStatusViewModel, actionHandler: nil)
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.translateStatusViewModel else { return }
        props.translateDisplayInfo = .display(backgroundColor: .clear)
        props.translateStatus = vm.translateStatus
        props.canShowTranslateIcon = vm.canShowTranslateIcon
        props.trackInfo = vm.translateTrackInfo
        props.tapHandler = { [weak self] in
            self?.translateStatusViewModel?.translateTapHandler()
        }
        _component.props = props
    }
}
