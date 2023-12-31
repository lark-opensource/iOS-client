//
//  BTDDUIWidgetFactory.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/12.
//

import Foundation
import LarkWebViewContainer

final class BTDDUIComponentFactory {
    
    static func constructComponent(with model: BTDDUIBaseModel, baseContext: BaseContext) throws -> any BTDDUIComponentProtocol {
        switch model.componentType {
        case .filterStepPanel:
            return BTFilterStepPanelComponent(baseContext: baseContext)
        case .filterConjunctionPanel:
            return BTFilterConjunctionPanelComponent(baseContext: baseContext)
        case .filterLarkFormFieldVisibilityPanel:
            return FormConditionComponent()
        case .colorPanel:
            return FormColorPanelComponent()
        case .formsSharePanel:
            return FormsShareComponent()
        case .unknown:
            throw BTDDUIError.constructComponentFailed
        }
    }
}
