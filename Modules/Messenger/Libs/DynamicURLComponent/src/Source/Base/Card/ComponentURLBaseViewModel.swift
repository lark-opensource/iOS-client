//
//  ComponentURLBaseViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/7/31.
//

import RustPB
import LarkModel

open class ComponentURLBaseViewModel: ComponentBaseViewModel {
    /// style & property为已patch好的结果
    public required init(entity: URLPreviewEntity,
                         stateID: String,
                         componentID: String,
                         component: Basic_V1_URLPreviewComponent,
                         style: Basic_V1_URLPreviewComponent.Style,
                         property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                         children: [ComponentBaseViewModel],
                         ability: ComponentAbility,
                         dependency: URLCardDependency) {
        super.init(entity: entity, children: children, ability: ability, dependency: dependency)
    }

    /// 是否能创建当前组件
    open class func canCreate(component: Basic_V1_URLPreviewComponent, context: URLCardContext) -> Bool {
        return true
    }
}
