//
//  TopStructureViewController.swift
//  Lark
//
//  Created by zc09v on 2017/7/21.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import RustPB
import LarkContainer
import EENavigator
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureSwitch
import AnimatedTabBar
import LarkKeyCommandKit
import LarkTraitCollection
import LarkFeatureGating
import LarkAddressBookSelector
import LarkGuide
import LarkGuideUI
import UGReachSDK
import UGSpotlight
import LarkExtensions
import UniverseDesignIcon
import ByteWebImage
import LarkNavigator

struct DataOptions: OptionSet {
    let rawValue: UInt
    static let group = DataOptions(rawValue: 1 << 0)
    static let robot = DataOptions(rawValue: 1 << 1)
    static let onCall = DataOptions(rawValue: 1 << 2)
    static let external = DataOptions(rawValue: 1 << 4)
}

enum DataOfRowType {
    case group, robot, onCall, contactApplication, external, specialFocusList, structure, collaborationTenant, nameCard, sharedMailAccount, emailAddress, userGroup, myAI
}

enum DataOfSectionType: Equatable {
    static func == (lhs: DataOfSectionType, rhs: DataOfSectionType) -> Bool {
        if case .department = lhs, case .department = rhs {
            return true
        }
        if case .contacts = lhs, case .contacts = rhs {
            return true
        }
        if case .group = lhs, case .group = rhs {
            return true
        }
        if case .helpdesk = lhs, case .helpdesk = rhs {
            return true
        }
        if case .collaborationTenant = lhs, case .collaborationTenant = rhs {
            return true
        }
        if case .namecards = lhs, case .namecards = rhs {
            return true
        }
        if case .myAI = lhs, case .myAI = rhs {
            return true
        }
        return false
    }

    /// 组织内联系人
    case department
    /// 关联组织
    case collaborationTenant
    /// 联系人
    case contacts([DataOfRow])
    /// 我的群组
    case group([DataOfRow])
    /// 服务台
    case helpdesk([DataOfRow])
    /// 邮箱通讯录
    case namecards([DataOfRow])
    /// AI助手
    case myAI([DataOfRow])
}

struct DataOfRow {
    let title: String
    let icon: UIImage?
    let isCircleIcon: Bool
    let type: DataOfRowType

    init(title: String, subTitle: String? = nil, icon: UIImage?, isCircleIcon: Bool = false, type: DataOfRowType) {
        self.title = title
        self.icon = icon
        self.isCircleIcon = isCircleIcon
        self.type = type
    }
}

// 联系人入口的总开关, 透传服务端配置
@available(*, deprecated, message: "Use `DataOfRow` instead")
struct ContactEntries: Equatable {
    var isShowRobot: Bool = false
    var isShowOrganization: Bool = false
    var isShowExternalContacts: Bool = false
    var isShowNewContacts: Bool = false
    var isShowChatGroups: Bool = false
    var isShowHelpDesks: Bool = false
    var isShowRelatedOrganizations: Bool = false
    var isShowSpecialFocusList: Bool = false
    var isShowUserGroup: Bool = false
    var isShowMyAI: Bool = false

    // 将所有属性设置到true
    mutating func setTrueToAllProperty() {
        self.isShowOrganization = true
        self.isShowExternalContacts = true
        self.isShowNewContacts = true
        self.isShowChatGroups = true
        self.isShowHelpDesks = true
        self.isShowRobot = true
        self.isShowRelatedOrganizations = true
        self.isShowSpecialFocusList = true
        self.isShowUserGroup = true
        self.isShowMyAI = true
    }
}

final class TopStructureViewController: BaseUIViewController,
                                  LarkContactTabProtocol,
                                  UITableViewDelegate,
                                  UITableViewDataSource,
                                  UITextFieldDelegate, UserResolverWrapper {

    private let tableView = UITableView(frame: .zero, style: .grouped)

    var router: TopStructureViewControllerRouter?
    var userResolver: LarkContainer.UserResolver
    static let logger = Logger.log(TopStructureViewController.self, category: "Contact")
    @ScopedInjectedLazy private var newGuideManager: NewGuideService?
    @ScopedProvider private var contactDataManager: ContactDataService?
    private var reachSDKService: UGReachSDKService? {
        return viewModel.reachService
    }

    // NaviBar
    private lazy var normalNaviBar: TitleNaviBar = {
        return TitleNaviBar(titleString: BundleI18n.LarkContact.Lark_Contacts_Contacts)
    }()
    private lazy var largeNaviBar: LargeTitleNaviBar = {
        return LargeTitleNaviBar(titleString: BundleI18n.LarkContact.Lark_Contacts_Contacts)
    }()
    private let addFriendReachPointId = "RP_SPOTLIGHT_ADD_NEW_CONTACT"
    private var spotlightReachPoint: SpotlightReachPoint?

    private lazy var headerView = UIView(frame: .zero)
    private lazy var searchView = SearchUITextField()
    private lazy var teamConversionBanner = TopStructureTeamConversionBanner()
    private let viewModel: TopStructureViewModel
    private let _firstScreenDataReady = BehaviorRelay<Bool>(value: false)

    let disposeBag = DisposeBag()
    /// 总数据源，内部包含DataOfRow
    var dataSource: [DataOfSectionType] = []
    /// 外部联系人、新联系人
    var contactsSection: [DataOfRow] = []
    /// 我的群组
    var myGroupSection: [DataOfRow] = []
    /// 服务台
    var helpdeskSection: [DataOfRow] = []
    /// 名片夹，邮箱通讯录
    var nameCardsSection: [DataOfRow] = []
    /// AI助手
    var myAISection: [DataOfRow] = []
    var totalMemberCount: Int32?
    var applicationBadge: Int = 0

    private lazy var isShowDeparment: Bool = self.viewModel.showOrgnization
    private lazy var isShowRelatedOrganization: Bool = {
        !viewModel.isCurrentAccountInfoSimple
    }()
    private let hasSearch: Bool
    var contactTab: LarkContactTab?

    /// 联系人选中策略：
    /// 1. iPhone和iPad的C模式下，无选中
    /// 2. iPad的R模式下，有选中
    /// 3. 默认选中第一行，默认选中的时机每次切tab、分屏的时候
    private var selected: IndexPath? {
        didSet {
            guard selected != oldValue else { return }
            selectionChanged()
        }
    }

    private var defaultSelect: IndexPath? {
        var indexPath: IndexPath?
        if self.dataSource.contains(.department), let index = self.getDatasourceIndexFromType(.department) {
            // row=0, 是公司名称cell，没有点击态
            // 此处默认选中的是组织架构cell
            // 修改相关逻辑需要注意
            indexPath = IndexPath(row: 1, section: index)
        } else if viewModel.contactsEntryRefactorFG, !self.collaborationTenantSection.dataIsEmpty(),
                    let index = self.getDatasourceIndexFromType(.collaborationTenant) {
            indexPath = IndexPath(row: 0, section: index)
        } else if !self.contactsSection.isEmpty, let index = self.getDatasourceIndexFromType(.contacts([])) {
            indexPath = IndexPath(row: 0, section: index)
        } else if !self.nameCardsSection.isEmpty, let index = self.getDatasourceIndexFromType(.namecards([])) {
            indexPath = IndexPath(row: 0, section: index)
        } else if !self.myGroupSection.isEmpty, let index = self.getDatasourceIndexFromType(.group([])) {
            indexPath = IndexPath(row: 0, section: index)
        } else if !self.helpdeskSection.isEmpty, let index = self.getDatasourceIndexFromType(.helpdesk([])) {
            indexPath = IndexPath(row: 0, section: index)
        }

        if let index = indexPath, tableView.cellForRow(at: index) != nil {
            // 以防还没有cell，被默认选中后崩溃
            return index
        }

        return nil
    }

    private var isSelectedByTabBar: Bool {
        guard let tabBarController = self.tabBarController else {
            /// 联系人放在侧边栏时
            return self.view.window?.lu.visibleViewController() === self
        }
        if larkSplitViewController != nil {
            return tabBarController.selectedViewController === larkSplitViewController
        }
        if splitViewController != nil {
            return tabBarController.selectedViewController === splitViewController
        }
        return tabBarController.selectedViewController === self
    }

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + [
            KeyCommandBaseInfo(
                input: "k",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkContact.Lark_Legacy_iPadShortcutsSearch
            ).binding(
                target: self,
                selector: #selector(triggerSearchBar)
            ).wraper
        ]
    }

    @objc
    func triggerSearchBar() {
        self.router?.jumpSearch(self)
    }

    private lazy var organizationSection = { () -> OrganizationStructureSectionProtocol in
        let enableInternal = true
        let section: OrganizationStructureSectionProtocol
        if enableInternal {
            let v = NewOrganizationSection(resolver: userResolver, isFromContactPage: true, isEnableInternalCollaborationFG: viewModel.internalCollaborationFG)
            v.routeDepartment = { [weak self] (department, tapOrganizationCell, subDepartmentsItems) in
                guard let self = self else { return }
                self.router?.didSelectDepartment(self, department: department, departmentPath: [department], subDepartmentsItems: subDepartmentsItems)
                if tapOrganizationCell {
                    Tracer.tarckContactEnter(type: "organization")
                }
                ContactTracker.Main.Click.Architecture()
            }
            v.routeInternal = { [weak self] (department, tenantID, _) in
                guard let self = self else { return }
                self.router?.didSelectInternalCollaboration(self, tenantID: tenantID, department: department, departmentPath: [department])
            }
            section = v
        } else {
            let v = StructureOrganizationSection(resolver: userResolver, isFromContactPage: true)
            v.routeDepartment = { [weak self] (department, tapOrganizationCell, subDepartmentsItems) in
                guard let self = self else { return }
                self.router?.didSelectDepartment(self, department: department, departmentPath: [department], subDepartmentsItems: subDepartmentsItems)
                if tapOrganizationCell {
                    Tracer.tarckContactEnter(type: "organization")
                }
                ContactTracker.Main.Click.Architecture()
            }
            section = v
        }
        return section
    }()

    private lazy var collaborationTenantSection = { () -> CollaborationTenantSection in
        let v = CollaborationTenantSection(resolver: userResolver, isFromContactPage: true)
        v.hideLastCellSeparator = true
        v.routeRelated = { [weak self] (department, _) in
            guard let self = self else { return }
            self.router?.didSelectCollaborationDepartment(self, department: department, departmentPath: [department])
        }
        return v
    }()

    init(viewModel: TopStructureViewModel,
         router: TopStructureViewControllerRouter?,
         resolver: UserResolver) {
        self.router = router
        self.viewModel = viewModel
        self.userResolver = resolver
        self.hasSearch = viewModel.showNormalNavigationBar || !viewModel.isUsingNewNaviBar
        super.init(nibName: nil, bundle: nil)

        self.createDataSouce()
        self.isLkShowTabBar = true
    }

    private func createDataSouce() {
        var contactDataSource: [DataOfSectionType] = []
        let cotnactSecitonTitle = viewModel.isCurrentAccountInfoSimple
            ? BundleI18n.LarkContact.Lark_Legacy_Contact // 联系人
            : BundleI18n.LarkContact.Lark_Legacy_StructureExternal // 外部联系人
        /// 1. department
        let department = DataOfSectionType.department
        /// 2. 关联组织
        let collaborationTenant = DataOfSectionType.collaborationTenant
        /// 4. contacts
        contactsSection = []
        contactsSection.append(DataOfRow(title: cotnactSecitonTitle,
                                         icon: Resources.external,
                                         type: .external))
        // 新的联系人
        contactsSection.append(DataOfRow(title: BundleI18n.LarkContact.Lark_Legacy_ContactsNew,
                                         icon: Resources.contact_application,
                                         type: .contactApplication))
        // 特别关注人
        if viewModel.contactEntries.isShowSpecialFocusList {
            contactsSection.append(DataOfRow(title: BundleI18n.LarkContact.Lark_IM_StarredContacts_FeatureName,
                                             icon: UDIcon.collectionOutlined.ud.withTintColor(UIColor.ud.colorfulYellow),
                                             type: .specialFocusList))
        }
        let contact = DataOfSectionType.contacts(contactsSection)

        /// 5. 名片夹
        nameCardsSection = []
        nameCardsSection.append(DataOfRow(title: BundleI18n.LarkContact.Mail_ThirdClient_EmailContacts,
                                        icon: Resources.nameCard,
                                        type: .nameCard))
        let nameCards = DataOfSectionType.namecards(nameCardsSection)

        /// 6. mygroup
        myGroupSection = []
        myGroupSection.append(DataOfRow(title: BundleI18n.LarkContact.Lark_Legacy_MyGroup,
                                        icon: Resources.group,
                                        type: .group))
        let mygroup = DataOfSectionType.group(myGroupSection)
        /// 7. helpdesk
        helpdeskSection = []
        if viewModel.showHelpdesk, viewModel.isEnableOncall {
            helpdeskSection.append(DataOfRow(title: BundleI18n.LarkContact.Lark_HelpDesk_ContactsHelpDesk,
                                             icon: Resources.oncall,
                                             type: .onCall))
        }
        let helpdesk = DataOfSectionType.helpdesk(helpdeskSection)

        /// 8. my ai
        myAISection = []
        if let aiService = viewModel.myAIService {
            // Onboarding 前使用默认的头像，Onboarding 后再通过 service 获取
            if aiService.needOnboarding.value {
                myAISection.append(DataOfRow(title: aiService.defaultResource.name,
                                             icon: aiService.defaultResource.iconSmall,
                                             isCircleIcon: true,
                                             type: .myAI))
                Self.logger.info("[MyAI.Entrance][Contact][\(#function)] need onboarding, show default icon and name")
            } else {
                myAISection.append(DataOfRow(title: aiService.info.value.name,
                                             icon: aiService.info.value.avatarImage ?? aiService.defaultResource.iconSmall,
                                             isCircleIcon: true,
                                             type: .myAI))
                Self.logger.info("[MyAI.Entrance][Contact][\(#function)] onboarding finished, show custom icon and name")
            }
        }
        let myAI = DataOfSectionType.myAI(myAISection)

        if viewModel.contactsEntryRefactorFG {
            if isShowDeparment && viewModel.contactEntries.isShowOrganization {
                contactDataSource.append(department)
            }
            if viewModel.contactEntries.isShowRelatedOrganizations {
                contactDataSource.append(collaborationTenant)
            }
            if viewModel.contactEntries.isShowNewContacts {
                contactDataSource.append(contact)
            }
            if viewModel.showNameCard { // 回滚邮箱联系人的FG控制, 为民生KA关闭该入口
                contactDataSource.append(nameCards)
            }
            if viewModel.contactEntries.isShowChatGroups {
                contactDataSource.append(mygroup)
            }
            if !helpdeskSection.isEmpty, viewModel.contactEntries.isShowHelpDesks {
                contactDataSource.append(helpdesk)
            }
            // contactEntries中已经判断了后台是否开启MyAI，所以这里只需要再额外判断FG即可，不需要接MyAIService.enable（内部会再判断后台是否开启MyAI）
            if !myAISection.isEmpty, viewModel.contactEntries.isShowMyAI, viewModel.larkMyAIMainSwitch, viewModel.myAIService?.enable.value ?? false {
                contactDataSource.append(myAI)
            } else {
                Self.logger.info("[MyAI.Entrance][Contact][\(#function)] not showing myAI entrance, isShowMyAI: \(viewModel.contactEntries.isShowMyAI), mainSwitch: \(viewModel.larkMyAIMainSwitch), isEnabled: \(viewModel.myAIService?.enable.value ?? false)") // swiftlint:disable:this line_length
            }
        } else {
            contactDataSource = [contact, mygroup, helpdesk]
            if viewModel.showNameCard {
                contactDataSource.insert(nameCards, at: 2)
            }
            if isShowDeparment {
                contactDataSource.insert(department, at: 0)
            }
            if !myAISection.isEmpty, viewModel.contactEntries.isShowMyAI, viewModel.larkMyAIMainSwitch,
               viewModel.myAIService?.enable.value ?? false {
                contactDataSource.append(myAI)
            } else {
                Self.logger.info("[MyAI.Entrance][Contact][\(#function)] not showing myAI entrance, isShowMyAI: \(viewModel.contactEntries.isShowMyAI), mainSwitch: \(viewModel.larkMyAIMainSwitch), isEnabled: \(viewModel.myAIService?.enable.value ?? false)") // swiftlint:disable:this line_length
            }
        }
        dataSource = contactDataSource
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isToolBarHidden = true
        view.backgroundColor = UIColor.ud.bgBase

        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                if self.isSelectedByTabBar {
                    self.setSelectionIfNeeded()
                }
            }).disposed(by: disposeBag)

        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.rowHeight = 68
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.animatedTabBarController?.tabbarHeight ?? 0, right: 0)
        setupSearchView()
        bindViewModel()

        var identifier = String(describing: ContactTableViewCell.self)
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: identifier)
        identifier = String(describing: TopStructureTableViewCell.self)
        tableView.register(TopStructureTableViewCell.self, forCellReuseIdentifier: identifier)
        identifier = String(describing: DataItemViewCell.self)
        tableView.register(DataItemViewCell.self, forCellReuseIdentifier: identifier)
        self.setSelectionIfNeeded()

        if self.viewModel.showNormalNavigationBar {
            isNavigationBarHidden = true
            normalNaviBar.addBackButton()
            view.addSubview(normalNaviBar)
            normalNaviBar.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview()
            }
            self.view.addSubview(tableView)
            tableView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(normalNaviBar.snp.bottom)
            }
        } else if !viewModel.isUsingNewNaviBar {
            isNavigationBarHidden = true
            let searchItem = TitleNaviBarItem(image: Resources.search, action: { [weak self] _ in
                guard let self = self else { return }
                self.router?.jumpSearch(self)
            })
            normalNaviBar.rightItems = [searchItem]
            NaviBarAnimator.setUpAnimatorWith(
                scrollView: tableView,
                normalNaviBar: normalNaviBar,
                largeNaviBar: largeNaviBar,
                toVC: self
            )
        } else {
            isNavigationBarHidden = true
            self.view.addSubview(tableView)
            self.view.sendSubviewToBack(tableView)
            tableView.snp.makeConstraints({ make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(naviHeight)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            })
        }

        self.organizationSection.setup(tableView: self.tableView) { [weak self] (result) in
            switch result {
            case .success:
                // 组织架构数据请求成功后在此做默认选中cell的逻辑（iPad R模式下）
                self?._firstScreenDataReady.accept(true)
            case .failure:
                break
            }
        }

        self.collaborationTenantSection.setup(tableView: self.tableView) { (_) in

        }

        self.viewModel.currentUserType
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self else { return }
                self.isShowDeparment = (state.user.type != .simple) && self.viewModel.showOrgnization
                self.createDataSouce()
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        // 监听刷新信号
        self.viewModel.reloadOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.createDataSouce()
                self.tableView.reloadData()
                self.setSelectionIfNeeded(atIndexPath: self.defaultSelect)
            }).disposed(by: self.disposeBag)

        // 监听 MyAI FG 开关
        self.viewModel.myAIService?.enable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.createDataSouce()
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        // 监听 MyAI 头像、名称变化
        self.viewModel.myAIService?.info
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.createDataSouce()
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        // 注册气泡ReachPoint
        self.spotlightReachPoint = reachSDKService?.obtainReachPoint(reachPointId: addFriendReachPointId, bizContextProvider: nil)
        self.spotlightReachPoint?.datasource = self
        self.spotlightReachPoint?.singleDelegate = self

        // 目前RP_SPOTLIGHT_ADD_NEW_CONTACT和banner收敛在同一个SCENE_CONTACT内，同时触发
        self.viewModel.tryExposeSceneContact()
        ContactTracker.Main.View(resolver: userResolver)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.bannerWidthChanged(self.view.frame.width)

        // https://stackoverflow.com/questions/34661793/setting-tableheaderview-height-dynamically
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        let size = headerView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .defaultLow,
            verticalFittingPriority: .defaultHigh
        )
        let height = size.height
        headerView.translatesAutoresizingMaskIntoConstraints = true
        if headerView.frame.height != height {
            headerView.frame.size.height = height
            tableView.layoutIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.viewModel.trackEnterContactHome()

        /// 统一添加好友逻辑
        self.handleInviteEntry()
        self.viewModel.updateContactAuthStatusIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.refreshListByFecthContactEntries()
        if isSelectedByTabBar {
            // 主要处理c模式下，返回到主页
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [self] in
                self.setSelectionIfNeeded(reset: true)
            })
        }

        // 新注册用户引导
        showOnboardingGuideIfNeed()
        if let view = headerView.subviews.first(where: { !$0.isHidden }) {
            return
        }
        self.removeTableHeaderView()
    }

    private func bindViewModel() {
        viewModel.getBannerViewDriver().drive(onNext: { [weak self] banner in
            guard let self = self else { return }

            self.headerView.subviews.forEach({ (view) in
                view.removeFromSuperview()
            })
            self.setupSearchView()

            let hasBanner = banner != nil
            var headerViewHeight = self.hasSearch ? SearchViewLayout.searchHeight : 0
            if let (bannerView, bannerHeight) = banner {
                self.updateBannerView(bannerView: bannerView, height: bannerHeight)
                headerViewHeight += bannerHeight
                headerViewHeight += self.hasSearch ? SearchViewLayout.verticalPadding : 0
            }

            if self.hasSearch || hasBanner {
                let bottomConstraint = banner?.0.snp.bottom ?? self.searchView.snp.bottom
                self.headerView.snp.remakeConstraints { (make) in
                    make.bottom.equalTo(bottomConstraint)
                    make.height.equalTo(headerViewHeight)
                }
                self.tableView.tableHeaderView = self.headerView
                self.headerView.layoutIfNeeded()

            } else {
                self.removeTableHeaderView()
            }

            self.tableView.reloadData()

        }).disposed(by: disposeBag)
    }

    private func removeTableHeaderView() {
        /// fix https://stackoverflow.com/questions/18880341
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.01))
    }

    private func setupSearchView() {
        guard hasSearch else { return }

        searchView.isHidden = !hasSearch
        if !headerView.subviews.contains(searchView) {
            headerView.addSubview(searchView)
        }
        searchView.canEdit = false
        searchView.tapBlock = { [weak self] (_) in
            guard let `self` = self else { return }
            self.router?.jumpSearch(self)
        }
        searchView.delegate = self
        searchView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(SearchViewLayout.horizontalPadding)
            make.top.equalToSuperview().offset(SearchViewLayout.verticalPadding)
            make.height.equalTo(SearchViewLayout.searchHeight)
        }
        tableView.tableHeaderView = headerView
    }

    private func updateBannerView(bannerView: UIView, height: CGFloat) {
        let teamConversionTop = hasSearch ? SearchViewLayout.searchHeight + SearchViewLayout.verticalPadding : 0
        headerView.addSubview(bannerView)
        bannerView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(teamConversionTop)
            make.height.equalTo(height)
        }
    }

    private func updateTableViewHeader() {
        let hasTeamConversion = viewModel.needShowTeamConversionBanner

        searchView.isHidden = !hasSearch
        teamConversionBanner.isHidden = !hasTeamConversion

        guard hasSearch || hasTeamConversion else {
            self.removeTableHeaderView()
            return
        }

        let verticalPadding: CGFloat = 6.0
        let horizontalPadding: CGFloat = 16.0
        let searchHeight: CGFloat = 32.0
        let teamConversionTop =
            hasSearch ? searchHeight + verticalPadding * 3.0 : verticalPadding
        headerView.backgroundColor = UIColor.ud.bgBase

        if hasSearch {
            if !headerView.subviews.contains(searchView) {
                headerView.addSubview(searchView)
            }
            searchView.canEdit = false
            searchView.tapBlock = { [weak self] (_) in
                guard let `self` = self else { return }
                self.router?.jumpSearch(self)
            }
            searchView.delegate = self

            searchView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
                make.top.equalToSuperview().offset(verticalPadding)
                make.height.equalTo(searchHeight)
            }
        }

        if hasTeamConversion {
            Tracer.trackGuideUpdateBannerShow()
            if headerView.subviews.contains(teamConversionBanner) {
                teamConversionBanner.snp.updateConstraints { (make) in
                    make.top.equalToSuperview().offset(teamConversionTop)
                }
            } else {
                headerView.addSubview(teamConversionBanner)
                teamConversionBanner.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(horizontalPadding)
                    make.top.equalToSuperview().offset(teamConversionTop)
                }
            }
            teamConversionBanner.entryHandler = { [weak self] in
                guard let self else { return }
                self.router?.jumpTeamConversion(navigator: self.userResolver.navigator)
            }
            teamConversionBanner.closeHandler = { [weak self] in
                self?.handleTeamConversionBannerClose()
            }
        }

        let bottomConstraint =
            hasTeamConversion ? teamConversionBanner.snp.bottom : searchView.snp.bottom
        headerView.snp.remakeConstraints { (make) in
            make.bottom.equalTo(bottomConstraint).offset(verticalPadding)
        }
        headerView.layoutIfNeeded()
        // self sizing headerView see viewDidLayoutSubviews
        tableView.tableHeaderView = headerView
    }

    private func handleTeamConversionBannerClose() {
        Tracer.trackGuideUpdateBannerClose()
        viewModel.closeTeamConversionBanner()
        tableView.beginUpdates()
        updateTableViewHeader()
        tableView.endUpdates()
    }

    var firstScreenDataReady: BehaviorRelay<Bool>? {
        return _firstScreenDataReady
    }

    func contactTabApplicationBadgeUpdate(_ applicationBadge: Int) {
        self.applicationBadge = applicationBadge
        TopStructureViewController.logger.debug("[NewContactBadge] applicationBadge update \(applicationBadge)")
        if self.isViewLoaded {
            self.createDataSouce()
            self.tableView.reloadData()
        }
        if applicationBadge > 0 {
            self.viewModel.trackNewContactBadgeShow()
        }
    }
    func contactTabRootController() -> UIViewController {
        return self
    }

    fileprivate var inviteEntryType: InviteEntryType?

    func handleInviteEntry() {
        self.viewModel.fetchInviteEntryType { [weak self] (type) in
            guard let self = self else { return }

            let addBarItemHandler = { (type: InviteEntryType) in
                TopStructureViewController.logger.info("fetchInviteEntryType: \(type)")
                let addInviteMemberItem: TitleNaviBarItem = TitleNaviBarItem(
                    image: Resources.unified_invite_icon,
                    text: nil,
                    badge: .none,
                    action: { [weak self] _ in
                        guard let `self` = self else { return }
                        self.routePageWithInviteType(type: type)
                        Tracer.trackReferContactClick(rewardNewTenant: self.viewModel.awardExternalInviteEnable ? 1 : 0)
                    })
                if self.viewModel.showNormalNavigationBar {
                    self.normalNaviBar.rightItems = [addInviteMemberItem]
                    self.normalNaviBar.rightStackView.snp.updateConstraints({ (make) in
                        make.right.equalToSuperview().offset(-16)
                    })
                } else if !self.viewModel.isUsingNewNaviBar {
                    self.largeNaviBar.rightItems = [addInviteMemberItem]
                    self.largeNaviBar.rightStackView.snp.updateConstraints({ (make) in
                        make.right.equalToSuperview().offset(-16)
                    })
                } else {
                    self.inviteEntryType = type
                    self.reloadNaviBar()
                }
                Tracer.trackReferContactView(rewardNewTenant: self.viewModel.awardExternalInviteEnable ? 1 : 0)
            }

            switch type {
            case .external:
                addBarItemHandler(type)
            default: break
            }
        }
    }

    private func routePageWithInviteType(type: InviteEntryType?) {
        guard let type = type else { return }
        switch type {
        case .union:
            Tracer.trackInvitePeopleContactsClick(entry_type: "union")
            let body = UnifiedInvitationBody()
            if Display.pad {
                navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                navigator.push(body: body, from: self)
            }
        case .member:
            Tracer.trackInvitePeopleContactsClick(entry_type: "internal")
            _ = viewModel.unifiedInvitationService.dynamicMemberInvitePageResource(
                baseView: view,
                sourceScenes: .department,
                departments: [])
                .subscribe(onNext: { [weak self] (resource) in
                    guard let `self` = self else { return }
                    switch resource {
                    case .memberFeishuSplit(let body):
                        if Display.pad {
                            self.navigator.present(
                                body: body,
                                wrap: LkNavigationController.self,
                                from: self,
                                prepare: { $0.modalPresentationStyle = .formSheet }
                            )
                        } else {
                            self.navigator.push(body: body, from: self)
                        }
                    case .memberLarkSplit(let body):
                        if Display.pad {
                            self.navigator.present(
                                body: body,
                                wrap: LkNavigationController.self,
                                from: self,
                                prepare: { $0.modalPresentationStyle = .formSheet }
                            )
                        } else {
                            self.navigator.push(body: body, from: self)
                        }
                    case .memberDirected(let body):
                        if Display.pad {
                            self.navigator.present(
                                body: body,
                                wrap: LkNavigationController.self,
                                from: self,
                                prepare: { $0.modalPresentationStyle = .formSheet }
                            )
                        } else {
                            self.navigator.push(body: body, from: self)
                        }
                    }
                })
        case .external:
            Tracer.trackInvitePeopleContactsClick(entry_type: "external")
            Tracer.trackExternalInvite("contacts_tab_invite")
            let body = ExternalContactDynamicBody(scenes: .externalInvite, fromEntrance: .contact)
            if Display.pad {
                navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                navigator.push(body: body, from: self)
            }
        case .none:
            Tracer.trackInvitePeopleContactsClick(entry_type: "external")
            routePageWithInviteType(type: .external)
        }
    }

    func setSelectionIfNeeded(reset: Bool = false, atIndexPath: IndexPath? = nil) {
        var canSelect = false
        Feature.on(.contactSelection).apply(on: {
            // 开关控制，iPhone无选中;
            // iPad C模式下无选中
            // iPad R模式下有选中
            canSelect = self.view.window?.lkTraitCollection.horizontalSizeClass == .regular
        }, off: {})

        if canSelect {
            if let indexPath = atIndexPath {
                selected = indexPath
            } else {
                selected = selected ?? defaultSelect
            }
            // 此处没有处理强制 reset 的情况，会导致 MyAI 这种可重复点击的 Cell 点击无响应
            if reset {
                selected = nil
            }
            tableView.selectRow(at: selected, animated: true, scrollPosition: .none)
        } else {
            if reset {
                selected = nil
            }
            tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
        }
    }

    private func selectionChanged() {
        guard let indexPath = selected else { return }
        let section = indexPath.section
        let row = indexPath.row
        guard section < dataSource.count else { return }

        var dataOfRow: DataOfRow?
        let sectionData = dataSource[section]
        switch sectionData {
        case .department:
            self.organizationSection.tableView(self.tableView, didSelectRowAt: indexPath)
            OrganizationAppReciableTrack.organizationPageLoadStart()
        case .collaborationTenant:
            self.collaborationTenantSection.tableView(self.tableView, didSelectRowAt: indexPath)
        case let .contacts(data):
            dataOfRow = data[row]
        case let .group(data):
            dataOfRow = data[row]
        case let .helpdesk(data):
            dataOfRow = data[row]
        case let .namecards(data):
            dataOfRow = data[row]
        case let .myAI(data):
            dataOfRow = data[row]
        }

        // router
        if let dataOfRow = dataOfRow {
            switch dataOfRow.type {
            case .contactApplication:
                router?.didSelectContactApplication(self)
                NewContactsAppReciableTrack.newContactPageLoadStart()
                ContactTracker.Main.Click.New()
            case .group:
                router?.didSelectMyGroups(self)
                ContactTracker.Main.Click.Group()
            case .robot:
                router?.didSelectBots(self)
            case .onCall:
                router?.didSelectOnCalls(self)
                ContactTracker.Main.Click.Helpdesk()
            case .external:
                router?.didSelectExternal(self)
                ContactTracker.Main.Click.External()
            case .specialFocusList:
                router?.didSelectSpecialFocusList(self)
                ContactTracker.Main.Click.SpecialFocusList()
            case .structure:
                break
            case .collaborationTenant:
                break
            case .nameCard:
                router?.didSelectNameCards(self)
                ContactTracker.Main.Click.Email()
            case .sharedMailAccount:
                break
            case .emailAddress:
                break
            case .userGroup:
                break
            case .myAI:
                router?.didSelectMyAI(self)
                // viewDidAppear会重置，但是我们是present的，所以需要手动重置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.setSelectionIfNeeded(reset: true)
                }
                ContactTracker.Main.Click.MyAI()
            }
            trackTab(type: dataOfRow.type)
        }
    }

    private func getDatasourceIndexFromType(_ type: DataOfSectionType) -> Int? {
        return dataSource.firstIndex { (obj) -> Bool in
            if case type = obj {
                return true
            }
            return false
        }
    }

    //  type: newcontact, organization, groups, bots, oncalls, external
    private func trackTab(type: DataOfRowType) {
        switch type {
        case .contactApplication:
            Tracer.tarckContactEnter(type: "newcontact")
        case .external:
            Tracer.tarckContactEnter(type: "external")
        case .group:
            Tracer.tarckContactEnter(type: "groups")
        case .onCall:
            Tracer.tarckContactEnter(type: "oncalls")
        case .robot:
            Tracer.tarckContactEnter(type: "bots")
        case .structure:
            break
        case .collaborationTenant:
            break
        case .nameCard:
            break
        case .sharedMailAccount:
            break
        case .emailAddress:
            break
        case .specialFocusList:
            break
        case .userGroup:
            break
        case .myAI:
            break
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < dataSource.count else {
            return 0
        }
        let sectionData = dataSource[section]
        var numOfRow = 0
        switch sectionData {
        case .department:
            numOfRow = self.organizationSection.numberOfRows
        case .collaborationTenant:
            numOfRow = self.collaborationTenantSection.numberOfRows
        case let .contacts(data):
            numOfRow = data.count
        case let .group(data):
            numOfRow = data.count
        case let .helpdesk(data):
            numOfRow = data.count
        case let .namecards(data):
            numOfRow = data.count
        case let .myAI(data):
            numOfRow = data.count
        }
        return numOfRow
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section > 0 else { return nil }

        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: TableViewLayout.sectionHeaderHeight))
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section > 0) ? TableViewLayout.sectionHeaderHeight : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < dataSource.count - 1 else { return nil }

        let departmentSectionIndex = getDatasourceIndexFromType(.department)
        if !self.isShowDeparment, let index = departmentSectionIndex, section == index {
            return nil
        }
        let sectionSeparatView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: TableViewLayout.sectionFooterHeight))
        sectionSeparatView.backgroundColor = UIColor.ud.bgBase
        let sectionBorderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 3))
        sectionBorderView.backgroundColor = UIColor.ud.bgBody
        sectionSeparatView.addSubview(sectionBorderView)
        return sectionSeparatView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section < dataSource.count - 1) ? TableViewLayout.sectionFooterHeight : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < dataSource.count else {
            return 0
        }
        let sectionData = dataSource[indexPath.section]
        switch sectionData {
        case .department:
            return self.organizationSection.tableView(tableView, heightForRowAt: indexPath)
        default:
            return TableViewLayout.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selected == indexPath {
            setSelectionIfNeeded()
        }
        let row = indexPath.row
        let section = indexPath.section
        let sectionData = dataSource[section]

        let identifier = String(describing: DataItemViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? DataItemViewCell
        switch sectionData {
        case .department:
            /// 组织架构
            return self.organizationSection.tableView(tableView, cellForRowAt: indexPath)
        case .collaborationTenant:
            return self.collaborationTenantSection.tableView(tableView, cellForRowAt: indexPath)
        case let .contacts(data):
            if let cell = cell {
                var dataOfRow = data[row]
                if row == 0 {
                    let contactsTitle = self.isShowDeparment
                        ? BundleI18n.LarkContact.Lark_Legacy_StructureExternal
                        : BundleI18n.LarkContact.Lark_Legacy_Contact
                    dataOfRow = DataOfRow(title: contactsTitle, icon: dataOfRow.icon, type: dataOfRow.type)
                } else if row == 1, dataOfRow.type == .contactApplication {
                    if self.applicationBadge == 0 {
                        cell.updateBadge(isHidden: true, badge: self.applicationBadge)
                    } else {
                        cell.updateBadge(isHidden: false, badge: self.applicationBadge)
                    }
                }
                cell.dataItem = dataOfRow
                return cell
            }
        case let .group(data):
            if let cell = cell {
                cell.dataItem = data[row]
                return cell
            }
        case let .helpdesk(data):
            if let cell = cell {
                cell.dataItem = data[row]
                return cell
            }
        case let .namecards(data):
            if let cell = cell {
                cell.dataItem = data[row]
                return cell
            }
        case let .myAI(data):
            if let cell = cell {
                cell.dataItem = data[row]
                return cell
            }
        }
        return UITableViewCell(frame: .zero)
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.section < dataSource.count else { return }

        let cell = tableView.cellForRow(at: indexPath)
        if cell is TenantItemViewCell {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.selectRow(at: selected, animated: false, scrollPosition: .none)
            return
        }

        // 点击展示更多不需要更新选中态
        if dataSource[indexPath.section] == .department, !organizationSection.enableSelect(indexPath: indexPath) {
            organizationSection.tableView(tableView, didSelectRowAt: indexPath)
            return
        }

       selected = indexPath
       setSelectionIfNeeded()
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }

    deinit {
        self.reachSDKService?.recycleReachPoint(reachPointId: addFriendReachPointId, reachPointType: SpotlightReachPoint.reachPointType)
    }
}

/// 引导
extension TopStructureViewController {
    // 新注册用户引导
    private func showOnboardingGuideIfNeed() {
        let newRegisterGuideEnbale = viewModel.newRegisterGuideEnbale
        TopStructureViewController.logger.debug("[ContactGuide] showLarkGuideBubble",
                                                additionalData: [
                                                    "newRegisterGuideEnbale": "\(newRegisterGuideEnbale)"
                                                ])
        guard newRegisterGuideEnbale else { return }
        showLarkGuideBubble()
    }

    /// 使用LarkGuide，展示的引导
    private func showLarkGuideBubble() {
        // 创建单个气泡的配置
        let guideKey = "mobile_contact_add_friends"
        guard let tabBar = self.animatedTabBarController as? MainTabbarProtocol,
              let addMemberButton = tabBar.naviBar?.getButtonByType(buttonType: .first) else { return }
        if addMemberButton.frame == .zero {
            // 此时如果未布局，需要提前布局下
            tabBar.naviBar?.layoutIfNeeded()
        }

        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(addMemberButton),
                                      offset: GuideBubbleLayout.targetAreaOffset,
                                      targetRectType: .circle),
            textConfig: TextInfoConfig(title: BundleI18n.LarkContact.Lark_Guide_SpotlightFindContactsTitle,
                                       detail: BundleI18n.LarkContact.Lark_Guide_SpotlightFindContactsDesc),
            bottomConfig: BottomConfig(leftBtnInfo: ButtonInfo(title: BundleI18n.LarkContact.Lark_Guide_SpotlightButtonKnow),
                                       rightBtnInfo: ButtonInfo(title: BundleI18n.LarkContact.Lark_Guide_SpotlightFindContactsAddButton))
        )
        let singleBubbleConfig = SingleBubbleConfig(
            delegate: self,
            bubbleConfig: bubbleConfig,
            maskConfig: MaskConfig()
        )
        newGuideManager?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                bubbleType: .single(singleBubbleConfig),
                                                dismissHandler: nil)
    }

    /// 处理下一步
    private func handleNewUserRegisterGuideNextAction() {
        self.contactDataManager?.getLocalContactsAsyncForOnboarding(
            hostProvider: self,
            successCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                let body = ContactPickListBody(pickFinishCallBack: {
                    TopStructureViewController.logger.debug("[ContactPick] pick finished")
                })
                self.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepare: { [weak self] (vc) in
                        guard let self = self else { return }
                        if self.view.window?.lkTraitCollection.horizontalSizeClass == .regular {
                            vc.modalPresentationStyle = .formSheet
                        } else {
                            vc.modalPresentationStyle = .fullScreen
                        }
                    }
                )
                TopStructureViewController.logger.debug("[ContactPick] getLocalContacts success")

            }, failedCallBack: { _ in
                // 步骤结束
                TopStructureViewController.logger.debug("[ContactPick] getLocalContacts failed")
            })
        TopStructureViewController.logger.debug("[ContactPick] request contact pick onboarding")
    }

}

extension TopStructureViewController: SearchBarTransitionBottomVCDataSource {

    var naviBarView: UIView {
        return self.largeNaviBar
    }

    var searchTextField: SearchUITextField {
        return self.searchView
    }

    // transform push transition to MainTabBarController
    var animationProxy: CustomNaviAnimation? {
        return viewModel.isUsingNewNaviBar
            ? self.animatedTabBarController as? CustomNaviAnimation
            : self
    }

    func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarPresentTransition()
    }

    func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarDismissTransition()
    }
}

extension TopStructureViewController: TabbarItemTapProtocol {

    func onTabbarItemDoubleTap() {
        setSelectionIfNeeded()
    }

    func onTabbarItemTap(_ isSameTab: Bool) {
        setSelectionIfNeeded()
    }

}

extension TopStructureViewController: LarkNaviBarAbility { }
extension TopStructureViewController: LarkNaviBarDelegate {
    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search: router?.jumpSearch(self)
        case .first: self.routePageWithInviteType(type: self.inviteEntryType)
        default: break
        }
    }
}

extension TopStructureViewController: LarkNaviBarDataSource {
    var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: BundleI18n.LarkContact.Lark_Contacts_Contacts)
    }

    var isNaviBarEnabled: Bool {
        return viewModel.isUsingNewNaviBar
    }

    var isDrawerEnabled: Bool {
        return viewModel.isUsingNewNaviBar
    }

    func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        switch type {
        case .first: return self.inviteEntryType == nil ? nil : Resources.iconAddMember
        default: return nil
        }
    }
}

extension TopStructureViewController: SpotlightReachPointDataSource {

    func onShow(spotlightReachPoint: SpotlightReachPoint, spotlightData: UGSpotlightData, isMult: Bool) -> SpotlightBizProvider? {
        guard let tabBar = self.animatedTabBarController as? MainTabbarProtocol,
              let addMemberButton = tabBar.naviBar?.getButtonByType(buttonType: .first) else { return nil }

        if addMemberButton.frame == .zero {
            // 此时如果未布局，需要提前布局下
            tabBar.naviBar?.layoutIfNeeded()
        }

        let provider = SpotlightBizProvider(hostProvider: {
            return self
        }, targetSourceTypes: {
            let targets: [TargetSourceType] = [.targetView(addMemberButton)]
            return targets
        })
        Self.logger.debug("onShow spotlightData: \(spotlightData)，isMult: \(isMult)")
        return provider
    }
}

extension TopStructureViewController: UGSingleSpotlightDelegate {
    func didClickLeftButton(bubbleConfig: BubbleItemConfig) {
        // close guide
        self.spotlightReachPoint?.closeSpotlight(hostProvider: self)
        self.reachSDKService?.recycleReachPoint(reachPointId: addFriendReachPointId, reachPointType: SpotlightReachPoint.reachPointType)
    }
    func didClickRightButton(bubbleConfig: BubbleItemConfig) {
        // close guide
        self.spotlightReachPoint?.closeSpotlight(hostProvider: self)
        // next action
        handleNewUserRegisterGuideNextAction()
        self.reachSDKService?.recycleReachPoint(reachPointId: addFriendReachPointId, reachPointType: SpotlightReachPoint.reachPointType)
    }
}

extension TopStructureViewController: GuideSingleBubbleDelegate {
    func didClickLeftButton(bubbleView: GuideBubbleView) {
        // close guide
        self.newGuideManager?.closeCurrentGuideUIIfNeeded()
    }

    func didClickRightButton(bubbleView: GuideBubbleView) {
        // close guide
        self.newGuideManager?.closeCurrentGuideUIIfNeeded()
        // next action
        handleNewUserRegisterGuideNextAction()
    }
}

extension TopStructureViewController {
    enum SearchViewLayout {
        static let verticalPadding: CGFloat = 6.0
        static let horizontalPadding: CGFloat = 16.0
        static let searchHeight: CGFloat = 32.0
    }
    enum TableViewLayout {
        static let sectionHeaderHeight: CGFloat = 3.0
        static let sectionFooterHeight: CGFloat = 11.0
        static let rowHeight: CGFloat = 60
    }
    enum GuideBubbleLayout {
        static let targetAreaOffset: CGFloat = 8.0
    }
}
