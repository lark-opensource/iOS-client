//
//  UserGroupSearchViewController.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/1/11.
// swiftlint:disable file_length

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import SnapKit
import SKResource
import SKFoundation
import SKUIKit
import EENavigator
import UniverseDesignEmpty
import UniverseDesignInput
import UniverseDesignColor
import UniverseDesignToast
import UIKit
import SpaceInterface

protocol UserGroupSearchViewControllerDelegate: AnyObject {
    func collaboratorUpdated(_ viewController: UserGroupSearchViewController, didUpdateWithItems items: [Collaborator])
    func collaboratorAdded(_ viewController: UserGroupSearchViewController, addedItem: Collaborator)
    func collaboratorRemoved(_ viewController: UserGroupSearchViewController, removedItem: Collaborator)
    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?)
}


class UserGroupSearchViewController: BaseViewController {
    private let viewModel: UserGroupSearchViewModel
    private var fileModel: CollaboratorFileModel { viewModel.fileModel }
    private let statistics: CollaboratorStatistics?
    private let permStatistics: PermissionStatistics?
    private let source: CollaboratorInviteSource

    weak var delegate: UserGroupSearchViewControllerDelegate?

    weak var followAPIDelegate: BrowserVCFollowDelegate?

    private var searchQuery = ""
    private let keyboard = Keyboard()
    private let disposeBag = DisposeBag()
    
    private lazy var loadingView: UIView = {
        let view = CollaboratorLoadingView(topOffset: 150)
        view.isHidden = true
        return view
    }()

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
    private lazy var separatorView: SeperatorView = {
        let separatorView = SeperatorView(frame: .zero)
        separatorView.backgroundColor = UDColor.bgBase
        return separatorView
    }()

    /// 用户组搜索的tableView
    private lazy var userGroupTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UDColor.bgBase
        tableView.rowHeight = 66
        tableView.register(UserGroupCell.self, forCellReuseIdentifier: UserGroupCell.reuseIdentifier)
        return tableView
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

    init(viewModel: UserGroupSearchViewModel,
         statistics: CollaboratorStatistics?,
         permStatistics: PermissionStatistics?,
         source: CollaboratorInviteSource) {
        self.viewModel = viewModel
        self.statistics = statistics
        self.permStatistics = permStatistics
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if fileModel.isForm {
            title = BundleI18n.SKResource.Bitable_Form_AddCollaborator
        } else if fileModel.isBitableSubShare {
            title = BundleI18n.SKResource.Bitable_Share_AddViewers_Title
        } else {
            title = BundleI18n.SKResource.CreationMobile_ECM_Add_UserGroup_Tab
        }
        setupUI()
        bindViewModel()
        setupToolBar()
        addKeyboardObserve()
        loadData()
        permStatistics?.reportPermissionUserGroupAuthorizeView()
        permStatistics?.reportAddUserGroupAuthorizeView()
    }

    private func loadData() {
        loadingView.isHidden = false
        viewModel.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboard.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboard.stop()
    }

    override func backBarButtonItemAction() {
        permStatistics?.reportPermissionUserGroupAuthorizeClick(click: .back, target: .noneTargetView)
        super.backBarButtonItemAction()
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBody

        view.addSubview(searchTextField)
        searchTextField.backgroundColor = UDColor.bgBodyOverlay
        if viewModel.isEmailSharingEnabled {
            searchTextField.placeholder = BundleI18n.SKResource.LarkCCM_Docs_Share_SearchForEmailUserGroup_Placeholder
        } else {
            searchTextField.placeholder = BundleI18n.SKResource.LarkCCM_Workspace_Search_UserGroup_Placeholder
        }
        searchTextField.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }

        view.addSubview(avatarBar)
        avatarBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchTextField.snp.bottom).offset(12)
            make.height.equalTo(0)
        }
        updateAvatarBar()

        view.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(avatarBar.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(8)
        }

        view.addSubview(userGroupTableView)
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(separatorView.snp.bottom)
        }
        // 保证底部 ToolBar 在最顶层
        view.addSubview(pickerToolBar)

        pickerToolBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        userGroupTableView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(pickerToolBar.snp.top)
        }
    }

    private func setupToolBar() {
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in
            guard let self = self else { return }
            let selectedItems = self.viewModel.selectedCollaborators
            let userList: [[String: Any]] = Array(selectedItems).map {
                return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                        "collaborate_type": $0.rawValue]
            }
            self.permStatistics?.reportPermissionUserGroupAuthorizeClick(click: .next, target: .permissionSelectContactView, userList: userList)
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

    // 更新 PickerToolBar
    private func updatePickerToolBar() {
        pickerToolBar.updateSelectedItem(firstSelectedItems: viewModel.selectedCollaborators, secondSelectedItems: [], updateResultButton: true)
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

    // 更新bar
    private func updateAvatarBar() {
        avatarBar.setImages(items: viewModel.selectedCollaborators.map { collaborator in
            var imageURL: String?
            var image: UIImage?
            if collaborator.type == .organization || collaborator.type == .ownerLeader {
                imageURL = nil
                image = BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32
            } else if collaborator.type == .userGroup || collaborator.type == .userGroupAssign {
                imageURL = nil
                image = BundleResources.SKResource.Common.Collaborator.icon_usergroup
            } else if collaborator.type == .email {
                imageURL = nil
                image = BundleResources.SKResource.Common.Collaborator.avatar_person
            } else {
                imageURL = collaborator.avatarURL
                image = nil
            }
            return AvatarBarItem(id: collaborator.userID, imageURL: imageURL, imageKey: collaborator.imageKey, image: image)
        }, complete: { [weak self] in
            guard let bar = self?.avatarBar else { return }
            // 滚动到最后
            bar.setContentOffset(CGPoint(x: max(0, bar.contentSize.width - bar.bounds.size.width), y: 0),
                                 animated: true)
        })
        avatarBar.snp.updateConstraints({ (make) in
            make.top.equalTo(searchTextField.snp.bottom).offset(viewModel.selectedCollaborators.isEmpty ? 0 : 12)
            make.height.equalTo(viewModel.selectedCollaborators.isEmpty ? 0 : 32)
        })
        view.layoutIfNeeded()
    }

    private func bindViewModel() {
        viewModel.stateChanged.emit(onNext: { [weak self] state in
            guard let self = self else { return }
            self.loadingView.isHidden = true
            self.handle(state: state)
        }).disposed(by: disposeBag)

        viewModel.itemUpdated.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.userGroupTableView.reloadData()
        }).disposed(by: disposeBag)
    }

    private func handle(state: UserGroupSearchViewModel.State) {
        switch state {
        case .success:
            break
        case .networkFailure, .emptyList:
            showToast(text: BundleI18n.SKResource.Doc_Facade_OperateFailed, type: .failure)
        }
    }

    private func updateUI() {
        updateAvatarBar()
        updatePickerToolBar()
        viewModel.updateData()
        collaboratorSearchTableView?.updateSelectItems(viewModel.selectedCollaborators)
    }

    @objc
    private func searchTextfieldAction(query: String) {
        guard query != searchQuery else { return }
        if !query.isEmpty {
            enterSearchMode(with: query)
        } else {
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

extension UserGroupSearchViewController: UDTextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}

extension UserGroupSearchViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 滚动时收起键盘
        resignSearchTextField()
    }
}

extension UserGroupSearchViewController: CollaboratorAvatarBarDelegate {
    func avatarBar(_ bar: CollaboratorAvatarBar, didSelectAt index: Int) {
        guard index >= 0, index < viewModel.selectedCollaborators.count else { return }
        let item = bar.items[index]
        // 点击头像去掉选择的
        if let index = viewModel.selectedCollaborators.firstIndex(where: { $0.userID == item.id }) {
            let deletedItem = viewModel.selectedCollaborators[index]
            // 通知delegate取消了选择
            delegate?.collaboratorRemoved(self, removedItem: deletedItem)
            viewModel.selectedCollaborators.remove(at: index)
            updateUI()
        } else {
            DocsLogger.error("out of range!")
        }
    }
}

extension UserGroupSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserGroupCell.reuseIdentifier, for: indexPath)
        guard let userGroupCell = cell as? UserGroupCell else {
            return cell
        }
        guard indexPath.row >= 0, indexPath.row < viewModel.items.count else {
            return cell
        }
        let model = viewModel.items[indexPath.row]
        userGroupCell.update(item: model)
        userGroupCell.backgroundColor = UDColor.bgBody
        return userGroupCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        // 更新数据源
        guard indexPath.row >= 0,
              indexPath.row < viewModel.items.count,
              indexPath.row < viewModel.userGroups.count
        else { return }
        let userGroup = viewModel.userGroups[indexPath.row]
        var cellItem = viewModel.items[indexPath.row]
        // Owner不可添加
        if cellItem.groupID == fileModel.ownerID {
            return
        }
        if cellItem.isExist {
            return
        }

        if cellItem.selectType == .disable {
            return
        } else if cellItem.selectType == .blue {
            cellItem.selectType = .gray
            if let index = viewModel.selectedCollaborators.firstIndex(where: { $0.userID == cellItem.groupID }) {
                let deletedItem = viewModel.selectedCollaborators[index]
                viewModel.selectedCollaborators.remove(at: index)
                delegate?.collaboratorRemoved(self, removedItem: deletedItem)
            }
        } else {
            cellItem.selectType = .blue
            viewModel.selectedCollaborators.append(userGroup)
            delegate?.collaboratorAdded(self, addedItem: userGroup)
        }
        updateAvatarBar()
        updatePickerToolBar()
        viewModel.updateData()
    }
}

extension UserGroupSearchViewController {
    private func enterSearchMode(with query: String) {
            let searchView: CollaboratorSearchResultView
            if let tableView = collaboratorSearchTableView {
                searchView = tableView
            } else {
                permStatistics?.reportPermissionUserGroupAuthorizeClick(click: .search, target: .permissionDynamicUserGroupAuthorizeSearchView)
                permStatistics?.reportPermissionUserGroupAuthorizeSearchView()
                let shouldCheckIsExist = viewModel.shouldCheckIsExisted

                var inviteExternalOption = CollaboratorSearchConfig.InviteExternalOption.all
                /// 对外分享关闭(非admin关闭)时,不允许用户选择
                let finalOption: CollaboratorSearchConfig.InviteExternalOption
                if let permissionMeta = viewModel.publicPermission {
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

                let config = CollaboratorSearchConfig(shouldSearchOrganization: CollaboratorUtils.addDepartmentEnable(source: source, docsType: self.fileModel.docsType),
                                                      shouldSearchUserGroup: true,
                                                      inviteExternalOption: inviteExternalOption)
                let viewModel = CollaboratorSearchTableViewModel(objToken: fileModel.objToken,
                                                                 docsType: fileModel.docsType,
                                                                 wikiV2SingleContainer: fileModel.wikiV2SingleContainer,
                                                                 spaceSingleContainer: fileModel.spaceSingleContainer,
                                                                 isBitableAdvancedPermissions: viewModel.isBitableAdvancedPermissions,
                                                                 ownerId: fileModel.ownerID,
                                                                 existedCollaborators: viewModel.getExistedCollaborators(),
                                                                 selectedItems: viewModel.selectedCollaborators,
                                                                 searchConfig: config,
                                                                 isEmailSharingEnabled: viewModel.isEmailSharingEnabled,
                                                                 canInviteEmailCollaborator: viewModel.userPermission?.isFA ?? false,
                                                                 adminCanInviteEmailCollaborator: AdminPermissionManager.adminCanExternalShare(),
                                                                 followAPIDelegate: followAPIDelegate)
                searchView = CollaboratorSearchResultView(viewModel: viewModel)
                collaboratorSearchTableView = searchView
                searchView.searchDelegate = self
                searchView.scrollDelegate = self
            }
            if searchView.superview == nil {
                view.addSubview(searchView)
                searchView.snp.makeConstraints { (make) in
                    make.top.equalTo(userGroupTableView.snp.top)
                    make.left.right.equalToSuperview()
                    make.bottom.equalTo(pickerToolBar.snp.top)
                }
            }
            view.bringSubviewToFront(loadingView)
            loadingView.isHidden = false
            searchView.search(query: query)
        }

        private func exitSearchMode() {
            guard let tableView = collaboratorSearchTableView else { return }
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

extension UserGroupSearchViewController {
    private func openCollaboratorInviteViewController() {
        let config = CollaboratorInviteModeConfig.config(with: viewModel.publicPermission,
                                                         userPermisson: viewModel.userPermission,
                                                         isBizDoc: viewModel.fileModel.docsType.isBizDoc)
        let inviteVM = CollaboratorInviteVCDependency(fileModel: viewModel.fileModel,
                                                   items: viewModel.selectedCollaborators,
                                                   layoutConfig: config,
                                                   needShowOptionBar: true,
                                                   source: source,
                                                   statistics: statistics,
                                                   permStatistics: permStatistics,
                                                   userPermisson: viewModel.userPermission)
        let vc = CollaboratorInviteViewController(vm: inviteVM)
        vc.delegate = self
        vc.watermarkConfig.needAddWatermark = watermarkConfig.needAddWatermark
        vc.supportOrientations = self.supportedInterfaceOrientations
        self.navigationController?.pushViewController(vc, animated: true)
        self.statistics?.clickCollaborateInviterNextStep(tenantParams: CollaboratorStatistics.getTenantParams(ownerId: self.fileModel.ownerID))
    }

    private func openBitableCollaboratorInviteViewController() {
        let config = CollaboratorInviteModeConfig.config(with: viewModel.publicPermission,
                                                         userPermisson: viewModel.userPermission,
                                                         isBizDoc: viewModel.fileModel.docsType.isBizDoc)
        let inviteVM = CollaboratorInviteVCDependency(fileModel: viewModel.fileModel,
                                                   items: viewModel.selectedCollaborators,
                                                   layoutConfig: config,
                                                   needShowOptionBar: true,
                                                   source: source,
                                                   statistics: statistics,
                                                   permStatistics: permStatistics,
                                                   userPermisson: viewModel.userPermission,
                                                   bitablePermissonRule: viewModel.bitablePermissionRule)
        let vc = BitableCollaboratorInviteViewController(vm: inviteVM)
        vc.watermarkConfig.needAddWatermark = self.watermarkConfig.needAddWatermark
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension UserGroupSearchViewController: BitableCollaboratorInviteViewControllerDelegate {
    func collaboardInvite(_ collaboardInvite: BitableCollaboratorInviteViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedCollaborators = items
        updateUI()
        delegate?.collaboratorUpdated(self, didUpdateWithItems: viewModel.selectedCollaborators)
    }
}

extension UserGroupSearchViewController: CollaboratorInviteViewControllerDelegate {

    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?) {
        delegate?.dissmissSharePanel(animated: animated, completion: completion)
    }

    func collaboardInvite(_ collaboardInvite: CollaboratorInviteViewController, didUpdateWithItems items: [Collaborator]) {
        viewModel.selectedCollaborators = items
        updateUI()
        delegate?.collaboratorUpdated(self, didUpdateWithItems: viewModel.selectedCollaborators)
    }
}

extension UserGroupSearchViewController: CollaboratorSearchResultViewDelegate {

    func collaboratorSearched(_ view: CollaboratorSearchResultView, didUpdateWithSearchResults searchResults: [Collaborator]?) {
        loadingView.isHidden = true
    }

    func collaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {
        loadingView.isHidden = true
        handleInviteCore(invitedItem: invitedItem)
    }

    func collaboratorRemoved(_ view: CollaboratorSearchResultView, removedItem: Collaborator) {
        loadingView.isHidden = true
        guard let index = viewModel.selectedCollaborators.firstIndex(where: { (collaborator) -> Bool in
            return collaborator.userID == removedItem.userID
        }) else { return }
        viewModel.selectedCollaborators.remove(at: index)
        updateUI()
    }

    func blockedCollaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {

    }

    func blockedExternalCollaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator) {
        if viewModel.publicPermission?.allowInviteExternalUserOnly == true && invitedItem.type != .user {
            if fileModel.isFolder {
                showToast(text: BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario8, type: .tips)
            } else {
                showToast(text: BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario5, type: .tips)
            }
            return
        }
        if fileModel.spaceSingleContainer || fileModel.wikiV2SingleContainer {
            if let reason = viewModel.publicPermission?.externalCollaboratorForbiddenReason(isFolder: fileModel.isFolder, isWiki: fileModel.wikiV2SingleContainer) {
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
        viewModel.selectedCollaborators.append(invitedItem)
        updateCollaboratorPermissions([invitedItem])
        updateUI()
    }

    func updateCollaboratorPermissions(_ selectedItems: [Collaborator]) {
        for item in selectedItems {
            CollaboratorUtils.setupSelectItemPermission(currentItem: item,
                                                        objToken: fileModel.objToken,
                                                        docsType: fileModel.docsType,
                                                        userPermissions: viewModel.userPermission)
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

extension UserGroupSearchViewController: CollaboratorSearchResultScrollViewDelegate {
    public func willBeginDragging(_ scrollView: UIScrollView) {
        // 滚动时收起键盘
        resignSearchTextField()
    }
}

extension UserGroupSearchViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? self.view) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
