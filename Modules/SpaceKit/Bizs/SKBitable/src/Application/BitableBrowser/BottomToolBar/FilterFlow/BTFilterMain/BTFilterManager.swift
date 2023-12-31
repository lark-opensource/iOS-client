//
//  BTFilterManager.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/22.
//  


import SKFoundation
import SKUIKit
import SKResource
import SKCommon
import SKBrowser
import UniverseDesignIcon
import UniverseDesignColor
import EENavigator
import CoreGraphics

enum BTFilterStep: Equatable {
    
    enum ValueStep: Equatable {
        case first
        case second
    }
    
    case field //字段
    case rule //规则
    case value(ValueStep) //值
}

struct BTFilterEventTrackInfo {
    var hostDocsInfo: DocsInfo?
    var baseData: BTEventBaseDataType
    var filterType: String
}


final class BTFilterManager {
    
    private(set) var viewModel: BTFilterViewModel
    private(set) var coordinator: BTFilterCoordinator
    
    private var finishSelecthandler: ((BTFilterCondition) -> Void)?
    private var cancelHandler: (() -> Void)?
    
    var trackInfo: BTFilterEventTrackInfo?
    
    init(viewModel: BTFilterViewModel, coordinator: BTFilterCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
    }
    
    /// 弹起筛选流程
    /// - Parameters:
    ///   - startStep: 从哪个步骤才是弹起来
    ///   - condition: 当前的条件
    ///   - popoverArgs: 这里只有当第一个界面需要适配 ipad popover 才需要传，例如 datePicker
    ///   - finishSelectHandler: 完成后的回调
    ///   - cancelHandler: 取消后的回调
    func showFilterFlowPanel(startStep: BTFilterStep,
                             condition: BTFilterCondition,
                             popoverArgs: BTFilterPopoverArgs? = nil,
                             finishSelectHandler: ((BTFilterCondition) -> Void)?,
                             cancelHandler: (() -> Void)?) {
        
        
        DocsLogger.btInfo("showFilterFlowPanel step: \(startStep), condition: \(condition)")
        
        viewModel.startHandleCondition(condition, startStep: startStep)
        self.finishSelecthandler = finishSelectHandler
        self.cancelHandler = cancelHandler
        switch startStep {
        case .field:
            openFieldVC(isFirstStep: true)
        case .rule:
            openRulesVC(fieldId: condition.fieldId, isFirstStep: true)
        case .value(let valueStep):
            switch valueStep {
            case .first:
                openValueVC(fieldId: condition.fieldId, isFirstStep: true)
            case .second:
                openFinalValueVC(fieldId: condition.fieldId, isFirstStep: true, popoverArgs: popoverArgs)
            }
        }
    }
    
    private func finish(_ step: BTFilterStep) {
        guard let condition = viewModel.getFinishCondition(finishStep: step) else {
            spaceAssertionFailure("condition should not be nil when finish")
            return
        }
        finishSelecthandler?(condition)
    }
    
    private func cancel() {
        cancelHandler?()
    }
    
    private func refresh(valueType: BTFilterValueDataType) {
        switch valueType {
        case .date:
            guard let dateValueRulesVC = coordinator.topMostVC as? BTFieldCommonDataListController,
                  dateValueRulesVC.action == BTFilterFieldAction.dateValueRule.rawValue else {
                return
            }
            let datas: [BTFieldCommonData] = dateValueRulesVC.data.map {
                var item = $0
                if item.id == BTFilterDuration.ExactDate.rawValue {
                    item.rightSubtitle = viewModel.getCurrentExactDateText()
                }
                return item
            }
            dateValueRulesVC.updateDates(datas)
        default: break
        }
    }
}


// MARK: - Coordinator
extension BTFilterManager {
    
    /// 打开字段面板
    func openFieldVC(isFirstStep: Bool) {
        let data = viewModel.getFieldsCommonData()
        let fieldVC = coordinator.createCommonListController(title: BundleI18n.SKResource.Bitable_Relation_SelectField_Mobile,
                                                             action: .field,
                                                             datas: data.datas,
                                                             selectedIndex: data.selectedIndex)
        fieldVC.delegate = self
        coordinator.openController(fieldVC, isFirstStep: isFirstStep)
    }
    
    /// 打开规则面板
    func openRulesVC(fieldId: String, isFirstStep: Bool) {
        let data = viewModel.getRulesCommonData(by: fieldId)
        self.viewModel.updateConditionOperator(data.selectedRule)
        let rulesVC = coordinator.createCommonListController(title: BundleI18n.SKResource.Bitable_Relation_SelectConditionType_Mobile,
                                                             action: .rule,
                                                             datas: data.datas,
                                                             selectedIndex: data.selectedIndex)
        rulesVC.delegate = self
        coordinator.openController(rulesVC, isFirstStep: isFirstStep)
    }
    
    /// 打开值面板，包括日期规则面板以及最后值类型面板
    func openValueVC(fieldId: String, isFirstStep: Bool, popoverArgs: BTFilterPopoverArgs? = nil) {
        guard  let fieldvalueType = viewModel.getFiledItem(byId: fieldId)?.valueType else {
            return
        }
        switch BTFilterValueType(valueType: fieldvalueType) {
        case .date:
            openDateValueRuleVC(fieldId: fieldId, isFirstStep: isFirstStep)
        default:
            openFinalValueVC(fieldId: fieldId, isFirstStep: isFirstStep, popoverArgs: popoverArgs)
        }
    }
    
    /// 打开日期规则面板
    func openDateValueRuleVC(fieldId: String, isFirstStep: Bool) {
        let rule = viewModel.currentSelectedRule
        viewModel.getDateValueCommonData(fieldId: fieldId,
                                         rule: rule,
                                         isShowExactDateValue: coordinator.isRegularSize) { [weak self] (datas, selectedIndex, values) in
            guard let self = self else { return }
            self.viewModel.updateConditionValue(values)
            let dateRuleVC = self.coordinator.createCommonListController(title: BundleI18n.SKResource.Bitable_Relation_ConditionValue_Mobile,
                                                                         action: .dateValueRule,
                                                                         datas: datas,
                                                                         selectedIndex: selectedIndex)
            dateRuleVC.delegate = self
            self.coordinator.openController(dateRuleVC, isFirstStep: isFirstStep)
        }
    }

    ///  打开最后值类型面板，最后的一个面板。这里要注意日期值面板
    func openFinalValueVC(fieldId: String, isFirstStep: Bool, popoverArgs: BTFilterPopoverArgs?) {
        /*
            isPopInNonFirstStep 代表着当前是 popover，且不是第一步。 案例参考 ipad 上的 ExactDate。
            点击完成时，不进行 finish
            点击取消时，不进行 cancel
            应该不会触发 back
         */
        let isPopInNonFirstStep = popoverArgs != nil && !isFirstStep
        func openValue(by valueDateType: BTFilterValueDataType) {
            let valueVC = coordinator.createValueController(valueDateType: valueDateType) { [weak self] value in
                guard let self = self else { return }
                self.viewModel.updateConditionValue(value)
                self.trackHalfWayEvent(.accomplish(.input))
                /// 如果当前是 popover，且不是第一步，则点击完成时，不进行 finish。
                if isPopInNonFirstStep {
                    self.refresh(valueType: valueDateType)
                } else {
                    self.finish(.value(.first))
                }
            } cancelHandler: { [weak self] type in
                
                guard let self = self else { return }
                switch type {
                case .close(let isByClickMask):
                    if !isByClickMask {
                        self.trackHalfWayEvent(.cancel(.input))
                    }
                    if !isPopInNonFirstStep {
                        self.cancel()
                    }
                case .back:
                    self.viewModel.updateConditionValue(nil)
                }
            }
            // 当值面板消失时有值变化时进行埋点
            (valueVC as? BTFilterValueBaseController)?.didChangeValueWhenDismiss = { [weak self] in
                self?.trackHalfWayEvent(.inputArea(.input))
            }
            coordinator.openController(valueVC, isFirstStep: isFirstStep, popoverArgs: popoverArgs)
        }
        
        self.viewModel.getFilterValueDataType(fieldId: fieldId) { valueDataType in
            if let valueDataType = valueDataType {
                openValue(by: valueDataType)
            }
        }
    }
}

// MARK: - BTFieldCommonDataListDelegate
extension BTFilterManager: BTFieldCommonDataListDelegate {
    func didSelectedItem(_ item: BTFieldCommonData,
                         relatedItemId: String,
                         relatedView: UIView?,
                         action: String,
                         viewController: UIViewController,
                         sourceView: UIView? = nil) {
      
        func dismissAndFinish(_ step: BTFilterStep) {
            viewController.dismiss(animated: true) { [weak self] in
                self?.finish(step)
            }
        }
        trackEvent(withFieldCommonAction: action, isCancel: false, isFinish: false)
        switch BTFilterFieldAction(rawValue: action) {
        case .field?:
            self.viewModel.updateConditionField(fieldId: item.id)
            // 如果是复选框，直接完成返回。
            guard let fieldValueType = self.viewModel.currentSelectedField?.valueType else {
                return
            }
            switch BTFieldType(rawValue: fieldValueType) {
            case .checkbox?:
                if !viewModel.isOriginalField(item.id) {
                    self.viewModel.updateConditionValue([false])
                }
                dismissAndFinish(.field)
            default:
                openRulesVC(fieldId: item.id, isFirstStep: false)
            }
        case .rule?:
            self.viewModel.updateConditionOperator(item.id)
            guard !BTFilterOperator.isAsValue(rule: item.id) else {
                // 如果选择为空或为非空时，直接完成返回。
                dismissAndFinish(.rule)
                return
            }
            if let field = self.viewModel.currentSelectedField {
                openValueVC(fieldId: field.id, isFirstStep: false)
            }
        case .dateValueRule?:
            switch BTFilterDuration(rawValue: item.id) {
            case .ExactDate?:
                var values: [AnyHashable] = [item.id]
                if let dateValue = viewModel.getCurrentExactDateValue() {
                    values.append(dateValue)
                }
                self.viewModel.updateConditionValue(values)
                guard let field = self.viewModel.currentSelectedField else {
                    return
                }
                var popoverArgs: BTFilterPopoverArgs?
                if coordinator.isRegularSize,
                   let fieldDataVC = viewController as? BTFieldCommonDataListController,
                   let sourceView = fieldDataVC.getSourceViewForPopoverFromSelectedItem() {
                    popoverArgs = BTFilterPopoverArgs(sourceView: sourceView, sourceRect: sourceView.bounds)
                }
                openFinalValueVC(fieldId: field.id, isFirstStep: false, popoverArgs: popoverArgs)
            default:
                self.viewModel.updateConditionValue([item.id])
                dismissAndFinish(.value(.first))
            }
        default:
            return
        }
    }
    
    func didClickBackPage(relatedItemId: String, action: String) {
        guard let fieldAction = BTFilterFieldAction(rawValue: action) else {
            return
        }
        switch fieldAction {
        case .field:
            spaceAssertionFailure("filed should not be back") //不可能会来这里的
        case .rule:
            self.viewModel.updateConditionOperator(nil)
        case .dateValueRule:
            self.viewModel.updateConditionValue(nil)
        }
    }
    
    func didClickDone(relatedItemId: String, action: String) {
        trackEvent(withFieldCommonAction: action, isCancel: false, isFinish: true)
        switch BTFilterFieldAction(rawValue: action) {
        case .field?:
            self.finish(.field)
        case .rule?:
            self.finish(.rule)
        case .dateValueRule?:
            self.finish(.value(.first))
        default:
            return
        }
    }
    
    func didClickClose(relatedItemId: String, action: String) {
        cancel()
        trackEvent(withFieldCommonAction: action, isCancel: true, isFinish: false)
    }
    
    func didClickMask(relatedItemId: String, action: String) {
        cancel()
    }
}

// MARK: - event track
extension BTFilterManager {
    
    enum HalfWayEventType {
        enum SettingType: String {
            case field
            case operation
            case input
        }
        case cancel(SettingType)
        case accomplish(SettingType)
        case inputArea(SettingType)
        
        var trackValue: (click: String, type: SettingType) {
            switch self {
            case .cancel(let type): return ("cancel", type)
            case .accomplish(let type): return ("accomplish", type)
            case .inputArea(let type): return ("input_area", type)
            }
        }
    }
    /// 排序各种选择面板相关埋点
    func trackHalfWayEvent(_ event: HalfWayEventType) {
        guard let trackInfo = trackInfo else { return }
        var commonParams = BTEventParamsGenerator.createCommonParams(by: trackInfo.hostDocsInfo,
                                                                baseData: trackInfo.baseData)
        commonParams["target"] = "none"
        commonParams["filterType"] = trackInfo.filterType
        
        let trackValue = event.trackValue
        commonParams["click"] = trackValue.click
        commonParams["setting_type"] = trackValue.type.rawValue
        
        DocsTracker.newLog(enumEvent: .bitableFilterSetHalfwayClick, parameters: commonParams)
    }
    
    func trackEvent(withFieldCommonAction action: String, isCancel: Bool, isFinish: Bool) {
        let settingType: HalfWayEventType.SettingType?
        switch BTFilterFieldAction(rawValue: action) {
        case .field?:
            settingType = .field
        case .rule?:
            settingType = .operation
        case .dateValueRule?:
            settingType = .input
        default:
            settingType = nil
        }
        
        guard let settingType = settingType else {
            return
        }
        if isFinish {
            trackHalfWayEvent(.accomplish(settingType))
        } else if isCancel {
            trackHalfWayEvent(.cancel(settingType))
        } else {
            trackHalfWayEvent(.inputArea(settingType))
        }
    }
}
