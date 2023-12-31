//
//  EmptyComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import UIKit
import Foundation
import RustPB
import TangramComponent
import TangramUIComponent

public final class EmptyComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: UIViewComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let empty = property?.empty ?? .init()
        let props = buildComponentProps(stateID: stateID, property: empty)
        _component = UIViewComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(stateID: String,
                                     property: Basic_V1_URLPreviewComponent.EmptyProperty) -> UIViewComponentProps {
        let props = UIViewComponentProps()
        let actions = self.entity.previewBody?.states[stateID]?.actions ?? [:]
        if let action = actions[property.actionID] {
            props.onTap.update { [weak self] in
                guard let self = self else { return }
                ComponentActionRegistry.handleAction(entity: self.entity,
                                                     action: action,
                                                     actionID: property.actionID,
                                                     dependency: self.dependency)
            }
        } else {
            props.onTap.value = nil
        }
        return props
    }
}
