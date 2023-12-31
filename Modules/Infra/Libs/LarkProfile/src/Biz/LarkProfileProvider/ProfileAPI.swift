//
//  ProfileAPI.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/4.
//

import ByteWebImage
import Foundation
import LarkRustClient
import RustPB
import ServerPB
import RxSwift
import LarkLocalizations

public typealias LarkUserProfile = RustPB.Contact_V2_GetUserProfileResponse
public typealias I18nVal = Contact_V2_GetUserProfileResponse.I18nVal
public typealias ServerI18n = ServerPB.ServerPB_Users_I18nVal
public typealias LarkUserProfileSource = RustPB.Basic_V1_ContactSource
public typealias LarkUserProfilChatSource = RustPB.Im_V1_CreateP2PChatSource
public typealias LarkUserProfilTab = RustPB.Contact_V2_GetUserProfileResponse.TabInfo
public typealias LarkUserProfilMedal = RustPB.Contact_V2_GetUserProfileResponse.Medal
public typealias LarkMedalItem = ServerPB.ServerPB_Medal_MedalItem
public typealias ProfileMemoDescription = RustPB.Contact_V2_GetUserProfileResponse.MemoDescription
public typealias SectionItem = ServerPB.ServerPB_Users_SectionItem
public typealias TabSection = ServerPB.ServerPB_Users_TabSection
public typealias SectionClusterTab = ServerPB.ServerPB_Users_SectionClusterTab
public typealias ProfileScene = ServerPB.ServerPB_Users_PullUserProfileV2Request.Scene
public typealias ProfileSource = ServerPB.ServerPB_Users_PullUserProfileV2Request.Source

public enum LarkUserProfileFromWhere: String, Codable {
    case none
    /// LarkSearch、添加朋友搜索界面
    case search
    /// 邀请朋友
    case invitation
    /// from chat
    case chat
    /// from thread
    case thread
    /// 机器人已被添加到群，支持删除
    case groupBotToRemove
    /// 机器人未被添加到群，支持添加
    case groupBotToAdd
}

public enum LarkUserProfileLinkType {
    case unknown, calendar, profile, mail, h5, microApp

    public static func getLinkType(url: String) -> LarkUserProfileLinkType {
        /// profile 前缀为：lark://client/profile
        var pattern = "lark://client/profile"
        if url.hasPrefix(pattern) {
            return .profile
        }

        /// 日历 前缀为：lark://client/calendar
        pattern = "lark://client/calendar"
        if url.hasPrefix(pattern) {
            return .calendar
        }

        /// 邮箱 前缀为：mailto:
        pattern = "mailto:"
        if url.hasPrefix(pattern) {
            return .mail
        }

        /// 小程序 前缀为：sslocal://microapp
        pattern = "sslocal://microapp"
        if url.hasPrefix(pattern) {
            return .microApp
        }

        /// h5为 http或者https
        pattern = "^http(s)?\\://([^.]+\\.)?/?([^/]+/)*"
        do {
            let urlRegexp = (try NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))
            let range = NSRange(location: 0, length: url.count)
            if !urlRegexp.matches(in: url, options: [], range: range).isEmpty {
                return .h5
            }
        } catch {
            return .unknown
        }

        return .unknown
    }
}

public protocol LarkProfileAPI {
    func fetchUserProfileInfomation(userId: String,
                                    contactToken: String,
                                    chatId: String,
                                    sourceType: RustPB.Basic_V1_ContactSource) -> Observable<LarkUserProfile>

    func getUserProfileInfomation(userId: String,
                                  contactToken: String,
                                  chatId: String,
                                  sourceType: RustPB.Basic_V1_ContactSource) -> Observable<LarkUserProfile>

    func updateTopImage(key: String) -> Observable<Void>

    func getMedalListBy(userID: String) -> Observable<ServerPB.ServerPB_Medal_ListUserMedalsResponse>

    func getCurrentMedalBy(userID: String) -> Observable<ServerPB.ServerPB_Medal_GetUserTakingMedalResponse>

    func getMedalDetailBy(userID: String,
                          medalID: String,
                          grantID: String) -> Observable<ServerPB.ServerPB_Medal_GetUserMedalDetailResponse>

    func getSectionClusterTab(userID: String,
                              contactToken: String,
                              scene: ProfileScene,
                              source: ProfileSource,
                              sectionKeys: [String]) -> Observable<ServerPB.ServerPB_Users_PullSectionClusterTabResponse>

    func setMedalBy(userID: String,
                    medalID: String,
                    grantID: String,
                    isTaking: Bool) -> Observable<ServerPB.ServerPB_Medal_SetUserMedalResponse>

    func setUserMemoBy(userID: String, alias: String, memoText: String, memoPicKey: String) -> Observable<Void>
    /// 发送沟通权限申请
    func sendApplyCommunicationApplicationBy(userID: String, reason: String) -> Observable<Void>
}

public final class LarkProfileAPIImp: LarkProfileAPI {
    public var client: RustService

    public init(client: RustService) {
        self.client = client
    }

    public func fetchUserProfileInfomation(userId: String,
                                           contactToken: String,
                                           chatId: String,
                                           sourceType: Basic_V1_ContactSource) -> Observable<LarkUserProfile> {
        var request = RustPB.Contact_V2_GetUserProfileRequest()
        if contactToken.isEmpty {
            request.userID = userId
            request.chatID = chatId
            request.scene = chatId.isEmpty ? .byUserID  : .inChat
        } else {
            request.contactToken = contactToken
            request.scene = .byContactToken
        }
        request.source = sourceType
        request.useNewLayout = true
        request.isSupportOneWayRelation = true
        request.syncDataStrategy = .forceServer
        return client.sendAsyncRequest(request)
    }

    public func getUserProfileInfomation(userId: String,
                                         contactToken: String,
                                         chatId: String,
                                         sourceType: Basic_V1_ContactSource) -> Observable<LarkUserProfile> {
        var request = RustPB.Contact_V2_GetUserProfileRequest()
        if contactToken.isEmpty {
            request.userID = userId
            request.chatID = chatId
            request.scene = chatId.isEmpty ? .byUserID  : .inChat
        } else {
            request.contactToken = contactToken
            request.scene = .byContactToken
        }
        request.source = sourceType
        request.isSupportOneWayRelation = true
        request.syncDataStrategy = .local
        request.useNewLayout = true
        return client.sendAsyncRequest(request)
    }

    public func updateTopImage(key: String) -> Observable<Void> {
        var request = RustPB.Contact_V2_PatchSelfUserProfileRequest()
        request.topImageKey = key
        request.updateProperties = [RustPB.Contact_V2_PatchSelfUserProfileRequest.SelfUserProfileUpdateProperty.topImage]
        return client.sendAsyncRequest(request)
    }

    public func getMedalListBy(userID: String) -> Observable<ServerPB.ServerPB_Medal_ListUserMedalsResponse> {
        var request = ServerPB.ServerPB_Medal_ListUserMedalsRequest()
        request.userID = userID
        return client.sendPassThroughAsyncRequest(request, serCommand: .getMedalList)
    }

    public func getCurrentMedalBy(userID: String) -> Observable<ServerPB.ServerPB_Medal_GetUserTakingMedalResponse> {
        var request = ServerPB.ServerPB_Medal_GetUserTakingMedalRequest()
        request.userID = userID
        return client.sendPassThroughAsyncRequest(request, serCommand: .getUserTakingMedal)
    }

    public func getMedalDetailBy(userID: String, medalID: String, grantID: String) -> Observable<ServerPB.ServerPB_Medal_GetUserMedalDetailResponse> {
        var request = ServerPB.ServerPB_Medal_GetUserMedalDetailRequest()
        request.userID = userID
        request.grantID = grantID
        request.medalID = medalID
        return client.sendPassThroughAsyncRequest(request, serCommand: .getMedalDetail)
    }

    public func setMedalBy(userID: String,
                           medalID: String,
                           grantID: String,
                           isTaking: Bool) -> Observable<ServerPB.ServerPB_Medal_SetUserMedalResponse> {
        var request = ServerPB.ServerPB_Medal_SetUserMedalRequest()
        request.userID = userID
        request.grantID = grantID
        request.medalID = medalID
        request.action = isTaking ? .take : .takeoff
        return client.sendPassThroughAsyncRequest(request, serCommand: .setMedal)
    }

    public func setUserMemoBy(userID: String,
                              alias: String,
                              memoText: String,
                              memoPicKey: String) -> Observable<Void> {
        var request = ServerPB.ServerPB_Users_PatchUserMemoRequest()
        request.targetUserID = userID
        request.alias = alias
        request.memoText = memoText
        request.memoPictureKey = memoPicKey
        return client.sendPassThroughAsyncRequest(request, serCommand: .patchUserMemo)
    }

    public func getSectionClusterTab(userID: String,
                                     contactToken: String,
                                     scene: ProfileScene,
                                     source: ProfileSource,
                                     sectionKeys: [String]) -> Observable<ServerPB.ServerPB_Users_PullSectionClusterTabResponse> {
        var request = ServerPB.ServerPB_Users_PullSectionClusterTabRequest()
        request.userID = userID
        request.contactToken = contactToken
        request.scene = scene
        request.source = source
        request.sectionTabKeys = sectionKeys
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullUserProfileSectionTab)
    }

    public func sendApplyCommunicationApplicationBy(userID: String,
                                               reason: String) -> Observable<Void> {
        var request = ServerPB.ServerPB_Messages_ApplyP2PChatPermissionRequest()
        request.toUserID = userID
        request.applyDescription = reason
        return client.sendPassThroughAsyncRequest(request, serCommand: .messageApplyP2PChatPermission)
    }
}

extension ServerI18n {
    public func getString() -> String {
        let i18NVal = self.i18NVals
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let result = i18NVal[currentLocalizations],
            !result.isEmpty {
            return result
        } else {
            return self.defaultVal
        }
    }
}

extension I18nVal {
    public func getString() -> String {
        let i18NVal = self.i18NVals
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let result = i18NVal[currentLocalizations],
            !result.isEmpty {
            return result
        } else {
            return self.defaultVal
        }
    }
}

extension ServerPB.ServerPB_Medal_I18nVal {
    public func getString() -> String {
        let i18NVal = self.i18NVals
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let result = i18NVal[currentLocalizations],
            !result.isEmpty {
            return result
        } else {
            return self.defaultVal
        }
    }
}

extension LarkUserProfile.UserInfo.FriendStatus {
    func getApplyStatus() -> ProfileRelationship {
        switch self {
        case .none:
            return .apply
        case .forward:
            return .applying
        case .reverse:
            return .accept
        case .unknown, .double:
            return .none
        @unknown default:
            assert(false, "new value")
            return .none
        }
    }
}

extension LarkUserProfile.UserInfo.ApplyCommunicationStatus {
    func getApplyCommunicationStatus() -> ProfileCommunicationPermission {
        switch self {
        case .applyUnknown:
            return .unown
        case .pass:
            return .agreed
        case .canApply:
            return .apply
        case .applyingCannotApply:
            return .applying
        case .applyingCanApply:
            return .applied
        case .canNotApply:
            return .inelligible
        @unknown default:
            assert(false, "new value")
            return .unown
        }
    }
}
