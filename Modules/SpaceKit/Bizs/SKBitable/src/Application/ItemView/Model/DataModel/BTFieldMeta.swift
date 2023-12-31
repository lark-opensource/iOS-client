//
//  BTFieldMeta.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/17.
//

import Foundation
import UIKit
import HandyJSON
import SKFoundation
import SKCommon
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SKInfra

/// 前端传过来的字段数据（对应前端的 `IFieldMeta`）
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTFieldMeta: HandyJSON, Hashable, SKFastDecodable {
    private var type: BTFieldType = .notSupport // 基础字段类型
    private var fieldUIType: String? // 相当于子类型 与 type 决定真实的字段类型
    /// 由 type 和 fieldUIType 组成的组合类型，用于在代码中流转。
    var compositeType: BTFieldCompositeType {
        return BTFieldCompositeType(fieldType: type, uiTypeValue: fieldUIType)
    }
    
    var id: String = ""  // 字段 ID
    var name: String = "" // 字段名称
    var title: String = "" // 表单有自己的title名字, title 为空再取 name显示
    var hidden: Bool = false
    var property: BTFieldProperty = BTFieldProperty()
    var required: Bool = false
    var errorMsg: String = ""
    var fieldWarning: String = "" //字段警告信息
    var description: BTDescriptionModel? // 字段描述
    var isSync: Bool = false
    var allowedEditModes: AllowedEditModes = AllowedEditModes()

    static func deserialized(with dictionary: [String : Any]) -> BTFieldMeta {
        var model = BTFieldMeta()
        model.type <~ (dictionary, "type")
        model.fieldUIType <~ (dictionary, "fieldUIType")
        model.id <~ (dictionary, "id")
        model.name <~ (dictionary, "name")
        model.title <~ (dictionary, "title")
        model.hidden <~ (dictionary, "hidden")
        model.property <~ (dictionary, "property")
        model.required <~ (dictionary, "required")
        model.errorMsg <~ (dictionary, "errorMsg")
        model.fieldWarning <~ (dictionary, "fieldWarning")
        model.description <~ (dictionary, "description")
        model.isSync <~ (dictionary, "isSync")
        model.allowedEditModes <~ (dictionary, "allowedEditModes")
        return model
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(fieldUIType)
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(title)
        hasher.combine(hidden)
        hasher.combine(property)
        hasher.combine(allowedEditModes)
        hasher.combine(required)
        hasher.combine(errorMsg)
        hasher.combine(description)
        hasher.combine(isSync)
    }
    static func == (lhs: BTFieldMeta, rhs: BTFieldMeta) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

/// 允许的编辑模式
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct AllowedEditModes: HandyJSON, Hashable, SKFastDecodable {
    var scan: Bool? = false //扫码
    var manual: Bool? = true //手动输入

    static func deserialized(with dictionary: [String : Any]) -> AllowedEditModes {
        var model = AllowedEditModes()
        model.scan <~ (dictionary, "scan")
        model.manual <~ (dictionary, "manual")
        return model
    }
}

/// 颜色配置
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTColorConfig: HandyJSON, Hashable, SKFastDecodable {
    /// 支持的颜色列表
    var supportColorIds: [String]?
    /// 默认颜色 id
    var defaultColorId: String?

    static func deserialized(with dictionary: [String : Any]) -> BTColorConfig {
        var model = BTColorConfig()
        model.supportColorIds <~ (dictionary, "supportColorIds")
        model.defaultColorId <~ (dictionary, "defaultColorId")
        return model
    }

}

/// 数值类型
enum BTFormatType: Int, HandyJSONEnum, SKFastDecodableEnum {
    /// 数值类型
    case number = 1
    /// 百分比类型
    case percentage = 4
    
    func tracingString() -> String {
        switch self {
        case .number:
            return "number"
        case .percentage:
            return "percentage"
        }
    }
}

/// 数值类型配置
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTFormatTypeConfig: HandyJSON, Hashable, SKFastDecodable {
    /// 数值类型
    var type: BTFormatType?
    /// 默认小数位数
    var defaultDecimalDigits: Int = 0
    /// 支持的小数位数列表
    var decimalDigits: [Int] = [0, 1, 2]

    static func deserialized(with dictionary: [String : Any]) -> BTFormatTypeConfig {
        var model = BTFormatTypeConfig()
        model.type <~ (dictionary, "type")
        model.defaultDecimalDigits <~ (dictionary, "defaultDecimalDigits")
        model.decimalDigits <~ (dictionary, "decimalDigits")
        return model
    }
    
    /// 获取小数位数对应的 formatCode
    func getFormatCode(decimalDigits: Int) -> String {
        var formatCode = "0"
        if decimalDigits > 0 {
            formatCode += "."
            for _ in 0 ..< decimalDigits {
                formatCode += "0"
            }
        }
        if type == .percentage {
            formatCode += "%"
        }
        return formatCode
    }
    
    /// 获取小数位数对应的示例
    func getFormatExample(decimalDigits: Int) -> String {
        var formatCode = "1"
        if decimalDigits > 0 {
            formatCode += "."
            for _ in 0 ..< decimalDigits {
                formatCode += "0"
            }
        }
        if type == .percentage {
            formatCode += "%"
        }
        return formatCode
    }
    
    /// 获取小数位数对应的选项名
    func getFormatDecimalDigitsName(decimalDigits: Int) -> String {
        if decimalDigits > 0 {
            return BundleI18n.SKResource.Bitable_Common_MultipleDecimalPlaces.replacingOccurrences(of: "%s", with: String(decimalDigits))
        } else {
            return BundleI18n.SKResource.Bitable_Progress_Integer
        }
    }
    
    /// 获取格式类型名称
    func getFormatTypeName() -> String {
        switch type {
        case .percentage:
            return BundleI18n.SKResource.Bitable_Progress_Percentage_Dropdown
        case .number:
            return BundleI18n.SKResource.Bitable_Progress_Number_Dropdown
        case .none:
            return ""
        }
    }
    
    /// 根据 formatCode 计算 value 的格式化字符串
    static func format(value: Double, formatCode: String) -> String {
        var mainNumberFormat: String = formatCode
        var numberSuffix: String = ""
        if formatCode.hasSuffix("%") {
            numberSuffix = "%%" // %% 是 % 在 format 中的转义字符 https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
            mainNumberFormat = String(formatCode[formatCode.startIndex..<formatCode.index(formatCode.endIndex, offsetBy: -1)])
        }
        
        guard let regular = try? NSRegularExpression(pattern: "^(0|0\\.0+)$") else {
            return String(value)
        }
        guard regular.matches(in: mainNumberFormat, range: NSRange(location: 0, length: mainNumberFormat.count)).count == 1 else {
            return String(value)
        }
        
        var digitsCount = 0 // 小数位数
        if mainNumberFormat.hasPrefix("0.") {
            digitsCount = mainNumberFormat.count - 2
        }
        
        return String(format: "%.\(digitsCount)f\(numberSuffix)", value)
    }
    
    /// 将一个数值转换为一个完整的数字字符串，可用于用户编辑，而不是用 e+ 这种缩写格式
    static func format(_ value: Double) -> String {
        let stringFormatter = NumberFormatter()
        stringFormatter.maximumFractionDigits = 310 // 最大小数位
        stringFormatter.maximumIntegerDigits = 310  // 最大整数位
        return stringFormatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    /// 获取小数位数对应的数据上报的值
    static func getDecimalDigitsTracingString(_ decimalDigits: Int) -> String {
        if decimalDigits > 0 {
            return "digital_round_\(decimalDigits)"
        } else {
            return "integer"
        }
    }
}

/// 数值格式配置
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTFormatConfig: HandyJSON, Hashable, SKFastDecodable {
    /// 支持的数值类型
    var types: [BTFormatTypeConfig]?
    /// 默认数值类型
    var defaultType: BTFormatType?
    
    static func deserialized(with dictionary: [String : Any]) -> BTFormatConfig {
        var model = BTFormatConfig()
        model.types <~ (dictionary, "types")
        model.defaultType <~ (dictionary, "defaultType")
        return model
    }
    
    /// 获取当前的格式配置
    func getCurrentConfig(formatter: String?) -> (typeConfig: BTFormatTypeConfig, decimalDigits: Int)? {
        if let formatter = formatter {
            var decimalDigits: Int?
            if let typeConfig = types?.first(where: { typeConfig in
                if let number = typeConfig.decimalDigits.first(where: { number in
                    return typeConfig.getFormatCode(decimalDigits: number) == formatter
                }) {
                    decimalDigits = number
                    return true
                } else {
                    return false
                }
            }), let decimalDigits = decimalDigits {
                return (typeConfig: typeConfig, decimalDigits: decimalDigits)
            }
        }
        // 默认处理
        if let typeConfig = types?.first(where: { typeConfig in
            return typeConfig.type == defaultType
        }) {
            if let decimalDigits = typeConfig.decimalDigits.first(where: { number in
                return number == typeConfig.defaultDecimalDigits
            }) {
                return (typeConfig: typeConfig, decimalDigits: decimalDigits)
            }
        }
        return nil
    }
}

/// 数值范围默认配置
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTRangeDefault: HandyJSON, Hashable, SKFastDecodable {
    /// 是否自定义范围的默认值
    var rangeCustomize: Bool = false
    /// 最小值的默认值
    var min: Double?
    /// 最大值的默认值
    var max: Double?
    /// min 范围的最小值
    var minRangeMin: Double?
    /// min 范围的最大值
    var minRangeMax: Double?
    /// max 范围的最小值
    var maxRangeMin: Double?
    /// max 范围的最大值
    var maxRangeMax: Double?

    static func deserialized(with dictionary: [String : Any]) -> BTRangeDefault {
        var model = BTRangeDefault()
        model.rangeCustomize <~ (dictionary, "rangeCustomize")
        model.min <~ (dictionary, "min")
        model.max <~ (dictionary, "max")
        model.minRangeMin <~ (dictionary, "minRangeMin")
        model.minRangeMax <~ (dictionary, "minRangeMax")
        model.maxRangeMin <~ (dictionary, "maxRangeMin")
        model.maxRangeMax <~ (dictionary, "maxRangeMax")
        return model
    }
    
}

/// 数值范围配置
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTRangeConfig: HandyJSON, Hashable, SKFastDecodable {
    var defaultRange: BTRangeDefault = BTRangeDefault()
    
    static func deserialized(with dictionary: [String : Any]) -> BTRangeConfig {
        var model = BTRangeConfig()
        model.defaultRange <~ (dictionary, "defaultRange")
        return model
    }
}

/// 颜色类型
enum BTColorType: String, HandyJSONEnum, Codable, SKFastDecodableEnum {
    /// 多段色(纯色即1段色)
    case multi
    /// 渐变色
    case gradient
}

/// 颜色值
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTColor: HandyJSON, Equatable, Codable, Hashable, SKFastDecodable {
    var id: String?
    var name: String?
    /// 颜色值列表
    var color: [String]?
    var type: BTColorType?
    
    static func deserialized(with dictionary: [String : Any]) -> BTColor {
        var model = BTColor()
        model.id <~ (dictionary, "id")
        model.name <~ (dictionary, "name")
        model.color <~ (dictionary, "color")
        model.type <~ (dictionary, "type")
        return model
    }
    
    static func == (lhs: BTColor, rhs: BTColor) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// 按照百分比获取颜色
    /// percent 区间 [0, 1]
    func color(for percent: Float) -> UIColor {
        var defaultColor = UIColor.clear
        
        let colors = color?.map {
            return UIColor.docs.rgb($0)
        }
        guard let colors = colors, !colors.isEmpty else {
            return defaultColor
        }
        defaultColor = colors.first ?? defaultColor
        switch type {
        case .multi:
            let index = Int(percent * Float(colors.count))
            if index >= 0, index < colors.count {
                return colors[index]
            } else if index == colors.count {
                return colors[index-1]
            }
        case .gradient:
            if colors.count < 2 {
                return colors.first ?? defaultColor
            }
            let indexFloat = percent * Float(colors.count - 1)
            let beginColorIndex = Int(indexFloat)
            let endColorIndex = beginColorIndex + 1
            if beginColorIndex >= 0, endColorIndex < colors.count {
                let beginColor = colors[beginColorIndex]
                let endColor = colors[endColorIndex]
                let percent = indexFloat - Float(beginColorIndex)
                return UIColor.docs.gradientColor(
                    begin: beginColor,
                    end: endColor,
                    percent: percent
                )
            } else if beginColorIndex <= 0 {
                return colors.first ?? defaultColor
            } else if endColorIndex >= colors.count {
                return colors.last ?? defaultColor
            }
        case .none:
            return defaultColor
        }
        return defaultColor
    }
}

/// 进度条属性
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTProgressModel: HandyJSON, Equatable, Hashable, SKFastDecodable {
    var color: BTColor?
    
    static func deserialized(with dictionary: [String : Any]) -> BTProgressModel {
        var model = BTProgressModel()
        model.color <~ (dictionary, "color")
        return model
    }
    
    static func == (lhs: BTProgressModel, rhs: BTProgressModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(color)
    }
}

/// 评分属性
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTRatingModel: HandyJSON, Equatable, Hashable, SKFastDecodable {
    
    static var defaultSymbol = "star"
    
    var symbol: String = BTRatingModel.defaultSymbol
    
    static func deserialized(with dictionary: [String : Any]) -> BTRatingModel {
        var model = BTRatingModel()
        model.symbol <~ (dictionary, "symbol")
        return model
    }
    
    static func == (lhs: BTRatingModel, rhs: BTRatingModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(symbol)
    }
}

/// 字段属性（对应前端的 `IFieldMeta` 里面的 `property` 对象）
/// ⚠️注意：由于历史原因，BTFieldProperty 成为了两种结构的混合体，我们区分这两种结构分别为 FieldMetaProperty 和 FieldConfigProperty
/// 这两种结构的结构是不一致的，BTFieldProperty 在某一个时刻只能是 FieldMetaProperty 或 FieldConfigProperty 的一种
/// FieldMetaProperty：字段 meta 数据，是一个字段实例的特有数据，同一种字段的不同实例值一般不一样
/// FieldConfigProperty：字段的配置数据，通过 biz.util.getBitableCommonData 请求而来，是一个字段的公共配置数据，同一种字段一般是一样的
/// 新增属性请备注自己属于哪个结构，参考 https://bytedance.feishu.cn/wiki/wikcn7xNQd9Ic7LioyvjOvpphPY?from=space_home_recent
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTFieldProperty: HandyJSON, Hashable, SKFastDecodable {
    
    static func == (lhs: BTFieldProperty, rhs: BTFieldProperty) -> Bool {
        // 阶段字段详情由于全部完成后UI层使用的optionId还是最后一个没发生变化，因此可能不会触发diff，但是会修改stage的status，从而修改property
        // 为了触发协同，这里增加对stage的判断
        return lhs.hashValue == rhs.hashValue && lhs.stages.elementsEqual(rhs.stages)
    }
    
    var optionsType: BTOptionType = .staticOption //选项类型
    var options: [BTOptionModel] = [] // 如果是选项类型 表示选项
    var optionsRule: BTDynamicOptionRuleModel = BTDynamicOptionRuleModel() //级联选项条件
    var autoFill: Bool = false // 新增时是否自动填写
    var dateFormat: String = "" // 日期的格式 'yyyy/MM/dd'
    var timeFormat: String = "" // 时间的格式 'HH:mm'
    var displayTimeZone: Bool = false //是否显示时区后缀
    var baseId: String = "" // 被关联记录所在的多维表格
    var tableId: String = "" // 被关联记录所在的子表
    var viewId: String = "" // 视图关联需要
    var multiple: Bool = false // 成员字段展示单、多选
    var fields: [String: BTFieldMeta] = [:] // 关联字段的 field 属性信息
    var tableVisible: Bool = true // 关联表格是否有查看权限
    var primaryFieldId: String = "" // 关联表格的主键 ID
    var filterInfo: BTFilterInfos? // 关联表过滤信息
    var backFieldId: String = "" //被双向关联字段关联的字段ID
    var backFieldName: String = "" //被双向关联字段关联的字段名
    var formula: String = "" // 公式字段的计算公式
    var formatter: String = "" // FieldMetaProperty 公式字段计算结果再套一层模版
    var proxyFieldMeta: Any?
    // swift 不允许值类型保存同类型的属性，否则无法计算值类型的实际内存占用，但是允许包含一个数组/字典
    var referencedFieldMeta: [BTFieldMeta] = [] // 原样引用的 field 属性信息
    // 若capture包含environment，可打开后置摄像头; 若capture包含user可打开前置摄像头 移动端只需要判断是否为空即可
    // 空：相册+摄像头，非空：仅摄像头
    var capture: [String] = []
    //默认日期格式下标
    var defaultDateTimeFormatIndex: Int = 0
    //默认数字格式下标
    var defaultNumberFormatIndex: Int = 0
    //默认进度条数字格式下标
    var defaultProgressTypeIndex: Int = 0
    //默认进度条数字小数位数下标
    var defaultProgressNumberFormatIndex: Int = 0
    var isAdvancedRules: Bool = false // 自动编号字段是否选择高级规则（false：自增数字；true：自定义规则）
    var ruleFieldOptions: [BTAutoNumberRuleOption] = [] // 自动编号字段用户选择的高级规则字段
    var reformatExistingRecord: Bool = false // 自动编号字段是否应用于之前的记录
    var defaultAutoNumberRuleTypeIndex: Int = 0 //自动编号字段默认选中的编号类型index
    // 地理位置字段输入方式
    var inputType: BTGeoLocationInputType = .notLimit
    var currencyCode: String = "" //货币类型代码
    var defaultCurrencyCodeIndex: Int = 0
    var defaultCurrencyDecimalIndex: Int = 0
    
    /// 颜色配置
    var colorConfig: BTColorConfig?                 // FieldConfigProperty
    /// 数值格式配置
    var formatConfig: BTFormatConfig?               // FieldConfigProperty
    /// 数值范围配置
    var rangeConfig: BTRangeConfig?                 // FieldConfigProperty
    /// 评分符号配置
    var ratingSymbolConfig: BTRatingSymbolConfig?   // FieldConfigProperty
    
    /// 进度条属性
    var progress: BTProgressModel?                  // FieldMetaProperty
    /// 是否开启自定义数值范围
    var rangeCustomize: Bool?                       // FieldMetaProperty
    /// 最小数值
    var min: Double?                                // FieldMetaProperty
    /// 最大数值
    var max: Double?                                // FieldMetaProperty
    
    /// 按钮字段属性
    var button: BTButtonModel?                      
    var isTriggerEnabled: Bool?
    
    /// 评分字段属性
    var rating: BTRatingModel?                      // FieldMetaProperty
    var enumerable: Bool?                           // FieldMetaProperty
    var rangeLimitMode: String?                     // FieldMetaProperty
    ///阶段字段属性
    var stages: [BTStageModel] = []                 // FieldMetaProperty

    static func deserialized(with dictionary: [String : Any]) -> BTFieldProperty {
        var model = BTFieldProperty()
        model.optionsType <~ (dictionary, "optionsType")
        model.options <~ (dictionary, "options")
        model.optionsRule <~ (dictionary, "optionsRule")
        model.autoFill <~ (dictionary, "autoFill")
        model.dateFormat <~ (dictionary, "dateFormat")
        model.timeFormat <~ (dictionary, "timeFormat")
        model.displayTimeZone <~ (dictionary, "displayTimeZone")
        model.baseId <~ (dictionary, "baseId")
        model.tableId <~ (dictionary, "tableId")
        model.viewId <~ (dictionary, "viewId")
        model.multiple <~ (dictionary, "multiple")
        model.fields <~ (dictionary, "fields")
        model.tableVisible <~ (dictionary, "tableVisible")
        model.primaryFieldId <~ (dictionary, "primaryFieldId")
        model.filterInfo <~ (dictionary, "filterInfo")
        model.backFieldId <~ (dictionary, "backFieldId")
        model.backFieldName <~ (dictionary, "backFieldName")
        model.formula <~ (dictionary, "formula")
        model.formatter <~ (dictionary, "formatter")
        model.proxyFieldMeta <~ (dictionary, "proxyFieldMeta")
        model.referencedFieldMeta <~ (dictionary, "referencedFieldMeta")
        model.capture <~ (dictionary, "capture")
        model.defaultDateTimeFormatIndex <~ (dictionary, "defaultDateTimeFormatIndex")
        model.defaultNumberFormatIndex <~ (dictionary, "defaultNumberFormatIndex")
        model.defaultProgressTypeIndex <~ (dictionary, "defaultProgressTypeIndex")
        model.defaultProgressNumberFormatIndex <~ (dictionary, "defaultProgressNumberFormatIndex")
        model.isAdvancedRules <~ (dictionary, "isAdvancedRules")
        model.ruleFieldOptions <~ (dictionary, "ruleFieldOptions")
        model.reformatExistingRecord <~ (dictionary, "reformatExistingRecord")
        model.defaultAutoNumberRuleTypeIndex <~ (dictionary, "defaultAutoNumberRuleTypeIndex")
        model.inputType <~ (dictionary, "inputType")
        model.currencyCode <~ (dictionary, "currencyCode")
        model.defaultCurrencyCodeIndex <~ (dictionary, "defaultCurrencyCodeIndex")
        model.defaultCurrencyDecimalIndex <~ (dictionary, "defaultCurrencyDecimalIndex")
        model.colorConfig <~ (dictionary, "colorConfig")
        model.formatConfig <~ (dictionary, "formatConfig")
        model.rangeConfig <~ (dictionary, "rangeConfig")
        model.ratingSymbolConfig <~ (dictionary, "ratingSymbolConfig")
        model.progress <~ (dictionary, "progress")
        model.rangeCustomize <~ (dictionary, "rangeCustomize")
        model.min <~ (dictionary, "min")
        model.max <~ (dictionary, "max")
        model.button <~ (dictionary, "button")
        model.isTriggerEnabled <~ (dictionary, "isTriggerEnabled")
        model.rating <~ (dictionary, "rating")
        model.enumerable <~ (dictionary, "enumerable")
        model.rangeLimitMode <~ (dictionary, "rangeLimitMode")
        model.stages <~ (dictionary, "options") // 阶段字段复用了options
        return model
    }
    
    mutating func didFinishDeserialize() {
        if let proxyFieldMeta = proxyFieldMeta as? [String: Any] {
            referencedFieldMeta = [proxyFieldMeta].map({ BTFieldMeta.convert(from: $0)})
        }
    }

    mutating func didFinishMapping() {
        if let proxyFieldMeta = proxyFieldMeta as? [String: Any],
           let unwrappedMeta = BTFieldMeta.deserialize(from: proxyFieldMeta) {
            referencedFieldMeta = [unwrappedMeta]
        }
    }
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<< self.inputType <-- TransformOf<BTGeoLocationInputType, String>(fromJSON: { (rawString) -> BTGeoLocationInputType? in
            guard let rawString = rawString else {
                return nil
            }
            return BTGeoLocationInputType(rawValue: rawString)
        }, toJSON: { inputType in
            inputType?.rawValue
        })
        mapper <<< self.stages <-- "options"
    }

     mutating func updateDateFormat(with format: BTDateFieldFormat) {
        self.dateFormat = format.dateFormat
        self.timeFormat = format.timeFormat
        self.displayTimeZone = format.displayTimeZone
    }
    
    func isMapDateFormat(_ format: BTDateFieldFormat) -> Bool {
        return self.dateFormat == format.dateFormat &&
        self.timeFormat == format.timeFormat &&
        self.displayTimeZone == format.displayTimeZone
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(options)
        hasher.combine(optionsRule)
        hasher.combine(optionsType)
        hasher.combine(autoFill)
        hasher.combine(dateFormat)
        hasher.combine(timeFormat)
        hasher.combine(displayTimeZone)
        hasher.combine(baseId)
        hasher.combine(viewId)
        hasher.combine(multiple)
        hasher.combine(fields)
        hasher.combine(tableVisible)
        hasher.combine(primaryFieldId)
        hasher.combine(formula)
        hasher.combine(formatter)
        hasher.combine(referencedFieldMeta)
        hasher.combine(capture)
        hasher.combine(isAdvancedRules)
        if isAdvancedRules {
            //自动编号为自定义规则时，ruleFieldOptions才参与equal的比较
            hasher.combine(ruleFieldOptions)
        }
        hasher.combine(reformatExistingRecord)
        hasher.combine(inputType)
        hasher.combine(backFieldId)
        hasher.combine(backFieldName)
        hasher.combine(filterInfo)
        
        hasher.combine(progress)
        hasher.combine(rangeCustomize)
        hasher.combine(min)
        hasher.combine(max)
        
        hasher.combine(button)
        hasher.combine(isTriggerEnabled)
        
        hasher.combine(rating)
        hasher.combine(enumerable)
        hasher.combine(rangeLimitMode)
    }
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTDescriptionModel: HandyJSON, Hashable, SKFastDecodable {

    var content: [BTRichTextSegmentModel]? // 与文本字段内容一致的格式
    var disableSync: Bool = false //是否允许同步到表单
    
    static func deserialized(with dictionary: [String : Any]) -> BTDescriptionModel {
        var model = BTDescriptionModel()
        model.disableSync <~ (dictionary, "disableSync")
        model.content <~ (dictionary, "content")
        return model
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(disableSync)
    }
}

struct BTNumberFieldFormat: HandyJSON, SKFastDecodable {
    var formatCode: String = "0"
    var name: String = "整数"
    var sample: String = "bitable.format.sample.digital_integer"
    var type: Int = 1
    var formatterName: String = "digital_without_separator"

    static func deserialized(with dictionary: [String : Any]) -> BTNumberFieldFormat {
        var model = BTNumberFieldFormat()
        model.formatCode <~ (dictionary, "formatCode")
        model.name <~ (dictionary, "name")
        model.sample <~ (dictionary, "sample")
        model.type <~ (dictionary, "type")
        model.formatterName <~ (dictionary, "formatterName")
        return model
    }
}

struct BTDateFieldFormat: HandyJSON, SKFastDecodable {
    var type: Int = 1
    var text: String = "2021/01/03"
    var dateFormat: String = "yyyy/MM/dd"
    var timeFormat: String = ""
    var displayTimeZone: Bool = false
    /// 由于 type 不能保证唯一，所以自己组装一个 id
    var id: String {
        return dateFormat + timeFormat + "\(displayTimeZone)"
    }

    static func deserialized(with dictionary: [String : Any]) -> BTDateFieldFormat {
        var model = BTDateFieldFormat()
        model.type <~ (dictionary, "type")
        model.text <~ (dictionary, "text")
        model.dateFormat <~ (dictionary, "dateFormat")
        model.timeFormat <~ (dictionary, "timeFormat")
        model.displayTimeZone <~ (dictionary, "displayTimeZone")
        return model
    }
}

enum BTGeoLocationInputType: String, HandyJSONEnum, CaseIterable, SKFastDecodableEnum {
    case notLimit = "NOT_LIMIT"
    case onlyMobile = "ONLY_MOBILE"
    
    var displayText: String {
        switch self {
        case .notLimit:
            return BundleI18n.SKResource.Bitable_Field_LocateManuallyMobileVer
        case .onlyMobile:
            return BundleI18n.SKResource.Bitable_Field_RealTimeLocationMobileVer
        }
    }
    var trackText: String {
        switch self {
        case .notLimit: return "any_location"
        case .onlyMobile: return "mobile_only"
        }
    }
}
