//
//  DepartmentViewController.swift
//  LarkContact
//
//  Created by SuPeng on 5/9/19.
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
import LKCommonsLogging
import Homeric
import LarkContainer
import LarkSearchCore
import LarkSetting
import LarkTraitCollection
import UniverseDesignBreadcrumb
import UniverseDesignActionPanel
import LarkTab

enum SingleMultiChangeableStatus {
    case single, multi
}

struct IGLayer {
    static let commonQrCodeRadius: CGFloat = 4
    static let commonButtonRadius: CGFloat = 6
    static let commonHighlightCellRadius: CGFloat = 6
    static let commonTextFieldRadius: CGFloat = 6
    static let commonAvatarImageRadius: CGFloat = 8
    static let commonPopPanelRadius: CGFloat = 8
    static let commonAppIconRadius: CGFloat = 8
    static let commonAlertViewRadius: CGFloat = 12
    static let commonCardContainerViewRadius: CGFloat = 10
}

final class DepartmentViewController: LKContactViewController, SelectionDataSource, UserResolverWrapper {
    /// 当前部门
    static let logger = Logger.log(DepartmentViewController.self, category: "Contact.DepartmentViewController")
    private let department: Department
    private let departmentPath: [Department]
    private let showNameStyle: ShowNameStyle
    private let departmentAPI: DepartmentAPI
    private let passportUserService: PassportUserService
    private let chatterDriver: Driver<PushChatters>
    private let router: DepartmentViewControllerRouter
    @ScopedInjectedLazy private var inviteStorageService: InviteStorageService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    private lazy var contactDepartmentAdminURL: String? = {
        return userGeneralSettings?.contactsConfig.contactOrganizeDepartmentAdminURL
    }()
    private var depth: Int
    /// 是否需要展示部门群入口，目前只有联系人模块需要
    let showContactsTeamGroup: Bool
    let isFromContactTab: Bool
    var subDepartmentsItems: [SubDepartmentItem]
    /// 父级部门，从 Rust 接口返回中拿到
    /// 当用户是从「组织架构」入口顺序访问时，parentDepartments 和 departmentPath 一致
    /// 当用户从 Profile 或直接访问个人部门时，parentDepartments 是完整的，departmentPath 是缺失的
    private var parentDepartments = [Department]()
    private var departmentsAdministratorStatus: DepartmentsAdministratorStatus = .unknown
    private lazy var viewModel: DepartmentViewModel = {
        return DepartmentViewModel(
            department: department,
            departmentAPI: departmentAPI,
            chatAPI: chatAPI,
            chatterDriver: chatterDriver,
            filterChatter: configuration.filterChatter,
            chatId: configuration.forceSelectedChattersInChatId,
            showContactsTeamGroup: showContactsTeamGroup,
            checkInvitePermission: configuration.checkInvitePermission,
            isCryptoModel: configuration.isCryptoModel,
            isCrossTenantChat: configuration.isCrossTenantChat,
            shouldCheckSelectPermission: false,
            departmentsAdminStatus: departmentsAdministratorStatus,
            subDepartments: subDepartmentsItems,
            disableTags: [],
            resolver: userResolver
        )
    }()

    private lazy var memberInviteEntryView: InviteEntryView = {
        let view = InviteEntryView(
            icon: Resources.invite_member_icon,
            title: BundleI18n.LarkContact.Lark_Invitation_InviteTeamMembers_TitleBar
        )
        view.addTarget(self, action: #selector(pushMemberInvitePage), for: .touchUpInside)
        return view
    }()
    /// 显示当前所在部门的父层级
    private let departmentsPathView = UDBreadcrumb()
    private let isPublic: Bool
    private let disposeBag = DisposeBag()
    private var checkUnRegisterStatusModel: CheckUnRegisterStatusModel?
    var selectChannel: SelectChannel {
        return .organization
    }
    var userResolver: LarkContainer.UserResolver

    var tableVC: DepartmentVC?
    private var moreOptBtn: UIButton?

    private lazy var adminLabel: UILabel = {
        var tempLabel: UILabel = UILabel()
        tempLabel.textAlignment = .right
        tempLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        tempLabel.font = UIFont.systemFont(ofSize: 14)
        tempLabel.textColor = UIColor.ud.B600
        tempLabel.text = BundleI18n.LarkContact.Lark_Contacts_Manage
        tempLabel.numberOfLines = 1

        return tempLabel
    }()

    private var isShowDepartmentPrimaryMemberCount: Bool = false

    init(department: Department,
         departmentPath: [Department],
         showNameStyle: ShowNameStyle,
         departmentAPI: DepartmentAPI,
         chatAPI: ChatAPI,
         chatterAPI: ChatterAPI,
         chatterDriver: Driver<PushChatters>,
         router: DepartmentViewControllerRouter,
         searchVC: ContactSearchViewController,
         isPublic: Bool = false,
         showContactsTeamGroup: Bool,
         isFromContactTab: Bool,
         subDepartmentsItems: [SubDepartmentItem],
         departmentsAdministratorStatus: DepartmentsAdministratorStatus,
         resolver: UserResolver) throws {
        self.department = department
        self.departmentPath = departmentPath
        self.showNameStyle = showNameStyle
        self.departmentAPI = departmentAPI
        self.chatterDriver = chatterDriver
        self.router = router
        self.isPublic = isPublic
        self.showContactsTeamGroup = showContactsTeamGroup
        self.isFromContactTab = isFromContactTab
        self.subDepartmentsItems = subDepartmentsItems
        self.departmentsAdministratorStatus = departmentsAdministratorStatus
        self.depth = departmentPath.count
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        super.init(chatAPI: chatAPI, chatterAPI: chatterAPI, searchVC: searchVC, showSearch: true, resolver: resolver)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OrganizationAppReciableTrack.organizationPageLoadEnd()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchVC.isPublic = isPublic

        title = department.name

        let initialRightBarButtonItems = self.navigationItem.rightBarButtonItems ?? []
        if let url = self.contactDepartmentAdminURL, !url.isEmpty {
            switch self.departmentsAdministratorStatus {
            case .unknown:
                self.departmentAPI.isSuperOrDepartmentAdministrator()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: {[weak self] (isSuperOrDepartmentAdministrator) in
                        guard let self = self else { return }
                        if isSuperOrDepartmentAdministrator {
                            self.departmentsAdministratorStatus = .isAdmin
                        } else {
                            self.departmentsAdministratorStatus = .notAdmin
                        }
                        self.setupNavigationBar(initialRightBarButtonItems: initialRightBarButtonItems)
                    }, onError: { (error) in
                        Self.logger.error("fail to fetch isSuperOrDepartmentAdministrator: \(error.localizedDescription)")
                    })
                    .disposed(by: disposeBag)
            default:
                break
            }
        } else {
            self.departmentsAdministratorStatus = .notAdmin
        }

        let defaultCheckUnRegisterStatusModel: CheckUnRegisterStatusModel = CheckUnRegisterStatusModel(enabled: false, notice: "", urlString: "")
        self.passportUserService.checkUnRegisterStatus(scope: .quitTeam).asDriver(onErrorJustReturn: defaultCheckUnRegisterStatusModel)
            .drive(onNext: { [weak self] (checkUnRegisterStatusModel) in
                guard let self = self else { return }
                self.checkUnRegisterStatusModel = checkUnRegisterStatusModel
                self.setupNavigationBar(initialRightBarButtonItems: initialRightBarButtonItems)
            })
            .disposed(by: self.disposeBag)
        self.viewModel.isShowDepartmentPrimaryMemberCountObservable
            .asDriver(onErrorJustReturn: false)
            .drive { [weak self] enabled in
                guard let self = self else { return }
                self.isShowDepartmentPrimaryMemberCount = enabled
                self.setupNavigationBar(initialRightBarButtonItems: initialRightBarButtonItems)
            }
            .disposed(by: self.disposeBag)
        guard let inviteStorageService = self.inviteStorageService else { return }
        let hasPermission = inviteStorageService.getInviteInfo(key: InviteStorage.invitationAccessKey)
        if isFromContactTab && hasPermission {
            view.addSubview(memberInviteEntryView)
            memberInviteEntryView.snp.makeConstraints { (make) in
                make.top.equalTo(collectionBottom).offset(8)
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
            }
        }

        departmentsPathView.backgroundColor = UIColor.ud.bgBody
        let tenantName = passportUserService.userTenant.localizedTenantName
        let departmentPathNames = [BundleI18n.LarkContact.Lark_Contacts_Contacts] + departmentPath.map { $0.name == BundleI18n.LarkContact.Lark_Contacts_MoreDepartments ? tenantName : $0.name }
        departmentsPathView.setItems(departmentPathNames)
        departmentsPathView.tapCallback = { [weak self] (index) in
            SearchTrackUtil.trackPickerSelectArchitectureClick(clickType: .navigationBar(target: Homeric.PUBLIC_PICKER_SELECT_ARCHITECTURE_MEMBER_VIEW))
            self?.tapIndex(index: index)
        }
        self.view.addSubview(departmentsPathView)
        departmentsPathView.snp.makeConstraints { (make) in
            if isFromContactTab && hasPermission {
                make.top.equalTo(memberInviteEntryView.snp.bottom).offset(8)
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
                routeSubDepartment: { [weak self] (_, _, department, departmentsAdministratorStatus) in
                    guard let self = self else { return }
                    let departmentPath = self.departmentPath + [department]
                    self.router.pushDepartmentViewController(
                        self,
                        department: department,
                        departmentPath: departmentPath,
                        departmentsAdministratorStatus: departmentsAdministratorStatus
                    )
                },
                departmenSupportSelect: false,
                selectedHandler: nil),
            selectionSource: self,
            selectChannel: .organization,
            resolver: userResolver)
        self.tableVC = tableVC
        self.tableVC?.viewModel.currentDepartmentParentsObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] parents in
                guard let self = self else { return }
                Self.logger.info("department update department path")
                self.updateDepartmentPath(with: parents)
            }, onError: { (error) in
                Self.logger.error("department update department path error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        self.addChild(tableVC)

        view.addSubview(tableVC.view)
        tableVC.view.snp.makeConstraints { make in
            make.top.equalTo(departmentsPathView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        ContactTracker.Architecture.View(resolver: userResolver)
    }

    /// 更新面包屑路径，并缓存父部门
    /// 面包屑上的内容（departmentPathNames）和父部门（parentDepartments）的关系是
    /// parentDepartments 没有头部的「通讯录/联系人」及尾部的当前部门
    private func updateDepartmentPath(with parents: [Department]) {
        defer {
            tableVC?.level = departmentsPathView.getTotalItemsNumber() - 1
            // 面包屑页面的跳转使用 depth 判断，当用户从通讯录直接点击自己所属的子部门进入时
            // 面包屑上的组织架构是完整的，但 depth 并不是基于层层 push 更新的，导致 index 和 depth 不吻合
            // 使用面包屑的数据同步更新 depth 的值，-1 是为了去除首个「通讯录」
            depth = departmentsPathView.getTotalItemsNumber() - 1
        }
        let tenantName = passportUserService.userTenant.localizedTenantName
        var tenantDepartment = Department()
        tenantDepartment.id = "0"
        tenantDepartment.name = tenantName
        // 用于缓存拿下来的父级组织架构
        var departments: [Department] = [tenantDepartment]
        departments.append(contentsOf: parents)
        parentDepartments = departments

        var departmentPathNames: [String] = [BundleI18n.LarkContact.Lark_Contacts_Contacts]
        var names: [String] = departmentPath.map { $0.name == BundleI18n.LarkContact.Lark_Contacts_MoreDepartments ? tenantName : $0.name }
        if parents.isEmpty {
            /// 租户根部门或一级部门，没有父架构
            if !names.contains(where: { $0 == tenantName }) {
                departmentPathNames.append(tenantName)
            }
            departmentPathNames.append(contentsOf: names)
            departmentsPathView.setItems(departmentPathNames)
            return
        }
        departmentPathNames.append(contentsOf: departments.map { $0.name })
        if let last = names.last, last != BundleI18n.LarkContact.Lark_Contacts_Contacts {
            departmentPathNames.append(last)
        }
        departmentsPathView.setItems(departmentPathNames)
    }

    private func dissmissAll(completion: (() -> Void)? = nil) {
        if let alert = self.presentedViewController {
            alert.dismiss(animated: false) { [weak self]  in
                guard let self = self else { return }
                self.dissmissAll(completion: completion)
            }
        } else {
            completion?()
        }
    }

    @objc
    private func manageEntry() {
        Tracer.contactArchitectureClick(click: "manage", target: (self.department.id == "0" ? "madmin_department_and_user_manage_view" : "madmin_sub_department_single_view"))
        guard let contactDepartmentAdminURL = self.contactDepartmentAdminURL else {
            Self.logger.error("enter manage departments failed. contactDepartmentAdminURL is nil")
            return
        }

        let manageString = contactDepartmentAdminURL + self.department.id
        Self.logger.info("open manage link, url = \(manageString)")

        self.dissmissAll(completion: { [weak self] in
            guard let self = self else { return }
            guard let topVC = self.navigator.mainSceneTopMost, let manageURL = URL(string: manageString) else {
                Self.logger.error("openLink failed, nav is nil.")
                return
            }
            self.navigator.push(manageURL, context: [:], from: topVC)
        })
    }

    private func setupNavigationBar(initialRightBarButtonItems: [UIBarButtonItem]) {
        var btns: [UIBarButtonItem] = initialRightBarButtonItems

        if !menuItems().isEmpty {
            let optionItem = LKBarButtonItem(image: Resources.person_card_more_icon, title: nil)
            optionItem.button.addTarget(self, action: #selector(self.showMenu), for: .touchUpInside)
            btns.append(optionItem)
            moreOptBtn = optionItem.button
        }
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }

    /**
     当前RightBarButtonItems展示逻辑（v6.1）：
     1. 与通讯录页面的管理button不同，部门页面的管理入口只有"超级管理员"或者"成员与部门管理员"才有，点进去之后跳进小程序的成员与部门页
     2. 「退出团队」入口只有从通讯录组织架构进去的第一个页面有，子部门没有；而「管理」入口更深级别的部门都有
     3. 统计说明在 FG 开启 && 仅计入主部门 时展示
     */
    private func menuItems() -> [UDActionSheetItem] {
        var items = [UDActionSheetItem]()

        if departmentsAdministratorStatus == .isAdmin {
            items.append(.init(title: BundleI18n.LarkContact.Lark_ORMTotal_Button_ManageOrganizationStructure, action: { [weak self] in
                self?.manageEntry()
            }))
        }

        let enableExitTeam = self.checkUnRegisterStatusModel?.enabled ?? false
        if isFromContactTab && enableExitTeam {
            items.append(.init(title: BundleI18n.LarkContact.Lark_ORMTotal_Button_ExitCurrentTenant, action: { [weak self] in
                self?.showOptionView()
            }))
        }

        let isMemberCountByRuleEnabled = userResolver.fg.staticFeatureGatingValue(with: .enableDepartmentHeadCountRules)
        if isMemberCountByRuleEnabled && self.isShowDepartmentPrimaryMemberCount {
            items.append(.init(title: BundleI18n.LarkContact.SuiteAdmin_ORMTotal_Tooltip_DepartmentMemberInstruction, action: { [weak self] in
                guard let self = self else { return }

                if let contactDataDependency = try? self.userResolver.resolve(assert: ContactDataDependency.self) {
                    let memberCountRuleViewController = DepartmentMemberCountRuleViewController(isShowDepartmentPrimaryMemberCount: self.isShowDepartmentPrimaryMemberCount,
                                                                                                contactDataDependency: contactDataDependency)
                    self.navigator.push(memberCountRuleViewController, from: self)
                }
            }))
        }

        return items
    }

    @objc
    private func showMenu() {
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .autoAlert, isShowTitle: false))
        menuItems().forEach { actionSheet.addItem($0) }
        actionSheet.setCancelItem(text: BundleI18n.LarkContact.Lark_Legacy_Cancel)
        navigator.present(actionSheet, from: self)
    }

    @objc
    func showOptionView() {
        Tracker.post(TeaEvent(Homeric.USER_EXIT_TEAM_ENTRANCE, params: [:]))
        let actionSheetAdapter: ActionSheetAdapter = ActionSheetAdapter()
        let source: ActionSheetAdapterSource
        if let optInBtn = self.moreOptBtn {
            source = ActionSheetAdapterSource(sourceView: optInBtn, sourceRect: optInBtn.bounds, arrowDirection: .up)
        } else {
            Self.baseLogger.error("quit team moreOptBtn unset")
            source = view.defaultSource
        }
        let alert = actionSheetAdapter.create(level: .normal(source: source), title: self.checkUnRegisterStatusModel?.notice, titleColor: UIColor.ud.N500)
        actionSheetAdapter.addItem(title: self.checkUnRegisterStatusModel?.buttonText ?? BundleI18n.LarkContact.Lark_UserGrowth_LeaveTeamButton, textColor: UIColor.ud.colorfulRed) { [weak self] in
            guard let `self` = self else { return }
            Tracker.post(TeaEvent(Homeric.USER_EXIT_TEAM_ACTIONSHEET, params: [
                "key": "button_name",
                "value": "exit_team"
            ]))
            if let urlStr = self.checkUnRegisterStatusModel?.urlString, let url = URL(string: urlStr) {
                self.navigator.push(body: WebBody(url: url, hideShowMore: true), from: self)
            } else {
                Self.baseLogger.error("quit team with url null")
            }
        }
        actionSheetAdapter.addCancelItem(title: BundleI18n.LarkContact.Lark_LeaveTeam_Cancel) {
            Tracker.post(TeaEvent("user_exit_team_actionsheet", params: [
                "key": "button_name",
                "value": "cancel"
            ]))
        }
        navigator.present(alert, from: self)
    }

    @objc
    func pushMemberInvitePage() {
        self.router.pushMemberInvitePage(self)
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
        chatterInfo.name = chatter.name
        chatterInfo.avatarKey = chatter.avatarKey
        chatterInfo.email = chatter.enterpriseEmail ?? ""

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

extension DepartmentViewController {
    func tapIndex(index: Int) {
        defer {
            Tracer.contactOrganizationBreadcrumbsClick()
        }
        // 5.6 新增逻辑
        // 从 profile 页直接跳转到用户所属的子部门，虽然面包屑是完整的，但 navigation 的 vc 栈中并没有完整的 vc array
        // 拿到 targetDepartment 后，如果找不到，就 pop 出去重新弹

        if index > 0 && index <= parentDepartments.count {
            let targetDepartment = parentDepartments[index - 1]
            Self.logger.info("department did tap breadcrumbs at index \(index), target department: \(targetDepartment.name)")
            let departments = navigationController?.viewControllers.compactMap { ($0 as? DepartmentViewController)?.department.name } ?? []
            // vc 栈中没有，说明是从外部跳转的，需要重新跳
            let body = DepartmentBody(department: targetDepartment,
                                      departmentPath: [targetDepartment],
                                      showNameStyle: ShowNameStyle.nameAndAlias,
                                      showContactsTeamGroup: true,
                                      isFromContactTab: false,
                                      subDepartmentsItems: [])

            if !departments.contains(where: { $0 == targetDepartment.name }) {
                navigator.getResource(body: body, completion: { [weak self] resource in
                    guard let self = self, let targetViewController = resource as? DepartmentViewController else {
                        Self.logger.error("department target resource not work: \(resource)")
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

        let getDepartmentVC: (Int) -> DepartmentViewController? = { [weak self] (index) in
            return self?.navigationController?.viewControllers.first(where: {
                ($0 as? DepartmentViewController)?.depth == index }) as? DepartmentViewController
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
