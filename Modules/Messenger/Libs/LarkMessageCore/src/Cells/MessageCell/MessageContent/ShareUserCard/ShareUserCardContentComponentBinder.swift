//
//  ShareUserCardContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2020/4/21.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import EEFlexiable

public struct ShareUserCardContentConfig {
    public static var contentMaxWidth: CGFloat {
        return 400
    }

    public let hasPaddingBottom: Bool?

    public init(hasPaddingBottom: Bool? = nil) {
        self.hasPaddingBottom = hasPaddingBottom
    }
}

final class ShareUserCardContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ShareUserCardContentContext>: ComponentBinder<C> {
    private let props = ShareUserCardViewComponent<C>.Props()
    private let style = ASComponentStyle()
    private lazy var _component: ShareUserCardViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ShareUserCardContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        style.width = CSSValue(cgfloat: min(ShareUserCardContentConfig.contentMaxWidth, vm.contentPreferMaxWidth))
        props.avatarKey = vm.content.chatter?.avatarKey ?? ""
        props.chatterId = vm.content.chatter?.id ?? ""
        props.name = vm.content.chatter?.nameWithAnotherName ?? ""
        props.cardTapped = { [weak vm] in
            vm?.cardTapped()
        }
        props.hasPaddingBottom = vm.hasPaddingBottom
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "ShareUserCardContent"
        _component = ShareUserCardViewComponent(props: props, style: style, context: context)
    }
}

final class ShareUserCardWithBorderContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ShareUserCardContentContext>: ComponentBinder<C> {
    private let props = ShareUserCardViewComponent<C>.Props()
    private let style = ASComponentStyle()
    private var contentComponent: ShareUserCardViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private let contentStyle = ASComponentStyle()

    private lazy var _component: UIViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ShareUserCardContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        contentStyle.width = CSSValue(cgfloat: min(ShareUserCardContentConfig.contentMaxWidth, vm.contentPreferMaxWidth))
        props.avatarKey = vm.content.chatter?.avatarKey ?? ""
        props.chatterId = vm.content.chatter?.id ?? ""
        props.name = vm.content.chatter?.nameWithAnotherName ?? ""
        props.cardTapped = { [weak vm] in
            vm?.cardTapped()
        }
        props.hasPaddingBottom = vm.hasPaddingBottom
        contentComponent.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "ShareUserCardContent"
        style.cornerRadius = 10
        style.boxSizing = .borderBox
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        self.contentComponent = ShareUserCardViewComponent(props: props, style: contentStyle, context: context)
        _component = UIViewComponent<C>(props: .empty, style: style)
        _component.setSubComponents([contentComponent])
    }
}
