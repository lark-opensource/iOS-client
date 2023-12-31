//
//  BTFilterEditComponent.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/18.
//

import Foundation
import HandyJSON
import SKUIKit
import SKResource
import SKBrowser
import SKCommon
import EENavigator
import RxRelay
import SKFoundation
import SpaceInterface

struct BTFilterStepPanelComponentModel: BTDDUIPlayload, BTWidgetModelProtocol, HandyJSON {
    enum Action: String, HandyJSONEnum {
        case pop = "pop"
        case push = "push"
        case refresh = "refresh"
    }
    enum Step: String, HandyJSONEnum {
        case field = "field"
        case `operator` = "operator"
        case subScope = "subScope"
        case value = "value"
    }
    enum ValueType: String, HandyJSONEnum {
        case inputArea = "inputArea"
        case inputNumber = "inputNumber"
        case inputPhone = "inputPhone"
        case datePicker = "datePicker"
        case checkList = "checkList"
        case chatterCheckList = "chatterCheckList"
        case linkCheckList = "linkCheckList"
    }
    
    struct Conent: HandyJSON {
        struct Value: HandyJSON {
            var type: ValueType = .inputArea
            var data: [Any] = []
            var inputValue: BTInputWidgetModel? {
                guard let dict = data.first as? NSDictionary else {
                    return nil
                }
                return try? CodableUtility.decode(BTInputWidgetModel.self, withJSONObject: dict)
            }
            var optionValue: [BTConditionEditModel]? {
                return try? CodableUtility.decode([BTConditionEditModel].self, withJSONObject: data)
            }
            var inputText: String? {
                return try? CodableUtility.decode(BTInputWidgetModel.self, withJSONObject: data.first as? NSDictionary ?? [:]).text
            }
            var datePickerValue: BTTimePickWidgetModel? {
                guard let dict = data.first as? NSDictionary else {
                    return nil
                }
                return try? CodableUtility.decode(BTTimePickWidgetModel.self, withJSONObject: dict)
            }
            var search: BTInputWidgetModel?
        }
        var field: [BTConditionEditModel]?
        var `operator`: [BTConditionEditModel]?
        var valueScope: [BTConditionEditModel]?
        var value: Value?
        var multiple: Bool? // 是否支持多选
    }
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var title: BTTitleWidgetModel?
    var action: Action = .push
    var panelStep: Step = .field
    var content: Conent = Conent()
}

class BTFilterStepPanelComponent {
    var model: BTFilterStepPanelComponentModel?
    var currentVC: UIViewController?
    var modelStack = BehaviorRelay<[BTFilterStepPanelComponentModel]>(value: [])
    var currentModel: BTFilterStepPanelComponentModel? {
        return modelStack.value.last
    }
    
    let baseContext: BaseContext
    
    init(baseContext: BaseContext) {
        self.baseContext = baseContext
        _ = modelStack.asObservable().subscribe { list in
            if list.isEmpty {
                self.onUnmounted()
            }
        }
    }
    
    private func push(_ model: BTFilterStepPanelComponentModel) {
        var modelList = modelStack.value
        modelList.append(model)
        modelStack.accept(modelList)
    }
    
    private func pop() {
        var modelList = modelStack.value
        _ = modelList.popLast()
        modelStack.accept(modelList)
        if let registeredVC = context?.uiConfig?.hostView.affiliatedViewController,
           let hostVc = UIViewController.docs.topMost(of: registeredVC) {
              currentVC = hostVc
        }
    }
    
    private func update(_ model: BTFilterStepPanelComponentModel) {
        var newList = modelStack.value
        _ = newList.popLast()
        newList.append(model)
        modelStack.accept(newList)
    }
}

extension BTFilterStepPanelComponent: BTDDUIComponentProtocol {
    
    static func convert(from payload: Any?) throws -> BTFilterStepPanelComponentModel {
        guard let payload = payload as? NSDictionary,
              let model = BTFilterStepPanelComponentModel.deserialize(from: payload)
        else {
            throw BTDDUIError.payloadInvalid
        }
        return model
    }
    
    typealias UIModel = BTFilterStepPanelComponentModel

    func setData(with model: BTFilterStepPanelComponentModel) throws {
        switch model.action {
        case .pop:
            pop()
            currentVC?.dismiss(animated: true)
        case .push:
            push(model)
            self.model = model
            switch model.panelStep {
            case .field:
                guard let vc = getCommonDataListVC(with: model) else {
                    throw BTDDUIError.setDataFailedInvalidData
                }
                openController(vc, isFirstStep: true)
            case .operator, .subScope:
                guard let vc = getCommonDataListVC(with: model) else {
                    throw BTDDUIError.setDataFailedInvalidData
                }
                openController(vc, isFirstStep: false)
            case .value:
                guard let vc = getValueVC(with: model) else {
                    throw BTDDUIError.setDataFailedInvalidData
                }
                openController(vc, isFirstStep: false)
            }
        case .refresh:
            update(model)
            switch model.panelStep {
            case .field, .operator, .subScope:
                guard let vc = currentVC as? BTFieldCommonDataListController,
                      let datas = model.content.field?.map({ $0.fieldCommonData }) else {
                    throw BTDDUIError.setDataFailedInvalidData
                }
                vc.updateDates(datas)
            case .value:
                switch model.content.value?.type {
                case .inputArea, .inputNumber:
                    if let text = model.content.value?.inputText,
                        let vc = currentVC as? BTFilterValueInputController {
                        vc.update(text)
                    }
                case .chatterCheckList:
                    if let vc = currentVC as? BTFilterValueChattersController,
                       let datas = model.content.value?.optionValue?.compactMap({ $0.chatterModel }) {
                           vc.update(datas)
                    }
                case .checkList:
                    if let vc = currentVC as? BTFilterValueOptionsController,
                       let datas = model.content.value?.optionValue?.compactMap({ $0.capsuleModel }) {
                        vc.update(datas)
                    }
                case .datePicker:
                    break
                case .linkCheckList:
                    if let vc = currentVC as? BTFilterValueLinksController,
                       let datas = model.content.value?.optionValue?.compactMap({ $0.linkRecordModel }) {
                        vc.update(datas)
                    }
                default:
                    break
                }
            }
        }
    }
    
    func mount(with model: BTFilterStepPanelComponentModel) throws {
        self.model = model
        push(model)
        switch model.panelStep {
        case .field, .operator, .subScope:
            guard let vc = getCommonDataListVC(with: model) else { throw  BTDDUIError.componentMountFailed }
            openController(vc, isFirstStep: true)
        case .value:
            guard let vc = getValueVC(with: model) else {
                throw BTDDUIError.componentMountFailed
            }
            openController(vc, isFirstStep: true)
        }
        onMounted()
    }
    
    func getCommonDataListVC(with model: BTFilterStepPanelComponentModel) -> BTFieldCommonDataListController? {
        let title = model.title?.centerText?.text ?? ""
        let datas: [BTConditionEditModel]?
        switch model.panelStep {
        case .field:
            datas = model.content.field
        case .operator:
            datas = model.content.operator
        case .subScope:
            datas = model.content.valueScope
        case .value:
            datas = nil
        }
        guard let datas = datas  else { return nil }
        let listVC = BTFieldCommonDataListController(newData: datas,
                                                     title: title,
                                                     action: model.action.rawValue,
                                                     shouldShowDragBar: false,
                                                     shouldShowDoneButton: true,
                                                     lastSelectedIndexPath: IndexPath(row: 0, section: 0),
                                                     initViewHeightBlock: { [weak self] in
            return (self?.context?.uiConfig?.hostView.window?.bounds.height ?? SKDisplay.activeWindowBounds.height) * 0.8
        })
        listVC.supportedInterfaceOrientationsSetByOutside = .portrait
        listVC.delegate = self
        currentVC = listVC
        listVC.dismissBlock = { [weak self] in
            self?.pop()
        }
        return listVC
    }
    
    func getValueVC(with model: BTFilterStepPanelComponentModel) -> BTFilterValueBaseController? {
        guard let value = model.content.value else {
            return nil
        }
        let title = model.title?.centerText?.text ?? ""
        let vc: BTFilterValueBaseController?
        switch model.content.value?.type {
        case .inputArea:
            let text = model.content.value?.inputText
            let valueVc = BTFilterValueInputController(title: title, type: .text(text), baseContext: self.baseContext)
            vc = valueVc
        case .inputNumber:
            let text = model.content.value?.inputText
            let valueVc = BTFilterValueInputController(title: title, type: .number(text), baseContext: self.baseContext)
            vc = valueVc
        case .inputPhone:
            let text = model.content.value?.inputText
            let valueVc = BTFilterValueInputController(title: title, type: .phone(text), baseContext: self.baseContext)
            vc = valueVc
        case .chatterCheckList:
            let valueVc = BTFilterValueChattersController(title: title,
                                                          datas: value.optionValue?.compactMap({$0.chatterModel}) ?? [],
                                                          isAllowMultipleSelect: model.content.multiple ?? false)
            vc = valueVc
        case .checkList:
            let valueVc = BTFilterValueOptionsController(title: title,
                                                         options: value.optionValue?.compactMap({$0.capsuleModel}) ?? [],
                                                         isAllowMultipleSelect: model.content.multiple ?? false,
                                                         isFromNewFilter: true)
            vc = valueVc
        case .datePicker:
            let dateModel = model.content.value?.datePickerValue
            var date = Date()
            if let timeStamp = dateModel?.timestamp {
                date = Date(timeIntervalSince1970: timeStamp / 1000)
            }
            var timeZone = TimeZone.current
            if let identifier = dateModel?.timeZone, let zone = TimeZone(identifier: identifier) {
                timeZone = zone
            }
            let dateFormat = dateModel?.dateFormat ?? "yyyy/MM/dd"
            let timeFormat = dateModel?.timeFormat ?? ""
            let formatConfig = BTFilterDateView.FormatConfig(dateFormat: dateFormat, timeFormat: timeFormat, timeZone: timeZone)
            let valueVc = BTFilterValueDateController(title: title, date: date, formatConfig: formatConfig, isFromNewFilter: true)
            vc = valueVc
        case .linkCheckList:
            let valueVc = BTFilterValueLinksController(title: title,
                                                       items: value.optionValue?.compactMap({$0.linkRecordModel}) ?? [],
                                                       allowMultipleSelect: model.content.multiple ?? false)
            currentVC = valueVc
            vc = valueVc
        default:
            vc = nil
        }
        vc?.delegate = self
        vc?.dismissBlock = { [weak self] in
            self?.pop()
        }
        currentVC = vc
        return vc
    }
    
    func openController(_ controller: BTDraggableViewController,
                        isFirstStep: Bool) {
        
        guard let registeredVC = context?.uiConfig?.hostView.affiliatedViewController,
              let hostVc = UIViewController.docs.topMost(of: registeredVC) else { return }
        if isFirstStep {
            BTNavigator.presentDraggableVCEmbedInNav(controller, from: hostVc)
        } else {
            Navigator.shared.push(controller, from: hostVc)
        }
    }
    
    func unmount() {
        currentVC?.dismiss(animated: true)
    }
    
}

extension BTFilterStepPanelComponent: BTFilterValueControllerDelegate {
    func valueControllerDidCancel() {
        if let callbackId = currentModel?.title?.leftIcon?.onClick {
            emitEvent(callbackId: callbackId, args: [:])
        }
    }
    
    func valueControllerDidDone(result: [AnyHashable]) {
        if let callbackId = currentModel?.title?.rightText?.onClick {
            var args: [String: AnyHashable] = [:]
            if let value = result.first {
                args["text"] = value
            }
            emitEvent(callbackId: callbackId, args: args)
        }
    }
    
    func valueSelected(_ value: Any, selected: Bool) {
        guard let type = currentModel?.content.value?.type, let contentValue = currentModel?.content.value else { return  }
        switch type {
        case .chatterCheckList:
            if let item = value as? MemberItem, let callbackId = item.callbackId {
                emitEvent(callbackId: callbackId, args: [:])
            }
        case .checkList:
            if let item = value as? BTCapsuleModel, let callbackId = item.callbackId {
                emitEvent(callbackId: callbackId, args: [:])
            }
        case .inputArea, .inputNumber, .inputPhone:
            if let text = value as? String, let callbackId = contentValue.inputValue?.onInputChanged {
                emitEvent(callbackId: callbackId, args: ["text": text])
            }
        case .linkCheckList:
            if let item = value as? BTLinkRecordModel, let callbackId = item.callbackId {
                emitEvent(callbackId: callbackId, args: [:])
            }
        case .datePicker:
            if let text = value as? Double, let callbackId = contentValue.inputValue?.onInputChanged {
                emitEvent(callbackId: callbackId, args: ["text": text])
            }
        }
    }
    
    func search(_ keywords: String) {
        guard let value = currentModel?.content.value else { return }
        if let callbackId = value.search?.onInputChanged {
            self.emitEvent(callbackId: callbackId, args: ["text": keywords])
        }
    }
}

extension BTFilterStepPanelComponent: BTFieldCommonDataListDelegate {
    func didSelectedItem(_ item: BTFieldCommonData, relatedItemId: String, relatedView: UIView?, action: String, viewController: UIViewController, sourceView: UIView? = nil) {
        guard currentModel != nil else { return }
        if let callbackId = item.callbackId {
            emitEvent(callbackId: callbackId, args: [:])
        }
    }
    func commonDataListControllerDidDone() {
        if let callabck = currentModel?.title?.rightText?.onClick {
            emitEvent(callbackId: callabck, args: [:])
        }
    }
    
    func commonDataListControllerDidCancel() {
        if let callabck = currentModel?.title?.leftIcon?.onClick {
            emitEvent(callbackId: callabck, args: [:])
        }
    }
}
