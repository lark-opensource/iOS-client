//
//  OrganizationSearchViewController.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/24.
// swiftlint:disable file_length type_body_length

import UIKit
import RxSwift
import RxCocoa
import SKFoundation
import SKUIKit
import SKResource
import LarkUIKit
import UniverseDesignToast
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignInput
import SpaceInterface

protocol OrganizationSearchViewControllerDelegate: AnyObject {
    func collaboratorUpdated(_ viewController: OrganizationSearchViewController, didUpdateWithItems items: [Collaborator])
    func collaboratorAdded(_ viewController: OrganizationSearchViewController, addedItem: Collaborator)
    func collaboratorRemoved(_ viewController: OrganizationSearchViewController, removedItem: Collaborator)
    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?)
}

class OrganizationSearchViewController: BaseViewController {
    // Rx
    let disposeBag = DisposeBag()
    private let viewModel: OrganizationSearchViewModel
    private var fileModel: CollaboratorFileModel {
        return viewModel.fileModel
    }
    let statistics: CollaboratorStatistics?
    private let permStatistics: PermissionStatistics?
    weak var delegate: OrganizationSearchViewControllerDelegate?
    weak var organizationNotifyDelegate: OrganizationInviteNotifyDelegate?
    private var currentQuery: String = ""
    private let keyboard = Keyboard()

    weak var followAPIDelegate: BrowserVCFollowDelegate?
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    /// 搜索框
    private lazy var searchTextField: CollaboratorSearchTextField = {
        let textField = CollaboratorSearchTextField(frame: .zero)
        textField.inputField.input.rx.text.changed
            .debounce(DispatchQueueConst.MilliSeconds_250, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                DocsLogger.info("search debounce 300 ms")
                guard let self = self else { return }
                self.searchTextfieldAction(query: text ?? "")
            }).disposed(by: disposeBag)
        textField.inputField.input.rx.text.changed
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                guard let text = text, text.isEmpty else { return }
                self.exitSearchMode()
            }).disposed(by: disposeBag)
        textField.inputField.input.addTarget(self, action: #selector(searchTextFieldEditingChanged(sender:)), for: .editingChanged)
        textField.inputField.delegate = self
        textField.backgroundColor = UDColor.bgBody
        return textField
    }()
    /// 已经选择了的协作者
    private lazy var avatarBar: CollaboratorAvatarBar = {
        let bar = CollaboratorAvatarBar()
        bar.delegate = self
        return bar
    }()
    /// 分割View
    private lazy var seperatorView: SeperatorView = {
        let seperatorView = SeperatorView(frame: .zero)
        seperatorView.backgroundColor = UDColor.bgBase
        return seperatorView
    }()
    /// 组织架构面包屑
    private lazy var organizationPathView: SKBreadcrumbsView<DepartmentInfo> = {
        let rootItem = DepartmentInfo.contacts
        let rootDepartment = DepartmentInfo.rootDepartment
        let config = SKBreadcrumbsViewConfig(seperatorImage: UDIcon.rightOutlined,
                                             titleFont: UIFont.systemFont(ofSize: 16),
                                             titleNormalColor: UIColor.ud.colorfulBlue,
                                             titleDisableColor: UIColor.ud.N900,
                                             itemSpacing: 4)
        let breadcrumbsView = SKBreadcrumbsView(rootItem: rootItem, config: config)
        breadcrumbsView.hideTopSeperatorView()
        breadcrumbsView.push(item: rootDepartment)
        breadcrumbsView.clickHandler = { [weak self] item in
            guard let self = self else { return }
            if item.id == DepartmentInfo.contactsId {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.popTo(item)
            }
        }
        return breadcrumbsView
    }()
    private let organizationCellIdentifier: String = "OrganizationCell"
    private let employeeCellIdentifier: String = "EmployeeCell"
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    /// 组织架构搜索的tableView
    private lazy var organizationSearchTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 50
        tableView.backgroundColor = UDColor.bgBase
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(OrganizationCell.self, forCellReuseIdentifier: organizationCellIdentifier)
        tableView.register(EmployeeCell.self, forCellReuseIdentifier: employeeCellIdentifier)
        return tableView
    }()
    private lazy var noResultBGView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()
    private lazy var noResultHintView: UDEmpty = {
        let hintView = UDEmpty(config: .init(title: .init(titleText: ""),
                                                 description: .init(descriptionText: ""),
                                                 imageSize: 100,
                                                 type: .noContact,
                                                 labelHandler: nil,
                                                 primaryButtonConfig: nil,
                                                 secondaryButtonConfig: nil))
        return hintView
    }()
    private lazy var pickerToolBar: CollaboratorPickerToolBar = {
        let toolBar = CollaboratorPickerToolBar()
        toolBar.setItems(toolBar.toolbarItems(), animated: false)
        toolBar.allowSelectNone = false
        toolBar.setBackgroundImage(UIImage.docs.color(UDColor.bgBody), forToolbarPosition: .bottom, barMetrics: .default)
        toolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        return toolBar
    }()
    private var collaboratorSearchTableView: CollaboratorSearchResultView?
    private let source: CollaboratorInviteSource

    public init(existedCollaborators: [Collaborator],
                selectedItems: [Collaborator],
                fileModel: CollaboratorFileModel,
                statistics: CollaboratorStatistics?,
                permStatistics: PermissionStatistics?,
                userPermissions: UserPermissionAbility?,
                publicPermisson: PublicPermissionMeta?,
                source: CollaboratorInviteSource,
                isBitableAdvancedPermissions: Bool = false,
                bitablePermissonRule: BitablePermissionRule? = nil,
                isEmailSharingEnabled: Bool = false) {
        self.viewModel = OrganizationSearchViewModel(existedCollaborators: existedCollaborators,
                                                     selectedItems: selectedItems,
                                                     fileModel: fileModel,
                                                     userPermissions: userPermissions,
                                                     publicPermisson: publicPermisson,
                                                     isBitableAdvancedPermissions: isBitableAdvancedPermissions,
                                                     bitablePermissonRule: bitablePermissonRule,
                                                     isEmailSharingEnabled: isEmailSharingEnabled)

        self.statistics = statistics
        self.permStatistics = permStatistics
        self.source = source
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("OrganizationSearchViewController deinit!")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if fileModel.isForm {
            title = BundleI18n.SKResource.Bitable_Form_AddCollaborator
        } else if fileModel.isBitableSubShare {
            title = BundleI18n.SKResource.Bitable_Share_AddViewers_Title
        } else {
            title = BundleI18n.SKResource.Doc_Permission_AddUserSelctDepartmentTitle
        }
        setupUI()
        loadData()
        bindviewModel()
        setupToolBar()
        addKeyboardObserve()
        permStatistics?.reportPermissionOrganizationAuthorizeView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboard.start()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboard.stop()
    }
    
    @objc
    private func orientationDidChange() {
        updateContentSize()
    }
    
    override func backBarButtonItemAction() {
        permStatistics?.reportPermissionOrganizationAuthorizeClick(click: .back, target: .noneTargetView)
        super.backBarButtonItemAction()
    }
    
    private func setupUI() {
        setupNav()
        view.backgroundColor = .clear
        view.addSubview(contentView)
        updateContentSize()
        contentView.addSubview(searchTextField)
        searchTextField.backgroundColor = UDColor.bgBodyOverlay
        let isSingleContainer = fileModel.spaceSingleContainer || fileModel.wikiV2SingleContainer
        let placeholderContext = CollaboratorUtils.PlaceHolderContext(
            source: source,
            docsType: fileModel.docsType,
            isForm: fileModel.isForm,
            isBitableAdvancedPermissions: viewModel.isBitableAdvancedPermissions,
            isSingleContainer: isSingleContainer,
            isSameTenant: fileModel.isSameTenantWithOwner,
            isEmailSharingEnabled: viewModel.isEmailSharingEnabled)
        searchTextField.placeholder = CollaboratorUtils.getCollaboratorSearchPlaceHolder(context: placeholderContext)
        searchTextField.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(36)
        }
        contentView.addSubview(avatarBar)
        avatarBar.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(searchTextField.snp.bottom).offset(12)
            make.height.equalTo(0)
        }
        updateAvatarBar()
        contentView.addSubview(seperatorView)
        seperatorView.snp.makeConstraints { (make) in
            make.top.equalTo(avatarBar.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
        contentView.addSubview(organizationPathView)
        organizationPathView.snp.makeConstraints { (make) in
            make.top.equalTo(seperatorView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        contentView.addSubview(pickerToolBar)
        pickerToolBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        contentView.addSubview(organizationSearchTableView)
        organizationSearchTableView.snp.makeConstraints { (make) in
            make.top.equalTo(organizationPathView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(pickerToolBar.snp.top)
        }
        contentView.addSubview(noResultBGView)
        noResultBGView.snp.makeConstraints { (make) in
            make.top.equalTo(organizationPathView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(pickerToolBar.snp.top)
        }
        noResultBGView.addSubview(noResultHintView)
        noResultHintView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    private func setupNav() {
        if SKDisplay.phone {
            navigationBar.layer.cornerRadius = 12
            navigationBar.layer.maskedCorners = .top
        }
    }
    
    private func updateContentSize() {
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            navigationBar.snp.remakeConstraints { (make) in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(14)
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
            }
            contentView.snp.remakeConstraints { (make) in
                make.width.equalTo(navigationBar.snp.width)
                make.centerX.bottom.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom)
            }
        } else {
            navigationBar.snp.remakeConstraints { (make) in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.leading.trailing.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    private func setupToolBar() {
        self.view.bringSubviewToFront(pickerToolBar)
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in
            guard let self = self else { return }
            let selectedItems = self.viewModel.selectedItems
            let userList: [[String: Any]] = Array(selectedItems).map {
                return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                        "collaborate_type": $0.rawValue]
            }
            self.permStatistics?.reportPermissionOrganizationAuthorizeClick(click: .next, target: .permissionSelectContactView, userList: userList)
            self.resignSearchTextField { [weak self] in
                guard let self = self else { return }
                if self.viewModel.isBitableAdvancedPermissions {
                    self.openBitableCollaboratorInviteViewController()
                } else {
                    self.openCollaboratorInviteViewController()
                }
            }
        }
        updatePickerToolBar()
    }

    private func openCollaboratorInviteViewController() {
        let config = CollaboratorInviteModeConfig.config(with: self.viewModel.publicPermisson,
                                                             userPermisson: self.viewModel.userPermissions,
                                                             isBizDoc: self.viewModel.fileModel.docsType.isBizDoc)
        let inviteVM = CollaboratorInviteVCDependency(fileModel: self.viewModel.fileModel,
                                                   items: self.viewModel.selectedItems,
                                                   layoutConfig: config,
                                                   needShowOptionBar: true,
                                                   source: self.source,
                                                   statistics: self.statistics,
                                                   permStatistics: self.permStatistics,
                                                   userPermisson: self.viewModel.userPermissions)
        let vc = CollaboratorInviteViewController(vm: inviteVM)
        vc.watermarkConfig.needAddWatermark = self.watermarkConfig.needAddWatermark
        vc.organizationDelegate = self
        vc.delegate = self
        vc.supportOrientations = self.supportedInterfaceOrientations
        self.navigationController?.pushViewController(vc, animated: true)
        self.statistics?.clickCollaborateInviterNextStep(tenantParams: CollaboratorStatistics.getTenantParams(ownerId: self.fileModel.ownerID))
    }

    private func openBitableCollaboratorInviteViewController() {
        let config = CollaboratorInviteModeConfig.config(with: self.viewModel.publicPermisson,
                                                             userPermisson: self.viewModel.userPermissions,
                                                             isBizDoc: self.viewModel.fileModel.docsType.isBizDoc)
        let inviteVM = CollaboratorInviteVCDependency(fileModel: self.viewModel.fileModel,
                                                   items: self.viewModel.selectedItems,
                                                   layoutConfig: config,
                                                   needShowOptionBar: true,
                                                   source: self.source,
                                                   statistics: self.statistics,
                                                   permStatistics: self.permStatistics,
                                                   userPermisson: self.viewModel.userPermissions,
                                                   bitablePermissonRule: self.viewModel.bitablePermissonRule)
        let vc = BitableCollaboratorInviteViewController(vm: inviteVM)
        vc.watermarkConfig.needAddWatermark = self.watermarkConfig.needAddWatermark
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func addKeyboardObserve() {
        keyboard.on(events: Keyboard.KeyboardEvent.allCases) { [weak self] (options) in
            guard let self = self else { return }
            guard let view = self.view else { return }
            let viewWindowBounds = view.convert(view.bounds, to: nil)

            var endFrame = options.endFrame.minY
            // 开启减弱动态效果/首选交叉淡出过渡效果,endFrame返回0.0,导致offset计算有问题
            if endFrame <= 0 {
                endFrame = viewWindowBounds.maxY
            }
            var offset = viewWindowBounds.maxY - endFrame - self.view.layoutMargins.bottom
            
            if self.isMyWindowRegularSizeInPad {
                var endFrameY = (options.endFrame.minY - self.view.frame.height) / 2
                endFrameY = endFrameY > 44 ? endFrameY : 44
                let moveOffest = viewWindowBounds.minY - endFrameY
                offset -= moveOffest
            }
            self.pickerToolBar.snp.updateConstraints({ (make) in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(min(-offset, 0))
            })
            
            let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
            UIView.animate(withDuration: options.animationDuration, delay: 0, options: animationCurve, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    private func loadData() {
        self.loading()
        viewModel.searchVisibleDepartment(departmentInfo: DepartmentInfo.rootDepartment)
    }

    // nolint: duplicated_code
    // 更新bar
    private func updateAvatarBar() {
        avatarBar.setImages(items: viewModel.selectedItems.map {
            var imageURL: String?
            var image: UIImage?
            if $0.type == .organization || $0.type == .ownerLeader {
                imageURL = nil
                image = BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32
            } else if $0.type == .userGroup || $0.type == .userGroupAssign {
                imageURL = nil
                image = BundleResources.SKResource.Common.Collaborator.icon_usergroup
            } else if $0.type == .email {
                imageURL = nil
                image = BundleResources.SKResource.Common.Collaborator.avatar_person
            } else {
                imageURL = $0.avatarURL
                image = nil
            }
            return AvatarBarItem(id: $0.userID, imageURL: imageURL, imageKey: $0.imageKey, image: image)
        }, complete: { [weak self] in
            guard let bar = self?.avatarBar else { return }
            // 滚动到最后
            bar.setContentOffset(CGPoint(x: max(0, bar.contentSize.width - bar.bounds.size.width), y: 0),
                                 animated: true)
        })
        avatarBar.snp.updateConstraints({ (make) in
            make.top.equalTo(searchTextField.snp.bottom).offset(viewModel.selectedItems.isEmpty ? 0 : 12)
            make.height.equalTo(viewModel.selectedItems.isEmpty ? 0 : 32)
        })
        view.layoutIfNeeded()
    }
    // enable-lint: duplicated_code

    // 更新 PickerToolBar
    private func updatePickerToolBar() {
        pickerToolBar.updateSelectedItem(firstSelectedItems: viewModel.selectedItems, secondSelectedItems: [], updateResultButton: true)
    }

    // 面包屑跳转
    private func popTo(_ department: DepartmentInfo) {
        organizationPathView.popTo(item: department)
        // 返回到点击的目录处
        viewModel.jumpToCurrentDepartment(department)
    }

    // 组织架构搜索的 ViewModel
    private func bindviewModel() {
        viewModel.tableViewDriver.drive(onNext: { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            switch result {
            case .success:
                self.noResultBGView.isHidden = true
                self.organizationSearchTableView.reloadData()
            case .failure(let error):
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_OperateFailed, type: .failure)
                DocsLogger.error("search organization failed", extraInfo: nil, error: error, component: nil)
            }
        }).disposed(by: disposeBag)

        viewModel.breadcrumbsViewDriver.drive(onNext: { [weak self] department in
            guard let self = self else { return }
            guard let department = department, department.id != DepartmentInfo.rootDepartmentId else { return }
            self.organizationPathView.push(item: department)
            self.organizationPathView.snp.updateConstraints { (make) in
                make.height.equalTo(50)
            }
        }).disposed(by: disposeBag)

        viewModel.noResultDriver.drive(onNext: { [weak self] resultType in
            guard let self = self else { return }
            guard let resultType = resultType else { return }
            self.noResultBGView.isHidden = false

            self.noResultHintView.update(config: .init(title: .init(titleText: ""),
                                                       description: .init(descriptionText: resultType.description),
                                                       type: .noContact))
        }).disposed(by: disposeBag)
    }

    private func updateUI() {
        // 更新 Avatar Bar
        self.updateAvatarBar()
        // 更新 PickerToolBar
        updatePickerToolBar()
        // 更新 TableView
        viewModel.collaboratorDatasConversion()
        collaboratorSearchTableView?.updateSelectItems(self.viewModel.selectedItems)
    }

    @objc
    private func searchTextfieldAction(query: String) {
        guard query != currentQuery else { return }
        currentQuery = query
        if !query.isEmpty {
            // 进入搜索状态
            enterSearchMode(with: query)
        } else {
            // 退出搜索状态
            exitSearchMode()
        }
    }
    
    func resignSearchTextField(completion: (() -> Void)? = nil) {
        if searchTextField.inputField.isFirstResponder {
            searchTextField.inputField.resignFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                completion?()
            }
        } else {
            completion?()
        }
    }
    func loading(isBehindNavBar: Bool = false) {
        showLoading(isBehindNavBar: isBehindNavBar, backgroundAlpha: 0.05)
    }
}

extension OrganizationSearchViewController: UDTextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UIScrollViewDelegate
extension OrganizationSearchViewController: UIScrollViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 滚动时收起键盘
        resignSearchTextField()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard organizationSearchTableView.contentOffset.y > 0 else { return }
        guard organizationSearchTableView.contentOffset.y + organizationSearchTableView.bounds.size.height > organizationSearchTableView.contentSize.height + 10 else { return }
        guard let currentDepartment = organizationPathView.currentItem else {
            DocsLogger.info("can not get current item")
            return
        }
        viewModel.loadMoreVisibleDepartment(departmentInfo: currentDepartment)
    }
}

extension OrganizationSearchViewController: CollaboratorAvatarBarDelegate {
    func avatarBar(_ bar: CollaboratorAvatarBar, didSelectAt index: Int) {
        guard index >= 0, index < viewModel.selectedItems.count else { return }
        let item = bar.items[index]
        // 点击头像去掉选择的
        if let index = viewModel.selectedItems.firstIndex(where: { $0.userID == item.id }) {
            let deletedItem = viewModel.selectedItems[index]
            // 通知delegate取消了选择
            delegate?.collaboratorRemoved(self, removedItem: deletedItem)
            viewModel.selectedItems.remove(at: index)
            updateUI()
        } else {
            DocsLogger.error("out of range!")
        }
    }
}

extension OrganizationSearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row >= 0, indexPath.row < viewModel.datas.count else { return UITableViewCell() }
        let model = viewModel.datas[indexPath.row]
        switch model.organizationType {
        case .department:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: organizationCellIdentifier, for: indexPath) as? OrganizationCell else { return UITableViewCell() }
            cell.update(item: model)
            cell.didClickedBlock = { [weak self] item in
                guard let self = self else { return }
                guard let item = item as? DepartmentInfo else {
                    DocsLogger.error("item is nil!")
                    return
                }
                if item.isExist {
                    return
                }
                self.permStatistics?.reportPermissionOrganizationAuthorizeClick(click: .nextLevel, target: .noneTargetView)
                if item.selectType == .blue {
                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_DepSelectedClickTips, type: .tips)
                } else {
                    self.loading()
                    self.viewModel.searchVisibleDepartment(departmentInfo: item)
                }
            }
            cell.backgroundColor = UDColor.bgBody
            return cell
        case .employee:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: employeeCellIdentifier, for: indexPath) as? EmployeeCell else { return UITableViewCell() }
            cell.update(item: model)
            cell.backgroundColor = UDColor.bgBody
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        // 更新数据源
        guard indexPath.row >= 0,
              indexPath.row < viewModel.datas.count,
              indexPath.row < viewModel.collaborators.count
        else { return }
        let collaborator = viewModel.collaborators[indexPath.row]
        var cellItem = viewModel.datas[indexPath.row]
        // 当前用户不可添加
        if cellItem.id == User.current.info?.userID {
            return
        }
        // Owner不可添加
        if cellItem.id == fileModel.ownerID {
            return
        }
        
        if cellItem.isExist {
            return
        }
        
        if cellItem.selectType == .disable {
            return
        } else if cellItem.selectType == .blue {
            cellItem.selectType = .gray
            if let index = viewModel.selectedItems.firstIndex(where: { $0.userID == cellItem.id }) {
                let deletedItem = viewModel.selectedItems[index]
                viewModel.selectedItems.remove(at: index)
                delegate?.collaboratorRemoved(self, removedItem: deletedItem)
            }
        } else {
            cellItem.selectType = .blue
            viewModel.selectedItems.append(collaborator)
            delegate?.collaboratorAdded(self, addedItem: collaborator)
        }
        updateAvatarBar()
        updatePickerToolBar()
        self.organizationSearchTableView.reloadData()
    }
}

extension OrganizationSearchViewController {
    private func enterSearchMode(with query: String) {
        let searchView: CollaboratorSearchResultView
        if let tableView = self.collaboratorSearchTableView {
            searchView = tableView
        } else {
            permStatistics?.reportPermissionOrganizationAuthorizeClick(click: .search, target: .permissionOrganizationAuthorizeSearchView)
            permStatistics?.reportPermissionOrganizationAuthorizeSearchView()
            
            var inviteExternalOption = CollaboratorSearchConfig.InviteExternalOption.all
            /// 对外分享关闭(非admin关闭)时,不允许用户选择
            let finalOption: CollaboratorSearchConfig.InviteExternalOption
            if let permissionMeta = viewModel.publicPermisson {
                if permissionMeta.forbiddenExternalCollaboratorByUser {
                    finalOption = .none
                } else if permissionMeta.allowInviteExternalUserOnly {
                    finalOption = .userOnly
                } else {
                    finalOption = .all
                }
            } else {
                finalOption = .all
            }

            if fileModel.wikiV2SingleContainer {
                /// wiki2.0 命中wiki单页面fg，可以邀请外部协作者
                inviteExternalOption = finalOption
            } else if fileModel.spaceSingleContainer {
                inviteExternalOption = finalOption
            }
            let isSingleContainer = fileModel.wikiV2SingleContainer || fileModel.spaceSingleContainer
            let placeholderContext = CollaboratorUtils.PlaceHolderContext(
                source: source,
                docsType: fileModel.docsType,
                isForm: fileModel.isForm,
                isBitableAdvancedPermissions: viewModel.isBitableAdvancedPermissions,
                isSingleContainer: isSingleContainer,
                isSameTenant: fileModel.isSameTenantWithOwner,
                isEmailSharingEnabled: viewModel.isEmailSharingEnabled)
            let userGroupEnable = CollaboratorUtils.addUserGroupEnable(context: placeholderContext)
            let config = CollaboratorSearchConfig(shouldSearchOrganization: CollaboratorUtils.addDepartmentEnable(source: source, docsType: self.fileModel.docsType),
                                                  shouldSearchUserGroup: userGroupEnable,
                                                  inviteExternalOption: inviteExternalOption)
            let viewModel = CollaboratorSearchTableViewModel(objToken: fileModel.objToken,
                                                             docsType: fileModel.docsType,
                                                             wikiV2SingleContainer: fileModel.wikiV2SingleContainer,
                                                             spaceSingleContainer: fileModel.spaceSingleContainer,
                                                             isBitableAdvancedPermissions: viewModel.isBitableAdvancedPermissions,
                                                             ownerId: fileModel.ownerID,
                                                             existedCollaborators: viewModel.getExistedCollaborators(),
                                                             selectedItems: self.viewModel.selectedItems,
                                                             searchConfig: config,
                                                             isEmailSharingEnabled: viewModel.isEmailSharingEnabled,
                                                             canInviteEmailCollaborator: viewModel.userPermissions?.isFA ?? false,
                                                             adminCanInviteEmailCollaborator: AdminPermissionManager.adminCanExternalShare(),
                                                             followAPIDelegate: followAPIDelegate)
            searchView = CollaboratorSearchResultView(viewModel: viewModel)
            self.collaboratorSearchTableView = searchView
            searchView.searchDelegate = self
            searchView.scrollDelegate = self
        }
        if searchView.superview == nil {
            view.addSubview(searchView)
            searchView.snp.makeConstraints { (make) in
                make.top.equalTo(organizationPathView.snp.top)
                make.left.equalTo(contentView.snp.left)
                make.right.equalTo(contentView.snp.right)
                make.bottom.greaterThanOrEqualTo(pickerToolBar.snp.top)
            }
        }
        loading()
        searchView.search(query: query)
    }

    private func exitSearchMode() {
        guard let tableView = self.collaboratorSearchTableView else { return }
        tableView.removeFromSuperview()
        tableView.clear()
    }

    @objc
    private func searchTextFieldEditingChanged(sender: UITextField) {
        guard let query = sender.text else { return }
        if query.isEmpty {
            exitSearchMode()
        }
    }
}

extension OrganizationSearchViewController: BitableCollaboratorInviteViewControllerDelegate {
    func collaboardInvite(_ collaboardInvite: BitableCollaboratorInviteViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedItems = items
        updateUI()
        delegate?.collaboratorUpdated(self, didUpdateWithItems: viewModel.selectedItems)
    }
}

extension OrganizationSearchViewController: CollaboratorInviteViewControllerDelegate {

    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?) {
        delegate?.dissmissSharePanel(animated: animated, completion: completion)
    }

    func collaboardInvite(_ collaboardInvite: CollaboratorInviteViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedItems = items
        updateUI()
        delegate?.collaboratorUpdated(self, didUpdateWithItems: viewModel.selectedItems)
    }
}

extension OrganizationSearchViewController: OrganizationInviteNotifyDelegate {
    func dismissSharePanelAndNotify(completion: (() -> Void)?) {
        organizationNotifyDelegate?.dismissSharePanelAndNotify(completion: completion)
    }
    func dismissInviteCompletion(completion: (() -> Void)?) {
        organizationNotifyDelegate?.dismissInviteCompletion(completion: completion)
    }
}

extension OrganizationSearchViewController: CollaboratorSearchResultViewDelegate {

    func collaboratorSearched(_ view: CollaboratorSearchResultView, didUpdateWithSearchResults searchResults: [Collaborator]?) {
        hideLoading()
        return
    }

    func collaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {
        hideLoading()
        handleInviteCore(invitedItem: invitedItem)
    }

    func collaboratorRemoved(_ view: CollaboratorSearchResultView, removedItem: Collaborator) {
        hideLoading()
        guard let index = viewModel.selectedItems.firstIndex(where: { (collaborator) -> Bool in
            return collaborator.userID == removedItem.userID
        }) else { return }
        viewModel.selectedItems.remove(at: index)
        updateUI()
    }

    func blockedCollaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {
    }

    func blockedExternalCollaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {
        if viewModel.publicPermisson?.allowInviteExternalUserOnly == true && invitedItem.type != .user {
            if fileModel.isFolder {
                showToast(text: BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario8, type: .tips)
            } else {
                showToast(text: BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario5, type: .tips)
            }
            return
        }
        if fileModel.spaceSingleContainer || fileModel.wikiV2SingleContainer {
            if let reason = viewModel.publicPermisson?.externalCollaboratorForbiddenReason(isFolder: fileModel.isFolder, isWiki: fileModel.wikiV2SingleContainer) {
                showToast(text: reason, type: .tips)
            } else {
                let text = fileModel.isFolder
                    ? BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_folder_toast
                    : BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_toast
                showToast(text: text, type: .tips)
            }
        } else {
            showToast(text: BundleI18n.SKResource.CreationMobile_ECM_ISVpermission_cannotadd, type: .tips)
        }
    }
    
    private func handleInviteCore(invitedItem: Collaborator) {
        viewModel.selectedItems.append(invitedItem)
        updateCollaboratorPermissions([invitedItem])
        updateUI()
    }
    
    func updateCollaboratorPermissions(_ selectedItems: [Collaborator]) {
        for item in selectedItems {
            CollaboratorUtils.setupSelectItemPermission(currentItem: item,
                                                        objToken: fileModel.objToken,
                                                        docsType: fileModel.docsType,
                                                        userPermissions: viewModel.userPermissions)
            statistics?.clickSelectPermInviter(groupType: searchTextField.text?.isEmpty == false ? .search : .recent,
                                                          userType: item.type == .user ? .user : .chat,
                                                          tenantParams: CollaboratorStatistics.getTenantParams(ownerId: fileModel.ownerID),
                                                          collaboratorParams: CollaboratorStatistics.getCollaboratorParams(tenantId: item.tenantID))
        }
    }
    
    func blockedEmailCollaborator(_ message: String) {
        showToast(text: message, type: .tips)
    }
}

extension OrganizationSearchViewController: CollaboratorSearchResultScrollViewDelegate {
    public func willBeginDragging(_ scrollView: UIScrollView) {
        // 滚动时收起键盘
        resignSearchTextField()
    }
}

extension OrganizationSearchViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? self.view) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
