//
//  RenderRouterEngineViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/7/31.
//

import RustPB
import LarkModel
import LarkSetting
import TangramComponent
import TangramUIComponent
import RenderRouterInterface

public final class RenderRouterEngineViewModel: RenderRouterBaseViewModel {
    public override var component: Component {
        if let component = engine?.tcComponent {
            sync(from: style, to: component.style)
            return component
        }
        assertionFailure("no engine")
        return Component()
    }
    private var _engine: EngineComponentInterface?
    private var engine: EngineComponentInterface? {
        get {
            safeRead {
                _engine
            }
        }
        set {
            safeWrite {
                _engine = newValue
            }
        }
    }
    private var style: Basic_V1_CardComponent.Style
    private let engineType: Basic_V1_CardComponent.EngineProperty.EngineType

    public required init(entity: URLPreviewEntity,
                         componentID: String,
                         component: Basic_V1_CardComponent,
                         engineEntity: Basic_V1_EngineEntity?,
                         children: [ComponentBaseViewModel],
                         ability: ComponentAbility,
                         dependency: URLCardDependency) {
        self.style = component.style
        self.engineType = component.engine.type
        super.init(entity: entity,
                   componentID: componentID,
                   component: component,
                   engineEntity: engineEntity,
                   children: children,
                   ability: ability,
                   dependency: dependency)
        if let engineEntity = engineEntity, let factory = EngineComponentRegistry.getFactory(type: component.engine.type) {
            self._engine = factory.create(
                previewID: self.entity.previewID,
                componentID: componentID,
                engineEntity: engineEntity,
                dependency: dependency,
                ability: ability
            )
        }
    }

    public override func update(componentID: String,
                                component: Basic_V1_CardComponent,
                                engineEntity: Basic_V1_EngineEntity?,
                                entity: URLPreviewEntity) {
        assert(canUpdate(component: component), "can not update")
        self.style = component.style
        super.update(componentID: componentID, component: component, engineEntity: engineEntity, entity: entity)
        guard let engineEntity = engineEntity else {
            self.engine = nil
            return
        }
        if let engine = self.engine {
            engine.update(previewID: entity.previewID, componentID: componentID, engineEntity: engineEntity)
        } else if let factory = EngineComponentRegistry.getFactory(type: component.engine.type) {
            self.engine = factory.create(
                previewID: entity.previewID,
                componentID: componentID,
                engineEntity: engineEntity,
                dependency: dependency,
                ability: ability
            )
        } else {
            assertionFailure("error update")
            self.engine = nil
        }
    }

    public override func canUpdate(component: Basic_V1_CardComponent) -> Bool {
        return component.type == .engine && component.engine.type == self.engineType
    }

    public override func willDisplay() {
        super.willDisplay()
        engine?.willDisplay()
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        engine?.didEndDisplay()
    }

    public override func onResize() {
        super.onResize()
        engine?.onResize()
    }

    /// 是否能创建当前组件
    public override class func canCreate(previewID: String,
                                         componentID: String,
                                         component: Basic_V1_CardComponent,
                                         engineEntity: Basic_V1_EngineEntity?,
                                         context: EngineComponentFactoryContext) -> Bool {
        guard let engineEntity = engineEntity, let factory = EngineComponentRegistry.getFactory(type: component.engine.type) else {
            return false
        }
        return factory.canCreate(
            previewID: previewID,
            componentID: componentID,
            engineEntity: engineEntity,
            context: context
        )
    }
}
