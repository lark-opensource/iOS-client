//
//  SignViewModel.swift
//  LarkMessageCore
//
//  Created by qihongye on 2019/4/19.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase

public protocol SignCellContext: ViewModelContext {
    var maxCellWidth: CGFloat { get }
    func getChatThemeScene() -> ChatThemeScene
}

extension PageContext: SignCellContext {}

open class SignCellViewModel<C: SignCellContext>: CellViewModel<C> {
    open override var identifier: String {
        return "sign"
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
        return UIColor.ud.colorfulBlue
    }

    open var lineColor: UIColor {
        return UIColor.ud.colorfulBlue
    }

    open var backgroundColor: UIColor {
        return UIColor.ud.N100
    }

    public override init(context: C, binder: ComponentBinder<C>, renderer: ASComponentRenderer? = nil) {
        super.init(context: context, binder: binder, renderer: renderer)
        super.calculateRenderer()
    }
}

public final class SignCellComponentBinder<C: SignCellContext>: ComponentBinder<C> {
    private lazy var _component: SignCellComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private var props: SignCellComponentProps = .init()

    public final override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? SignCellViewModel<C> else {
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
        props = SignCellComponentProps()
        _component = SignCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
    }
}
