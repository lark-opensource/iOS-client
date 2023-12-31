//
//  UserGroupSearchViewModel.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/1/11.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import SKFoundation
import SwiftyJSON
import SKResource

extension UserGroupSearchViewModel {
    enum State {
        case success
        case networkFailure
        case emptyList
    }
}

class UserGroupSearchViewModel {
    // 预先拉取好的用户组协作者列表
    let userGroups: [Collaborator]
    // 选中的协作者，展示在 UI 上方
    var selectedCollaborators: [Collaborator]
    // 已存在的协作者，用于置灰列表中的协作者，避免重复选中
    @available(*, deprecated, message: "use existedCollaboratorsV2 instead")
    private var existedCollaborators: [Collaborator]
    private var existedCollaboratorsV2: Set<Collaborator> = []

    private let stateRelay = PublishRelay<State>()
    var stateChanged: Signal<State> {
        stateRelay.asSignal()
    }

    private let itemRelay = BehaviorRelay<[UserGroupItem]>(value: [])
    var items: [UserGroupItem] { itemRelay.value }
    var itemUpdated: Driver<[UserGroupItem]> {
        itemRelay.asDriver().skip(1)
    }

    private let disposeBag = DisposeBag()

    // 从外部透传
    let userPermission: UserPermissionAbility?
    let publicPermission: PublicPermissionMeta?
    let fileModel: CollaboratorFileModel
    let shouldCheckIsExisted: Bool
    let isBitableAdvancedPermissions: Bool
    let bitablePermissionRule: BitablePermissionRule?
    
    let isEmailSharingEnabled: Bool

    init(userGroups: [Collaborator],
         existedCollaborators: [Collaborator],
         selectedCollaborators: [Collaborator],
         fileModel: CollaboratorFileModel,
         userPermission: UserPermissionAbility?,
         publicPermission: PublicPermissionMeta?,
         shouldCheckIsExisted: Bool,
         isBitableAdvancedPermissions: Bool,
         bitablePermissionRule: BitablePermissionRule?,
         isEmailSharingEnabled: Bool) {
        self.userGroups = userGroups
        self.existedCollaborators = existedCollaborators
        self.existedCollaboratorsV2 = Set<Collaborator>(existedCollaborators)
        self.selectedCollaborators = selectedCollaborators
        self.userPermission = userPermission
        self.publicPermission = publicPermission
        self.fileModel = fileModel
        self.shouldCheckIsExisted = shouldCheckIsExisted
        self.isBitableAdvancedPermissions = isBitableAdvancedPermissions
        self.bitablePermissionRule = bitablePermissionRule
        self.isEmailSharingEnabled = isEmailSharingEnabled
    }
    
    func getExistedCollaborators() -> [Collaborator] {
        return Array(existedCollaboratorsV2)
    }

    func reloadData() {
        batchQueryUserGroupsIsExisted(candidates: userGroups)
            .subscribe { [weak self] in
                guard let self = self else { return }
                let items = self.generateItems()
                self.itemRelay.accept(items)
                if items.isEmpty {
                    self.stateRelay.accept(.emptyList)
                } else {
                    self.stateRelay.accept(.success)
                }
            } onError: { [weak self] error in
                DocsLogger.error("check is user group existed failed", error: error)
                self?.stateRelay.accept(.networkFailure)
            }
            .disposed(by: disposeBag)
    }
    
    func reloadDataForUnitTest() -> Completable {
        return batchQueryUserGroupsIsExisted(candidates: userGroups)
    }

    func updateData() {
        let items = generateItems()
        itemRelay.accept(items)
    }

    private func batchQueryUserGroupsIsExisted(candidates: [Collaborator]) -> Completable {
        guard fileModel.wikiV2SingleContainer || shouldCheckIsExisted else {
            return .empty()
        }
        let type = fileModel.docsType.rawValue
        let token = fileModel.objToken
        if fileModel.isFolder, fileModel.spaceSingleContainer {
            return Completable.create { [weak self] observer in
                let request = PermissionManager.batchQueryCollaboratorsExistForFolder(token: token, candidates: Set(candidates)) { result, error in
                    if let error = error {
                        DocsLogger.error("batch query user group is exist failed", error: error)
                        observer(.completed)
                        return
                    }
                    guard let self = self else { return }
                    guard let result = result else {
                        DocsLogger.error("batch query user group is exist failed, no result found", error: error)
                        observer(.completed)
                        return
                    }
                    self.existedCollaboratorsV2.formUnion(Set<Collaborator>(result))
                    observer(.completed)
                }
                return Disposables.create {
                    request.cancel()
                }
            }
        } else {
            return Completable.create { [weak self] observer in
                let request = PermissionManager.batchQueryCollaboratorsExist(type: type, token: token, candidates: Set(candidates)) { result, error in
                    if let error = error {
                        DocsLogger.error("batch query user group is exist failed", error: error)
                        observer(.completed)
                        return
                    }
                    guard let self = self else { return }
                    guard let result = result else {
                        DocsLogger.error("batch query user group is exist failed, no result found", error: error)
                        observer(.completed)
                        return
                    }
                    if self.isBitableAdvancedPermissions {
                        // Bitable 高级权限中，文档协作者 != 角色组成员，只能筛选出协作者中的 FA 将其禁用掉
                        // 这里最好是有个后端接口，区分开高级权限场景和普通添加协作者的场景
                        self.existedCollaboratorsV2.formUnion(Set(result).filter({ $0.userPermissions.isFA }))
                    } else {
                        self.existedCollaboratorsV2.formUnion(Set<Collaborator>(result))
                    }
                    observer(.completed)
                }
                return Disposables.create {
                    request.cancel()
                }
            }
        }
    }

    private func generateItems() -> [UserGroupItem] {
        let items = userGroups.map { userGroup -> UserGroupItem in
            var item = UserGroupItem(groupID: userGroup.userID, name: userGroup.name, selectType: .gray, isExist: false)
            let exist = self.existedCollaboratorsV2.contains(userGroup)
            if selectedCollaborators.contains(where: { $0.userID == userGroup.userID }) {
                // 已经选中
                item.selectType = .blue
            } else if (fileModel.wikiV2SingleContainer || shouldCheckIsExisted), exist {
                // 已是协作者
                item.selectType = .hasSelected
                item.isExist = true
            } else if userGroup.userID == fileModel.ownerID {
                // 是 owner，不过用户组不太可能是 owner
                item.selectType = .hasSelected
            } else {
                // 默认未选中状态
                item.selectType = .gray
            }
            return item
        }
        return items
    }
}
