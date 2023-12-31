//
//  CollaboratorUniversalSearchAPI.swift
//  CCMMod
//
//  Created by Weston Wu on 2022/11/24.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import Swinject
import ServerPB
import RustPB
import SKResource
import LarkAccountInterface

#if MessengerMod
import LarkSDKInterface

class CollaboratorUniversalSearchAPI: CollaboratorSearchAPI {

    let searchAPI: SearchAPI

    init(searchAPI: SearchAPI) {
        self.searchAPI = searchAPI
    }

    func getRecommend() -> Single<[Collaborator]> {
        DocsLogger.info("start get recommend using V2 API")
        let request = ServerPB_Usearch_PullDocFeedCardsRequest()
        return searchAPI.universalRecommendFeeds(request: request)
            .map { results -> [Collaborator] in
                return results.compactMap(Self.convert(searchResult:))
            }
            .asSingle()
    }

    func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse> {
        if request.query.isEmpty {
            // 无 query 只有一页
            return getRecommend().map {
                CollaboratorSearchResponse(collaborators: $0, pagingInfo: .noMore)
            }
        }

        DocsLogger.info("start search collaborator using V2 API with query")

        var params = UniversalSearchParam.default
        // 可搜外部租户
        params.needSearchOuterTenant = true
        // 是否搜组织架构取决于入参
        params.includeDepartment = request.shouldSearchOrganzation
        // 是否搜用户组取决于入参
        params.includeUserGroup = request.shouldSearchUserGroup
        // 搜群
        params.includeChat = true
        // 搜人
        params.includeChatter = true
        // 不搜离职用户
        params.doNotSearchResignedUser = true
        // 不搜密聊
        params.includeCrypto = false
        // 可搜"外部群"，不可搜"未加入的公开群"
        params.incluedOuterChat = true

        return searchAPI.universalSearch(query: request.query,
                                         scene: .searchDocCollaborator,
                                         moreToken: request.pageToken,
                                         searchParam: params,
                                         authPermissions: [.checkBlock])
        .map { response in
            let pagingInfo: CollaboratorSearchResponse.PagingInfo
            if response.hasMore, let pageToken = response.moreToken {
                pagingInfo = .hasMore(pageToken: pageToken)
            } else {
                pagingInfo = .noMore
            }
            DocsLogger.info("universal search result count: \(response.results.count)")
            let collaborators = response.results.compactMap(Self.convert(searchResult:))
            return CollaboratorSearchResponse(collaborators: collaborators, pagingInfo: pagingInfo)
        }
        .asSingle()
    }

    static func convert(searchResult: SearchResultType) -> Collaborator? {
        let userID = searchResult.id
        let userName = searchResult.title.string
        guard let meta = searchResult.meta else {
            DocsLogger.error("meta not found when convert search result")
            return nil
        }
        // 提前 switch 决定基础类型
        let collaboratorType: CollaboratorType
        switch meta {
        // 人
        case let .chatter(chatterMeta):
            collaboratorType = .user
        // 群
        case let .chat(chatMeta):
            collaboratorType = .group
        // 组织架构
        case let .department(departmentMeta):
            collaboratorType = .organization
        // 用户组
        case let .userGroup(userGroupMeta):
            collaboratorType = .userGroup
        case let .userGroupAssign(userGroupMeta):
            collaboratorType = .userGroupAssign
        default:
            DocsLogger.error("unsupport meta found when convert search result")
            spaceAssertionFailure("unsupport meta found when convert search result")
            return nil
        }

        let collaborator = Collaborator(rawValue: collaboratorType.rawValue,
                                        userID: userID,
                                        name: userName,
                                        avatarURL: "",
                                        avatarImage: nil,
                                        imageKey: searchResult.avatarKey,
                                        userPermissions: UserPermissionMask(),
                                        groupDescription: nil)
        collaborator.v2SearchSubTitle = searchResult.summary.string
        // 这里给一些特化字段赋值
        switch meta {
        // 人
        case let .chatter(chatterMeta):
            collaborator.tenantID = chatterMeta.tenantID
            let currentUserResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            let userService = try? currentUserResolver.resolve(type: PassportUserService.self)
            let currentUserTenantId = userService?.user.tenant.tenantID
            collaborator.isExternal = currentUserTenantId != chatterMeta.tenantID
            collaborator.enterpriseEmail = chatterMeta.enterpriseEmail
            // 取第一个有内容的 tag
            let tag = chatterMeta.relationTag.tagDataItems.first {
                $0.respTagType != .relationTagUnset && !$0.textVal.isEmpty
            }
            collaborator.organizationTagValue = tag?.textVal
            let actionTypeValue = Int32(Basic_V1_Auth_ActionType.checkBlock.rawValue) ?? 0
            let deniedReason = chatterMeta.deniedReason[actionTypeValue]
            switch deniedReason {
            case .blocked:
                collaborator.blockStatus = .blockThisUser
            case .beBlocked:
                collaborator.blockStatus = .blockedByThisUser
            @unknown default: break
            }
        // 群
        case let .chat(chatMeta):
            collaborator.isCrossTenant = chatMeta.isCrossTenant
            collaborator.userCount = Int(chatMeta.userCountWithBackup)
            let tag = chatMeta.relationTag.tagDataItems.first {
                $0.respTagType != .relationTagUnset && !$0.textVal.isEmpty
            }
            collaborator.organizationTagValue = tag?.textVal
            collaborator.v2SearchSubTitle = chatMeta.description
            collaborator.groupDescription = chatMeta.description
            collaborator.isUserCountVisible = chatMeta.isUserCountVisible
        // 动态用户组
        case let .userGroup(userGroupMeta):
            collaborator.name = userGroupMeta.name
        //静态用户组
        case let .userGroupAssign(userGroupMeta):
            collaborator.name = userGroupMeta.name
        // 组织架构
        case let .department(departmentMeta):
            break
        default:
            DocsLogger.error("unsupport meta found when convert search result")
            spaceAssertionFailure("unsupport meta found when convert search result")
            return nil
        }
        return collaborator
    }
}
#endif

public final class CollaboratorSearchAPIImpl: CollaboratorSearchAPI {

    let searchAPI: CollaboratorSearchAPI

    public init(resolver: Resolver) {
        #if MessengerMod
        if let searchAPI = resolver.resolve(SearchAPI.self) {
            DocsLogger.info("search collaborator using V2 API")
            self.searchAPI = CollaboratorUniversalSearchAPI(searchAPI: searchAPI)
        } else {
            DocsLogger.info("search collaborator using legacy API for FG off")
            self.searchAPI = LegacyCollaboratorSearchAPI()
        }
        #else
        DocsLogger.info("search collaborator using legacy API for docs demo")
        self.searchAPI = LegacyCollaboratorSearchAPI()
        #endif
    }

    public func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse> {
        searchAPI.search(request: request)
    }
}
