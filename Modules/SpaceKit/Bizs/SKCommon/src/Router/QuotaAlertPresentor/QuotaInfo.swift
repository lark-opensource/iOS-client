//
//  QuotaInfo.swift
//  SKCommon
//
//  Created by bupozhuang on 2021/7/19.
//

import Foundation
import SKFoundation
import UniverseDesignColor
import SpaceInterface

struct QuotaContact: Codable {
    static let attributedStringAtInfoKey = NSAttributedString.Key(rawValue: "at")
    let uid: String
    let name: String
    let enName: String
    let display_name: UserAliasInfo?
    var isAdmin: Bool = false
    
    var displayName: String {
        if let displayName = display_name?.currentLanguageDisplayName {
            return displayName
        }
        if DocsSDK.currentLanguage == .en_US {
            return enName.isEmpty ? name : enName
        } else {
            return name
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case uid
        case name
        case enName
        case display_name
    }
}

struct QuotaUrl: Codable {
    let title: String
    let url: String
    
    private enum CodingKeys: String, CodingKey {
        case title
        case url
    }
}

struct QuotaNewState: Codable {
    let usage: Int64
    let limit: Int64
    let config_type: ContactType?
    var contacts: [QuotaContact]
    var conf_contacts: [QuotaContact]?
    var url_link: QuotaUrl?
    
    private enum CodingKeys: String, CodingKey {
        case usage
        case limit
        case contacts
        case config_type
        case conf_contacts
        case url_link
    }
}

struct QuotaInfo: Codable {
    var tenantState: QuotaNewState
    let myState: QuotaNewState
    let ownerState: QuotaNewState?
    
    private enum CodingKeys: String, CodingKey {
        case tenantState = "tenant"
        case myState = "user"
        case ownerState = "owner"
    }
    
    mutating func updateAdmins() {
        var contacts = [QuotaContact]()
        for item in tenantState.contacts {
            var user = item
            user.isAdmin = true
            contacts.append(user)
        }
        tenantState.contacts = contacts
    }
}

struct QuotaUploadInfo: Codable {
    static let attributedStringAtInfoKey = NSAttributedString.Key(rawValue: "at")
    let suiteType: SuiteType
    var suiteToQuota: SuiteToQuota
    let admins: [Admin]
    let isAdmin: Bool
    
    private enum CodingKeys: String, CodingKey {
        case suiteType = "suite_type"
        case suiteToQuota = "suite_to_file_size_limit"
        case admins = "admins"
        case isAdmin = "is_admin"
    }
    
    mutating func setMaxSize(_ size: Int64?) {
        suiteToQuota.maxSize = size
    }
}

// 租户商业版本
enum SuiteType: Int, Codable {
    case legacyFree = 1        // 标准版E1
    case legacyEnterprise = 2   // 旗舰版E2
    case standard = 3          // 标准版E3(未认证）
    case certStandard = 4      // 标准版E3(已认证）
    case business = 5         // 企业版E4
    case enterprise = 6       // 旗舰版E5
}

// 配置类型
enum ContactType: Int, Codable {
    case contact = 0        // 管理员
    case orderContact = 1   // 指定成员
    case fileContact = 2    // 文档链接
}

struct SuiteToQuota: Codable {
    let legacyFreeMaxSize: Int64?
    let legacyEnterpriseMaxSize: Int64?
    let standardMaxSize: Int64?
    let certStandardMaxSize: Int64?
    let businessMaxSize: Int64?
    let enterpriseMaxSize: Int64?
    var maxSize: Int64? // 所有版本的最大值，后续可能有版本7、8、9
    
    private enum CodingKeys: String, CodingKey {
        case legacyFreeMaxSize = "1"
        case legacyEnterpriseMaxSize = "2"
        case standardMaxSize = "3"
        case certStandardMaxSize = "4"
        case businessMaxSize = "5"
        case enterpriseMaxSize = "6"
        case maxSize = "maxSize"
    }
    var tenantMaxSize: Int64? {
        if let maxSize = maxSize {
            return maxSize
        }
        if let enterpriseMaxSize = enterpriseMaxSize {
            return enterpriseMaxSize
        }
        
        if let legacyEnterpriseMaxSize = legacyEnterpriseMaxSize {
            return legacyEnterpriseMaxSize
        }
        
        if let businessMaxSize = businessMaxSize {
            return businessMaxSize
        }
        
        if let certStandardMaxSize = certStandardMaxSize {
            return certStandardMaxSize
        }
        
        if let standardMaxSize = standardMaxSize {
            return standardMaxSize
        }
        
        if let legacyFreeMaxSize = legacyFreeMaxSize {
            return legacyFreeMaxSize
        }
        DocsLogger.info("quota upload error: can not get tanantMaxSize")
        return nil
    }
}

struct Admin: Codable {
    let uid: String
    let name: String
    let enName: String
    
    private enum CodingKeys: String, CodingKey {
        case uid
        case name
        case enName = "en_name"
    }
    
    var displayName: String {
        if DocsSDK.currentLanguage == .en_US {
            return enName.isEmpty ? name : enName
        } else {
            return name
        }
    }
}
