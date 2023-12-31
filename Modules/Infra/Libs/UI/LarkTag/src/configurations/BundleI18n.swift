// swiftlint:disable all
/**
Warning: Do Not Edit It!
Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
Toolchains For EE


______ ______ _____        __
|  ____|  ____|_   _|      / _|
| |__  | |__    | |  _ __ | |_ _ __ __ _
|  __| |  __|   | | | '_ \|  _| '__/ _` |
| |____| |____ _| |_| | | | | | | | (_| |
|______|______|_____|_| |_|_| |_|  \__,_|


Meta信息不要删除！如果冲突，重新生成BundleI18n就好
---Meta---
{
"keys":{
"Lark_Chat_OfficialTag":{
"hash":"r3w",
"#vars":0
},
"Lark_Core_RegularAdministratorLable":{
"hash":"4sw",
"#vars":0
},
"Lark_Core_SuperAdministratorLable":{
"hash":"ZvY",
"#vars":0
},
"Lark_Education_SchoolParentGroupLabel":{
"hash":"Ii4",
"#vars":0
},
"Lark_Group_ConnectGroupLabel":{
"hash":"MjU",
"#vars":0
},
"Lark_Group_CreateGroup_TypeSwitch_Public":{
"hash":"HBg",
"#vars":0
},
"Lark_Group_GroupAdministratorLabel":{
"hash":"4nk",
"#vars":0
},
"Lark_Group_InvitationDeactivated":{
"hash":"yHw",
"#vars":0
},
"Lark_HelpDesk_AgentIcon":{
"hash":"5Aw",
"#vars":0
},
"Lark_HelpDesk_UserIcon":{
"hash":"lXM",
"#vars":0
},
"Lark_Legacy_ReadStatus":{
"hash":"1jo",
"#vars":0
},
"Lark_Legacy_TagCalendarConfliect":{
"hash":"HJo",
"#vars":0
},
"Lark_Legacy_TagCalendarConfliectInMonth":{
"hash":"Np4",
"#vars":0
},
"Lark_Legacy_TagCalendarCreator":{
"hash":"iyA",
"#vars":0
},
"Lark_Legacy_TagCalendarCurrentLocation":{
"hash":"aq0",
"#vars":0
},
"Lark_Legacy_TagCalendarNotAttend":{
"hash":"qFw",
"#vars":0
},
"Lark_Legacy_TagCalendarOptionalAttend":{
"hash":"6is",
"#vars":0
},
"Lark_Legacy_TagCalendarOrganizer":{
"hash":"mlw",
"#vars":0
},
"Lark_Legacy_TagExternal":{
"hash":"+vc",
"#vars":0
},
"Lark_Profile_AccountPausedLabel":{
"hash":"E8I",
"#vars":0
},
"Lark_Search_AppLabel":{
"hash":"yJg",
"#vars":0
},
"Lark_Status_AdminTag":{
"hash":"vwE",
"#vars":0
},
"Lark_Status_AllStaffTag":{
"hash":"Ew0",
"#vars":0
},
"Lark_Status_BotTag":{
"hash":"C+g",
"#vars":0
},
"Lark_Status_DeactivatedTag":{
"hash":"rlk",
"#vars":0
},
"Lark_Status_ExternalTag":{
"hash":"uqE",
"#vars":0
},
"Lark_Status_OnLeaveTag":{
"hash":"HDE",
"#vars":0
},
"Lark_Status_OrganizationSupervisor":{
"hash":"Pig",
"#vars":0
},
"Lark_Status_SupervisorMain":{
"hash":"g+U",
"#vars":0
},
"Lark_Status_SupervisorTag":{
"hash":"p8U",
"#vars":0
},
"Lark_Status_TagUnread":{
"hash":"kas",
"#vars":0
},
"Lark_Status_TagUnregistered":{
"hash":"iJc",
"#vars":0
},
"Lark_Status_TeamTag":{
"hash":"Pi8",
"#vars":0
},
"Lark_Supergroups_Supergroup":{
"hash":"aYc",
"#vars":0
},
"Project_T_AdministratorRoleHere":{
"hash":"z/Q",
"#vars":0
},
"Project_T_AllMembersRightHere":{
"hash":"ahY",
"#vars":0
},
"Project_T_MembersRole":{
"hash":"igU",
"#vars":0
}
},
"name":"LarkTag",
"short_key":true,
"config":{
"positional-args":true,
"use-native":true
},
"fetch":{
"resources":[{
"projectId":2207,
"namespaceId":[34815,38483,34810]
},{
"projectId":2094,
"namespaceId":[34132,34137]
},{
"projectId":2085,
"namespaceId":[34083]
},{
"projectId":2103,
"namespaceId":[34186,34191,34187]
},{
"projectId":2108,
"namespaceId":[34221,34216]
},{
"projectId":2187,
"namespaceId":[34695]
},{
"projectId":2521,
"namespaceId":[38139]
},{
"projectId":3545,
"namespaceId":[37986]
},{
"projectId":4394,
"namespaceId":[41385]
},{
"projectId":8217,
"namespaceId":[50340,50342,50344],
"support_single_param":true
},{
"projectId":3788,
"namespaceId":[38915]
},{
"projectId":2095,
"namespaceId":[34143,34138]
},{
"projectId":3129,
"namespaceId":[37171]
},{
"projectId":2268,
"namespaceId":[35181],
"support_single_param":true
},{
"projectId":2176,
"namespaceId":[34629,41969,41970]
},{
"projectId":2085,
"namespaceId":[34078,34083]
},{
"projectId":2113,
"namespaceId":[34251,34246]
},{
"projectId":2086,
"namespaceId":[38121,34089]
},{
"projectId":2231,
"namespaceId":[34959]
},{
"projectId":8770,
"namespaceId":[52445,66909]
},{
"projectId":23858,
"namespaceId":[81561]
}],
"locale":["en-US","zh-CN","zh-TW","zh-HK","ja-JP","id-ID","de-DE","es-ES","fr-FR","it-IT","pt-BR","vi-VN","ru-RU","hi-IN","th-TH","ko-KR","ms-MY"]
}
}
---Meta---
*/

import Foundation
import LarkLocalizations

final class BundleI18n: LanguageManager {
    private static let _tableLock = NSLock()
    private static var _tableMap: [String: String] = {
        _ = NotificationCenter.default.addObserver(
            forName: Notification.Name("preferLanguageChangeNotification"),
            object: nil,
            queue: nil
        ) { (_) -> Void in
            _tableLock.lock(); defer { _tableLock.unlock() }
            BundleI18n._tableMap = [:]
        }
        return [:]
    }()
    @usableFromInline
    static func LocalizedString(key: String, originalKey: String, lang: Lang? = nil) -> String {
        func fetch() -> String {
            #if USE_DYNAMIC_RESOURCE
            return self.localizedString(key: key, originalKey: originalKey, bundle: BundleConfig.LarkTagAutoBundle, moduleName: "LarkTag", lang: lang) ?? key
            #else
            return self.localizedString(key: key, bundle: BundleConfig.LarkTagAutoBundle, moduleName: "LarkTag", lang: lang) ?? key
            #endif
        }

        if lang != nil { return fetch() } // speicify lang will no cache, call api directly
        _tableLock.lock(); defer { _tableLock.unlock() }
        if let str = _tableMap[key] { return str }
        let str = fetch()
        _tableMap[key] = str
        return str
    }

    /*
     * you can set I18n like that:
     * static var done: String { @inline(__always) get { return LocalizedString(key: "done") } }
     */
    final class LarkTag {
        @inlinable
        static var Lark_Chat_OfficialTag: String {
            return LocalizedString(key: "r3w", originalKey: "Lark_Chat_OfficialTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Chat_OfficialTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "r3w", originalKey: "Lark_Chat_OfficialTag", lang: __lang)
        }
        @inlinable
        static var Lark_Core_RegularAdministratorLable: String {
            return LocalizedString(key: "4sw", originalKey: "Lark_Core_RegularAdministratorLable")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_RegularAdministratorLable(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4sw", originalKey: "Lark_Core_RegularAdministratorLable", lang: __lang)
        }
        @inlinable
        static var Lark_Core_SuperAdministratorLable: String {
            return LocalizedString(key: "ZvY", originalKey: "Lark_Core_SuperAdministratorLable")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Core_SuperAdministratorLable(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ZvY", originalKey: "Lark_Core_SuperAdministratorLable", lang: __lang)
        }
        @inlinable
        static var Lark_Education_SchoolParentGroupLabel: String {
            return LocalizedString(key: "Ii4", originalKey: "Lark_Education_SchoolParentGroupLabel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Education_SchoolParentGroupLabel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ii4", originalKey: "Lark_Education_SchoolParentGroupLabel", lang: __lang)
        }
        @inlinable
        static var Lark_Group_ConnectGroupLabel: String {
            return LocalizedString(key: "MjU", originalKey: "Lark_Group_ConnectGroupLabel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Group_ConnectGroupLabel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "MjU", originalKey: "Lark_Group_ConnectGroupLabel", lang: __lang)
        }
        @inlinable
        static var Lark_Group_CreateGroup_TypeSwitch_Public: String {
            return LocalizedString(key: "HBg", originalKey: "Lark_Group_CreateGroup_TypeSwitch_Public")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Group_CreateGroup_TypeSwitch_Public(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HBg", originalKey: "Lark_Group_CreateGroup_TypeSwitch_Public", lang: __lang)
        }
        @inlinable
        static var Lark_Group_GroupAdministratorLabel: String {
            return LocalizedString(key: "4nk", originalKey: "Lark_Group_GroupAdministratorLabel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Group_GroupAdministratorLabel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "4nk", originalKey: "Lark_Group_GroupAdministratorLabel", lang: __lang)
        }
        @inlinable
        static var Lark_Group_InvitationDeactivated: String {
            return LocalizedString(key: "yHw", originalKey: "Lark_Group_InvitationDeactivated")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Group_InvitationDeactivated(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yHw", originalKey: "Lark_Group_InvitationDeactivated", lang: __lang)
        }
        @inlinable
        static var Lark_HelpDesk_AgentIcon: String {
            return LocalizedString(key: "5Aw", originalKey: "Lark_HelpDesk_AgentIcon")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_HelpDesk_AgentIcon(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "5Aw", originalKey: "Lark_HelpDesk_AgentIcon", lang: __lang)
        }
        @inlinable
        static var Lark_HelpDesk_UserIcon: String {
            return LocalizedString(key: "lXM", originalKey: "Lark_HelpDesk_UserIcon")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_HelpDesk_UserIcon(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "lXM", originalKey: "Lark_HelpDesk_UserIcon", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_ReadStatus: String {
            return LocalizedString(key: "1jo", originalKey: "Lark_Legacy_ReadStatus")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_ReadStatus(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "1jo", originalKey: "Lark_Legacy_ReadStatus", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagCalendarConfliect: String {
            return LocalizedString(key: "HJo", originalKey: "Lark_Legacy_TagCalendarConfliect")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagCalendarConfliect(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HJo", originalKey: "Lark_Legacy_TagCalendarConfliect", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagCalendarConfliectInMonth: String {
            return LocalizedString(key: "Np4", originalKey: "Lark_Legacy_TagCalendarConfliectInMonth")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagCalendarConfliectInMonth(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Np4", originalKey: "Lark_Legacy_TagCalendarConfliectInMonth", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagCalendarCreator: String {
            return LocalizedString(key: "iyA", originalKey: "Lark_Legacy_TagCalendarCreator")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagCalendarCreator(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iyA", originalKey: "Lark_Legacy_TagCalendarCreator", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagCalendarCurrentLocation: String {
            return LocalizedString(key: "aq0", originalKey: "Lark_Legacy_TagCalendarCurrentLocation")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagCalendarCurrentLocation(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "aq0", originalKey: "Lark_Legacy_TagCalendarCurrentLocation", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagCalendarNotAttend: String {
            return LocalizedString(key: "qFw", originalKey: "Lark_Legacy_TagCalendarNotAttend")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagCalendarNotAttend(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "qFw", originalKey: "Lark_Legacy_TagCalendarNotAttend", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagCalendarOptionalAttend: String {
            return LocalizedString(key: "6is", originalKey: "Lark_Legacy_TagCalendarOptionalAttend")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagCalendarOptionalAttend(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "6is", originalKey: "Lark_Legacy_TagCalendarOptionalAttend", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagCalendarOrganizer: String {
            return LocalizedString(key: "mlw", originalKey: "Lark_Legacy_TagCalendarOrganizer")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagCalendarOrganizer(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "mlw", originalKey: "Lark_Legacy_TagCalendarOrganizer", lang: __lang)
        }
        @inlinable
        static var Lark_Legacy_TagExternal: String {
            return LocalizedString(key: "+vc", originalKey: "Lark_Legacy_TagExternal")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Legacy_TagExternal(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "+vc", originalKey: "Lark_Legacy_TagExternal", lang: __lang)
        }
        @inlinable
        static var Lark_Profile_AccountPausedLabel: String {
            return LocalizedString(key: "E8I", originalKey: "Lark_Profile_AccountPausedLabel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Profile_AccountPausedLabel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "E8I", originalKey: "Lark_Profile_AccountPausedLabel", lang: __lang)
        }
        @inlinable
        static var Lark_Search_AppLabel: String {
            return LocalizedString(key: "yJg", originalKey: "Lark_Search_AppLabel")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Search_AppLabel(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "yJg", originalKey: "Lark_Search_AppLabel", lang: __lang)
        }
        @inlinable
        static var Lark_Status_AdminTag: String {
            return LocalizedString(key: "vwE", originalKey: "Lark_Status_AdminTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_AdminTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "vwE", originalKey: "Lark_Status_AdminTag", lang: __lang)
        }
        @inlinable
        static var Lark_Status_AllStaffTag: String {
            return LocalizedString(key: "Ew0", originalKey: "Lark_Status_AllStaffTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_AllStaffTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Ew0", originalKey: "Lark_Status_AllStaffTag", lang: __lang)
        }
        @inlinable
        static var Lark_Status_BotTag: String {
            return LocalizedString(key: "C+g", originalKey: "Lark_Status_BotTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_BotTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "C+g", originalKey: "Lark_Status_BotTag", lang: __lang)
        }
        @inlinable
        static var Lark_Status_DeactivatedTag: String {
            return LocalizedString(key: "rlk", originalKey: "Lark_Status_DeactivatedTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_DeactivatedTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "rlk", originalKey: "Lark_Status_DeactivatedTag", lang: __lang)
        }
        @inlinable
        static var Lark_Status_ExternalTag: String {
            return LocalizedString(key: "uqE", originalKey: "Lark_Status_ExternalTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_ExternalTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "uqE", originalKey: "Lark_Status_ExternalTag", lang: __lang)
        }
        @inlinable
        static var Lark_Status_OnLeaveTag: String {
            return LocalizedString(key: "HDE", originalKey: "Lark_Status_OnLeaveTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_OnLeaveTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "HDE", originalKey: "Lark_Status_OnLeaveTag", lang: __lang)
        }
        @inlinable
        static var Lark_Status_OrganizationSupervisor: String {
            return LocalizedString(key: "Pig", originalKey: "Lark_Status_OrganizationSupervisor")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_OrganizationSupervisor(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Pig", originalKey: "Lark_Status_OrganizationSupervisor", lang: __lang)
        }
        @inlinable
        static var Lark_Status_SupervisorMain: String {
            return LocalizedString(key: "g+U", originalKey: "Lark_Status_SupervisorMain")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_SupervisorMain(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "g+U", originalKey: "Lark_Status_SupervisorMain", lang: __lang)
        }
        @inlinable
        static var Lark_Status_SupervisorTag: String {
            return LocalizedString(key: "p8U", originalKey: "Lark_Status_SupervisorTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_SupervisorTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "p8U", originalKey: "Lark_Status_SupervisorTag", lang: __lang)
        }
        @inlinable
        static var Lark_Status_TagUnread: String {
            return LocalizedString(key: "kas", originalKey: "Lark_Status_TagUnread")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_TagUnread(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "kas", originalKey: "Lark_Status_TagUnread", lang: __lang)
        }
        @inlinable
        static var Lark_Status_TagUnregistered: String {
            return LocalizedString(key: "iJc", originalKey: "Lark_Status_TagUnregistered")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_TagUnregistered(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "iJc", originalKey: "Lark_Status_TagUnregistered", lang: __lang)
        }
        @inlinable
        static var Lark_Status_TeamTag: String {
            return LocalizedString(key: "Pi8", originalKey: "Lark_Status_TeamTag")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Status_TeamTag(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "Pi8", originalKey: "Lark_Status_TeamTag", lang: __lang)
        }
        @inlinable
        static var Lark_Supergroups_Supergroup: String {
            return LocalizedString(key: "aYc", originalKey: "Lark_Supergroups_Supergroup")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Lark_Supergroups_Supergroup(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "aYc", originalKey: "Lark_Supergroups_Supergroup", lang: __lang)
        }
        @inlinable
        static var Project_T_AdministratorRoleHere: String {
            return LocalizedString(key: "z/Q", originalKey: "Project_T_AdministratorRoleHere")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Project_T_AdministratorRoleHere(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "z/Q", originalKey: "Project_T_AdministratorRoleHere", lang: __lang)
        }
        @inlinable
        static var Project_T_AllMembersRightHere: String {
            return LocalizedString(key: "ahY", originalKey: "Project_T_AllMembersRightHere")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Project_T_AllMembersRightHere(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "ahY", originalKey: "Project_T_AllMembersRightHere", lang: __lang)
        }
        @inlinable
        static var Project_T_MembersRole: String {
            return LocalizedString(key: "igU", originalKey: "Project_T_MembersRole")
        }
        /// - Parameter lang: 使用指定语言获取文案，同时获取多个不同语言的文案时，注意初始化加载主线程卡死风险
        @inlinable
        static func Project_T_MembersRole(lang __lang: Lang? = nil) -> String {
            return LocalizedString(key: "igU", originalKey: "Project_T_MembersRole", lang: __lang)
        }
    }
}
// swiftlint:enable all
