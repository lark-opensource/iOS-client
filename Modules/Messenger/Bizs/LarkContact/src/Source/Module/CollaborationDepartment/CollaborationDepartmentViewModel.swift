//
//  CollaborationDepartmentViewModel.swift
//  LarkContact
//
//  Created by tangyunfei.tyf on 2021/3/4.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkModel
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkFeatureGating
import RustPB
import LKCommonsLogging
import LarkTag
import LarkSetting

final class CollaborationDepartmentViewModel: DepartmentViewModelProtocol {
    static let logger = Logger.log(CollaborationDepartmentViewModel.self, category: "contact.CollaborationDepartmentViewModel")

    enum DataType {
        case tenant
        case department(tenantId: String, departmentId: String)
    }

    let tenantId: String?
    let department: Department
    private let departmentAPI: CollaborationDepartmentAPI
    private let chatterDriver: Driver<PushChatters>
    var filterChatter: ((String) -> Bool)? //支持过滤部门中的成员
    var chatId: String?

    /// 当前已拉取子部门数+直属成员数
    private var offset: Int = 0
    /// 默认一页拉取多少个，在有子部门未拉取完时，值为100，否则为20
    private var count: Int = 100
    /// 是否显示部门群
    let showContactsTeamGroup: Bool
    /// 以部门拉群时，携带该参数，返回是否对部门或其上层部门具有leader权限
    let checkHasLeaderPermission: Bool
    /// 检查是否对某些人有添加权限
    var checkInvitePermission: Bool
    /// 当前是否处于密聊场景
    var isCryptoModel: Bool
    /// 关联组织类型
    let associationContactType: AssociationContactType?
    ///需要过滤的标签
    private var disableTags: [TagType]
    /// 获取数据时携带的额外参数
    private var requestExtendParam: RustPB.Contact_V1_CollaborationExtendParam {
        var extendParam = RustPB.Contact_V1_CollaborationExtendParam()
        if let chatId = self.chatId { extendParam.inChatID = chatId }
        if self.checkInvitePermission {
            // 根据FG开关来使用新旧属性
            if fgService.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate") {
                extendParam.businessScene = self.isCryptoModel ? .inviteSameCryptoChat : .inviteSameChat
            }
        }
        if extendParam.businessScene == .unknownAction,
           let permissions = self.permissions?.first {
            extendParam.businessScene = permissions
        }
        return extendParam
    }
    private let departmentVariable = BehaviorRelay<[DepartmentSectionModel]>(value: [])
    lazy var departmentObservable: Observable<[DepartmentSectionModel]> = self.departmentVariable.asObservable()

    private let parentDepartmentsVariable = BehaviorRelay<[Basic_V1_Department]>(value: [])
    lazy var parentDepartmentsObservable: Observable<[Basic_V1_Department]> = self.parentDepartmentsVariable.asObservable()

    private let collaborationTenantVariable = BehaviorRelay<Contact_V1_CollaborationTenant?>(value: nil)
    lazy var collaborationTenantObservable: Observable<Contact_V1_CollaborationTenant?> = self.collaborationTenantVariable.asObservable()

    /// 会话内的成员
    private(set) var chattersIdsInChat: [String] = []
    /// 无权添加的人列表（旧属性）
    private var denyInviteChatterIds: [String] = []
    /// 无权添加的人列表（新属性）
    private var deniedReasons: [String: RustPB.Basic_V1_Auth_DeniedReason] = [:]
    private let isShowTenantMemberCount = false

    let chatAPI: ChatAPI
    let fgService: FeatureGatingService
    private let hasMoreSubject = PublishSubject<Bool>()
    var hasMoreDriver: Driver<Bool> {
        return hasMoreSubject.asDriver(onErrorJustReturn: true)
    }

    public var permissions: [RustPB.Basic_V1_Auth_ActionType]?

    var isEnableInternalCollaborationFG: Bool {
        fgService.staticFeatureGatingValue(with: "lark.admin.orm.b2b.high_trust_parties")
    }

    private let disposeBag = DisposeBag()

    init(
         tenantId: String?,
         department: Department,
         departmentAPI: CollaborationDepartmentAPI,
         chatAPI: ChatAPI,
         fgService: FeatureGatingService,
         chatterDriver: Driver<PushChatters>,
         filterChatter: ((String) -> Bool)?,
         chatId: String?,
         showContactsTeamGroup: Bool,
         checkInvitePermission: Bool,
         isCryptoModel: Bool,
         checkHasLeaderPermission: Bool,
         disableTags: [TagType],
         associationContactType: AssociationContactType?,
         permissions: [RustPB.Basic_V1_Auth_ActionType]? = nil) {
        self.tenantId = tenantId
        self.department = department
        self.departmentAPI = departmentAPI
        self.chatAPI = chatAPI
        self.fgService = fgService
        self.chatterDriver = chatterDriver
        self.filterChatter = filterChatter
        self.chatId = chatId
        self.showContactsTeamGroup = showContactsTeamGroup
        self.checkInvitePermission = checkInvitePermission
        self.isCryptoModel = isCryptoModel
        self.checkHasLeaderPermission = checkHasLeaderPermission
        self.associationContactType = associationContactType
        self.disableTags = disableTags
        self.permissions = permissions
    }

    private func currentDataType() -> DataType {
        guard let tenantId = self.tenantId else {
            return .tenant
        }
        return .department(tenantId: tenantId, departmentId: department.id)
    }

    // MARK: DepartmentViewModelProtocol
    func currentDepartment() -> Department {
        return self.department
    }

    func currentDepartmentObservable() -> Observable<[DepartmentSectionModel]> {
        return self.departmentObservable
    }

    func currentDepartmentParentsObservable() -> Observable<[Basic_V1_Department]> {
        return self.parentDepartmentsObservable
    }

    func currentHasMoreDriver() -> Driver<Bool> {
        return hasMoreDriver
    }

    func loadData() {
        let dataType = self.currentDataType()
        switch dataType {
        case .tenant:
            self.loadTenantData()
        case .department(let tenantId, let departmentId):
            self.loadDepartmentData(tenantId: tenantId, departmentId: departmentId)
        }
    }

    func loadMoreData() {
        //Todo: 后续重构DepartmentViewModel,去除loadMoreData
        self.loadData()
    }

    private func loadTenantData() {
        self.departmentAPI
            .fetchCollaborationTenant(offset: offset, count: count, showConnectType: associationContactType)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (callBack) in
                guard let `self` = self else { return }
                Self.logger.info("fetch collaboration tenants success, tenant count: \(callBack.tenants.count)")
                self.hasMoreSubject.onNext(callBack.hasMore)
                self.count = callBack.hasMore ? 100 : 20

                var sections = self.departmentVariable.value
                if !self.hasTenantSection(sections: sections) {
                    sections.append(DepartmentSectionModel.TenantSection(tenants: []))
                }
                if !callBack.tenants.isEmpty {
                    self.offset += callBack.tenants.count
                    sections = sections.map({ (model) -> DepartmentSectionModel in
                        switch model {
                        case let .TenantSection(tenants):
                            var newTenants = tenants
                            newTenants.append(contentsOf: callBack.tenants.map({
                                SectionItem.TenantSectionItem(tenantId: $0.tenantID, tenantName: $0.tenantName, memberCount: $0.tenantUserCount, isShowMemberCount: self.isShowTenantMemberCount)
                            }))
                            return DepartmentSectionModel.TenantSection(tenants: newTenants)
                        case .LeaderSection, .ChatterSection, .ChatInfoSection, .SubDepartmentSection:
                            return model
                        }
                    })
                }

                self.departmentVariable.accept(sections)
            })
            .disposed(by: self.disposeBag)
    }

    private func loadDepartmentData(tenantId: String, departmentId: String) {
        self.departmentAPI
            .fetchDepartmentStructure(tenantId: tenantId, departmentId: departmentId, offset: offset, count: count, extendParam: self.requestExtendParam)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (callBack) in
                guard let `self` = self else { return }
                let departmentStructure = callBack.departmentStructure
                Self.logger.info("fetch collaboration departments success, sub department count: \(departmentStructure.subDepartments.count), chatter counts: \(departmentStructure.chatters.count)")
                let isShowMemberCount = callBack.isShowMemberCount
                self.chattersIdsInChat += callBack.extendFields.chattersInChatID
                self.denyInviteChatterIds.lf_appendContentsIfNotContains(callBack.extendFields.chattersDenyInviteSameChat)
                self.deniedReasons = self.deniedReasons.lf_update(callBack.extendFields.authResult.deniedReasons)
                self.hasMoreSubject.onNext(departmentStructure.hasMore)
                // 如果没有子部门了，则count需要变为20
                self.count = departmentStructure.hasMoreDepartment ? 100 : 20

                let sections = self.refreshDataSource(departmentStructure: departmentStructure, isShowMemberCount: isShowMemberCount)
                self.departmentVariable.accept(sections)
                self.parentDepartmentsVariable.accept(callBack.parentDepartments)
                self.collaborationTenantVariable.accept(callBack.tenant)
            })
            .disposed(by: self.disposeBag)
    }

    private func refreshDataSource(departmentStructure: CollaborationDepartmentStructure, isShowMemberCount: Bool) -> [DepartmentSectionModel] {
        var sections = self.departmentVariable.value
        if !self.hasSubDepartmentSection(sections: sections) {
            sections.append(DepartmentSectionModel.SubDepartmentSection(departments: []))
        }
        if !self.hasChatterSection(sections: sections) {
            sections.append(DepartmentSectionModel.ChatterSection(chatters: []))
        }

        // 追加子部门
        if !departmentStructure.subDepartments.isEmpty {
            self.offset += departmentStructure.subDepartments.count
            sections = sections.map({ (model) -> DepartmentSectionModel in
                switch model {
                case .SubDepartmentSection(let departments):
                    var newDepartments = departments
                    let departmentItemsToAdd = departmentStructure.subDepartments.map({
                        return SectionItem.SubDepartmentSectionItem(
                            tenantId: tenantId,
                            department: $0,
                            isShowMemberCount: isShowMemberCount
                        )
                    })
                    newDepartments.append(contentsOf: departmentItemsToAdd)
                    return DepartmentSectionModel.SubDepartmentSection(departments: newDepartments)
                case .LeaderSection, .ChatterSection, .ChatInfoSection, .TenantSection:
                    return model
                }
            })
        }
        // 追加直属成员
        if !departmentStructure.chatters.isEmpty {
            self.offset += departmentStructure.chatters.count
            sections = sections.map({ (model) -> DepartmentSectionModel in
                switch model {
                case .ChatterSection(chatters: let chatters):
                    var newChatters = chatters
                    let pushChatters = departmentStructure.chatters.filter({ [weak self] (chatter) -> Bool in
                        return self?.filterChatter?(chatter.id) ?? true
                    })
                    newChatters.append(contentsOf: pushChatters.map({
                        return SectionItem.ChatterSectionItem(chatter: $0) }
                    ))
                    return DepartmentSectionModel.ChatterSection(chatters: newChatters)
                case .LeaderSection, .SubDepartmentSection, .ChatInfoSection, .TenantSection:
                    return model
                }
            })
        }
        return sections
    }

    private func hasTenantSection(sections: [DepartmentSectionModel]) -> Bool {
        if sections.isEmpty {
            return false
        }
        return sections.contains { (section) -> Bool in
            if case .TenantSection = section {
                return true
            } else {
                return false
            }
        }
    }

    private func hasSubDepartmentSection(sections: [DepartmentSectionModel]) -> Bool {
        if sections.isEmpty {
            return false
        }
        return sections.contains { (section) -> Bool in
            if case .SubDepartmentSection = section {
                return true
            } else {
                return false
            }
        }
    }

    private func hasChatterSection(sections: [DepartmentSectionModel]) -> Bool {
        if sections.isEmpty {
            return false
        }
        return sections.contains { (section) -> Bool in
            if case .ChatterSection = section {
                return true
            } else {
                return false
            }
        }
    }

    func isExternal(_ chaterId: String) -> Bool {
        return true
    }

    func isAdministrator(_ chaterId: String) -> Bool {
        return false
    }

    func isSuperAdministrator(_ chaterId: String) -> Bool {
        return false
    }

    func currentDisableTags() -> [TagType] {
        return self.disableTags
    }

    /// 是否能邀请某人
    func canInviteChatter(_ chaterId: String) -> Bool {
        // 根据FG开关来使用新旧属性
        if fgService.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate") {
            // 无密聊权限/OU限制/单向联系人
            return !self.deniedReasons.keys.contains(chaterId)
        }

        // OU限制/单向联系人
        return !self.denyInviteChatterIds.contains(chaterId)
    }

    /// 返回无法选中该用户的原因
    func denyInviteReason(_ chaterId: String) -> String {
        // 根据FG开关来使用新旧属性
        if fgService.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate") {
            guard let reason = self.deniedReasons[chaterId] else { return "" }

            // 无密聊权限
            if reason == .cryptoChatDeny {
                return BundleI18n.LarkContact.Lark_Chat_CantSecretChatWithUserSecurityRestrict
            }

            // OU限制/单向联系人
            return BundleI18n.LarkContact.Lark_Groups_NoPermissionToAdd
        }

        // OU限制/单向联系人
        guard self.denyInviteChatterIds.contains(chaterId) else { return "" }

        return BundleI18n.LarkContact.Lark_Groups_NoPermissionToAdd
    }

    func isChattersIdsInChat(_ chaterId: String) -> Bool {
        return self.chattersIdsInChat.contains(chaterId)
    }

    // 关联组织在任何场景都不允许选择部门
    func fobiddenDepartmentSelect() -> Bool {
        return true
    }

    func shouldCheckHasSelectPermission() -> Bool {
        return self.checkHasLeaderPermission
    }

    func isSelfSuperAdministrator() -> Observable<Bool> {
        return .just(false)
    }

    func isLeaderPermissionDepartment(_ departmentId: String) -> Bool {
        return false
    }

    func getDepartmentSelectDisabledText() -> String {
        return BundleI18n.LarkContact.Lark_B2B_NoPermSelectDept
    }

    func currentChatAPI() -> ChatAPI {
        return self.chatAPI
    }

    func departmentsAdministratorStatus() -> DepartmentsAdministratorStatus {
        return .notAdmin
    }

    func subDepartmentsItems() -> [SubDepartmentItem] {
        return []
    }

    func getProfileFieldsTitleDic() -> [String: [UserProfileField]] {
        return [:]
    }

    func getNameFormatRule() -> UserNameFormatRule? {
        return nil
    }

    func mailGroupCheckCanSeletedDepartment(departmentId: String) -> (selected: Bool, disable: Bool)? {
        return nil
    }

    func mailGroupCheckCanSeletedChatter(_ chatterId: String) -> (selected: Bool, disable: Bool)? {
        return nil
    }
}
