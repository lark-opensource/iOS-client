//
//  MomentsUnsupportContentViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/1/29.
//

import Foundation
import UIKit
import LarkMessageBase
import EEFlexiable
import AsyncComponent

protocol MomentsUnsupportTip: HasId {
    var unsupportTip: String? { get }
}

final class MomentsUnsupportContentViewModel <T: MomentsUnsupportTip>: BaseMomentSubCellViewModel<T, BaseMomentContext> {

    public override var identifier: String {
        return "unsupport_content"
    }

    var unsupportTip: String? {
        return self.entity.unsupportTip
    }

    override init(entity: T, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        super.init(entity: entity, context: context, binder: binder)
    }
}

final class MomentsUnsupportContentViewModelBinder<T: MomentsUnsupportTip, C: BaseMomentContext>: ComponentBinder<C> {
    private let unsupportContentComponentKey: String = "unsupport_content_component"
    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ComponentWithContext<C> {
        return _component
    }

    lazy var unsupportContenProps: MomentsUnsupportContentComponent<C>.Props = {
        return MomentsUnsupportContentComponent<C>.Props()
    }()

    lazy var unsupportContentComponent: MomentsUnsupportContentComponent<C> = {
        let style = ASComponentStyle()
        return MomentsUnsupportContentComponent<C>(props: unsupportContenProps, style: style)
    }()

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MomentsUnsupportContentViewModel<T> else {
            assertionFailure()
            return
        }
        if let tip = vm.unsupportTip {
            unsupportContenProps.tipText = tip
            self._component.style.display = .flex
        } else {
            unsupportContenProps.tipText = ""
            self._component.style.display = .none
        }
        self.unsupportContentComponent.props = unsupportContenProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        self._component = ASLayoutComponent<C>(
            key: key ?? unsupportContentComponentKey,
            style: style,
            context: context,
            [unsupportContentComponent]
        )
    }

}
