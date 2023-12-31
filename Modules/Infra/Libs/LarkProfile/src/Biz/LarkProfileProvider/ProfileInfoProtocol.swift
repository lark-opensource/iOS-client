//
//  ProfileInfoProtocol.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/4/12.
//

import Foundation
import RustPB

public protocol ProfileInfoProtocol {
    var userInfoProtocol: UserInfoProtocol { get set }
    var ctaOrders: [RustPB.Contact_V2_GetUserProfileResponse.CTA] { get }
    var fieldOrders: [RustPB.Contact_V2_GetUserProfileResponse.Field] { get }
    var tabOrders: [Contact_V2_GetUserProfileResponse.TabInfo] { get }
    var canNotFind: Bool { get }
}

extension RustPB.Contact_V2_GetAIProfileResponse: ProfileInfoProtocol {
    public var userInfoProtocol: UserInfoProtocol {
        get {
            return aiInfo
        }
        set {
            if let newValue = newValue as? Contact_V2_AIProfile {
                aiInfo = newValue
            }
        }
    }
    public var tabOrders: [Contact_V2_GetUserProfileResponse.TabInfo] {
        return []
    }
    public var canNotFind: Bool {
        return false
    }
}

extension RustPB.Contact_V2_GetUserProfileResponse: ProfileInfoProtocol {
    public var userInfoProtocol: UserInfoProtocol {
        get {
            return userInfo
        }
        set {
            if let newValue = newValue as? Contact_V2_GetUserProfileResponse.UserInfo {
                userInfo = newValue
            }
        }
    }
    public var canNotFind: Bool {
        return self.permission.canNotFind
    }
}

public protocol UserInfoProtocol {
    var avatarKey: String { get set }
    var avatarMedal: Basic_V1_AvatarMedal { get }
    var userID: String { get }
    var topImage: Basic_V1_ImageSetPassThrough { get }
    var medalList: Contact_V2_GetUserProfileResponse.MedalList { get }
    var description_p: Basic_V1_Chatter.Description { get }
    var certificationInfo: Contact_V2_GetUserProfileResponse.UserInfo.CertificationInfo { get }
    var hasTenantCertification_p: Bool { get }
    var isTenantCertification: Bool { get }
    var isRegistered: Bool { get }
    var friendStatus: Contact_V2_GetUserProfileResponse.UserInfo.FriendStatus { get }
    var tenantName: Contact_V2_GetUserProfileResponse.I18nVal { get }
    var tenantNameStatus: Basic_V1_TenantNameStatus { get }
    var isResigned: Bool { get }
    var isSpecialFocus: Bool { get }
    var hasGender: Bool { get }
    var gender: Contact_V2_GetUserProfileResponse.UserInfo.Gender { get }
    var isFrozen: Bool { get }
    var hasDoNotDisturbEndTime: Bool { get }
    var doNotDisturbEndTime: Int64 { get }
    var hasWorkStatus: Bool { get }
    var workStatus: Basic_V1_WorkStatus { get }
    var hasShareInfo: Bool { get }
    var shareInfo: Contact_V2_GetUserProfileResponse.ShareInfo { get }
    var leaderID: String { get }
    var contactToken: String { get }
    var customTagFields: [Contact_V2_GetUserProfileResponse.Field] { get }
    var nameWithAnotherName: String { get set }
    var alias: String { get }
    var genderPronouns: String { get }
    var metaUnitDescription: Contact_V2_GetUserProfileResponse.I18nVal { get }
    var profileUserName: String { get set }
    var userName: String { get set }
    var tenantID: String { get }
    var blockStatus: Contact_V2_GetUserProfileResponse.UserInfo.BlockStatus { get }
    var isBlocked: Bool { get }
    var hasApplyCommunication: Bool { get }
    var canBlock: Bool { get }
    var applyCommunication: Contact_V2_GetUserProfileResponse.UserInfo.ApplyCommunication { get }
    var isDefaultAvatar: Bool { get }
    var contactApplicationID: Int64 { get }
    var chatterStatus: [Basic_V1_Chatter.ChatterCustomStatus] { get }
    var hideAddConnectButton: Bool { get }
}

extension RustPB.Contact_V2_GetUserProfileResponse.UserInfo: UserInfoProtocol {}

extension Contact_V2_AIProfile: UserInfoProtocol {
    public var userName: String {
        get { name }
        set { name = newValue }
    }
    public var userID: String { return self.id }
    public var medalList: Contact_V2_GetUserProfileResponse.MedalList {
        return Contact_V2_GetUserProfileResponse.MedalList()
    }
    public var certificationInfo: Contact_V2_GetUserProfileResponse.UserInfo.CertificationInfo {
        return Contact_V2_GetUserProfileResponse.UserInfo.CertificationInfo()
    }
    public var hasTenantCertification_p: Bool { return false }
    public var isTenantCertification: Bool { return false }
    public var isRegistered: Bool { return false }
    public var friendStatus: Contact_V2_GetUserProfileResponse.UserInfo.FriendStatus {
        return Contact_V2_GetUserProfileResponse.UserInfo.FriendStatus()
    }
    public var tenantName: Contact_V2_GetUserProfileResponse.I18nVal {
        return Contact_V2_GetUserProfileResponse.I18nVal()
    }
    public var tenantNameStatus: Basic_V1_TenantNameStatus {
        return Basic_V1_TenantNameStatus()
    }
    public var isResigned: Bool { return false }
    public var isSpecialFocus: Bool { return false }
    public var hasGender: Bool { return false }
    public var gender: Contact_V2_GetUserProfileResponse.UserInfo.Gender {
        return Contact_V2_GetUserProfileResponse.UserInfo.Gender()
    }
    public var isFrozen: Bool { return false }
    public var hasDoNotDisturbEndTime: Bool { return false }
    public var doNotDisturbEndTime: Int64 { return 0 }
    public var hasWorkStatus: Bool { return false }
    public var workStatus: Basic_V1_WorkStatus {
        return Basic_V1_WorkStatus()
    }
    public var hasShareInfo: Bool { return false }
    public var shareInfo: Contact_V2_GetUserProfileResponse.ShareInfo {
        return Contact_V2_GetUserProfileResponse.ShareInfo()
    }
    public var leaderID: String { return "" }
    public var contactToken: String { return "" }
    public var customTagFields: [Contact_V2_GetUserProfileResponse.Field] { return [] }
    public var genderPronouns: String { return "" }
    public var metaUnitDescription: Contact_V2_GetUserProfileResponse.I18nVal {
        return Contact_V2_GetUserProfileResponse.I18nVal()
    }
    public var tenantID: String { return "" }
    public var blockStatus: Contact_V2_GetUserProfileResponse.UserInfo.BlockStatus {
        return Contact_V2_GetUserProfileResponse.UserInfo.BlockStatus()
    }
    public var isBlocked: Bool { return false }
    public var canBlock: Bool { return false }
    public var hasApplyCommunication: Bool { return false }
    public var applyCommunication: Contact_V2_GetUserProfileResponse.UserInfo.ApplyCommunication {
        return Contact_V2_GetUserProfileResponse.UserInfo.ApplyCommunication()
    }
    public var contactApplicationID: Int64 { return 0 }
    public var chatterStatus: [Basic_V1_Chatter.ChatterCustomStatus] { return [] }
    public var hideAddConnectButton: Bool { return false }
}

