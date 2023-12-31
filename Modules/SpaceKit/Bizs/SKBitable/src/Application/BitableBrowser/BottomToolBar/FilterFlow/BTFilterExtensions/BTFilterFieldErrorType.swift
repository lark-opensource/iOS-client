//
//  BTFilterFieldErrorType.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/28.
//  


import SKResource

// fieldDeleted fieldTypeChanged fieldValueChanged 在筛选中都会把筛选条件删除掉。
enum BTFilterFieldErrorType: CaseIterable {
    case tableDeleted
    case tableNoPermission
    case fieldDeleted
    case fieldTypeChanged
    case fieldValueChanged
    case fieldNotSupport
    
    var warnMessage: String {
        switch self {
        case .tableDeleted:
            return ""
        case .tableNoPermission:
            return ""
        case .fieldDeleted:
            // 字段已删除，请重新设置
            return BundleI18n.SKResource.Bitable_Relation_FieldDeletedTip_Mobile
        case .fieldTypeChanged:
            // 字段类型发生变更，请重新设置
            return BundleI18n.SKResource.Bitable_Relation_FieldTypeChangedTip_Mobile
        case .fieldValueChanged:
            // 筛选条件中所选的内容发生变更，请重新设置
            return BundleI18n.SKResource.Bitable_Relation_RecordContentDeletedTip_Mobile
        case .fieldNotSupport:
            // 目前移动端暂不支持该字段
            return BundleI18n.SKResource.Bitable_Record_FieldNotSupported
        }
    }
}
