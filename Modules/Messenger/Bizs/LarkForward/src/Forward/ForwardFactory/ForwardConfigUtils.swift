//
//  ForwardConfigUtils.swift
//  LarkForward
//
//  Created by ByteDance on 2022/12/6.
//

import Foundation
import LarkMessengerInterface
import LarkModel
import LarkAccountInterface
import LKCommonsLogging
import LarkSearchCore
import UniverseDesignToast
import LarkContainer

public final class ForwardConfigUtils {
    static let logger = Logger.log(ForwardConfigUtils.self, category: "ForwardConfigUtils")
    static let loggerKeyword = "ForwardConfigUtils:"
    public static func isForwardItemEnabled(_ forwardItem: ForwardItem, _ enabledConfigs: [EntityConfigType]?, _ currentChatterID: String) -> Bool {
        //传nil代表不置灰
        guard let enabledConfigs = enabledConfigs else { return true }
        let chatters: [ForwardUserEnabledEntityConfig] = enabledConfigs.getEntities()
        let chats: [ForwardGroupChatEnabledEntityConfig] = enabledConfigs.getEntities()
        let bots: [ForwardBotEnabledEntityConfig] = enabledConfigs.getEntities()
        let threads: [ForwardThreadEnabledEntityConfig] = enabledConfigs.getEntities()
        let myAis: [ForwardMyAiEnabledEntityConfig] = enabledConfigs.getEntities()

        var enabled = false
        if forwardItem.type == .user, let userConfig = chatters.first {
            var isSelfTypeConditionSame = false
            var isTenantConditionSame = false
            switch userConfig.selfType {
            case .me:
                isSelfTypeConditionSame = forwardItem.id == currentChatterID
            case .other:
                isSelfTypeConditionSame = forwardItem.id != currentChatterID
            case .all:
                isSelfTypeConditionSame = true
            }
            switch userConfig.tenant {
            case .outer:
                isTenantConditionSame = forwardItem.isCrossTenant || forwardItem.isCrossWithKa
            case .inner:
                isTenantConditionSame = !forwardItem.isCrossTenant && !forwardItem.isCrossWithKa
            case .all:
                isTenantConditionSame = true
            }
            //item属性和置灰参数match时，item可被保留下来（不置灰），否则将置灰
            enabled = isTenantConditionSame && isSelfTypeConditionSame
        }
        if forwardItem.type == .chat, let groupChatConfig = chats.first {
            var isGroupChatTypeConditionSame = false
            var isTenantConditionSame = false
            switch groupChatConfig.chatType {
            case .thread:
                isGroupChatTypeConditionSame = forwardItem.isThread
            case .normal:
                isGroupChatTypeConditionSame = !forwardItem.isThread
            case .all:
                isGroupChatTypeConditionSame = true
            }
            switch groupChatConfig.tenant {
            case .outer:
                isTenantConditionSame = forwardItem.isCrossTenant
            case .inner:
                isTenantConditionSame = !forwardItem.isCrossTenant
            case .all:
                isTenantConditionSame = true
            }
            enabled = isTenantConditionSame && isGroupChatTypeConditionSame
        }
        if forwardItem.type == .bot, let botConfig = bots.first {
            enabled = true
        }
        if (forwardItem.type == .threadMessage || forwardItem.type == .replyThreadMessage), let threadConfig = threads.first {
            var isThreadTypeConditionSame = false
            switch threadConfig.threadType {
            case .normal:
                isThreadTypeConditionSame = forwardItem.type == .threadMessage
            case .message:
                isThreadTypeConditionSame = forwardItem.type == .replyThreadMessage
            case .all:
                isThreadTypeConditionSame = true
            }
            enabled = isThreadTypeConditionSame
        }
        if forwardItem.type == .myAi, !myAis.isEmpty {
            enabled = true
        }
        if !enabled { self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> enabled:false") }
        return enabled
    }

    /// 根据置灰参数判断ChatterMeta是否置灰，true表示置灰
    private static func isChatterDisabled(chatterMeta: PickerChatterMeta,
                                          currentUserID: String,
                                          userEnabledConfig: ForwardUserEnabledEntityConfig) -> Bool {
        // Chatter实体属性是否满足Chatter置灰配置
        // 例如，isOuter属性是true，则置灰配置配置为.all或.outer时该值为true，表示条件满足
        // 配置的所有条件都满足时才不置灰，否则置灰
        var isSelfTypeConditionSatisfied = false
        // 内外部是否满足配置
        var isTenantConditionSatisfied = false
        switch userEnabledConfig.selfType {
        case .me:
            // 仅展示自己
            isSelfTypeConditionSatisfied = chatterMeta.id == currentUserID
        case .other:
            // 仅展示别人
            isSelfTypeConditionSatisfied = chatterMeta.id != currentUserID
        case .all:
            isSelfTypeConditionSatisfied = true
        default:
            break
        }
        switch userEnabledConfig.tenant {
        case .outer:
            // 仅展示外部
            isTenantConditionSatisfied = chatterMeta.isOuter == true
        case .inner:
            // 仅展示内部
            isTenantConditionSatisfied = chatterMeta.isOuter != true
        case .all:
            isTenantConditionSatisfied = true
        default:
            break
        }
        // 所有条件都满足，则不置灰
        // 若有条件不满足，则要置灰
        let disabled = !(isSelfTypeConditionSatisfied && isTenantConditionSatisfied)
        return disabled
    }

    /// 根据过滤参数判断ChatterMeta是否置灰，true表示置灰
    private static func isChatterDisabled(chatterMeta: PickerChatterMeta,
                                          userIncludeConfig: ForwardUserEntityConfig) -> Bool {
        var isTenantConditionSatisfied = false
        switch userIncludeConfig.tenant {
        case .outer:
            // 仅展示外部
            isTenantConditionSatisfied = chatterMeta.isOuter == true
        case .inner:
            // 仅展示内部
            isTenantConditionSatisfied = chatterMeta.isOuter != true
        case .all:
            isTenantConditionSatisfied = true
        default:
            break
        }
        // tenant条件满足，则不置灰
        // tenant条件不满足，则要置灰
        let disabled = !isTenantConditionSatisfied
        return disabled
    }

    /// 根据置灰参数判断ChatMeta是否置灰
    private static func isChatDisabled(chatMeta: PickerChatMeta,
                                       chatEnabledConfig: ForwardGroupChatEnabledEntityConfig) -> Bool {
        // 群聊类型是否满足配置
        var isChatTypeConditionSatisfied = false
        // 内外部是否满足配置
        var isTenantConditionSatisfied = false
        switch chatEnabledConfig.chatType {
        case .thread:
            // 仅展示话题群
            isChatTypeConditionSatisfied = chatMeta.mode == .threadV2
        case .normal:
            // 仅展示普通群（不展示话题群）
            isChatTypeConditionSatisfied = chatMeta.mode == .default
        case .all:
            isChatTypeConditionSatisfied = true
        default:
            break
        }
        switch chatEnabledConfig.tenant {
        case .outer:
            // 仅展示外部
            isTenantConditionSatisfied = chatMeta.isOuter == true
        case .inner:
            isTenantConditionSatisfied = chatMeta.isOuter != true
        case .all:
            isTenantConditionSatisfied = true
        default:
            break
        }
        let disabled = !(isChatTypeConditionSatisfied && isTenantConditionSatisfied)
        return disabled
    }

    /// 根据过滤参数判断ChatMeta是否置灰
    private static func isChatDisabled(chatMeta: PickerChatMeta,
                                       chatIncludeConfig: ForwardGroupChatEntityConfig) -> Bool {
        var isTenantConditionSatisfied = false
        switch chatIncludeConfig.tenant {
        case .outer:
            // 仅展示外部
            isTenantConditionSatisfied = chatMeta.isOuter == true
        case .inner:
            // 仅展示内部
            isTenantConditionSatisfied = chatMeta.isOuter != true
        case .all:
            isTenantConditionSatisfied = true
        default:
            break
        }
        // tenant条件满足，则不置灰
        // tenant条件不满足，则要置灰
        let disabled = !isTenantConditionSatisfied
        return disabled
    }

    public static func isPickerItemDisabled(pickerItem: PickerItem, includeConfigs: [EntityConfigType]?) -> Bool {
        guard let includeConfigs = includeConfigs else { return false }
        let userConfigs: [ForwardUserEntityConfig] = includeConfigs.getEntities()
        let chatConfigs: [ForwardGroupChatEntityConfig] = includeConfigs.getEntities()
        let myAiConfigs: [ForwardMyAiEntityConfig] = includeConfigs.getEntities()
        switch pickerItem.meta {
        case .chatter(let chatterMeta):
            if chatterMeta.isMyAI == true {
                return myAiConfigs.isEmpty
            } else if let userConfig = userConfigs.first {
                return Self.isChatterDisabled(chatterMeta: chatterMeta, userIncludeConfig: userConfig)
            } else {
                return true
            }
        case .chat(let chatMeat):
            if let chatConfig = chatConfigs.first {
                return Self.isChatDisabled(chatMeta: chatMeat, chatIncludeConfig: chatConfig)
            } else {
                return true
            }
        default:
            break
        }
        return false
    }

    /// 根据置灰参数判断PickerItem是否需要置灰
    public static func isPickerItemDisabled(pickerItem: PickerItem,
                                            currentChatterID: String,
                                            enabledConfigs: [EntityConfigType]?) -> Bool {
        //参数数组为nil，代表用户使用默认配置，默认不置灰
        guard let enabledConfigs = enabledConfigs else { return false }
        // pickerItem目前无法区分机器人实体和话题实体，只有chatter实体（包括MyAI）和chat实体
        let userConfigs: [ForwardUserEnabledEntityConfig] = enabledConfigs.getEntities()
        let chatConfigs: [ForwardGroupChatEnabledEntityConfig] = enabledConfigs.getEntities()
        let myAiConfigs: [ForwardMyAiEnabledEntityConfig] = enabledConfigs.getEntities()
        switch pickerItem.meta {
        case .chatter(let chatterMeta):
            if chatterMeta.isMyAI == true {
                // myAI类型: myAIConfigs为空置灰，不为空不置灰
                return myAiConfigs.isEmpty
            } else if let userConfig = userConfigs.first {
                // 普通单聊，参数数组中有userConfig，根据配置参数决定是否置灰
                return Self.isChatterDisabled(chatterMeta: chatterMeta,
                                              currentUserID: currentChatterID,
                                              userEnabledConfig: userConfig)
            } else {
                // 普通单聊，参数数组中无userConfig，置灰
                return true
            }
        case .chat(let chatMeta):
            if let chatConfig = chatConfigs.first {
                // 群聊类型，参数数组中有chatConfig，根据配置参数决定是否置灰
                return Self.isChatDisabled(chatMeta: chatMeta, chatEnabledConfig: chatConfig)
            } else {
                // 群聊类型，参数数组中无chatConfig，置灰
                return true
            }
        default:
            // 其他类型不做处理，默认不置灰
            break
        }
        return false
    }

    // 创建群组并转发默认置灰逻辑
    public static func isPickerItemDisabledInCreateGroup(pickerItem: PickerItem) -> Bool {
        switch pickerItem.meta {
        case .chat(let chatMeta):
            // 外部群置灰
            return (chatMeta.isOuter == true)
        case .chatter(let chatterMeta):
            // deniedReasons为nil不置灰
            guard let reasons = chatterMeta.deniedReasons else { return false }
            // 包含下列reason则置灰，否则不置灰
            if reasons.contains(where: { $0 == .beBlocked || $0 == .blocked || $0 == .cryptoChatDeny || $0 == .sameTenantDeny || $0 == .externalCoordinateCtl || $0 == .targetExternalCoordinateCtl }) {
                return true
            } else {
                return false
            }
        default: break
        }
        // 其他情况不置灰
        return false
    }

    // “转发业务方过滤参数”转换成“创建群组Picker搜索过滤参数”
    public static func transToPickerSearchConfigs(forwardIncludeConfigs: [EntityConfigType]?) -> [EntityConfigType] {
        var pickerSearchConfigs: [EntityConfigType] = []
        guard let forwardIncludeConfigs = forwardIncludeConfigs else { return pickerSearchConfigs }
        let chatters: [ForwardUserEntityConfig] = forwardIncludeConfigs.getEntities()
        let chats: [ForwardGroupChatEntityConfig] = forwardIncludeConfigs.getEntities()
        let myAis: [ForwardMyAiEntityConfig] = forwardIncludeConfigs.getEntities()
        // picker搜索chatter配置
        let pickerChatterConfigs: [EntityConfigType] = chatters.map { PickerConfig.ChatterEntityConfig(tenant: $0.tenant) }
        // picker搜索chat配置, relationTag需设为true，否则搜索场景item不展示外部Tag
        let pickerChatConfigs: [EntityConfigType] = chats.map { PickerConfig.ChatEntityConfig(tenant: $0.tenant, field: .init(relationTag: true)) }
        // picker搜索myai配置
        let pickerMyAiConfigs: [EntityConfigType] = myAis.map { _ in PickerConfig.MyAiEntityConfig(talk: .all) }
        // picker不支持bot和thread实体的配置，转换逻辑
        pickerSearchConfigs = pickerChatterConfigs + pickerChatConfigs + pickerMyAiConfigs
        return pickerSearchConfigs
    }

    public static func convertIncludeConfigsToPickerInitParams(includeConfigs: IncludeConfigs, pickerParam: ChatPicker.InitParam) -> ChatPicker.InitParam {
        //目前转发搜索在includConfigs里仅支持配置单个
        //新参数设计下，仍需将includeConfigs映射至pickerParam再传给转发搜索场景使用
        let chatters: [ForwardUserEntityConfig] = includeConfigs.getEntities()
        let chats: [ForwardGroupChatEntityConfig] = includeConfigs.getEntities()
        let threads: [ForwardThreadEntityConfig] = includeConfigs.getEntities()
        let myAis: [ForwardMyAiEntityConfig] = includeConfigs.getEntities()
        if let userConfig = chatters.first {
            // 大搜是否过滤外部联系人逻辑是 includeOuterTenant&&!excludeOuterContact
            switch userConfig.tenant {
            case .outer:
                assertionFailure("only include outer users not supported")
            case .inner:
                // 过滤外部联系人
                pickerParam.includeOuterTenant = false
            case .all:
                // 不过滤外部联系人
                pickerParam.includeOuterTenant = true
                pickerParam.excludeOuterContact = false
            }
            // 目前默认包含密盾聊单聊
            pickerParam.includeShieldP2PChat = true
            // 转发场景只展示在职用户
            pickerParam.doNotSearchResignedUser = true
        }
        if let groupChatConfig = chats.first {
            // 大搜是否展示外部群聊逻辑是由 优先级最高的includeOuterChat控制，includeOuterTenant不影响
            switch groupChatConfig.tenant {
            case .outer:
                assertionFailure("only include outer groupchats not supported")
            case .inner:
                //过滤外部群组
                pickerParam.includeOuterChat = false
            case .all:
                pickerParam.includeOuterChat = true
            }
            // 目前默认包含密盾聊群聊
            pickerParam.includeShieldGroup = true
        }
        if let threadConfig = threads.first {
            pickerParam.includeThread = true
        } else {
            pickerParam.includeThread = false
        }
        pickerParam.includeMyAi = !myAis.isEmpty
        return pickerParam
    }

    public static func convertIncludeConfigsToAtPickerInitParams(includeConfigs: IncludeConfigs, pickerParam: AtPicker.InitParam) -> AtPicker.InitParam {
        //目前转发搜索在includConfigs里仅支持配置单个
        //新参数设计下，仍需将includeConfigs映射至pickerParam再传给转发搜索场景使用
        let chatters: [ForwardUserEntityConfig] = includeConfigs.getEntities()
        let threads: [ForwardThreadEntityConfig] = includeConfigs.getEntities()
        if let userConfig = chatters.first {
            // 大搜是否过滤外部联系人逻辑是 includeOuterTenant&&!excludeOuterContact
            switch userConfig.tenant {
            case .outer:
                assertionFailure("only include outer users not supported")
            case .inner:
                // 过滤外部联系人
                pickerParam.includeOuterTenant = false
            case .all:
                // 不过滤外部联系人
                pickerParam.includeOuterTenant = true
            }
        }
        if let threadConfig = threads.first {
            pickerParam.includeThread = true
        } else {
            pickerParam.includeThread = false
        }
        return pickerParam
    }

    public static func logForwardEnabledConfigs(enabledConfigs: [EntityConfigType]?) {
        guard let enabledConfigs = enabledConfigs else {
            self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> enabledConfigs is nil")
            return
        }
        var logStr = ""
        for enabledConfig in enabledConfigs {
            if let userConfig = enabledConfig as? ForwardUserEnabledEntityConfig {
                logStr += userConfig.description + "; "
            }
            if let groupChatConfig = enabledConfig as? ForwardGroupChatEnabledEntityConfig {
                logStr += groupChatConfig.description + "; "
            }
            if let botConfig = enabledConfig as? ForwardBotEnabledEntityConfig {
                logStr += botConfig.description + "; "
            }
            if let threadConfig = enabledConfig as? ForwardThreadEnabledEntityConfig {
                logStr += threadConfig.description
            }
        }
        self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> enabledConfigs: \(logStr)")
    }

   // 创建群组并转发根据鉴权结果决定是否置灰，以及toast逻辑
   public static func checkSearchChatterDeniedReasonForWillSelected(chatterMeta: PickerChatterMeta, on window: UIWindow?) -> Bool {
        if let reasons = chatterMeta.deniedReasons {
            if reasons.contains(where: { $0 == .blocked }) {
                if let view = window {
                    UDToast.showTips(with: BundleI18n.LarkForward.Lark_NewContacts_BlockedOthersUnableToXToastGeneral, on: view)
                }
                return false
            }
            if reasons.contains(where: { $0 == .beBlocked }) {
                if let view = window {
                    UDToast.showTips(with: BundleI18n.LarkForward.Lark_NewContacts_BlockedUnableToXToastGeneral, on: view)
                }
                return false
            }
            if reasons.contains(where: { $0 == .sameTenantDeny }) {
                if let view = window {
                    UDToast.showFailure(with: BundleI18n.LarkForward.Lark_Groups_NoPermissionToAdd, on: view)
                }
                return false
            }
            if reasons.contains(where: { $0 == .cryptoChatDeny }) {
                if let view = window {
                    UDToast.showFailure(with: BundleI18n.LarkForward.Lark_Chat_CantSecretChatWithUserSecurityRestrict, on: view)
                }
                return false
            }
            if reasons.contains(where: { $0 == .externalCoordinateCtl || $0 == .targetExternalCoordinateCtl }) {
                if let view = window {
                    UDToast.showFailure(with: BundleI18n.LarkForward.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission, on: view)
                }
                return false
            }
        }
        return true
    }

    public static func chatterInfos(pickerChatterMeta: [PickerChatterMeta], userResolver: UserResolver) -> [SelectChatterInfo] {
        guard let passportUserService = try? userResolver.resolve(assert: PassportUserService.self) else { return [] }
        let currentTID = passportUserService.userTenant.tenantID
        return pickerChatterMeta.map { (chatterMeta) -> SelectChatterInfo in
            var info = SelectChatterInfo(ID: chatterMeta.id)
            info.avatarKey = chatterMeta.avatarKey ?? ""
            info.name = chatterMeta.name ?? ""
            info.isExternal = chatterMeta.isOuter ?? false
            info.deniedReason = chatterMeta.deniedReasons?.first
            info.email = chatterMeta.email ?? ""
            info.localizedRealName = chatterMeta.localizedRealName ?? (chatterMeta.name ?? "")
            info.isInTeam = chatterMeta.isDirectlyInTeam
            return info
        }
    }

    public static func getSelectedUnFriendNum(pickerItems: [PickerItem]) -> Int {
        return pickerItems.filter { (pickerItem) -> Bool in
            if case let .chatter(chatterMeta) = pickerItem.meta {
                guard let reasons = chatterMeta.deniedReasons else { return false }
                return reasons.contains(where: { $0 == .noFriendship })
            }
            return false
        }.count
    }
}
