//
//  ComponentCardRegistry.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/18.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkModel
import EENavigator
import LarkContainer
import TangramService
import LarkMessageBase
import TangramComponent
import LKCommonsLogging
import RenderRouterInterface

/// 负责预览卡片注册 & 创建
final class ComponentCardRegistry {
    static let logger = Logger.log(ComponentCardRegistry.self, category: "DynamicURLComponent.ComponentCardRegistry")

    // 若后续需要自定义VM Factory的，可以新增注册provider的形式
    static let componentVMs: [Basic_V1_URLPreviewComponent.TypeEnum: ComponentURLBaseViewModel.Type] = [
        .text: UILabelComponentViewModel.self,
        .oversizedText: OversizedTextComponentViewModel.self,
        .image: UIImageViewComponentViewModel.self,
        .avatar: AvatarComponentViewModel.self,
        .time: TimerViewComponentViewModel.self,
        .header: HeaderComponentViewModel.self,
        .spinButton: SpinButtonComponentViewModel.self,
        .empty: EmptyComponentViewModel.self,
        .chattersPreview: AvatarListComponentViewModel.self,
        .button: ButtonComponentViewModel.self,
        .textButton: TextButtonComponentViewModel.self,
        .iconButton: IconButtonComponentViewModel.self,
        .tagList: TagListComponentViewModel.self,
        .richtext: RichLabelComponentViewModel.self,
        .video: VideoCoverComponentViewModel.self,
        .linearLayout: LinearLayoutComponentViewModel.self,
        .flexLayout: FlexLayoutComponentViewModel.self,
        .cardContainer: CardContainerComponentViewModel.self,
        .docImage: DocImageComponentViewModel.self,
        .loading: LoadingComponentViewModel.self,
        .timeZone: TimeZoneComponentViewModel.self,
        .engine: BuildInEngineComponentViewModel.self
    ]

    // 多引擎场景
    static let renderRouterComponentVMs: [Basic_V1_CardComponent.TypeEnum: RenderRouterBaseViewModel.Type] = [
        .flexLayout: RenderRouterFlexLayoutViewModel.self,
        .engine: RenderRouterEngineViewModel.self
    ]

    static func createRenderRouter(entity: URLPreviewEntity,
                                   componentID: String,
                                   renderRouterEntity: Basic_V1_RenderRouterEntity,
                                   ability: ComponentAbility,
                                   dependency: URLCardDependency) -> RenderRouterBaseViewModel? {
        let previewID = entity.previewID
        guard let component = renderRouterEntity.elements[componentID],
              let componentVM = renderRouterComponentVMs[component.type] else {
            logger.error("[URLPreview] createRenderRouter error -> previewID = \(previewID) -> componentID = \(componentID) -> elements = \(renderRouterEntity.elements.keys)")
            return nil
        }
        let engineEntity = renderRouterEntity.engineEntities[componentID]
        let childVMs = component.childIds.compactMap { componentID in
            return createRenderRouter(
                entity: entity,
                componentID: componentID,
                renderRouterEntity: renderRouterEntity,
                ability: ability,
                dependency: dependency
            )
        }
        return componentVM.init(entity: entity,
                                componentID: componentID,
                                component: component,
                                engineEntity: engineEntity,
                                children: childVMs,
                                ability: ability,
                                dependency: dependency)
    }

    static func createPreview(entity: URLPreviewEntity,
                              stateID: String,
                              state: Basic_V1_URLPreviewState,
                              componentID: String,
                              template: Basic_V1_URLPreviewTemplate,
                              ability: ComponentAbility,
                              dependency: URLCardDependency,
                              hideBorder: Bool = false) -> ComponentBaseViewModel? {
        guard var component = template.elements[componentID], let componentVM = componentVMs[component.type] else {
            logger.error("[URLPreview] createPreview error -> stateID = \(stateID) -> componentID = \(componentID) -> elements = \(template.elements.keys)")
            return nil
        }
        let childIDs = component.childIds
        let childVMs = childIDs.compactMap({
            createPreview(entity: entity,
                          stateID: stateID,
                          state: state,
                          componentID: $0,
                          template: template,
                          ability: ability,
                          dependency: dependency)
        })
        var style = component.style
        if let data = state.styles[componentID] {
            style = ComponentPatcherRegistry.stylePatch(base: style, data: data)
            component.style = style
        }
        if hideBorder {
            style.clearBorder()
            component.style = style
        }
        var property = component.urlpreviewComponentProperty
        if let data = state.properties[componentID] {
            property = ComponentPatcherRegistry.propertyPatch(base: property, baseType: component.type, data: data)
            component.urlpreviewComponentProperty = property
        }
        return componentVM.init(entity: entity,
                                stateID: stateID,
                                componentID: componentID,
                                component: component,
                                style: style,
                                property: property,
                                children: childVMs,
                                ability: ability,
                                dependency: dependency)
    }
}
