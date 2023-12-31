//
//  BTFieldExtendModel.swift
//  SKBitable
//
//  Created by zhysan on 2023/3/31.
//

import SKFoundation
import SKResource
import UniverseDesignIcon
import HandyJSON

/// 字段的已（可）扩展信息
struct FieldExtendConfigs: Codable, Equatable {
    let isOwner: Bool
    var configs: [FieldExtendConfig]
}

/// 当前表中存在的可扩展字段
struct ExistExtendableFields: Codable {
    let groupName: String
    let fields: [FieldExtendOrigin]
}

/// 扩展系统来源（eg: 通讯录）
struct FieldExtendConfig: Codable, Equatable {
    let editInfo: String
    let fromInfo: String
    let editable: Bool
    let extendType: String
    var extendState: Bool
    var extendItems: [FieldExtendConfigItem]
}

/// 扩展子字段信息
struct FieldExtendConfigItem: Codable, Equatable, BTFieldProtocol {
    let extendFieldType: String
    let fieldType: BTFieldType
    let fieldUIType: BTFieldUIType
    let name: String
    let fieldId: String?
    let fieldName: String?
    var isChecked: Bool
}

/// 扩展根字段信息
struct FieldExtendOrigin: Codable, BTFieldProtocol {
    let fieldId: String
    let fieldName: String
    let fieldType: BTFieldType
    let fieldUIType: BTFieldUIType
    let configs: [FieldExtendConfig]
}

struct FieldExtendInfo: HandyJSON, Hashable {
    struct OriginInfo: HandyJSON, Hashable, BTFieldProtocol {
        var fieldId: String = ""
        var fieldName: String = ""
        var fieldType: BTFieldType = .notSupport
        var fieldUIType: BTFieldUIType = .notSupport
    }
    
    struct ExtendInfo: HandyJSON, Hashable, Codable {
        var extendFieldType: String = ""
        var originFieldId: String?
        var originFieldUIType: BTFieldUIType = .notSupport
    }
    
    var originField: OriginInfo?
    
    var editable: Bool = false
    
    var extendInfo: ExtendInfo = ExtendInfo()
}

enum FieldExtendExceptNotice: Int, HandyJSONEnum {
    case noExtendFieldPermForOwner = 1
    case noExtendFieldPermForUser = 2
    case originDeleteForOwner = 3
    case originDeleteForUser = 4
    case originMultipleEnable = 5
    
    var bodyText: String {
        switch self {
        case .originDeleteForOwner:
            // 源字段被删除，owner 提示
            return BundleI18n.SKResource.Bitable_PeopleField_SourceFieldNotExisted_SwitchToNormalField_Description
        case .originDeleteForUser:
            // 源字段被删除，一般用户（非 owner）提示
            return BundleI18n.SKResource.Bitable_PeopleField_Error_PeopleFieldNotExist_Toast
        case .noExtendFieldPermForOwner:
            // owner 变更，新 owner 提示
            return BundleI18n.SKResource.Bitable_PeopleField_Error_SyncPausedDueToOwnerChangedResetRequired_Toast
        case .noExtendFieldPermForUser:
            // owner 变更，一般用户（非 owner）提示
            return BundleI18n.SKResource.Bitable_PeopleField_Error_SyncPausedDueToOwnerChangedContactOwner_Toast
        case .originMultipleEnable:
            // 源字段被修改为多选，扩展关系断联
            return BundleI18n.SKResource.Bitable_PeopleField_SyncPauseDueToAllowAddMultiplePerson_Description
        }
    }
    
    var actionText: String? {
        switch self {
        case .originDeleteForOwner:
            return BundleI18n.SKResource.Bitable_PeopleField_Switch_Button
        case .noExtendFieldPermForOwner:
            return BundleI18n.SKResource.Bitable_PeopleField_Resync_Button
        case .originDeleteForUser, .noExtendFieldPermForUser, .originMultipleEnable:
            return nil
        }
    }
}

/// 存储扩展字段编辑信息存储类
class FieldExtendOperationStore: Codable {
    struct AddOption: Codable, Equatable {
        var extendFieldType: String
        var originFieldReportType: String
    }
    
    struct DelOption: Codable, Equatable {
        var extendFieldType: String
        var extendFieldId: String
    }
    
    class FieldExtendOptions: Codable {
        var addFieldOptions: [AddOption] = []
        var deleteFieldOptions: [DelOption] = []
    }
    
    var extendFieldOptions = FieldExtendOptions()
}
