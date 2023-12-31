//
//  V3ListShareViewModel.swift
//  Todo
//
//  Created by GCW on 2022/11/30.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import ThreadSafeDataStructure
import LarkAccountInterface
import LKCommonsLogging
import TodoInterface
import UniverseDesignIcon

struct V3ListShareViewData {
    // cell数据信息
    var cellItem: [TaskMemberCellData]
    // 协作人总数量
    var totalCount: Int64?
    // 目前不使用此title，无相关文案
    var title: String? {
        guard let totalCount = totalCount, totalCount > 0 else { return nil }
        return String(totalCount)
    }
    var state: V3ListShareViewDataState = .refresh

    enum V3ListShareViewDataState {
        case refresh
        case dismiss
    }
}

struct TaskMemberCellData {
    enum IconType {
        case avatar(AvatarSeed)
        case icon(UIImage)
    }
    var identifier: String
    var name: String
    var leadingIcon: IconType
    // 角色对应的可操作点位
    var roleActionText: String
    // 是否可以编辑角色操作点为
    var canEditAction: Bool
    // 协作人类型
    var memberType: Rust.TaskMemberType
    // 角色
    var role: Rust.MemberRole
    
    var url: String?

}

struct MemberData {
    var userId: String
    var name: String
    var avatar: AvatarSeed
    var memberDepart: String
    var memberType: Rust.EntityType
}

final class V3ListShareViewModel: UserResolverWrapper {
    // view drivers
    let reloadNoti = BehaviorRelay<V3ListShareViewData>(value: .init(cellItem: [], totalCount: nil))
    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)
    let rxLoadMoreState = BehaviorRelay<ListLoadMoreState>(value: .none)
    let inviteNoti = BehaviorRelay<V3ListShareViewData>(value: .init(cellItem: [], totalCount: nil))

    private static let logger = Logger.log(V3ListShareViewModel.self, category: "Todo.V3ListShareViewModel")

    var taskListInput: Rust.TaskContainer
    var userResolver: LarkContainer.UserResolver
    private let scene: ListShareScene
    private let pageCount = 30
    private let disposeBag = DisposeBag()
    private var viewModelData: (lastPageToken: String, hasMore: Bool) = ("", false)

    // 当前角色
    lazy var currentRole: Rust.MemberRole = .none

    var currentUserId: String { userResolver.userID }

    @ScopedInjectedLazy private var listApi: TaskListApi?

    init(
        resolver: UserResolver,
        taskListInput: Rust.TaskContainer,
        scene: ListShareScene,
        invitorData: V3ListShareViewData? = nil,
        currentRole: Rust.MemberRole? = nil
    ) {
        self.userResolver = resolver
        self.taskListInput = taskListInput
        self.scene = scene

        // 初始化当前角色
        if let currentRole = currentRole {
            self.currentRole = currentRole
        } else {
            self.currentRole = Self.containerRole(taskListInput)
        }
        // 请求接口
        switch scene {
        case .manage:
            initFechData()
        case .share:
            guard let invitorData = invitorData else { return }
            inviteNoti.accept(invitorData)
        }
    }

    private func initFechData() {
        rxViewState.accept(.loading)
        listApi?.getPagingTaskListMembers(with: taskListInput.guid, cursor: "", count: pageCount)
            .take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] res in
                    guard let self = self else { return }
                    self.viewModelData = (res.lastToken, res.hasMore_p)
                    let viewData = V3ListShareViewData(cellItem: self.transformCellData(res.taskListMembers), totalCount: res.totalCount)
                    self.rxViewState.accept(viewData.cellItem.isEmpty ? .empty : .data)
                    self.rxLoadMoreState.accept(res.hasMore_p ? .hasMore : .noMore)
                    self.reloadNoti.accept(viewData)
                },
                onError: { err in
                    self.rxViewState.accept(.failed())
                    Self.logger.error("initFetchTaskListMembers err: \(err)")
                })
            .disposed(by: disposeBag)
    }


    func doLoadMoreTaskLists() {
        guard viewModelData.hasMore else { return }
        rxLoadMoreState.accept(.loading)
        listApi?.getPagingTaskListMembers(with: taskListInput.guid, cursor: viewModelData.lastPageToken, count: pageCount)
            .take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] res in
                    guard let self = self else { return }
                    self.appendToMemberList(res.taskListMembers)
                    self.viewModelData = (res.lastToken, res.hasMore_p)
                    if self.rxLoadMoreState.value != .none {
                        self.rxLoadMoreState.accept(res.hasMore_p ? .hasMore : .noMore)
                    }
                },
                onError: { [weak self] err in
                    self?.rxLoadMoreState.accept(.hasMore)
                    Self.logger.error("loadMoreTaskListMembers err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    private func appendToMemberList(_ members: [Rust.TaskListMember]) {
        guard !members.isEmpty else { return }
        var viewData = reloadNoti.value
        viewData.cellItem.append(contentsOf: transformCellData(members))
        self.reloadNoti.accept(viewData)
    }

    private func transformCellData(_ members: [Rust.TaskListMember]) -> [TaskMemberCellData] {

        let currentMember = members.first(where: { $0.member.user.userID == currentUserId})
        // 如果拉取到当前用户的权限，进行更新。用于本用户为所有者，并进行所有者移交时
        if let currentMember = currentMember {
            currentRole = currentMember.role
            // 如果是阅读角色，但当前清单的权限是编辑权限，那么需要覆盖。比如在群里面是编辑权限，但在清单里面是阅读权限
            if currentRole == .reader, taskListInput.isManageEditor {
                currentRole = .writer
            }
        }

        let cellDatas = members.compactMap { member -> TaskMemberCellData? in
            let memverVal = member.member
            var id: String = "", name: String = ""
            var leadingIcon: TaskMemberCellData.IconType = .icon(UIImage())
            switch memverVal.type {
            case .user:
                id = memverVal.user.userID
                name = memverVal.user.name
                leadingIcon = .avatar(AvatarSeed(avatarId: memverVal.user.userID, avatarKey: memverVal.user.avatarKey))
            case .group:
                id = memverVal.chat.chatID
                name = memverVal.chat.name
                leadingIcon = .avatar(AvatarSeed(avatarId: memverVal.chat.chatID, avatarKey: memverVal.chat.avatarKey))
            case .docs:
                id = memverVal.doc.id
                name = memverVal.doc.name
                if name.isEmpty {
                    name = memverVal.doc.hasPermission_p ? I18N.Todo_Doc_UntitledDocument_Title : I18N.Todo_Activities_DocNameUnauthorized_Text
                }
                leadingIcon = .icon(UDIcon.getIconByKey(.fileRoundDocxColorful, size: ListShare.Config.leadingIconSize))
            @unknown default: return nil
            }
            let role = transformPermissionsToRole(permissions: member.permissions)
            return TaskMemberCellData(
                identifier: id,
                name: name,
                leadingIcon: leadingIcon,
                roleActionText: member.role.roleActionText,
                canEditAction: canEditAction(from: role),
                memberType: memverVal.type,
                role: member.role,
                url: memverVal.doc.url
            )
        }
        return cellDatas
    }

    // MARK: - List DataSource

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfRows(in section: Int) -> Int {
        return scene == .manage ? reloadNoti.value.cellItem.count : inviteNoti.value.cellItem.count
    }

    func cellData(at indexPath: IndexPath) -> TaskMemberCellData? {
        switch scene {
        case .manage:
            guard indexPath.row >= 0 && indexPath.row < reloadNoti.value.cellItem.count else {
                assertionFailure()
                return nil
            }
            return reloadNoti.value.cellItem[indexPath.row]
        case .share:
            guard indexPath.row >= 0 && indexPath.row < inviteNoti.value.cellItem.count else {
                assertionFailure()
                return nil
            }
            return inviteNoti.value.cellItem[indexPath.row]
        }

    }
}

// MARK: - View Action
extension V3ListShareViewModel {

    func updateMemberPermission(updateMemberRole: Rust.MemberRole, memberId: String, entityType: Rust.TaskMemberType, completion: @escaping ((ListActionResult) -> Void)) {
        var updatedMember = [Int64: Rust.EntityTaskListMember]()
        var entity = Rust.EntityTaskListMember()
        entity.permission = {
            var permission = Rust.ContianerPermission()
            switch updateMemberRole {
            case .owner:
                permission.permissions = [Int32(Rust.PermissionAction.manageOwner.rawValue): true]
                entity.role = .owner
            case .writer:
                permission.permissions = [Int32(Rust.PermissionAction.manageEditor.rawValue): true]
                entity.role = .writer
            case .reader:
                permission.permissions = [Int32(Rust.PermissionAction.manageViewer.rawValue): true]
                entity.role = .reader
            case .inherit:
                permission.permissions = [Int32(Rust.PermissionAction.manageInherit.rawValue): true]
                entity.role = .inherit
            case .none:
                permission.permissions = [Int32(Rust.PermissionAction.unknownAction.rawValue): true]
                entity.role = .none
            @unknown default: break
            }
            return permission
        }()
        entity.memberID = memberId
        entity.type = entityType.toServerPB()
        if let intId = Int64(memberId) {
            updatedMember[intId] = entity
        }
        // 快速修改用户权限，无需note信息
        listApi?.updateTaskListMember(with: taskListInput.guid, updatedMembers: updatedMember, isSendNote: false, note: "")
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] result in
                if let intId = Int64(memberId) {
                    guard let memberRole = result.updatedMember[intId]?.role, let self = self else { return }
                    switch memberRole {
                        // 转移所有者后需要进行排序，其他权限变更与删除无须排序
                    case .owner:
                        if let currentIntId = Int64(self.currentUserId),
                           let currentMember = result.updatedMember[currentIntId]?.role,
                            currentMember == .writer {
                            var viewData = self.updateMemberCell(memberId: memberId, memberRole: .owner, preViewData: self.reloadNoti.value)
                            viewData = self.updateMemberCell(memberId: self.currentUserId, memberRole: .writer, preViewData: viewData)
                            guard var viewData = viewData else { return }
                            self.reloadNoti.accept(viewData)
                            completion(.succeed(toast: I18N.Todo_TaskListOwnershipTransferred_Title))
                        }
                    case .writer:
                        guard let viewData = self.updateMemberCell(memberId: memberId, memberRole: .writer) else { return }
                        self.reloadNoti.accept(viewData)
                        completion(.succeed(toast: I18N.Todo_TaskList_ChangePermissionForOthers_Toast))
                    case .reader:
                        guard let viewData = self.updateMemberCell(memberId: memberId, memberRole: .reader) else { return }
                        self.reloadNoti.accept(viewData)
                        completion(.succeed(toast: I18N.Todo_TaskList_ChangePermissionForOthers_Toast))
                    case .inherit:
                        guard let viewData = self.updateMemberCell(memberId: memberId, memberRole: .inherit) else { return }
                        self.reloadNoti.accept(viewData)
                        completion(.succeed(toast: I18N.Todo_TaskList_ChangePermissionForOthers_Toast))
                    case .none:
                        guard let viewData = self.removeMemberCell(memberId: memberId) else { return }
                        self.reloadNoti.accept(viewData)
                        completion(.succeed(toast: I18N.Todo_TaskList_ChangePermissionForOthers_Toast))
                    @unknown default: break
                    }
                }
            }, onError: { err in
                Self.logger.error("update member permission failed \(err)")
            }).disposed(by: disposeBag)
        }

    static func transformInviteData(container: Rust.TaskContainer, memberDatas: [MemberData], currentRole: Rust.MemberRole? = nil) -> V3ListShareViewData {
        var cellItem: [TaskMemberCellData] = []
        var canEdit: Bool = false
        // 当该vm从管理者界面初始化时，应携带，因为currentRole可能被修改，但container中权限并未更新
        if let currentRole = currentRole {
            canEdit = currentRole.rawValue - Rust.MemberRole.writer.rawValue <= 0
        } else {
            let currentRole: Rust.MemberRole = Self.containerRole(container)
            canEdit = currentRole.rawValue - Rust.MemberRole.writer.rawValue <= 0
        }
        let role: Rust.MemberRole = canEdit ? .writer : .reader
        let items = memberDatas.map {
            return TaskMemberCellData(
                identifier: $0.userId, name: $0.name,
                leadingIcon: .avatar($0.avatar),
                roleActionText: role.roleActionText,
                canEditAction: true,
                memberType: Rust.TaskMemberType.init(from: $0.memberType),
                role: role
            )
        }
        cellItem.append(contentsOf: items)
        return V3ListShareViewData(cellItem: cellItem, totalCount: Int64(cellItem.count))
    }


    private func updateMemberCell(memberId: String, memberRole: Rust.MemberRole, preViewData: V3ListShareViewData? = nil) -> V3ListShareViewData? {
        var viewData = V3ListShareViewData(cellItem: [])
        var memberList: V3ListShareViewData
        if let preViewData = preViewData {
            memberList = preViewData
        } else {
            memberList = reloadNoti.value
        }
        var cellData = memberList.cellItem
        if memberRole == .owner {
            var cellItem: [TaskMemberCellData] = []
            let owner = cellData.first(where: { $0.identifier == memberId })
            guard var owner = owner else { return nil }
            owner.roleActionText = Rust.MemberRole.owner.roleActionText
            owner.role = .owner
            // owner位置放在首位，并将其他member添加进来
            cellItem.append(owner)
            cellItem.append(contentsOf: cellData.filter { $0.identifier != memberId })
            viewData = V3ListShareViewData(cellItem: cellItem, totalCount: memberList.totalCount)
        } else {
            let memberIndex = cellData.firstIndex(where: { $0.identifier == memberId })
            guard let memberIndex = memberIndex, memberIndex < cellData.count else { return nil }
            cellData[memberIndex].role = memberRole
            cellData[memberIndex].roleActionText = memberRole.roleActionText

            // 更新权限时，只有可能对自己进行降级操作
            if memberId == currentUserId {
                currentRole = memberRole
                cellData = cellData.map { member in
                    // 当前用户权限更改时，更新所有用户的编辑权限
                    var newMember = member
                    newMember.canEditAction = canEditAction(from: member.role)
                    return newMember
                }
            }
            viewData = V3ListShareViewData(cellItem: cellData, totalCount: memberList.totalCount)
        }
        return viewData
    }

    private func removeMemberCell(memberId: String) -> V3ListShareViewData? {
        let memberList = reloadNoti.value
        let cellItem = memberList.cellItem.filter { return $0.identifier != memberId }
        // 判断当totalCount == 0时，说明移除了最后一个，需要关闭
        if var totalCount = memberList.totalCount, totalCount >= 1 {
            totalCount -= 1
            var viewData = V3ListShareViewData(cellItem: cellItem, totalCount: totalCount)
            if memberId == currentUserId {
                viewData.state = .dismiss
            }
            return viewData
        }
        return nil
    }

    func getAlertViewData(memberId: String, scene: ListShareScene) -> [AlertAction] {
        if scene == .manage {
            guard let item = reloadNoti.value.cellItem.first(where: { $0.identifier == memberId }) else { return [] }
            let alterActions = actions(by: item.memberType).map { action in
                return AlertAction(
                    title: action.title,
                    style: (action.alertActionStyle, action.role),
                    isSelected: item.role == action.role,
                    canBeselected: isCanBeSelected(
                        memberType: item.memberType,
                        alertActionStyle: action.alertActionStyle,
                        role: action.role
                    ),
                    needSeparateLine: action.role == .writer,
                    handler: {}
                )
            }
            return alterActions
        } else {
            guard let item = inviteNoti.value.cellItem.first(where: { $0.identifier == memberId }) else { return [] }
            let alterActions = inviteActions().map { action in
                return AlertAction(
                    title: action.title,
                    style: (action.alertActionStyle, action.role),
                    isSelected: item.role == action.role,
                    canBeselected: isCanBeSelected(
                        memberType: item.memberType,
                        alertActionStyle: action.alertActionStyle,
                        role: action.role
                    ),
                    needSeparateLine: action.role == .writer,
                    handler: {}
                )
            }
            return alterActions
        }
    }

    func updateInvitorPermission(memberId: String, memberRole: Rust.MemberRole) {
        var cellData = inviteNoti.value.cellItem
        let memberIndex = cellData.firstIndex(where: { $0.identifier == memberId })
        guard let memberIndex = memberIndex, memberIndex < cellData.count else { return }
        cellData[memberIndex].role = memberRole
        cellData[memberIndex].roleActionText = memberRole.roleActionText
        inviteNoti.accept(V3ListShareViewData(cellItem: cellData, totalCount: Int64(cellData.count)))
    }

    func removeInvitor(memberId: String) {
        let cellData = inviteNoti.value.cellItem.filter { return $0.identifier != memberId }
        // 判断当cellData为空时，说明移除了最后一个，需要关闭
        if cellData.isEmpty {
            inviteNoti.accept(V3ListShareViewData(cellItem: cellData, totalCount: Int64(cellData.count), state: .dismiss))
        } else {
            inviteNoti.accept(V3ListShareViewData(cellItem: cellData, totalCount: Int64(cellData.count)))
        }
    }

    func inviteMembers(isSendNote: Bool, note: String?, completion: @escaping ((ListActionResult) -> Void)) {
        var updatedMember = [Int64: Rust.EntityTaskListMember]()
        for item in inviteNoti.value.cellItem.enumerated() {
            var entity = Rust.EntityTaskListMember()
            entity.permission = {
                var permission = Rust.ContianerPermission()
                switch item.element.role {
                case .writer:
                    permission.permissions = [Int32(Rust.PermissionAction.manageEditor.rawValue): true]
                    entity.role = .writer
                case .reader:
                    permission.permissions = [Int32(Rust.PermissionAction.manageViewer.rawValue): true]
                    entity.role = .reader
                @unknown default: break
                }
                return permission
            }()
            entity.memberID = item.element.identifier
            entity.type = item.element.memberType.toServerPB()
            if let intId = Int64(item.element.identifier) {
                updatedMember[intId] = entity
            }
        }
        listApi?.updateTaskListMember(with: taskListInput.guid, updatedMembers: updatedMember, isSendNote: isSendNote, note: note)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { _ in
                completion(isSendNote ? .succeed(toast: I18N.Todo_TaskList_InvitationSent_Toast) : .succeed(toast: I18N.Todo_TaskList_ChangePermissionForOthers_Toast))
            }, onError: { err in
                Self.logger.error("invite members failed \(err)")
            }).disposed(by: disposeBag)
    }

    private func isCanBeSelected(memberType: Rust.TaskMemberType?, alertActionStyle: AlertActionStyle, role: Rust.MemberRole) -> Bool {
        guard let memberType = memberType else { return false }
        // 只有user类型才可以设置为所有者
        if alertActionStyle == .option && role == .owner {
            return currentRole == .owner && memberType == .user
        } else if alertActionStyle == .destructive {
            return true
        } else if currentRoleCanChange(otherRole: role) {
            return true
        }
        return false
    }

    private func currentRoleCanChange(otherRole: Rust.MemberRole) -> Bool {
        switch (currentRole, otherRole) {
        case (.owner, .owner), (.owner, .writer), (.owner, .reader), (.owner, .inherit): return true
        case (.writer, .writer), (.writer, .inherit), (.writer, .reader): return true
        case (.reader, .reader): return true
        @unknown default: return false
        }
    }
}

extension V3ListShareViewModel {

    private func transformPermissionsToRole(permissions: [Int32: Bool]) -> Rust.MemberRole {
        if permissions[Int32(Rust.PermissionAction.manageOwner.rawValue)] ?? false {
            return .owner
        } else if permissions[Int32(Rust.PermissionAction.manageEditor.rawValue)] ?? false {
            return .writer
        } else if permissions[Int32(Rust.PermissionAction.manageInherit.rawValue)] ?? false {
            return .inherit
        } else if permissions[Int32(Rust.PermissionAction.manageViewer.rawValue)] ?? false {
            return .reader
        }
        return .none
    }

    static func containerRole(_ container: Rust.TaskContainer) -> Rust.MemberRole {
        if container.isTaskListOwner {
            return .owner
        } else if container.isManageEditor {
            return .writer
        } else if container.isManageViewer {
            return .reader
        } else if container.isManageInherit {
            return .inherit
        }
        return .none
    }

    private func canEditAction(from role: Rust.MemberRole) -> Bool {
        // 当前用户与member如果未知权限则不可修改（兜底），member为所有者，不可点击更改
        if currentRole == .none || role == .none || role == .owner {
            return false
        }
        return currentRoleCanChange(otherRole: role)
    }

    typealias Action = (title: String, alertActionStyle: AlertActionStyle, role: Rust.MemberRole)
    private func actions(by memberType: Rust.TaskMemberType) -> [Action] {
        var items: [Action] = [
            (I18N.Todo_ShareList_ManageCollaboratorsCanView_Text, AlertActionStyle.option, Rust.MemberRole.reader),
            (I18N.Todo_ShareList_ManageCollaboratorsCanEdit_Text, AlertActionStyle.option, Rust.MemberRole.writer),
            (I18N.Todo_ShareList_ManageCollaboratorsSetAsOwner_MenuItem, AlertActionStyle.option, Rust.MemberRole.owner),
            (I18N.Todo_ShareList_ManageCollaboratorsRemove_MenuItem, AlertActionStyle.destructive, Rust.MemberRole.none)
        ]
        // 来自文档类型需要有【继承文档权限】的action
        if memberType == .docs {
            items.insert((I18N.Todo_Doc_FollowDocsPermissions_Button, AlertActionStyle.option, Rust.MemberRole.inherit), at: 0)
        }
        return items
    }

    private func inviteActions() -> [Action] {
        return [
            (I18N.Todo_ShareList_ManageCollaboratorsCanView_Text, .option, Rust.MemberRole.reader),
            (I18N.Todo_ShareList_ManageCollaboratorsCanEdit_Text, .option, Rust.MemberRole.writer),
            (I18N.Lark_Legacy_Delete, .destructive, Rust.MemberRole.none)
        ]
    }

}

extension Rust.MemberRole {

    var roleActionText: String {
        switch self {
        case .owner:
            return I18N.Todo_ShareList_ManageCollaboratorsCanManage_Text
        case .writer:
            return I18N.Todo_ShareList_ManageCollaboratorsCanEdit_Text
        case .reader:
            return I18N.Todo_ShareList_ManageCollaboratorsCanView_Text
        case .inherit:
            return I18N.Todo_Doc_FollowDocsPermissions_Button
        case .none:
            return ""
        @unknown default:
            return ""
        }
    }
}
