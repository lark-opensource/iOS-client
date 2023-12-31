//
//  SearchFactory.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/9.
//

import Foundation
import RxSwift
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import RustPB
import LarkFeatureGating
import LarkContainer
import LarkRustClient
import EEAtomic
import LarkSearchFilter

// 当用户态出错时, 获取不到RustService是, 用做兜底的服务
public class CatchSearchSource: SearchSource {
    public var identifier: String { return "CatchSearchSource" }
    public var supportedFilters: [SearchFilter] { return [] }
    public func search(request: SearchRequest) -> Observable<SearchResponse> {
        return .never()
    }
}

// 本文件用于存贮方便使用的一些内置组合的工厂方法和相应的helper组合方法
// 区别于Container, 这个文件的代码可以被外部依赖选择直接使用而不用依赖container.
// 另外这里作为提供给外部库使用的易用性接口，环境依赖类参数应该尽量可选，外部只用提供有限的必要参数即可

// TODO: 要传的参数太多了。怎么控制API传尽量少的参数...
public final class SearchFactory {
}

// MARK: - RustSearchSourceMaker
/// 负责创建一个调用底层Rust的Search Source. 兼容各个版本的Source和V2迁移
/// make方法可多次调用创建多个不同的source
public struct RustSearchSourceMaker {
    let userResolver: LarkContainer.UserResolver
    let rustService: RustService?
    let userService: PassportUserService?

    public var scene: SearchSceneSection
    public var supportedFilters: [SearchFilter] = []

    public var session: SearchSession
    public var authPermissions: [RustPB.Basic_V1_Auth_ActionType] = []

    public var externalID: String?

    public var needSearchOuterTenant: Bool = true
    public var doNotSearchResignedUser: Bool?
    public var inChatID: String?
    public var chatFilterMode: [ChatFilterMode]?
    /// calendar use, only true or nil, v2始终会带上这个标记
    public var includeMeetingGroup: Bool?

    /// 人群部门搜索的标记，只有V2支持，V1会降级到只有人
    public var includeChat = false
    public var includeDepartment = false
    /// 用户组类型，保留参数，目前大搜接口是写死的CCM用户组，未支持其他业务场景的用户组类型配置
    public var userGroupSceneType: UserGroupSceneType?
    public var includeUserGroup = false
    public var includeChatter = true
    public var includeBot = false
    public var includeThread = false
    public var includeMailContact = false
    /// 以群拉人标记，后端有对应的权限过滤
    public var includeChatForAddChatter = false
    /// 以部门拉人标记，后端有对应的权限过滤
    public var includeDepartmentForAddChatter = false
    /// 是否在搜索群的时候包含外部群
    public var includeOuterGroupForChat = false
    /// 是否在搜索单聊的时候包含密盾单聊
    public var includeShieldP2PChat = false
    /// 是否在搜索群的时候包含密盾群
    public var includeShieldGroup = false
    /// 是否筛选未聊天过的人和Bot
    public var excludeUntalkedChatterBot = false
    public var wikiNeedOwner = false
    /// 是否筛选外部联系人
    public var excludeOuterContact = false

    public var needRelationTag = true
    // 加在 commonFilter 中
    public var chatID: String?

    /// v1的local不太稳定，暂时只给历史遗留的使用。新代码迁移到v2, 不使用v1 local兜底了..
    public var v1LocalEnabled = true
    /// 优先级最高的外部群组配置
    public var incluedOuterChat: Bool?
    /// 是否包含密聊/密聊群聊
    public var includeCrypto: Bool?
    /// 是否支持搜索冷冻群
    public var supportFrozenChat: Bool?
    // 是否可以搜索到全部类型的群组
    public var includeAllChat: Bool?
    // 控制用户离职情况
    public var userResignFilter: UserResignFilter?
    // AI
    public var includeMyAi: Bool = false
    public var myAiMustTalked: Bool = false

    public var pickType: UniversalPickerType = .chat(chatMode: .unlimited)

    public var configs: [PickerContentConfigType]?

    public var resultViewWidth: (() -> CGFloat?)?

    /// todo: picker适配后再容器改造
    public init(resolver: LarkContainer.UserResolver, scene: SearchSceneSection, session: SearchSession = SearchSession()) {
        self.userResolver = resolver
        self.scene = scene
        self.session = session
        self.rustService = try? resolver.resolve(assert: RustService.self)
        let serviceContainer = try? resolver.resolve(assert: PickerServiceContainer.self)
        self.userService = serviceContainer?.userService
    }

    // lijinru attention 此处风险最大
    /*
     if v2 able {
        use v2
     } else {
        use v1 v1 不可用，返回空
     }
     ->
     if v2 able {
        use v2
     } else {
        nothing
     }
     */
    // maker不持有Source, Source持有maker来提供配置参数
    // nolint: long_function 较重的历史代码,内部也有函数拆分,暂不修改
    /// 现在临时用这个名字, 全量后再来调整方法名
    public func makeAndReturnProtocol() -> SearchSource {
        guard let rustService else { return CatchSearchSource() }

        func makeEntity(type: Search_V2_SearchEntityType, config: (inout Search_V2_BaseEntity.EntityItem) -> Void = { _ in }) -> Search_V2_BaseEntity.EntityItem {
            var en = Search_V2_BaseEntity.EntityItem()
            en.type = type
            config(&en)
            return en
        }
        var userEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .user) { (en) in
                typealias SearchType = Search_V2_UniversalFilters.UserFilter.SearchType
                /// addChatChatters场景不搜索离职用户出来
                var searchTypeTemp: Int32 = 0
                PickerLogger.shared.info(module: PickerLogger.Module.search, event: "search user config",
                                         parameters: "\(String(describing: doNotSearchResignedUser)), \(String(describing: userResignFilter)), \(excludeOuterContact)")
                if doNotSearchResignedUser == true {
                    searchTypeTemp = searchTypeTemp | Int32(SearchType.unResigned.rawValue)
                } else {
                    // 默认排除离职且未聊过天的（有联系的可以被搜索出来）
                    en.entityFilter.userFilter.exclude = true
                    searchTypeTemp = searchTypeTemp | Int32(SearchType.resigned.rawValue | SearchType.unTalked.rawValue)
                }
                if let userResignFilter = userResignFilter {
                    en.entityFilter.userFilter.exclude = false
                    // 根据userResignFilter重新设置unResigned或resigned
                    switch userResignFilter {
                    case .all:
                        searchTypeTemp = Int32(SearchType.resigned.rawValue) | Int32(SearchType.unResigned.rawValue)
                    case .resigned:
                        searchTypeTemp = Int32(SearchType.resigned.rawValue)
                    case .unresigned:
                        searchTypeTemp = Int32(SearchType.unResigned.rawValue)
                    @unknown default:
                        break
                    }
                }
                if excludeUntalkedChatterBot {
                    searchTypeTemp = searchTypeTemp | Int32(SearchType.talked.rawValue)
                }
                en.entityFilter.userFilter.searchType = [searchTypeTemp]
                if needRelationTag { en.entitySelector.userSelector.relationTag = true }
                en.entityFilter.userFilter.excludeOuterContact = excludeOuterContact
                inChatID.flatMap { inChatID in
                    en.entitySelector.userSelector.isInChatID = inChatID
                }
                // 配置团队的用户搜索属性
                let chatters: [PickerConfig.ChatterContent]? = configs?.getEntities()
                let chatterEntityConfig = chatters?.first
                if let teamIds = chatterEntityConfig?.field?.directlyTeamIds,
                   let teamId = teamIds.first {
                    en.entitySelector.userSelector.isDirectlyInTeamID = teamId
                }
            }
        }
        var botEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .bot) { (en) in
                typealias SearchType = Search_V2_UniversalFilters.BotFilter.SearchType
                if excludeUntalkedChatterBot {
                    en.entityFilter.botFilter.searchType = [Int32(SearchType.talked.rawValue)]
                }
            }
        }
        var wikiEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .wiki) { (en) in
                en.entitySelector.wikiSelector.needOwner = true
                if needRelationTag { en.entitySelector.wikiSelector.relationTag = true }
            }
        }
        var docEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .doc) { (en) in
                if needRelationTag { en.entitySelector.docSelector.relationTag = true }
            }
        }

        var chatEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .groupChat) { (en) in
                PickerLogger.shared.info(module: PickerLogger.Module.search, event: "search chat config",
                                         parameters: "\(includeChatForAddChatter), \(String(describing: incluedOuterChat)), \(String(describing: includeAllChat))")
                typealias SearchType = Search_V2_UniversalFilters.ChatFilter.SearchType
                var typeValue: Int = 0
                if includeChatForAddChatter {
                    en.entityFilter.groupChatFilter.addableAsUser = true
                    if includeOuterGroupForChat {
                        typeValue = SearchType.joined.rawValue
                    } else {
                        /// 以群拉群特化暂时不支持外部群，现在可通过设置 includeOuterGroupForChat 来取消特化逻辑
                        typeValue = SearchType.joined.rawValue | SearchType.unCrossTenant.rawValue
                    }
                } else {
                    typeValue = SearchType.joined.rawValue
                }
                // incluedOuterChat为新接口，是优先级最高的外部群组配置
                if let incluedOuterChat = incluedOuterChat {
                    if incluedOuterChat {
                        typeValue = SearchType.joined.rawValue
                    } else {
                        typeValue = SearchType.joined.rawValue | SearchType.unCrossTenant.rawValue
                    }
                }
                // 根据配置，设置是否可以搜索密聊群聊
                if let includeCrypto = includeCrypto, !includeCrypto {
                    typeValue = typeValue | SearchType.normal.rawValue
                }
                if let includeAllChat = self.includeAllChat, includeAllChat {
                    typeValue = SearchType.crossTenant.rawValue | SearchType.unCrossTenant.rawValue
                }
                en.entityFilter.groupChatFilter.searchTypes = [Int32(typeValue)]
                if needRelationTag { en.entitySelector.groupChatSelector.relationTag = true }
                en.entityFilter.groupChatFilter.addableAsUser = includeChatForAddChatter
                en.entityFilter.groupChatFilter.searchShield = includeShieldGroup
                /// 支持搜索解散后保留的群组
                if let supportFrozenChat = supportFrozenChat, supportFrozenChat {
                    en.entityFilter.groupChatFilter.needFrozenChat = true
                }

                // 配置团队的聊天搜索属性
                let chats: [PickerConfig.ChatContent]? = configs?.getEntities()
                let chatEntityConfig = chats?.first
                if let teamIds = chatEntityConfig?.field?.directlyTeamIds,
                   let teamId = teamIds.first {
                    en.entitySelector.groupChatSelector.isInTeamID = teamId
                }
                // TODO: chatFilterMode.flatMap { en.entityFilter.groupChatFilter.chatModes = $0 }
            }
        }
        var userGroupEntity: Search_V2_BaseEntity.EntityItem { makeEntity(type: .userGroup) }
        var userGroupAssignEntity: Search_V2_BaseEntity.EntityItem { makeEntity(type: .userGroupAssign) }
        var newUserGroupEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .newUserGroup) { (en) in
                en.entityFilter.newUserGroupFilter.userGroupTypes = [.assign, .dynamic]
                var nameSpace = Search_V2_UniversalFilters.NewUserGroupFilter.Namespace()
                let visibilityType = Basic_V1_UserGroupSceneType(rawValue: userGroupSceneType?.rawValue ?? 0)
                /// 目前nameSpace只有admin
                nameSpace.name = "admin"
                nameSpace.visibilityTypes.append(visibilityType ?? .sceneTypeUnknown)
                en.entityFilter.newUserGroupFilter.namespaces.append(nameSpace)
            }
        }
        var threadEntity: Search_V2_BaseEntity.EntityItem { makeEntity(type: .thread) }
        var departmentEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .department) { (en) in
                if includeDepartmentForAddChatter {
                    en.entityFilter.departmentFilter.addableAsUser = true
                }
            }
        }
        var mailContactEntity: Search_V2_BaseEntity.EntityItem { makeEntity(type: .mailContact) }
        var shieldP2PEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .shieldP2PChat) { (en) in
                if needRelationTag { en.entitySelector.shieldP2PChatSelector.relationTag = true }
            }

        }
        var cryptoEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .cryptoP2PChat) { (en) in
                if needRelationTag { en.entitySelector.cryptoP2PChatSelector.relationTag = true }
            }

        }
        var myAiEntity: Search_V2_BaseEntity.EntityItem {
            makeEntity(type: .myAi) { (en) in
                en.entityFilter.myAiFilter.mustHaveChat = myAiMustTalked
            }

        }

        var types: [Search_V2_BaseEntity.EntityItem] = []
        switch scene {
        case .rustScene(let remote):
            switch remote {
            case .addChatChatters:
                // TestCase:
                // * 正常高亮，内容正常
                // * 群内拉人正常置灰 TODO
                // * 离职员工是否能搜出(应该都不搜索出, 大搜才可以搜出离职)
                // * 外部租户过滤正常
                // * 权限提示正常
                if includeChatter { types.append(userEntity) }
                if includeBot { types.append(botEntity) }
                if includeChat { types.append(chatEntity) }
                if includeDepartment { types.append(departmentEntity) }
                if includeMailContact { types.append(mailContactEntity) }
                if includeUserGroup {
                    types.append(newUserGroupEntity)
                }
            case .searchUsers:
                types = [userEntity]
            case .searchInCalendarScene:
                // TestCase
                // Meeting群, 邮箱搜索
                types = [ userEntity, chatEntity, departmentEntity] // 动态开关控制是否搜索群和部门
                if includeMailContact { types.append(mailContactEntity) }
                if includeUserGroup {
                    types.append(userGroupEntity)
                    types.append(userGroupAssignEntity)
                }
            case .transmitMessages:
                types = [ userEntity, botEntity, chatEntity]
                if includeThread { types.append(threadEntity) }
                if includeShieldP2PChat { types.append(shieldP2PEntity) }
            case .searchHadChatHistoryScene:
                types = [ userEntity, chatEntity ]
                if includeBot { types.append(botEntity) }
            case .searchPinMsgScene:
                var messageEntity = makeEntity(type: .message)
                messageEntity.entityFilter.messageFilter.searchTypes = [.pin]
                types = [messageEntity]
            case .searchOncallScene:
                types = [makeEntity(type: .oncall)]
            case .searchFileScene:
                if SearchFeatureGatingKey.enableSearchSubFile.isUserEnabled(userResolver: self.userResolver) {
                    let file = makeEntity(type: .messageFile)
                    types = [file]
                } else {
                    var message = makeEntity(type: .message)
                    message.entityFilter.messageFilter.messageTypes = [.file]
                    if let chatID = chatID, !chatID.isEmpty {
                        message.entityFilter.messageFilter.messageTypes.append(.folder)
                    }
                    types = [message]
                }
            case .searchDoc:
                types = []
                switch pickType {
                case .folder:
                    var docEntity = makeEntity(type: .doc)
                    docEntity.entityFilter.docFilter.types = [.folder]
                    types.append(docEntity)
                case .workspace:
                    var wikiSpaceEntity = makeEntity(type: .wikiSpace)
                    wikiSpaceEntity.entityFilter.wikiSpaceFilter.wikiSpaceTypes = [.personal, .team]
                    types.append(wikiSpaceEntity)
                @unknown default:
                    types.append(docEntity)
                    types.append(wikiEntity)
                }
            case .searchChatters:
                types = [userEntity]
            @unknown default: break
            }
        case .searchDocCollaborator:
            types.append(userEntity)
            types.append(chatEntity)
            if includeUserGroup {
                types.append(userGroupEntity)
                types.append(userGroupAssignEntity)
            }
            if includeDepartment { types.append(departmentEntity) }
        case let .searchPlatformFilter(commandID):
            var openSearchEntity = makeEntity(type: .slashCommand)
            openSearchEntity.entityFilter.slashCommandFilter.commandID = commandID
            types = [openSearchEntity]
        case .searchDocAndWiki:
            types.append(docEntity)
            types.append(wikiEntity)
        case .searchUserAndGroupChat:
            types.append(userEntity)
            types.append(chatEntity)
        default: break
        }
        if SearchFeatureGatingKey.myAiMainSwitch.isUserEnabled(userResolver: self.userResolver) && includeMyAi {
            types.append(myAiEntity)
        }
        let resultViewWidth = self.resultViewWidth
        let chatID = chatID
        let source = RustSearchSourceV2(
            client: rustService, scene: scene.name, session: session,
            types: types, searchActionTabName: scene.searchActionTabName,
            resolver: self.userResolver,
            config: {
                [needSearchOuterTenant, authPermissions, chatID] header in // swiftlint:disable:this all
                header.searchContext.commonFilter.includeOuterTenant = needSearchOuterTenant
                if !authPermissions.isEmpty {
                    header.extraParams.chatterPermissions.actions = authPermissions
                }
                if let chatId = chatID {
                    header.searchContext.commonFilter.chatID = chatId
                }
                if let _resultViewWidth = resultViewWidth?(), _resultViewWidth > 0 {
                    header.titleLayout.width = Int32(TitleLayoutBenchmark().titleCountForMessage(searchViewWidth: _resultViewWidth))
                    header.summaryLayout.width = Int32(TitleLayoutBenchmark().subtitleCountForMessage(searchViewWidth: _resultViewWidth))
                }
                // 放到commonFilter里了，接群内搜索场景时再来管这个字段，现在context和filter等用途有些混淆
                // inChatID.flatMap { header.searchContext.chatID = $0 }
            })
        return source
    }
    // enable-lint: long_function
    public func makeSource(config: PickerSearchConfig, supportRecommend: Bool = false) -> SearchSource {
        guard let rustService else { return CatchSearchSource() }
        var types = SearchEntityGenerator.generatorEntities(configs: config.entities)
        if !SearchFeatureGatingKey.myAiMainSwitch.isUserEnabled(userResolver: self.userResolver) {
            types.removeAll(where: { $0.type == .myAi })
        }
        let chatterConfigs: [PickerConfig.ChatterEntityConfig] = config.entities.getEntities()
        let lastChatterTenant = chatterConfigs.last?.tenant
        let includeOuterChatter = lastChatterTenant == .all || lastChatterTenant == .outer
        let resultViewWidth = self.resultViewWidth
        let source = RustSearchSourceV2(
            client: rustService, scene: config.scene, session: session,
            types: types, searchActionTabName: .smartSearchTab,
            resolver: self.userResolver,
            config: { header in
                header.searchContext.commonFilter.includeOuterTenant = includeOuterChatter
                if let permissions = config.permissions {
                    header.extraParams.chatterPermissions.actions = permissions
                }
                if let chatId = config.chatId {
                    header.searchContext.commonFilter.chatID = chatId
                }
                header.isForce = supportRecommend
                if let _resultViewWidth = resultViewWidth?(), _resultViewWidth > 0 {
                    header.titleLayout.width = Int32(TitleLayoutBenchmark().titleCountForMessage(searchViewWidth: _resultViewWidth))
                    header.summaryLayout.width = Int32(TitleLayoutBenchmark().subtitleCountForMessage(searchViewWidth: _resultViewWidth))
                }
            })
        return source
    }
}

extension Search_V1_ChatFilterParam.ChatMode {
    func `as`() -> Search_V2_BaseEntity.ChatMode {
        switch self {
        case .thread: return .thread
        case .normal: return .normal
        case .unlimited: return .unlimited
        @unknown default: return .init()
        }
    }
}
