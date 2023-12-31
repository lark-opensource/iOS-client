//
//  BTFilterViewModel.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/29.
//  


import SKFoundation
import SKBrowser
import SKCommon
import UniverseDesignIcon
import Foundation
import RxSwift

enum BTFilterValueType {
    case text
    case number
    case phone
    case user
    case options
    case link
    case date
    case checkbox
    case group
    
    init(valueType: Int) {
        let fieldValueType = BTFieldType(rawValue: valueType) ?? .notSupport
        switch fieldValueType {
        case .text, .url, .formula, .location: self = .text
        case .phone: self = .phone
        case .number, .autoNumber: self = .number
        case .user, .createUser, .lastModifyUser: self = .user
        case .singleSelect, .multiSelect, .stage: self = .options
        case .singleLink, .duplexLink: self = .link
        case .dateTime, .lastModifyTime, .createTime: self = .date
        case .checkbox: self = .checkbox
        case .group:
            self = .group
        // 这按道理应该不会走到这里来的
        case .notSupport, .lookup, .attachment, .virtual:
            spaceAssertionFailure("should not be here")
            self = .text
        }
    }
    
    var defaultValue: [AnyHashable]? {
        switch self {
        case .checkbox: return [false]
        case .date: return [BTFilterDuration.ExactDate.rawValue]
        default: return nil
        }
    }
    
}

enum BTFilterValueDataType {
    case text(String?)
    case number(String?)
    case phone(String?)
    case options(alls: [BTCapsuleModel], isAllowMultipleSelect: Bool)
    case links(viewModel: BTFilterValueLinkViewModel)
    case date(Date, fromat: BTFilterDateView.FormatConfig)
    case chatter(viewModel: BTFilterValueChatterViewModel)
}

final class BTFilterViewModel {
    
    private let disposeBag = DisposeBag()
    /// 筛选所需要的数据
    private(set) var filterOptions: BTFilterOptions
    /// 数据请求服务
    private(set) var dataService: BTFilterDataServiceType
    /// 原始的条件
    private var originalCondition: BTFilterCondition?
    /// 记录筛选流程中的条件
    private(set) var handleCondition: BTFilterCondition?
    /// 获取当前选中的字段筛选数据
    var currentSelectedField: BTFilterOptions.Field? {
        return filterOptions.fieldOptions.first(where: { $0.id == handleCondition?.fieldId })
    }
    /// 获取当前选中的规则
    var currentSelectedRule: String {
        return handleCondition?.operator ?? BTFilterOperator.is.rawValue
    }
    
    init(filterOptions: BTFilterOptions, dataService: BTFilterDataServiceType) {
        self.filterOptions = filterOptions
        self.dataService = dataService
    }
    
    func getFiledItem(byId id: String) -> BTFilterOptions.Field? {
        return filterOptions.fieldOptions.first(where: { $0.id == id })
    }
    
    func isOriginalField(_ fieldId: String) -> Bool {
        return originalCondition?.fieldId == fieldId
    }
}

// MARK: - view Datas
extension BTFilterViewModel {
    
    /// 获取字段列表显示数据
    func getFieldsCommonData() -> (datas: [BTFieldCommonData], selectedIndex: Int) {
        func getIcon(compositeType: BTFieldCompositeType) -> UIImage? {
            return compositeType.icon(size: CGSize(width: 20, height: 20))
        }
        let validFieldOptions = self.filterOptions.fieldOptions.filter {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                if $0.invalidType == .partNoPermission {
                    // 筛选部分无权限
                    return false
                }
            }
            return $0.invalidType != .fieldUnreadable || $0.compositeType.uiType != .notSupport
        }
        let selectedIndex = validFieldOptions.firstIndex(where: { $0.id == self.originalCondition?.fieldId }) ?? 0
        let datas = validFieldOptions.map {
            BTFieldCommonData(id: $0.id,
                              name: $0.name,
                              icon: getIcon(compositeType: $0.compositeType),
                              showLighting: $0.isSync ?? false,
                              rightIocnType: .arraw,
                              selectedType: .textHighlight)
        }
        return (datas, selectedIndex)
    }
    
    /// 获取规则列表显示数据
    func getRulesCommonData(by fieldId: String) -> (datas: [BTFieldCommonData], selectedIndex: Int, selectedRule: String) {
        let defaultOperator = BTFilterOperator.is.rawValue
        guard let operators = self.filterOptions.fieldOptions.first(where: { $0.id == fieldId })?.operators,
              !operators.isEmpty else {
            return ([], 0, defaultOperator)
        }
        var selectedIndex = 0
        if fieldId == originalCondition?.fieldId {
            selectedIndex = operators.firstIndex(where: { $0.value == self.originalCondition?.operator }) ?? 0
        }
        let selectedRule = operators[selectedIndex].value
        func getRightIcon(rule: String) -> BTFieldCommonData.RightIconType {
            return BTFilterOperator.isAsValue(rule: rule) ? .none : .arraw
        }
        let datas = operators.map {
            BTFieldCommonData(id: $0.value,
                              name: $0.text,
                              rightIocnType: getRightIcon(rule: $0.value),
                              selectedType: .textHighlight)
        }
        return (datas, selectedIndex, selectedRule)
    }
    
    /// 获取日期列表显示数据
    func getDateValueCommonData(fieldId: String,
                                rule: String,
                                isShowExactDateValue: Bool = false,
                                completion: ((_ datas: [BTFieldCommonData], _ selectedIndex: Int, _ selectedValue: [AnyHashable]) -> Void)?) {
        
        func getRightSubtitle(duration: String) -> String? {
            guard isShowExactDateValue else {
                return nil
            }
            guard duration == BTFilterDuration.ExactDate.rawValue else {
                return nil
            }
            return getCurrentExactDateText()
        }
        
        func getRightIcon(duration: String) -> BTFieldCommonData.RightIconType {
            return duration == BTFilterDuration.ExactDate.rawValue ? .arraw : .none
        }
        var values: [AnyHashable] = getOriginlValues(by: fieldId)
        values = !values.isEmpty ? values : [BTFilterDuration.ExactDate.rawValue]
        dataService.getFieldDurations(byRule: rule).subscribe { event in
            switch event {
            case .success(let durations):
                let selectedIndex = durations.data.firstIndex(where: { $0.value == (values.first as? String) }) ?? 0
                let datas = durations.data.map {
                    BTFieldCommonData(id: $0.value,
                                      name: $0.text,
                                      rightSubtitle: getRightSubtitle(duration: $0.value),
                                      rightIocnType: getRightIcon(duration: $0.value),
                                      selectedType: .textHighlight)
                }
                completion?(datas, selectedIndex, values)
            default:
                completion?([], 0, values)
            }
           
        }.disposed(by: self.disposeBag)
    }
    
    /// 获取各种值的初始数据
    func getFilterValueDataType(fieldId: String, completion: @escaping (BTFilterValueDataType?) -> Void) {
        guard let fieldItem = getFiledItem(byId: fieldId) else {
            completion(nil)
            return
        }
        let filterValueType = BTFilterValueType(valueType: fieldItem.valueType)
        switch filterValueType {
        case .text:
            let text: String? = getOriginlValues(by: fieldId).first
            completion(.text(text))
        case .number:
            let number: String? = getOriginlValues(by: fieldId).first
            completion(.number(number))
        case .phone:
            let phone: String? = getOriginlValues(by: fieldId).first
            completion(.phone(phone))
        case .options:
            self.getFilterValueDataTypeOptions(fieldItem: fieldItem, completion: completion)
        case .link:
            //请求逻辑放到BTFilterValueLinksController里去执行
            let recordIds: [String] = getOriginlValues(by: fieldId)
            
            var isMultiple = true
            // 双向关联 允许添加多条记录->不允许添加多条记录  视图的双向关联数据依旧保持多条数据 此时筛选如果是单选，则无法筛选出相关数据
            if fieldItem.compositeType.uiType == .singleLink &&
                !(fieldItem.multiple ?? false) &&
                BTFilterOperator.isEqual(rule: self.currentSelectedRule) {
                isMultiple = false
            }
            
            let viewModel = BTFilterValueLinkViewModel(fieldId: fieldId,
                                                       selectedRecordIds: recordIds,
                                                       isAllowMultipleSelect: isMultiple,
                                                       btDataService: self.dataService)
            completion(.links(viewModel: viewModel))
        case .date:
            self.getFilterValueDataTypeDate(fieldItem: fieldItem, completion: completion)
        case .checkbox:
            completion(nil)
        case .group, .user:
            // 后续稳定后，迁移user过来
            var isMultiple = true
            if !(fieldItem.multiple ?? false) &&
                BTFilterOperator.isEqual(rule: self.currentSelectedRule) {
                isMultiple = false
            }
            let chatterType: BTChatterType = filterValueType == .group ? .group : .user
            let viewModel = BTFilterValueChatterViewModel(fieldId: fieldId,
                                                          selectedMembers: self.getChatterDataValue(by: fieldId, type: chatterType),
                                                          isAllowMultipleSelect: isMultiple,
                                                          chatterType: chatterType,
                                                          btDataService: self.dataService)

            completion(.chatter(viewModel: viewModel))
        }
    }
    
    /// 获取时间字段的具体日期时间戳
    func getCurrentExactDateValue() -> Double? {
        if let newExactDateValue = handleCondition?.getExactDateValueIfExist(with: filterOptions) {
            return newExactDateValue
        }
        if let exactDateValue = originalCondition?.getExactDateValueIfExist(with: filterOptions) {
            return exactDateValue
        }
        return nil
    }
    
    /// 获取时间字段的具体日期的文案
    func getCurrentExactDateText() -> String? {
        if let exactDateValue = getCurrentExactDateValue(),
           let field = self.currentSelectedField,
           let dateFormat = field.dateFormat {
            return BTUtil.dateFormate(exactDateValue / 1000,
                                      dateFormat: dateFormat,
                                      timeFormat: "",
                                      timeZoneId: self.filterOptions.timeZone,
                                      displayTimeZone: false)
        }
        return nil
    }
    
    private func getUserDateValue(by fieldId: String) -> [MemberItem] {
        let userDicts: [[String: Any]] = getOriginlValues(by: fieldId)
        let users = userDicts.compactMap { obj -> BTFilterUserOptions.User? in
            guard let user = try? CodableUtility.decode(BTFilterUserOptions.User.self, withJSONObject: obj) else {
                DocsLogger.btError("[BTFilterViewModel] getUserDateValue data format error")
                return nil
            }
            return user
        }
        
        let members = users.map {
            MemberItem(identifier: $0.userId,
                       selectType: .blue,
                       imageURL: $0.avatarUrl,
                       title: $0.name,
                       detail: "",
                       token: "",
                       isExternal: false,
                       displayTag: nil,
                       isCrossTenanet: false)
        }
        
        return members
    }
    
    private func getChatterDataValue(by fieldId: String, type: BTChatterType) -> [MemberItem] {
        let chatterDicts: [[String: Any]] = getOriginlValues(by: fieldId)
        let chatters = chatterDicts.compactMap { obj -> BTFilterChatterOptionProtocol? in
            do {
                let modelType: BTFilterChatterOptionProtocol.Type = (type == .group) ? BTFilterGroupOption.self : BTFilterUserOption.self
                let chatter = try CodableUtility.decode(modelType, withJSONObject: obj)
                return chatter
            } catch {
                DocsLogger.btError("[BTFilterViewModel] getGroupDataValue data format error: \(error)")
                return nil
            }
        }
        
        let members = chatters.map {
            MemberItem(identifier: $0.chatterId,
                       selectType: .blue,
                       imageURL: $0.avatarUrl,
                       title: $0.name,
                       detail: "",
                       token: "", // 筛选里群组不需要跳转
                       isExternal: false,
                       displayTag: nil,
                       isCrossTenanet: false)
        }
        
        return members
    }
    
    /// 解析当前条件中的各字段的值
    private func getOriginlValues<T>(by fieldId: String) -> [T] {
        if let condition = self.originalCondition,
            condition.fieldId == fieldId {
            return (condition.value as? [T]) ?? []
        }
        return []
    }
}


// MARK: - condition handle
extension BTFilterViewModel {
    /// 初始化处理条件
    /// - Parameter condition: 条件
    func startHandleCondition(_ condition: BTFilterCondition, startStep: BTFilterStep) {
        self.originalCondition = condition
        self.handleCondition = BTFilterCondition(conditionId: condition.conditionId,
                                                 fieldId: condition.fieldId,
                                                 fieldType: condition.fieldType)
        switch startStep {
        case .field: break
        case .rule:
            self.handleCondition?.operator = condition.operator
        case .value:
            self.handleCondition?.operator = condition.operator
            self.handleCondition?.value = condition.value
        }
    }
    
    /*
        规则
        1. 在某步骤点击完成按钮，只保存当前以及前面的步骤的选择。如果当前以及前面的步骤相对原条件有修改则，将后面的步骤置为默认值。如果都没有修改则相当于点击 x 按钮。
        1.1 有修改的例子：原有是 合同编号 -> 不等于 -> 011111 ，如果将不等于改为等于，然后用户在选择规则页面点击完成，那么就值为置为默认值（空）合同编号 -> 不等于
        2. 用户修改了文本值点击返回后默认用户放弃所填写的内容，下次进入默认文本还是原先条件的值。
     */
    func getFinishCondition(finishStep: BTFilterStep) -> BTFilterCondition? {
        guard let newCondition = handleCondition else {
            spaceAssertionFailure("condition should not be nil when finish")
            return nil
        }
        switch finishStep {
        case .field:
            if originalCondition?.fieldId == newCondition.fieldId {
                return originalCondition
            } else {
                return newCondition
            }
        case .rule:
            if originalCondition?.fieldId == newCondition.fieldId,
               originalCondition?.operator == newCondition.operator {
                return originalCondition
            } else {
                return newCondition
            }
        case .value:
            return handleCondition
        }
    }
    /// 更新字段值
    /// - Parameter fieldId: 字段值
    func updateConditionField(fieldId: String) {
        if let field = filterOptions.fieldOptions.first(where: { $0.id == fieldId }),
        let originalCondition = originalCondition {
            self.handleCondition = BTFilterCondition(conditionId: originalCondition.conditionId,
                                                     fieldId: field.id,
                                                     fieldType: field.compositeType.type.rawValue)
        }
    }
    /// 更新规则
    /// - Parameter operator: 如果 operator 为 nil，则为清空
    func updateConditionOperator(_ operator: String?) {
        self.handleCondition?.operator = `operator` ?? "is"
    }
    /// 更新条件值
    /// - Parameter operator: 如果 value 为 nil，则为清空
    func updateConditionValue(_ value: [AnyHashable]?) {
        self.handleCondition?.value = value
    }
}


// MARK: - get filterValue submethod
extension BTFilterViewModel {
    private func getFilterValueDataTypeOptions(fieldItem: BTFilterOptions.Field, completion: @escaping (BTFilterValueDataType?) -> Void) {

        dataService.getColorList(byFieldId: fieldItem.id).subscribe { [weak self] event in
            guard let self = self else { return }
            let colors: [BTColorModel]
            switch event {
            case .success(let colorList):
                colors = colorList.ColorList
            default:
                colors = []
            }
            var isMultiple = true
            if fieldItem.valueType == BTFieldType.singleSelect.rawValue,
                BTFilterOperator.isEqual(rule: self.currentSelectedRule) {
                isMultiple = false
            }
            var selecteds: [String] = self.getOriginlValues(by: fieldItem.id)
            if !isMultiple, let firstSelected = selecteds.first {
                selecteds = [firstSelected]
            }
            let selectedIdsSet: Set<String> = Set(selecteds)
            let alls: [BTCapsuleModel] = (fieldItem.selectFieldOptions ?? []).map { item in
                let colorModel = colors.first(where: { $0.id == item.color }) ?? BTColorModel()
                return BTCapsuleModel(id: item.id, text: item.name, color: colorModel, isSelected: selectedIdsSet.contains(item.id))
            }
            
            
            let filterValueData = BTFilterValueDataType.options(alls: alls, isAllowMultipleSelect: isMultiple)
            completion(filterValueData)
        }.disposed(by: self.disposeBag)
    }
    
    private func getFilterValueDataTypeDate(fieldItem: BTFilterOptions.Field, completion: @escaping (BTFilterValueDataType?) -> Void) {
        var date = Date()
        if let stamp = getCurrentExactDateValue() {
            date = Date(timeIntervalSince1970: stamp / 1000)
        }
        func getFormat() -> BTFilterDateView.FormatConfig {
            var format = BTFilterDateView.FormatConfig()
            if let dateFormat = self.currentSelectedField?.dateFormat {
                format.dateFormat = dateFormat
            }
            if let timeZoneId = self.filterOptions.timeZone {
                format.timeZone = TimeZone(identifier: timeZoneId) ?? .current
            }
            return format
        }
        completion(.date(date, fromat: getFormat()))
    }
}
