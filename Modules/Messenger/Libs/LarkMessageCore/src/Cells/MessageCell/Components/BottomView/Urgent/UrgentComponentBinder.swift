//
//  UrgentComponentBinder.swift
//  LarkMessageCore
//
//  Created by 赵冬 on 2020/4/7.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import EEFlexiable
import UniverseDesignIcon

final class UrgentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: UrgentComponentViewModelContext>: ComponentBinder<C> {
    private let style: ASComponentStyle = {
        var style = ASComponentStyle()
        style.position = .absolute
        style.left = 0
        style.top = 0
        return style
    }()
    private let props = ASComponentProps()
    private lazy var _component: UrgentComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: UrgentComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = UrgentComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? UrgentComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        style.width = CSSValue(cgfloat: vm.iconSize.width)
        style.height = CSSValue(cgfloat: vm.iconSize.height)
        _component.props = props
    }
}

final class MessageDetailUrgentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: UrgentComponentViewModelContext>: ComponentBinder<C> {
    private let style: ASComponentStyle = {
        var style = ASComponentStyle()
        style.position = .absolute
        style.left = 0
        style.top = 0
        style.width = CSSValue(cgfloat: 24)
        style.height = CSSValue(cgfloat: 24)
        return style
    }()

    private let props = MessageDetailUrgentComponent<C>.Props()
    private lazy var _component: MessageDetailUrgentComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: MessageDetailUrgentComponent<C> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = MessageDetailUrgentComponent<C>(props: props, style: style, context: context)
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? UrgentComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        _component.props = props
    }
}

final class UrgentBackgroundView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        let imageView = UIImageView(frame: CGRect(x: 2, y: 3, width: 10, height: 10))
        imageView.image = UDIcon.getIconByKey(.buzzFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 10, height: 10))
        self.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.ud.red.cgColor)
        context?.move(to: CGPoint(x: 0, y: 0))
        context?.addLine(to: CGPoint(x: 24, y: 0))
        context?.addLine(to: CGPoint(x: 0, y: 24))
        context?.closePath()
        context?.drawPath(using: .fill)
    }
}

final class MessageDetailUrgentComponent<C: AsyncComponent.Context>: ASComponent<MessageDetailUrgentComponent.Props, EmptyState, UrgentBackgroundView, C> {
    final class Props: ASComponentProps {}

    override var isComplex: Bool {
        return true
    }

    override func update(view: UrgentBackgroundView) {
        view.backgroundColor = UIColor.clear
    }
}
