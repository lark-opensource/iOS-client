//
//  PassportDomain.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/11/8.
//

import Foundation

// MARK: - Passport Level 2

public enum Passport: Int32, MetricDomainEnum {
    case unknown
    case login, account, logout, switchUser, userList
}

// MARK: - Passport Level 3

public enum Login: Int32, MetricDomainEnum {
    case unknown
    case loginTypeV3, verifyCodeV3, verifyPwdV3
    case tenantCreateV3, chooseOrCreateV3, successCV3
    case registerV3, afterLogin, loginTypeV2
    case createTeamV2, verifyCodeV2, verifyPwdV2
    case setPwdV2, forgetPwdV2, setPersonalIdentityV2
    case selectTenantV2, joinTenantScanV3, joinTenantCodeV3
    case officialEmailV3, setNameV3, setPwdV3
    case dispatchNextV3, joinTenantV3
}

public enum AccountDM: Int32, MetricDomainEnum {
    case unknown
    case modifyPwd, cpManager, securityVerify
    case twoAuth, loginDeviceManage, cancelAccount
}

public enum UserList: Int32, MetricDomainEnum {
    case unknown
    case joinTenantV3 = 1
}
