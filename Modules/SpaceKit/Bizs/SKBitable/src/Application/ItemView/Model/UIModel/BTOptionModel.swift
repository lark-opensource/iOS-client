//
//  BTOptionModel.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/17.
//  


import UIKit
import HandyJSON
import SKCommon
import SKInfra

/// 选项字段的信息（对应前端的 `IOptionInfo`）
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTOptionModel: HandyJSON, Hashable, SKFastDecodable {
    static func == (lhs: BTOptionModel, rhs: BTOptionModel) -> Bool {
        return lhs.hashValue == rhs.hashValue

    }
    var id: String = "" // option ID
    var name: String = "" // option 内容
    var color: Int = 0 // 上层颜色数组 colors 的索引值
    
    static func deserialized(with dictionary: [String : Any]) -> BTOptionModel {
        var model = BTOptionModel()
        model.id <~ (dictionary, "id")
        model.name <~ (dictionary, "name")
        model.color <~ (dictionary, "color")
        return model
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(color)
    }
}

enum BTOptionType: Int, HandyJSONEnum, SKFastDecodableEnum {
    case staticOption = 0//自定义选项数据
    case dynamicOption = 1 //引用数据
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTDynamicOptionRuleModel: HandyJSON, Hashable, SKFastDecodable {
    static func == (lhs: BTDynamicOptionRuleModel, rhs: BTDynamicOptionRuleModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var targetTable: String = "" //引用表ID
    var targetField: String = "" //引用字段ID
    var conditions: [BTDynamicOptionConditionModel] = [] //引用条件
    var conjunction: String = "and" //引用条件组合类型
    
    static func deserialized(with dictionary: [String: Any]) -> BTDynamicOptionRuleModel {
        var model = BTDynamicOptionRuleModel()
        model.targetTable <~ (dictionary, "targetTable")
        model.targetField <~ (dictionary, "targetField")
        model.conjunction <~ (dictionary, "conjunction")
        model.conditions <~ (dictionary, "conditions")
        return model
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(targetTable)
        hasher.combine(targetField)
        hasher.combine(conditions)
        hasher.combine(conjunction)
    }
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTDynamicOptionConditionModel: HandyJSON, Hashable, SKFastDecodable {

    var conditionId: String = ""
    var fieldId: String = ""
    var fieldType: BTFieldType = .text
    var `operator`: BTConditionType = .Unkonwn
    var value: String = ""
    
    static func deserialized(with dictionary: [String : Any]) -> BTDynamicOptionConditionModel {
        var model =  BTDynamicOptionConditionModel()
        model.conditionId <~ (dictionary, "conditionId")
        model.fieldId <~ (dictionary, "fieldId")
        model.value <~ (dictionary, "value")
        model.fieldType <~ (dictionary, "fieldType")
        model.operator <~ (dictionary, "operator")
        return model
    }

    mutating func mapping(mapper: HelpingMapper) {
        mapper <<< self.operator <-- "operator"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(conditionId)
        hasher.combine(fieldId)
        hasher.combine(fieldType)
        hasher.combine(self.operator)
        hasher.combine(value)
    }
    
    static func == (lhs: BTDynamicOptionConditionModel, rhs: BTDynamicOptionConditionModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

}
