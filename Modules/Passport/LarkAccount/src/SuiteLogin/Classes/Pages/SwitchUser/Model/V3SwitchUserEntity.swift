//
//  SwitchUserModel.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/14.
//

import Foundation

/// 只用于C端IdP
enum LoginCredentialIdpChannel: String, Codable {
    case unknown = ""
    case apple_id = "apple_id"
    case facebook = "facebook"
    case google = "google"
    case wechat = "wechat"
}

enum LoginCredentialType: Int, Codable {
    case unknown = 0
    case phone = 1
    case email = 2
    /// B端IdP 和 C端IdP
    case idp = 32
}

/// 对 LoginCredentialType 的扩充，支持更多验证方式
enum SwitchVerifyType: Int, Codable {
    case unknown = 0
    case phone = 1
    case email = 2
    case otp = 3
    /// B端IdP 和 C端IdP
    case idp = 32
}

//注册流程控制
enum RegisterActionType: Int, Codable {
    case passport = 0
    case ug = 1 //国内ug流程
    case global = 2 //国外ug流程
    case idp = 3 //google idp流程
}
