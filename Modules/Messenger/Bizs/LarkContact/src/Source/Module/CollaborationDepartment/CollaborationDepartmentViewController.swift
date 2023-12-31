//
//  CollaborationDepartmentViewController.swift
//  LarkContact
//
//  Created by tangyunfei.tyf on 2021/3/4.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import EENavigator
import LarkAlertController
import UniverseDesignToast
import LarkNavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkNavigation
import AnimatedTabBar
import LarkActionSheet
import WebBrowser
import LarkAccountInterface
import LKCommonsTracker
import Homeric
import LarkContainer
import LarkSearchCore
import LarkTraitCollection
import LKCommonsLogging
import UniverseDesignBreadcrumb
import RustPB
import LarkTab
import LarkSetting

final class CollaborationDepartmentViewController: LKContactViewController, SelectionDataSource, UserResolverWrapper {
    static let logger = Logger.log(CollaborationDepartmentViewController.self, category: "LarkContact.CollaborationDepartmentViewController")
    fileprivate let tenantId: String?
    private let department: Department
    private let departmentPath: [Department]
    private let showNameStyle: ShowNameStyle
    private let departmentAPI: CollaborationDepartmentAPI
    private let passportUserService: PassportUserService
    private let chatterDriver: Driver<PushChatters>
    var userResolver: LarkContainer.UserResolver

    private let router: CollaborationDepartmentViewControllerRouter
    /// 父级部门，从 Rust 接口返回中拿到
    /// 当用户是从「组织架构」入口顺序访问时，parentDepartments 和 departmentPath 一致
    /// 当用户从 Profile 或直接访问个人部门时，parentDepartments 是完整的，departmentPath 是缺失的
    private var parentDepartments = [Department]()
    @ScopedInjectedLazy private var inviteStorageService: InviteStorageService?
    private var depth: Int
    /// 是否需要展示部门群入口，目前只有联系人模块需要
    let isFromContactTab: Bool
    let showContactsTeamGroup: Bool
    let associationContactType: AssociationContactType?
    private lazy var viewModel: CollaborationDepartmentViewModel = {
        return CollaborationDepartmentViewModel(
            tenantId: tenantId,
            department: department,
            departmentAPI: departmentAPI,
            chatAPI: chatAPI,
            fgService: userResolver.fg,
            chatterDriver: chatterDriver,
            filterChatter: configuration.filterChatter,
            chatId: configuration.forceSelectedChattersInChatId,
            showContactsTeamGroup: showContactsTeamGroup,
            checkInvitePermission: configuration.checkInvitePermission,
            isCryptoModel: configuration.isCryptoModel,
            checkHasLeaderPermission: false,
            disableTags: [.onLeave, .supervisor, .external],
            associationContactType: associationContactType
        )
    }()
    private lazy var tenantInviteEntryView: InviteEntryView = {
        let view = InviteEntryView(
            icon: Resources.collaboration_invite,
            title: BundleI18n.LarkContact.Lark_B2B_AddTrust
        )
        view.addTarget(self, action: #selector(pushTenantInvitePage), for: .touchUpInside)
        return view
    }()
    /// 显示当前所在部门的父层级
    private let departmentsPathView = UDBreadcrumb()
    private let isPublic: Bool
    private let disposeBag = DisposeBag()
    private var checkUnRegisterStatusModel: CheckUnRegisterStatusModel?
    var selectChannel: SelectChannel {
        return .collaboration
    }

    var tableVC: DepartmentVC?
    private var moreOptBtn: UIButton?

    init(tenantId: String?,
         department: Department,
         departmentPath: [Department],
         showNameStyle: ShowNameStyle,
         departmentAPI: CollaborationDepartmentAPI,
         chatAPI: ChatAPI,
         chatterAPI: ChatterAPI,
         chatterDriver: Driver<PushChatters>,
         router: CollaborationDepartmentViewControllerRouter,
         searchVC: ContactSearchableViewController,
         isPublic: Bool = false,
         showContactsTeamGroup: Bool,
         isFromContactTab: Bool,
         associationContactType: AssociationContactType?,
         resolver: UserResolver) throws {
        self.tenantId = tenantId
        self.department = department
        self.departmentPath = departmentPath
        self.showNameStyle = showNameStyle
        self.departmentAPI = departmentAPI
        self.chatterDriver = chatterDriver
        self.router = router
        self.isPublic = isPublic
        self.showContactsTeamGroup = showContactsTeamGroup
        self.isFromContactTab = isFromContactTab
        self.depth = departmentPath.count
        self.associationContactType = associationContactType
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        super.init(chatAPI: chatAPI, chatterAPI: chatterAPI, searchVC: searchVC, showSearch: true, resolver: resolver)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 根目录文案为搜索’xx‘组织
        if isFromContactTab && tenantId == nil {
            searchFieldWrapperView?.searchUITextField.placeholder = BundleI18n.LarkContact.Lark_B2B_PH_SearchWithEntNameOrNo
        }
        self.searchVC.isPublic = isPublic

        title = self.viewModel.currentDepartment().name

        if isFromContactTab {
            self.departmentAPI.isSuperAdministrator()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (isSuperAdministrator) in
                    self.setupView(isSuperAdministrator: isSuperAdministrator)
                }, onError: { (error) in
                    Self.logger.error("fail to fetch isSuperAdministrator: \(error.localizedDescription)")
                    self.setupView(isSuperAdministrator: false)
                })
                .disposed(by: disposeBag)
        } else {
            self.setupView(isSuperAdministrator: false)
        }
    }

    private func setupView(isSuperAdministrator: Bool) {
        if isSuperAdministrator {
            view.addSubview(tenantInviteEntryView)
            tenantInviteEntryView.snp.makeConstraints { (make) in
                make.top.equalTo(collectionBottom).offset(8)
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
            }
        }

        departmentsPathView.backgroundColor = UIColor.ud.bgBody
        let departmentPathNames = [BundleI18n.LarkContact.Lark_Contacts_Contacts] + departmentPath.map { $0.name }
        departmentsPathView.setItems(departmentPathNames)
        departmentsPathView.tapCallback = { [weak self] (index) in
            SearchTrackUtil.trackPickerSelectAssociatedOrganizationsClick(clickType: .navigationBar(target: Homeric.PUBLIC_PICKER_SELECT_ASSOCIATED_ORGANIZATIONS_VIEW))
            self?.tapIndex(index: index)
        }
        self.view.addSubview(departmentsPathView)
        departmentsPathView.snp.makeConstraints { (make) in
            if isSuperAdministrator {
                make.top.equalTo(tenantInviteEntryView.snp.bottom).offset(8)
            } else {
                make.top.equalTo(collectionBottom)
            }
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        // init的时候不确定是否能取到configuration, 放在稍后的viewLoad里
        let tableVC = DepartmentVC(
            viewModel: viewModel,
            config: DepartmentVC.Config(
                showNameStyle: showNameStyle,
                routeSubDepartment: { [weak self](_, tenantId, department, _) in
                    guard let self = self else { return }
                    guard let tenantId = tenantId else {
                        Self.logger.error("no valid tenantId for department name: \(department.name)")
                        return
                    }
                    let departmentPath = self.departmentPath + [department]
                    self.router.pushCollaborationDepartmentViewController(
                        self,
                        tenantId: tenantId,
                        department: department,
                        departmentPath: departmentPath,
                        associationContactType: associationContactType
                    )
                },
                departmenSupportSelect: false,
                selectedHandler: nil),
            selectionSource: self,
            selectChannel: .collaboration,
            resolver: userResolver)
        self.tableVC = tableVC
        Observable.combineLatest(viewModel.currentDepartmentParentsObservable(), viewModel.collaborationTenantObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (parents, tenant) in
                guard let self = self, let tenant = tenant else { return }
                Self.logger.info("collaboration department update department path")
                self.updateDepartmentPath(with: parents, tenant: tenant)
            }, onError: { (error) in
                Self.logger.error("collaboration department update department path error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        self.addChild(tableVC)

        view.addSubview(tableVC.view)
        tableVC.view.snp.makeConstraints { make in
            make.top.equalTo(departmentsPathView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    /// 更新面包屑路径，并缓存父部门
    /// 面包屑上的内容（departmentPathNames）和父部门（parentDepartments）的关系是
    /// parentDepartments 没有头部的「通讯录/联系人」及尾部的当前部门
    private func updateDepartmentPath(with parents: [Department], tenant: Contact_V1_CollaborationTenant) {

        let tenantName = tenant.tenantName
        var tenantDepartment = Department()
        tenantDepartment.id = "0"
        tenantDepartment.name = tenantName
        // 用于缓存拿下来的父级组织架构
        var departments: [Department] = [tenantDepartment]
        departments.append(contentsOf: parents)
        parentDepartments = departments

        var departmentPathNames: [String] = [BundleI18n.LarkContact.Lark_Contacts_Contacts]
        var names: [String] = departmentPath.map { $0.name }
        if parents.isEmpty {

            if !tenantName.isEmpty {
                if !names.contains(where: { $0 == tenantName }) {
                    departmentPathNames.append(tenantName)
                }
            }

            departmentPathNames.append(contentsOf: names)
            departmentsPathView.setItems(departmentPathNames)
        } else {
            departmentPathNames.append(contentsOf: departments.map { $0.name })
            if let last = names.last, last != BundleI18n.LarkContact.Lark_Contacts_Contacts {
                departmentPathNames.append(last)
            }
            departmentsPathView.setItems(departmentPathNames)
        }
    }

    @objc
    func pushTenantInvitePage() {
        self.router.pushCollaborationTenantInviteSelectPage(self, contactType: associationContactType ?? .external)
    }

    override func multiSelectDidClick() {
        super.multiSelectDidClick()
        _isMultipleObservable.onNext(self.isMultiple)
    }

    // 返回到single状态
    override func cancelDidClick() {
        super.cancelDidClick()
        _isMultipleObservable.onNext(self.isMultiple)
    }

    // MARK: SelectionDataSource
    var _isMultipleObservable = PublishSubject<Bool>()
    var isMultipleChangeObservable: Observable<Bool> { _isMultipleObservable.asObservable() }

    func select(option: Option, from: Any?) -> Bool {
        guard let chatter = option as? Chatter else {
            assertionFailure("unreachable code!!")
            return false
        }
        var chatterInfo = SelectChatterInfo(ID: chatter.id)
        chatterInfo.email = chatter.email ?? ""
        chatterInfo.name = chatter.name
        chatterInfo.avatarKey = chatter.avatarKey

        func multiAdd() -> Bool {
            guard !configuration.forceSelectedChatterIds.contains(chatter.id) else { return false }
            if !dataSource.containChatter(chatterId: chatter.id) {
                if configuration.maxSelectedNum > dataSource.selectedChatters().count {
                    Tracer.trackCreateGroupSelectMembers(.orgStructure)
                    dataSource.addChatter(chatterInfo)
                } else {
                    let alert = LarkAlertController()
                    alert.setContent(text: configuration.limitTips ?? "")
                    alert.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
                    present(alert, animated: true, completion: nil)
                    return false
                }
            }
            return true
        }

        switch self.style {
        case .multi:
            return multiAdd()
        case .single(let style):
            switch style {
            case .callback:
                dataSource.addChatter(chatterInfo)
                contactPicker.finishSelect()
            case .defaultRoute:
                router.didSelectWithChatter(self, chatter: chatter)
            case .callbackWithReset:
                dataSource.addChatter(chatterInfo)
                contactPicker.finishSelect(reset: true, extra: selectChannel)
            }
        case .singleMultiChangeable:
            let v = multiAdd()
            switch singleMultiChangeableStatus {
            case .multi:
                return v
            case .single:
                contactPicker.finishSelect()
            }
        }
        return true
    }

    func deselect(option: Option, from: Any?) -> Bool {
        if self.isMultiple == false {
            // 单选没有取消，按选中走
            _ = select(option: option, from: from)
            return true
        }
        guard let chatter = option as? Chatter else {
            assertionFailure("unreachable code!!")
            return false
        }
        guard !configuration.forceSelectedChatterIds.contains(chatter.id) else { return false }

        if dataSource.containChatter(chatterId: chatter.id) {
            var chatterInfo = SelectChatterInfo(ID: chatter.id)
            chatterInfo.name = chatter.name
            chatterInfo.avatarKey = chatter.avatarKey
            chatterInfo.email = chatter.email ?? ""
            dataSource.removeChatter(chatterInfo)
        }
        return true
    }
}

extension CollaborationDepartmentViewController {
    func tapIndex(index: Int) {
        defer {
            Tracer.contactOrganizationBreadcrumbsClick()
        }
        // 5.6 新增逻辑
        // 从 profile 页直接跳转到用户所属的子部门，虽然面包屑是完整的，但 navigation 的 vc 栈中并没有完整的 vc array
        // 拿到 targetDepartment 后，如果找不到，就 pop 出去重新弹

        if index > 0 && index <= parentDepartments.count {
            let targetDepartment = parentDepartments[index - 1]
            Self.logger.info("collaboration department did tap breadcrumbs at index \(index), target department: \(targetDepartment.name)")
            let departments = navigationController?.viewControllers.compactMap { ($0 as? CollaborationDepartmentViewController)?.department.name } ?? []
            // vc 栈中没有，说明是从外部跳转的，需要重新跳
            let rootName = viewModel.isEnableInternalCollaborationFG ? BundleI18n.LarkContact.Lark_B2B_Menu_ExternalOrg : BundleI18n.LarkContact.Lark_B2B_TrustedParties
            let tenantID = targetDepartment.name == rootName ? nil : self.tenantId
            let body = CollaborationDepartmentBody(tenantId: tenantID,
                                                   department: targetDepartment,
                                                   departmentPath: [targetDepartment],
                                                   showNameStyle: .nameAndAlias,
                                                   showContactsTeamGroup: true,
                                                   associationContactType: associationContactType)

            if !departments.contains(where: { $0 == targetDepartment.name }) {
                navigator.getResource(body: body, completion: { [weak self] resource in
                    guard let self = self, let targetViewController = resource as? CollaborationDepartmentViewController else {
                        Self.logger.error("collaboration department target resource not work: \(resource)")
                        return
                    }
                    Self.logger.info("collaboration department re-pop")
                    var viewControllers = self.navigationController?.viewControllers ?? []
                    let insertIndex = viewControllers.isEmpty ? viewControllers.startIndex : viewControllers.endIndex - 1
                    viewControllers.insert(targetViewController, at: insertIndex)
                    self.navigationController?.setViewControllers(viewControllers, animated: false)
                    self.navigationController?.popToViewController(targetViewController, animated: true)
                })
                return
            }
        }

        // 面包屑导航
        // 本页面实现：默认增加一个“联系人”item，departmentPath才是真正的显示页面的path；也就是第一个页面的departmentPath = 1
        // 因此，index为0的时候点击的是“联系人”，其他情况index和depth一定是对应的
        // index为0，考虑到ipad和iphone目前架构，“联系人”和“组织架构”不一定是同一个navigation（如双栏架构，“联系人”放在masterNavi里，"组织架构"放在detailNavi里）
        // 所以需要先跳转到第一级页面，然后“模拟”第一级页面点击返回按钮，从而返回到联系人
        let getDepartmentVC: (Int) -> CollaborationDepartmentViewController? = { [weak self] (index) in
            return self?.navigationController?.viewControllers.first(where: {
                ($0 as? CollaborationDepartmentViewController)?.depth == index }) as? CollaborationDepartmentViewController
        }
        if let departmentVC = getDepartmentVC(index) {
            navigationController?.popToViewController(departmentVC, animated: true)
        } else if index == 0, let departmentVC = getDepartmentVC(1), departmentVC.hasBackPage {
            navigationController?.popToViewController(departmentVC, animated: false)
            let count = departmentVC.navigationController?.viewControllers.count ?? 0
            // 如果栈中的 vc 大于两个，说明不是从通讯录 Tab 访问的，而是 AppLink
            if let root = departmentVC.navigationController?.viewControllers.first,
               count > 2 {
                departmentVC.navigationController?.popToRootViewController(animated: false)
                navigator.switchTab(Tab.contact.url, from: root, animated: true, completion: nil)
            } else {
                departmentVC.navigationController?.popViewController(animated: true)
            }
        }
    }
}
