//
//  StructureRootVC.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/4.
//

import Foundation
import UIKit
import RustPB
import RxSwift
import RxRelay
import LarkUIKit
import LarkContainer
import LarkSDKInterface
import LarkSearchCore
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkAccountInterface
import LarkFeatureGating
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import UniverseDesignIcon
import LarkSetting

protocol StructureRootVCRouter {
    func didSelectGroupWithChat(_ vc: StructureRootVC)
    func didSelectBotWithChatter(_ vc: StructureRootVC)
    func didSelectOnCallWithOncall(_ vc: StructureRootVC)
    func didSelectExternal(_ vc: StructureRootVC)
    func didSelectUserGroup(_ vc: StructureRootVC)
    func didSelectDepartment(_ vc: StructureRootVC, department: Department)
    func didSelectCollaborationDepartment(_ vc: StructureRootVC,
                                          tenantId: String?,
                                          department: Department,
                                          departmentPath: [Department],
                                          associationContactType: AssociationContactType?)
    func didSelectEmailContact(_ vc: StructureRootVC)
    func didSelectSharedMailAccount(_ vc: StructureRootVC)
    func didSelectMailGroupEmailAddress(_ vc: StructureRootVC)
}

/// 组织架构根部的导航视图
/// 做为子VC，嵌入到其他view视图里
final class StructureRootVC: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewKeyboardHandlerDelegate, UserResolverWrapper {
    var pickerScene: String?
    var currentSection: ((Section) -> Void)?
    var keyboardHandler: TableViewKeyboardHandler?
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }
    static let logger = Logger.log(StructureRootVC.self, category: "StructureRootVC")
    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }

    private let router: StructureRootVCRouter
    @ScopedInjectedLazy private var structureService: StructureService?
    private(set) var contactEntries = ContactEntries()
    private let disposeBag = DisposeBag()
    // 联系人列表服务端开关控制fg
    private lazy var contactsEntryRefactorFG = {
        return userResolver.fg.staticFeatureGatingValue(with: "messenger.contacts.entry_refactor")
    }()
    private lazy var isShowMailContactFG = {
        return userResolver.fg.staticFeatureGatingValue(with: "contact.contactcards.email")
    }()
    // tableView's header and footer and be used to custom
    let tableView = UITableView(frame: .zero, style: .plain)
    let bag = DisposeBag()

    var isCurrentAccountInfoSimple: Bool {
        return passportUserService?.user.type == .simple
    }

    var selectedRecommendList: [SearchResultType] {
        return fromFilterRecommendSection.selectedDataItem.map { $0.value }
    }

    var defaultOption: [Option] = [] {
        didSet {
            fromFilterRecommendSection.defaultOption = defaultOption
            tableView.reloadData()
        }
    }

    // Section排序，利用自增int，避免手写数字
    enum Section: Int {
        case group
        case robot
        case onCall
        case external
        case organization
        case todoRecommend
        case todoInChat
        // 关联组织
        case collaborationTenant
        /// 用户组
        case userGroup
        /// 就是之前的nameCard，为了避免歧义
        case emailContact
        /// 公共邮箱列表
        case sharedMailAccount
        /// 输入邮箱地址 （目前只给email业务邮件组使用，有耦合，有复用需求再抽）
        case emailAddress
        /// 大搜来自筛选器中展示推荐（需要展示在最底下）
        case searchFromFilterRecommend
        case total
    }
    var enableOwnedGroup: Bool?
    var hasGroup: Bool = false {
        didSet { tableView.reloadData() }
    }
    var supportSelectGroup: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasRobot: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasOnCall: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasExternal: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasOrganization: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasRelatedOrganizations: Bool = false {
        didSet { tableView.reloadData() }
    }
    var supportSelectOrganization: Bool = false {
        didSet { tableView.reloadData() }
    }
    var userGroupSceneType: UserGroupSceneType? {
        didSet { tableView.reloadData() }
    }
    var hasUserGroup: Bool {
        guard userGroupSceneType != nil else { return false }
        return true
    }
    var hasEmailContact: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasSharedMailAccount: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasEmailAddress: Bool = false {
        didSet { tableView.reloadData() }
    }
    var hasSearchFromFilterRecommend: Bool = false {
        didSet { tableView.reloadData() }
    }
    var targetPreview: Bool = false {
        didSet { tableView.reloadData() }
    }

    weak var selectionDataSource: SelectionDataSource?
    var source: ChatterPickerSource?

    private lazy var todoSectionsManager = { () -> TodoSectionsManager in
        let manager = TodoSectionsManager(
            selectionDataSource: selectionDataSource,
            source: source,
            resolver: userResolver
        )
        manager.setup(tableView: tableView)
        return manager
    }()

    private lazy var organizationSection = { () -> StructureOrganizationSection in
        let v = StructureOrganizationSection(resolver: userResolver)
        v.routeDepartment = { [weak self] (department, _, _) in
            guard let self = self else { return }
            self.router.didSelectDepartment(self, department: department)
        }
        v.setup(tableView: tableView, completion: nil)
        return v
    }()

    private lazy var fromFilterRecommendSection: SearchFromFilterRecommendSection = {
        let section = SearchFromFilterRecommendSection(recommendList: fromFilterRecommendList, selectionDataSource: selectionDataSource, resolver: userResolver)
        section.setup(tableView: tableView, completion: nil)
        return section
    }()

    // 关联组织section
    private lazy var collaborationTenantSection = { () -> CollaborationTenantSection in
        let v = CollaborationTenantSection(resolver: userResolver)
        v.hideLastCellSeparator = true
        v.routeRelated = { [weak self] (department, _) in
            guard let self = self else { return }
            self.router.didSelectCollaborationDepartment(self, tenantId: nil, department: department, departmentPath: [department], associationContactType: nil)
        }
        return v
    }()
    private let showTopBorder: Bool
    private let fromFilterRecommendList: [SearchResultType]
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService?

    init(router: StructureRootVCRouter, tableBackgroundColor: UIColor, showTopBorder: Bool, fromFilterRecommendList: [SearchResultType] = [], resolver: UserResolver) {
        self.router = router
        self.showTopBorder = showTopBorder
        self.fromFilterRecommendList = fromFilterRecommendList
        self.userResolver = resolver
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.LarkContact.Lark_Legacy_Contact
        self.tableView.backgroundColor = tableBackgroundColor
        self.fetchContactEntriesForLocalAndServer()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func customTableViewHeader(customView: UIView) {
        self.tableView.tableHeaderView = customView
    }

    func customTableViewFooter(customView: UIView) {
        self.tableView.tableFooterView = customView
    }

    private func fetchContactEntriesForLocalAndServer() {
        guard contactsEntryRefactorFG else { return }
        guard let structureService = self.structureService else { return }
        let localOb = structureService.fetchContactEntriesRequest(isFromServer: false,
                                                                  scene: .picker).materialize()
            .flatMap { event -> Observable<ContactEntries> in
                switch event {
                case .next(let i): return .just(i)
                default: return .never()
                }
            }
            .map { (res) -> (ContactEntries, FetchSource) in
                return (res, .local)
            }
        let serverOb = structureService.fetchContactEntriesRequest(isFromServer: true,
                                                                   scene: .picker).map { (res) -> (ContactEntries, FetchSource) in
            return (res, .server)
        }
        Observable.merge([localOb, serverOb])
            .observeOn(MainScheduler.instance)
            // 过滤掉数据相同的结果和处理远端先于本地回来的badcase(直接忽略本地的)
            .distinctUntilChanged({ (old, new) -> Bool in
                let isFilter = (old.0 == new.0) || new.1 == .local
                return isFilter
            })
            .subscribe(onNext: { [weak self] (res) in
                self?.contactEntries = res.0
                self?.tableView.reloadData()
            }, onError: { [weak self] (error) in
                Self.logger.error("Contact.Request: fetchContactEntriesRequest error, error = \(error)")
//                self?.contactEntries.setTrueToAllProperty() 请求错误的时候打开全部入口,安卓也没有这个无理的逻辑 -.-
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // config
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 68
        tableView.showsVerticalScrollIndicator = false
        tableView.register(DataItemViewCell.self, forCellReuseIdentifier: "DataItemViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        #endif

        // view hierarchy
        self.view.addSubview(tableView)
        if showTopBorder { self.view.lu.addTopBorder() }

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        #endif

        // Keyboard
        keyboardHandler = TableViewKeyboardHandler(
            options: [.allowCellFocused(focused: Display.pad)]
        )
        keyboardHandler?.delegate = self
    }

    fileprivate func dataItem(from: Section) -> DataOfRow? {
        switch from {
        case .group:
            if let ownedGroup = enableOwnedGroup, ownedGroup {
                return DataOfRow(title: BundleI18n.LarkContact.Lark_Groups_MyGroups,
                                 icon: Resources.group,
                                 type: .group)
            }
            return DataOfRow(title: self.supportSelectGroup ? BundleI18n.LarkContact.Lark_Groups_MyGroups : BundleI18n.LarkContact.Lark_Legacy_CreateGroupChatSelectGroup,
                             icon: Resources.group,
                             type: .group)
        case .robot:
            return DataOfRow(title: BundleI18n.LarkContact.Lark_Legacy_StructureRobot,
                             icon: Resources.bot,
                             type: .robot)
        case .onCall:
            return DataOfRow(title: BundleI18n.LarkContact.Lark_HelpDesk_ContactsHelpDesk,
                             icon: Resources.oncall,
                             type: .onCall)
        case .external:
            return DataOfRow(title: BundleI18n.LarkContact.Lark_Legacy_StructureExternal,
                             icon: Resources.external,
                             type: .external)
        case .emailContact:
            return DataOfRow(title: BundleI18n.LarkContact.Lark_Contacts_EmailContacts,
                             icon: Resources.nameCard,
                             type: .nameCard)
        case .sharedMailAccount:
            return DataOfRow(title: BundleI18n.LarkContact.Mail_MailingList_PublicMailbox,
                             icon: UDIcon.mailOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault),
                             type: .sharedMailAccount)
        case .emailAddress:
            return DataOfRow(title: BundleI18n.LarkContact.Mail_MailingList_EnterEmailAddress,
                             icon: UDIcon.addOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault),
                             type: .emailAddress)
        case .userGroup:
            return DataOfRow(title: BundleI18n.LarkContact.Lark_IM_Picker_UserGroups_Breadcrum,
                             icon: Resources.userGroup,
                             type: .userGroup)
        default: return nil
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.total.rawValue
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .group:
            if contactsEntryRefactorFG, !contactEntries.isShowChatGroups { return 0 }
            return hasGroup ? 1 : 0
        case .robot:
            if contactsEntryRefactorFG, !contactEntries.isShowRobot { return 0 }
            return hasRobot ? 1 : 0
        case .onCall:
            if contactsEntryRefactorFG, !contactEntries.isShowHelpDesks { return 0 }
            return hasOnCall ? 1 : 0
        case .external:
            if contactsEntryRefactorFG, !contactEntries.isShowExternalContacts { return 0 }
            return hasExternal ? 1 : 0
        case .emailContact:
            if isShowMailContactFG == false { return 0 }
            return hasEmailContact ? 1 : 0
        case .sharedMailAccount:
            return hasSharedMailAccount ? 1 : 0
        case .emailAddress:
            return hasEmailAddress ? 1 : 0
        case .organization:
            if hasOrganization {
                if contactsEntryRefactorFG, !contactEntries.isShowOrganization { return 0 }
                return organizationSection.tableView(tableView, numberOfRowsInSection: section)
            }
        case .todoRecommend:
            if let todoSection = todoSectionsManager.recommendSection {
                return todoSection.tableView(tableView, numberOfRowsInSection: section)
            }
        case .todoInChat:
            if let todoSection = todoSectionsManager.inChatSection {
                return todoSection.tableView(tableView, numberOfRowsInSection: section)
            }
        case .collaborationTenant:
            guard contactsEntryRefactorFG, contactEntries.isShowRelatedOrganizations else { return 0 }
            return hasRelatedOrganizations ? collaborationTenantSection.tableView(tableView, numberOfRowsInSection: section) : 0
        case .searchFromFilterRecommend:
            guard hasSearchFromFilterRecommend else { return 0 }
            return fromFilterRecommendSection.tableView(tableView, numberOfRowsInSection: section)
        case .userGroup:
            guard  contactEntries.isShowUserGroup else { return 0 }
            return hasUserGroup ? 1 : 0
        default: break
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == Section.todoRecommend.rawValue, let recommendSection = todoSectionsManager.recommendSection {
            return recommendSection.tableView(tableView, viewForHeaderInSection: section)
        }
        if section == Section.todoInChat.rawValue, let inChatSection = todoSectionsManager.inChatSection {
            return inChatSection.tableView(tableView, viewForHeaderInSection: section)
        }
        if section == Section.emailAddress.rawValue && hasEmailAddress {
            return MailGroupHelper.mailCommonSectionHeader(text: BundleI18n.LarkContact.Mail_MailingList_OtherWays)
        }
        if section == Section.searchFromFilterRecommend.rawValue && hasSearchFromFilterRecommend {
            return fromFilterRecommendSection.tableView(tableView, viewForHeaderInSection: section)
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Section.todoRecommend.rawValue, let recommendSection = todoSectionsManager.recommendSection {
            return recommendSection.tableView(tableView, heightForHeaderInSection: section)
        }
        if section == Section.todoInChat.rawValue, let inChatSection = todoSectionsManager.inChatSection {
            return inChatSection.tableView(tableView, heightForHeaderInSection: section)
        }
        if section == Section.emailAddress.rawValue && hasEmailAddress {
            return 40
        }
        if section == Section.searchFromFilterRecommend.rawValue && hasSearchFromFilterRecommend {
            return fromFilterRecommendSection.tableView(tableView, heightForHeaderInSection: section)
        }
        return .zero
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Section.organization.rawValue {
            return organizationSection.tableView(tableView, heightForRowAt: indexPath)
        }
        if indexPath.section == Section.todoRecommend.rawValue, let section = todoSectionsManager.recommendSection {
            return section.tableView(tableView, heightForRowAt: indexPath)
        }
        if indexPath.section == Section.todoInChat.rawValue, let section = todoSectionsManager.inChatSection {
            return section.tableView(tableView, heightForRowAt: indexPath)
        }
        if indexPath.section == Section.searchFromFilterRecommend.rawValue && hasSearchFromFilterRecommend {
            return fromFilterRecommendSection.tableView(tableView, heightForRowAt: indexPath)
        }
        return 51
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)
        func dequeDataItemViewCell() -> DataItemViewCell? {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "DataItemViewCell") as? DataItemViewCell,
               let section {
                let item = dataItem(from: section)
                cell.dataItem = item
                return cell
            }
            return nil
        }

        switch section {
        case .group, .robot, .onCall, .external, .emailContact, .sharedMailAccount, .emailAddress, .userGroup:
            if let cell = dequeDataItemViewCell() { return cell }
        case .organization:
            return organizationSection.tableView(tableView, cellForRowAt: indexPath)
        case .todoRecommend:
            if let section = todoSectionsManager.recommendSection {
                return section.tableView(tableView, cellForRowAt: indexPath)
            }
        case .todoInChat:
            if let section = todoSectionsManager.inChatSection {
                return section.tableView(tableView, cellForRowAt: indexPath)
            }
        case .collaborationTenant:
            return collaborationTenantSection.tableView(tableView, cellForRowAt: indexPath)
        case .searchFromFilterRecommend:
            return fromFilterRecommendSection.tableView(tableView, cellForRowAt: indexPath)
        default: break
        }
        assertionFailure()
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil,
            let section = Section(rawValue: indexPath.section)
            else { return }
        currentSection?(section)
        tableView.deselectRow(at: indexPath, animated: true)

        switch section {
        case .group:
            router.didSelectGroupWithChat(self)
            SearchTrackUtil.trackPickerSelectClick(scene: pickerScene, clickType: .manageGroup)
        case .robot:
            router.didSelectBotWithChatter(self)
        case .onCall:
            router.didSelectOnCallWithOncall(self)
        case .external:
            router.didSelectExternal(self)
            SearchTrackUtil.trackPickerSelectClick(scene: pickerScene, clickType: .external)
        case .emailContact:
            router.didSelectEmailContact(self)
            SearchTrackUtil.trackPickerSelectClick(scene: pickerScene, clickType: .emailMemeber)
        case .sharedMailAccount:
            router.didSelectSharedMailAccount(self)
        case .emailAddress:
            router.didSelectMailGroupEmailAddress(self)
        case .organization:
            organizationSection.tableView(tableView, didSelectRowAt: indexPath)
            SearchTrackUtil.trackPickerSelectClick(scene: pickerScene, clickType: .architectureMember)
        case .collaborationTenant:
            SearchTrackUtil.trackPickerSelectClick(scene: pickerScene, clickType: .associatedOrganizations)
            return collaborationTenantSection.tableView(tableView, didSelectRowAt: indexPath)
        case .todoRecommend:
            if let section = todoSectionsManager.recommendSection {
                return section.tableView(tableView, didSelectRowAt: indexPath)
            }
        case .todoInChat:
            if let section = todoSectionsManager.inChatSection {
                return section.tableView(tableView, didSelectRowAt: indexPath)
            }
        case .searchFromFilterRecommend:
            return fromFilterRecommendSection.tableView(tableView, didSelectRowAt: indexPath)
        case .userGroup:
            router.didSelectUserGroup(self)
            SearchTrackUtil.trackPickerSelectClick(scene: pickerScene, clickType: .userGroup)
        default: break
        }
    }
}

final class StructureOrganizationSection: OrganizationStructureSectionProtocol {

    enum OrganizationDataItem {
        case tenantInfo(URL?, String)
        case structureInfo(String)
        case departmentInfo(Department)
        case moreDepartmentsInfo(String)
    }

    var userAPI: UserAPI?
    var passportAPI: PassportAPI?
    let bag = DisposeBag()
    static let logger = Logger.log(StructureOrganizationSection.self, category: "Contact.StructureOrganizationSection")
    private var departments: [Department] = []
    private var dataSource: [OrganizationDataItem] = []
    private var totalMemberCount: Int32?
    private var isAdmin: Bool = false
    private var adminURL: String = ""
    private var isShowMemberCount: Bool = false
    private var enableMoreDepartments: Bool = true
    private static let maxDepartmentsDisplayNumber: Int = 3
    private var isFromContactPage: Bool = false
    private let passportUserService: PassportUserService?

    var routeDepartment: ((Department, _ tapOrganizationCell: Bool, _ subDepartmentsItems: [SubDepartmentItem]) -> Void)?
    private let userResolver: UserResolver

    init(resolver: UserResolver,
         isFromContactPage: Bool = false) {
        self.userResolver = resolver
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
        self.userAPI = try? resolver.resolve(assert: UserAPI.self)
        self.passportAPI = try? resolver.resolve(assert: PassportAPI.self)
        self.isFromContactPage = isFromContactPage
        self.refreshDataSource()
    }

    private func refreshDataSource(_ complete: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.dataSource.removeAll()

            if self.isFromContactPage, let passportUserService = self.passportUserService {
                let iconURL = URL(string: passportUserService.userTenant.iconURL)
                let tenantName = passportUserService.userTenant.localizedTenantName
                self.dataSource.append(.tenantInfo(iconURL, tenantName))
            }

            var title = BundleI18n.LarkContact.Lark_Legacy_StructureDepartments
            if let totalMemberCount = self.totalMemberCount, totalMemberCount > 0 {
                title = "\(title) (\(totalMemberCount))"
            }
            self.dataSource.append(.structureInfo(title))

            if self.enableMoreDepartments {
                if self.departments.count > Self.maxDepartmentsDisplayNumber {
                    let departmentInfos = self.departments[0..<Self.maxDepartmentsDisplayNumber].map { OrganizationDataItem.departmentInfo($0) }
                    self.dataSource.append(contentsOf: departmentInfos)
                    let moreTitle = "\(BundleI18n.LarkContact.Lark_Contacts_MoreDepartments) (\(self.departments.count - Self.maxDepartmentsDisplayNumber))"
                    self.dataSource.append(.moreDepartmentsInfo(moreTitle))
                } else {
                    let departmentInfos = self.departments.map { OrganizationDataItem.departmentInfo($0) }
                    self.dataSource.append(contentsOf: departmentInfos)
                }
            } else {
                let departmentInfos = self.departments.map { OrganizationDataItem.departmentInfo($0) }
                self.dataSource.append(contentsOf: departmentInfos)
            }

            if let complete = complete {
                complete()
            }
        }
    }

    func setup(tableView: UITableView, completion: ((Result<Void, Error>) -> Void)?) {
        tableView.register(DataItemViewCell.self, forCellReuseIdentifier: "DataItemViewCell")
        tableView.register(TopStructureTableViewCell.self, forCellReuseIdentifier: "TopStructureTableViewCell")
        tableView.register(TenantItemViewCell.self, forCellReuseIdentifier: "TenantItemViewCell")
        tableView.register(MoreDepartmentsViewCell.self, forCellReuseIdentifier: "MoreDepartmentsViewCell")

        self.enableMoreDepartments = self.isFromContactPage && userResolver.fg.staticFeatureGatingValue(with: "lark.client.contact.organization.moredepartments")
        guard let userAPI = self.userAPI, let passportAPI = self.passportAPI else { return }
        let adminDataSubjects = passportAPI.getMineSidebar(strategy: .tryLocal)
            .map { $0.first(where: { $0.sidebarType == .admin })?.sidebarLink }
            .catchError { _ in return .just(nil) }

        Observable.combineLatest(adminDataSubjects, userAPI.getSubordinateDepartments())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (adminURL: String?, departmentsInfo: ([RustPB.Basic_V1_Department], Int32?, Bool)) in
                guard let self = self else { return }

                if let adminURL = adminURL, !adminURL.isEmpty {
                    self.isAdmin = true
                    self.adminURL = "\(adminURL)&from=contact"
                    Self.logger.info("get admin url from MineSideBar success, adminUrl: \(self.adminURL)")
                } else {
                    self.isAdmin = false
                    self.adminURL = ""
                }

                let (departments, totalMemberCount, showMemberCount) = departmentsInfo
                self.departments = departments
                self.totalMemberCount = totalMemberCount
                self.isShowMemberCount = showMemberCount
                self.refreshDataSource {
                    tableView.reloadData()
                    completion?(.success(()))
                }
            }, onError: { (error) in
                completion?(.failure(error))
            }).disposed(by: bag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dataItem = self.dataSource[indexPath.row]
        let moreDepartmentsHeight = 44.0
        let defaultHeight = 54.0
        switch  dataItem {
        case .moreDepartmentsInfo:
            return moreDepartmentsHeight
        default:
            return defaultHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.dataSource.count else {
            assertionFailure()
            return UITableViewCell()
        }

        let dataItem = self.dataSource[indexPath.row]
        switch dataItem {
        case .tenantInfo(let iconURL, let tenantName):
            return self.createTenantInfoCell(tableView, indexPath: indexPath, iconURL: iconURL, tenantName: tenantName)
        case .structureInfo(let title):
            return self.createStructureTitleCell(tableView, indexPath: indexPath, title: title)
        case .departmentInfo(let department):
            return self.createDepartmentCell(tableView, indexPath: indexPath, department: department)
        case .moreDepartmentsInfo(let title):
            return self.createMoreDepartmentsCell(tableView, indexPath: indexPath, title: title)
        }
    }

    private func createTenantInfoCell(_ tableView: UITableView, indexPath: IndexPath, iconURL: URL?, tenantName: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TenantItemViewCell", for: indexPath) as? TenantItemViewCell {
            cell.iconURL = iconURL
            cell.tenantName = tenantName
            cell.isAdmin = self.isAdmin
            cell.adminURL = self.adminURL
            cell.navigator = self.userResolver.navigator
            cell.selectionStyle = .none
            return cell
        }
        return UITableViewCell()
    }

    private func createStructureTitleCell(_ tableView: UITableView, indexPath: IndexPath, title: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DataItemViewCell", for: indexPath) as? DataItemViewCell {
            cell.dataItem = DataOfRow(title: title, icon: Resources.structure, type: .structure)
            return cell
        }
        return UITableViewCell()
    }

    private func createDepartmentCell(_ tableView: UITableView, indexPath: IndexPath, department: Department) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TopStructureTableViewCell", for: indexPath) as? TopStructureTableViewCell {
            cell.set(departmentName: department.name, userCount: department.memberCount)
            let exceedMaxNum = self.departments.count > Self.maxDepartmentsDisplayNumber
            let isLastDepartmentShownOnContactPage = indexPath.row == Self.maxDepartmentsDisplayNumber + 1
            let shouldDispalyOnContactPage = self.enableMoreDepartments && exceedMaxNum && isLastDepartmentShownOnContactPage

            let isLastDepartmentShownOnSelectPage = indexPath.row == self.departments.count
            let shouldDisplayOnSelectPage = !self.enableMoreDepartments && isLastDepartmentShownOnSelectPage
            let shouldDisplay = shouldDispalyOnContactPage || shouldDisplayOnSelectPage
            cell.hideSeparator(isHidden: !shouldDisplay)

            return cell
        }
        return UITableViewCell()
    }

    private func createMoreDepartmentsCell(_ tableView: UITableView, indexPath: IndexPath, title: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MoreDepartmentsViewCell", for: indexPath) as? MoreDepartmentsViewCell {
            cell.set(title: title)
            cell.hideSeparator(isHidden: true)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ table: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let route = self.routeDepartment, let passportUserService = self.passportUserService else { return }

        let dataItem = self.dataSource[indexPath.row]
        switch dataItem {
        case .structureInfo:
            Tracer.contactOrganizationView()
            var department = Department()
            department = Department()
            department.id = "0" //id为0表示直接查看大组织架构
            department.name = passportUserService.userTenant.localizedTenantName
            route(department, true, [])
        case .departmentInfo(let department):
            route(department, false, [])
            Tracer.contactOrganizationHomeDepartmentsClick()
        case .moreDepartmentsInfo:
            Tracer.contactOrganizationMoreDepartmentsClick()
            var department = Department()
            department.name = BundleI18n.LarkContact.Lark_Contacts_MoreDepartments
            let subDepartmentsItems = self.departments.map { (department) -> SubDepartmentItem in
                (nil, department, self.isShowMemberCount)
            }
            route(department, true, subDepartmentsItems)
        default:
            break
        }
    }

    var numberOfRows: Int { self.dataSource.count }
}

final class NewOrganizationSection: OrganizationStructureSectionProtocol {

    enum OrganizationDataItem {
        case tenantInfo(URL?, String)
        case structureInfo(String)
        case rootOrganizationInfo(String)
        case departmentInfo(Department)
        case moreDepartmentsInfo(String, Bool)
        case internalCollaboration(Contact_V1_CollaborationTenant)
        case moreInternalCollaboration(String, Bool)
    }

    var userAPI: UserAPI?
    var passportAPI: PassportAPI?
    var structureService: StructureService?
    let bag = DisposeBag()
    static let logger = Logger.log(StructureOrganizationSection.self, category: "Contact.StructureOrganizationSection")
    private var departments: [Department] = []
    private var internalCollaborations: [Contact_V1_CollaborationTenant] = []
    private var dataSource: [OrganizationDataItem] = []
    private var totalMemberCount: Int32?
    private var isAdmin: Bool = false
    private var adminURL: String = ""
    private var isShowMemberCount: Bool = false
    private var isEnableInternalCollaborationFG: Bool = false
    var enableMoreDepartments: Bool = true
    private static let maxInternalCollaborationNumber: Int = 200
    private static let maxDepartmentsDisplayNumber: Int = 3
    private var isFromContactPage: Bool = false
    private let passportUserService: PassportUserService?
    private var loadMoreDepartmentStatus = BehaviorRelay<Bool>(value: false)
    private var loadMoreInternalCollaborationStatus = BehaviorRelay<Bool>(value: false)
    private(set) var organizationEntryVisible: OrganizationEntryVisible = .defaultValue

    var routeDepartment: ((Department, _ tapOrganizationCell: Bool, _ subDepartmentsItems: [SubDepartmentItem]) -> Void)?
    var routeInternal: ((Department, _ tenantID: String, _ tapOrganizationCell: Bool) -> Void)?
    private let userResolver: UserResolver

    init(resolver: UserResolver,
         isFromContactPage: Bool = false,
         isEnableInternalCollaborationFG: Bool = false) {
        self.userResolver = resolver
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
        self.userAPI = try? resolver.resolve(assert: UserAPI.self)
        self.passportAPI = try? resolver.resolve(assert: PassportAPI.self)
        self.structureService = try? resolver.resolve(assert: StructureService.self)
        self.isFromContactPage = isFromContactPage
        self.isEnableInternalCollaborationFG = isEnableInternalCollaborationFG
        self.refreshDataSource()
    }

    private func refreshDataSource(_ complete: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.dataSource.removeAll()

            if self.isFromContactPage, let passportUserService = self.passportUserService {
                let iconURL = URL(string: passportUserService.userTenant.iconURL)
                let tenantName = passportUserService.userTenant.localizedTenantName
                self.dataSource.append(.tenantInfo(iconURL, tenantName))
            }

            var title = BundleI18n.LarkContact.Lark_Legacy_StructureDepartments
            if let totalMemberCount = self.totalMemberCount, totalMemberCount > 0 {
                title = "\(title) (\(totalMemberCount))"
            }
            // 如果有内部关联组织的话，就显示组织架构的根部门（租户），以和内部关联组织的层级对齐
            if self.organizationEntryVisible.internalCollaborationVisible || self.organizationEntryVisible.subordinateDepartmentVisible || self.isAdmin {
                self.dataSource.append(.structureInfo(title))
            }

            // 如果有内部关联组织的话，就显示组织架构的根部门（租户），以和内部关联组织的层级对齐
            if !self.internalCollaborations.isEmpty, let passportUserService = self.passportUserService {
                let tenantName = passportUserService.userTenant.localizedTenantName
                self.dataSource.append(.rootOrganizationInfo(tenantName))
            }

            if self.organizationEntryVisible.subordinateDepartmentVisible {
                if self.enableMoreDepartments {
                    if self.departments.count > Self.maxDepartmentsDisplayNumber {
                        if !self.loadMoreDepartmentStatus.value {
                            let departmentInfos = self.departments[0..<Self.maxDepartmentsDisplayNumber].map { OrganizationDataItem.departmentInfo($0) }
                            self.dataSource.append(contentsOf: departmentInfos)
                            let moreTitle = BundleI18n.LarkContact.Lark_B2B_Button_ShowMore
                            self.dataSource.append(.moreDepartmentsInfo(moreTitle, false))
                        } else {
                            let departmentInfos = self.departments.map { OrganizationDataItem.departmentInfo($0) }
                            self.dataSource.append(contentsOf: departmentInfos)
                            let moreTitle = BundleI18n.LarkContact.Lark_B2B_Button_ShowLess
                            self.dataSource.append(.moreDepartmentsInfo(moreTitle, true))
                        }
                    } else {
                        let departmentInfos = self.departments.map { OrganizationDataItem.departmentInfo($0) }
                        self.dataSource.append(contentsOf: departmentInfos)
                    }
                } else {
                    let departmentInfos = self.departments.map { OrganizationDataItem.departmentInfo($0) }
                    self.dataSource.append(contentsOf: departmentInfos)
                }
            }

            if self.organizationEntryVisible.internalCollaborationVisible {
                if self.internalCollaborations.count > Self.maxDepartmentsDisplayNumber {
                    if !self.loadMoreInternalCollaborationStatus.value {
                        let internalCollaborationInfos = self.internalCollaborations[0..<Self.maxDepartmentsDisplayNumber].map { OrganizationDataItem.internalCollaboration($0) }
                        self.dataSource.append(contentsOf: internalCollaborationInfos)
                        let moreTitle = BundleI18n.LarkContact.Lark_B2B_Button_ShowMore
                        self.dataSource.append(.moreInternalCollaboration(moreTitle, false))
                    } else {
                        let internalCollaborationInfos = self.internalCollaborations.map { OrganizationDataItem.internalCollaboration($0) }
                        self.dataSource.append(contentsOf: internalCollaborationInfos)
                        let hideTitle = BundleI18n.LarkContact.Lark_B2B_Button_ShowLess
                        self.dataSource.append(.moreInternalCollaboration(hideTitle, true))
                    }
                } else {
                    let internalCollaborationInfos = self.internalCollaborations.map { OrganizationDataItem.internalCollaboration($0) }
                    self.dataSource.append(contentsOf: internalCollaborationInfos)
                }
            }

            if let complete = complete {
                complete()
            }
        }
    }

    func setup(tableView: UITableView, completion: ((Result<Void, Error>) -> Void)?) {
        tableView.register(DataItemViewCell.self, forCellReuseIdentifier: "DataItemViewCell")
        tableView.register(TopStructureTableViewCell.self, forCellReuseIdentifier: "TopStructureTableViewCell")
        tableView.register(TenantItemViewCell.self, forCellReuseIdentifier: "TenantItemViewCell")
        tableView.register(MoreOrganizationViewCell.self, forCellReuseIdentifier: "MoreOrganizationViewCell")
        // 根部的组织架构和内部关联组织复用同一个类
        tableView.register(OrganizationTableViewCell.self, forCellReuseIdentifier: "RootOrganizationTableViewCell")
        tableView.register(OrganizationTableViewCell.self, forCellReuseIdentifier: "InternalCollaborationTableViewCell")

        self.enableMoreDepartments = true
        guard let userAPI = self.userAPI, let passportAPI = self.passportAPI else { return }
        let adminDataSubjects = passportAPI.getMineSidebar(strategy: .tryLocal)
            .map { $0.first(where: { $0.sidebarType == .admin })?.sidebarLink }
            .catchError { _ in return .just(nil) }

        Observable.combineLatest(adminDataSubjects, userAPI.getSubordinateDepartments())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (adminURL: String?, departmentsInfo: ([RustPB.Basic_V1_Department], Int32?, Bool)) in
                guard let self = self else { return }

                if let adminURL = adminURL, !adminURL.isEmpty {
                    self.isAdmin = true
                    self.adminURL = "\(adminURL)&from=contact"
                    Self.logger.info("get admin url from MineSideBar success, adminUrl: \(self.adminURL)")
                } else {
                    self.isAdmin = false
                    self.adminURL = ""
                }

                let (departments, totalMemberCount, showMemberCount) = departmentsInfo
                self.departments = departments
                self.totalMemberCount = totalMemberCount
                self.isShowMemberCount = showMemberCount
                self.refreshDataSource {
                    tableView.reloadData()
                    completion?(.success(()))
                }
            }, onError: { (error) in
                completion?(.failure(error))
            }).disposed(by: bag)

        if isEnableInternalCollaborationFG {
            userAPI.fetchCollaborationTenant(offset: 0, count: Self.maxInternalCollaborationNumber, isInternal: true, query: nil)
                .observeOn(MainScheduler.instance)
                .subscribe {[weak self] internalCollaborationModel in
                    self?.internalCollaborations = internalCollaborationModel.tenants
                    self?.refreshDataSource {
                        tableView.reloadData()
                        completion?(.success(()))
                    }
                }.disposed(by: bag)
        }

        loadMoreDepartmentStatus.subscribe(onNext: {[weak self] _ in
            self?.refreshDataSource {
                tableView.reloadData()
                completion?(.success(()))
            }
        }).disposed(by: bag)

        loadMoreInternalCollaborationStatus.subscribe(onNext: {[weak self] _ in
            self?.refreshDataSource {
                tableView.reloadData()
                completion?(.success(()))
            }
        }).disposed(by: bag)

        structureService?.fetchOrganizationVisible().subscribe {[weak self] response in
            self?.organizationEntryVisible = response
            self?.refreshDataSource {
                tableView.reloadData()
                completion?(.success(()))
            }
        }.disposed(by: bag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dataItem = self.dataSource[indexPath.row]
        switch  dataItem {
        case .moreDepartmentsInfo:
            return 44
        default:
            return 54
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.dataSource.count else {
            assertionFailure()
            return UITableViewCell()
        }

        // 分隔线只出现在内外部组织之间
        var needSeparator = false
        if (indexPath.row + 1 < self.dataSource.count),
           case .internalCollaboration = self.dataSource[indexPath.row + 1] {
            needSeparator = true
        }

        let dataItem = self.dataSource[indexPath.row]
        switch dataItem {
        case .tenantInfo(let iconURL, let tenantName):
            return self.createTenantInfoCell(tableView, indexPath: indexPath, iconURL: iconURL, tenantName: tenantName)
        case .structureInfo(let title):
            return self.createStructureTitleCell(tableView, indexPath: indexPath, title: title)
        case .rootOrganizationInfo(let title):
            return self.createRootOrganizationCell(tableView, indexPath: indexPath, tenantName: title)
        case .departmentInfo(let department):
            return self.createDepartmentCell(tableView, indexPath: indexPath, department: department, needSeparator: needSeparator)
        case .moreDepartmentsInfo(let title, let isShowDetails):
            if isShowDetails {
                return self.createHideDepartmentsCell(tableView, indexPath: indexPath, title: title, isInternal: false, needSeparator: needSeparator)
            } else {
                return self.createMoreDepartmentsCell(tableView, indexPath: indexPath, title: title, isInternal: false, needSeparator: needSeparator)
            }
        case .internalCollaboration(let internalCollaboration):
            return self.createInternalCollaborationCell(tableView, indexPath: indexPath, internalCollaboration: internalCollaboration)
        case .moreInternalCollaboration(let title, let isShowDetails):
            if isShowDetails {
                return self.createHideDepartmentsCell(tableView, indexPath: indexPath, title: title, isInternal: true, needSeparator: needSeparator)
            } else {
                return self.createMoreDepartmentsCell(tableView, indexPath: indexPath, title: title, isInternal: true, needSeparator: needSeparator)
            }
        }
    }

    // 是否有根组织Cell（租户）
    func hasRootOrganization() -> Bool {
        if dataSource.contains(where: { item in
            if case .rootOrganizationInfo(_) = item { return true } else { return false }
        }) {
            return true
        } else {
            return false
        }
    }

    // 是否可以点击某个cell
    func enableSelect(indexPath: IndexPath) -> Bool {
        guard indexPath.row < self.dataSource.count else {
            assertionFailure()
            return true
        }
        let dataItem = self.dataSource[indexPath.row]
        switch dataItem {
        case .moreDepartmentsInfo(_, _):
            return false
        case .moreInternalCollaboration(_, _):
            return false
        case .structureInfo(_):
            // 如果有根组织，则代替'组织架构'的作用，所以组织架构的cell不可点击
            if hasRootOrganization() {
                return false
            }
            return true
        default:
            return true
        }
    }

    private func createTenantInfoCell(_ tableView: UITableView, indexPath: IndexPath, iconURL: URL?, tenantName: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TenantItemViewCell", for: indexPath) as? TenantItemViewCell {
            cell.iconURL = iconURL
            cell.tenantName = tenantName
            cell.isAdmin = self.isAdmin
            cell.adminURL = self.adminURL
            cell.navigator = self.userResolver.navigator
            cell.selectionStyle = .none
            return cell
        }
        return UITableViewCell()
    }

    private func createStructureTitleCell(_ tableView: UITableView, indexPath: IndexPath, title: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DataItemViewCell", for: indexPath) as? DataItemViewCell {
            cell.dataItem = DataOfRow(title: title, icon: Resources.structure, type: .structure)
            cell.setArrowIcon(hide: hasRootOrganization())
            return cell
        }
        return UITableViewCell()
    }

    private func createRootOrganizationCell(_ tableView: UITableView, indexPath: IndexPath, tenantName: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "RootOrganizationTableViewCell", for: indexPath) as? OrganizationTableViewCell {
            cell.set(departmentName: tenantName)
            cell.hideSeparator(isHidden: true)
            return cell
        }
        return UITableViewCell()
    }

    private func createInternalCollaborationCell(_ tableView: UITableView, indexPath: IndexPath, internalCollaboration: Contact_V1_CollaborationTenant) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "InternalCollaborationTableViewCell", for: indexPath) as? OrganizationTableViewCell {
            cell.set(departmentName: internalCollaboration.tenantName)
            cell.hideSeparator(isHidden: true)
            return cell
        }
        return UITableViewCell()
    }

    private func createDepartmentCell(_ tableView: UITableView, indexPath: IndexPath, department: Department, needSeparator: Bool) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TopStructureTableViewCell", for: indexPath) as? TopStructureTableViewCell {
            cell.set(departmentName: department.name, userCount: department.memberCount)
            let exceedMaxNum = self.departments.count > Self.maxDepartmentsDisplayNumber
            let isLastDepartmentShownOnContactPage = indexPath.row == Self.maxDepartmentsDisplayNumber + 1
            let shouldDispalyOnContactPage = self.enableMoreDepartments && exceedMaxNum && isLastDepartmentShownOnContactPage

            let isLastDepartmentShownOnSelectPage = indexPath.row == self.departments.count
            let shouldDisplayOnSelectPage = !self.enableMoreDepartments && isLastDepartmentShownOnSelectPage
            let shouldDisplay = shouldDispalyOnContactPage || shouldDisplayOnSelectPage
            cell.hideSeparator(isHidden: !needSeparator)

            return cell
        }
        return UITableViewCell()
    }

    private func createMoreDepartmentsCell(_ tableView: UITableView, indexPath: IndexPath, title: String, isInternal: Bool, needSeparator: Bool) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MoreOrganizationViewCell", for: indexPath) as? MoreOrganizationViewCell {
            cell.set(title: title, isInternal: isInternal, hideMore: true)
            cell.hideSeparator(isHidden: !needSeparator)
            return cell
        }
        return UITableViewCell()
    }

    private func createHideDepartmentsCell(_ tableView: UITableView, indexPath: IndexPath, title: String, isInternal: Bool, needSeparator: Bool) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MoreOrganizationViewCell", for: indexPath) as? MoreOrganizationViewCell {
            cell.set(title: title, isInternal: isInternal, hideMore: false)
            cell.hideSeparator(isHidden: !needSeparator)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ table: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let route = self.routeDepartment, let passportUserService = self.passportUserService else { return }

        let dataItem = self.dataSource[indexPath.row]
        switch dataItem {
        case .structureInfo:
            // 如果有根组织，则代替'组织架构'的作用
            if hasRootOrganization() {
                break
            }
            Tracer.contactOrganizationView()
            var department = Department()
            department = Department()
            department.id = "0" //id为0表示直接查看大组织架构
            department.name = passportUserService.userTenant.localizedTenantName
            route(department, true, [])
        case .rootOrganizationInfo(let title):
            var department = Department()
            department = Department()
            department.id = "0" //id为0表示直接查看大组织架构
            department.name = title
            route(department, true, [])
        case .departmentInfo(let department):
            route(department, false, [])
            Tracer.contactOrganizationHomeDepartmentsClick()
        case .moreDepartmentsInfo:
            Tracer.contactOrganizationMoreDepartmentsClick()
            let currentStatus = loadMoreDepartmentStatus.value
            loadMoreDepartmentStatus.accept(!currentStatus)
        case .internalCollaboration(let tenant):
            var department = Department()
            department.id = "0" //id为0表示直接查看大组织架构
            department.name = tenant.tenantName
            self.routeInternal?(department, tenant.tenantID, true)
        case .moreInternalCollaboration(_, _):
            let currentStatus = loadMoreInternalCollaborationStatus.value
            loadMoreInternalCollaborationStatus.accept(!currentStatus)
        default:
            break
        }
    }

    var numberOfRows: Int { self.dataSource.count }
}

final class SearchFromFilterRecommendSection: SectionDataSource {
    final class SectionHeader: UITableViewHeaderFooterView {
        let titleLabel: UILabel = UILabel()
        private let container = UIView()

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            backgroundColor = UIColor.ud.bgBase

            titleLabel.font = .systemFont(ofSize: 14)
            titleLabel.textColor = UIColor.ud.textCaption
            titleLabel.text = BundleI18n.LarkSearch.Lark_ASL_SearchSuggestions_PossibleRelatedContacts
            addSubview(container)
            container.backgroundColor = .ud.bgBody
            container.addSubview(titleLabel)
            container.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(26)
            }
            titleLabel.snp.makeConstraints {
                $0.left.equalToSuperview().offset(16)
                $0.right.equalToSuperview().offset(-16)
                $0.bottom.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }
    var passportUserService: PassportUserService?
    private let dataSource: [SearchResultType]
    weak var selectionDataSource: SelectionDataSource?
    private let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    private(set) var selectedDataItem: [OptionIdentifier: SearchResultType] = [:]
    private var isMultiple: Bool = false
    var defaultOption: [Option] = [] {
        didSet {
            for item in dataSource where defaultOption.contains(where: { item.optionIdentifier == $0.optionIdentifier }) {
                select(option: item)
            }
        }
    }
    init(recommendList: [SearchResultType], selectionDataSource: SelectionDataSource?, resolver: UserResolver) {
        self.dataSource = recommendList
        self.selectionDataSource = selectionDataSource
        self.userResolver = resolver
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
    }

    func setup(tableView: UITableView, completion: ((Result<Void, Error>) -> Void)?) {
        tableView.register(LarkSearchCore.ContactSearchTableViewCell.self, forCellReuseIdentifier: "ContactSearchTableViewCell")
        tableView.register(SectionHeader.self, forHeaderFooterViewReuseIdentifier: "SearchFromFilterRecommendSectionHeader")
        selectionDataSource?.selectedChangeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                tableView.reloadData()
            }).disposed(by: disposeBag)
        selectionDataSource?.isMultipleChangeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isMultiple in
                self?.isMultiple = isMultiple
                tableView.reloadData()
            })
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactSearchTableViewCell", for: indexPath) as? LarkSearchCore.ContactSearchTableViewCell,
              let selectionDataSource = selectionDataSource else {
            return UITableViewCell()
        }

        guard indexPath.row < self.dataSource.count,
                let passportUserService = self.passportUserService else {
            assertionFailure()
            return UITableViewCell()
        }

        let dataItem = self.dataSource[indexPath.row]
        let state = selectionDataSource.state(for: dataItem.optionIdentifier, from: tableView)
        cell.shouldHideAccessoryViews = true
        cell.shouldShowSecondaryInfo = true
        cell.shouldShowDividor = true
        cell.setContent(resolver: self.userResolver,
                        searchResult: dataItem,
                        currentTenantId: passportUserService.userTenant.tenantID,
                        hideCheckBox: !selectionDataSource.isMultiple,
                        enabled: true,
                        isSelected: state.selected,
                        checkInDoNotDisturb: { _ in false },
                        needShowMail: false,
                        currentUserType: passportUserService.user.type)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? LarkSearchCore.ContactSearchTableViewCell else { return }
        guard indexPath.row < self.dataSource.count else {
            assertionFailure()
            return
        }

        let dataItem = self.dataSource[indexPath.row]
        toggle(option: dataItem, forCell: cell, from: tableView)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SearchFromFilterRecommendSectionHeader") as? SectionHeader else {
            return UIView()
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return dataSource.isEmpty ? 0 : 26 + 8
    }

    private func isSelected(for option: SearchResultType) -> Bool {
        return selectedDataItem.contains(where: { $0.key == option.optionIdentifier })
    }

    private func toggle(option: SearchResultType, forCell cell: LarkSearchCore.ContactSearchTableViewCell, from: Any?) {
        let isSelected = self.isSelected(for: option)
        if isMultiple {
            if isSelected {
                cell.setCheckBox(selected: false)
                deselect(option: option)
            } else {
                cell.setCheckBox(selected: true)
                select(option: option)
            }
        } else {
            select(option: option)
        }
        selectionDataSource?.toggle(option: option, from: from)
    }

    private func select(option: SearchResultType) {
        selectedDataItem[option.optionIdentifier] = option
    }

    private func deselect(option: SearchResultType) {
        selectedDataItem.removeValue(forKey: option.optionIdentifier)
    }
}

final class CollaborationTenantSection: SectionDataSource {

    enum CollaborationDataItem {
        case collaborationInfo(String)
    }

    let bag = DisposeBag()
    let userResolver: UserResolver
    private var dataSource: [CollaborationDataItem] = []
    private var isFromContactPage: Bool
    var hideLastCellSeparator: Bool = false
    var routeRelated: ((Department, _ tapOrganizationCell: Bool) -> Void)?

    // 是否开启内部关联组织功能的FG
    var internalCollaborationFG: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "lark.admin.orm.b2b.high_trust_parties")
    }

    init(resolver: UserResolver, isFromContactPage: Bool = false) {
        self.userResolver = resolver
        self.isFromContactPage = isFromContactPage
        self.refreshDataSource()
        // Picker 埋点
        SearchTrackUtil.trackPickerSelectAssociatedOrganizationsView()
    }

    private func refreshDataSource(_ complete: (() -> Void)? = nil) {
        self.dataSource.removeAll()
        // 通讯录中当命中内部关联组织的FG后，将关联组织的Tab换成‘外部组织’，隔离Picker
        let isSwitchToExternalTitle = internalCollaborationFG && isFromContactPage
        let title = isSwitchToExternalTitle ? BundleI18n.LarkContact.Lark_B2B_Menu_ExternalOrg : BundleI18n.LarkContact.Lark_B2B_TrustedParties
        self.dataSource.append(.collaborationInfo(title))

        if let complete = complete {
            complete()
        }
    }

    func setup(tableView: UITableView, completion: ((Result<Void, Error>) -> Void)?) {
        tableView.register(DataItemViewCell.self, forCellReuseIdentifier: "DataItemViewCell")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 51
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.dataSource.count else {
            assertionFailure()
            return UITableViewCell()
        }

        let dataItem = self.dataSource[indexPath.row]
        switch dataItem {
        case .collaborationInfo(let title):
            return self.createStructureTitleCell(tableView, indexPath: indexPath, title: title)
        }
    }

    private func createStructureTitleCell(_ tableView: UITableView, indexPath: IndexPath, title: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DataItemViewCell", for: indexPath) as? DataItemViewCell {
            cell.dataItem = DataOfRow(title: title, icon: Resources.collaboration_tenant, type: .collaborationTenant)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ table: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let route = self.routeRelated else { return }
        Tracker.post(TeaEvent(Homeric.CONTACT_TRUST_PARTY_CLICK, params: [:]))

        let dataItem = self.dataSource[indexPath.row]
        switch dataItem {
        case .collaborationInfo(let title):
            var department = Department()
            department.id = "0" //id为0表示直接查看大组织架构
            department.name = title
            route(department, true)
        }
    }
    var numberOfRows: Int { self.dataSource.count }

    func dataIsEmpty() -> Bool {
        return self.dataSource.isEmpty
    }
}

/// 会把相对应的Section的调用，代理到实现对象。
/// 这里出于方便直接给予了UITableView，不应该影响到其他section
protocol SectionDataSource {
    /// will called before call other method
    func setup(tableView: UITableView, completion: ((Result<Void, Error>) -> Void)?)

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
}

extension SectionDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { return nil }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return .zero }
}

protocol OrganizationStructureSectionProtocol: SectionDataSource {
    var numberOfRows: Int { get }
    func enableSelect(indexPath: IndexPath) -> Bool
}

extension OrganizationStructureSectionProtocol {
    func enableSelect(indexPath: IndexPath) -> Bool {
        return true
    }
}
