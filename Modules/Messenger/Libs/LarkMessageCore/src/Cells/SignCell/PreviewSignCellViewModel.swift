//
//  PreviewSignCellViewModel.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/10/9.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase

public protocol PreviewSignCellContext: ViewModelContext {
    var maxCellWidth: CGFloat { get }
    func getChatThemeScene() -> ChatThemeScene
}

extension PageContext: PreviewSignCellContext {}

open class PreviewSignCellViewModel<C: PreviewSignCellContext>: CellViewModel<C> {
    open override var identifier: String {
        return "preview_sign"
    }
    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    open var centerText: String {
        return ""
    }

    open var textFont: UIFont {
        return UIFont.ud.body2
    }

    open var textColor: UIColor {
        return chatComponentTheme.systemTextColor
    }

    open var lineColor: UIColor {
        return UIColor.ud.textPlaceholder
    }

    open var backgroundColor: UIColor {
        return UIColor.ud.N100
    }

    public override init(context: C, binder: ComponentBinder<C>, renderer: ASComponentRenderer? = nil) {
        super.init(context: context, binder: binder, renderer: renderer)
        super.calculateRenderer()
    }
}

public final class PreviewSignCellComponentBinder<C: PreviewSignCellContext>: ComponentBinder<C> {
    private lazy var _component: PreviewSignCellComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private var props: PreviewSignCellComponentProps = .init()

    public final override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PreviewSignCellViewModel<C> else {
            assertionFailure()
            return
        }
        props.centerText = vm.centerText
        props.textFont = vm.textFont
        props.styleColor = vm.lineColor
        props.textColor = vm.textColor
        props.backgroundColor = vm.backgroundColor
        props.chatComponentTheme = vm.chatComponentTheme
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props = PreviewSignCellComponentProps()
        _component = PreviewSignCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
    }
}
