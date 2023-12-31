//
//  LayoutComponentBaseViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import Foundation
import RustPB
import LarkModel
import TangramComponent

open class LayoutComponentBaseViewModel: ComponentURLBaseViewModel {
    public required init(entity: URLPreviewEntity,
                         stateID: String,
                         componentID: String,
                         component: Basic_V1_URLPreviewComponent,
                         style: Basic_V1_URLPreviewComponent.Style,
                         property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                         children: [ComponentBaseViewModel],
                         ability: ComponentAbility,
                         dependency: URLCardDependency) {
        super.init(entity: entity,
                   stateID: stateID,
                   componentID: componentID,
                   component: component,
                   style: style,
                   property: property,
                   children: children,
                   ability: ability,
                   dependency: dependency)
        let layoutStyle = buildComponentStyle(style: style)
        buildComponent(stateID: stateID, componentID: componentID, component: component, style: style, property: property, layoutStyle: layoutStyle)
        self.component.setChildren(children.map({ $0.component }))
    }

    // Component构建的时候会有如点击事件等业务逻辑，所以有ViewModel充当工厂方法
    open func buildComponent(stateID: String,
                             componentID: String,
                             component: Basic_V1_URLPreviewComponent,
                             style: Basic_V1_URLPreviewComponent.Style,
                             property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                             layoutStyle: LayoutComponentStyle) {
        assertionFailure("must be overrided")
    }

    open func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> LayoutComponentStyle {
        let layoutStyle = LayoutComponentStyle()
        return sync(from: style, to: layoutStyle)
    }
}
