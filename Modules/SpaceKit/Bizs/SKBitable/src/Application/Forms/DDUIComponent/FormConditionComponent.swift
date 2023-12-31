//
//  BTFormConditionComponent.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/18.
//

import Foundation
import SKFoundation
import HandyJSON
import SpaceInterface

struct BTNewFilterPanelModel: BTDDUIPlayload, Codable {
    struct AddCondition: Codable {
        struct Content: Codable {
            var text: String?
        }
        var backgroudColor: String?
        var borderColor: String?
        var content: Content?
        var leftIcon: BTImageWidgetModel?
        var onClick: String?
    }
    var conjunction: BTNewConditionConjunctionModel?
    var conditions: [BTNewConditionSelectCellModel]?
    var addCondition: AddCondition?
    var hasInvalideCondition: Bool {
        return conditions?.contains { model in
            return model.invalidType == .fieldUnreadable && model.warning != nil
        } ?? false
    }
}

typealias AddCondition = BTNewFilterPanelModel.AddCondition
typealias ConjunctionModel = BTNewConditionConjunctionModel
typealias ConditionModel = BTNewConditionSelectCellModel

struct FormConditionTitleWidgetModel: BTWidgetModelProtocol, Codable {
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var leftText: BTTextWidgetModel?
    var centerText: BTTextWidgetModel?
    var rightText: BTTextWidgetModel?
}


struct FormConditionModel: BTDDUIPlayload, Codable {
    var conjunction: ConjunctionModel?
    var conditions: [ConditionModel]?
    var addCondition: AddCondition?
    var titleBar: FormConditionTitleWidgetModel?
}


final class FormConditionComponent: BTDDUIComponentProtocol {
    
    typealias UIModel = FormConditionModel
    
    private var controller: FormConditionController?
    
    static func convert(from payload: Any?) throws -> FormConditionModel {
        guard let payload = payload as? [String: Any],
              let model = try? CodableUtility.decode(FormConditionModel.self, withJSONObject: payload)
        else { throw BTDDUIError.payloadInvalid }
        return model
    }
    
    func mount(with model: FormConditionModel) throws {
        guard let registeredVC = context?.uiConfig?.hostView.affiliatedViewController,
              let hostVc = UIViewController.docs.topMost(of: registeredVC)
        else { throw BTDDUIError.componentMountFailed }
        let controller = FormConditionController()
        self.controller = controller
        controller.setData(model: model, with: context)
        controller.dismissBlock = { [weak self] in
            self?.onUnmounted()
        }
        BTNavigator.presentVCEmbedInNav(controller, from: hostVc)
    }
    
    func setData(with model: FormConditionModel) throws {
        self.controller?.setData(model: model)
    }
    
    func unmount() {
        self.controller?.dismiss(animated: true)
    }
    
}
