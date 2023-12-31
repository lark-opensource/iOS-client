//
//  BTStageModel.swift
//  SKBitable
//
//  Created by X-MAN on 2023/6/1.
//

import Foundation
import HandyJSON
import SKInfra

struct BTStageModel: HandyJSON, SKFastDecodable, Equatable {
    static func == (lhs: BTStageModel, rhs: BTStageModel) -> Bool {
        return lhs.isCurrent == rhs.isCurrent && lhs.id == rhs.id && lhs.name == rhs.name &&
        lhs.status == rhs.status && lhs.color == rhs.color &&
        lhs.type == rhs.type && lhs.fieldsConfigInfo.elementsEqual(rhs.fieldsConfigInfo, by: { item1, itme2 in
            return item1.id == itme2.id
        })
    }
    
    var id: String = ""
    var name: String = "" // 名称
    var color: Int = 0  // 颜色
    var type: StageType = .defualt // 阶段类型，model层不感知具体类型，仅保存，业务方自行定义
    var status: StageNodeState = .pending
    var transitionRule: TransitionRule = TransitionRule() // 转换规则/完成方式
    var fieldsConfigInfo: [FieldConfigInfo] = [] // 当前阶段关联的字段，即阶段表单，用对象保存，方便以后扩展
    var isCurrent: Bool = false // 是否是当选中的，本地使用

    static func deserialized(with dictionary: [String : Any]) -> BTStageModel {
        var model = BTStageModel()
        model.id <~ (dictionary, "id")
        model.name <~ (dictionary, "name")
        model.color <~ (dictionary, "color")
        model.type <~ (dictionary, "type")
        model.status <~ (dictionary, "status")
        model.transitionRule <~ (dictionary, "transitionRule")
        model.fieldsConfigInfo <~ (dictionary, "fieldsConfigInfo")
        return model
    }
    
    struct TransitionRule: HandyJSON, SKFastDecodable {
        enum TransitionType: String, HandyJSONEnum, SKFastDecodableEnum {
            case condition = "Condition" // 需要满足阶段表单设置的条件
            case conditionAndPerson = "ConditionAndPerson" // 需要满足阶段表单设置的条件 & 指定人员/创建人字段可流
        }
        var type: TransitionType = .condition
        var permissionFieldIds: [String] = []
        var condition: BTFilterInfos = BTFilterInfos()

        static func deserialized(with dictionary: [String : Any]) -> TransitionRule {
            var model = TransitionRule()
            model.type <~ (dictionary, "type")
            model.permissionFieldIds <~ (dictionary, "permissionFieldIds")
            model.condition <~ (dictionary, "condition")
            return model
        }
    }
    enum StageType: String, HandyJSONEnum, CaseIterable, SKFastDecodableEnum {
        case defualt = "Default"
        case endDone = "EndDone"
        case endCancel = "EndCancel"
    }
    enum StageNodeState: String, HandyJSONEnum, SKFastDecodableEnum {
        case pending
        case progressing
        case finish
    }
    struct FieldConfigInfo: HandyJSON, SKFastDecodable {
        var id: String = ""
        static func deserialized(with dictionary: [String : Any]) -> FieldConfigInfo {
            var model = FieldConfigInfo()
            model.id <~ (dictionary, "id")
            return model
        }
    }
}
