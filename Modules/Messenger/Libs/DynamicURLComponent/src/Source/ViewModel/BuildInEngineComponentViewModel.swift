//
//  BuildInEngineComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/3/2.
//

import RustPB
import LarkSetting
import TangramComponent
import TangramUIComponent

public final class BuildInEngineComponentViewModel: RenderComponentBaseViewModel {
    public override var component: Component {
        if let tcComponent = engine?.tcComponent {
            return tcComponent
        }
        assertionFailure("no engine")
        return Component()
    }
    private var engine: URLEngineAbility?

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let engineProperty = property?.engine ?? .init()
        engine = dependency.createEngine(
            entity: entity,
            property: engineProperty,
            style: style,
            renderStyle: renderStyle
        )
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

    public override class func canCreate(component: Basic_V1_URLPreviewComponent, context: URLCardContext) -> Bool {
        return context.canCreateEngine(property: component.engine, style: component.style)
    }
}
