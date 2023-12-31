//
//  BTFieldEditViewModel.swift
//  SKBitable
//
//  Created by zoujie on 2022/9/27.
//  swiftlint:disable file_length type_body_length

import SKFoundation
import SKCommon
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import LarkSetting

final class BTFieldEditViewModel {
    var fieldEditModel: BTFieldEditModel

    private(set) var oldFieldEditModel: BTFieldEditModel
    
    private let maxNumberOfFieldName = 100 // 字段名最大字符数
    
    private let numberFieldCurrencyPrefix = "#,##" //数字字段货币格式前缀，用来数字字段和货币字段之间格式转换
    
    var cellViewDataManager: BTLinkFieldFilterCellViewDataManager?

    weak var dataService: BTDataService?
    
    var commonData: BTCommonData
    
    @Setting(key: UserSettingKey.make(userKeyLiteral: "ccm_bitable_field_name_max_length"))
    private var bitableFieldNameMaxCount: Int?
    
    var isCurrentExtendChildType: Bool {
        fieldEditModel.fieldExtendInfo != nil
    }
    
    var isCurrentExtendChildTypeChanged: Bool {
        fieldEditModel.fieldExtendInfo != oldFieldEditModel.fieldExtendInfo
    }
    
    var fieldExtendRefreshState: FieldExtendRefreshButtonState {
        if let notice = fieldEditModel.editNotice {
            switch notice {
            case .noExtendFieldPermForOwner, .noExtendFieldPermForUser, .originMultipleEnable:
                return .disable
            case .originDeleteForOwner, .originDeleteForUser:
                return .hidden
            }
        }
        guard !isCurrentExtendChildTypeChanged else {
            // 如果字段扩展信息被修改了，隐藏刷新按钮
            return .hidden
        }
        guard !fieldEditModel.fieldId.isEmpty else {
            // 是新增字段，隐藏刷新按钮
            return .hidden
        }
        guard fieldEditModel.fieldExtendInfo?.editable == true else {
            // 不可编辑（不是 owner），禁用刷新
            return .disable
        }
        return .normal
    }
    
    var extendManager: BTFieldExtendManager?
    
    lazy var fieldEditConfig: BTFieldEditConfig = BTFieldEditConfig()
    
    var dynamicOptionsEnable = LKFeatureGating.bitableDynamicOptionsEnable
    
    // 级联是否部分无权限(只有scheme4文档下才会为true，老文档isPartialDenied是nil)
    var isDynamicPartNoPerimission: Bool {
        commonData.isDynamicPartNoPerimission(targetTable: dynamicOptionRuleTargetTable, targetField: dynamicOptionRuleTargetField)
    }
    // 级联引用表是否有权限
    var dynamicTableReadPerimission: Bool {
        commonData.dynamicTableReadPerimission(targetTable: dynamicOptionRuleTargetTable)
    }
    // 级联引用字段是否无权限
    var isDynamicFieldDenied: Bool {
        commonData.isDynamicFieldDenied(targetField: dynamicOptionRuleTargetField)
    }
    // 级联表部分无权限
    var isDynamicTablePartialDenied: Bool {
        if let linkTable = commonData.tableNames.first(where: { $0.tableId == dynamicOptionRuleTargetTable }) {
            if linkTable.isPartialDenied == true {
                return true
            }
        }
        return false
    }
    // 关联表权限
    var linkTableReadPerimission: Bool {
        if let linkTable = commonData.tableNames.first(where: { $0.tableId == fieldEditModel.fieldProperty.tableId }) {
            return linkTable.readPerimission
        }
        return false
    }
    // 关联表部分无权限
    var isLinkTablePartialDenied: Bool {
        commonData.isLinkTablePartialDenied(tableID: fieldEditModel.fieldProperty.tableId)
    }
    
    //静态选项
    var options: [BTOptionModel] {
        get {
            return fieldEditModel.fieldProperty.options
        }

        set {
            fieldEditModel.fieldProperty.options = newValue
        }
    }
    
    //级联选项条件列表
    var dynamicOptionsConditions: [BTDynamicOptionConditionModel] {
        get {
            return fieldEditModel.fieldProperty.optionsRule.conditions
        }

        set {
            fieldEditModel.fieldProperty.optionsRule.conditions = newValue
        }
    }
    
    //自动编号规则
    var auotNumberRuleList: [BTAutoNumberRuleOption] {
        get {
            return fieldEditModel.fieldProperty.ruleFieldOptions
        }

        set {
            fieldEditModel.fieldProperty.ruleFieldOptions = newValue
        }
    }
    
    var linkTableFilterInfo: BTFilterInfos? {
        get {
            return fieldEditModel.fieldProperty.filterInfo
        }
        set {
            fieldEditModel.fieldProperty.filterInfo = newValue
        }
    }
    
    var dynamicOptionRuleTargetTable: String {
        get {
            return fieldEditModel.fieldProperty.optionsRule.targetTable
        }
        
        set {
            fieldEditModel.fieldProperty.optionsRule.targetTable = newValue
        }
    }
    
    var dynamicOptionRuleTargetField: String {
        get {
            return fieldEditModel.fieldProperty.optionsRule.targetField
        }
        
        set {
            fieldEditModel.fieldProperty.optionsRule.targetField = newValue
        }
    }
    
    var dynamicOptionRuleConjunction: String {
        get {
            return fieldEditModel.fieldProperty.optionsRule.conjunction
        }
        
        set {
            fieldEditModel.fieldProperty.optionsRule.conjunction = newValue
        }
    }
    
    var editingFieldCellHasErrorIndexs: [Int] = []
    
    var linkFieldFilterCellModels = [BTLinkFieldFilterCellModel]()
    
    init(fieldEditModel: BTFieldEditModel,
         commonData: BTCommonData,
         dataService: BTDataService?) {
        self.commonData = commonData
        self.dataService = dataService
        self.fieldEditModel = fieldEditModel
        self.oldFieldEditModel = fieldEditModel
        initData()
    }
    
    func initData() {
        if fieldEditModel.compositeType.uiType == .autoNumber {
            var i = 0
            auotNumberRuleList = auotNumberRuleList.map { rule in
                guard let ruleList = commonData.fieldConfigItem.commonAutoNumberRuleTypeList.first(where: { $0.isAdvancedRules })?.ruleFieldOptions,
                      let defaultRule = ruleList.first(where: { $0.type == rule.type }) else { return rule }

                var r = rule
                r.id = String(i)
                r.title = defaultRule.title
                r.description = defaultRule.description

                if rule.type == .createdTime {
                    //转换日期格式 yyyymmdd -> 20220301
                    r.value = defaultRule.optionList.first(where: { $0.format.lowercased() == rule.value.lowercased() })?.text ?? ""
                }
                i += 1
                return r
            }
            
            //初始数据格式转换后需要赋值给旧值，避免后续判断是否改动时出错
            oldFieldEditModel.fieldProperty.ruleFieldOptions = auotNumberRuleList
        }
        
        if fieldEditModel.compositeType.classifyType == .link {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                // 不用筛选
            } else {
            if checkLinkedTableExist() == false {
                linkTableFilterInfo = nil
            }
            }
            let filterCount = fieldEditModel.fieldProperty.filterInfo?.conditions.count ?? 0
            // 若没有过滤条件，即关联所有字段
            fieldEditModel.isLinkAllRecord = filterCount <= 0
        }
    }
    
    /// 检查关联的table是否存在
    func checkLinkedTableExist() -> Bool {
        let table = fieldEditModel.tableNameMap.first(where: { $0.tableId == fieldEditModel.fieldProperty.tableId })
        let isExist = table != nil
        return isExist
    }
    
    func createNormalCommitChangeProperty() -> [String: Any] {
        if let property = fieldEditConfig.createNormalCommitChangeProperty() {
            // 新字段走新逻辑
            return property
        }
        var property: [String: Any] = [:]

        switch fieldEditModel.compositeType.uiType {
        case let type where type.classifyType == .date:
            if fieldEditModel.compositeType.uiType == .dateTime {
                property["autoFill"] = fieldEditModel.fieldProperty.autoFill
            }
            property["dateFormat"] = fieldEditModel.fieldProperty.dateFormat
            property["timeFormat"] = fieldEditModel.fieldProperty.timeFormat
            property["displayTimeZone"] = fieldEditModel.fieldProperty.displayTimeZone
        case let type where type.classifyType == .link:
            property["baseId"] = fieldEditModel.baseId
            property["tableId"] = fieldEditModel.fieldProperty.tableId
            //允许添加多个记录
            property["multiple"] = fieldEditModel.fieldProperty.multiple
            if !fieldEditModel.isLinkAllRecord {
                let filterInfo = fieldEditModel.fieldProperty.filterInfo ?? BTFilterInfos()
                property["filterInfo"] = filterInfo.toDict()
            }

            if fieldEditModel.compositeType.uiType == .duplexLink {
                property["backFieldName"] = fieldEditModel.fieldProperty.backFieldName
                property["backFieldId"] = fieldEditModel.fieldProperty.backFieldId
            }
        case .autoNumber:
            //自定义规则 or 自增数字
            property["isAdvancedRules"] = fieldEditModel.fieldProperty.isAdvancedRules
            //编号规则发生变更，是否修改已有的记录编号
            property["reformatExistingRecord"] = fieldEditModel.fieldProperty.reformatExistingRecord
            if fieldEditModel.fieldProperty.isAdvancedRules {
                property["ruleFieldOptions"] = BTFieldEditUtil.generateAutoNumberJSON(auotNumberRuleList: auotNumberRuleList,
                                                                                      commonData: commonData)
            }
        case let type where type.classifyType == .option:
            property["optionsType"] = fieldEditModel.fieldProperty.optionsType.rawValue
            if fieldEditModel.fieldProperty.optionsType == .dynamicOption {
                //级联选项
                property["options"] = []
                property["optionsRule"] = fieldEditModel.fieldProperty.optionsRule.toJSON()
            } else {
                //自定义选项
                property["options"] = BTFieldEditUtil.generateOptionJSON(options: fieldEditModel.fieldProperty.options)
            }
        case .attachment:
            property["capture"] = fieldEditModel.fieldProperty.capture
        case .number:
            property["formatter"] = fieldEditModel.fieldProperty.formatter
        case .currency:
            property["currencyCode"] = fieldEditModel.fieldProperty.currencyCode
            property["formatter"] = fieldEditModel.fieldProperty.formatter
        case .user, .group:
            property["multiple"] = fieldEditModel.fieldProperty.multiple
        case .location:
            property["inputType"] = fieldEditModel.fieldProperty.inputType.rawValue
        case .progress:
            // 需要保证所有的值都有，即使没有修改也得有，如果有值不合法，将会导致文档卡死的致命异常
            var formatter: String = fieldEditModel.fieldProperty.formatter
            if formatter.isEmpty, let formatConfig = commonData.fieldConfigItem.getCurrentFormatConfig(fieldEditModel: fieldEditModel) {
                formatter = formatConfig.typeConfig.getFormatCode(decimalDigits: formatConfig.decimalDigits)
            }
            
            let rangeConfig = commonData.fieldConfigItem.getCurrentRangeConfig(fieldEditModel: fieldEditModel)
            let rangeCustomize: Bool = rangeConfig.rangeCustomize
            let min: Double = rangeConfig.min
            let max: Double = rangeConfig.max
            
            if max <= min {
                let errMsg = "progress max must great than min"
                DocsLogger.error(errMsg)
                spaceAssertionFailure(errMsg)
            }
            
            var progress: BTProgressModel = fieldEditModel.fieldProperty.progress ?? BTProgressModel()
            if progress.color == nil {
                let colorConfig = commonData.fieldConfigItem.getCurrentColorConfig(fieldEditModel: fieldEditModel)
                progress.color = colorConfig?.selectedColor
            }
            let progressJson = progress.toJSON()
            if progress.color == nil || progress.color?.id == nil || progressJson == nil || progressJson.isEmpty {
                let errMsg = "progress color property invalid"
                DocsLogger.error(errMsg)
                spaceAssertionFailure(errMsg)
            }
            
            property["formatter"] = formatter
            property["rangeCustomize"] = rangeCustomize
            property["min"] = min
            property["max"] = max
            property["progress"] = progressJson
            
            DocsLogger.info("progress property: formatter:\(formatter) rangeCustomize:\(rangeCustomize) min:\(min) max:\(max)")
        default:
            break
        }
        return property
    }
    
    ///校验字段名
    ///不为空，字符数小于100，包含某些特殊字符
    func verifyFieldName() -> (isValid: Bool, invalidMsg: String?) {
        let fieldName = fieldEditModel.fieldName
        let maxCount = bitableFieldNameMaxCount ?? 100
        if fieldName.count > maxCount {
            return (false, BundleI18n.SKResource.Bitable_Field_MaxCharacterLimit(maxCount))
        } else if fieldName.contains("[") || fieldName.contains("]") {
            return (false, BundleI18n.SKResource.Bitable_Field_CannotContainSpecialCharacter)
        }

        return (true, nil)
    }
    
    func verifyProgress() -> (isValid: Bool, invalidMsg: String?) {
        if fieldEditModel.fieldProperty.rangeCustomize == true {
            guard let min = fieldEditModel.fieldProperty.min, let max = fieldEditModel.fieldProperty.max else {
                return (false, BundleI18n.SKResource.Bitable_Progress_PleaseEnterValue)
            }
            guard max > min else {
                return (false, BundleI18n.SKResource.Bitable_Progress_TagetValueShouldGreaterThanStartValue)
            }
        }
        return (true, nil)
    }
    
    //级联选项校验引用表和引用ID是否合规
    func verifyTargetTable() -> Bool {
        let targetTable = dynamicOptionRuleTargetTable

        var linkTableHasError = false
        if let linkTable = commonData.tableNames.first(where: { $0.tableId == targetTable }) {
            linkTableHasError = !linkTable.readPerimission
        } else {
            linkTableHasError = true
        }

        return !linkTableHasError
    }

    func verifyTargetField() -> Bool {
        let targetField = dynamicOptionRuleTargetField
        var linkFieldHasError = false
        if let linkField = commonData.linkTableFieldOperators.first(where: { $0.id == targetField }) {
            linkFieldHasError = linkField.isDeniedField
        } else {
            linkFieldHasError = true
        }

        return !linkFieldHasError
    }

    func verifyCondition() -> Bool {
        let conditions = fieldEditModel.fieldProperty.optionsRule.conditions
        let data = conditions.filter({
            if $0.operator == .Unkonwn {
                return false
            } else {
                if $0.operator.hasNotNextValueType {
                    return !$0.fieldId.isEmpty
                } else {
                    return !$0.fieldId.isEmpty && !$0.value.isEmpty

                }
            }
        })
        return data.count == conditions.count
    }
    
    func isLinkFieldFilterValueValid(condition: BTFilterCondition) -> Bool {
        if (condition.value ?? []).isEmpty {
            return false
        }
        let filterOptions = cellViewDataManager?.filterOptions ?? BTFilterOptions()
        guard let fieldOption = filterOptions.fieldOptions.first(where: { $0.id == condition.fieldId }) else {
            return false
        }
        if BTFilterValueType(valueType: fieldOption.valueType) == .date,
           let exactDate = condition.value?.first as? String,
           exactDate == BTFilterDuration.ExactDate.rawValue {
            let exactTime = condition.value?.last as? TimeInterval
            return exactTime != nil
        }
        return true
    }
    
    func verifyLinkFieldCommitData() -> (isValid: Bool, invalidMsg: String?) {
        guard fieldEditModel.compositeType.classifyType == .link else { return (true, nil) }
        if fieldEditModel.fieldProperty.tableId.isEmpty || !checkLinkedTableExist() {
            // 请选择关联数据表
            return (false, BundleI18n.SKResource.Bitable_Relation_SelectLinkTableFirstPopup_Mobile)
        }
        guard !fieldEditModel.isLinkAllRecord else {
            return (true, nil)
        }
        let finsishConditionText = BundleI18n.SKResource.Bitable_Relation_FinishSettingsFirstPopup_Mobile
        // 没有条件
        guard let conditions = linkTableFilterInfo?.conditions, conditions.count > 0 else {
            return (false, finsishConditionText)
        }
        if !UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
        // 含有不支持字段条件
        if linkFieldFilterCellModels.contains(where: { $0.fieldErrorType == .fieldNotSupport }) {
            return (false, BundleI18n.SKResource.Bitable_Mobile_Filter_UnsupportedField)
        }
        }
        // 其他错误条件
        let hasFieldError: Bool
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            hasFieldError = linkFieldFilterCellModels.contains(where: { $0.fieldErrorType != nil && $0.fieldErrorType != .fieldNotSupport && $0.fieldErrorType != .tableNoPermission })
        } else {
            hasFieldError = linkFieldFilterCellModels.contains(where: { $0.fieldErrorType != nil })
        }
        if hasFieldError {
            // 字段被删、字段类型被改、字段内容被改情况
            return (false, finsishConditionText)
        }
        for condition in conditions {
            guard !BTFilterOperator.isAsValue(rule: condition.operator) else {
                // 为空/不为空 的 operator 不需要检查 value 是否有值
                continue
            }
            if !isLinkFieldFilterValueValid(condition: condition) {
                // 值为空
                return (false, finsishConditionText)
            }
        }
        return (true, nil)
    }
    
    //数据校验
    func verifyData() -> Bool {
        let (fieldNameIsOK, _) = verifyFieldName()
        let cellHasError = editingFieldCellHasErrorIndexs.count != 0

        switch fieldEditModel.compositeType.uiType {
        case let type where type.classifyType == .link:
            return !fieldEditModel.fieldProperty.tableId.isEmpty && verifyLinkFieldCommitData().isValid && fieldNameIsOK
        case let type where type.classifyType == .option:
            if fieldEditModel.fieldProperty.optionsType == .dynamicOption {
                if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                    return verifyTargetTable() && verifyCondition() && fieldNameIsOK
                } else {
                return verifyTargetField() && verifyTargetTable() && verifyCondition() && fieldNameIsOK
                }
                
            }
            return fieldNameIsOK
        case .autoNumber:
            return fieldNameIsOK && !cellHasError
        default:
            return fieldNameIsOK
        }
    }
    
    ///级联选项、关联字段构建条件cell model
    func configConditionButtons(_ item: BTDynamicOptionConditionModel) -> ([BTConditionSelectButtonModel], String) {
        var errorMsg = ""

        var conditionButtonEnable = true
        var shouldEnableConUserAction: Bool = true
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            shouldEnableConUserAction = !isDynamicPartNoPerimission
        }
        var linkFieldHasError = false
        var linkFieldType = item.fieldType
        var linkFieldName = BundleI18n.SKResource.Bitable_SingleOption_FieldInTargetTable
        var linkFieldIcon: UIImage?
        var linkFieldIconShowLighting: Bool = false
        if let linkField = commonData.linkTableFieldOperators.first(where: { $0.id == item.fieldId }) {
            if linkField.isDeniedField {
                //字段无权限
                linkFieldHasError = true
                shouldEnableConUserAction = false // 字段无权限：允许阅读引用条件，不允许修改引用条件
                conditionButtonEnable = false
                linkFieldName = BundleI18n.SKResource.Bitable_SingleOption_NoPermToViewOptionTip
            } else if linkField.compositeType.type != item.fieldType {
                //字段类型被修改
                linkFieldHasError = true
                linkFieldType = linkField.compositeType.type
                linkFieldName = linkField.name
                linkFieldIcon = linkField.compositeType.icon()
                linkFieldIconShowLighting = linkField.isSync
            } else {
                linkFieldName = linkField.name
                linkFieldIcon = linkField.compositeType.icon()
                linkFieldIconShowLighting = linkField.isSync
            }
        } else if !item.fieldId.isEmpty {
            //字段被删除
            linkFieldHasError = true
            conditionButtonEnable = false
        }

        var currentFieldHasError = false
        var currentFieldType: BTFieldType = .text
        var currentFieldName = BundleI18n.SKResource.Bitable_SingleOption_FieldInCurrentTable
        var currentFieldIcon: UIImage?
        var currentFieldIconShowLighting: Bool = false
        if let currentField = commonData.currentTableFieldOperators.first(where: { $0.id == item.value }) {
            //当前表字段无法感知类型被修改
            if currentField.isDeniedField {
                //字段无权限
                currentFieldHasError = true
                shouldEnableConUserAction = false // 字段无权限：允许阅读引用条件，不允许修改引用条件
                currentFieldName = BundleI18n.SKResource.Bitable_SingleOption_NoPermToViewOptionTip
            } else {
                currentFieldType = currentField.compositeType.type
                currentFieldName = currentField.name
                currentFieldIcon = currentField.compositeType.icon()
                currentFieldIconShowLighting = currentField.isSync
            }
        } else if !item.value.isEmpty {
            //字段被删除
            currentFieldHasError = true
        }
        
        if linkFieldHasError || currentFieldHasError {
            errorMsg = BundleI18n.SKResource.Bitable_SingleOption_ConditionSettingsChangedTip_Mobile
        }

        var conditionValue = BundleI18n.SKResource.Bitable_BTModule_Equal
        if let fieldOperators = commonData.linkTableFieldOperators.first(where: { $0.id == item.fieldId })?.operators,
           let operatorName = fieldOperators.first(where: { $0.value == item.operator })?.text {
            conditionValue = operatorName
        }

        var conditionButtonTextColor = UDColor.textTitle
        if !verifyTargetTable() ||
            item.fieldId.isEmpty {
            conditionButtonTextColor = UDColor.textDisabled
        } else if item.operator == .Unkonwn {
            conditionButtonTextColor = UDColor.textPlaceholder
        }

        var conditionsButton = [
            BTConditionSelectButtonModel(
                text: linkFieldName,
                icon: (item.fieldId.isEmpty || !conditionButtonEnable) ? nil : linkFieldIcon,
                showIconLighting: linkFieldIconShowLighting,
                enable: verifyTargetTable() && shouldEnableConUserAction,
                textColor: (item.fieldId.isEmpty || !conditionButtonEnable) ? UDColor.textPlaceholder : UDColor.textTitle
            ),
            BTConditionSelectButtonModel(
                text: conditionValue,
                enable: conditionButtonEnable && shouldEnableConUserAction,
                textColor: conditionButtonTextColor
            )
        ]

        if !item.operator.hasNotNextValueType {
            conditionsButton.append(
                BTConditionSelectButtonModel(
                    text: currentFieldName,
                    icon: (item.value.isEmpty || currentFieldHasError) ? nil : currentFieldIcon,
                    showIconLighting: currentFieldIconShowLighting,
                    enable: shouldEnableConUserAction,
                    textColor: (item.value.isEmpty || currentFieldHasError) ? UDColor.textPlaceholder : UDColor.textTitle
                )
            )
        }

        return (conditionsButton, errorMsg)
    }
    
    ///获取字段操作列表
    func getFieldOperators(tableId: String,
                           fieldId: String?,
                           needUpdate: Bool,
                           completion: (() -> Void)?) {
        guard needUpdate else {
            completion?()
            DocsLogger.info("[BTFieldEditViewModel] not need getFieldOperators use cache")
            return
        }
        let args = BTGetBitableCommonDataArgs(type: .getFieldList,
                                              tableID: tableId,
                                              viewID: fieldEditModel.viewId,
                                              fieldID: fieldId,
                                              extraParams: nil)
        dataService?.getBitableCommonData(args: args) { [weak self] (result, error) in
            guard error == nil, let self = self else {
                completion?()
                DocsLogger.btError("[BTFieldEditViewModel] getFieldList error")
                return
            }

            guard let dataDic = result as? [[String: Any]],
                  var fieldOperators = [BTFieldOperatorModel].deserialize(from: dataDic)?.compactMap({ $0 }) else {
                completion?()
                DocsLogger.btError("[BTFieldEditViewModel] getFieldList decode error")
                return
            }
            
            fieldOperators = fieldOperators.filter({ !$0.isRemoteCompute || $0.compositeType.classifyType != .link })

            if tableId == self.dynamicOptionRuleTargetTable {
                self.commonData.linkTableFieldOperators = fieldOperators
            }

            if tableId == self.fieldEditModel.tableId {
                self.commonData.currentTableFieldOperators = fieldOperators
            }

            completion?()
        }
    }
    
    ///获取新的fieldId，双向关联需要
    func getNewFieldID(tableID: String, completion: ((String?) -> Void)? = nil) {
        let args = BTGetBitableCommonDataArgs(type: .getNewFieldId,
                                              tableID: tableID,
                                              viewID: "",
                                              fieldID: nil,
                                              extraParams: nil)
        dataService?.getBitableCommonData(args: args) { result, error in
            guard error == nil else {
                DocsLogger.btError("[BTFieldEditViewModel] get newFieldId failed error\(String(describing: error))")
                completion?(nil)
                return
            }

            guard let dataDic = result as? [String: Any],
                  let fieldId = dataDic["fieldId"] as? String else {
                      DocsLogger.btError("[BTFieldEditViewModel] get newFieldId decode failed")
                      completion?(nil)
                      return
                  }

            DocsLogger.btInfo("[BTFieldEditViewModel] get newFieldId success")
            completion?(fieldId)
        }
    }
    
    ///静态选项新增选项、级联选项新增条件
    func didAddOptionItem(completion: ((String?) -> Void)? = nil) {
        if dynamicOptionsEnable,
           fieldEditModel.compositeType.classifyType == .option,
           fieldEditModel.fieldProperty.optionsType == .dynamicOption {
            //添加级联选项规则
            let ids = dynamicOptionsConditions.compactMap({ $0.conditionId })
            let args = BTGetBitableCommonDataArgs(type: .getNewConditionIds,
                                                  tableID: fieldEditModel.tableId,
                                                  viewID: fieldEditModel.viewId,
                                                  fieldID: fieldEditModel.fieldId,
                                                  extraParams: ["total": 1,
                                                                "ids": ids])
            dataService?.getBitableCommonData(args: args) { [weak self] (result, error) in
                guard let self = self, error == nil,
                      let conditionIds = result as? [String],
                      let conditionId = conditionIds.first else {
                    completion?(nil)
                    DocsLogger.btError("bitable fieldEdit getConditionId failed")
                    return
                }
                var newCondition = BTDynamicOptionConditionModel()
                newCondition.conditionId = conditionId
                self.dynamicOptionsConditions.append(newCondition)
                completion?(conditionId)
            }
            return
        }
        
        let newOptionArgs = BTGetBitableCommonDataArgs(type: .getNewOptionId,
                                              tableID: fieldEditModel.tableId,
                                              viewID: fieldEditModel.viewId,
                                              fieldID: fieldEditModel.fieldId,
                                              extraParams: BTFieldEditUtil.generateOptionIdsJSON(options: options))
        dataService?.getBitableCommonData(args: newOptionArgs) { [weak self] (result, error) in
            guard let self = self, error == nil,
                  let optionIds = result as? [String],
                  let optionId = optionIds.first else {
                DocsLogger.btError("bitable fieldEdit getOptionId failed")
                return
            }
            //调用前端接口获取随机生成的颜色
            let colorArgs = BTGetBitableCommonDataArgs(type: .getRandomColor,
                                                       tableID: self.fieldEditModel.tableId,
                                                       viewID: self.fieldEditModel.viewId,
                                                       fieldID: self.fieldEditModel.fieldId,
                                                       extraParams: BTFieldEditUtil.generateColorIdsJSON(options: self.options))
            self.dataService?.getBitableCommonData(args: colorArgs) { result, error in
                guard error == nil,
                      let result = result as? [String: Any],
                      let colorId = result["color"] as? Int else {
                    completion?(optionId)
                    DocsLogger.btError("bitable optionPanel getOptionColor failed")
                    return
                }
                
                var newOptionModel = BTOptionModel()
                newOptionModel.id = optionId
                newOptionModel.color = colorId
                self.options.append(newOptionModel)
                
                completion?(optionId)
            }
        }
    }
    
    /// 根据编辑模式和编辑啊模型获取 js 参数数据
    func getJSFieldInfoArgs(editMode: BTFieldEditMode, fieldEditModel: BTFieldEditModel) -> BTJSFieldInfoArgs {
        let extendInfo = fieldEditModel.fieldExtendInfo?.extendInfo
        return BTJSFieldInfoArgs(index: editMode == .edit ? nil : fieldEditModel.fieldIndex,
                                 fieldID: editMode == .add ? nil : fieldEditModel.fieldId,
                                 fieldName: fieldEditModel.fieldName,
                                 compositeType: fieldEditModel.compositeType,
                                 fieldDescription: fieldEditModel.fieldDesc,
                                 allowEditModes: fieldEditModel.allowedEditModes,
                                 extendConfig: extendManager?.extendEditParams,
                                 extendInfo: extendInfo
        )
    }
    
    /// 自动编号字段仅当前是自定义编号，且修改了编号规则后才需要弹二次确认是否覆盖已有编号的弹框
    func autoNumberShouldShowConfirmPanel() -> Bool {
        let originalTypeIsAutoNumber = oldFieldEditModel.compositeType.uiType == .autoNumber
        let currentTypeIsAutoNumber = fieldEditModel.compositeType.uiType == .autoNumber
        
        let originalAutoNumberIsAdvance = oldFieldEditModel.fieldProperty.isAdvancedRules
        let currentAutoNumberIsAdvance = fieldEditModel.fieldProperty.isAdvancedRules
        
        let ruleHasChanged = oldFieldEditModel.fieldProperty.ruleFieldOptions != fieldEditModel.fieldProperty.ruleFieldOptions
        
        return originalTypeIsAutoNumber &&
               currentTypeIsAutoNumber &&
               originalAutoNumberIsAdvance &&
               currentAutoNumberIsAdvance &&
               ruleHasChanged
    }
    
    ///自动编号，当编号类型发生变更或字段类型由其它字段变更到自动编号字段时，需要默认设置为覆盖已有值，不需要二次确认弹框
    func setAutoNumberReformatExistingRecord() {
        guard fieldEditModel.compositeType.uiType == .autoNumber &&
              (oldFieldEditModel.compositeType.uiType != .autoNumber ||
              fieldEditModel.fieldProperty.isAdvancedRules != oldFieldEditModel.fieldProperty.isAdvancedRules) else {
            return
        }
        
        fieldEditModel.fieldProperty.reformatExistingRecord = true
    }
    
    func initCurrencyProperty() {
        let commonCurrencyCodeList = commonData.fieldConfigItem.commonCurrencyCodeList
        let commonCurrencyDecimalList = commonData.fieldConfigItem.commonCurrencyDecimalList
        guard !commonCurrencyCodeList.isEmpty, !commonCurrencyDecimalList.isEmpty else {
            return
        }
        
        let fieldItem = commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType })
        let defaultCurrencyCodeIndex = fieldItem?.property.defaultCurrencyCodeIndex ?? 0
        let defaultCurrencyDecimalIndex = fieldItem?.property.defaultCurrencyDecimalIndex ?? 0
        
        let selectedCurrencyTypeIndex = commonCurrencyCodeList.firstIndex(where: { $0.currencyCode == fieldEditModel.fieldProperty.currencyCode }) ?? defaultCurrencyCodeIndex
        let currencyType = commonData.fieldConfigItem.commonCurrencyCodeList[selectedCurrencyTypeIndex]
        
        let selectedDecimalypeIndex = commonCurrencyDecimalList.firstIndex(where: {
            currencyType.formatCode + $0.formatCode == fieldEditModel.fieldProperty.formatter
        }) ?? defaultCurrencyDecimalIndex
        
        let decimalType = commonData.fieldConfigItem.commonCurrencyDecimalList[selectedDecimalypeIndex]
        
        fieldEditModel.fieldProperty.formatter = currencyType.formatCode + decimalType.formatCode
        fieldEditModel.fieldProperty.currencyCode = currencyType.currencyCode
    }
    
    func updateCurrencyProperty(formatter: String, currencyCode: String) {
        let oldCurrencyCode = fieldEditModel.fieldProperty.currencyCode

        fieldEditModel.fieldProperty.currencyCode = currencyCode
        guard let oldCurrency = getCurrency(by: oldCurrencyCode) else {
            return
        }
        //去掉当前formatter拼接的货币符号
        let newFormatterCode = formatter.replacingOccurrences(of: oldCurrency.formatCode, with: "")

        let commonCurrencyDecimalList = commonData.fieldConfigItem.commonCurrencyDecimalList
        if let newFormatter = commonCurrencyDecimalList.first(where: { $0.formatCode == newFormatterCode }),
           let currency = getCurrency(by: currencyCode) {
            //重新拼接新的货币符号
            fieldEditModel.fieldProperty.formatter = currency.formatCode + newFormatter.formatCode
        }
    }

    private func getCurrency(by currencyCode: String) -> BTCurrencyCodeList? {
        let commonCurrencyCodeList = commonData.fieldConfigItem.commonCurrencyCodeList
        return commonCurrencyCodeList.first(where: { $0.currencyCode == currencyCode })
    }

    ///数字字段转货币字段
    func covertNumberAndCurrency(fieldType: BTFieldType, uiType: String) {
        let compositeType = BTFieldCompositeType(fieldType: fieldType, uiTypeValue: uiType)
        let currentFieldType = fieldEditModel.compositeType.uiType

        guard compositeType.uiType == .currency, currentFieldType == .number else {
            return
        }
        
        numberToCurrency()
    }

    ///数字字段转货币字段
    private func numberToCurrency() {
        //数字字段中的人民币和美元要转换到对应的货币字段中
        var formatter = fieldEditModel.fieldProperty.formatter
        let numberCurrency = commonData.fieldConfigItem.commonCurrencyCodeList.first(where: { formatter.contains($0.currencySymbol) })
        if let numberCurrency = numberCurrency {
            formatter = formatter.replacingOccurrences(of: numberCurrency.currencySymbol + numberFieldCurrencyPrefix, with: "")
        }

        let currencyCode = fieldEditModel.fieldProperty.currencyCode
        var currency = getCurrency(by: currencyCode) ?? numberCurrency

        if currency == nil {
            //选择默认的货币
            let defaultCurrencyCodeIndex = fieldEditModel.fieldProperty.defaultCurrencyCodeIndex
            let commonCurrencyCodeList = commonData.fieldConfigItem.commonCurrencyCodeList
            if defaultCurrencyCodeIndex < commonCurrencyCodeList.count {
                currency = commonCurrencyCodeList[defaultCurrencyCodeIndex]
            }
        }

        if let currency = currency {
            fieldEditModel.fieldProperty.currencyCode = currency.currencyCode
            fieldEditModel.fieldProperty.formatter = currency.formatCode + numberFieldCurrencyPrefix + formatter
        }
    }
    
    func resetNumberFieldProperty() {
        fieldEditModel.fieldProperty.formatter = commonData.fieldConfigItem.getNumberDefaultFormat()
    }
    
    func resetProgressFieldProperty() {
        fieldEditModel.fieldProperty.formatter = commonData.fieldConfigItem.getProgressDefaultFormat()
        fieldEditModel.fieldProperty.rangeCustomize = nil
        fieldEditModel.fieldProperty.min = nil
        fieldEditModel.fieldProperty.max = nil
        fieldEditModel.fieldProperty.progress = nil
        let rangeConfig = commonData.fieldConfigItem.getCurrentRangeConfig(fieldEditModel: fieldEditModel)
        // 保证range由初始化值
        fieldEditModel.fieldProperty.rangeCustomize = rangeConfig.rangeCustomize
        fieldEditModel.fieldProperty.min = rangeConfig.min
        fieldEditModel.fieldProperty.max = rangeConfig.max
        if let colorConfig = commonData.fieldConfigItem.getCurrentColorConfig(fieldEditModel: fieldEditModel) {
            fieldEditModel.fieldProperty.progress = BTProgressModel(color: colorConfig.selectedColor)
        }
    }
    
    /// 构造当前字段编辑配置数据，每次 updateUI 时会调用到这里
    /// 新增字段需要采用该新设计，有疑问可联系 yinyuan.0
    /// 该方法存在计算耗时，仅在必要刷新 UI 的地方调用，如果只是为了获取数据，请调用 viewModel.fieldEditModel 属性
    func updateCurrentFieldEditConfig(viewController: BTFieldEditController) {
        switch fieldEditModel.compositeType.uiType {
        case .notSupport, .text, .number, .singleSelect,
                .multiSelect, .dateTime, .checkbox, .user, .phone, .url,
                .attachment, .singleLink, .lookup, .formula,
                .duplexLink, .location, .createTime, .lastModifyTime,
                .createUser, .lastModifyUser, .autoNumber, .barcode,
                .currency, .progress, .group, .button, .stage, .email:
            // 旧字段，保持现有逻辑，可不要求使用 commonDataModel
            fieldEditConfig = BTFieldEditConfig()
        case .rating:
            if !(fieldEditConfig is BTRatingFieldEditConfig) {
                fieldEditConfig = BTRatingFieldEditConfig()
            }
        }
        fieldEditConfig.updateConfig(viewController: viewController)
    }
}
