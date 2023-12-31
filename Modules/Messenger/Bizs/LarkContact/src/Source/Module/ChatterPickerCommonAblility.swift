//
//  ChatterPickerCommonAblility.swift
//  LarkContact
//
//  Created by zc09v on 2020/12/10.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import LarkSearchCore
import UniverseDesignToast
import LarkMessengerInterface
import LarkAccountInterface
import RustPB
import LarkContainer
import LarkLocalizations

// MARK: - 对接chatterpicker方案定义协议，用于将不同数据来源归一
protocol ChatterPickerSelectedInfo {
    var selectedInfoId: String { get }
    var avatarKey: String { get }
    var name: String { get }
    var emailAddress: String? { get }
    func deniedReason() -> RustPB.Basic_V1_Auth_DeniedReason?
    func isExternal(currentTenantId: String) -> Bool
    func isNotFriend(reason: RustPB.Basic_V1_Auth_DeniedReason?) -> Bool
}

extension Option {
    /// should use this to convert, which will check the type for common struct like IntegrationSearchResult
    func asChatterPickerSelectedInfo() -> ChatterPickerSelectedInfo? {
        if self.optionIdentifier.type == OptionIdentifier.Types.chatter.rawValue {
            let result = self as? ChatterPickerSelectedInfo
            assert(result != nil, "数据应遵循ChatterPickerSelectedInfo协议")
            return result
        }
        return nil
    }

    func asBotPickerSelectedInfo() -> ChatterPickerSelectedInfo? {
        if self.optionIdentifier.type == OptionIdentifier.Types.bot.rawValue {
            let result = self as? ChatterPickerSelectedInfo
            assert(result != nil, "数据应遵循ChatterPickerSelectedInfo协议")
            return result
        }
        return nil
    }
}

extension Chatter: ChatterPickerSelectedInfo {
    var emailAddress: String? {
        return enterpriseEmail
    }

    var selectedInfoId: String {
        return self.id
    }
}

extension Search.Result: ChatterPickerSelectedInfo {
    var emailAddress: String? {
        var email: String?
        switch self.meta {
        case .chatter(let value):
            email = value.enterpriseEmail
        case .mailContact(let value):
            email = value.email
        default:
            break
        }
        return email
    }

    public var selectedInfoId: String {
        return self.id
    }
}

extension NewSelectExternalContact: ChatterPickerSelectedInfo {
    var emailAddress: String? {
        // TODO: MAIL_CONTACT
        return self.chatter?.enterpriseEmail
    }

    var avatarKey: String {
        self.contactInfo.avatarKey
    }

    var name: String {
        self.contactInfo.userName
    }

    var selectedInfoId: String {
        return self.contactInfo.userID
    }
}

extension Contact: ChatterPickerSelectedInfo {
    var emailAddress: String? {
        self.chatter?.email
    }

    var avatarKey: String {
        self.chatter?.avatarKey ?? ""
    }

    var name: String {
        self.chatter?.name ?? ""
    }

    var selectedInfoId: String {
        return self.chatterId
    }
}

extension SelectChatterInfo: ChatterPickerSelectedInfo {
    var emailAddress: String? {
        return self.email
    }

    var selectedInfoId: String {
        return self.ID
    }
}

extension SelectVisibleUserGroup: ChatterPickerSelectedInfo {
    var avatarKey: String {
        ""
    }

    var emailAddress: String? {
        nil
    }

    public var selectedInfoId: String {
        return self.id
    }
}

extension OptionIdentifier: ChatterPickerSelectedInfo {
    var emailAddress: String? {
        return nil
    }

    // 目前上层无法获知此属性, 暂时置空避免编译问题, 需由使用方获取
    var avatarKey: String {
        ""
    }

    // 目前上层无法获知此属性, 暂时置空避免编译问题, 需由使用方获取
    var name: String {
        ""
    }

    public var selectedInfoId: String {
        return self.id
    }
}

extension ChatterPickerSelectedInfo {
    func isNotFriend(reason: RustPB.Basic_V1_Auth_DeniedReason?) -> Bool {
        guard let reason = reason else {
            return false
        }
        return reason == .noFriendship
    }

    func deniedReason() -> RustPB.Basic_V1_Auth_DeniedReason? {
        if let externalContact = self as? NewSelectExternalContact {
            switch externalContact.deniedReason {
            // OU denied
            case .sameTenantDeny:
                return externalContact.deniedReason
            // contact denied
            case .beBlocked, .blocked, .noFriendship:
                return externalContact.deniedReason
            // crypto denied
            case .cryptoChatDeny:
                return externalContact.deniedReason
            // cooridinate control denied
            case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                return externalContact.deniedReason
            @unknown default:
                break
            }
        }
        if self is Contact {
            return nil
        }
        if let chatterMeta = asSearchChatterMetaInContact(self),
           let searchDeniedReason = chatterMeta.deniedReason.first?.value {
            if searchDeniedReason == .beBlocked || searchDeniedReason == .blocked {
                return nil
            }
            let deniedReason = RustPB.Basic_V1_Auth_DeniedReason(rawValue: searchDeniedReason.rawValue)
            let hasOUDeniedReason = (searchDeniedReason == .sameTenantDeny)
            let hasContactDeniedReason = (searchDeniedReason == .beBlocked ||
                searchDeniedReason == .blocked ||
                searchDeniedReason == .noFriendship)
            let hasCryptoDeniedReason = searchDeniedReason == .cryptoChatDeny
            let hasCoordinateCtl = searchDeniedReason == .externalCoordinateCtl
                || searchDeniedReason == .targetExternalCoordinateCtl
            if hasOUDeniedReason || hasContactDeniedReason || hasCryptoDeniedReason
                || hasCoordinateCtl {
                return deniedReason
            }
        }
        return nil
    }

    func isExternal(currentTenantId: String) -> Bool {
        if self is NewSelectExternalContact || self is Contact {
            return true
        }
        if let chatterMeta = asSearchChatterMetaInContact(self) {
            return chatterMeta.tenantID != currentTenantId
        }
        if let chatter = self as? Chatter {
            return chatter.tenantId != currentTenantId
        }
        return false
    }
}

// MARK: - 对接chaterpicker，对搜索结果一些权限判断
protocol CheckSearchChatterDeniedReason {
    // 根据权限判断搜索结果是否可选
    func checkSearchChatterDeniedReasonForDisabledPick(_ chatterMeta: SearchMetaChatterType) -> Bool
    // 根据权限对搜索结果进行权限提示
    func checkSearchChatterDeniedReasonForWillSelected(_ chatterMeta: SearchMetaChatterType, on window: UIWindow?) -> Bool
}

/// 将搜索结果类型尝试转化为需要的meta类型, 主要用于兼容v1,v2不同的模型
private func asSearchChatterMetaInContact(_ item: Any) -> SearchMetaChatterType? {
    if let v = item as? SearchResultType, case .chatter(let meta) = v.meta { return meta }
    return nil
}
extension Option {
    func getSearchChatterMetaInContact() -> SearchMetaChatterType? { asSearchChatterMetaInContact(self) }
}

extension CheckSearchChatterDeniedReason {
    func checkSearchChatterDeniedReasonForDisabledPick(_ chatterMeta: SearchMetaChatterType) -> Bool {
        if let searchDeniedReason = chatterMeta.deniedReason.first?.value {
            let contactAuthNeedBlock = (searchDeniedReason == .beBlocked || searchDeniedReason == .blocked)
            let hasCryptoDeniedReason = searchDeniedReason == .cryptoChatDeny
            let OUAuthNeedBlock = (searchDeniedReason == .sameTenantDeny)
            let hasCoordinateCtl = searchDeniedReason == .externalCoordinateCtl
                || searchDeniedReason == .targetExternalCoordinateCtl
            if contactAuthNeedBlock || OUAuthNeedBlock
                || hasCryptoDeniedReason || hasCoordinateCtl {
                return true
            }
        }
        return false
    }

    func checkSearchChatterDeniedReasonForWillSelected(_ chatterMeta: SearchMetaChatterType, on window: UIWindow?) -> Bool {
        if let searchDeniedReason = chatterMeta.deniedReason.first?.value {
            if searchDeniedReason == .beBlocked || searchDeniedReason == .blocked {
                let blockTip = BundleI18n.LarkContact.Lark_NewContacts_BlockedOthersUnableToXToastGeneral
                let beBlockTip = BundleI18n.LarkContact.Lark_NewContacts_BlockedUnableToXToastGeneral
                let tips = searchDeniedReason == .blocked ? blockTip : beBlockTip
                if let view = window {
                    UDToast.showTips(with: tips, on: view)
                }
                return false
            }
            if searchDeniedReason == .sameTenantDeny {
                if let view = window {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Groups_NoPermissionToAdd, on: view)
                }
                return false
            }
            if searchDeniedReason == .cryptoChatDeny {
                if let view = window {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Chat_CantSecretChatWithUserSecurityRestrict, on: view)
                }
                return false
            }
            if searchDeniedReason == .externalCoordinateCtl || searchDeniedReason == .targetExternalCoordinateCtl {
                if let view = window {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission, on: view)
                }
                return false
            }
        }
        return true
    }
}

// MARK: - 将Option数据转化为SelectChatterInfo
protocol ConvertOptionToSelectChatterInfo {
    func chatterInfos(from: [Option]) -> [SelectChatterInfo]
    var userResolver: UserResolver { get }
}

extension ConvertOptionToSelectChatterInfo {
    func chatterInfos(from: [Option]) -> [SelectChatterInfo] {
        guard let passportUserService = try? userResolver.resolve(assert: PassportUserService.self) else { return [] }
        let currentTenantID = passportUserService.userTenant.tenantID
        return from.compactMap({ (selected) -> SelectChatterInfo? in
            if let pickerSelectInfo = selected.asChatterPickerSelectedInfo() {
                var chatterInfo = SelectChatterInfo(ID: pickerSelectInfo.selectedInfoId)
                chatterInfo.avatarKey = pickerSelectInfo.avatarKey
                chatterInfo.name = pickerSelectInfo.name
                chatterInfo.isExternal = pickerSelectInfo.isExternal(currentTenantId: currentTenantID)
                chatterInfo.deniedReason = pickerSelectInfo.deniedReason()
                chatterInfo.email = pickerSelectInfo.emailAddress ?? ""
                // 搜索结果映射
                if let result = selected as? LarkSDKInterface.Search.Result,
                   case .userMeta(let info) = result.base.resultMeta.typedMeta {
                    chatterInfo.isInTeam = info.extraFields.isDirectlyInTeam
                    chatterInfo.localizedRealName = getLocalizeName(i18n: info.i18NNames) ?? ""
                }
                // 关联组织,组织架构
                if let result = selected as? LarkModel.Chatter {
                    chatterInfo.localizedRealName = result.localizedName
                }
                // 外部联系人映射
                if let result = selected as? LarkSDKInterface.NewSelectExternalContact {
                    chatterInfo.localizedRealName = result.chatter?.localizedName ?? ""
                }
                return chatterInfo
            }
            return nil
        })
    }

    private func getLocalizeName(i18n: [String: String]) -> String? {
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        var result = i18n[currentLocalizations]
        if result.isEmpty { // 没有匹配语言的名字时使用英文兜底
           result = i18n["en_us"]
        }
        return result
    }

    func botInfos(from: [Option]) -> [SelectBotInfo] {
        guard let passportUserService = try? userResolver.resolve(assert: PassportUserService.self) else { return [] }
        let currentTenantID = passportUserService.userTenant.tenantID
        return from.compactMap({ (selected) -> SelectBotInfo? in
            if let pickerSelectInfo = selected.asBotPickerSelectedInfo() {
                var botInfo = SelectBotInfo(id: pickerSelectInfo.selectedInfoId, avatarKey: pickerSelectInfo.avatarKey, name: pickerSelectInfo.name)
                return botInfo
            }
            return nil
        })
    }
}

// MARK: - 获取非好友人数
protocol GetSelectedUnFriendNum {
    func getSelectedUnFriendNum(_ options: [Option]) -> Int
}

extension GetSelectedUnFriendNum {
    func getSelectedUnFriendNum(_ options: [Option]) -> Int {
        return options.filter { (selectInfo) -> Bool in
            guard let chatterPickerSelectInfo = selectInfo.asChatterPickerSelectedInfo() else {
                return false }
            let reason = chatterPickerSelectInfo.deniedReason()
            return chatterPickerSelectInfo.isNotFriend(reason: reason)
        }.count
    }
}

// MARK: - 不同来源数据实现 ChatterPickeSelectChatType 协议
extension Option {
    func asPickerSelectChatType() -> ChatterPickeSelectChatType? {
        if self.optionIdentifier.type == OptionIdentifier.Types.chat.rawValue {
            let result = self as? ChatterPickeSelectChatType
            assert(result != nil, "数据应遵循 ChatterPickeSelectChatType 协议")
            return result
        }
        return nil
    }
}

extension Search.Result: ChatterPickeSelectChatType {
    public var isCrossTenant: Bool {
        if case .chat(let meta) = self.meta {
            return meta.isCrossTenant
        }
        return false
    }

    public var isPublic: Bool {
        if case .chat(let meta) = self.meta {
            return meta.isPublicV2
        }
        return false
    }

    public var isDepartment: Bool {
        if case .chat(let meta) = self.meta {
            return meta.isDepartment
        }
        return false
    }

    public var isCrypto: Bool {
        if case .chat(let meta) = self.meta {
            return meta.isCrypto
        }
        return false
    }

    public var isPrivateMode: Bool {
        if case .chat(let meta) = self.meta {
            return meta.isShield
        }
        return false
    }
}

extension Chat: ChatterPickeSelectChatType {
    public var selectedInfoId: String {
        return self.id
    }
}

/// 目前上层无法获知此属性, 暂时置空避免编译问题, 需由使用方获取
extension OptionIdentifier: ChatterPickeSelectChatType {
    public var isCrossTenant: Bool { return false }
    public var isPublic: Bool { return false }
    public var isDepartment: Bool { return false }
    public var isMeeting: Bool { return false }
    public var isCrypto: Bool { return false }
    public var isPrivateMode: Bool { return false }
}

extension SelectChatterInfo: Option {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.chatter(id: self.ID) }
}

extension SelectChatterInfo: SelectedOptionInfoConvertable, SelectedOptionInfo {
    public var avaterIdentifier: String { return self.ID }
}

extension SelectChatInfo: Option {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.chat(id: self.id) }
}

extension SelectChatInfo: SelectedOptionInfoConvertable, SelectedChatOptionInfo {
    public var isUserCountVisible: Bool {
        return true
    }

    public var avaterIdentifier: String { return self.id }
}

extension SelectDepartmentInfo: Option {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.department(id: self.id) }
}

extension SelectDepartmentInfo: SelectedOptionInfoConvertable, SelectedOptionInfo {
    public var avaterIdentifier: String { return self.id }
    public var avatarKey: String { return "" }
    public var backupImage: UIImage? { Resources.department_picker_default_icon }
}
