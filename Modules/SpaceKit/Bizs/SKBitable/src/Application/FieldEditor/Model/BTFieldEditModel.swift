//
//  BTFieldEditModel.swift
//  SKBitable
//
//  Created by zoujie on 2022/9/27.
//  


import SKFoundation
import SKCommon
import HandyJSON
import SKBrowser
import UniverseDesignIcon
import UniverseDesignColor
import SKInfra

enum BTOperationType: String, HandyJSONEnum {
    case modifyField //编辑字段
    case copyField // 复制字段
    case insertLeftColumn // 向左插入列
    case insertRightColumn // 向右插入列
    case positiveSort // 按A到Z排序
    case reverseSort // 按Z到A排序
    case deleteField // 删除字段/列
    case selectStatType //选择统计方式
    case filter //按某字段筛选
    case unknown

    var trackingString: String {
        var string: String
        switch self {
        case .modifyField:
            string = "field_modify"
        case .copyField:
            string = "field_duplicate"
        case .insertLeftColumn:
            string = "left_field_insert"
        case .insertRightColumn:
            string = "right_field_insert"
        case .positiveSort:
            string = "order"
        case .reverseSort:
            string = "inverse_order"
        case .deleteField:
            string = "delete"
        case .selectStatType:
            string = "statistics_change"
        case .filter:
            string = "filter"
        case .unknown:
            string = ""
        }

        return string
    }
}

enum BTFieldActionType: Int {
    case modify = 1 //编辑字段
    case add = 2 //新增字段
    case exit = 3 //退出操作面板
    case updateData = 4 //协同更新字段信息
    case openEditPage = 5 //打开二级编辑面板
}

struct BTCommonData {
    var colorList: [BTColorModel] = [] //颜色列表
    var tableNames: [BTFieldRelatedForm] = [] //当前bitable中所有表信息
    var fieldConfigItem: BTFieldConfigItem = BTFieldConfigItem() //field基础信息列表
    var linkTableFieldOperators: [BTFieldOperatorModel] = [] //引用数据表字段与当前数据表字段的关系列表
    var currentTableFieldOperators: [BTFieldOperatorModel] = [] //引用数据表字段与当前数据表字段的关系列表
    var filterOptions = BTFilterOptions() // 筛选选项数据源
    var hostDocsInfos: DocsInfo?
}

extension BTCommonData {
    // 级联是否部分无权限(只有scheme4文档下才会为true，老文档isPartialDenied是nil)
    func isDynamicPartNoPerimission(targetTable: String, targetField: String) -> Bool {
        guard let linkTable = tableNames.first(where: { $0.tableId == targetTable }) else {
            DocsLogger.error("get linkTable error")
            return false
        }
        guard let linkField = linkTableFieldOperators.first(where: { $0.id == targetField }) else {
            DocsLogger.error("get linkField error")
            return false
        }
        if (linkTable.readPerimission && linkTable.isPartialDenied == true)
            || (!linkField.isDeniedField && linkField.isPartialDenied == true) {
            return true
        } else {
            return false
        }
    }
    // 级联引用表是否有权限
    func dynamicTableReadPerimission(targetTable: String) -> Bool {
        guard let linkTable = tableNames.first(where: { $0.tableId == targetTable }) else {
            DocsLogger.error("get linkTable error")
            return false
        }
        return linkTable.readPerimission
    }
    // 级联引用字段是否无权限
    func isDynamicFieldDenied(targetField: String) -> Bool {
        guard let linkField = linkTableFieldOperators.first(where: { $0.id == targetField }) else {
            DocsLogger.error("get linkField error")
            return false
        }
        return linkField.isDeniedField
    }
    // 关联表部分无权限
    func isLinkTablePartialDenied(tableID: String) -> Bool {
        guard let linkTable = tableNames.first(where: { $0.tableId == tableID }) else {
            DocsLogger.error("get linkTable error")
            return false
        }
        if linkTable.isPartialDenied == true {
            return true
        } else {
            return false
        }
    }
}

struct BTOperationItem: HandyJSON, GroupableItem {
    var id: BTOperationType = .modifyField
    var title: String = ""
    var groupId: String = ""
    var enable: Bool = true
    var disableReason: Int = 0
    var shouldShowWarningIcon: Bool = false

    var iconImage: UIImage? {
        let image: UIImage?
        switch self.id {
        case .modifyField: image = UDIcon.editOutlined
        case .copyField: image = UDIcon.copyOutlined
        case .insertLeftColumn: image = UDIcon.insertLeftOutlined
        case .insertRightColumn: image = UDIcon.insertRightOutlined
        case .positiveSort: image = UDIcon.sorAToZOutlined
        case .reverseSort: image = UDIcon.sorZToAOutlined
        case .deleteField: image = UDIcon.deleteTrashOutlined
        case .selectStatType: image = UDIcon.functionsOutlined
        case .filter: image = UDIcon.filterOutlined
        default: image = nil
        }
        return image?.ud.withTintColor(UDColor.iconN1)
    }

}

struct BTConfigurableFieldTypeListItem: HandyJSON {
   
    var fieldType: BTFieldType = .notSupport
    var fieldUIType: String?
    
    var compositeType: BTFieldCompositeType {
        return BTFieldCompositeType(fieldType: fieldType, uiTypeValue: fieldUIType)
    }
}

struct BTGroupingStatisticsSetItem: HandyJSON {
    var id: String = ""
    var name: String = ""
}

struct BTFieldRelatedForm: HandyJSON {
    var tableName: String = ""
    var tableId: String = ""
    var readPerimission: Bool = true
    var isSyncTable: Bool = false
    var isPartialDenied: Bool? // nil代表老文档，true代表新文档部分无权限
}

enum BTFieldProgressType: String, HandyJSONEnum {
    case percent    // 按百分比
    case number     // 显示原始数字
}

struct BTFieldProgressTypeItem: HandyJSON {
    var type: BTFieldProgressType = .percent
    var name: String = ""
    
    // 所有支持的进度条小数位数格式列表
    var progressNumberFormatList: [BTNumberFieldFormat] = []
}

struct BTFieldConfigItem: HandyJSON {
    
    var fieldItems: [BTFieldTypeItem] = [] //field基础信息列表
    //所有支持的日期格式列表
    var commonNumberFormatList: [BTNumberFieldFormat] = []
    //所有支持的数字格式列表
    var commonDateTimeList: [BTDateFieldFormat] = []
    //自动编号配置
    var commonAutoNumberRuleTypeList: [BTAutoNumberRuleTypeList] = []
    //货币字段的货币选项列表
    var commonCurrencyCodeList: [BTCurrencyCodeList] = []
    //货币字段小数位数选项列表
    var commonCurrencyDecimalList: [BTNumberFieldFormat] = []
    // 通用色卡
    var commonColorList: [BTColor] = []
    /// Rating 符号配置
    var commonRatingSymbolList: [BTRatingSymbol] = []
}


struct BTRatingSymbolConfig: HandyJSON, SKFastDecodable {
    var supportRatingSymbols: [String] = []
    var defaultRatingSymbol: String = BTRatingModel.defaultSymbol

    static func deserialized(with dictionary: [String : Any]) -> BTRatingSymbolConfig {
        var model = BTRatingSymbolConfig()
        model.supportRatingSymbols <~ (dictionary, "supportRatingSymbols")
        model.defaultRatingSymbol <~ (dictionary, "defaultRatingSymbol")
        return model
    }
}

struct BTRatingSymbol: HandyJSON {
    var symbol: String = ""
    var name: String = ""
}

struct BTFieldTypeItem: HandyJSON, GroupableItem {
    private var type: BTFieldType = .text // 字段类型
    private var fieldUIType: String?
    var compositeType: BTFieldCompositeType {
        return BTFieldCompositeType(fieldType: type, uiTypeValue: fieldUIType)
    }
    var title: String = ""
    var groupName: String = ""
    var enable: Bool = true
    var property: BTFieldProperty = BTFieldProperty()
    var allowedEditModes: AllowedEditModes?

    var groupId: String {
        groupName
    }
}

extension BTFieldConfigItem {
    func getNumberDefaultFormat() -> String {
        let defaultFormatter = "0"
        var numberFormatIndex = 0
        if let defaultDataItem = fieldItems.first(where: { $0.compositeType.uiType == .number }) {
            numberFormatIndex = defaultDataItem.property.defaultNumberFormatIndex
        }
        if numberFormatIndex > 0, numberFormatIndex < commonNumberFormatList.count {
            return commonNumberFormatList[numberFormatIndex].formatCode ?? defaultFormatter
        }
        return commonNumberFormatList.first?.formatCode ?? defaultFormatter
    }
    
    func getProgressDefaultFormat() -> String {
        let defaultFormatter = "0"
        guard let defaultDataItem = fieldItems.first(where: { $0.compositeType.uiType == .progress }) else {
            return defaultFormatter
        }
        guard let config = defaultDataItem.property.formatConfig?.getCurrentConfig(formatter: nil) else {
            return defaultFormatter
        }
        return config.typeConfig.getFormatCode(decimalDigits: config.decimalDigits)
    }
    
    func getCurrentFormatConfig(fieldEditModel: BTFieldEditModel) -> (typeConfig: BTFormatTypeConfig, decimalDigits: Int)? {
        guard let defaultDataItem = fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType }) else {
            DocsLogger.error("fieldItems for \(fieldEditModel.compositeType.uiType.rawValue) not found")
            return nil
        }
        return defaultDataItem.property.formatConfig?.getCurrentConfig(formatter: fieldEditModel.fieldProperty.formatter)
    }
    
    func getCurrentColorConfig(fieldEditModel: BTFieldEditModel) -> (colors: [BTColor], selectedColor: BTColor)? {
        guard let defaultDataItem = fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType }) else {
            DocsLogger.error("fieldItems for \(fieldEditModel.compositeType.uiType.rawValue) not found")
            return nil
        }
        let colors = commonColorList.filter({ color in
            defaultDataItem.property.colorConfig?.supportColorIds?.contains(where: { colorId in
                colorId == color.id
            }) == true
        })
        guard !colors.isEmpty else {
            DocsLogger.error("fieldItems for \(fieldEditModel.compositeType.uiType.rawValue) colors is empty")
            return nil
        }
        if let selectedColor = fieldEditModel.fieldProperty.progress?.color, colors.contains(where: { color in
            color.id == selectedColor.id
        }) {
            return (colors: colors, selectedColor: selectedColor)
        } else if let selectedColor = colors.first(where: { color in
            defaultDataItem.property.colorConfig?.defaultColorId == color.id
        }) {
            return (colors: colors, selectedColor: selectedColor)
        } else if let selectedColor = colors.first {
            return (colors: colors, selectedColor: selectedColor)
        }
        return nil
    }
    
    func getCurrentRangeConfig(fieldEditModel: BTFieldEditModel) -> (rangeCustomize: Bool, min: Double, max: Double) {
        var rangeCustomize = false
        let defaultMin = Double(0)
        let defaultMax = Double(100)
        guard let defaultDataItem = fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType }) else {
            DocsLogger.warning("fieldItems for \(fieldEditModel.compositeType.uiType.rawValue) not found")
            return (rangeCustomize: rangeCustomize, min: defaultMin, max: defaultMax)
        }
        rangeCustomize = fieldEditModel.fieldProperty.rangeCustomize ?? defaultDataItem.property.rangeConfig?.defaultRange.rangeCustomize ?? rangeCustomize
        if !rangeCustomize {
            return (
                rangeCustomize: rangeCustomize,
                min: defaultMin,
                max: defaultMax
            )
        } else {
            return (
                rangeCustomize: rangeCustomize,
                min: fieldEditModel.fieldProperty.min ?? defaultDataItem.property.rangeConfig?.defaultRange.min ?? defaultMin,
                max: fieldEditModel.fieldProperty.max ?? defaultDataItem.property.rangeConfig?.defaultRange.max ?? defaultMax
            )
        }
    }
    
    func getCurrentRatingSymbolConfig(fieldEditModel: BTFieldEditModel) -> (symbols: [BTRatingSymbol], selectedSymbol: BTRatingSymbol)? {
        guard let defaultDataItem = fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType }) else {
            DocsLogger.error("fieldItems for \(fieldEditModel.compositeType.uiType.rawValue) not found")
            return nil
        }
        
        let supportRatingSymbols = defaultDataItem.property.ratingSymbolConfig?.supportRatingSymbols.compactMap({ symbol in
            commonRatingSymbolList.first { symbolModel in
                symbolModel.symbol == symbol
            }
        })
        guard let supportRatingSymbols = supportRatingSymbols, !supportRatingSymbols.isEmpty else {
            DocsLogger.error("supportRatingSymbols is empty")
            return nil
        }
        let selectedItem = supportRatingSymbols.first { symbolModel in
            symbolModel.symbol == fieldEditModel.fieldProperty.rating?.symbol
        } ?? supportRatingSymbols.first { symbolModel in
            symbolModel.symbol == defaultDataItem.property.ratingSymbolConfig?.defaultRatingSymbol
        } ?? supportRatingSymbols[0]
        
        return (supportRatingSymbols, selectedItem)
    }
    
    
    func getCurrentRatingRangeConfig(fieldEditModel: BTFieldEditModel) -> (min: Int, max: Int, minRangeMin: Int, minRangeMax: Int, maxRangeMin: Int, maxRangeMax: Int) {
        let defaultDataItem = fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType })
        let min = fieldEditModel.fieldProperty.min ?? defaultDataItem?.property.rangeConfig?.defaultRange.min ?? Double(getRatingDefaultRangeConfig().min)
        let max = fieldEditModel.fieldProperty.max ?? defaultDataItem?.property.rangeConfig?.defaultRange.max ?? Double(getRatingDefaultRangeConfig().max)
        let minRangeMin = defaultDataItem?.property.rangeConfig?.defaultRange.minRangeMin ?? Double(getRatingDefaultRangeConfig().minRangeMin)
        let minRangeMax = defaultDataItem?.property.rangeConfig?.defaultRange.minRangeMax ?? Double(getRatingDefaultRangeConfig().minRangeMax)
        let maxRangeMin = defaultDataItem?.property.rangeConfig?.defaultRange.maxRangeMin ?? Double(getRatingDefaultRangeConfig().maxRangeMin)
        let maxRangeMax = defaultDataItem?.property.rangeConfig?.defaultRange.maxRangeMax ?? Double(getRatingDefaultRangeConfig().maxRangeMax)
        return (Int(min), Int(max), Int(minRangeMin), Int(minRangeMax), Int(maxRangeMin), Int(maxRangeMax))
     }
     
    func getRatingDefaultFormat() -> String {
        return "0"
    }
    
    func getRatingDefaultRangeConfig() -> (min: Int, max: Int, minRangeMin: Int, minRangeMax: Int, maxRangeMin: Int, maxRangeMax: Int) {
        return (1, 5, 0, 1, 1, 10)
    }
    
    func getSymbolConfig(symbol: String?) -> BTRatingSymbol? {
        let symbol = symbol ?? BTRatingModel.defaultSymbol
        return commonRatingSymbolList.first { symbolConfig in
            symbolConfig.symbol == symbol
        }
    }
}


struct BTFieldEditModel: HandyJSON, Hashable, BTEventBaseDataType {
    var type: Int = 1 // 1 = 编辑，2 = 新增
    var allowEmptyTitle: Bool = false //是否允许字段标题为空
    var baseId: String = "" // bitable文档ID
    var tableId: String = "" // 数据表ID
    var viewId: String = "" //视图ID
    var fieldId: String = "" // 字段id
    var fieldIndex: Int = 0 // 当前字段在表格中列的index，新增选项时需要
    private var fieldType: BTFieldType = .text // 字段类型
    private var fieldUIType: String? //ui类型
    var fieldName: String = "" // 字段名称
    var fieldDesc: BTDescriptionModel? // 字段描述
    var position: BTPanelLocation = BTPanelLocation()
    var fieldProperty: BTFieldProperty = BTFieldProperty()
    
    var allowedEditModes: AllowedEditModes?
    
    var fieldExtendInfo: FieldExtendInfo?
    var editNotice: FieldExtendExceptNotice?
    
    var tableNameMap: [BTFieldRelatedForm] = [] //可关联表
    var dependentTables: [String] = [] //引用当前字段的表名
    var operationItems: [BTOperationItem] = [] // 操作选项
    var configurableFieldTypeList: [BTConfigurableFieldTypeListItem] = [] //可配置更改的字段类型选项
    var callback: String = ""
    var statTypeId: String = "none" //当前的字段统计方式
    var statTypeList: [BTGroupingStatisticsSetItem] = [] //字段分组统计值设置
    var isLinkAllRecord: Bool = true // 关联字段的关联范围是否为所有记录
    var sceneType: String = ""  // 编辑或创建场景，用于埋点上报
    var fieldTips: FieldEditPanelFieldTips?
    
    var canShowAIConfig: Bool = false
    var showAIConfigTx: String = ""
    
    var isPartial: Bool = false
    
    // MARK: - 计算属性
    /// 组合类型
    var compositeType: BTFieldCompositeType {
        return BTFieldCompositeType(fieldType: fieldType, uiTypeValue: fieldUIType)
    }
    /// 字段埋点名称
    var fieldTrackName: String {
        return compositeType.fieldTrackName
    }
    
    mutating func update(fieldType: BTFieldType, uiType: String?) {
        self.fieldType = fieldType
        self.fieldUIType = uiType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fieldType)
        hasher.combine(fieldUIType)
        hasher.combine(fieldName)
        hasher.combine(fieldProperty)
        hasher.combine(allowedEditModes)
        hasher.combine(statTypeId)
        hasher.combine(fieldExtendInfo)
        hasher.combine(editNotice)
    }
    
    static func == (lhs: BTFieldEditModel, rhs: BTFieldEditModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
struct FieldEditPanelFieldTips: HandyJSON {
    var iconType: Int?
    var text: String?
    var img: UIImage? {
        if iconType == 1 {
            return UDIcon.loadingOutlined.ud.withTintColor(UDColor.N400)
        } else {
            return nil
        }
    }
}

struct BTAutoNumberRuleTypeList: HandyJSON {
    var isAdvancedRules: Bool = false
    var title: String = ""
    var description: String = ""
    var ruleFieldOptions: [BTAutoNumberRuleOption] = [] //编号规则
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTAutoNumberRuleOption: HandyJSON, Hashable, SKFastDecodable {
    static func == (lhs: BTAutoNumberRuleOption, rhs: BTAutoNumberRuleOption) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var id: String = ""
    var fixed: Bool = false //是否是固定存在的编号规则
    var type: BTAutoNumberRuleType = .systemNumber
    var value: String = ""
    var title: String = ""
    var description: String = ""
    var optionList: [BTAutoNumberRuleDateModel] = []

    static func deserialized(with dictionary: [String : Any]) -> BTAutoNumberRuleOption {
        var model = BTAutoNumberRuleOption()
        model.id <~ (dictionary, "id")
        model.fixed <~ (dictionary, "fixed")
        model.type <~ (dictionary, "type")
        model.value <~ (dictionary, "value")
        model.title <~ (dictionary, "title")
        model.description <~ (dictionary, "description")
        model.optionList <~ (dictionary, "optionList")
        return model
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fixed)
        hasher.combine(type)
        hasher.combine(value)
        hasher.combine(optionList)
    }
}

public enum BTAutoNumberRuleType: Int, HandyJSONEnum, SKFastDecodableEnum {
    case systemNumber = 1 //自增数字
    case fixedText = 2   //固定字符
    case createdTime = 3  //创建时间
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTAutoNumberRuleDateModel: HandyJSON, Hashable, SKFastDecodable {
    static func == (lhs: BTAutoNumberRuleDateModel, rhs: BTAutoNumberRuleDateModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var format: String = ""
    var text: String = ""
    
    public static func deserialized(with dictionary: [String : Any]) -> BTAutoNumberRuleDateModel {
        var model = BTAutoNumberRuleDateModel()
        model.format <~ (dictionary, "format")
        model.text <~ (dictionary, "text")
        return model
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(format)
        hasher.combine(text)
    }
}

struct BTFieldOperatorModel: HandyJSON {
    var id: String = ""
    var name: String = ""
    private var type: BTFieldType = .text
    private var fieldUIType: String?
    var compositeType: BTFieldCompositeType {
        return BTFieldCompositeType(fieldType: type, uiTypeValue: fieldUIType)
    }
    var property: BTFieldProperty = BTFieldProperty()
    var isDeniedField: Bool = false
    var operators: [BTFieldOperatorModelListModel] = []
    var isHidden: Bool = false
    var isPartialDenied: Bool? // nil代表老文档，true代表新文档部分无权限
    var isRemoteCompute: Bool = false
    var isSync: Bool = false
}

struct BTFieldOperatorModelListModel: HandyJSON {
    var value: BTConditionType = .Unkonwn
    var text: String = ""
}

struct BTCurrencyCodeList: HandyJSON {
    var currencyCode: String = "" // 货币代码
    var currencySymbol: String = "" // 货币符号
    var name: String = "" // 展示名称
    var formatCode: String = "" // 货币在formatter属性中的code
}

public enum FormatterType: Int {
    case general = 0 // 默认值
    case number = 1 // 数字
    case dateTime = 2 // 日期
    case text = 3 // 文本
    case percentage = 4 // 进度
    case currency = 5 // 货币
}
