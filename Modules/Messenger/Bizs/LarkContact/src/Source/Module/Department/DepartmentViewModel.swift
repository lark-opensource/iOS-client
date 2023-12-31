//
//  DepartmentViewModel.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/27.
//  Copyright © 2018年 Bytedance. All rights reserved.
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
import LarkTag
import LarkProfile
import LKCommonsLogging
import LarkContainer

protocol DepartmentViewModelProtocol: AnyObject {
    func currentDepartment() -> Department
    func currentDepartmentObservable() -> Observable<[DepartmentSectionModel]>
    func currentDepartmentParentsObservable() -> Observable<[Basic_V1_Department]>
    func currentHasMoreDriver() -> Driver<Bool>
    func loadData()
    func loadMoreData()
    func isExternal(_ chaterId: String) -> Bool
    func isAdministrator(_ chaterId: String) -> Bool
    func isSuperAdministrator(_ chaterId: String) -> Bool
    func currentDisableTags() -> [TagType]
    func canInviteChatter(_ chaterId: String) -> Bool
    func denyInviteReason(_ chaterId: String) -> String
    func isChattersIdsInChat(_ chaterId: String) -> Bool
    func fobiddenDepartmentSelect() -> Bool
    func shouldCheckHasSelectPermission() -> Bool
    func isSelfSuperAdministrator() -> Observable<Bool>
    func isLeaderPermissionDepartment(_ departmentId: String) -> Bool
    func getDepartmentSelectDisabledText() -> String
    func currentChatAPI() -> ChatAPI
    func subDepartmentsItems() -> [SubDepartmentItem]
    func departmentsAdministratorStatus() -> DepartmentsAdministratorStatus
    func getProfileFieldsTitleDic() -> [String: [UserProfileField]]
    func getNameFormatRule() -> UserNameFormatRule?
    // 邮件组场景异化逻辑
    func mailGroupCheckCanSeletedChatter(_ chatterId: String) -> (selected: Bool, disable: Bool)?
    func mailGroupCheckCanSeletedDepartment( departmentId: String) -> (selected: Bool, disable: Bool)?
}

final class DepartmentViewModel: DepartmentViewModelProtocol, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let department: Department
    private let departmentAPI: DepartmentAPI
    private let chatterDriver: Driver<PushChatters>
    var filterChatter: ((String) -> Bool)? //支持过滤部门中的成员
    var chatId: String?

    static let logger = Logger.log(DepartmentViewModel.self, category: "Contact.DepartmentViewModel")

    /// 当前已拉取子部门数+直属成员数
    private var offset: Int = 0
    /// 默认一页拉取多少个，在有子部门未拉取完时，值为100，否则为20
    private var count: Int = 100
    /// 是否显示部门群
    let showContactsTeamGroup: Bool
    /// 以部门拉群时，携带该参数，返回是否对部门或其上层部门具有leader权限
    private let checkHasLeaderPermission: Bool
    /// 选择部门时对于选择权限是否需要做鉴权
    let shouldCheckSelectPermission: Bool
    /// 检查是否对某些人有添加权限
    var checkInvitePermission: Bool
    /// 当前是否处于密聊场景
    private let isCryptoModel: Bool
    /// 是不是跨租户群
    private let isCrossTenantChat: Bool
    /// 成员与部门管理权限当前已知状态
    private let departmentsAdminStatus: DepartmentsAdministratorStatus
    /// 子部门列表，更多部门的时候非空
    private let subDepartments: [SubDepartmentItem]
    /// 是否拉取企业邮箱数据
    private let preferEnterpriseEmail: Bool
    /// 邮件组相关参数，用于数据回来时排重
    var mailGroupId: Int?
    var mailGroupRole: MailGroupRole?
    /// 获取数据时携带的额外参数
    ///需要过滤的标签
    private var disableTags: [TagType]
    private var requestExtendParam: RustPB.Contact_V1_ExtendParam {
        var extendParam = RustPB.Contact_V1_ExtendParam()
        if let chatId = self.chatId { extendParam.inChatID = chatId }
        if self.checkInvitePermission {
            // 根据FG开关来使用新旧属性
            if userResolver.fg.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate") {
                if self.isCryptoModel {
                    extendParam.actionType = .inviteSameCryptoChat
                } else if self.isCrossTenantChat {
                    extendParam.actionType = .inviteSameCrossTenantChat
                } else {
                    extendParam.actionType = .inviteSameChat
                }
            } else {
                extendParam.canInviteSameChatTag = true
            }
        }
        if extendParam.actionType == .unknownAction,
           let permission = self.permissions?.first {
            extendParam.actionType = permission
        }
        extendParam.hasLeadPerm_p = self.checkHasLeaderPermission
        extendParam.needUserProfileFields = true
        if self.preferEnterpriseEmail {
            extendParam.selectEnterpriseEmail = true
        }
        if let groupId = mailGroupId {
            extendParam.checkMailGroupID = Int64(groupId)
        }
        if let roleType = mailGroupRole {
            var checkType: Contact_V1_ExtendParam.CheckMailGroupRole = .member
            if roleType == .manager {
                checkType = .manager
            } else if roleType == .member {
                checkType = .member
            } else if roleType == .permission {
                checkType = .permission
            }
            extendParam.checkMailGroupRole = checkType
        }
        return extendParam
    }
    private let departmentVariable = BehaviorRelay<[DepartmentSectionModel]>(value: [])
    lazy var departmentObservable: Observable<[DepartmentSectionModel]> = self.departmentVariable.asObservable()

    private let parentDepartmentsVariable = BehaviorRelay<[Basic_V1_Department]>(value: [])
    lazy var parentDepartmentsObservable: Observable<[Basic_V1_Department]> = self.parentDepartmentsVariable.asObservable()
    /// 会话内的成员
    private(set) var chattersIdsInChat: [String] = []
    /// 无权添加的人列表（旧属性）
    private var denyInviteChatterIds: [String] = []
    /// 无权添加的人列表（新属性）
    private var deniedReasons: [String: RustPB.Basic_V1_Auth_DeniedReason] = [:]
    /// 管理员id
    private(set) var administrator: Set<String> = []
    /// 超级管理员id
    private(set) var superAdministrator: Set<String> = []
    /// 子部门列表中有leader权限的部门
    private(set) var leaderPermissionDepartments: Set<String> = []
    /// chatter对应的企业邮箱， 只有在preferEnterpriseEmail参数为true时才会有
    private(set) var enterpriseEmails: [String: String] = [:]
    /// 已经在邮件组内的userId
    private(set) var mailGroupSelectedUsers: [String: Bool] = [:]
    /// 已经在邮件组内的部门
    private(set) var mailGroupSelectedDepartment: [String: Bool] = [:]

    private var profileFieldsTitleArray: [String] = []

    private var profileFieldsTitleDic: [String: [UserProfileField]] = [:]

    private let isShowDepartmentPrimaryMemberCountVariable = BehaviorRelay<Bool>(value: false)
    lazy var isShowDepartmentPrimaryMemberCountObservable: Observable<Bool> = self.isShowDepartmentPrimaryMemberCountVariable.asObservable()

    let chatAPI: ChatAPI
    private let hasMoreSubject = PublishSubject<Bool>()
    var hasMoreDriver: Driver<Bool> {
        return hasMoreSubject.asDriver(onErrorJustReturn: true)
    }
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?

    private var nameFormatRule: UserNameFormatRule = .nameFirst

    public var permissions: [RustPB.Basic_V1_Auth_ActionType]?
    private let disposeBag = DisposeBag()

    init(department: Department,
         departmentAPI: DepartmentAPI,
         chatAPI: ChatAPI,
         chatterDriver: Driver<PushChatters>,
         filterChatter: ((String) -> Bool)?,
         chatId: String?,
         showContactsTeamGroup: Bool,
         checkInvitePermission: Bool,
         isCryptoModel: Bool,
         isCrossTenantChat: Bool,
         shouldCheckSelectPermission: Bool,
         departmentsAdminStatus: DepartmentsAdministratorStatus = .unknown,
         subDepartments: [SubDepartmentItem] = [],
         disableTags: [TagType],
         preferEnterpriseEmail: Bool = false,
         permissions: [RustPB.Basic_V1_Auth_ActionType]? = nil,
         resolver: UserResolver) {
        self.department = department
        self.departmentAPI = departmentAPI
        self.chatAPI = chatAPI
        self.chatterDriver = chatterDriver
        self.filterChatter = filterChatter
        self.chatId = chatId
        self.showContactsTeamGroup = showContactsTeamGroup
        self.checkInvitePermission = checkInvitePermission
        self.isCryptoModel = isCryptoModel
        self.isCrossTenantChat = isCrossTenantChat
        self.checkHasLeaderPermission = shouldCheckSelectPermission
        self.shouldCheckSelectPermission = shouldCheckSelectPermission
        self.preferEnterpriseEmail = preferEnterpriseEmail
        self.departmentsAdminStatus = departmentsAdminStatus
        self.subDepartments = subDepartments
        self.disableTags = disableTags
        self.permissions = permissions
        self.userResolver = resolver
    }

    private func updateChatterIsSpecialFocus(addChatterIds: [String], deleteChatterIds: [String]) {
        var sections: [DepartmentSectionModel] = []
        let departmentSectionModel = self.departmentVariable.value
        departmentSectionModel.forEach({ (model) in
            var sectionModel: DepartmentSectionModel
            switch model {
            case .ChatterSection(chatters: let chatters):
                let newChatters = chatters.map({ (item) -> SectionItem in
                    switch item {
                    case .ChatterSectionItem(chatter: let chatter):
                        let newChatter = chatter
                        if addChatterIds.contains(chatter.id) {
                            newChatter.isSpecialFocus = true
                        } else if deleteChatterIds.contains(chatter.id) {
                            newChatter.isSpecialFocus = false
                        }
                        return SectionItem.ChatterSectionItem(chatter: newChatter)
                    default:
                        return item
                    }
                })
                sectionModel = DepartmentSectionModel.ChatterSection(chatters: newChatters)
            case .LeaderSection(leaders: let leaders):
                let newLeaders = leaders.map({ (item) -> SectionItem in
                    switch item {
                    case .LeaderSectionItem(leader: let leader, type: let type):
                        let newLeader = leader
                        if addChatterIds.contains(leader.id) {
                            newLeader.isSpecialFocus = true
                        } else if deleteChatterIds.contains(leader.id) {
                            newLeader.isSpecialFocus = false
                        }
                        return SectionItem.LeaderSectionItem(leader: newLeader, type: type)
                    default:
                        return item
                    }
                })
                sectionModel = DepartmentSectionModel.LeaderSection(leaders: newLeaders)
            default:
                sectionModel = model
            }
            sections.append(sectionModel)
        })
        self.departmentVariable.accept(sections)
    }

    private func updateSectionItem(pushChatters: [Chatter]) {
        pushChatters.forEach { (pushChatter) in
            var sections: [DepartmentSectionModel] = []
            self.departmentVariable.value.forEach({ (model) in
                var sectionModel: DepartmentSectionModel
                switch model {
                case .ChatterSection(chatters: let chatters):
                    let newChatters = chatters.map({ (item) -> SectionItem in
                        switch item {
                        case .ChatterSectionItem(chatter: let chatter):
                            if chatter.id == pushChatter.id {
                                return SectionItem.ChatterSectionItem(chatter: pushChatter)
                            } else {
                                return item
                            }
                        case .LeaderSectionItem, .SubDepartmentSectionItem, .ChatInfoSectionItem, .TenantSectionItem:
                            return item
                        }
                    })
                    sectionModel = DepartmentSectionModel.ChatterSection(chatters: newChatters)
                case .LeaderSection(leaders: let leaders):
                    let newLeaders = leaders.map({ (item) -> SectionItem in
                        switch item {
                        case .LeaderSectionItem(leader: let leader, type: let type):
                            if leader.id == pushChatter.id {
                                return SectionItem.LeaderSectionItem(leader: pushChatter, type: type)
                            } else {
                                return item
                            }
                        case .ChatterSectionItem, .SubDepartmentSectionItem, .ChatInfoSectionItem, .TenantSectionItem:
                            return item
                        }
                    })
                    sectionModel = DepartmentSectionModel.LeaderSection(leaders: newLeaders)
                case .SubDepartmentSection, .ChatInfoSection, .TenantSection:
                    sectionModel = model
                }
                sections.append(sectionModel)
            })
            self.departmentVariable.accept(sections)
        }
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

    func setupEnterpriseMail(chatter: Chatter) -> Chatter {
        if enterpriseEmails.isEmpty {
            return chatter
        }

        if let email = enterpriseEmails[chatter.id] {
            chatter.enterpriseEmail = email
        }
        return chatter
    }

    func getMembers(departmentStructure: DepartmentStructure, enterpriseEmails: [String: String]) -> [Chatter] {
        self.enterpriseEmails.merge(enterpriseEmails) { $1 }

        let leaderIDs = departmentStructure.deptLeaders.map { $0.leader.id }
        return departmentStructure.chatters
            .filter { chatter in
                // 过滤负责人
                !leaderIDs.contains(chatter.id)
            }.filter({ [weak self] (chatter) -> Bool in
                // 支持过滤部门中的成员
                return self?.filterChatter?(chatter.id) ?? true
            })
            .map({ chatter in
                // 组装企业邮箱数据
                return setupEnterpriseMail(chatter: chatter)
            })
    }

    func loadData() {
        let timeStamp = CACurrentMediaTime()
        let fetchDepartmentStructureObservable = departmentAPI.fetchDepartmentStructure(departmentId: department.id, offset: 0, count: count, extendParam: self.requestExtendParam)
            .do(onNext: { _ in
                Self.logger.info("n_action_fetch_dept_struct_succ")
            }, onError: { error in
                OrganizationAppReciableTrack.organizationPageLoadError(error: error)
                Self.logger.error("n_action_fetch_dept_struct_fail", error: error)
            })
        let getAnotherNameFormat = departmentAPI.getAnotherNameFormat()
            .do(onNext: { rule in
                Self.logger.info("n_action_get_name_format_rule_succ: rule: \(rule.rawValue)")
            }, onError: { error in
                Self.logger.error("n_action_get_name_format_rule_fail", error: error)
            })
                .catchErrorJustReturn(.nameFirst)

        Observable.combineLatest(fetchDepartmentStructureObservable, getAnotherNameFormat)
            .observeOn(MainScheduler.instance)
            .do(onError: { error in
                OrganizationAppReciableTrack.organizationPageLoadError(error: error)
            })
            .subscribe(onNext: { [weak self] (deptInfo, rule) in
                guard let `self` = self else { return }
                let sdkCost = CACurrentMediaTime() - timeStamp
                OrganizationAppReciableTrack.updateOrganizationSdkCost(sdkCost)
                self.nameFormatRule = rule
                self.enterpriseEmails = deptInfo.extendFields.enterpriseEmails
                let departmentStructure = deptInfo.departmentStructure
                let isShowMemberCount = deptInfo.isShowMemberCount
                self.parentDepartmentsVariable.accept(deptInfo.parentDepartments)
                self.chattersIdsInChat += deptInfo.extendFields.inChatChatterIds
                self.hasMoreSubject.onNext(departmentStructure.hasMore)
                self.denyInviteChatterIds = deptInfo.extendFields.chattersDenyInviteSameChat
                self.deniedReasons = deptInfo.extendFields.authResult.deniedReasons

                // 管理员信息
                self.administrator = deptInfo.departmentStructure.administrator
                self.superAdministrator = deptInfo.departmentStructure.superAdministrator

                self.mailGroupSelectedUsers = deptInfo.extendFields.selectedUsers.reduce([:], { (partialResult, arg1) in
                    let (key, value) = arg1
                    var res = partialResult
                    res[String(key)] = value
                    return res
                })
                self.mailGroupSelectedDepartment = deptInfo.extendFields.selectedDeparts.reduce([:], { (partialResult, arg1) in
                    let (key, value) = arg1
                    var res = partialResult
                    res[String(key)] = value
                    return res
                })
                deptInfo.extendFields.userProfileFields.forEach { (key, pbValue) in
                    for chatters in departmentStructure.chatters where chatters.id == key {
                        let getFields = GetUserProfileField.getFields(responseFileds: pbValue.profileFields)
                        self.profileFieldsTitleDic.updateValue(getFields, forKey: chatters.id)
                    }

                    for deptLeader in departmentStructure.deptLeaders where deptLeader.leader.id == key {
                        let getFields = GetUserProfileField.getFields(responseFileds: pbValue.profileFields)
                        self.profileFieldsTitleDic.updateValue(getFields, forKey: deptLeader.leader.id)
                    }
                }
                for (id, hasPermission) in deptInfo.extendFields.depHasLeadPerm where hasPermission {
                    self.leaderPermissionDepartments.insert(id)
                }

                // 如果没有子部门了，则count需要变为20
                self.count = departmentStructure.hasMoreDepartment ? 100 : 20
                var sections: [DepartmentSectionModel] = []
                // 部门群
                let chatInfo = departmentStructure.chatInfo
                if self.showContactsTeamGroup,
                   chatInfo.userPerm == .visibleAndCreate && !chatInfo.hasChat {
                    let chatInfoSectionItem = SectionItem.ChatInfoSectionItem(chatInfo: chatInfo)
                    let chatInfoSectionModel = DepartmentSectionModel.ChatInfoSection(chatInfos: [chatInfoSectionItem])
                    sections.append(chatInfoSectionModel)
                }

                // Leader
                // 负责人分为 企业负责人/主负责人/负责人
                // https://bytedance.feishu.cn/wiki/wikcnMYROM3CJcQuw820f1fF77g
                var leaderSectionModel: DepartmentSectionModel?
                let deptLeaders = departmentStructure.deptLeaders
                    .filter { deptLeader in
                        return self.filterChatter?(deptLeader.leader.id) ?? true
                    }
                var leaderSectionItems: [SectionItem] = []
                for deptLeader in deptLeaders {
                    let leader = self.setupEnterpriseMail(chatter: deptLeader.leader)
                    let leaderItem = SectionItem.LeaderSectionItem(leader: leader, type: deptLeader.leaderType)
                    leaderSectionItems.append(leaderItem)
                }

                if !leaderSectionItems.isEmpty {
                    leaderSectionModel = DepartmentSectionModel.LeaderSection(leaders: leaderSectionItems)
                }

                // 子部门
                var departmentSectionModel: DepartmentSectionModel = DepartmentSectionModel.SubDepartmentSection(departments: [])
                if !departmentStructure.subDepartments.isEmpty {
                    let subDepartments = departmentStructure.subDepartments.map {
                        SectionItem.SubDepartmentSectionItem(tenantId: nil, department: $0, isShowMemberCount: isShowMemberCount)
                    }
                    departmentSectionModel = DepartmentSectionModel.SubDepartmentSection(departments: subDepartments)
                }
                self.offset += departmentStructure.subDepartments.count

                // 直属成员
                // Chatters 可能包含 deptLeaders 中的副负责人，需要做过滤
                // https://bytedance.feishu.cn/wiki/wikcnMYROM3CJcQuw820f1fF77g
                var userSectionModel: DepartmentSectionModel = DepartmentSectionModel.ChatterSection(chatters: [])
                let members = self.getMembers(departmentStructure: departmentStructure, enterpriseEmails: deptInfo.extendFields.enterpriseEmails)
                if !members.isEmpty {
                    let chatters = members.map { SectionItem.ChatterSectionItem(chatter: $0) }
                    userSectionModel = DepartmentSectionModel.ChatterSection(chatters: chatters)
                }
                self.offset += departmentStructure.chatters.count

                // 显示顺序
                let defaultDisplayOrder: [ContactDisplayModule] = [.leader, .department, .user]
                let displayOrder: [ContactDisplayModule] = deptInfo.displayOrder.isEmpty ? defaultDisplayOrder : deptInfo.displayOrder
                for module in displayOrder {
                    switch module {
                    case .leader:
                        if let leaderSectionModel = leaderSectionModel {
                            sections.append(leaderSectionModel)
                        }
                    case .department:
                        sections.append(departmentSectionModel)
                    case .user:
                        sections.append(userSectionModel)
                    default:
                        assertionFailure("Unknown display module")
                    }
                }

                self.departmentVariable.accept(sections)
                self.isShowDepartmentPrimaryMemberCountVariable.accept(deptInfo.isShowDepartmentPrimaryMemberCount)
            })
            .disposed(by: self.disposeBag)

        self.chatterDriver
            .drive(onNext: { [weak self] (push) in
                self?.updateSectionItem(pushChatters: push.chatters)
            }).disposed(by: self.disposeBag)

        // 星标联系人状态改变时 及时更新
        chatterAPI?.pushFocusChatter
            .subscribe(onNext: { [weak self] msg in
                guard let self = self else { return }
                self.updateChatterIsSpecialFocus(addChatterIds: msg.addChatters.map { $0.id },
                                                 deleteChatterIds: msg.deleteChatterIds)
           }).disposed(by: self.disposeBag)
    }

    func loadMoreData() {
        self.departmentAPI
            .fetchDepartmentStructure(departmentId: department.id, offset: offset, count: count, extendParam: self.requestExtendParam)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (callBack) in
                guard let `self` = self else { return }
                let departmentStructure = callBack.departmentStructure
                let isShowMemberCount = callBack.isShowMemberCount
                self.chattersIdsInChat += callBack.extendFields.inChatChatterIds
                self.denyInviteChatterIds.lf_appendContentsIfNotContains(callBack.extendFields.chattersDenyInviteSameChat)
                self.deniedReasons = self.deniedReasons.lf_update(callBack.extendFields.authResult.deniedReasons)
                self.administrator = self.administrator.union(callBack.departmentStructure.administrator)
                self.superAdministrator = self.superAdministrator.union(callBack.departmentStructure.superAdministrator)
                for (id, hasPermission) in callBack.extendFields.depHasLeadPerm where hasPermission {
                    self.leaderPermissionDepartments.insert(id)
                }
                self.hasMoreSubject.onNext(departmentStructure.hasMore)
                // 如果没有子部门了，则count需要变为20
                self.count = departmentStructure.hasMoreDepartment ? 100 : 20
                var sections = self.departmentVariable.value
                // 追加子部门
                if !departmentStructure.subDepartments.isEmpty {
                    sections = sections.map({ (model) -> DepartmentSectionModel in
                        switch model {
                        case .SubDepartmentSection(let departments):
                            var newDepartments = departments
                            let departmentItemsToAdd = departmentStructure.subDepartments.map({
                                return SectionItem.SubDepartmentSectionItem(
                                    tenantId: nil,
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
                self.offset += departmentStructure.subDepartments.count

                // 追加直属成员
                // Chatters 可能包含 deptLeaders 中的副负责人，需要做过滤
                let newMembers = self.getMembers(departmentStructure: departmentStructure, enterpriseEmails: callBack.extendFields.enterpriseEmails)
                if !newMembers.isEmpty {
                    sections = sections.map({ (model) -> DepartmentSectionModel in
                        switch model {
                        case .ChatterSection(chatters: let chatters):
                            var newChatters = chatters
                            newChatters.append(contentsOf: newMembers.map({
                                return SectionItem.ChatterSectionItem(chatter: $0) }
                            ))
                            return DepartmentSectionModel.ChatterSection(chatters: newChatters)
                        case .LeaderSection, .SubDepartmentSection, .ChatInfoSection, .TenantSection:
                            return model
                        }
                    })
                }
                self.offset += departmentStructure.chatters.count

                self.departmentVariable.accept(sections)
            })
            .disposed(by: self.disposeBag)
    }

    func isExternal(_ chaterId: String) -> Bool {
        return false
    }

    func isAdministrator(_ chaterId: String) -> Bool {
        return self.administrator.contains(chaterId)
    }

    func isSuperAdministrator(_ chaterId: String) -> Bool {
        return self.superAdministrator.contains(chaterId)
    }

    func currentDisableTags() -> [TagType] {
        return self.disableTags
    }

    /// 是否能邀请某人
    func canInviteChatter(_ chaterId: String) -> Bool {
        // 如果是邮箱入口的邮箱联系人，只能拉有企业邮箱的用户
        if preferEnterpriseEmail {
            if let mail = enterpriseEmails[chaterId], !mail.isEmpty {
                return true
            } else {
                Self.logger.info("n_action_department_cannot_invite_enterprise_email")
                return false
            }
        }

        // 根据FG开关来使用新旧属性
        if userResolver.fg.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate") {
            // 无密聊权限/OU限制/单向联系人
            Self.logger.info("n_action_department_cannot_invite_deny_reason: \(String(describing: self.deniedReasons[chaterId]))")
            return !self.deniedReasons.keys.contains(chaterId)
        }

        // OU限制/单向联系人
        Self.logger.info("n_action_department_cannot_invite_deny_invite_chatter: \(self.denyInviteChatterIds.contains(chaterId))")
        return !self.denyInviteChatterIds.contains(chaterId)
    }

    /// 返回无法选中该用户的原因
    func denyInviteReason(_ chaterId: String) -> String {
        // 在邮箱场景下不能选的原因是没有企业邮箱
        if preferEnterpriseEmail {
            return BundleI18n.LarkContact.Lark_Contacts_NoBusinessEmail
        }

        Self.logger.info("n_action_department_deny_invite_reason: \(self.deniedReasons[chaterId])")

        // 根据FG开关来使用新旧属性
        if userResolver.fg.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate") {
            guard let reason = self.deniedReasons[chaterId] else { return "" }

            // 无密聊权限
            if reason == .cryptoChatDeny {
                return BundleI18n.LarkContact.Lark_Chat_CantSecretChatWithUserSecurityRestrict
            }
        }

        if let reason = self.deniedReasons[chaterId] {
            switch reason {
            case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                return BundleI18n.LarkContact
                    .Lark_Contacts_CantAddExternalContactNoExternalCommunicationPermission
            @unknown default:
                break
            }
        }

        // OU限制/单向联系人
        guard self.denyInviteChatterIds.contains(chaterId) else { return "" }

        return BundleI18n.LarkContact.Lark_Groups_NoPermissionToAdd
    }

    func isChattersIdsInChat(_ chaterId: String) -> Bool {
        return self.chattersIdsInChat.contains(chaterId)
    }

    func fobiddenDepartmentSelect() -> Bool {
        return false
    }

    func shouldCheckHasSelectPermission() -> Bool {
        return self.shouldCheckSelectPermission
    }

    func isSelfSuperAdministrator() -> Observable<Bool> {
        return self.departmentAPI.isSuperAdministrator()
    }

    func isLeaderPermissionDepartment(_ departmentId: String) -> Bool {
        self.leaderPermissionDepartments.contains(departmentId)
    }

    func getDepartmentSelectDisabledText() -> String {
        return BundleI18n.LarkContact.Lark_Groups_NoPermissionSelectDept
    }

    func currentChatAPI() -> ChatAPI {
        self.chatAPI
    }

    func subDepartmentsItems() -> [SubDepartmentItem] {
        return self.subDepartments
    }

    func departmentsAdministratorStatus() -> DepartmentsAdministratorStatus {
        return self.departmentsAdminStatus
    }

    func getProfileFieldsTitleDic() -> [String: [UserProfileField]] {
        return self.profileFieldsTitleDic
    }

    func getNameFormatRule() -> UserNameFormatRule? {
        return self.nameFormatRule
    }

    func mailGroupCheckCanSeletedChatter(_ chatterId: String) -> (selected: Bool, disable: Bool)? {
        guard mailGroupId != nil, mailGroupRole != nil else {
            return nil
        }
        let contain = mailGroupSelectedUsers[chatterId] ?? false
        return (contain, contain)
    }

    func mailGroupCheckCanSeletedDepartment( departmentId: String) -> (selected: Bool, disable: Bool)? {
        guard mailGroupId != nil, mailGroupRole != nil else {
            return nil
        }
        let contain = mailGroupSelectedDepartment[departmentId] ?? false
        return (contain, contain)
    }
}
