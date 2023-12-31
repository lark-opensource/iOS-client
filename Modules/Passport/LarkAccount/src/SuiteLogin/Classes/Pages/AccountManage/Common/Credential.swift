//
//  Credential.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/8/2.
//

import Foundation

typealias CContact = Credential.Contact

struct Credential {
    var type: LoginCredentialType {
        return contact.type
    }
    let contact: CContact
    let id: String

    let modify: Bool
    let delete: Bool
    let bindCp: Bool

    init(dic: [String: Any]) {
        self.id = dic["cp_id"] as? String ?? ""
        self.modify = dic["modify"] as? Bool ?? false
        self.delete = dic["delete"] as? Bool ?? false
        self.bindCp = dic["bind_cp"] as? Bool ?? false
        self.contact = CContact(
            type: LoginCredentialType(rawValue: dic["type"] as? Int ?? 0) ?? .unknown,
            contact: dic["contact"] as? String ?? "",
            displayName: dic["display_name"] as? String ?? "",
            credentialName: dic["credential_name"] as? String ?? "",
            mobile: Contact.Mobile(countryCode: dic["country_code"] as? String ?? "",
            phoneNumber: dic["mobile"] as? String ?? ""),
            authenticationChannel: LoginCredentialIdpChannel(rawValue: dic["authentication_channel"] as? String ?? "") ?? .unknown,
            iconUrl: dic["icon_url"] as? String ?? "",
            isTenantCp: dic["is_tenant_cp"] as? Bool ?? false,
            tenantName: dic["tenant_name"] as? String ?? "",
            tenantId: dic["tenant_id"] as? String ?? ""
        )
    }

    struct Contact {
        let type: LoginCredentialType
        var contact: String     // 手机号或邮箱 +86130000000 xxx@bytedance.com
        var displayName: String // 手机号 邮箱 ..
        var credentialName: String // 登录凭证名称
        var mobile: Mobile?      // 如果是手机才有
        var authenticationChannel: LoginCredentialIdpChannel?
        var iconUrl: String
        /// B端IdP
        var isTenantCp: Bool
        var tenantName: String
        var tenantId: String

        struct Mobile {
            var countryCode: String
            var phoneNumber: String
        }

        init(
            type: LoginCredentialType,
            contact: String,
            displayName: String,
            credentialName: String,
            mobile: Mobile? = nil,
            authenticationChannel: LoginCredentialIdpChannel? = .unknown,
            iconUrl: String = "",
            isTenantCp: Bool = false,
            tenantName: String = "",
            tenantId: String = "") {
            self.type = type
            self.contact = contact
            self.displayName = displayName
            self.credentialName = credentialName
            self.mobile = mobile
            self.authenticationChannel = authenticationChannel
            self.iconUrl = iconUrl
            self.isTenantCp = isTenantCp
            self.tenantName = tenantName
            self.tenantId = tenantId
        }
    }
}

let CredentialModifySuccessNotificationName = Notification.Name("CredentialModifySuccessNotificationName")
