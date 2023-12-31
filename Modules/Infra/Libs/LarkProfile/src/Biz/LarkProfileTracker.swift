//
//  LarkProfileTracker.swift
//  LarkProfileTracker
//
//  Created by 姚启灏 on 2021/8/30.
//

import Foundation
import LKCommonsTracker
import Homeric
import SwiftProtobuf
import LarkSDKInterface
import LarkContainer
import ThreadSafeDataStructure

/// 新埋点
public struct LarkProfileTracker {
//    @ScopedInjectedLazy var serverNTPTimeService: ServerNTPTimeService?

    public static var userMap: SafeDictionary<String, [AnyHashable: Any]> = [:] + .readWriteLock

    private var userProfile: LarkUserProfile
    private var contactType: String

    private var userInfo: LarkUserProfile.UserInfo {
        return userProfile.userInfo
    }

    var blockStatus: LarkUserProfile.UserInfo.BlockStatus {
        return userProfile.userInfo.blockStatus
    }

    var isBlocked: Bool {
        return self.blockStatus == .bForward || self.blockStatus == .bDouble || self.userProfile.userInfo.isBlocked
    }
    let userResolver: LarkContainer.UserResolver
    public init(resolver: LarkContainer.UserResolver, userProfile: LarkUserProfile, contactType: String) {
        self.userResolver = resolver
        self.userProfile = userProfile
        self.contactType = contactType

        self.updateUserProfile(userProfile, contactType: contactType)
    }

    public mutating func updateUserProfile(_ userProfile: LarkUserProfile, contactType: String) {
        self.userProfile = userProfile
        self.contactType = contactType

        let hasVerification = userInfo.hasTenantCertification_p
        && !userInfo.tenantName.getString().isEmpty ? "true" : "false"
        let userID = userProfile.userInfo.userID
        let isVerified = userInfo.hasTenantCertification_p
        && userInfo.isTenantCertification ? "true" : "false"

        var params: [AnyHashable: Any] = [:]

        params["contact_type"] = contactType
        params["verification"] = hasVerification
        params["to_user_id"] = userID
        params["is_verified"] = isVerified
        LarkProfileTracker.userMap[userProfile.userInfo.userID] = params
    }

    public mutating func trackMainView(enableMedal: Bool) {
        var hasCustom = "false"
        var hasAlias = "false"
        var hasMoments = "false"
        let (genderTag, hasOnLeave, hasNoDisturb, accountStatus) = getUserInfoStatus()

        if !userInfo.customTagFields.isEmpty {
            hasCustom = "true"
        }

        var containModules: String = ""
        for field in userProfile.fieldOrders {
            if containModules.isEmpty {
                containModules += field.key
            } else {
                containModules += ", \(field.key)"
            }
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true
            switch field.fieldType {
            case .cAlias:
                if let text = try? LarkUserProfile.Text(jsonString: field.jsonFieldVal, options: options),
                   !text.text.i18NVals.isEmpty || !text.text.defaultVal.isEmpty {
                    hasAlias = "true"
                }
            @unknown default:
                continue
            }
        }

        for cta in userProfile.ctaOrders {
            if containModules.isEmpty {
                containModules += cta.key
            } else {
                containModules += ", \(cta.key)"
            }
        }

        var tabs = ""
        for tab in userProfile.tabOrders {
            if tabs.isEmpty {
                tabs += tab.key
            } else {
                tabs += ", \(tab.key)"
            }
            switch tab.tabType {
            case .fCommunity:
                hasMoments = "true"
                break
            @unknown default:
                continue
            }
        }

        let isPrivacy = userProfile.hasPermission ? "false" : "true"
        let userID = userProfile.userInfo.userID
        let certificateStatus = userInfo.certificationInfo.certificateStatus
        let hasVerification = userInfo.certificationInfo.isShowCertSign && (certificateStatus != .teamCertificated) ? "true" : "false"
        let isVerified = (certificateStatus == .certificated) ? "true" : "false"
        let verifiedStatus = userInfo.certificationInfo.hasCertificateStatus ? "\(certificateStatus.rawValue)" : "0"
        let length = getLength(forText: userInfo.description_p.text)

        var params: [AnyHashable: Any] = [:]
        params["gender_tag"] = genderTag
        params["is_user_on_leave_tag_shown"] = hasOnLeave
        params["is_user_no_disturb_tag_shown"] = hasNoDisturb
        params["account_status_tag"] = accountStatus
        params["is_custom_image_field_shown"] = hasCustom
        params["is_alias_filled"] = hasAlias
        params["is_moments_tab_shown"] = hasMoments
        params["friend_conversion"] = getFriendConversion()
        params["contact_type"] = contactType
        params["contain_module"] = containModules
        params["to_user_id"] = userID
        params["signature_length"] = length
        params["is_privacy_set"] = userProfile.permission.canNotFind ? "true" : "false"
        params["is_avatar_medal_shown"] = userProfile.userInfo.avatarMedal.key.isEmpty ? "false" : "true"
        params["is_medal_wall_entry_shown"] = enableMedal ? "true" : "false"
        params["tab"] = tabs
        params["verification"] = hasVerification
        params["is_verified"] = isVerified
        params["verified_status"] = verifiedStatus

        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    func getUserInfoStatus() -> (String, String, String, String) {
        var genderTag = "none"
        var hasOnLeave = "false"
        var hasNoDisturb = "false"
        var accountStatus = "none"
        if userInfo.isResigned {
            accountStatus = "resigned"
        } else {
            if userInfo.hasGender {
                genderTag = userInfo.gender == .woman ? "female" : "male"
            }
            if isBlocked {
                accountStatus = "blocked"
            }

            if userInfo.isFrozen {
                accountStatus = "use_suspend"
            } else {
                let serverNTPTimeService = try? self.userResolver.resolve(assert: ServerNTPTimeService.self)
                if userInfo.hasDoNotDisturbEndTime,
                   serverNTPTimeService?.afterThatServerTime(time: userInfo.doNotDisturbEndTime) == true {
                    hasNoDisturb = "true"
                }

                if userInfo.hasWorkStatus {
                    hasOnLeave = "true"
                }
            }
        }
        return (genderTag, hasOnLeave, hasNoDisturb, accountStatus)
    }

    func getFriendConversion() -> String {
        var friendConversion = "none"
        if userProfile.userInfo.isRegistered {
            switch userProfile.userInfo.friendStatus {
            case .none:
                friendConversion = "invite"
            case .forward:
                friendConversion = "send"
            case .reverse:
                friendConversion = "agree"
            case .unknown, .double:
                friendConversion = "none"
            @unknown default:
                friendConversion = "none"
            }
        }
        return friendConversion
    }

    public func trackMainClick(_ click: String, extra: [AnyHashable: Any] = [:]) {
        let certificateStatus = userInfo.certificationInfo.certificateStatus
        let hasVerification = userInfo.certificationInfo.isShowCertSign && (certificateStatus != .teamCertificated) ? "true" : "false"
        let isVerified = (certificateStatus == .certificated) ? "true" : "false"
        let verifiedStatus = userInfo.certificationInfo.hasCertificateStatus ? "\(certificateStatus.rawValue)" : "0"
        var params: [AnyHashable: Any] = [:]
        params["click"] = click
        params["contact_type"] = contactType
        params["to_user_id"] = userProfile.userInfo.userID
        params["verification"] = hasVerification
        params["is_verified"] = isVerified
        params["verified_status"] = verifiedStatus
        params += extra
        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    public func trackContact() {
        let hasVerification = userInfo.hasTenantCertification_p && !userInfo.tenantName.getString().isEmpty ? "true" : "false"
        let userID = userProfile.userInfo.userID
        let isVerified = userInfo.hasTenantCertification_p
        && userInfo.isTenantCertification ? "true" : "false"

        var params: [AnyHashable: Any] = [:]
        params["to_user_id"] = userID
        params["is_verified"] = isVerified
        params["verification"] = hasVerification

        Tracker.post(TeaEvent(Homeric.PROFILE_CONTACT_REQUEST_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    public func trackContactClick(hasReason: Bool) {
        let hasVerification = userInfo.hasTenantCertification_p && !userInfo.tenantName.getString().isEmpty ? "true" : "false"
        let userID = userProfile.userInfo.userID
        let isVerified = userInfo.hasTenantCertification_p
        && userInfo.isTenantCertification ? "true" : "false"

        var params: [AnyHashable: Any] = [:]
        params["to_user_id"] = userID
        params["is_verified"] = isVerified
        params["verification"] = hasVerification
        params["click"] = "send"
        params["is_reason_apply"] = hasReason ? "true" : "false"

        Tracker.post(TeaEvent(Homeric.PROFILE_CONTACT_REQUEST_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    public func trackVoiceCallView() {
        var params: [AnyHashable: Any] = [:]
        params["to_user_id"] = userProfile.userInfo.userID
        params["contact_type"] = contactType

        Tracker.post(TeaEvent(Homeric.PROFILE_VOICE_CALL_SELECT_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    public func trackVoiceCallViewClick(isPhone: Bool) {
        var params: [AnyHashable: Any] = [:]
        params["to_user_id"] = userProfile.userInfo.userID
        params["contact_type"] = contactType
        params["click"] = isPhone ? "phone_call" : "voice_call"
        params["target"] = isPhone ? "none" : "vc_meeting_calling_view"

        Tracker.post(TeaEvent(Homeric.PROFILE_VOICE_CALL_SELECT_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    public func trackBackgroundMainView() {
        var params: [AnyHashable: Any] = [:]
        params["to_user_id"] = userProfile.userInfo.userID
        params["contact_type"] = contactType

        Tracker.post(TeaEvent(Homeric.PROFILE_BACKGROUND_MAIN_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    public func trackBackgroundMainClick() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "change"
        params["target"] = "profile_background_change_view"

        Tracker.post(TeaEvent(Homeric.PROFILE_BACKGROUND_MAIN_CLICK, params: params))
    }

    public func trackBackgroundChangeView() {

        Tracker.post(TeaEvent(Homeric.PROFILE_BACKGROUND_CHANGE_VIEW))
    }

    public func trackBackgroundChangeClick(_ click: String, target: String) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = click
        params["target"] = target

        Tracker.post(TeaEvent(Homeric.PROFILE_BACKGROUND_CHANGE_CLICK, params: params))
    }

    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }

    /// 勋章 目标用户 userId 的加密值
    public func trackerAvatarActionSheetToUserId() {
        var params: [AnyHashable: Any] = [:]
        params["to_user_id"] = userProfile.userInfo.userID
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_ACTION_SHEET_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    /// 勋章 在查看头像查看勋章详情的动作面板的动作
    public func trackerAvatarActionSheetClick(_ click: String, target: String) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = click
        params["target"] = target
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_ACTION_SHEET_CLICK, params: params))
    }

    /// 「勋章墙」页面的展示
    public static func trackerAvatarMedalWallShow(_ medals: [LarkMedalItem], extra: [AnyHashable: Any] = [:]) {
        var validMedalCount = 0
        var invalidMedalCount = 0
        var isMedalPutOn = "false"
        for medal in medals {
            switch medal.status {
            case .valid:
                validMedalCount += 1
            case .taking:
                isMedalPutOn = "true"
            case .invalid:
                invalidMedalCount += 1
            @unknown default:
                continue
            }
        }
        var params: [AnyHashable: Any] = [:]
        params["valid_medal_count"] = validMedalCount
        params["invalid_medal_count"] = invalidMedalCount
        params["is_medal_put_on"] = isMedalPutOn
        params += extra
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_MEDAL_WALL_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    /// 在「勋章墙」页，发生动作事件
    public static func trackerAvatarMedalWallClick(_ click: String, extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = click
        params += extra
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_MEDAL_WALL_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    /// 「勋章确定佩戴」页面的展示
    public static func trackAvatarMedalPutOnConfirmView(medalID: String) {
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_MEDAL_PUT_ON_CONFIRM_VIEW, params: ["medal_id": medalID]))
    }

    /// 在「勋章确定佩戴」页，发生动作事件
    public static func trackAvatarMedalPutOnConfirmClick(_ click: String, extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = click
        params += extra
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_MEDAL_PUT_ON_CONFIRM_CLICK, params: params))
    }

    /// 「勋章详情」页面的展示
    public static func trackAvatarMedalDetailView(_ isValid: Bool, extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["is_valid"] = isValid ? "true" : "false"
        params += extra
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_MEDAL_DETAIL_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    /// 在「勋章详情」页，发生动作事件
    public static func trackAvatarMedalDetailClick(extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "back"
        params["target"] = "profile_avatar_medal_wall_view"
        params += extra
        Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_MEDAL_DETAIL_CLICK, params: params))
    }
}
