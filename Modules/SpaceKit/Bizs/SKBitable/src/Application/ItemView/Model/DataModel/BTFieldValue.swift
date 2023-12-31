//
// Created by duanxiaochen.7 on 2022/3/21.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import HandyJSON
import SKCommon
import SKInfra

/// 字段的内容信息（对应前端的 `IFieldInfo`）
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTFieldValue: HandyJSON, SKFastDecodable {
    
    struct FieldPermission: HandyJSON, SKFastDecodable, Equatable {
        
        
        static func deserialized(with dictionary: [String : Any]) -> BTFieldValue.FieldPermission {
            var model = FieldPermission()
            model.stageConvert <~ (dictionary, "stageConvert")
            return model
        }
        
        var stageConvert: [String: Bool] = [:]
    }

    enum UneditableReason: String, Equatable, HandyJSONEnum, SKFastDecodableEnum {
        case notSupported = "field_not_support_edit" // 该字段在移动端暂时还不支持编辑
        case fileReadOnly = "suite_no_edit_perm" // 用户对于该文档无编辑权限，需要去找 owner 去申请
        case phoneLandscape = "landscape_readonly" // iPhone 横屏下不支持编辑
        case proAdd = "attachment_forbidden_in_pro" // 高级权限新增卡片时不允许上传附件
        case others // 精细化权限 || 其他特殊场景下不支持编辑
        case bitableNotReady // table 未ready不让编辑
//        case unreadable // 无阅读权限
        case drillDown = "drill_down_not_support_edit" // 数据下钻不允许编辑
        case isSyncTable = "is_sync_table" // 数据是从其它数据表同步的
        case isExtendField = "is_extend_field" // 数据是从其它字段扩展来的
        case editAfterSubmit = "edit_after_submit"     // 记录添加模式，等记录添加完成后才可以编辑
        case isOnDemand = "is_on_demand" //按需
    }

    var id: String = "" // field id，用于从 BTFieldMeta 里面取其他的属性
    var active: Bool = false // 是不是当前聚焦的卡片
    var editable: Bool = false // 当前字段是否支持编辑
    var triggerAble: Bool = false // 按钮字段点击是否可触发
    var uneditableReason: UneditableReason = .others
    var extraParams: [String: Any]?
    var value: Any? // 前端的类型是 ICellValue，具体内容的拆包放到 BTFieldModel 中完成
    var fieldPermission: FieldPermission? // 字段某些权限控制，目前阶段字段在用后需要其他字段需要可进行扩展

    static func deserialized(with dictionary: [String : Any]) -> BTFieldValue {
        var model = BTFieldValue()
        model.id <~ (dictionary, "id")
        model.active <~ (dictionary, "active")
        model.editable <~ (dictionary, "editable")
        model.triggerAble <~ (dictionary, "triggerAble")
        model.uneditableReason <~ (dictionary, "uneditableReason")
        model.extraParams <~ (dictionary, "extraParams")
        model.value <~ (dictionary, "value")
        model.fieldPermission <~ (dictionary, "fieldPermission")
        return model
    }

}
