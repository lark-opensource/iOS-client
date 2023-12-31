//
//  MomentsEmptyContentCellViewModel.swift
//  Moment
//
//  Created by ByteDance on 2022/7/28.
//
import Foundation
import UIKit
import LarkMessageBase
import EEFlexiable
import AsyncComponent

final class MomentsEmptyContentCellViewModel: BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext> {

    public override var identifier: String {
        return "unsupport_content"
    }
    override init(entity: RawData.CommentEntity, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        super.init(entity: entity, context: context, binder: binder)
    }
}

final class MomentsEmptyContentCellViewModelBinder<C: BaseMomentContext>: ComponentBinder<C> {
    private let emptyContentComponentKey: String = "empty_content_component"
    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        self._component = ASLayoutComponent<C>(
            key: key ?? emptyContentComponentKey,
            style: style,
            context: context,
            []
        )
    }

}
