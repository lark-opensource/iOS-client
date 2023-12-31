//
//  DepartmentVC.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/5.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import LarkSetting
import UniverseDesignToast
import LarkContainer
import LarkSearchCore
import LarkMessengerInterface
import EENavigator
import AnimatedTabBar
import LarkKeyCommandKit
import LarkUIKit
import LarkAlertController
import LarkTab
import RustPB
import LarkTag
import LKCommonsLogging
import UniverseDesignEmpty
import UniverseDesignLoading
import Homeric
import LarkSDKInterface

/// 显示部门架构或者组织成员等，仅包含TableView核心界面部分。属于可复用UI组件
final class DepartmentVC: UIViewController, UITableViewDataSource, UITableViewDelegate, DepartmentChatInfoDelegate, HasSelectChannel, TableViewKeyboardHandlerDelegate, UserResolverWrapper {
    static let logger = Logger.log(DepartmentVC.self, category: "contact.DepartmentVC")
    var selectChannel: SelectChannel
    private var hasDepartmentData: Bool
    private let departmentsAdministratorStatus: DepartmentsAdministratorStatus
    var level: Int = 0 // contact_organization_click埋点所需，从1开始，0为外部赋值错误
    let tableView = UITableView(frame: .zero, style: .plain)
    var keyboardHandler: TableViewKeyboardHandler?
    let bag = DisposeBag()

    let viewModel: DepartmentViewModelProtocol
    private var isSelfSuperAdmin: Bool = false
    weak var selectionSource: SelectionDataSource?
    struct Config {
        let showNameStyle: ShowNameStyle
        let routeSubDepartment: (DepartmentVC, String?, Department, DepartmentsAdministratorStatus) -> Void
        let departmenSupportSelect: Bool
        let selectedHandler: ((Int) -> Void)?
    }
    var config: Config

    private let emptyView = UDEmptyView(
        config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_ContactEmpty),
        type: .noContact)
    )

    private var loadingView: UIView?
    public var targetPreview: Bool = false
    weak var fromVC: UIViewController?
    var userResolver: LarkContainer.UserResolver

    init(viewModel: DepartmentViewModelProtocol, config: Config, selectionSource: SelectionDataSource, selectChannel: SelectChannel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.hasDepartmentData = !viewModel.subDepartmentsItems().isEmpty
        self.departmentsAdministratorStatus = viewModel.departmentsAdministratorStatus()
        self.config = config
        self.selectionSource = selectionSource
        self.selectChannel = selectChannel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)

        self.title = self.viewModel.currentDepartment().name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(emptyView)
        emptyView.useCenterConstraints = true
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 68
        tableView.register(ContactOrganizationalTableViewCell.self, forCellReuseIdentifier: "ContactOrganizationalTableViewCell")
        tableView.register(DepartmentTableViewCell.self, forCellReuseIdentifier: "DepartmentTableViewCell")
        tableView.register(DepartmentChatInfoCell.self, forCellReuseIdentifier: "DepartmentChatInfoCell")
        tableView.register(SelectableDepartmentTableViewCell.self, forCellReuseIdentifier: "SelectableDepartmentTableViewCell")

        tableView.delegate = self
        tableView.dataSource = self

        self.view.addSubview(tableView)

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = self.view.bounds

        setupLoadingView()

        if self.hasDepartmentData {
            var sectionItems: [SectionItem]
            sectionItems = self.viewModel.subDepartmentsItems().map { (subDepartmentItem: SubDepartmentItem) -> SectionItem in
                .SubDepartmentSectionItem(tenantId: subDepartmentItem.tenantId, department: subDepartmentItem.department, isShowMemberCount: subDepartmentItem.isShowMemberCount)
            }
            self.departmentSections.append(.SubDepartmentSection(departments: sectionItems))

            self.viewModel.isSelfSuperAdministrator()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { isSelfSuperAdmin in
                self.isSelfSuperAdmin = isSelfSuperAdmin
                Self.logger.info("succeed to get isSelfSuperAdmin info: \(isSelfSuperAdmin)")
                self.tableView.reloadData()
            }).disposed(by: bag)
            self.tableView.reloadData()
        } else {
        /// Load Data
            viewModel.loadData()
            Observable.combineLatest(self.viewModel.currentDepartmentObservable(), self.viewModel.isSelfSuperAdministrator())
                .observeOn(MainScheduler.instance)
                .skip(1) // 跳过订阅初始化的第一次，避免结束 loaading 并出现空状态
                .subscribe(onNext: { [weak self] (sections, isSelfSuperAdmin) in
                    self?.isSelfSuperAdmin = isSelfSuperAdmin
                    self?.departmentSections = sections
                    Self.logger.info("succeed to get isSelfSuperAdmin info: \(isSelfSuperAdmin)")
                    self?.tableView.reloadData()
                }).disposed(by: bag)
        }
        viewModel.currentHasMoreDriver().drive(onNext: { [weak self] (hasMore) in
            self?.stopLoading(more: hasMore)
        }).disposed(by: bag)

        selectionSource?.isMultipleChangeObservable.distinctUntilChanged().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: bag)
        selectionSource?.selectedChangeObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: bag)

        // tableview keyboard
        keyboardHandler = TableViewKeyboardHandler(options: [.allowCellFocused(focused: Display.pad)])
        keyboardHandler?.delegate = self

        // Picker 埋点
        switch selectChannel {
        case .organization:
            SearchTrackUtil.trackPickerSelectArchitectureView()
        case .collaboration:
            SearchTrackUtil.trackPickerSelectAssociatedOrganizationsView()
        default: break
        }
    }

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }

    private func setupLoadingView() {
        let loadingBackgroundView = UIView()
        loadingBackgroundView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(loadingBackgroundView)
        loadingBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody
        loadingBackgroundView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(134)
            make.centerY.equalToSuperview()

        }

        let loadingView = UDLoading.loadingImageView(lottieResource: nil)
        containerView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        let label = UILabel()
        label.text = BundleI18n.LarkContact.Lark_Legacy_BaseUiLoading
        label.backgroundColor = UIColor.ud.bgBody
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        containerView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(loadingView.snp.bottom).offset(12)
        }

        self.loadingView = loadingBackgroundView
    }

    // MARK: Load Data
    /// 会话内的成员
    private var departmentSections: [DepartmentSectionModel] = [] {
        didSet {
            self.loadingView?.isHidden = true
            if checkIsEmpty(departmentSections: departmentSections) {
                self.tableView.isHidden = true
                self.emptyView.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.emptyView.isHidden = true
            }
        }
    }

    private func checkIsEmpty(departmentSections: [DepartmentSectionModel]) -> Bool {
        guard !departmentSections.isEmpty else {
            return true
        }
        var isEmpty: Bool = true
        for item in departmentSections {
            switch item {
            case let .ChatInfoSection(chatInfos: chatInfo):
                if !chatInfo.isEmpty {
                    return false
                }
            case let .ChatterSection(chatters: chatter):
                if !chatter.isEmpty {
                    return false
                }
            case let .LeaderSection(leaders: leader):
                if !leader.isEmpty {
                    return false
                }
            case let .SubDepartmentSection(departments: department):
                if !department.isEmpty {
                    return false
                }
            case let .TenantSection(tenants: tenant):
                if !tenant.isEmpty {
                    return false
                }
            }
        }
        return true
    }

    // MARK: TableViewKeyboardHandlerDelegate

    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

    // MARK: UITableView
    func stopLoading(more: Bool) {
        tableView.endBottomLoadMore()
        if more {
            tableView.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadMoreData()
            }
        } else {
            tableView.removeBottomLoadMore()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return departmentSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        departmentSections[section].items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let departmentSection = self.departmentSections[indexPath.section]
        switch departmentSection {
        /// 部门群行高度为102
        case .ChatInfoSection:
            return 102
        default:
            return 68
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = departmentSections[indexPath.section]
        let item = section.items[indexPath.row]
        let nameStyle = NameStyle(showNameStyle: config.showNameStyle,
                                  nameFormatRule: self.viewModel.getNameFormatRule())

        switch section {
        case .ChatInfoSection:
            let cellID = String(describing: DepartmentChatInfoCell.self)
            if let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? DepartmentChatInfoCell,
                case let .ChatInfoSectionItem(chatInfo: chatInfo) = item {
                cell.delegate = self
                cell.setChatInfo(chatInfo: chatInfo)
                cell.backgroundColor = UIColor.ud.bgBody
                return cell
            }
        case .LeaderSection:
            let cellID = String(describing: ContactOrganizationalTableViewCell.self)
            if
                let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? ContactOrganizationalTableViewCell,
                case let .LeaderSectionItem(leader: leader, type: type) = item {
                var props = cellProps(with: leader,
                                      checkoutStatus: contactCheckBoxStaus(with: leader),
                                      isLeader: true,
                                      leaderType: type,
                                      isExternal: self.viewModel.isExternal(leader.id),
                                      isAdministrator: self.viewModel.isAdministrator(leader.id),
                                      isSuperAdministrator: self.viewModel.isSuperAdministrator(leader.id),
                                      disableTags: self.viewModel.currentDisableTags(),
                                      nameStyle: nameStyle,
                                      profileFieldsDic: self.viewModel.getProfileFieldsTitleDic())
                props.targetPreview = targetPreview && TargetPreviewUtils.canTargetPreview(chatter: leader)
                cell.backgroundColor = UIColor.ud.bgBody
                cell.setOrgProps(props)
                cell.section = indexPath.section
                cell.row = indexPath.row
                cell.delegate = self
                return cell
            }
        case .ChatterSection:
            let cellID = String(describing: ContactOrganizationalTableViewCell.self)
            if let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? ContactOrganizationalTableViewCell,
                case let .ChatterSectionItem(chatter: chatter) = item {
                var props = cellProps(with: chatter,
                                      checkoutStatus: contactCheckBoxStaus(with: chatter),
                                      isLeader: false,
                                      isExternal: self.viewModel.isExternal(chatter.id),
                                      isAdministrator: self.viewModel.isAdministrator(chatter.id),
                                      isSuperAdministrator: self.viewModel.isSuperAdministrator(chatter.id),
                                      disableTags: self.viewModel.currentDisableTags(),
                                      nameStyle: nameStyle,
                                      profileFieldsDic: self.viewModel.getProfileFieldsTitleDic())
                props.targetPreview = targetPreview && TargetPreviewUtils.canTargetPreview(chatter: chatter)
                cell.backgroundColor = UIColor.ud.bgBody
                cell.setOrgProps(props)
                cell.section = indexPath.section
                cell.row = indexPath.row
                cell.delegate = self
                return cell
            }
        case .SubDepartmentSection:
            if self.config.departmenSupportSelect {
                let cellID = String(describing: SelectableDepartmentTableViewCell.self)
                if
                    let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? SelectableDepartmentTableViewCell,
                    case let .SubDepartmentSectionItem(tenantId: tenantId, department: department, isShowMemberCount: isShowMemberCount) = item {

                    cell.backgroundColor = UIColor.ud.bgBody
                    let buttonStatus: SubordinateButtonStatus
                    if let state = self.selectionSource?.state(for: department, from: self), state.selected {
                        buttonStatus = .disable
                    } else {
                        buttonStatus = .enable
                    }

                    let props = SelectableDepartmentCellProps(
                        selectChannel: selectChannel,
                        departmentName: department.name,
                        info: isShowMemberCount ? "\(getMemberCount(department: department))" : "",
                        checkStatus: contactCheckBoxStaus(with: department),
                        tapHandler: { [weak self] in
                            guard let self = self, buttonStatus == .enable else { return }
                            self.config.routeSubDepartment(self, tenantId, department, self.departmentsAdministratorStatus)
                        },
                        buttonStatus: buttonStatus
                    )
                    cell.setProps(props)
                    return cell
                }
            } else {
                let cellID = String(describing: DepartmentTableViewCell.self)
                if
                    let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? DepartmentTableViewCell,
                    case let .SubDepartmentSectionItem(tenantId: _, department: department, isShowMemberCount: isShowMemberCount) = item {
                    cell.contentView.backgroundColor = UIColor.ud.bgBody
                    cell.set(departmentName: department.name, userCount: getMemberCount(department: department), isShowMemberCount: isShowMemberCount)
                    return cell
                }
            }
        case .TenantSection:
            let cellID = String(describing: DepartmentTableViewCell.self)
            if
                let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? DepartmentTableViewCell,
                case let .TenantSectionItem(tenantId: _, tenantName: tenantName, memberCount: memberCount, isShowMemberCount: isShowMemberCount) = item {
                cell.backgroundColor = UIColor.ud.bgBody
                cell.set(departmentName: tenantName, userCount: memberCount, isShowMemberCount: isShowMemberCount)
                return cell
            }
        }
        assertionFailure()
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)

        // Picker 埋点
        var pickerEvent: String?
        var pickerTarget: String?
        switch selectChannel {
        case .organization:
            pickerEvent = Homeric.PUBLIC_PICKER_SELECT_ARCHITECTURE_MEMBER_CLICK
            pickerTarget = Homeric.PUBLIC_PICKER_SELECT_ARCHITECTURE_MEMBER_VIEW
        case .collaboration:
            pickerEvent = Homeric.PUBLIC_PICKER_SELECT_ASSOCIATED_ORGANIZATIONS_CLICK
            pickerTarget = Homeric.PUBLIC_PICKER_SELECT_ASSOCIATED_ORGANIZATIONS_VIEW
        default: break
        }

        func didSelectChatter(chatter: Chatter) {
            Tracer.contactOrganizationClick(departmentLevel: self.level, departmentID: "", userID: chatter.id)
            // 组织架构和关联组织下，点击用户跳转 profile 而不是选择用户，不做权限校验
            if (selectChannel != .organization && selectChannel != .collaboration) && !self.viewModel.canInviteChatter(chatter.id) {
                // 无权选中某人，toast提示，不进行后续操作
                if let window = self.view.window {
                    UDToast.showFailure(with: self.viewModel.denyInviteReason(chatter.id), on: window)
                }
                return
            }
            guard let selectionDataSource = selectionSource else { return }
            if let mail = viewModel.mailGroupCheckCanSeletedChatter(chatter.id), mail.disable { return }
            if viewModel.isChattersIdsInChat(chatter.id) { return }
            if selectionDataSource.toggle(option: chatter,
                                          from: self,
                                          at: tableView.absolutePosition(at: indexPath),
                                          event: pickerEvent,
                                          target: pickerTarget),
               selectionDataSource.state(for: chatter, from: self).selected {
                self.config.selectedHandler?(calculateIndex(indexPath))
            }
        }

        func didSelectDepartment(department: Department) {
            if self.viewModel.fobiddenDepartmentSelect() {
                UDToast.showTips(with: self.viewModel.getDepartmentSelectDisabledText(), on: self.view)
                return
            }

            if self.viewModel.shouldCheckHasSelectPermission(),
                !self.isSelfSuperAdmin,
                !self.viewModel.isLeaderPermissionDepartment(department.id) {
                UDToast.showTips(with: self.viewModel.getDepartmentSelectDisabledText(), on: self.view)
                return
            }

            if let mail = self.viewModel.mailGroupCheckCanSeletedDepartment(departmentId: department.id), mail.disable {
                return
            }

            guard let selectionDataSource = selectionSource else { return }
            /// 所选部门包含子部门
            if department.hasSubDepartments_p,
               !selectionDataSource.state(for: department, from: self).selected {
                let alertController = LarkAlertController()
                alertController.setContent(text: BundleI18n.LarkContact.Lark_Group_SelectedMultipleDeptDialogTitle)
                alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Cancel)
                alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Sure, dismissCompletion: {
                    if selectionDataSource.toggle(option: department,
                                                  from: self,
                                                  at: tableView.absolutePosition(at: indexPath),
                                                  event: pickerEvent,
                                                  target: pickerTarget),
                       selectionDataSource.state(for: department, from: self).selected {
                        self.config.selectedHandler?(self.calculateIndex(indexPath))
                    }
                })
                navigator.present(alertController, from: self)
                return
            }
            if selectionDataSource.toggle(option: department,
                                          from: self,
                                          at: tableView.absolutePosition(at: indexPath),
                                          event: pickerEvent,
                                          target: pickerTarget),
               selectionDataSource.state(for: department, from: self).selected {
                self.config.selectedHandler?(calculateIndex(indexPath))
            }
        }

        let section = departmentSections[indexPath.section]
        let item = section.items[indexPath.row]

        switch item {
        case .ChatInfoSectionItem:
            break
        case let .LeaderSectionItem(leader: leader, type: _):
            didSelectChatter(chatter: leader)
        case let .SubDepartmentSectionItem(tenantId, department, _):
            Tracer.contactOrganizationClick(departmentLevel: self.level, departmentID: department.id, userID: "")
            ContactTracker.Architecture.Click.Architecture(layerCount: departmentSections.count)
            if !self.config.departmenSupportSelect {
                config.routeSubDepartment(self, tenantId, department, self.departmentsAdministratorStatus)
                return
            }
            didSelectDepartment(department: department)
        case let .TenantSectionItem(tenantId, tenantName, _, _):
            var department = Department()
            department.id = "0" //id为0表示直接查看大组织架构
            department.name = tenantName
            config.routeSubDepartment(self, tenantId, department, self.departmentsAdministratorStatus)
        case let .ChatterSectionItem(chatter):
            didSelectChatter(chatter: chatter)
        }
    }

    private struct NameStyle {
        let showNameStyle: ShowNameStyle
        let nameFormatRule: UserNameFormatRule?
    }

    private func cellProps(with chatter: Chatter,
                           checkoutStatus: ContactCheckBoxStaus,
                           isLeader: Bool,
                           leaderType: LeaderType = .subLeader,
                           isExternal: Bool,
                           isAdministrator: Bool,
                           isSuperAdministrator: Bool,
                           disableTags: [TagType],
                           nameStyle: NameStyle,
                           profileFieldsDic: [String: [UserProfileField]]) -> ContactTableViewCellProps {
        func formatName(namesInOrder: [String]) -> String {
            let nonEmtyNames = namesInOrder.filter { !$0.isEmpty }
            let count = nonEmtyNames.count
            if count >= 2 {
                return String(format: BundleI18n.LarkContact.Lark_Legacy_ContactName,
                              nonEmtyNames[0],
                              nonEmtyNames[1])
            } else {
                return nonEmtyNames.first ?? ""
            }
        }

        var contactName = chatter.localizedName

        if let nameFormatRule = nameStyle.nameFormatRule {
            if nameFormatRule == .anotherNameFirst {
                if chatter.anotherName.isEmpty {
                    // 姓名 > 备注名
                    contactName = formatName(namesInOrder: [chatter.localizedName, chatter.alias])
                } else {
                    // 别名 > 备注名 > 姓名
                    contactName = formatName(namesInOrder: [chatter.anotherName, chatter.alias, chatter.localizedName])
                }
            } else {
                // 姓名 > 备注名 > 别名
                contactName = formatName(namesInOrder: [chatter.localizedName, chatter.alias, chatter.anotherName])
            }
        } else {
            if !chatter.alias.isEmpty {
                switch nameStyle.showNameStyle {
                case .nameAndAlias:
                    contactName = String(format: BundleI18n.LarkContact.Lark_Legacy_ContactName,
                                         chatter.localizedName,
                                         chatter.alias)
                case .justAlias:
                    contactName = chatter.alias
                }
            }
        }
        var props = ContactTableViewCellProps(
            name: contactName,
            pinyinOfName: chatter.namePinyin,
            avatarKey: chatter.avatarKey,
            entityId: chatter.id,
            hasNext: false,
            hasRegister: chatter.isRegistered,
            isRobot: false,
            isLeader: isLeader,
            leaderType: leaderType,
            isExternal: isExternal,
            isAdministrator: isAdministrator,
            isSuperAdministrator: isSuperAdministrator,
            disableTags: disableTags,
            checkStatus: checkoutStatus,
            status: chatter.description_p,
            timeString: nil,
            isSpecialFocus: chatter.isSpecialFocus,
            profileFieldsDic: profileFieldsDic,
            tagData: chatter.tagData)
        props.medalKey = chatter.medalKey
        return props
    }

    private func contactCheckBoxStaus(with chatter: Chatter) -> ContactCheckBoxStaus {
        let multiStatusBlock: (Chatter) -> ContactCheckBoxStaus = { chatter in
            if let mail = self.viewModel.mailGroupCheckCanSeletedChatter(chatter.id), mail.selected {
                return .defaultSelected
            }
            if !self.viewModel.canInviteChatter(chatter.id) {
                return .disableToSelect
            }
            if self.viewModel.isChattersIdsInChat(chatter.id) {
                return .defaultSelected
            }
            if let state = self.selectionSource?.state(for: chatter, from: self) {
                return state.asContactCheckBoxStaus
            }
            return .unselected
        }
        return selectionSource?.isMultiple == true ? multiStatusBlock(chatter) : .invalid
    }

    private func contactCheckBoxStaus(with department: Department) -> ContactCheckBoxStaus {
        let multiStatusBlock: (Department) -> ContactCheckBoxStaus = { department in
            if let mail = self.viewModel.mailGroupCheckCanSeletedDepartment(departmentId: department.id), mail.selected {
                return .defaultSelected
            }
            if self.viewModel.fobiddenDepartmentSelect() {
                return .disableToSelect
            }
            if self.viewModel.shouldCheckHasSelectPermission(),
               !self.isSelfSuperAdmin,
               !self.viewModel.isLeaderPermissionDepartment(department.id) {
                return .disableToSelect
            }
            if let state = self.selectionSource?.state(for: department, from: self) {
                return state.asContactCheckBoxStaus
            }
            return .unselected
        }
        return selectionSource?.isMultiple == true ? multiStatusBlock(department) : .invalid
    }

    // MARK: DepartmentChatInfoCell Delegate
    func createOrEnterDidSelect(_ sender: UIButton, chatInfo: RustPB.Contact_V1_ChatInfo) {
        if chatInfo.hasChat {
            self.enterDepartmentGroup(chatInfo: chatInfo)
        } else {
            self.createDepartmentGroupAlert(department: self.viewModel.currentDepartment())
        }
    }
    /// 弹窗确认创建部门群
    private func createDepartmentGroupAlert(department: Department) {
        /// 构造alert弹窗
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateTipTitle)
        alertController.setContent(text: BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateTipContent)
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateTipCancel)
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateTipCreate, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            let body = CreateDepartmentGroupBody(departmentId: department.id) { [weak self] chat in
                guard let `self` = self else { return }
                self.jumpChatFromFeed(chat: chat)
            }
            self.navigator.open(body: body, from: self)
        })

        navigator.present(alertController, from: self)
    }

    /// 进入部门群
    private func enterDepartmentGroup(chatInfo: RustPB.Contact_V1_ChatInfo) {
        /// 每次都从服务器获取自己在该群中的身份，处理一种badcase：如果你在群里了，但是这里chatInfo.isMember不是最新的，那么会走
        /// JoinGroupApplyBody加群逻辑，如果群需要验证则只会弹一个alert（如果群不需要验证/你是群主则不会有问题）并不会再判断你是不是在群里
        /// pm希望如果在群里则直接进群
        self.viewModel.currentChatAPI().fetchChats(by: [chatInfo.chat.id], forceRemote: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatMap) in
                guard let `self` = self else { return }
                guard let chat = chatMap[chatInfo.chat.id] else {
                    if let window = self.view.window {
                        UDToast.showTips(with: BundleI18n.LarkContact.Lark_Legacy_GroupAddMemberFailTip, on: window)
                    }
                    return
                }
                /// 直接进群
                guard chat.role != .member else {
                    self.jumpChatFromFeed(chat: Chat.transform(pb: chatInfo.chat))
                    return
                }
                /// 加群逻辑
                let body = JoinGroupApplyBody(
                    chatId: chatInfo.chat.id,
                    way: .viaDepartmentStructure(jumpChat: false)
                ) { [weak self] status in
                    guard let `self` = self else { return }
                    switch status {
                    case .hadJoined:
                        self.jumpChatFromFeed(chat: Chat.transform(pb: chatInfo.chat))
                    case .waitAccept, .expired, .fail, .unTap, .sharerQuit,
                         .cancel, .ban, .groupDisband, .noPermission, .numberLimit, .contactAdmin, .nonCertifiedTenantRefuse:
                        break
                    }
                }
                self.navigator.open(body: body, from: self)
            }, onError: { [weak self] (error) in
                guard let window = self?.view.window else { return }
                UDToast.showFailure(
                    with: BundleI18n.LarkContact.Lark_Legacy_GroupAddMemberFailTip,
                    on: window,
                    error: error
                )
            }).disposed(by: bag)
    }

    private func jumpChatFromFeed(chat: Chat) {
        guard let nvc = navigationController else {
            assertionFailure("DepartmentViewController cannot find navigation")
            return
        }
        let body = ChatControllerByChatBody(
            chat: chat,
            fromWhere: .profile,
            showNormalBack: false
        )
        var params = NaviParams()
        params.switchTab = Tab.feed.url
        navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url, body: body, naviParams: params, wrap: LkNavigationController.self, from: nvc)
    }

    private func getMemberCount(department: Department) -> Int32 {
        let isMemberCountByRuleEnabled = userResolver.fg.staticFeatureGatingValue(with: .enableDepartmentHeadCountRules)
        if isMemberCountByRuleEnabled {
            return department.memberCountByDisplayRule
        } else {
            return department.memberCount
        }
    }

}

extension DepartmentVC {
    // 计算 item 在第几行，埋点使用
    private func calculateIndex(_ indexPath: IndexPath) -> Int {
        if indexPath.section > 0 {
            let preItemCount = (0...indexPath.section - 1)
                .map { departmentSections[$0].items.count }
                .reduce(0, +)
            return preItemCount + indexPath.row + 1

        }
        return indexPath.row + 1
    }
}

extension DepartmentVC: TargetInfoTapDelegate {
    func presentPreviewViewController(section: Int?, row: Int?) {
        func presentpreViewController(chatter: Chatter) {
            guard let fromVC = self.fromVC else { return }
            if !TargetPreviewUtils.canTargetPreview(chatter: chatter) {
                if let window = fromVC.view.window {
                    UDToast.showTips(with: BundleI18n.LarkContact.Lark_IM_UnableToPreviewContent_Toast, on: window)
                }
            } else {
                let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: "", userId: chatter.id, title: chatter.name)
                navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
            }
        }

        guard let section = section,
              let row = row,
              section < departmentSections.count,
              row < departmentSections[section].items.count
        else { return }
        let item = departmentSections[section].items[row]
        switch item {
        case let .LeaderSectionItem(leader: chatter, type: type):
            presentpreViewController(chatter: chatter)
        case let .ChatterSectionItem(chatter: chatter):
            presentpreViewController(chatter: chatter)
        default:
            break
        }
        let picker = selectionSource as? Picker
        SearchTrackUtil.trackPickerSelectClick(scene: picker?.scene, clickType: .chatDetail(target: "none"))
    }
}
