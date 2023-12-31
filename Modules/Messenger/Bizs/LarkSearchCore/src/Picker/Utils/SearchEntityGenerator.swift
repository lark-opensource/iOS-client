//
//  SearchEntityGenerator.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/29.
//

import Foundation
import LarkModel
import RustPB

final class SearchEntityGenerator {
    typealias Entity = Search_V2_BaseEntity.EntityItem
    typealias Chatter = PickerConfig.ChatterEntityConfig
    typealias Chat = PickerConfig.ChatEntityConfig
    typealias UserGroup = PickerConfig.UserGroupEntityConfig
    typealias Doc = PickerConfig.DocEntityConfig
    typealias Wiki = PickerConfig.WikiEntityConfig
    typealias WikiSpace = PickerConfig.WikiSpaceEntityConfig
    typealias MyAi = PickerConfig.MyAiEntityConfig
    typealias MailUser = PickerConfig.MailUserEntityConfig

    static func generatorEntities(configs: [EntityConfigType]) -> [Entity] {
        var entities = [Entity]()
        let chatterConfigs: [Chatter] = configs.getEntities()
        if !chatterConfigs.isEmpty {
            entities.append(getUserEntity(by: chatterConfigs))
        }
        let chatConfigs: [Chat] = configs.getEntities()
        if !chatConfigs.isEmpty {
            entities.append(getChatEntity(by: chatConfigs))
        }
        let userGroupConfigs: [UserGroup] = configs.getEntities()
        /// 新的数据结构下动态用户组、静态用户组都通过此配置进行设置
        if !userGroupConfigs.isEmpty {
            entities.append(getUserGroupEntity(by: userGroupConfigs))
        }
        let docConfigs: [Doc] = configs.getEntities()
        if !docConfigs.isEmpty {
            entities.append(getDocEntity(by: docConfigs))
        }
        let wikiConfigs: [Wiki] = configs.getEntities()
        if !wikiConfigs.isEmpty {
            entities.append(getWikiEntity(by: wikiConfigs))
        }
        let wikiSpaceConfigs: [WikiSpace] = configs.getEntities()
        if !wikiSpaceConfigs.isEmpty {
            entities.append(getWikiSpaceEntity(by: wikiSpaceConfigs))
        }
        let myAiConfigs: [MyAi] = configs.getEntities()
        if !myAiConfigs.isEmpty {
            entities.append(getMyAiEntity(by: myAiConfigs))
        }

        let mailUserConfigs: [MailUser] = configs.getEntities()
        if !mailUserConfigs.isEmpty {
            entities.append(getMailUserEntity(by: mailUserConfigs))
        }
        return entities
    }

    static func getUserEntity(by configs: [Chatter]) -> Search_V2_BaseEntity.EntityItem {
        var en = makeEntity(type: .user)
        typealias SearchType = Search_V2_UniversalFilters.UserFilter.SearchType
        for config in configs {
            var searchTypeTemp: Int32 = 0
            // 在职状态
            switch config.resign {
            case .resigned:
                searchTypeTemp = searchTypeTemp | Int32(SearchType.resigned.rawValue)
            case .unresigned:
                searchTypeTemp = searchTypeTemp | Int32(SearchType.unResigned.rawValue)
            case .all:
                searchTypeTemp = searchTypeTemp | Int32(SearchType.resigned.rawValue) | Int32(SearchType.unResigned.rawValue)
            @unknown default:
                break
            }
            // 是否聊过天
            switch config.talk {
            case .all:
                searchTypeTemp = searchTypeTemp | Int32(SearchType.talked.rawValue) | Int32(SearchType.unTalked.rawValue)
            case .talked:
                searchTypeTemp = searchTypeTemp | Int32(SearchType.talked.rawValue)
            case .untalked:
                searchTypeTemp = searchTypeTemp | Int32(SearchType.unTalked.rawValue)
            default:
                break
            }

            en.entityFilter.userFilter.searchType = [searchTypeTemp]
            // 是否过滤外部好友
            switch config.externalFriend {
            case .noExternalFriend:
                en.entityFilter.userFilter.excludeOuterContact = true
            default:
                break
            }
            // 是否仅搜索存在企业邮箱的用户
            switch config.existsEnterpriseEmail {
            case .onlyExistsEnterpriseEmail:
                en.entityFilter.userFilter.existsEnterpriseEmail = true
            default:
                break
            }
            // Field
            if let chatId = config.field?.chatIds?.first,
               !chatId.isEmpty {
                en.entitySelector.userSelector.isInChatID = chatId
            }
            if let teamId = config.field?.directlyTeamIds?.first,
               !teamId.isEmpty {
                en.entitySelector.userSelector.isDirectlyInTeamID = teamId
            }
            let needRelationTag = config.field?.relationTag ?? false
            en.entitySelector.userSelector.relationTag = needRelationTag
        }
        // 特殊处理: 在职 & 离职聊过
        let isIncludeInwork = configs.contains(where: { $0.resign == .unresigned })
        let resignAndTalked = configs.contains(where: {
            $0.resign == .resigned && $0.talk == .talked
        })
        if isIncludeInwork && resignAndTalked {
            var type = en.entityFilter.userFilter.searchType.first ?? 0
            // 去掉之前在职离职的设置,重新设置在职
            let mask = ~Int32(SearchType.resigned.rawValue | SearchType.unResigned.rawValue | SearchType.talked.rawValue | SearchType.unTalked.rawValue)
            type = type & mask
            type = type | Int32(SearchType.resigned.rawValue | SearchType.unTalked.rawValue)
            en.entityFilter.userFilter.exclude = true
            en.entityFilter.userFilter.searchType = [type]
        }
        return en
    }

    static func getChatEntity(by configs: [Chat]) -> Search_V2_BaseEntity.EntityItem {
        typealias SearchType = Search_V2_UniversalFilters.ChatFilter.SearchType
        var en = makeEntity(type: .groupChat)
        for config in configs {
            // 我管理的群组
            switch config.owner {
            case .all:
                en.entityFilter.groupChatFilter.addableAsUser = false
            case .ownered:
                en.entityFilter.groupChatFilter.addableAsUser = true
            @unknown default:
                break
            }
            // 是否关闭以人搜群
            switch config.searchByUser {
            case .closeSearchByUser:
                en.entityFilter.groupChatFilter.closeSearchByUser = true
            case .all:
                break
            @unknown default:
                break
            }
            // Search Types
            var searchTypes: Int32 = 0
            // 是否加入群聊
            switch config.join {
            case .joined:
                searchTypes = searchTypes | Int32(SearchType.joined.rawValue)
            case .unjoined:
                searchTypes = searchTypes | Int32(SearchType.unJoined.rawValue)
            default:
                break
            }
            // 内外部
            switch config.tenant {
            case .inner:
                searchTypes = searchTypes | Int32(SearchType.unCrossTenant.rawValue)
            case .outer:
                searchTypes = searchTypes | Int32(SearchType.crossTenant.rawValue)
            default:
                break
            }
            // 公开私有
            switch config.publicType {
            case .all:
                searchTypes = searchTypes | Int32(SearchType.public.rawValue | SearchType.private.rawValue)
            case .public:
                searchTypes = searchTypes | Int32(SearchType.public.rawValue)
            case .private:
                searchTypes = searchTypes | Int32(SearchType.private.rawValue)
            default:
                break
            }
            // 密聊
            switch config.crypto {
            case .all:
                searchTypes = searchTypes | Int32(SearchType.crypto.rawValue) | Int32(SearchType.normal.rawValue)
            case .normal:
                searchTypes = searchTypes | Int32(SearchType.normal.rawValue)
            case .crypto:
                searchTypes = searchTypes | Int32(SearchType.crypto.rawValue)
            default:
                break
            }
            en.entityFilter.groupChatFilter.searchTypes = [searchTypes]
            // 密盾聊
            switch config.shield {
            case .shield:
                en.entityFilter.groupChatFilter.searchShield = true
            case .noShield:
                en.entityFilter.groupChatFilter.searchShield = false
            default:
                break
            }
            // 是否包含冻结群
            switch config.frozen {
            case .all:
                en.entityFilter.groupChatFilter.needFrozenChat = true
            case .noFrozened:
                en.entityFilter.groupChatFilter.needFrozenChat = false
            @unknown default:
                break
            }
            /// Field
            if let relationTag = config.field?.relationTag {
                en.entitySelector.groupChatSelector.relationTag = relationTag
            }
            // 配置是否属于team
            if let teamId = config.field?.directlyTeamIds?.first {
                en.entitySelector.groupChatSelector.isInTeamID = teamId
            }

            if let showEnterpriseMail = config.field?.showEnterpriseMail {
                en.entitySelector.groupChatSelector.showEnterpriseEmail = showEnterpriseMail
            }
        }
        return en
    }

    static func getUserGroupEntity(by configs: [UserGroup]) -> Search_V2_BaseEntity.EntityItem {
        var en = makeEntity(type: .newUserGroup)
        var namespaces: [Search_V2_UniversalFilters.NewUserGroupFilter.Namespace] = []
        var userGroupTypes: [Basic_V1_UserGroupType] = []
        for config in configs {
            switch config.category {
            case .assign:
                userGroupTypes.append(.assign)
            case .dynamic:
                userGroupTypes.append(.dynamic)
            case .all:
                userGroupTypes.append(.assign)
                userGroupTypes.append(.dynamic)
            default: break
            }
            var nameSpace = Search_V2_UniversalFilters.NewUserGroupFilter.Namespace()
            let visibilityType = Basic_V1_UserGroupSceneType(rawValue: config.userGroupVisibilityType?.rawValue ?? 0)
            nameSpace.name = config.nameSpace
            nameSpace.visibilityTypes.append(visibilityType ?? .sceneTypeUnknown)
            namespaces.append(nameSpace)
        }
        en.entityFilter.newUserGroupFilter.userGroupTypes = userGroupTypes
        en.entityFilter.newUserGroupFilter.namespaces = namespaces
        return en
    }

    static func getDocEntity(by configs: [Doc]) -> Search_V2_BaseEntity.EntityItem {
        var en = makeEntity(type: .doc)
        for config in configs {
            switch config.belongUser {
            case .belong(let ids):
                en.entityFilter.docFilter.creatorIds = ids
            default:
                en.entityFilter.docFilter.creatorIds = []
            }
            switch config.belongChat {
            case .belong(let ids):
                en.entityFilter.docFilter.chatIds = ids
            default:
                en.entityFilter.docFilter.chatIds = []
            }
            en.entityFilter.docFilter.types = config.types
            switch config.reviewTimeRange {
            case .range(let start, let end):
                var range = Search_V2_UniversalFilters.TimeRange()
                range.startTime = start ?? 0
                range.endTime = end ?? Int64.max
                en.entityFilter.docFilter.reviewTimeRange = range
            default:
                en.entityFilter.docFilter.clearReviewTimeRange()
            }

            en.entityFilter.docFilter.searchContentTypes = config.searchContentTypes
            en.entityFilter.docFilter.sharerIds = config.sharerIds
            en.entityFilter.docFilter.fromIds = config.fromIds
            en.entityFilter.docFilter.sortType = config.sortType
            en.entityFilter.docFilter.crossLanguage = config.crossLanguage
            en.entityFilter.docFilter.folderTokens = config.folderTokens
            en.entityFilter.docFilter.enableExtendedSearch = config.enableExtendedSearch
            en.entityFilter.docFilter.useExtendedSearchV2 = config.useExtendedSearchV2

            if let field = config.field {
                en.entitySelector.docSelector.relationTag = field.relationTag
            }
        }
        return en
    }

    static func getWikiEntity(by configs: [Wiki]) -> Search_V2_BaseEntity.EntityItem {
        var en = makeEntity(type: .wiki)
        for config in configs {
            switch config.belongUser {
            case .belong(let ids):
                en.entityFilter.wikiFilter.creatorIds = ids
            default:
                en.entityFilter.wikiFilter.creatorIds = []
            }
            // chat ids
            switch config.belongChat {
            case .belong(let ids):
                en.entityFilter.wikiFilter.chatIds = ids
            default:
                en.entityFilter.wikiFilter.chatIds = []
            }

            switch config.reviewTimeRange {
            case .range(let start, let end):
                var range = Search_V2_UniversalFilters.TimeRange()
                range.startTime = start ?? 0
                range.endTime = end ?? Int64.max
                en.entityFilter.wikiFilter.reviewTimeRange = range
            case .all:
                en.entityFilter.wikiFilter.clearReviewTimeRange()
            default: break
            }

            en.entityFilter.wikiFilter.repoIds = config.repoIds
            en.entityFilter.wikiFilter.types = config.types
            en.entityFilter.wikiFilter.searchContentTypes = config.searchContentTypes
            en.entityFilter.wikiFilter.sharerIds = config.sharerIds
            en.entityFilter.wikiFilter.fromIds = config.fromIds
            en.entityFilter.wikiFilter.sortType = config.sortType
            en.entityFilter.wikiFilter.crossLanguage = config.crossLanguage
            en.entityFilter.wikiFilter.spaceIds = config.spaceIds
            en.entityFilter.wikiFilter.useExtendedSearchV2 = config.useExtendedSearchV2

            if let field = config.field {
                en.entitySelector.wikiSelector.relationTag = field.relationTag
            } else {
                en.entitySelector.wikiSelector.clearRelationTag()
            }
        }
        return en
    }

    static func getWikiSpaceEntity(by configs: [WikiSpace]) -> Search_V2_BaseEntity.EntityItem {
        var en = makeEntity(type: .wikiSpace)
        for config in configs {
            en.entityFilter.wikiSpaceFilter.wikiSpaceTypes = config.wikiSpaceTypes
        }
        return en
    }

    static func getMyAiEntity(by configs: [MyAi]) -> Search_V2_BaseEntity.EntityItem {
        var en = makeEntity(type: .myAi)
        if let config = configs.first {
            switch config.talk {
            case .talked:
                en.entityFilter.myAiFilter.mustHaveChat = true
            default:
                en.entityFilter.myAiFilter.clearMustHaveChat()
            }
        }
        return en
    }

    static func getMailUserEntity(by configs: [MailUser]) -> Search_V2_BaseEntity.EntityItem {
        var en = makeEntity(type: .mailUser)
        if let config = configs.first, !config.extras.isEmpty {
            en.extras = config.extras
        }
        return en
    }

    static func makeEntity(type: Search_V2_SearchEntityType) -> Search_V2_BaseEntity.EntityItem {
        var en = Search_V2_BaseEntity.EntityItem()
        en.type = type
        return en
    }
}
