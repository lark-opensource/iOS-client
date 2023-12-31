//
//  StructureView.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/20.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkUIKit
import Swinject
import RxSwift
import EENavigator
import LarkMessengerInterface
import LarkSearchCore
import LarkAccountInterface
import LarkSDKInterface
import RxCocoa
import LarkFeatureGating
import LarkKeyCommandKit
import RustPB
import LarkTag
import Homeric
import LarkRustClient
import LarkSetting

protocol StructureViewDependency {
    // config
    var enableOwnedGroup: Bool? { get set }
    var selectionSource: SelectionDataSource? { get }
    var hasGroup: Bool { get }
    var supportSelectGroup: Observable<Bool> { get }
    var checkMyGroupsSelectDeniedReason: MyGroupsCheckSelectDeniedReason? { get }
    var hasBot: Bool { get }
    var hasRelatedOrganizations: Observable<Bool> { get }
    /// should contains a initial notify
    var hasOrganization: Observable<Bool> { get }
    var supportSelectOrganization: Observable<Bool> { get }
    var userGroupSceneType: UserGroupSceneType? { get }
    var hasUserGroup: Bool { get }
    /// should contains a initial notify
    var hasExternal: Observable<Bool> { get }
    var hasOncall: Bool { get }
    var hasEmailConatact: Bool { get }
    var hasSharedMailAccount: Bool { get }
    var hasEmailAddress: Bool { get }
    var hasSearchFromFilterRecommend: Bool { get }
    /// UI
    var tableBackgroundColor: UIColor { get }
    var showTopBorder: Bool { get }

    /// target preview
    var targetPreview: Bool { get }

    var forceSelectedChattersInChatId: String? { get }
    var source: ChatterPickerSource? { get }

    // externalContracts dep
    var contactActionType: RustPB.Basic_V1_Auth_ActionType? { get }

    var passportUserService: PassportUserService? { get }
    var serverNTPTimeService: ServerNTPTimeService? { get }
    var externalContactsAPI: ExternalContactsAPI? { get }
    var newExternalContactsDriver: Driver<NewPushExternalContactsWithChatterIds>? { get }
    var externalContactsDriver: Driver<PushExternalContactsWithChatterIds>? { get }

    // department dep
    var showContactsTeamGroup: Bool { get }
    var showNameStyle: ShowNameStyle { get }
    var checkInvitePermission: Bool { get }
    var isCryptoModel: Bool { get }
    var isCrossTenantChat: Bool { get }
    var shouldCheckHasSelectOrganizationPermission: Bool { get }

    // mail contact
    var mailAccountId: String? { get }
    var preferEnterpriseEmail: Bool { get }
    var mailGroupId: Int? { get }
    var mailGroupRole: MailGroupRole? { get }

    var userAPI: UserAPI? { get }
    var chatAPI: ChatAPI? { get }
    var clientAPI: RustService? { get }
    var chatterDriver: Driver<PushChatters>? { get }
    var namecardAPI: NamecardAPI? { get }
    // from filter recommmendation
    var fromFilterRecommendList: [SearchResultType] { get }
    var defaultOption: [Option] { get }
    // picker
    var pickerScene: String? { get }
}

// Center Controller for Router different subVC
final class StructureView: NavigationView, UserResolverWrapper {
    let dependency: StructureViewDependency
    private let structRootVC: StructureRootVC
    weak var targetVC: UIViewController?
    private var section: StructureRootVC.Section?
    var userResolver: LarkContainer.UserResolver
    weak var delegate: PickerContactViewDelegate?
    init(frame: CGRect, dependency: StructureViewDependency, resolver: UserResolver) {
        self.dependency = dependency
        self.userResolver = resolver
        let router = RootRouter(resolver: userResolver)
        self.structRootVC = StructureRootVC(router: router,
                                            tableBackgroundColor: dependency.tableBackgroundColor,
                                            showTopBorder: dependency.showTopBorder,
                                            fromFilterRecommendList: dependency.fromFilterRecommendList,
                                            resolver: userResolver)
        structRootVC.selectionDataSource = dependency.selectionSource
        structRootVC.source = dependency.source
        structRootVC.hasGroup = dependency.hasGroup
        structRootVC.hasRobot = dependency.hasBot
        structRootVC.hasOnCall = dependency.hasOncall
        structRootVC.hasEmailContact = dependency.hasEmailConatact
        structRootVC.hasSharedMailAccount = dependency.hasSharedMailAccount
        structRootVC.hasEmailAddress = dependency.hasEmailAddress
        structRootVC.hasSearchFromFilterRecommend = dependency.hasSearchFromFilterRecommend
        structRootVC.pickerScene = dependency.pickerScene
        structRootVC.defaultOption = dependency.defaultOption
        structRootVC.targetPreview = dependency.targetPreview
        structRootVC.enableOwnedGroup = dependency.enableOwnedGroup
        dependency.hasOrganization.observeOn(MainScheduler.instance).bind(to: structRootVC.rx[\.hasOrganization]).disposed(by: structRootVC.bag)
        dependency.hasRelatedOrganizations.observeOn(MainScheduler.instance).bind(to: structRootVC.rx[\.hasRelatedOrganizations]).disposed(by: structRootVC.bag)
        dependency.hasExternal.observeOn(MainScheduler.instance).bind(to: structRootVC.rx[\.hasExternal]).disposed(by: structRootVC.bag)
        dependency.supportSelectOrganization.observeOn(MainScheduler.instance).bind(to: structRootVC.rx[\.supportSelectOrganization]).disposed(by: structRootVC.bag)
        dependency.supportSelectGroup.observeOn(MainScheduler.instance).bind(to: structRootVC.rx[\.supportSelectGroup]).disposed(by: structRootVC.bag)
        structRootVC.userGroupSceneType = dependency.userGroupSceneType
        super.init(frame: frame, root: structRootVC)

        router.base = self
        structRootVC.currentSection = { [weak self] section in
            self?.section = section
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    // TableViewKeyboardHandlerProvider
//    var tableViewKeyboardHandler: TableViewKeyboardHandler? {
//        if let handlerProvider = self.currentSource as? TableViewKeyboardHandlerProvider {
//            return handlerProvider.tableViewKeyboardHandler
//        }
//        return structRootVC.keyboardHandler
//    }
    public override func subProviders() -> [KeyCommandProvider] {
        return [currentSource ?? structRootVC]
    }

    override func tapIndex(index: Int) {
        super.tapIndex(index: index)
        Tracer.contactOrganizationBreadcrumbsClick()
        if let section = section {
            switch section {
            case .organization:
                SearchTrackUtil.trackPickerSelectArchitectureClick(clickType: .navigationBar(target: Homeric.PUBLIC_PICKER_SELECT_ARCHITECTURE_MEMBER_VIEW))
            case .collaborationTenant:
                SearchTrackUtil.trackPickerSelectAssociatedOrganizationsClick(clickType: .navigationBar(target: Homeric.PUBLIC_PICKER_SELECT_ASSOCIATED_ORGANIZATIONS_VIEW))
            default: break
            }
        }
    }

    var selectedRecommendList: [SearchResultType] {
        return structRootVC.selectedRecommendList
    }

    func customTableViewHeader(customView: UIView) {
        self.structRootVC.customTableViewHeader(customView: customView)
    }

    func customTableViewFooter(customView: UIView) {
        self.structRootVC.customTableViewFooter(customView: customView)
    }

    final class RootRouter: StructureRootVCRouter, UserResolverWrapper {
        weak var base: StructureView?
        var userResolver: LarkContainer.UserResolver
        init(resolver: UserResolver) {
            self.userResolver = resolver
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        // FIXME: Navigator push传的子VC，不确定是否有问题
        func didSelectGroupWithChat(_ vc: StructureRootVC) {
            guard let base = base,
                    let selectionDataSource = base.dependency.selectionSource,
                    let passportUserService = base.dependency.passportUserService,
                    let userAPI = base.dependency.userAPI else { return }
            let hasOwnedGroup = base.dependency.enableOwnedGroup ?? false
            if hasOwnedGroup || vc.supportSelectGroup {
                let VC = MyGroupsVC(
                    viewModel: GroupsViewModel(
                        userAPI: userAPI,
                        currentTenantId: passportUserService.userTenant.tenantID,
                        chatId: base.dependency.forceSelectedChattersInChatId,
                        currentUserType: Account.userTypeFromPassportUserType(passportUserService.user.type)
                    ),
                    config: MyGroupsVC.Config(selectedHandler: { index in
                        Tracer.trackPickerItemSelect(source: .myOwnedGroup, index: index)
                    }),
                    selectionSource: selectionDataSource,
                    selectAbility: base.dependency.checkMyGroupsSelectDeniedReason,
                    resolver: userResolver
                )
                VC.targetPreview = vc.targetPreview
                VC.fromVC = base.targetVC
                VC.delegate = base.delegate
                base.push(source: VC)
                return
            }
            guard let from = base.targetVC else { return }
            let body = GroupsViewControllerBody(title: BundleI18n.LarkContact.Lark_Legacy_GroupExistGroup, newGroupBtnHidden: true)
            navigator.push(body: body, from: from)
        }

        func didSelectBotWithChatter(_ vc: StructureRootVC) {
            guard let from = base?.targetVC else { return }
            navigator.push(body: RobotViewControllerBody(), from: from)
        }

        func didSelectOnCallWithOncall(_ vc: StructureRootVC) {
            guard let from = base?.targetVC else { return }
            navigator.push(body: OnCallViewControllerBody(), from: from)
        }

        func didSelectExternal(_ vc: StructureRootVC) {
            guard let base = base,
                    let selectionDataSource = base.dependency.selectionSource,
                    let chatAPI = base.dependency.chatAPI,
                    let externalContactsAPI = base.dependency.externalContactsAPI,
                    let serverNTPTimeService = base.dependency.serverNTPTimeService,
                    let newExternalContactsDriver = base.dependency.newExternalContactsDriver else { return }
            guard let VC = try? SelectionExternalContactsContentView(
                viewModel: SelectionExternalContactsViewModel(
                    chatID: base.dependency.forceSelectedChattersInChatId,
                    actionType: base.dependency.contactActionType,
                    externalContactsAPI: externalContactsAPI,
                    chatAPI: chatAPI,
                    pushDriver: newExternalContactsDriver
                    ),
                selectionSource: selectionDataSource,
                serverNTPTimeService: serverNTPTimeService,
                config: SelectionExternalContactsContentView.Config(
                    pickerTracker: nil,
                    selectedHandler: { index in
                        Tracer.trackPickerItemSelect(source: .externalContacts, index: index)
                    }),
                resolver: userResolver
            ) else { return }
            // FIXME: 暂时不传，这只是一个子页面
            base.dependency.hasExternal.observeOn(MainScheduler.instance)
                .bind(to: VC.rx[\.canSelectExternalContacts])
                .disposed(by: VC.disposeBag)
            VC.targetPreview = vc.targetPreview
            VC.fromVC = base.targetVC
            base.push(source: VC)
        }

        /// 跳转用户组列表选择页面
        /// - Parameter vc: 根Vc
        func didSelectUserGroup(_ vc: StructureRootVC) {
            guard let base = base,
                    let selectionDataSource = base.dependency.selectionSource,
                    let clientApi = base.dependency.clientAPI,
                    let groupSceneType = base.dependency.userGroupSceneType else {
                return
            }
            let config = UserGroupViewController.Config(selectedHandler: { index in
                Tracer.trackPickerItemSelect(source: .userGroup, index: index)
            })
            let viewModel = UserGroupViewModel(client: clientApi,
                                               userGroupSceneType: groupSceneType)
            let userGroupVc = UserGroupViewController(viewModel: viewModel,
                                                      config: config,
                                                      selectionSource: selectionDataSource,
                                                      resolver: userResolver)
            userGroupVc.fromVC = base.targetVC
            base.push(source: userGroupVc)
        }

        func didSelectDepartment(_ vc: StructureRootVC, department: Department) {
            router(vc, department: department, supportSelectDepartment: vc.supportSelectOrganization, targetPreview: vc.targetPreview)
        }

        func didSelectCollaborationDepartment(_ vc: StructureRootVC,
                                              tenantId: String?,
                                              department: Department,
                                              departmentPath: [Department],
                                              associationContactType: AssociationContactType?) {
            guard let base = base,
                    let selectionDataSource = base.dependency.selectionSource,
                    let userAPI = base.dependency.userAPI,
                    let chatAPI = base.dependency.chatAPI,
                    let chatterDriver = base.dependency.chatterDriver else { return }
            let departmentAPI = CollaborationDepartmentAPI(userAPI: userAPI)
            let viewModel = CollaborationDepartmentViewModel(
                tenantId: tenantId,
                department: department,
                departmentAPI: departmentAPI,
                chatAPI: chatAPI,
                fgService: userResolver.fg,
                chatterDriver: chatterDriver,
                filterChatter: nil,
                chatId: base.dependency.forceSelectedChattersInChatId,
                showContactsTeamGroup: false,
                checkInvitePermission: base.dependency.checkInvitePermission,
                isCryptoModel: base.dependency.isCryptoModel,
                checkHasLeaderPermission: true,
                disableTags: [.onLeave, .supervisor],
                associationContactType: associationContactType
            )
            if let dependency = base.dependency as? DefaultStructureViewDependencyImpl {
                viewModel.permissions = dependency.picker?.params.permissions
            }

            let VC = DepartmentVC(
                viewModel: viewModel,
                config: DepartmentVC.Config(
                    showNameStyle: ShowNameStyle.nameAndAlias,
                    routeSubDepartment: { [weak self](_, tenantId, department, _) in
                        guard let self = self else { return }
                        let newDepartmentPath = departmentPath + [department]
                        self.didSelectCollaborationDepartment(vc, tenantId: tenantId, department: department, departmentPath: newDepartmentPath, associationContactType: associationContactType)
                    },
                    departmenSupportSelect: vc.supportSelectOrganization,
                    selectedHandler: nil),
                selectionSource: selectionDataSource,
                selectChannel: .collaboration,
                resolver: userResolver)
            VC.targetPreview = vc.targetPreview
            VC.fromVC = base.targetVC
            base.push(source: VC)
        }

        func didSelectEmailContact(_ vc: StructureRootVC) {
            guard let base = base,
                    let selectionDataSource = base.dependency.selectionSource,
                    let namecardAPI = base.dependency.namecardAPI else { return }
            let vm = MailContactsContentViewModelImp(dataAPI: namecardAPI, accountID: base.dependency.mailAccountId ?? "")
            let vc = MailContactsContentView(viewModel: vm, selectionSource: selectionDataSource, config: MailContactsContentView.Config(pickerTracker: nil, selectedHandler: { _ in

            }))
            base.push(source: vc)
        }

        func didSelectSharedMailAccount(_ vc: StructureRootVC) {
            guard let base = base,
                    let groupId = base.dependency.mailGroupId,
                    let roly = base.dependency.mailGroupRole,
                    let selectionDataSource = base.dependency.selectionSource,
                    let namecardAPI = base.dependency.namecardAPI else { return }
            let vm = MailSharedAddressContentViewModel(dataAPI: namecardAPI, groupId: groupId, groupRole: roly)
            let vc = MailContactsContentView(viewModel: vm, selectionSource: selectionDataSource, config: MailContactsContentView.Config(pickerTracker: nil, selectedHandler: { _ in

            }))
            base.push(source: vc)
        }

        func didSelectMailGroupEmailAddress(_ vc: StructureRootVC) {
            guard let base = base, let selectionDataSource = base.dependency.selectionSource,
                    let groupId = base.dependency.mailGroupId,
                    let roly = base.dependency.mailGroupRole,
                    let selectionDataSource = base.dependency.selectionSource,
                    let from = base.targetVC,
                    let namecardAPI = base.dependency.namecardAPI else { return }
            let mailAddressVC = MailEmailAddressInputContentView(groupId: groupId, nameCardAPI: namecardAPI, resolver: userResolver)
            mailAddressVC.selectionSource = selectionDataSource
            navigator.push(mailAddressVC, from: from)
//            base.push(source: vc)
        }

        private func router(_ vc: UIViewController, department: Department, supportSelectDepartment: Bool, targetPreview: Bool = false) {
            // TODO: 其他configuration同步
            guard let base = base,
                    let selectionDataSource = base.dependency.selectionSource,
                    let userAPI = base.dependency.userAPI,
                    let chatAPI = base.dependency.chatAPI,
                    let chatterDriver = base.dependency.chatterDriver else { return }
            let currentDepth = base.sources.count
            let departmentAPI = DepartmentAPI(userAPI: userAPI)
            var permissions: [RustPB.Basic_V1_Auth_ActionType]?
            if let dependency = base.dependency as? DefaultStructureViewDependencyImpl {
                permissions = dependency.picker?.params.permissions
            }
            var departViewModel = DepartmentViewModel(
                department: department,
                departmentAPI: departmentAPI,
                chatAPI: chatAPI,
                chatterDriver: chatterDriver,
                filterChatter: nil, // 不支持任意的filter, 可以提供有限制的filter
                chatId: base.dependency.forceSelectedChattersInChatId,
                showContactsTeamGroup: base.dependency.showContactsTeamGroup,
                checkInvitePermission: base.dependency.checkInvitePermission,
                isCryptoModel: base.dependency.isCryptoModel,
                isCrossTenantChat: base.dependency.isCrossTenantChat,
                shouldCheckSelectPermission: base.dependency.shouldCheckHasSelectOrganizationPermission,
                disableTags: [],
                preferEnterpriseEmail: base.dependency.preferEnterpriseEmail,
                permissions: permissions,
                resolver: userResolver)
            departViewModel.mailGroupId = base.dependency.mailGroupId
            departViewModel.mailGroupRole = base.dependency.mailGroupRole
            let VC = DepartmentVC(
                viewModel: departViewModel,
                config: DepartmentVC.Config(
                    showNameStyle: base.dependency.showNameStyle,
                    routeSubDepartment: { [weak self](vc, _, department, _) in
                        guard let self = self else { return }
                        self.router(vc, department: department, supportSelectDepartment: supportSelectDepartment, targetPreview: targetPreview)
                    },
                    departmenSupportSelect: supportSelectDepartment,
                    selectedHandler: { index in
                        Tracer.trackPickerItemSelect(source: .bussinessOrg, index: index, depth: currentDepth)
                    }),
                selectionSource: selectionDataSource,
                selectChannel: .organization,
                resolver: userResolver)
            VC.targetPreview = targetPreview
            VC.fromVC = base.targetVC
            base.push(source: VC)
        }
    }
}

extension RustPB.Basic_V1_Auth_ActionType {
    func isCrypto() -> Bool {
        switch self {
        case .crateP2PCryptoChat, .inviteSameCryptoChat: return true
        @unknown default: return false
        }
    }
    func isCheckInvitePermission() -> Bool {
        switch self {
        case .inviteSameChat, .inviteSameCryptoChat, .inviteSameCrossTenantChat:
            return true
        @unknown default: return false
        }
    }
}
