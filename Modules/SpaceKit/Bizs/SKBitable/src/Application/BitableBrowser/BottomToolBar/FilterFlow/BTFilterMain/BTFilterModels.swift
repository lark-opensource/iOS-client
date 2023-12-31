//
//  BTFilterModels.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/1.
//  


import Foundation
import HandyJSON
import SKCommon
import SKInfra

struct BTBaseData: BTEventBaseDataType {
    var baseId: String
    var tableId: String
    var viewId: String
}

enum BTFilterOperator: String {
    case `is`
    case isNot
    case contains
    case doesNotContain
    case isEmpty
    case isNotEmpty
    case isGreater
    case isGreaterEqual
    case isLess
    case isLessEqual
    
    
    var tracingString: String {
        switch self {
        case .is:
            return "is"
        case .isNot:
            return "is_not"
        case .contains:
            return "contains"
        case .doesNotContain:
            return "not_contain"
        case .isEmpty:
            return "is_empty"
        case .isNotEmpty:
            return "not_empty"
        case .isGreater:
            return "greater"
        case .isGreaterEqual:
            return "greater_or_equal"
        case .isLess:
            return "less"
        case .isLessEqual:
            return "less_or_equal"
        }
    }
    
    static var defaultValue: String {
        return BTFilterOperator.is.rawValue
    }
    
    static func isAsValue(rule: String) -> Bool {
        return [BTFilterOperator.isEmpty.rawValue,
                BTFilterOperator.isNotEmpty.rawValue].contains(rule)
    }

    static func isEqual(rule: String) -> Bool {
        return [BTFilterOperator.`is`.rawValue,
                BTFilterOperator.isNot.rawValue].contains(rule)
    }
}

enum BTFilterDuration: String, CaseIterable {
    case ExactDate
    case Today
    case Tomorrow
    case Yesterday
    case TheLastWeek // 以下四项由于历史原因，命名不好改了，这里含义是过去7天
    case TheNextWeek // 未来7天
    case TheLastMonth // 过去30天
    case TheNextMonth // 未来30天
    case CurrentWeek
    case LastWeek
    case CurrentMonth
    case LastMonth
    
    var trackString: String {
        switch self {
        case .ExactDate: return "exact_date"
        case .Today: return "today"
        case .Tomorrow: return "tomorrow"
        case .Yesterday: return "yesterday"
        case .TheLastWeek: return "last_7_days"
        case .TheNextWeek: return "next_7_days"
        case .TheLastMonth: return "last_30_days"
        case .TheNextMonth: return "next_30_days"
        case .CurrentWeek: return "this_week"
        case .LastWeek: return "last_week"
        case .CurrentMonth: return "this_month"
        case .LastMonth: return "last_month"
        }
    }
}

/// 字段不可见
enum BTFieldInvalidType: Int, Codable, SKFastDecodableEnum, HandyJSONEnum {
    case other = 0
    case fieldUnreadable = 1
    case partNoPermission = 2
}


// MARK: 筛选信息所需模型
/// 条件模型， 这里用 handyJSON 是为了适配原来的模型
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTFilterCondition: HandyJSON, Hashable, SKFastDecodable {
    
    var conditionId: String = ""
    var fieldId: String = ""
    var fieldType: Int = 0
    var `operator`: String = "is"
    var value: [AnyHashable]?
    var invalidType: BTFieldInvalidType? = nil

    static func deserialized(with dictionary: [String : Any]) -> BTFilterCondition {
        var model = BTFilterCondition()
        model.conditionId <~ (dictionary, "conditionId")
        model.fieldId <~ (dictionary, "fieldId")
        model.fieldType <~ (dictionary, "fieldType")
        model.operator <~ (dictionary, "operator")
        model.value <~ (dictionary, "value")
        model.invalidType <~ (dictionary, "invalidType")
        return model
    }
    
    init(conditionId: String,
         fieldId: String,
         fieldType: Int,
         operator: String = "is",
         invalidType: BTFieldInvalidType? = nil,
         value: [AnyHashable]? = nil) {
        self.conditionId = conditionId
        self.fieldId = fieldId
        self.fieldType = fieldType
        self.operator = `operator`
        self.value = value
        self.invalidType = invalidType
    }
        
    init() {}
    
    static func == (lhs: BTFilterCondition, rhs: BTFilterCondition) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension BTFilterCondition {
    
    func getExactDateValueIfExist(with filterOptions: BTFilterOptions) -> Double? {
        guard let fieldOption = filterOptions.fieldOptions.first(where: { $0.id == fieldId }) else {
            return  nil
        }
        guard BTFilterValueType(valueType: fieldOption.valueType) == .date else {
            return nil
        }
        guard let values = self.value,
              values.count > 1,
              let exactDateValue = values[1] as? Double else {
            return nil
        }
        return exactDateValue
    }
}

/// 已筛选信息
struct BTFilterInfos: HandyJSON, Hashable, SKFastDecodable {

    var conjunction: String = "and"
    var conditions: [BTFilterCondition] = []
    var notice: String? = nil
    
    // 埋点用
    var schemaVersion: Int? = nil
    var isRowLimit: Bool? = false

    static func deserialized(with dictionary: [String : Any]) -> BTFilterInfos {
        var model = BTFilterInfos()
        model.conjunction <~ (dictionary, "conjunction")
        model.conditions <~ (dictionary, "conditions")
        model.notice <~ (dictionary, "notice")
        model.schemaVersion <~ (dictionary, "schemaVersion")
        model.isRowLimit <~ (dictionary, "isRowLimit")
        return model
    }
    
    static func == (lhs: BTFilterInfos, rhs: BTFilterInfos) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: 筛选流程所需模型
struct BTFilterOptions: Codable {
    
    struct Conjunction: Codable {
        var value: String
        var text: String
    }
    
    struct Field: Codable {
        /// 规则字段
        struct RuleOperator: Codable {
            var value: String
            var text: String
        }
        /// 选项字段
        struct SelectFieldOption: Codable {
            var id: String
            var name: String
            var color: Int
        }
        var id: String
        var name: String
        private var type: Int
        private var fieldUIType: String?
        var isSync: Bool?
        var invalidType: BTFieldInvalidType? = nil
        
        var compositeType: BTFieldCompositeType {
            return BTFieldCompositeType(fieldTypeValue: type, uiTypeValue: fieldUIType)
        }
        var valueType: Int //如果是原样引用则代表的是原样引用的 fieldType
        var operators: [RuleOperator] = []
       /// 当字段为单多选的选项值
        var selectFieldOptions: [SelectFieldOption]? = []
        /// 当字段为人员的属性值，是否可以多选。
        var multiple: Bool? = false
        /// 当字段为日期时的属性值
        var dateFormat: String? = ""
        var timeFormat: String? = ""
    }
    
    var conjunctionOptions: [Conjunction] = []
    var fieldOptions: [Field] = []
    var durationOptions: [BTFilterDurations.Duration] = []
    var timeZone: String? = ""
}

/// 人员字段相关信息
struct BTFilterDurations: Codable {
    struct Duration: Codable {
        var value: String
        var text: String
    }
    var data: [Duration] = []
}

/// 人员字段相关信息
struct BTFilterUserOptions: Codable {
    struct User: Codable {
        var userId: String = ""
        var name: String = ""
        var enName: String = ""
        var avatarUrl: String = ""
    }
    var data: [User] = []
}

/// 关联字段相关信息
struct BTFilterLinkOptions: Codable {
    struct Link: Codable {
        var id: String
        var text: String
    }
    var data: [Link] = []
}

/// 成员（群、机器人、联系人等）字段相关信息
protocol BTFilterChatterOptionProtocol: Codable {
    var chatterId: String { get set }
    var name: String { get set }
    var avatarUrl: String { get set }
}

struct BTFilterGroupOption: BTFilterChatterOptionProtocol {
    
    var chatterId: String = ""
    var name: String = ""
    var avatarUrl: String = ""
    var linkToken: String = ""
    enum CodingKeys: String, CodingKey {
        case chatterId = "id"
        case name
        case avatarUrl
        case linkToken
    }
}

struct BTFilterUserOption: BTFilterChatterOptionProtocol {
    var chatterId: String = ""
    var name: String = ""
    var enName: String = ""
    var avatarUrl: String = ""
    
    enum CodingKeys: String, CodingKey {
        case chatterId = "userId"
        case name
        case enName
        case avatarUrl
    }
}
