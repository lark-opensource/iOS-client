//
//  CollaboratorSearchViewController.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/23.
//  swiftlint:disable file_length type_body_length

import UIKit
import RxSwift
import RxCocoa
import SKFoundation
import SKUIKit
import SKResource
import LarkUIKit
import LarkAddressBookSelector
import EENavigator
import LarkLocalizations
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignInput
import UniverseDesignIcon
import UniverseDesignLoading
import SpaceInterface

public struct CollaboratorSearchVCDependency {
    // 打点类，可选是因为从新建文件夹路径进来不需要
    let statistics: CollaboratorStatistics?
    let permStatistics: PermissionStatistics?

    // 是否需要提示的Bar，从新建文件夹路径进来不需要
    let needShowOptionBar: Bool

    public init(statistics: CollaboratorStatistics?,
                permStatistics: PermissionStatistics?,
                needShowOptionBar: Bool) {
        self.statistics = statistics
        self.needShowOptionBar = needShowOptionBar
        self.permStatistics = permStatistics
    }
}

public struct CollaboratorSearchVCUIConfig {
    // 是否需要直接激活键盘
    let needActivateKeyboard: Bool
    // 来源
    let source: CollaboratorInviteSource

    public init(needActivateKeyboard: Bool, source: CollaboratorInviteSource) {
        self.needActivateKeyboard = needActivateKeyboard
        self.source = source
    }
}

public protocol CollaboratorSearchViewControllerDelegate: AnyObject {
    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?)
}
extension CollaboratorSearchViewControllerDelegate {
    public func dissmissSharePanel(animated: Bool, completion: (() -> Void)?) {

    }
}

public final class CollaboratorSearchViewController: BaseViewController {

    // RxSwift
    private let bag = DisposeBag()
    // 标记是否是第一次唤起键盘
    private var firstActiveKeyboard: Bool = true

    private lazy var loadingView: UIView = {
        let view = CollaboratorLoadingView(topOffset: 150)
        view.isHidden = true
        return view
    }()
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    weak var followAPIDelegate: BrowserVCFollowDelegate?

    // UI
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    /// 搜索框
    private(set) lazy var searchTextField: CollaboratorSearchTextField = {
        let textField = CollaboratorSearchTextField()
        textField.inputField.input.rx.text.changed
            .debounce(DispatchQueueConst.MilliSeconds_250, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                DocsLogger.info("search debounce 300 ms")
                self?.searchTextfieldAction(query: text ?? "")
            }).disposed(by: bag)
        textField.inputField.input.addTarget(self, action: #selector(searchTextFieldBeginEdting(sender:)), for: .editingDidBegin)
        textField.inputField.delegate = self
        textField.backgroundColor = UDColor.bgBodyOverlay
        return textField
    }()
    /// 已选择的协作者头像面板
    private lazy var avatarBar: CollaboratorAvatarBar = {
        let bar = CollaboratorAvatarBar()
        bar.delegate = self
        return bar
    }()
    private lazy var topSeperatorView: SeperatorView = {
        let seperatorView = SeperatorView(frame: .zero)
        seperatorView.updateBottomSeprateLine(isHidden: true)
        seperatorView.backgroundColor = UDColor.bgBase
        return seperatorView
    }()
    private lazy var bottomSeperatorView: SeperatorView = {
        let seperatorView = SeperatorView(frame: .zero)
        seperatorView.updateTopSeprateLine(isHidden: true)
        seperatorView.backgroundColor = UDColor.bgBase
        return seperatorView
    }()
    private let cellReuseIdentifier = "CollaboratorInvitationCell"
    private lazy var invitationTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorColor = UDColor.lineDividerDefault
        tableView.backgroundColor = UDColor.bgBody
        tableView.rowHeight = 52
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 0)
        tableView.register(CollaboratorInvitationCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = UDColor.bgBody
        return tableView
    }()
    /// 协作者选择列表
    private(set) lazy var collaboratorSearchTableView: CollaboratorSearchResultView = {
        let shouldCheckExisit = (uiConfig.source == .diyTemplate || fileModel.spaceSingleContainer || viewModel.isBitableAdvancedPermissions)

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
            inviteExternalOption = finalOption
        } else if fileModel.spaceSingleContainer {
            inviteExternalOption = finalOption
        }
        let isSingleContainer = fileModel.wikiV2SingleContainer || fileModel.spaceSingleContainer
        let placeholderContext = CollaboratorUtils.PlaceHolderContext(
            source: uiConfig.source,
            docsType: fileModel.docsType,
            isForm: fileModel.isForm,
            isBitableAdvancedPermissions: viewModel.isBitableAdvancedPermissions,
            isSingleContainer: isSingleContainer,
            isSameTenant: fileModel.isSameTenantWithOwner,
            isEmailSharingEnabled: viewModel.isEmailSharingEnabled)
        let userGroupEnable = CollaboratorUtils.addUserGroupEnable(context: placeholderContext)
        let config = CollaboratorSearchConfig(shouldSearchOrganization: CollaboratorUtils.addDepartmentEnable(source: uiConfig.source, docsType: fileModel.docsType),
                                              shouldSearchUserGroup: userGroupEnable,
                                              inviteExternalOption: inviteExternalOption)
        let viewModel = CollaboratorSearchTableViewModel(objToken: fileModel.objToken,
                                                         docsType: fileModel.docsType,
                                                         wikiV2SingleContainer: fileModel.wikiV2SingleContainer,
                                                         spaceSingleContainer: fileModel.spaceSingleContainer,
                                                         isBitableAdvancedPermissions: viewModel.isBitableAdvancedPermissions,
                                                         ownerId: fileModel.ownerID,
                                                         existedCollaborators: viewModel.existedCollaborators,
                                                         selectedItems: viewModel.selectedItems,
                                                         wikiMembers: viewModel.wikiMembers,
                                                         searchConfig: config,
                                                         isEmailSharingEnabled: viewModel.isEmailSharingEnabled,
                                                         canInviteEmailCollaborator: viewModel.userPermissions?.isFA ?? false,
                                                         adminCanInviteEmailCollaborator: AdminPermissionManager.adminCanExternalShare(),
                                                         followAPIDelegate: followAPIDelegate)
        let tableView = CollaboratorSearchResultView(viewModel: viewModel)
        tableView.searchDelegate = self
        tableView.scrollDelegate = self
        tableView.backgroundColor = UDColor.bgBody
        return tableView
    }()
    /// 底部的选择面板
    private lazy var pickerToolBar: CollaboratorPickerToolBar = {
        let toolBar = CollaboratorPickerToolBar()
        toolBar.setItems(toolBar.toolbarItems(), animated: false)
        toolBar.allowSelectNone = false
        toolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        toolBar.setBackgroundImage(UIImage.docs.color(UDColor.bgBody),
                                   forToolbarPosition: .bottom,
                                                 barMetrics: .default)
        return toolBar
    }()
    private var alertController: UDDialog?

    private let keyboard = Keyboard()
    private let viewModel: CollaboratorSearchViewModel
    private(set) var dependency: CollaboratorSearchVCDependency
    private let uiConfig: CollaboratorSearchVCUIConfig
    private var isFirstSearched: Bool = true
    private var currentQuery: String = ""
    public weak var collaboratorSearchVCDelegate: CollaboratorSearchViewControllerDelegate?
    weak var organizationNotifyDelegate: OrganizationInviteNotifyDelegate?

    private var fileModel: CollaboratorFileModel {
        return self.viewModel.fileModel
    }

    public init(viewModel: CollaboratorSearchViewModel,
                dependency: CollaboratorSearchVCDependency,
                uiConfig: CollaboratorSearchVCUIConfig) {
        self.viewModel = viewModel
        self.dependency = dependency
        self.uiConfig = uiConfig
        super.init(nibName: nil, bundle: nil)
        viewModel.invitationDataChanged = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.invitationTableView.reloadData()
                self.invitationTableView.snp.updateConstraints { make in
                    make.height.equalTo(self.viewModel.invitationTableViewHeight)
                }
            }
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange(_:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("CollaboratorSearchViewController deinit!")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        view.backgroundColor = .clear
        title = viewModel.naviBarTitle
        addCloseBarItemIfNeed()
        view.addSubview(contentView)
        updateContentSize()
        contentView.addSubview(searchTextField)
        let isSingleContainer = fileModel.spaceSingleContainer || fileModel.wikiV2SingleContainer
        let placeholderContext = CollaboratorUtils.PlaceHolderContext(
            source: uiConfig.source,
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
        contentView.addSubview(topSeperatorView)
        topSeperatorView.isHidden = !viewModel.shouldShowInvitationTableView
        topSeperatorView.snp.makeConstraints { (make) in
            make.top.equalTo(avatarBar.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            if viewModel.shouldShowInvitationTableView {
                make.height.equalTo(8)
            } else {
                make.height.equalTo(0)
            }
        }
        contentView.addSubview(invitationTableView)
        invitationTableView.snp.makeConstraints { (make) in
            make.top.equalTo(topSeperatorView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(viewModel.invitationTableViewHeight)
        }
        contentView.addSubview(bottomSeperatorView)
        bottomSeperatorView.isHidden = !viewModel.shouldShowInvitationTableView
        bottomSeperatorView.snp.makeConstraints { (make) in
            make.top.equalTo(invitationTableView.snp.bottom)
            make.left.right.equalToSuperview()
            if viewModel.shouldShowInvitationTableView {
                make.height.equalTo(8)
            } else {
                make.height.equalTo(0)
            }
        }
        contentView.addSubview(collaboratorSearchTableView)
        collaboratorSearchTableView.snp.makeConstraints { (make) in
            make.top.lessThanOrEqualTo(bottomSeperatorView.snp.bottom)
            make.left.right.equalToSuperview()
            //make.bottom.equalTo(pickerToolBar.snp.top).offset(-0.5)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(44.5)
        }
        contentView.addSubview(pickerToolBar)
        pickerToolBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        setupPickerToolBar()
        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(searchTextField.snp.bottom)
        }

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
        search(query: currentQuery)
        updateAvatarBar()
        updatePickerToolBar()
        viewModel.requestUserPermission()
        clickShowCollaborateSearch()
        dependency.permStatistics?.reportPermissionAddCollaboratorView()
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
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(14)
                make.centerX.equalToSuperview()
                make.width.equalTo(contentView.snp.width)
            }
            contentView.snp.remakeConstraints { (make) in
                make.width.equalToSuperview().multipliedBy(0.7)
                make.centerX.bottom.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom)
            }
        } else {
            navigationBar.snp.remakeConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.leading.trailing.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
    
    @objc
    private func orientationDidChange(_ notification: Notification) {
        guard SKDisplay.phone else { return }
        guard let int = notification.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
              let newOrientation = UIInterfaceOrientation(rawValue: int),
              newOrientation != .unknown else { return }
        updateContentSize()
    }
    
    
    
    private func addCloseBarItemIfNeed() {
        let btnItem = SKBarButtonItem(title: BundleI18n.SKResource.Doc_List_Cancel,
                                      style: .plain,
                                      target: self,
                                      action: #selector(didClickedCloseBarItem))
        btnItem.foregroundColorMapping = SKBarButton.defaultTitleColorMapping
        btnItem.id = .close
        navigationBar.leadingBarButtonItems = [btnItem]
    }

    private func clickShowCollaborateSearch() {
        self.dependency.statistics?.clickShowCollaborateSearch(tenantParams: CollaboratorStatistics.getTenantParams(ownerId: self.fileModel.ownerID))
    }
    
    @objc
    func didClickedCloseBarItem() {
        dependency.permStatistics?.reportPermissionAddCollaboratorClick(click: .close, target: .noneTargetView)
        self.dismiss(animated: true, completion: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboard.start()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboard.stop()
    }

    public override func backBarButtonItemAction() {
        dependency.permStatistics?.reportPermissionAddCollaboratorClick(click: .close, target: .noneTargetView)
        back()
    }

    // nolint: duplicated_code
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
            } else  {
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
    }
    // enable-lint: duplicated_code

    private func updatePickerToolBar() {
        pickerToolBar.updateSelectedItem(firstSelectedItems: viewModel.selectedItems,
                                         secondSelectedItems: [],
                                         updateResultButton: true)
    }

    private func updateSearchResultView() {
        collaboratorSearchTableView.updateSelectItems(viewModel.selectedItems)
    }

    func search(query: String) {
        if isFirstSearched {
            loadingView.isHidden = false
            isFirstSearched = false
        } else {
            loadingView.isHidden = false
        }
        collaboratorSearchTableView.search(query: query)
    }

    func setupPickerToolBar() {
        self.contentView.bringSubviewToFront(pickerToolBar)
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in
            guard let self = self else { return }
            let selectedItems = self.viewModel.selectedItems
            let num = String(selectedItems.count)
            let userList: [[String: Any]] = Array(selectedItems).map {
                return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                        "collaborate_type": $0.rawValue]
            }
            let target: DocsTracker.EventType
            if self.viewModel.isBitableAdvancedPermissions {
                target = .ccmBitablePremiumPermissionInviteCollaboratorView
            } else if self.fileModel.isForm {
                target = .bitableFormPermissionSelectContactView
            } else {
                target = .noneTargetView
            }
            self.dependency.permStatistics?.reportPermissionAddCollaboratorClick(click: .next,
                                                                                 num: num,
                                                                                 target: target,
                                                                                 userList: userList)
            if self.viewModel.isBitableAdvancedPermissions {
                self.openBitableCollaboratorInviteViewController()
            } else if self.viewModel.inviteModeConfig.mode == .sendLink {
                self.handleSendLinkInvite()
            } else if self.viewModel.inviteModeConfig.mode == .askOwner {
                self.handleAskOwnerInvite()
            } else {
                self.openCollaboratorInviteViewController()
            }
        }
    }

    func openBitableCollaboratorInviteViewController() {
        resignSearchTextField { [weak self] in
            guard let self = self else { return }
            let inviteVM = CollaboratorInviteVCDependency(fileModel: self.viewModel.fileModel,
                                                       items: self.viewModel.selectedItems,
                                                       layoutConfig: self.viewModel.inviteModeConfig,
                                                       needShowOptionBar: true,
                                                       source: self.uiConfig.source,
                                                       statistics: self.dependency.statistics,
                                                       permStatistics: self.dependency.permStatistics,
                                                       userPermisson: self.viewModel.userPermissions,
                                                       bitablePermissonRule: self.viewModel.bitablePermissonRule)
            let vc = BitableCollaboratorInviteViewController(vm: inviteVM)
            vc.watermarkConfig.needAddWatermark = self.watermarkConfig.needAddWatermark
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
            self.dependency.statistics?.clickCollaborateInviterNextStep(tenantParams: CollaboratorStatistics.getTenantParams(ownerId: self.viewModel.fileModel.ownerID))
        }
    }

    func openCollaboratorInviteViewController() {
        resignSearchTextField { [weak self] in
            guard let self = self else { return }
            let inviteVM = CollaboratorInviteVCDependency(fileModel: self.viewModel.fileModel,
                                                       items: self.viewModel.selectedItems,
                                                       layoutConfig: self.viewModel.inviteModeConfig,
                                                       needShowOptionBar: true,
                                                       source: self.uiConfig.source,
                                                       statistics: self.dependency.statistics,
                                                       permStatistics: self.dependency.permStatistics,
                                                       userPermisson: self.viewModel.userPermissions)
            let vc = CollaboratorInviteViewController(vm: inviteVM)
            vc.watermarkConfig.needAddWatermark = self.watermarkConfig.needAddWatermark
            vc.delegate = self
            vc.organizationDelegate = self
            vc.supportOrientations = self.supportedInterfaceOrientations
            self.navigationController?.pushViewController(vc, animated: SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape ? false: true)
            self.dependency.statistics?.clickCollaborateInviterNextStep(tenantParams: CollaboratorStatistics.getTenantParams(ownerId: self.viewModel.fileModel.ownerID))
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
}

// 跳转
extension CollaboratorSearchViewController {
    // 跳转到选择组织架构
    func openOrganizationSelectionVC() {
        dependency.permStatistics?.reportPermissionAddCollaboratorClick(click: .organization, target: .permissionOrganizationAuthorizeView)
        resignSearchTextField { [weak self] in
            guard let self = self else { return }
            let vc = OrganizationSearchViewController(existedCollaborators: self.viewModel.existedCollaborators,
                                                      selectedItems: self.viewModel.selectedItems,
                                                      fileModel: self.fileModel,
                                                      statistics: self.dependency.statistics,
                                                      permStatistics: self.dependency.permStatistics,
                                                      userPermissions: self.viewModel.userPermissions,
                                                      publicPermisson: self.viewModel.publicPermisson,
                                                      source: self.uiConfig.source,
                                                      isBitableAdvancedPermissions: self.viewModel.isBitableAdvancedPermissions,
                                                      bitablePermissonRule: self.viewModel.bitablePermissonRule,
                                                      isEmailSharingEnabled: self.viewModel.isEmailSharingEnabled)
            vc.delegate = self
            vc.organizationNotifyDelegate = self
            vc.followAPIDelegate = self.followAPIDelegate
            vc.supportOrientations = self.supportedInterfaceOrientations
            let animated = UIApplication.shared.statusBarOrientation.isPortrait || SKDisplay.pad
            self.navigationController?.pushViewController(vc, animated: animated)
        }
    }

    func openUserGroupSelectionVC(groups: [Collaborator]) {
        dependency.permStatistics?.reportPermissionAddCollaboratorClick(click: .userGroup, target: .permissionDynamicUserGroupAuthorizeView)
        resignSearchTextField { [weak self] in
            guard let self = self else { return }
            let shouldCheckIsExisted = self.uiConfig.source == .diyTemplate || self.fileModel.spaceSingleContainer
            let viewModel = UserGroupSearchViewModel(userGroups: groups,
                                                     existedCollaborators: self.viewModel.existedCollaborators,
                                                     selectedCollaborators: self.viewModel.selectedItems,
                                                     fileModel: self.viewModel.fileModel,
                                                     userPermission: self.viewModel.userPermissions,
                                                     publicPermission: self.viewModel.publicPermisson,
                                                     shouldCheckIsExisted: shouldCheckIsExisted,
                                                     isBitableAdvancedPermissions: self.viewModel.isBitableAdvancedPermissions,
                                                     bitablePermissionRule: self.viewModel.bitablePermissonRule,
                                                     isEmailSharingEnabled: self.viewModel.isEmailSharingEnabled)
            let controller = UserGroupSearchViewController(viewModel: viewModel,
                                                           statistics: self.dependency.statistics,
                                                           permStatistics: self.dependency.permStatistics,
                                                           source: self.uiConfig.source)
            controller.delegate = self
            controller.followAPIDelegate = self.followAPIDelegate
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension CollaboratorSearchViewController: UDTextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignSearchTextField()
        return true
    }
}

// MARK: - CollaboratorAvatarBar
extension CollaboratorSearchViewController: CollaboratorAvatarBarDelegate {
    func avatarBar(_ bar: CollaboratorAvatarBar, didSelectAt index: Int) {
        guard index >= 0, index < viewModel.selectedItems.count else { return }
        let item = viewModel.selectedItems[index]
        // 点击头像去掉选择的
        if let index = viewModel.selectedItems.firstIndex(where: { $0.userID == item.userID }) {
            viewModel.selectedItems.remove(at: index)
            updateAvatarBar()
            updatePickerToolBar()
            updateSearchResultView()
        } else {
            DocsLogger.error("out of range")
        }
    }
}

// MARK: - TextField Action
extension CollaboratorSearchViewController {

    func updateInvitationTableViewIfNeed(isShow: Bool) {
        guard viewModel.shouldShowInvitationTableView || searchTextField.text?.isEmpty == false else { return }
        UIView.animate(withDuration: 0.25) {
            self.collaboratorSearchTableView.snp.remakeConstraints { (make) in
                if isShow {
                    make.top.lessThanOrEqualTo(self.bottomSeperatorView.snp.bottom)
                } else {
                    make.top.equalTo(self.avatarBar.snp.bottom).offset(12)
                }
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.pickerToolBar.snp.top).offset(-0.5)
            }
            self.view.layoutIfNeeded()
        }
    }

    @objc
    private func searchTextfieldAction(query: String) {
        guard query != currentQuery else { return }
        currentQuery = query
        if query.isEmpty {
            updateInvitationTableViewIfNeed(isShow: true)
        } else {
            // 搜索状态
            updateInvitationTableViewIfNeed(isShow: false)
        }
        search(query: query)
    }

    @objc
    private func searchTextFieldBeginEdting(sender: UITextField) {
        dependency.permStatistics?.reportPermissionAddCollaboratorClick(click: .search, target: .noneTargetView)
        dependency.statistics?.clickedInvitingSearchBar(tenantParams: CollaboratorStatistics.getTenantParams(ownerId: fileModel.ownerID))
    }
}

extension CollaboratorSearchViewController: OrganizationSearchViewControllerDelegate {

    func collaboratorUpdated(_ viewController: OrganizationSearchViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedItems = items
        updateCollaboratorPermissions(viewModel.selectedItems)
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }

    func collaboratorAdded(_ viewController: OrganizationSearchViewController, addedItem: Collaborator) {
        viewModel.selectedItems.append(addedItem)
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }

    func collaboratorRemoved(_ viewController: OrganizationSearchViewController, removedItem: Collaborator) {
        guard let firstIndex = viewModel.selectedItems.firstIndex(where: { (collaborator) -> Bool in
            return collaborator.userID == removedItem.userID
        }) else { return }
        viewModel.selectedItems.remove(at: firstIndex)
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }
}

extension CollaboratorSearchViewController: UserGroupSearchViewControllerDelegate {
    func collaboratorUpdated(_ viewController: UserGroupSearchViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedItems = items
        updateCollaboratorPermissions(viewModel.selectedItems)
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }
    func collaboratorAdded(_ viewController: UserGroupSearchViewController, addedItem: Collaborator) {
        viewModel.selectedItems.append(addedItem)
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }
    func collaboratorRemoved(_ viewController: UserGroupSearchViewController, removedItem: Collaborator) {
        guard let firstIndex = viewModel.selectedItems.firstIndex(where: { (collaborator) -> Bool in
            return collaborator.userID == removedItem.userID
        }) else { return }
        viewModel.selectedItems.remove(at: firstIndex)
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }
}

extension CollaboratorSearchViewController: BitableCollaboratorInviteViewControllerDelegate {
    func collaboardInvite(_ collaboardInvite: BitableCollaboratorInviteViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedItems = items
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }
}

extension CollaboratorSearchViewController: CollaboratorInviteViewControllerDelegate {

    func collaboardInvite(_ collaboardInvite: CollaboratorInviteViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedItems = items
        updateAvatarBar()
        updatePickerToolBar()
        updateSearchResultView()
    }

    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?) {
        collaboratorSearchVCDelegate?.dissmissSharePanel(animated: animated, completion: completion)
    }
}

extension CollaboratorSearchViewController: OrganizationInviteNotifyDelegate {
    func dismissSharePanelAndNotify(completion: (() -> Void)?) {
        organizationNotifyDelegate?.dismissSharePanelAndNotify(completion: completion)
    }
    func dismissInviteCompletion(completion: (() -> Void)?) {
        organizationNotifyDelegate?.dismissInviteCompletion(completion: completion)
    }
}

extension CollaboratorSearchViewController: CollaboratorSearchResultViewDelegate {
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

    func collaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {
        handleInviteCore(invitedItem: invitedItem)
        // 埋点上报
        dependency.statistics?.clickShareSearchResult(memberId: invitedItem.userID,
                                                      relationType: invitedItem.isFriend ?? false)
    }

    private func handleSendLinkInvite() {
        self.openCollaboratorInviteViewController()
    }

    private func handleAskOwnerInvite() {
        self.openCollaboratorInviteViewController()
    }

    private func handleInviteCore(invitedItem: Collaborator) {
        viewModel.selectedItems.append(invitedItem)
        updateCollaboratorPermissions([invitedItem])
        updateAvatarBar()
        updatePickerToolBar()
    }

    func collaboratorRemoved(_ view: CollaboratorSearchResultView, removedItem: Collaborator) {
        guard let index = viewModel.selectedItems.firstIndex(where: { (collaborator) -> Bool in
            return collaborator.userID == removedItem.userID
        }) else { return }
        viewModel.selectedItems.remove(at: index)
        updateAvatarBar()
        updatePickerToolBar()
    }

    func collaboratorSearched(_ view: CollaboratorSearchResultView, didUpdateWithSearchResults searchResults: [Collaborator]?) {
        loadingView.isHidden = true
        if uiConfig.needActivateKeyboard {
            DispatchQueue.main.async(execute: {
                if !self.searchTextField.inputField.isFirstResponder && self.firstActiveKeyboard {
                    self.firstActiveKeyboard = false
                    self.searchTextField.inputField.becomeFirstResponder()
                }
            })
        }
    }

    func blockedCollaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {
        switch invitedItem.blockStatus {
        case .none, .blockedByCac:
            return
        case .blockThisUser:
            self.showToast(text: BundleI18n.SKResource.Doc_Permission_BlockUnableInviteCollaboratorToast(invitedItem.name), type: .failure)
            dependency.statistics?.clientAuthError(reason: .block, location: .invitedCollaborateBefore)
        case .blockedByThisUser:
            self.showToast(text: BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToInvite_Toast, type: .failure)
            dependency.statistics?.clientAuthError(reason: .blocked, location: .invitedCollaborateBefore)
        case .privacySetting:
            self.showToast(text: BundleI18n.SKResource.Doc_Permission_SettingInviteCollaboratorShareToast(invitedItem.name), type: .failure)
            dependency.statistics?.clientAuthError(reason: .privacySetting, location: .invitedCollaborateBefore)
        }
    }
    
    func blockedEmailCollaborator(_ message: String) {
        showToast(text: message, type: .tips)
    }
}

extension CollaboratorSearchViewController {

    func updateCollaboratorPermissions(_ selectedItems: [Collaborator]) {
        for item in selectedItems {
            CollaboratorUtils.setupSelectItemPermission(currentItem: item,
                                                        objToken: fileModel.objToken,
                                                        docsType: fileModel.docsType,
                                                        userPermissions: viewModel.userPermissions)
            dependency.statistics?.clickSelectPermInviter(groupType: searchTextField.text?.isEmpty == false ? .search : .recent,
                                                          userType: item.type == .user ? .user : .chat,
                                                          tenantParams: CollaboratorStatistics.getTenantParams(ownerId: fileModel.ownerID),
                                                          collaboratorParams: CollaboratorStatistics.getCollaboratorParams(tenantId: item.tenantID))
        }
    }
}

extension CollaboratorSearchViewController: CollaboratorSearchResultScrollViewDelegate {

    public func willBeginDragging(_ scrollView: UIScrollView) {
        // 滚动时收起键盘
        resignSearchTextField()
    }
}

extension CollaboratorSearchViewController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.invitationDatas.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? CollaboratorInvitationCell else {
            return UITableViewCell()
        }
        let row = indexPath.row
        guard row >= 0, row < viewModel.invitationDatas.count else { return UITableViewCell() }
        cell.update(with: viewModel.invitationDatas[row])
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        let row = indexPath.row
        guard row >= 0, row < viewModel.invitationDatas.count else { return }
        let data = viewModel.invitationDatas[row]
        switch data.cellType {
        case .organization:
            openOrganizationSelectionVC()
        case .userGroup:
            openUserGroupSelectionVC(groups: viewModel.visibleUserGroups)
        }
    }
}

extension CollaboratorSearchViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        handleTitleLabelClicked()
        return false
    }

    func handleTitleLabelClicked() {
        if fileModel.ownerID.isEmpty {
            DocsLogger.info("userId is nil")
            return
        }
        let userID = fileModel.ownerID
        self.alertController?.dismiss(animated: true) {
            let params = ["type": self.fileModel.docsType.rawValue]
            HostAppBridge.shared.call(ShowUserProfileService(userId: userID, fileName: self.fileModel.displayName, fromVC: self, params: params))
        }
        self.alertController = nil
    }
}

extension CollaboratorSearchViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? self.view) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
