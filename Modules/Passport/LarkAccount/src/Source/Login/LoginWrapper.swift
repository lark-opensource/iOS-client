//
//  LoginWrapper.swift
//  LarkAccount
//
//  Created by liuwanlin on 2018/11/23.
//

import Foundation
import LarkLocalizations
import RxSwift
import EENavigator
import LarkUIKit
import LarkReleaseConfig
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface
import LarkPerf

struct UserListUpdateInfo: PushMessage {
    let userInfos: [V3UserInfo]
    let pendingUsers: [PendingUser]
    let userInfoList: [V4UserInfo]
}

extension Array where Element == V4UserInfo {
    func toAccountList() -> [Account] {
        var result = [Account]()
        forEach { userInfo in
            result.append(userInfo.makeAccount())
        }
        return result
    }

    func makeUserList() -> [User] {
        return map { $0.makeUser() }
    }
}

extension AccountUserInfo {
    func toV3UserInfo() -> V3UserInfo {
        var tag: LarkAccountInterface.TenantTag = .defaultValue
        if let tagInInt = self.tenant?.tag,
           let tagInTagType = LarkAccountInterface.TenantTag(rawValue: tagInInt) {
            tag = tagInTagType
        }

        var tenantInfo: V3TenantInfo?
        if let tenant = self.tenant {
            tenantInfo = V3TenantInfo(
                id: tenant.tenantID,
                name: tenant.name,
                iconUrl: tenant.iconUrl,
                domain: tenant.tenantCode,
                fullDomain: tenant.fullDomain,
                tip: nil,
                tag: tag,
                status: nil,
                singleProductTypes: []
            )
        }

        return V3UserInfo(
            id: userID,
            name: name,
            i18nName: nil,
            active: isActive,
            frozen: isFrozen,
            c: tenantID == "0" ? true: false,
            avatarUrl: avatarUrl,
            avatarKey: avatarKey,
            env: userEnv ?? "", // userEnv in AccountUserInfo instance decoded from disk must not be empty
            unit: userUnit ?? "", // userUnit in AccountUserInfo instance decoded from disk must not be empty
            tenant: tenantInfo,
            status: status, // user transform from Account must be enable user
            tip: nil,
            bIdp: isIdp,
            guest: isGuest,
            securityConfig: securityConfig,
            session: session,
            sessions: sessions,
            logoutToken: logoutToken
        )
    }
}

extension V3SecurityConfigItem {
    func transform() -> SecurityConfigItem {
        return SecurityConfigItem(
            status: switchStatus,
            info: moduleInfo
        )
    }
}
