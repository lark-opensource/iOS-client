//
//  RenderRouterFlexLayoutViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/7/31.
//

import RustPB
import LarkModel
import LarkSetting
import TangramComponent
import TangramUIComponent

public final class RenderRouterFlexLayoutViewModel: RenderRouterBaseViewModel {
    private var _flexLayoutComponent: FlexLayoutComponent = FlexLayoutComponent(children: [], props: .init())
    private var flexLayoutComponent: FlexLayoutComponent {
        get {
            safeRead {
                _flexLayoutComponent
            }
        }
        set {
            safeWrite {
                _flexLayoutComponent = newValue
            }
        }
    }
    public override var component: Component {
        return flexLayoutComponent
    }

    public required init(entity: URLPreviewEntity,
                         componentID: String,
                         component: Basic_V1_CardComponent,
                         engineEntity: Basic_V1_EngineEntity?,
                         children: [ComponentBaseViewModel],
                         ability: ComponentAbility,
                         dependency: URLCardDependency) {
        super.init(entity: entity,
                   componentID: componentID,
                   component: component,
                   engineEntity: engineEntity,
                   children: children,
                   ability: ability,
                   dependency: dependency)
        let props = buildComponentProps(property: component.flexLayout)
        var layoutStyle = LayoutComponentStyle()
        layoutStyle = sync(from: component.style, to: layoutStyle)
        _flexLayoutComponent = FlexLayoutComponent(children: children.map({ $0.component }), props: props, style: layoutStyle)
    }

    private func buildComponentProps(property: Basic_V1_CardComponent.FlexLayoutProperty) -> FlexLayoutComponentProps {
        var props = FlexLayoutComponentProps()
        props.orientation = property.orientation.tcOrientation
        // 兼容开放平台ColumnSet：宽屏模式下且未配置强制使用窄屏模式时，固定不折叠
        if dependency.contentMaxWidth >= 378, !property.forceUseCompactMode {
            props.flexWrap = .noWrap
        } else {
            props.flexWrap = property.flexWrap.tcFlexWrap
        }
        props.mainAxisSpacing = CGFloat(property.mainAxisSpacing)
        props.crossAxisSpacing = CGFloat(property.crossAxisSpacing)
        props.padding = property.tcPadding
        props.justify = property.mainAxisJustify.tcJustify
        props.align = property.crossAxisAlign.tcAlign
        return props
    }

    public override func update(componentID: String,
                                component: Basic_V1_CardComponent,
                                engineEntity: Basic_V1_EngineEntity?,
                                entity: URLPreviewEntity) {
        assert(canUpdate(component: component), "can not update")
        super.update(componentID: componentID, component: component, engineEntity: engineEntity, entity: entity)
        guard let renderRouter = entity.renderRouter else {
            self.flexLayoutComponent = FlexLayoutComponent(children: [], props: .init())
            return
        }
        var children = children.compactMap { $0 as? RenderRouterBaseViewModel }
        var newChildren: [ComponentBaseViewModel] = []
        let subComponents = component.childIds.compactMap { renderRouter.elements[$0] }
        subComponents.forEach { component in
            if let index = children.firstIndex(where: { $0.canUpdate(component: component) }) {
                let vm = children.remove(at: index)
                vm.update(componentID: componentID, component: component, engineEntity: engineEntity, entity: entity)
                newChildren.append(vm)
            } else if let vm = ComponentCardRegistry.createRenderRouter(entity: entity,
                                                                        componentID: componentID,
                                                                        renderRouterEntity: renderRouter,
                                                                        ability: ability,
                                                                        dependency: dependency) {
                newChildren.append(vm)
            } else {
                assertionFailure("invalid component")
            }
        }
        let props = buildComponentProps(property: component.flexLayout)
        var layoutStyle = LayoutComponentStyle()
        layoutStyle = sync(from: component.style, to: layoutStyle)
        self.flexLayoutComponent = FlexLayoutComponent(children: newChildren.map({ $0.component }), props: props, style: layoutStyle)
        self.children = newChildren
    }

    public override func canUpdate(component: Basic_V1_CardComponent) -> Bool {
        return component.type == .flexLayout
    }
}

extension Basic_V1_CardComponent.FlexLayoutProperty {
    var tcPadding: Padding {
        if hasPadding {
            return .init(top: CGFloat(padding.top),
                         right: CGFloat(padding.right),
                         bottom: CGFloat(padding.bottom),
                         left: CGFloat(padding.left))
        }
        return .zero
    }
}
