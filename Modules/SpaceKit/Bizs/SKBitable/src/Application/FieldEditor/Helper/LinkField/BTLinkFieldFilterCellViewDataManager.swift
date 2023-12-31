//
//  BTLinkFieldFilterCellViewDataManager.swift
//  SKBitable
//
//  Created by ZhangYuanping on 2022/7/13.
//  swiftlint:disable file_length type_body_length

import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation
import SKResource
import RxSwift
import UniverseDesignToast
import SKUIKit
import SKCommon

struct BTLinkFieldFilterCellModel {
    var valueFieldType: BTFieldType?
    var conditionId: String
    var fieldErrorType: BTFilterFieldErrorType?
    var conditionButtonModels = [BTConditionSelectButtonModel]()
    var invalidType: BTFieldInvalidType? = .other
}

final class BTLinkFieldFilterCellViewDataManager {
    enum AsyncGetOptionsStatus<T> {
        case success(T)
        case failed
        case loading
    }
    
    let disposeBag = DisposeBag()
    var timeZoneId: String?
    var dataService: BTFilterDataServiceType
    var filterOptions: BTFilterOptions
    var fieldLinkOptions = [String: AsyncGetOptionsStatus<BTFilterLinkOptions>]()
    var fieldUserOptions = [String: BTFilterUserOptions]()
    var asyncResponseCallbacks = [String: (Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void]()
    
    init(dataService: BTFilterDataServiceType, timeZoneId: String?, filterOptions: BTFilterOptions) {
        self.dataService = dataService
        self.timeZoneId = timeZoneId
        self.filterOptions = filterOptions
    }
    
    func update(timeZoneId: String?, filterOptions: BTFilterOptions) {
        self.timeZoneId = timeZoneId
        self.filterOptions = filterOptions
    }
    
    func restCache() {
        self.fieldLinkOptions.removeAll()
        self.fieldUserOptions.removeAll()
        self.asyncResponseCallbacks.removeAll()
    }
    
    func cancelAsyncResponse(conditionId: String) {
        DocsLogger.btInfo("[BTLinkFieldFilterCellViewDataManager] cancelAsyncResponse conditionId:\(conditionId)")
        asyncResponseCallbacks.removeValue(forKey: conditionId)
    }
    
    func convert(conditions: [BTFilterCondition],
                 responseHandler: (([BTLinkFieldFilterCellModel]) -> Void)?,
                 complete: @escaping (_ models: [BTLinkFieldFilterCellModel]) -> Void) {
        fetchExtraOptionsIfNeed(conditions: conditions, responseHandler: responseHandler) { [weak self] in
            let result = self?.convertData(conditions: conditions) ?? []
            complete(result)
        }
    }
    
    func isContainNotSupportField(in conditions: [BTFilterCondition]) -> Bool {
        func conditionFieldIsNotSupport(_ condition: BTFilterCondition) -> Bool {
            let filterField = filterOptions.fieldOptions.first(where: { $0.id == condition.fieldId })
            return filterField?.compositeType.uiType == .notSupport
        }
        return conditions.contains(where: conditionFieldIsNotSupport)
    }
    
    
    private func convertData(conditions: [BTFilterCondition]) -> [BTLinkFieldFilterCellModel] {
        var cellModels = [BTLinkFieldFilterCellModel]()
        for condition in conditions {
            guard let filterField = filterOptions.fieldOptions.first(where: { $0.id == condition.fieldId }) else {
                // 字段已删除
                let model = configFilterCellModel(error: .fieldDeleted, condition: condition)
                cellModels.append(model)
                continue
            }
            
            guard filterField.compositeType.uiType != .notSupport,
                  let valueFieldType = BTFieldType(rawValue: filterField.valueType) else {
                // 字段类型不支持
                DocsLogger.btError("[LinkField] Can't get fieldType \(filterField.compositeType.type)")
                var model = BTLinkFieldFilterCellModel(conditionId: condition.conditionId, invalidType: filterField.invalidType)
                model.fieldErrorType = .fieldNotSupport
                cellModels.append(model)
                continue
            }
            
            guard filterField.compositeType.type.rawValue == condition.fieldType else {
                // 字段类型发生改变
                let model = configFilterCellModel(error: .fieldTypeChanged, condition: condition, field: filterField)
                cellModels.append(model)
                continue
            }
            
            let conditionOperator = filterField.operators.first(where: { $0.value == condition.operator })
            let operatorText = conditionOperator?.text ?? BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer
            let operatorValue = conditionOperator?.value ?? ""
            let icon = filterField.compositeType.icon()
            var fieldNameModel = BTConditionSelectButtonModel(text: filterField.name, icon: icon, showIconLighting: filterField.isSync ?? false, textColor: UDColor.textTitle)
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                if filterField.invalidType == .partNoPermission {
                    fieldNameModel.showLockIcon = true
                }
            }
            let operatorModel = BTConditionSelectButtonModel(text: operatorText, textColor: UDColor.textTitle)
            var buttonModels = [BTConditionSelectButtonModel]()
            buttonModels.append(fieldNameModel)
            var conditionError: BTFilterFieldErrorType?
            switch valueFieldType {
            case .user, .createUser, .lastModifyUser:
                buttonModels.append(operatorModel)
                let result = parseUserFilterValue(condition.value, conditionFieldId: condition.fieldId)
                if !BTFilterOperator.isAsValue(rule: operatorValue) {
                    buttonModels.append(result.0)
                }
                conditionError = result.1
            case .group:
                buttonModels.append(operatorModel)
                let result = parseGroupFilterValue(condition.value as? [[String: Any]])
                if !BTFilterOperator.isAsValue(rule: operatorValue) {
                    buttonModels.append(result)
                }
            case .duplexLink, .singleLink:
                buttonModels.append(operatorModel)
                let result = parseLinkTypeValue(condition.value, conditionFieldId: condition.fieldId)
                if !BTFilterOperator.isAsValue(rule: operatorValue) {
                    buttonModels.append(result.0)
                }
                conditionError = result.1
            case .dateTime, .createTime, .lastModifyTime:
                buttonModels.append(operatorModel)
                if !BTFilterOperator.isAsValue(rule: operatorValue) {
                    let valueModels = parseDateFilterValue(condition.value, filterField: filterField, fieldType: valueFieldType, operatorValue: operatorValue)
                    buttonModels.append(contentsOf: valueModels)
                }
            case .checkbox:
                let values: [Bool] = parseFilterValues(values: condition.value)
                let isSelected = values.first ?? false
                let checkboxModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_BTModule_Equal,
                                                                 type: .checkbox, typeValue: isSelected)
                buttonModels.append(checkboxModel)
            case .singleSelect, .multiSelect, .stage:
                buttonModels.append(operatorModel)
                let result = parseOptionSelectTypeValue(condition.value, filterField: filterField)
                if !BTFilterOperator.isAsValue(rule: operatorValue) {
                    buttonModels.append(result.0)
                }
                conditionError = result.1
            default:
                buttonModels.append(operatorModel)
                if let valueModel = configTextTypeFilterValue(fieldType: valueFieldType,
                                                              operate: operatorValue,
                                                              value: condition.value,
                                                              optionField: filterField) {
                    buttonModels.append(valueModel)
                }
            }
            
            var model = BTLinkFieldFilterCellModel(conditionId: condition.conditionId)
            model.valueFieldType = valueFieldType
            model.fieldErrorType = conditionError
            model.conditionButtonModels = buttonModels
            model.invalidType = condition.invalidType
            cellModels.append(model)
        }
        return cellModels
    }
    
    // 请求额外的条件选项值（关联选项、用户选项数据）
    private func fetchExtraOptionsIfNeed(conditions: [BTFilterCondition],
                                         responseHandler: (([BTLinkFieldFilterCellModel]) -> Void)?,
                                         complete: @escaping (() -> Void)) {
        let group = DispatchGroup()
        for condition in conditions {
            guard let filterField = filterOptions.fieldOptions.first(where: { $0.id == condition.fieldId }) else {
                continue
            }
            let valueFieldType = BTFieldType(rawValue: filterField.valueType) ?? .notSupport
            // 修改说明：BTFieldCompositeType 不再支持传入 nil，将会产生不合法的类型，这里上下文中无法取到对应的 uiType，因此改为直接判断 valueFieldType 的方式
//            let compositeType = BTFieldCompositeType(fieldType: valueFieldType, uiTypeValue: nil)
            if (valueFieldType == .singleLink || valueFieldType == .duplexLink), let selectedIds = condition.value as? [String] {
                var hasCompleteGetLinkOptions = false
                group.enter()
                fieldLinkOptions.updateValue(.loading, forKey: condition.fieldId)
                responseHandler?(self.convertData(conditions: conditions))
                
                getFieldLinkOptionsByIds(condition: condition, recordIds: selectedIds) { [weak self] value in
                    defer {
                        if (!hasCompleteGetLinkOptions) {
                            // 避免多次回调导致crash
                            hasCompleteGetLinkOptions = true
                            group.leave()
                        }
                    }
                    guard let self = self else { return }
                    if let value = value {
                        let linkRecordOptions = self.parseLinkFilterValue(value)
                        self.fieldLinkOptions.updateValue(.success(linkRecordOptions), forKey: condition.fieldId)
                    } else {
                        self.fieldLinkOptions.updateValue(.failed, forKey: condition.fieldId)
                    }
                    
                    self.asyncResponseCallbacks.removeValue(forKey: condition.conditionId)
                }
            } else if (valueFieldType == .user || valueFieldType == .createUser  || valueFieldType == .lastModifyUser) {
                DocsLogger.btInfo("[BTLinkFieldFilterCellViewDataManager] group user enter")
                var hasCompleteGetUserOptions = false
                group.enter()
                getFieldUserOptions(condition: condition) { [weak self] value in
                    defer {
                        if (!hasCompleteGetUserOptions) {
                            // 避免多次回调导致crash
                            hasCompleteGetUserOptions = true
                            group.leave()
                        }
                    }
                    
                    guard let self = self else { return }
                    if let value = value {
                        let linkRecordOptions = self.parseUserFilterValue(value)
                        self.fieldUserOptions[condition.fieldId] = linkRecordOptions
                    }
                    
                    self.asyncResponseCallbacks.removeValue(forKey: condition.conditionId)
                }
            }
        }
        group.notify(queue: .main) {
            complete()
        }
    }
    
    private func getFieldLinkOptionsByIds(condition: BTFilterCondition,
                                          recordIds: [String],
                                          completion: (([[String: Any]]?) -> Void)?) {
        let responseHandlerBlock: (Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void = { [weak self] result in
            guard self != nil else { return }
            //前端异步请求回调
            switch result {
            case .success(let data):
                guard data.result == 0, let options = data.data["options"] as? [[String: Any]] else {
                    completion?(nil)
                    return
                }
                
                completion?(options)
            case .failure(_):
                completion?(nil)
            }
        }
        
        DocsLogger.btInfo("[BTLinkFieldFilterCellViewDataManager] add handler conditionId:\(condition.conditionId)")
        asyncResponseCallbacks.updateValue(responseHandlerBlock, forKey: condition.conditionId)
        
        dataService.getFieldLinkOptionsByIds(byFieldId: condition.fieldId,
                                             recordIds: recordIds,
                                             responseHandler: { [weak self] result in
            guard let response = self?.asyncResponseCallbacks[condition.conditionId] else {
                DocsLogger.btInfo("[BTLinkFieldFilterCellViewDataManager] no asyncHandler conditionId:\(condition.conditionId)")
                completion?(nil)
                return
            }
            response(result)
        }, resultHandler: { [weak self] result in
            guard self != nil else { return }
            if case .failure(_) = result {
                completion?(nil)
            }
        })
    }

    private func getFieldUserOptions(condition: BTFilterCondition, completion: (([[String: Any]]?) -> Void)?) {
        let responseHandlerBlock: (Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void = { [weak self] result in
            guard self != nil else { return }
            //前端异步请求回调
            switch result {
            case .success(let data):
                guard data.result == 0, let userData = data.data["data"] as? [[String: Any]] else {
                    completion?(nil)
                    return
                }
                
                completion?(userData)
            case .failure(_):
                completion?(nil)
            }
        }
        
        asyncResponseCallbacks.updateValue(responseHandlerBlock, forKey: condition.conditionId)
        
        dataService.getFieldOptions(by: condition.fieldId,
                                    with: nil,
                                    router: .getFieldUserOptions,
                                    responseHandler: { [weak self] result in
                                        guard let response = self?.asyncResponseCallbacks[condition.conditionId] else {
                                            DocsLogger.btInfo("[BTLinkFieldFilterCellViewDataManager] no asyncHandler conditionId:\(condition.conditionId)")
                                            completion?(nil)
                                            return
                                        }
                                        response(result)
                                    },
                                    resultHandler: { result in
                                        if case .failure = result {
                                            completion?(nil)
                                        }
                                    })
    }
    
    private func configTextTypeFilterValue(fieldType: BTFieldType, operate: String, value: [Any]?,
                                           optionField: BTFilterOptions.Field) -> BTConditionSelectButtonModel? {
        let values: [String] = parseFilterValues(values: value)
        if BTFilterOperator.isAsValue(rule: operate) {
            // "为空"/"不为空"情况，没有第三个 value 值
            return nil
        }
        var valueText = ""
        // 修改说明：BTFieldCompositeType 不再支持传入 nil，将会产生不合法的类型，这里上下文中无法取到对应的 uiType，因此改为直接判断 valueFieldType 的方式
//        let compositeType = BTFieldCompositeType(fieldType: fieldType, uiTypeValue: nil)
        if fieldType == .dateTime || fieldType == .createTime || fieldType == .lastModifyTime {
            valueText = filterOptions.durationOptions.first(where: { $0.value == values.first })?.text ?? ""
        } else {
            valueText = values.joined(separator: ", ")
        }
        let textColor = valueText.isEmpty ? UDColor.textPlaceholder : UDColor.textTitle
        valueText = valueText.isEmpty ? BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer : valueText
        let hasRightIcon = !fieldType.isInputTypeForFilter
        return BTConditionSelectButtonModel(text: valueText, textColor: textColor, hasRightIcon: hasRightIcon)
    }
    
    // 处理筛选条件异常情况
    private func configFilterCellModel(error: BTFilterFieldErrorType,
                                       condition: BTFilterCondition,
                                       field: BTFilterOptions.Field? = nil) -> BTLinkFieldFilterCellModel {
        var fieldIcon: UIImage?
        if let field = field {
            fieldIcon = field.compositeType.icon()
        }
        var fieldNameTextColor = UDColor.textTitle
        var operatorTextColor = UDColor.textPlaceholder
        var valueTextColor = UDColor.textPlaceholder
        var operatorValueEnable = true
        var conditionOperator = getFilterOperator(condition: condition)
        
        switch error {
        case .fieldDeleted:
            fieldNameTextColor = UDColor.textPlaceholder
            operatorTextColor = UDColor.textDisabled
            valueTextColor = UDColor.textDisabled
            operatorValueEnable = false
        case .fieldTypeChanged:
            conditionOperator = getDefaultFilterOperator(fieldId: field?.id ?? "")
            operatorTextColor = UDColor.textTitle
        default:
            break
        }
        
        let operatorText = conditionOperator?.text ?? BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer
        let fieldName = field?.name ?? BundleI18n.SKResource.Bitable_Relation_FieldWasDeleted_Mobile
        let fieldNameModel = BTConditionSelectButtonModel(text: fieldName,
                                                          icon: fieldIcon,
                                                          showIconLighting: field?.isSync ?? false,
                                                          textColor: fieldNameTextColor)
        let operatorModel = BTConditionSelectButtonModel(text: operatorText,
                                                         enable: operatorValueEnable,
                                                         textColor: operatorTextColor)
        let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                      enable: operatorValueEnable,
                                                      textColor: valueTextColor)
        var buttonModels = [fieldNameModel, operatorModel]
        if !BTFilterOperator.isAsValue(rule: conditionOperator?.value ?? "") {
            buttonModels.append(valueModel)
        }
        if field?.compositeType.uiType.rawValue == BTFieldUIType.checkbox.rawValue {
            let checkboxModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_BTModule_Equal,
                                                             type: .checkbox, typeValue: false)
            buttonModels = [fieldNameModel, checkboxModel]
        }
        var cellModel = BTLinkFieldFilterCellModel(conditionId: condition.conditionId)
        cellModel.conditionButtonModels = buttonModels
        cellModel.fieldErrorType = error
        return cellModel
    }
    
    private func parseFilterValues<T>(values: [Any]?) -> [T] {
        return values as? [T] ?? []
    }
    
    private func parseFieldType(_ type: Int) -> BTFieldType {
        return BTFieldType(rawValue: type) ?? .notSupport
    }
    
    private func getFilterOperator(condition: BTFilterCondition) -> BTFilterOptions.Field.RuleOperator? {
        let ruleOperator = filterOptions
            .fieldOptions.first(where: { $0.id == condition.fieldId })?
            .operators.first(where: { $0.value == condition.operator })
        return ruleOperator
    }
    
    private func getDefaultFilterOperator(fieldId: String) -> BTFilterOptions.Field.RuleOperator? {
        return filterOptions
            .fieldOptions.first(where: { $0.id == fieldId })?
            .operators.first
    }
    
    private func parseLinkFilterValue(_ value: [[String: Any]]) -> BTFilterLinkOptions {
        let links = value.compactMap { obj -> BTFilterLinkOptions.Link? in
            guard let link = try? CodableUtility.decode(BTFilterLinkOptions.Link.self, withJSONObject: obj) else {
                DocsLogger.btError("[BTLinkFieldFilterCellViewDataManager] parseLinkFilterValue data format error")
                return nil
            }
            return link
        }
        
        return BTFilterLinkOptions(data: links)
    }
    
    private func parseUserFilterValue(_ value: [[String: Any]]) -> BTFilterUserOptions {
        let users = value.compactMap { obj -> BTFilterUserOptions.User? in
            guard let user = try? CodableUtility.decode(BTFilterUserOptions.User.self, withJSONObject: obj) else {
                DocsLogger.btError("[BTLinkFieldFilterCellViewDataManager] parseUserFilterValue data format error")
                return nil
            }
            return user
        }
        
        return BTFilterUserOptions(data: users)
    }
    
    private func parseGroupFilterValue(_ value: [[String: Any]]?) -> BTConditionSelectButtonModel {
        guard let value = value else {
            DocsLogger.btError("[BTLinkFieldFilterCellViewDataManager] parseChatterFilterValue data empty")
            return BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                textColor: UDColor.textPlaceholder)
        }
        let names = value.compactMap { obj -> String? in
            do {
                let chatter = try CodableUtility.decode(BTFilterGroupOption.self, withJSONObject: obj)
                return chatter.name
            } catch {
                DocsLogger.btError("[BTLinkFieldFilterCellViewDataManager] parseChatterFilterValue data format error: \(error)")
                return nil
            }
        }
        let text = names.joined(separator: ",")
        if text.isEmpty {
            return BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                textColor: UDColor.textPlaceholder)
        }
        return BTConditionSelectButtonModel(text: text, textColor: UDColor.textTitle)
    }
    
    private func parseUserFilterValue(_ value: [Any]?, conditionFieldId: String) -> (BTConditionSelectButtonModel, BTFilterFieldErrorType?) {
        let userDicts: [[String: Any]] = parseFilterValues(values: value)
        let users = userDicts.compactMap { obj -> BTFilterUserOptions.User? in
            guard let user = try? CodableUtility.decode(BTFilterUserOptions.User.self, withJSONObject: obj) else {
                DocsLogger.btError("[BTLinkFieldFilterCellViewDataManager] parseUserFilterValue data format error")
                return nil
            }
            return user
        }
        
        let userOptions = fieldUserOptions[conditionFieldId]?.data ?? []
        var isValidValues = true
        for user in users {
            let isValidUser = userOptions.contains(where: { $0.userId == user.userId })
            if !isValidUser {
                isValidValues = false
                break
            }
        }

        guard isValidValues else {
            // 存在用户数据不在用户选项中，代表内容被变更
            let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                          enable: false,
                                                          textColor: UDColor.textPlaceholder)
            return (valueModel, .fieldValueChanged)
        }

        let userNames = users.map { user -> String in
            if (Locale.preferredLanguages.first ?? Locale.current.identifier).hasPrefix("zh") {
                return user.name
            } else {
                // 兼容没有英文名用中文名
                return user.enName.isEmpty ? user.name : user.enName
            }
        }
        
        let valueText = userNames.joined(separator: ", ")
        if valueText.isEmpty {
            let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                          textColor: UDColor.textPlaceholder)
            return (valueModel, nil)
        } else {
            let valueModel = BTConditionSelectButtonModel(text: valueText, textColor: UDColor.textTitle)
            return (valueModel, nil)
        }
    }
    
    private func parseDateFilterValue(_ value: [Any]?, filterField: BTFilterOptions.Field, fieldType: BTFieldType, operatorValue: String) -> [BTConditionSelectButtonModel] {
        if let exactDate = value?.first as? String,
           exactDate == BTFilterDuration.ExactDate.rawValue {
            var models = [BTConditionSelectButtonModel]()
            let text = filterOptions.durationOptions.first(where: { $0.value == exactDate })?.text ?? BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer
            let exactDateModel = BTConditionSelectButtonModel(text: text, textColor: UDColor.textTitle)
            models.append(exactDateModel)
            
            let dateModel: BTConditionSelectButtonModel
            if let time = value?.last as? TimeInterval {
                let dateFormat = filterField.dateFormat ?? "yyyy/MM/dd"
                // 前端传过来的是毫秒
                let dateString = BTUtil.dateFormate(time / 1000, dateFormat: dateFormat, timeFormat: "", timeZoneId: timeZoneId)
                dateModel = BTConditionSelectButtonModel(text: dateString, textColor: UDColor.textTitle)
            } else {
                dateModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                              textColor: UDColor.textPlaceholder)
            }
            models.append(dateModel)
            return models
        } else {
            if let valueModel = configTextTypeFilterValue(fieldType: fieldType,
                                                          operate: operatorValue,
                                                          value: value,
                                                          optionField: filterField) {
                return [valueModel]
            }
        }
        return [BTConditionSelectButtonModel(text: "")]
    }
    
    private func parseLinkTypeValue(_ value: [Any]?, conditionFieldId: String) -> (BTConditionSelectButtonModel, BTFilterFieldErrorType?) {
        let records: [String] = parseFilterValues(values: value)
        if records.isEmpty {
            let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                          textColor: UDColor.textPlaceholder)
            return (valueModel, nil)
        } else {
            let optionsStatus = fieldLinkOptions[conditionFieldId]
            switch optionsStatus {
            case .success(let data):
                let linkTexts = data.data.filter { records.contains($0.id) }.map { $0.text }
                if linkTexts.count != records.count {
                    // 条件中的记录内容发生改变，存在没有匹配的记录
                    let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                                  enable: false,
                                                                  textColor: UDColor.textPlaceholder)
                    return (valueModel, .fieldValueChanged)
                } else {
                    let valueText = linkTexts.reduce("") { partialResult, text in
                        let newText = text.isEmpty ? BundleI18n.SKResource.Doc_Block_UnnamedRecord : text
                        if partialResult.isEmpty {
                            return newText
                        } else {
                            return "\(partialResult), \(newText)"
                        }
                    }
                    let valueModel = BTConditionSelectButtonModel(text: valueText, textColor: UDColor.textTitle)
                    return (valueModel, nil)
                }
            case .failed:
                let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_DataReference_LoadingFailed + " " + BundleI18n.SKResource.Bitable_DataReference_TryAgain_Button,
                                                              type: .failed)
                return (valueModel, nil)
            default:
                let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_DataReference_Loading,
                                                              type: .loading)
                return (valueModel, nil)
            }
        }
    }
    
    private func parseOptionSelectTypeValue(_ value: [Any]?,
                                            filterField: BTFilterOptions.Field) -> (BTConditionSelectButtonModel, BTFilterFieldErrorType?) {
        let values: [String] = parseFilterValues(values: value)
        if values.isEmpty {
            let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                          textColor: UDColor.textPlaceholder)
            return (valueModel, nil)
        } else {
            let flatValues = values.compactMap { value in
                return filterField.selectFieldOptions?.first(where: { $0.id == value })?.name
            }
            if flatValues.count != values.count {
                // 解析出的选项数量不一致，说明选项内容有变更
                let valueModel = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer,
                                                              enable: false,
                                                              textColor: UDColor.textPlaceholder)
                return (valueModel, .fieldValueChanged)
            } else {
                let valueText = flatValues.joined(separator: ", ")
                let valueModel = BTConditionSelectButtonModel(text: valueText, textColor: UDColor.textTitle)
                return (valueModel, nil)
            }
        }
    }
}
