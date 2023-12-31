//
//  CollaboratorBlockStatusManager.swift
//  SKCommon
//
//  Created by liweiye on 2020/10/13.
//  swiftlint:disable file_length

import Foundation
import UniverseDesignToast
import SwiftyJSON
import SKFoundation
import SKResource
import LarkLocalizations
import UniverseDesignDialog

/// 被cac管控的邀请协作者结果
public enum InviteResultsByCacBlocked {
    case noFail ///cac管控没有影响协作者添加结果
    case partFail ///cac管控导致的失败部分协作者添加失败
    case allFail  ///cac管控导致没有协作者添加失败
}

public protocol CollaboratorBlockStatusManagerDelegate: AnyObject {
    func showInviteFolderCollaboratorCacDialog(animated: Bool, completion: (() -> Void)?)
}

// 处理协作者之间的屏蔽关系
public final class CollaboratorBlockStatusManager {

    public enum RequestType {
        case sendLink
        case askOwner
        case requestPermissionForFolder
        case requestPermissionForBiz
        case inviteCollaboratorsForFolder
        case inviteCollaboratorsForBiz
    }

    public enum ResponseCode: Int {
        case success = 0                        // 成功
        case fail = 1                           // 失败
        case failForAdministratorCloseShare = 10004     //邀请失败，管理员关闭了外部共享
        case failForOwnerCloseShare = 10005     //邀请失败，所有者关闭了外部共享
        case executivesBlock = 10015            // 高管屏蔽
        case activeBlock = 10021                // 主动屏蔽
        case passiveBlock = 10022               // 被动屏蔽
        case privacyBlock = 10023               // 隐私设置原因屏蔽
        case partialFail = 10024                // 下游原因部分添加失败
        case countLimit = 10025                 // 达到每日授权次数上限
        case emailCountLimit = 14001                 // 邮箱协作者达到每日授权次数上限
        case phoneLimit = 10026                 // 手机号邀请达到每日上限
        case ownerNotInGroup = 10027            // ask owner分享文档给owner不在的群
        case dataUpgradeLocked = 10040          //数据迁移期间，禁止写操作
        case notInPartnerTenant = 10043          // 非关联组织的外部用户邀请失败
        case cacBlocked = 2_002                   //cac管控
    }

    let requestType: RequestType
    private var blockUserMap: [String: [String]] = [:]
    private var userInfo: [String: Any] = [:]
    private var blockUserInfoMap: [String: [Any]] = [:]
    private var failCodeCollaboratorMap: [String: [Any]] = [:]
    // 文档/文件夹默认授权的上限为20次
    private var limitCount = 20
    // 打点类，可选是因为从新建文件夹路径进来不需要
    let statistics: CollaboratorStatistics?
    let fromView: UIView?
    let fromVC: UIViewController?
    weak var delegate: CollaboratorBlockStatusManagerDelegate?


    public init(requestType: RequestType,
                fromVC: UIViewController? = nil,
                fromView: UIView?,
         statistics: CollaboratorStatistics?) {
        self.requestType = requestType
        self.fromVC = fromVC
        self.fromView = fromView
        self.statistics = statistics
    }

    private func parseBlockUsersCore(code: ResponseCode, userIds: [String]) {
        if code == .emailCountLimit {
            blockUserInfoMap[String(code.rawValue)] = [userIds]
            return 
        }
        for userId in userIds {
            if let user = userInfo[userId] {
                if var userInfos = blockUserInfoMap[String(code.rawValue)] {
                    userInfos.append(user)
                    blockUserInfoMap[String(code.rawValue)] = userInfos
                } else {
                    blockUserInfoMap[String(code.rawValue)] = [user]
                }
            }
        }
    }

    // 兜底文案
    func getDefaultFailedMessage() -> String {
        switch self.requestType {
        case .askOwner:
            return BundleI18n.SKResource.Doc_Permission_SendApplyFailed
        case .sendLink:
            return BundleI18n.SKResource.Doc_Permission_SendFailed
        case .requestPermissionForBiz, .requestPermissionForFolder:
            return BundleI18n.SKResource.Doc_Permission_ApplyFailed
        case .inviteCollaboratorsForBiz, .inviteCollaboratorsForFolder:
            return BundleI18n.SKResource.Doc_Share_AddCollaboratorFailed
        }
    }

    func getAllCollaboratorNames(users: Any) -> String? {
        let json = JSON(users).arrayValue
        if json.isEmpty { return nil }

        let seperator = LanguageManager.currentLanguage == .en_US ? "," : "、"

        return json.map { (user) -> String in
            return user["name"].stringValue
        }.reduce("") { (result, name) -> String in
            return "\(result)\(seperator)\(name)"
        }.mySubString(from: 1)
    }

    // 处理我和Owner之间屏蔽关系
    private func getOwnerBlockedMessage(code: Int, ownerName: String, location: AuthErrorLocation) -> String? {
        //成功
        if code == ResponseCode.success.rawValue {
            return nil
        }
        // 主动屏蔽
        if code == ResponseCode.activeBlock.rawValue {
            return getBlockedOwnerMessage(ownerName: ownerName, location: location)
        }
        // 被动屏蔽
        if code == ResponseCode.passiveBlock.rawValue {
            return getBlockedByOwnerMessage(ownerName: ownerName, location: location)
        }
        // 隐私设置
        if code == ResponseCode.privacyBlock.rawValue {
            return getOwnerPrivacySettingMessage(ownerName: ownerName, location: location)
        }
        // 给文档owner发送消息达到上限
        if code == ResponseCode.countLimit.rawValue {
            return getOwnerCountsLimitsSingleMessage(ownerName: ownerName, location: location)
        }
        // 高管屏蔽
        if code == ResponseCode.executivesBlock.rawValue {
            return getOwnerIsExecutivesMessage(ownerName: ownerName, location: location)
        }

        // 升级提醒
        if code == ResponseCode.dataUpgradeLocked.rawValue {
            return getDataUpgradeLockedMessage(ownerName: ownerName, location: location)
        }
        return nil
    }

    private func getInviteCollaboratorsForBizMessage(code: Int, ownerName: String, location: AuthErrorLocation) -> String? {
        if code == ResponseCode.failForAdministratorCloseShare.rawValue {
            return getInviteFailAdministratorClossShareMessage(ownerName: ownerName, location: location)
        }
        if code == ResponseCode.failForOwnerCloseShare.rawValue {
            return getInviteFailOwnerClossShareMessage(ownerName: ownerName, location: location)
        }
        return nil
    }

    // 处理我和协作者或者owner和协作者之间的屏蔽关系
    public func getCollaboratorsBlockedMessage(json: JSON, ownerName: String?, location: AuthErrorLocation, isFolder: Bool) -> String? {
        parseBlockInfo(json: json, location: location)
        return getCollaboratorsBlockedCoreMessage(ownerName: ownerName, location: location, isFolder: isFolder)
    }

    private func parseBlockInfo(json: JSON, location: AuthErrorLocation) {
        // 解析老的not_notify_users接口
        if let notNotifyUsers = json["data"]["not_notify_users"].arrayObject {
            blockUserInfoMap[String(ResponseCode.executivesBlock.rawValue)] = notNotifyUsers
        }
        // 解析邀请授权的上限次数
        if let limitCount = json["data"]["limit_num"].int {
            self.limitCount = limitCount
        }
        var blockUserMap: [String: [String]] = [:]
        if let collaboratorMapFromJSON = json["data"]["failCode_collaborator_map"].dictionaryObject as? [String: [String]] {
            blockUserMap = collaboratorMapFromJSON
        } else if let mapFromJSON = json["data"]["block_user_map"].dictionaryObject as? [String: [String]] {
            blockUserMap = mapFromJSON
        } else if let folderMapFromJSON = json["data"]["fail_map"].dictionary {
            blockUserMap = [:]
            folderMapFromJSON.forEach { userID, value in
                let code: String
                if let codeString = value.string {
                    code = codeString
                } else if let codeNumber = value.int {
                    code = String(codeNumber)
                } else {
                    return
                }
                var userIDs = blockUserMap[code] ?? []
                userIDs.append(userID)
                blockUserMap[code] = userIDs
            }
        }
        if !blockUserMap.isEmpty,
           let userMap = json["data"]["user_map"].dictionaryObject {
            self.blockUserMap = blockUserMap
            self.userInfo = userMap
            for (key, value) in self.blockUserMap {
                let codeValue = Int(key) ?? 1
                let code = ResponseCode(rawValue: codeValue) ?? .fail
                // 文档/文件夹邀请协作者不需要解析内部的高管数据
                if location == .invitedCollaborateAfter && code == .executivesBlock { continue }
                parseBlockUsersCore(code: code, userIds: value)
            }
        }
    }

    private func getCollaboratorsBlockedCoreMessage(ownerName: String?, location: AuthErrorLocation, isFolder: Bool) -> String? {
        /// cac 管控比较特殊，由 delegate 负责 toast
        if blockUserMap.keys.contains(String(ResponseCode.cacBlocked.rawValue)) {
            showInviteFailCacBlocked(ownerName: "", location: location)
            return nil
        } else {
            return getCollaboratorsBlockedMessage(ownerName: ownerName, location: location, isFolder: isFolder)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private func getCollaboratorsBlockedMessage(ownerName: String?, location: AuthErrorLocation, isFolder: Bool) -> String? {
        // 按照优先级处理
        /// admin关闭对外分享
        if blockUserMap.keys.contains(String(ResponseCode.failForAdministratorCloseShare.rawValue)) {
            return getInviteFailAdministratorClossShareMessage(ownerName: "", location: location)
        }
        /// owner关闭对外分享
        if blockUserMap.keys.contains(String(ResponseCode.failForOwnerCloseShare.rawValue)) {
            return getInviteFailOwnerClossShareMessage(ownerName: "", location: location)
        }
        if let activeBlockUsers = blockUserInfoMap[String(ResponseCode.activeBlock.rawValue)], !activeBlockUsers.isEmpty {
            guard let names = getAllCollaboratorNames(users: activeBlockUsers) else { return nil }
            if let ownerName = ownerName {
                return getOwnerBlockedUsersMessage(ownerName: ownerName, userNames: names, location: location)
            } else {
                report(reason: .block, location: location)
                return getIBlockedUsersMessage(userNames: names)
            }
        }
        if let passiveBlockUsers = blockUserInfoMap[String(ResponseCode.passiveBlock.rawValue)], !passiveBlockUsers.isEmpty {
            guard let names = getAllCollaboratorNames(users: passiveBlockUsers) else { return nil }
            if let ownerName = ownerName {
                return getOwnerBlockedByUsersMessage(ownerName: ownerName, userNames: names, location: location)
            } else {
                report(reason: .blocked, location: location)
                return getIBlockedByUsersMessage(userNames: names)
            }
        }
        if let privacyBlockUsers = blockUserInfoMap[String(ResponseCode.privacyBlock.rawValue)], !privacyBlockUsers.isEmpty {
            guard let names = getAllCollaboratorNames(users: privacyBlockUsers) else { return nil }
            if requestType == .askOwner {
                return getUsersPrivacySettingMessage(userNames: names, location: location)
            } else {
                report(reason: .privacySetting, location: location)
                return getOtherUsersPrivacySettingMessage(userNames: names)
            }
        }
        if let countLimitUsers = blockUserInfoMap[String(ResponseCode.countLimit.rawValue)], !countLimitUsers.isEmpty {
            guard let names = getAllCollaboratorNames(users: countLimitUsers) else { return nil }
            if let ownerName = ownerName {
                return getUsersCountsLimitsSingleMessage(ownerName: ownerName, userNames: names, location: location)
            } else {
                report(reason: .moreThenLimited, location: location)
                return getOtherUsersCountsLimitsSingleMessage(userNames: names)
            }
        }
        if let emailCountLimitUsers = blockUserInfoMap[String(ResponseCode.emailCountLimit.rawValue)], !emailCountLimitUsers.isEmpty {
            report(reason: .moreThenLimited, location: location)
            return getEmailCountsLimitsSingleMessage(location: location)
        }
        if let phoneLimitUsers = blockUserInfoMap[String(ResponseCode.phoneLimit.rawValue)], !phoneLimitUsers.isEmpty {
            guard let names = getAllCollaboratorNames(users: phoneLimitUsers) else { return nil }
            if ownerName != nil {
                return nil
            } else {
                report(reason: .phoneInviteLimited, location: location)
                return getOtherUsersPhoneLimitsSingleMessage(userNames: names)
            }
        }
        if let executivesUsers = blockUserInfoMap[String(ResponseCode.executivesBlock.rawValue)], !executivesUsers.isEmpty {
            guard let names = getAllCollaboratorNames(users: executivesUsers) else { return nil }
            if ownerName != nil {
                return getUserIsExecutivesMessage(userNames: names, location: location)
            } else {

                report(reason: .adminSetting, location: location)
                return getOtherUsersIsExecutivesMessage(userNames: names)
            }
        }
        if let executivesUsers = blockUserInfoMap[String(ResponseCode.notInPartnerTenant.rawValue)], !executivesUsers.isEmpty {
            guard let names = getAllCollaboratorNames(users: executivesUsers) else { return nil }
            return getOtherUsersNotInPartnerTenantMessage(userNames: names, isFolder: isFolder)
        }
        return getDefaultFailedMessage()
    }
}

// Request Permission
extension CollaboratorBlockStatusManager {
    public func showRequestPermissionForBizFaliedToast(_ json: JSON, ownerName: String) {
        guard let codeValue = json["code"].int else {
            DocsLogger.info("parseAskOwner code is not exist")
            return
        }
        DocsLogger.info("code = \(codeValue)")
        let msg = getOwnerBlockedMessage(code: codeValue, ownerName: ownerName, location: .applyPermission)
        showToast(text: msg, type: .failure)
    }
}

// Invite Collaborators
extension CollaboratorBlockStatusManager {

    public func showInviteCollaboratorsForFolderFailedToast(_ json: JSON) {
        guard let codeValue = json["code"].int else {
            DocsLogger.info("code is not exist")
            return
        }

        /// 判断外层code
        var msg = getInviteCollaboratorsForBizMessage(code: codeValue, ownerName: "", location: .invitedCollaborateAfter)
        if msg == nil {
            /// 判断内层json数据
            msg = getCollaboratorsBlockedMessage(json: json, ownerName: nil, location: .invitedCollaborateAfter, isFolder: true)
        }
        showToast(text: msg, type: .failure)
    }

    public func showInviteCollaboratorsForBizFailedToast(_ json: JSON) {
        let msg = getInviteCollaboratorsForBizFailedMessage(json)
        showToast(text: msg, type: .failure)
    }

    public func getInviteCollaboratorsForBizFailedMessage(_ json: JSON) -> String? {
        guard let codeValue = json["code"].int else {
            DocsLogger.info("code is not exist")
            return nil
        }
        // 下面这个方法把外层的code拿去和里层的blockUserMap-key作匹配
        var msg = getInviteCollaboratorsForBizMessage(code: codeValue, ownerName: "", location: .invitedCollaborateAfter)
        if msg == nil {
            msg = getCollaboratorsBlockedMessage(json: json, ownerName: nil, location: .invitedCollaborateAfter, isFolder: false)
        }
        return msg
    }
}

// Send Link
extension CollaboratorBlockStatusManager {

    public func showSendLinkFailedToast(_ json: JSON, isFolder: Bool) {
        let msg = getCollaboratorsBlockedMessage(json: json, ownerName: nil, location: .sendLink, isFolder: isFolder)
        showToast(text: msg, type: .failure)
    }
}

// Ask Owner
extension CollaboratorBlockStatusManager {

    // Ask Owner 失败 Toast 处理
    // Code 处理 「我」 和 「文档owner」之间的屏蔽关系，只可能返回一种，不需要处理优先级
    // map 内的错误码 list 处理 「文档owner」和 「邀请的协作者」之间的屏蔽关系，可能有多种情况，按照优先级处理
    public func showAskOwnerFailedToast(_ json: JSON, ownerName: String, isFolder: Bool) {
        guard let codeValue = json["code"].int else {
            DocsLogger.info("parseAskOwner code is not exist")
            return
        }
        DocsLogger.info("parseAskOwner code = \(codeValue)")
        var msg = getOwnerBlockedMessage(code: codeValue, ownerName: ownerName, location: .askOwner)
        if msg == nil {
            msg = getCollaboratorsBlockedMessage(json: json, ownerName: ownerName, location: .askOwner, isFolder: isFolder)
        }
        showToast(text: msg, type: .failure)
    }
}

// 我和owner之间的屏蔽关系
extension CollaboratorBlockStatusManager {

    // 主动屏蔽
    private func getBlockedOwnerMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .block, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyBlock(ownerName)
    }

    // 被动屏蔽
    private func getBlockedByOwnerMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .blocked, location: location)
        switch self.requestType {
        case .inviteCollaboratorsForBiz, .inviteCollaboratorsForFolder:
            return BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToInvite_Toast
        case .askOwner:
            return BundleI18n.SKResource.LarkCCM_BlockSettingsByOwner_UnableToInvite_Toast
        case .sendLink:
            return BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToSendMessage_Toast
        case .requestPermissionForBiz, .requestPermissionForFolder:
            return BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToRequestPerm_Toast
        }
    }

    // 隐私设置
    private func getOwnerPrivacySettingMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .privacySetting, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerPrivacySettingBlocked
    }

    // 次数限制
    func getOwnerCountsLimitsSingleMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .moreThenLimited, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyMaxLimit(ownerName, 5)
    }

    // 高管屏蔽
    func getOwnerIsExecutivesMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .adminSetting, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyAdminBlocked(ownerName)
    }

    // 数据迁移，禁止写操作
    func getDataUpgradeLockedMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .others, location: location)
        return BundleI18n.SKResource.CreationMobile_DataUpgrade_Locked_toast
    }

    // 邀请失败，所有者关闭了外部分享
    func getInviteFailOwnerClossShareMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .others, location: location)
        return BundleI18n.SKResource.Doc_Share_OwnerCloseShare
    }

    // 邀请失败，管理员关闭了外部分享
    func getInviteFailAdministratorClossShareMessage(ownerName: String, location: AuthErrorLocation) -> String {
        report(reason: .others, location: location)
        return BundleI18n.SKResource.Doc_Share_AdministratorCloseShare
    }
    
    /// 邀请失败，cac管控
    func showInviteFailCacBlocked(ownerName: String, location: AuthErrorLocation) {
        self.delegate?.showInviteFolderCollaboratorCacDialog(animated: true, completion: nil)
        report(reason: .others, location: location)
    }
}

// owner和被邀请人之间的屏蔽关系
extension CollaboratorBlockStatusManager {

    // 主动屏蔽
    private func getOwnerBlockedUsersMessage(ownerName: String, userNames: String, location: AuthErrorLocation) -> String {
        report(reason: .block, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyOwnerBlock(ownerName, userNames)
    }

    // 被动屏蔽
    private func getOwnerBlockedByUsersMessage(ownerName: String, userNames: String, location: AuthErrorLocation) -> String {
        report(reason: .blocked, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyOwnerBlocked(userNames, ownerName)
    }

    // 隐私设置
    private func getUsersPrivacySettingMessage(userNames: String, location: AuthErrorLocation) -> String {
        report(reason: .privacySetting, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyOwnerPrivacySettingBlocked(userNames)
    }

    // 次数限制
    func getUsersCountsLimitsSingleMessage(ownerName: String, userNames: String, location: AuthErrorLocation) -> String {
        report(reason: .moreThenLimited, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyOwnerMaxLimit(ownerName, userNames, 5)
    }
    
    // 邮箱协作者次数限制
    func getEmailCountsLimitsSingleMessage(location: AuthErrorLocation) -> String {
        report(reason: .moreThenLimited, location: location)
        return BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_ReachLimitToday_Toast
    }

    // 高管屏蔽
    func getUserIsExecutivesMessage(userNames: String, location: AuthErrorLocation) -> String {
        report(reason: .adminSetting, location: location)
        return BundleI18n.SKResource.Doc_Permission_AskOwnerApplyOwnerAdminBlocked(userNames)
    }
}

// 我和被邀请人之间的关系
extension CollaboratorBlockStatusManager {

    // 主动屏蔽
    private func getIBlockedUsersMessage(userNames: String) -> String? {
        switch self.requestType {
        case .inviteCollaboratorsForBiz, .inviteCollaboratorsForFolder:
            return BundleI18n.SKResource.Doc_Permission_BlockUnableInviteCollaboratorToast(userNames)
        case .sendLink:
            return BundleI18n.SKResource.Doc_Permission_AskOwnerSendLinkBlock(userNames)
        case .requestPermissionForBiz, .requestPermissionForFolder, .askOwner:
            return nil
        }
    }

    // 被动屏蔽
    private func getIBlockedByUsersMessage(userNames: String) -> String {
        switch self.requestType {
        case .inviteCollaboratorsForBiz, .inviteCollaboratorsForFolder:
            return BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToInvite_Toast
        case .askOwner:
            return BundleI18n.SKResource.LarkCCM_BlockSettingsByOwner_UnableToInvite_Toast
        case .sendLink:
            return BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToSendMessage_Toast
        case .requestPermissionForBiz, .requestPermissionForFolder:
            return BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToRequestPerm_Toast
        }
    }

    // 隐私设置
    private func getOtherUsersPrivacySettingMessage(userNames: String) -> String? {
        switch self.requestType {
        case .inviteCollaboratorsForBiz, .inviteCollaboratorsForFolder:
            return BundleI18n.SKResource.Doc_Permission_SettingInviteCollaboratorShareToast(userNames)
        case .sendLink:
            return BundleI18n.SKResource.Doc_Permission_SettingInviteCollaboratorShareToast(userNames)
        case .requestPermissionForBiz, .requestPermissionForFolder, .askOwner:
            return nil
        }
    }

    // 次数限制
    func getOtherUsersCountsLimitsSingleMessage(userNames: String) -> String? {
        switch self.requestType {
        case .inviteCollaboratorsForBiz, .inviteCollaboratorsForFolder:
            return BundleI18n.SKResource.Doc_Permission_MaxShareInvitationContactsToast(userNames, self.limitCount)
        case .sendLink:
            return BundleI18n.SKResource.Doc_Permission_AskOwnerSendLinkMaxLimit(userNames, 5)
        case .requestPermissionForBiz, .requestPermissionForFolder, .askOwner:
            return nil
        }
    }

    // 手机号邀请限制
    func getOtherUsersPhoneLimitsSingleMessage(userNames: String) -> String? {
        switch self.requestType {
        case .inviteCollaboratorsForBiz, .inviteCollaboratorsForFolder:
            return BundleI18n.SKResource.Doc_Permission_MaxSharePhonenumberInvitationToast(userNames)
        default:
            return nil
        }
    }

    // 高管屏蔽
    func getOtherUsersIsExecutivesMessage(userNames: String) -> String? {
        switch self.requestType {
        case .sendLink:
            return BundleI18n.SKResource.Doc_Permission_AskOwnerSendLinkAdminBlocked(userNames)
        default:
            return nil
        }
    }

    // 非关联组织屏蔽
    private func getOtherUsersNotInPartnerTenantMessage(userNames: String, isFolder: Bool) -> String {
        if isFolder {
            return BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario7(userNames)
        } else {
            return BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario4(userNames)
        }
    }

    static func getAllNotPartnerTenantCollaboratorNames(json: JSON) -> String? {
        guard let userIDs = json["data"]["block_user_map"]["10043"].array else { return nil }
        let userMap = json["data"]["user_map"]
        let userNames = userIDs.compactMap { json -> String? in
            guard let userID = json.string else { return nil }
            return userMap[userID]["name"].string
        }
        if userNames.isEmpty { return nil }

        let separator = LanguageManager.currentLanguage == .en_US ? "," : "、"
        return userNames.joined(separator: separator)
    }
    
    /// 非关联组织的外部用户邀请失败 name字符串
    static func getAllNotPartnerTenantFolderCollaboratorNames(json: JSON) -> String? {
        guard let userIDMaps = json["data"]["fail_map"].dictionary else { return nil }
        let userIDs = userIDMaps.compactMap { userID, reasonValue -> String? in
            guard reasonValue.int == 10043 || reasonValue.string == "10043" else { return nil }
            return userID
        }
        let userMap = json["data"]["user_map"]
        let userNames = userIDs.compactMap { userID -> String? in
            return userMap[userID]["name"].string
        }
        if userNames.isEmpty { return nil }

        let separator = LanguageManager.currentLanguage == .en_US ? "," : "、"
        return userNames.joined(separator: separator)
    }
    /// 是否被cac管控，被管控的情况有部分失败和全部失败
    static func getInviteResultsByCacBlocked(json: JSON) -> InviteResultsByCacBlocked {
        guard let userIDs = json["data"]["failCode_collaborator_map"]["2002"].array,
                userIDs.count > 0 else {
            return .noFail
        }
        if let successCount = json["data"]["success_count"].int, successCount > 0 {
            return .partFail
        }
        return .allFail
    }
    
    
    /// cac管控名单
    static func getAllCacBlockedCollaboratorNames(json: JSON) -> String? {
        guard let userIDMaps = json["data"]["fail_map"].dictionary else { return nil }
        let userIDs = userIDMaps.compactMap { userID, reasonValue -> String? in
            guard reasonValue.int == 2002 || reasonValue.string == "2002" else { return nil }
            return userID
        }
        let userMap = json["data"]["user_map"]
        let userNames = userIDs.compactMap { userID -> String? in
            return userMap[userID]["name"].string
        }
        if userNames.isEmpty { return nil }

        let separator = LanguageManager.currentLanguage == .en_US ? "," : "、"
        return userNames.joined(separator: separator)
    }
}

// 埋点
extension CollaboratorBlockStatusManager {

    private func report(reason: AuthErrorReason, location: AuthErrorLocation) {
        statistics?.clientAuthError(reason: reason, location: location)
    }
}

extension CollaboratorBlockStatusManager {
    func showToast(text: String?, type: DocsExtension<UDToast>.MsgType) {
        guard let text = text, let view = (self.fromView?.window ?? self.fromView) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
