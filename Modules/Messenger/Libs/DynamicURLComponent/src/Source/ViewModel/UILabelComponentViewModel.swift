//
//  UILabelComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import TangramComponent
import TangramUIComponent

public final class UILabelComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: UILabelComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let text = property?.text ?? .init()
        let props = buildComponentProps(stateID: stateID,
                                        componentID: componentID,
                                        property: text,
                                        style: style)
        _component = UILabelComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(stateID: String,
                                     componentID: String,
                                     property: Basic_V1_URLPreviewComponent.TextProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> UILabelComponentProps {
        let props = UILabelComponentProps()
        props.text = property.text
        if let font = style.tcFont {
            props.font = font
        }
        if let textColor = style.tcTextColor {
            props.textColor = textColor
        }
        let actions = self.entity.previewBody?.states[stateID]?.actions ?? [:]
        if let action = actions[property.actionID] {
            props.onTap.update { [weak self] in
                guard let self = self else { return }
                ComponentActionRegistry.handleAction(entity: self.entity,
                                                     action: action,
                                                     actionID: property.actionID,
                                                     dependency: self.dependency)
                URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .text, componentID: componentID)
            }
        } else {
            props.onTap.value = nil
        }
        props.numberOfLines = Int(property.numberOfLines)
        return props
    }
}
