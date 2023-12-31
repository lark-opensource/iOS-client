//
//  ShareGroupContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/11.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import EEFlexiable

public struct ShareGroupContentConfig {
    public static var contentMaxWidth: CGFloat {
        return 400
    }

    public let hasPaddingBottom: Bool?

    public init(hasPaddingBottom: Bool? = nil) {
        self.hasPaddingBottom = hasPaddingBottom
    }
}

final class ShareGroupContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ShareGroupContentContext>: ComponentBinder<C> {
    private let props = ShareGroupViewComponent<C>.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ShareGroupViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ShareGroupContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        style.width = CSSValue(cgfloat: min(ShareGroupContentConfig.contentMaxWidth, vm.contentPreferMaxWidth))
        props.delegate = vm
        props.content = vm.content
        props.displayJoinButton = vm.displayJoinButton
        props.joinButtonText = vm.joinButtonText
        props.joinButtonTextColor = vm.joinButtonTextColor
        props.joinButtonBorderColor = vm.joinButtonBorderColor
        props.joinButtonEnable = vm.joinButtonEnable
        props.joinStatusText = vm.joinStatusText
        props.threadMiniIconEnableFg = vm.threadMiniIconEnableFg
        props.hasPaddingBottom = vm.hasPaddingBottom
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "ShareGroupContent"
        _component = ShareGroupViewComponent(props: props, style: style, context: context)
    }
}

final class ShareGroupWithBorderContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ShareGroupContentContext>: ComponentBinder<C> {
    private let props = ShareGroupViewComponent<C>.Props()
    private let style = ASComponentStyle()
    private var contentComponent: ShareGroupViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private let contentStyle = ASComponentStyle()
    private lazy var _component: UIViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: UIViewComponent<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ShareGroupContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        contentStyle.width = CSSValue(cgfloat: min(ShareGroupContentConfig.contentMaxWidth, vm.contentPreferMaxWidth))
        props.delegate = vm
        props.content = vm.content
        props.displayJoinButton = vm.displayJoinButton
        props.joinButtonText = vm.joinButtonText
        props.joinButtonTextColor = vm.joinButtonTextColor
        props.joinButtonBorderColor = vm.joinButtonBorderColor
        props.joinButtonEnable = vm.joinButtonEnable
        props.joinStatusText = vm.joinStatusText
        props.threadMiniIconEnableFg = vm.threadMiniIconEnableFg
        props.hasPaddingBottom = vm.hasPaddingBottom
        contentComponent.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "ShareGroupContent"
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        self.contentComponent = ShareGroupViewComponent(props: props, style: contentStyle, context: context)
        _component = UIViewComponent<C>(props: .empty, style: style)
        _component.setSubComponents([contentComponent])
    }

}
