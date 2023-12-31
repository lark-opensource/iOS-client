//
//  CollaboratorSearchViewModel.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/23.
//

import Foundation
import SKFoundation
import SwiftyJSON
import RxSwift
import RxCocoa
import SKResource
import SKInfra


struct VisibleDepartmentResponse: Codable {
    let visibleDepartments: [DepartmentInfo]
    let visibleTopUsersOfDepartments: [EmployeeInfo]
    let hasMore: Bool

    var totalCounts: Int {
        return visibleDepartments.count + visibleTopUsersOfDepartments.count
    }

    enum CodingKeys: String, CodingKey {
        case visibleDepartments = "visible_departments"
        case visibleTopUsersOfDepartments = "visible_top_users_of_dep"
        case hasMore = "has_more"
    }

    init(visibleDepartments: [DepartmentInfo],
         visibleTopUsersOfDepartments: [EmployeeInfo],
         hasMore: Bool) {
        self.visibleDepartments = visibleDepartments
        self.visibleTopUsersOfDepartments = visibleTopUsersOfDepartments
        self.hasMore = hasMore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        visibleDepartments = try container.decode([DepartmentInfo].self, forKey: CodingKeys.visibleDepartments)
        visibleTopUsersOfDepartments = try container.decode([EmployeeInfo].self, forKey: CodingKeys.visibleTopUsersOfDepartments)
        hasMore = try container.decode(Bool.self, forKey: CodingKeys.hasMore)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(visibleDepartments, forKey: CodingKeys.visibleDepartments)
        try container.encode(visibleTopUsersOfDepartments, forKey: CodingKeys.visibleTopUsersOfDepartments)
        try container.encode(hasMore, forKey: CodingKeys.hasMore)
    }

    func merge(_ other: VisibleDepartmentResponse) -> VisibleDepartmentResponse {
        return VisibleDepartmentResponse(visibleDepartments: self.visibleDepartments + other.visibleDepartments,
                                         visibleTopUsersOfDepartments: self.visibleTopUsersOfDepartments + other.visibleTopUsersOfDepartments,
                                         hasMore: other.hasMore)
    }
}

enum OrganizationSearchError: Error {
    case searchFailed
}

enum OrganizationSearchNoResultType {
    case noResult                       // 部门内无成员
    case adminClose                     // 当前企业管理员设置为不可见组织架构，如需修改请联系管理员

    var description: String {
        switch self {
        case .adminClose:
            return BundleI18n.SKResource.Doc_Permission_RootDepNoMemberDesc
        case .noResult:
            return BundleI18n.SKResource.Doc_Permission_NoMemberDesc
        }
    }
}

class OrganizationSearchViewModel {

    // Rx 驱动
    lazy var tableViewDriver: Driver<Result<Void, Error>> = {
        return updateTableViewSubject.asDriver(onErrorJustReturn: .failure(OrganizationSearchError.searchFailed))
    }()
    lazy var noResultDriver: Driver<OrganizationSearchNoResultType?> = {
        return noResultSubject.asDriver(onErrorJustReturn: nil)
    }()
    lazy var breadcrumbsViewDriver: Driver<DepartmentInfo?> = {
        return updateBreadcrumbsViewSubject.asDriver(onErrorJustReturn: nil)
    }()
    private let updateTableViewSubject = PublishSubject<Result<Void, Error>>()
    private let updateAvatarBarSubject = PublishSubject<Void>()
    private let updateBreadcrumbsViewSubject = PublishSubject<DepartmentInfo?>()
    private let noResultSubject = PublishSubject<OrganizationSearchNoResultType?>()

    // 数据源
    var datas: [OrganizationCellItem] = [] {
        didSet {
            self.updateTableViewSubject.onNext(.success(()))
        }
    }
    var collaborators: [Collaborator] = []
    var selectedItems: [Collaborator] = []
    @available(*, deprecated, message: "use existedCollaboratorsV2 instead")
    private var existedCollaborators: [Collaborator] = []
    private var existedCollaboratorsV2: Set<Collaborator> = []
    // key: DepartmentId value: 子部门数据
    private var organizationMaps: [String: VisibleDepartmentResponse] = [:]

    // 网络
    private var searchVisibleDepartmentRequest: DocsRequest<JSON>?
    private let backgroundQueue = DispatchQueue(label: "CollaboratorSearchViewModel")

    var userPermissions: UserPermissionAbility?
    var publicPermisson: PublicPermissionMeta?
    private(set) var fileModel: CollaboratorFileModel
    private var batchQueryRequest: DocsRequest<JSON>?
    
    public private(set) var isBitableAdvancedPermissions: Bool = false
    private(set) var bitablePermissonRule: BitablePermissionRule?
    
    let isEmailSharingEnabled: Bool

    init(existedCollaborators: [Collaborator],
         selectedItems: [Collaborator],
         fileModel: CollaboratorFileModel,
         userPermissions: UserPermissionAbility?,
         publicPermisson: PublicPermissionMeta?,
         isBitableAdvancedPermissions: Bool = false,
         bitablePermissonRule: BitablePermissionRule? = nil,
         isEmailSharingEnabled: Bool = false) {
        self.existedCollaborators = existedCollaborators
        self.existedCollaboratorsV2 = Set<Collaborator>(existedCollaborators)
        self.selectedItems = selectedItems
        self.userPermissions = userPermissions
        self.publicPermisson = publicPermisson
        self.fileModel = fileModel
        self.isBitableAdvancedPermissions = isBitableAdvancedPermissions
        self.bitablePermissonRule = bitablePermissonRule
        self.isEmailSharingEnabled = isEmailSharingEnabled
    }
    
    func getExistedCollaborators() -> [Collaborator] {
        return Array(existedCollaboratorsV2)
    }

    // 查询下级组织架构
    func searchVisibleDepartment(departmentInfo: DepartmentInfo) {
        // 先查内存缓存，没有才发网络请求
        if let response = organizationMaps[departmentInfo.id] {
            updateDatas(response, requestDepartmentInfo: departmentInfo)
            updateBreadcrumbsViewSubject.onNext(departmentInfo)
        } else {
            searchVisibleDepartmentCore(departmentId: departmentInfo.id, offset: 0, count: 50) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.batchQueryCollaboratorsExist(response: response) { [weak self] in
                        guard let self = self else { return }
                        self.organizationMaps[departmentInfo.id] = response
                        self.updateDatas(response, requestDepartmentInfo: departmentInfo)
                        self.updateBreadcrumbsViewSubject.onNext(departmentInfo)
                    }
                case .failure(let error):
                    self.updateTableViewSubject.onNext(.failure(error))
                }
            }
        }
    }

    // 上滑搜索更多
    func loadMoreVisibleDepartment(departmentInfo: DepartmentInfo) {
        let id = departmentInfo.id
        guard let oldResponse = organizationMaps[id] else {
            DocsLogger.error("can't find childDatas in \(id)")
            return
        }
        guard oldResponse.hasMore else {
            DocsLogger.error("no more datas")
            return
        }
        searchVisibleDepartmentCore(offset: oldResponse.totalCounts, count: 50) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.batchQueryCollaboratorsExist(response: response) { [weak self] in
                    guard let self = self else { return }
                    let newResponse = oldResponse.merge(response)
                    self.organizationMaps[id] = newResponse
                    self.organizationMaps[id] = newResponse
                    self.updateDatas(newResponse, requestDepartmentInfo: departmentInfo)
                }
            case .failure(let error):
                self.updateTableViewSubject.onNext(.failure(error))
            }
        }
    }

    /// 搜索可见的组织架构
    /// 接口文档：https://bytedance.feishu.cn/docs/doccn6c3U8R8sgxVnn8O7MZocnc#
    /// - Parameters:
    ///   - departmentID: 部门ID，顶级部门需传0
    ///   - offset: 偏移量，从0开始
    ///   - count: 单次查询的数量
    private func searchVisibleDepartmentCore(departmentId: String = DepartmentInfo.rootDepartmentId,
                                             offset: Int,
                                             count: Int,
                                             completionHandler: @escaping (Result<VisibleDepartmentResponse, Error>) -> Void) {
        searchVisibleDepartmentRequest?.cancel()
        searchVisibleDepartmentRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.searchVisibleDepartment + "?department_id=\(departmentId)&visible_type=3&offset=\(offset)"
            + "&count=\(count)&need_paging=true", params: nil)
        .set(method: .GET)
        .set(timeout: 20)
        .set(needVerifyData: false)
        .start(callbackQueue: backgroundQueue, result: { (json, error) in
            guard error == nil else {
                DocsLogger.error("error", error: error)
                if (error as? URLError)?.errorCode != NSURLErrorCancelled {
                    DispatchQueue.main.async {
                        completionHandler(.failure(OrganizationSearchError.searchFailed))
                    }
                    return
                }
                return
            }
            guard let json = json else {
                DocsLogger.error("error")
                DispatchQueue.main.async {
                    completionHandler(.failure(OrganizationSearchError.searchFailed))
                }
                return
            }
            guard let code = json["code"].int else {
                DocsLogger.error("code is nil")
                DispatchQueue.main.async {
                    completionHandler(.failure(OrganizationSearchError.searchFailed))
                }
                return
            }
            guard code == 0 else {
                DocsLogger.error("error code is \(code)")
                DispatchQueue.main.async {
                    completionHandler(.failure(OrganizationSearchError.searchFailed))
                }
                return
            }
            let jsonData = json["data"]
            guard let data = try? jsonData.rawData(),
                let visibleDepartmentResponse = try? JSONDecoder().decode(VisibleDepartmentResponse.self, from: data) else {
                    DispatchQueue.main.async {
                        completionHandler(.failure(OrganizationSearchError.searchFailed))
                    }
                    return
            }
            DispatchQueue.main.async {
                completionHandler(.success(visibleDepartmentResponse))
            }
        })
    }

    private func batchQueryCollaboratorsExist(response: VisibleDepartmentResponse, complete: (() -> Void)?) {
        let tempDatas: [OrganizationCellItem] = response.visibleDepartments + response.visibleTopUsersOfDepartments
        collaborators = tempDatas.map { $0.collaborator }
        let type = fileModel.docsType.rawValue
        let token = fileModel.objToken
        if fileModel.isFolder && fileModel.spaceSingleContainer {
            batchQueryRequest = PermissionManager.batchQueryCollaboratorsExistForFolder(token: token, candidates: Set(collaborators)) { [weak self] (result, error) in
                guard let self = self else { return }
                guard let result = result, error == nil else {
                    complete?()
                    return
                }
                self.existedCollaboratorsV2.formUnion(Set(result))
                complete?()
            }
        } else {
            batchQueryRequest = PermissionManager.batchQueryCollaboratorsExist(type: type, token: token, candidates: Set(collaborators)) { [weak self] (result, error) in
                guard let self = self else { return }
                guard let result = result, error == nil else {
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
    
    func jumpToCurrentDepartment(_ department: DepartmentInfo) {
        guard let childDatas = organizationMaps[department.id] else {
            DocsLogger.error("找不到\(department.id)对应的子部门数据")
            return
        }
        updateDatas(childDatas, requestDepartmentInfo: department)
    }

    func collaboratorDatasConversion() {
        dataConversion(self.datas)
    }

    private func updateDatas(_ response: VisibleDepartmentResponse, requestDepartmentInfo: DepartmentInfo) {
        let tempDatas: [OrganizationCellItem] = response.visibleDepartments + response.visibleTopUsersOfDepartments
        collaborators = tempDatas.map { $0.collaborator }
        dataConversion(tempDatas)
        handleNoResultIfNeed(requestDepartmentInfo: requestDepartmentInfo)
    }

    private func dataConversion(_ items: [OrganizationCellItem]) {
        // 搜索结果可能已经被添加为了协作者，需要更新状态
        self.datas = items.map { (info) -> OrganizationCellItem in
            var info = info
            info.isExist = false
            // 已经选择了的协作者
            if (selectedItems.firstIndex(where: { (collaborator) -> Bool in
                return collaborator.userID == info.id
            }) != nil) {
                info.selectType = .blue
            } else if info.id == User.current.info?.userID {
                // 当前用户
                info.selectType = .hasSelected
            } else if existedCollaborators.first(where: { $0.userID == info.id }) != nil {
                // 当前用户
                info.selectType = .hasSelected
                info.isExist = true
            } else if info.id == fileModel.ownerID {
                // Owner
                info.selectType = .hasSelected
            } else {
                info.selectType = .gray
            }
            return info
        }
    }

    private func handleNoResultIfNeed(requestDepartmentInfo: DepartmentInfo) {
        guard self.datas.isEmpty else { return }
        if requestDepartmentInfo.id == DepartmentInfo.rootDepartmentId {
            // 根部门返回空，说明管理员后台关闭了组织架构的可见性
            noResultSubject.onNext(.adminClose)
        } else {
            noResultSubject.onNext(.noResult)
        }
    }
}
