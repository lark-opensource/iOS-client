//
//  BTFilterHelper.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/28.
//  


import SKResource

final class BTFilterHelper {
    
    /// 检测某个 condition 是否可以从某个 BTFilterStep 开始
    static func checkFilterConditionStepValid(step: BTFilterStep,
                                              filterCondition: inout BTFilterCondition,
                                              filterOptions: BTFilterOptions,
                                              fieldErrorType: BTFilterFieldErrorType?) -> (isValid: Bool, toast: String?) {
        guard let fieldErrorType = fieldErrorType else {
            return (true, nil)
        }
        switch fieldErrorType {
        case .fieldDeleted:
            // 字段被删，点击operator和value时弹toast提示，无需进入筛选组件
            if case .field = step {
                return (true, nil)
            } else {
                return (false, BundleI18n.SKResource.Bitable_Relation_PleaseSelectFieldToast_Mobile)
            }
        case .fieldTypeChanged:
            // 字段类型发生变化情况，需把当前正确的 fieldType 赋到当前的条件中
            let currentField = filterOptions.fieldOptions.first(where: { $0.id == filterCondition.fieldId })
            let ruleOperator = currentField?.operators.first?.value ?? ""
            let fieldTypeValue = (currentField?.compositeType.type ?? .notSupport).rawValue
            filterCondition.fieldType = fieldTypeValue
            filterCondition.operator = ruleOperator
            filterCondition.value = []
        case .fieldValueChanged:
            // 字段内容变更，把当前内容清空再传入筛选组件
            filterCondition.value = []
        default: break
        }
        return (true, nil)
    }
    
    /// 根据 index 获取开始步骤
    static func getFilterStep(by index: Int) -> BTFilterStep {
        var step = BTFilterStep.field
        switch index {
        case 0: step = .field
        case 1: step = .rule
        case 2: step = .value(.first)
        case 3: step = .value(.second)
        default:
            break
        }
        return step
    }
    
    /// 获取 任一/所有面板数据
    static func getConjunctionModels(by filterOptions: BTFilterOptions,
                                     conjuctionValue: String) -> (models: [BTConjuctionSelectedModel], selectedIndex: Int) {
        let models = filterOptions.conjunctionOptions.map {
            BTConjuctionSelectedModel(title: $0.text)
        }
        let selectedIndex = filterOptions.conjunctionOptions.firstIndex(where: { $0.value == conjuctionValue }) ?? 0
        return (models, selectedIndex)
    }
}
