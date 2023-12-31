//
//  TextButtonComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import Foundation
import RustPB
import LarkCore
import EENavigator
import TangramComponent
import TangramUIComponent

public final class TextButtonComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: UDButtonComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let textButton = property?.textButton ?? .init()
        let props = buildComponentProps(stateID: stateID, componentID: componentID, property: textButton, style: style)
        _component = UDButtonComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        scale(renderStyle)
        return renderStyle
    }

    private func buildComponentProps(stateID: String,
                                     componentID: String,
                                     property: Basic_V1_URLPreviewComponent.TextButtonProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> UDButtonComponentProps {
        let props = UDButtonComponentProps()
        props.isEnabled = !property.isDisable
        props.title = property.text
        let actions = self.entity.previewBody?.states[stateID]?.actions ?? [:]
        if let action = actions[property.actionID] {
            props.onTap.update { [weak self, weak props] in
                guard let self = self, let from = self.dependency.targetVC else { return }
                props?.isLoading = true
                self.ability.updatePreview(component: self.component)
                ComponentActionRegistry.handleAction(
                    entity: self.entity,
                    action: action,
                    actionID: property.actionID,
                    dependency: self.dependency,
                    completion: { [weak self] _ in
                        guard let self = self else { return }
                        props?.isLoading = false
                        self.ability.updatePreview(component: self.component)
                    }
                )
                URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .button, componentID: componentID)
            }
        } else {
            props.onTap.value = nil
            props.isLoading = false
        }
        let config = UDButtonComponentProps.buttonConfig(font: style.tcFont,
                                                         borderColor: style.tcBorderColor,
                                                         backgroundColor: style.tcBackgroundColor,
                                                         textColor: style.tcTextColor,
                                                         semanticContentAttribute: .unspecified)
        props.config.value = config
        return props
    }
}
