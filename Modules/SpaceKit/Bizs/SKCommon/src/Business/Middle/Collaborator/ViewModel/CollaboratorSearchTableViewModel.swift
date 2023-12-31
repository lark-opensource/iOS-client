//
//  CollaboratorSearchTableViewModel.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/16.
//

import Foundation
import SKFoundation
import SwiftyJSON
import RxSwift
import RxCocoa
import SKResource
import SKInfra
import SpaceInterface

protocol CollaboratorSearchTableViewModelDelegate: AnyObject {
    func collaboratorSearched(_ viewModel: CollaboratorSearchTableViewModel, didUpdateWithSearchResults searchResults: [Collaborator]?, error: Error?)
    func collaboratorInvited(_ viewModel: CollaboratorSearchTableViewModel, didUpdateWithSelectedItems selectedItems: [Collaborator])
}

class CollaboratorSearchTableViewModel {

    // 当前搜索的关键字
    var query: String?
    // Model
    var datas = [CollaboratorSearchResultCellItem]()
    var searchResults = [Collaborator]() {
        didSet {
            self.reloadDatas()
        }
    }
    private var pagingInfo = CollaboratorSearchResponse.PagingInfo.noMore
    var hasMore: Bool {
        if case .hasMore = pagingInfo {
            return true
        }
        return false
    }
    @available(*, deprecated, message: "use existedCollaboratorsV2 instead")
    private var existedCollaborators: [Collaborator] = []
    private var existedCollaboratorsV2: Set<Collaborator> = []
    var selectedItems = [Collaborator]() {
        didSet {
            self.datas = self.mapToCollaboratorCellItem(searchResults)
            self.delegate?.collaboratorInvited(self, didUpdateWithSelectedItems: selectedItems)
        }
    }
    var objToken: String
    var docsType: ShareDocsType
    var ownerId: String
    var wikiV2SingleContainer: Bool
    var spaceSingleContainer: Bool
    var isBitableAdvancedPermissions: Bool
    var isEmailSharingEnabled: Bool
    var emailCollaboratorCount: Int {
        return selectedItems.filter({ $0.type == .email }).count
    }
    var canInviteEmailCollaborator: Bool = false
    var adminCanInviteEmailCollaborator: Bool = false
    
    // Network
    private var batchQueryRequest: DocsRequest<JSON>?

    private let statistics: CollaboratorStatistics?
    weak var delegate: CollaboratorSearchTableViewModelDelegate?
    weak var followAPIDelegate: BrowserVCFollowDelegate?
    var searchConfig: CollaboratorSearchConfig
    
    /// 知识库成员
    let wikiMembers: [Collaborator]?

    private let searchAPI: CollaboratorSearchAPI
    private var searchBag = DisposeBag()
    private var isSearching = false

    public init(objToken: String,
                docsType: ShareDocsType,
                wikiV2SingleContainer: Bool,
                spaceSingleContainer: Bool,
                isBitableAdvancedPermissions: Bool,
                ownerId: String,
                existedCollaborators: [Collaborator],
                selectedItems: [Collaborator],
                wikiMembers: [Collaborator]? = nil,
                statistics: CollaboratorStatistics? = nil,
                searchConfig: CollaboratorSearchConfig,
                searchAPI: CollaboratorSearchAPI? = nil,
                isEmailSharingEnabled: Bool = false,
                canInviteEmailCollaborator: Bool = false,
                adminCanInviteEmailCollaborator: Bool = false,
                followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        self.objToken = objToken
        self.docsType = docsType
        self.existedCollaborators = existedCollaborators
        self.existedCollaboratorsV2 = Set(existedCollaborators)
        self.selectedItems = selectedItems
        self.statistics = statistics
        self.searchConfig = searchConfig
        self.ownerId = ownerId
        self.wikiV2SingleContainer = wikiV2SingleContainer
        self.spaceSingleContainer = spaceSingleContainer
        self.isBitableAdvancedPermissions = isBitableAdvancedPermissions
        self.wikiMembers = wikiMembers
        self.isEmailSharingEnabled = isEmailSharingEnabled
        self.canInviteEmailCollaborator = canInviteEmailCollaborator
        self.adminCanInviteEmailCollaborator = adminCanInviteEmailCollaborator
        self.followAPIDelegate = followAPIDelegate

        if let searchAPI {
            // 提供单测注入
            self.searchAPI = searchAPI
        } else {
            self.searchAPI = DocsContainer.shared.resolve(CollaboratorSearchAPI.self) ?? LegacyCollaboratorSearchAPI()
        }
    }

    func searchCollaborator(with query: String, completionHandler: (([Collaborator]) -> Void)? = nil) {
        searchBag = DisposeBag()
        self.query = query
        isSearching = true
        let request = CollaboratorSearchRequest(query: query,
                                                pageToken: nil,
                                                count: 10,
                                                objToken: objToken,
                                                objTypeValue: docsType.rawValue,
                                                shouldSearchOrganzation: searchConfig.shouldSearchOrganization,
                                                shouldSearchUserGroup: searchConfig.shouldSearchUserGroup)
        searchAPI.search(request: request)
        .map({ [weak self] response -> [Collaborator] in
            guard let self else { return [] }
            var items = response.collaborators
            // 这里应该由后端返回「知识库管理员」和「知识库成员」两个用户组，但是后端支持周期太长，客户端先临时支持
            // 只有首次进入触发搜索时候（query=""），将管理员和成员置顶
            if query.isEmpty, self.isBitableAdvancedPermissions {
                if let wikiMembers = self.wikiMembers, !wikiMembers.isEmpty {
                    items.removeAll(where: { $0.type == .newWikiMember })
                    items.insert(contentsOf: wikiMembers, at: 0)
                }
            }
            self.pagingInfo = response.pagingInfo
            return items
        })
        .flatMap({ [weak self] items -> Single<[Collaborator]> in
            guard let self = self else { return .just(items) }
            if self.isEmailSharingEnabled {
                return self.inviteEmailCollaborator(items: items, query: query)
            }
            return .just(items)
        })
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(onSuccess: { [weak self] items in
            guard let self else { return }
            defer {
                self.isSearching = false
            }
            self.batchQueryCollaboratorsExist(collaborators: items) { [weak self] in
                guard let self = self else { return }
                self.searchResults = items
                completionHandler?(self.searchResults)
                self.statistics?.clickSearchInviter(resultUserIds: self.searchResults.map({ $0.userID }),
                                                    resultUserTypes: self.searchResults.map({ ($0.accountType?.rawValue ?? "chat_group") }),
                                                    searchType: .nickname)
            }
        }, onError: { [weak self] error in
            guard let self else { return }
            defer {
                self.isSearching = false
            }
            DocsLogger.error("searchCollaboratorCandidatesRequest failed!", error: error)
            self.delegate?.collaboratorSearched(self, didUpdateWithSearchResults: nil, error: error)
            completionHandler?(self.searchResults)
        })
        .disposed(by: searchBag)
    }
    
    private func batchQueryCollaboratorsExist(collaborators: [Collaborator], isMore: Bool = false, complete: (() -> Void)?) {
        if docsType == .folder {
            batchQueryRequest = PermissionManager.batchQueryCollaboratorsExistForFolder(token: objToken, candidates: Set(collaborators)) { [weak self] (result, error) in
                guard let self = self else { return }
                guard let result = result,
                      error == nil else {
                    complete?()
                    return
                }
                self.existedCollaboratorsV2.formUnion(Set(result))
                complete?()
            }
        } else {
            batchQueryRequest = PermissionManager.batchQueryCollaboratorsExist(type: docsType.rawValue, token: objToken, candidates: Set(collaborators)) { [weak self] (result, error) in
                guard let self = self else { return }
                guard var result = result, error == nil else {
                    complete?()
                    return
                }
                if self.isBitableAdvancedPermissions {
                    // Bitable 高级权限中，是文档协作者 != 是角色组成员，只能筛选出协作者中的 FA 将其禁用掉
                    // 这里最好是有个后端接口，区分开高级权限场景和普通添加协作者的场景
                    self.existedCollaboratorsV2.formUnion(Set(result).filter({ $0.userPermissions.isFA }))
                } else {
                    self.existedCollaboratorsV2.formUnion(Set(result))
                }
                complete?()
            }
        }
    }
    
    private func inviteEmailCollaborator(items: [Collaborator], query: String) -> Single<[Collaborator]> {
        guard checkEmail(email: query) else {
            DocsLogger.info("inviteEmailCollaborator: the query is't email")
            return .just(items)
        }
        let containsEmail = items.contains(where: { $0.enterpriseEmail == query })
        if containsEmail {
            DocsLogger.info("inviteEmailCollaborator: containsEmail is true")
            return .just(items)
        }
        return PermissionManager.generateEmailInfo(type: docsType.rawValue, token: objToken, email: query).map { ownerId in
            if let ownerId = ownerId {
                let emailCollaborator = Collaborator(rawValue: 29, userID: ownerId, name: query, avatarURL: "", avatarImage: nil, userPermissions: UserPermissionMask(rawValue: 1), groupDescription: nil)
                emailCollaborator.emailDescription = BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_Note_Descrip()
                emailCollaborator.isExternal = true
                return items + [emailCollaborator]
            }
            return items
        }.catchErrorJustReturn(items)
    }
    
    private func checkEmail(email: String) -> Bool {
        guard let emailAddressRegex = SettingConfig.emailValidateRegular?["email_reg"] as? String else {
            DocsLogger.info("SettingConfig email_reg is nil")
            let emailAddressRegex = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
            return email.isMatch(for: emailAddressRegex)
        }
        let isEmail = email.isMatch(for: emailAddressRegex)
        let info = "checkEmail:" + email + (isEmail ? "is" : "is't") + "email"
        DocsLogger.info(info)
        return isEmail
    }

    // 将后台数据转换为UI数据
    private func mapToCollaboratorCellItem(_ searchResults: [Collaborator]) -> [CollaboratorSearchResultCellItem] {
        for item in searchResults {
            item.blockExternal = false
            item.isExist = isExist(collaborator: item)
        }
        return searchResults.map {
            return CollaboratorSearchResultCellItem(collaboratorID: $0.userID,
                                                    selectType: getSelectType(with: $0),
                                                    imageURL: $0.avatarURL,
                                                    imageKey: $0.imageKey,
                                                    title: $0.name,
                                                    detail: getDetail(with: $0),
                                                    isExternal: $0.isExternal,
                                                    blockExternal: $0.blockExternal,
                                                    isCrossTenanet: $0.isCrossTenant,
                                                    roleType: $0.type,
                                                    isExist: $0.isExist,
                                                    userCount: $0.userCount,
                                                    canShowMemberCount: $0.isUserCountVisible,
                                                    organizationTagValue: $0.organizationTagValue)
        }
    }
    
    private func isExist(collaborator: Collaborator) -> Bool {
        if collaborator.type == .email {
            return false
        }
        return existedCollaboratorsV2.contains(collaborator)
    }

    private func getSelectType(with collaborator: Collaborator) -> SelectType {
        let selectType: SelectType
        if selectedItems.contains(collaborator) {
            selectType = .blue
        } else if collaborator.userID == User.current.info?.userID {
            // 当前用户不可再次邀请
            selectType = .hasSelected
        } else if collaborator.isExist {
            // 已经在协作者列表
            selectType = .hasSelected
        } else if collaborator.userID == ownerId {
            // Owner不可再次邀请
            selectType = .hasSelected
        } else if (collaborator.isExternal || collaborator.isCrossTenant) && (searchConfig.inviteExternalOption == .none) {
            // wiki2.0不支持邀请外部协作者
            selectType = .disable
        } else if (collaborator.isExternal || collaborator.isCrossTenant) && (searchConfig.inviteExternalOption == .userOnly) && collaborator.type != .user {
            // 禁止邀请外部非 user 协作者
            selectType = .disable
        } else if collaborator.blockStatus != .none {
            // 存在屏蔽关系的用户也不可以邀请
            selectType = .disable
        } else if collaborator.type == .email {
            if (!canInviteEmailCollaborator || !adminCanInviteEmailCollaborator || emailCollaboratorCount == 10) {
                selectType = .disable
            } else {
                selectType = .none
            }
        } else {
            selectType = .gray
        }
        return selectType
    }

    private func getDetail(with collaborator: Collaborator) -> String? {
        if let subTitleFromSearch = collaborator.v2SearchSubTitle, !subTitleFromSearch.isEmpty {
            return subTitleFromSearch
        }
        let detail: String?
        switch collaborator.type {
        case .user:
            detail = collaborator.departmentName
        case .group:
            detail = !collaborator.groupDescription.isEmpty ? collaborator.groupDescription : BundleI18n.SKResource.Doc_Facade_NoGroupDesc
        case .newWikiAdmin, .newWikiMember, .newWikiEditor:
            detail = collaborator.wikiDescription
        case .email:
            detail = collaborator.emailDescription
        default:
            detail = nil
        }
        return detail
    }

    func updateSearchRequest(query: String, completion: ((Error?) -> Void)? = nil) {
        if isSearching { return }
        guard case let .hasMore(pageToken) = pagingInfo else { return }
        self.query = query
        isSearching = true
        let request = CollaboratorSearchRequest(query: query,
                                                pageToken: pageToken,
                                                count: 10,
                                                objToken: objToken,
                                                objTypeValue: docsType.rawValue,
                                                shouldSearchOrganzation: searchConfig.shouldSearchOrganization,
                                                shouldSearchUserGroup: searchConfig.shouldSearchUserGroup)
        searchAPI.search(request: request)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] response in
            guard let self = self else { return }
            defer {
                self.isSearching = false
            }
            self.pagingInfo = response.pagingInfo
            if response.collaborators.isEmpty {
                return
            }
            self.batchQueryCollaboratorsExist(collaborators: response.collaborators, isMore: true) { [weak self] in
                guard let self = self else { return }
                self.searchResults += response.collaborators
                completion?(nil)
            }
        } onError: { [weak self] error in
            guard let self = self else { return }
            defer {
                self.isSearching = false
            }
            DocsLogger.info(error.localizedDescription)
            completion?(error)
        }
        .disposed(by: searchBag)
    }

    func reloadDatas() {
        self.datas = self.mapToCollaboratorCellItem(searchResults)
        self.delegate?.collaboratorSearched(self, didUpdateWithSearchResults: searchResults, error: nil)
    }
}
