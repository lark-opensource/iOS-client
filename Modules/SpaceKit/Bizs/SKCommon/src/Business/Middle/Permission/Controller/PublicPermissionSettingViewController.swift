//
//  PublicPermissionSettingViewController.swift
//  Collaborator
//
//  Created by Da Lei on 2018/4/10.
//
// swiftlint:disable file_length line_length

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import UniverseDesignDialog
import SKInfra

extension WoCanManageCollaboratorsByPermission {
    var permSetOption: PermissionSettingOption {
        switch self {
        case .fullAccess:
            return .fullAccess
        case .edit:
            return .edit
        case .read:
            return .read
        }
    }
    var clickValue: PermissionSettingPageClickAction {
        switch self {
        case .fullAccess:
            return .chooseFullAccess
        case .edit:
            return .chooseEdit
        case .read:
            return .chooseRead
        }
    }
}

extension CommentEntity {
    var permSetOption: PermissionSettingOption {
        switch self {
        case .userCanEdit:
            return .edit
        case .userCanRead:
            return .read
        }
    }
    var clickValue: PermissionSettingPageClickAction {
        switch self {
        case .userCanEdit:
            return .chooseEdit
        case .userCanRead:
            return .chooseRead
        }
    }
}

extension CopyEntity {
    var permSetOption: PermissionSettingOption {
        switch self {
        case .onlyMe:
            return .fullAccess
        case .userCanEdit:
            return .edit
        case .userCanRead:
            return .read
        }
    }
    var clickValue: PermissionSettingPageClickAction {
        switch self {
        case .onlyMe:
            return .chooseFullAccess
        case .userCanEdit:
            return .chooseEdit
        case .userCanRead:
            return .chooseRead
        }
    }
}

extension SecurityEntity {
    var permSetOption: PermissionSettingOption {
        switch self {
        case .onlyMe:
            return .fullAccess
        case .userCanEdit:
            return .edit
        case .userCanRead:
            return .read
        }
    }
    var clickValue: PermissionSettingPageClickAction {
        switch self {
        case .onlyMe:
            return .chooseFullAccess
        case .userCanEdit:
            return .chooseEdit
        case .userCanRead:
            return .chooseRead
        }
    }
}

extension ShowCollaboratorInfoEntity {
    var permSetOption: PermissionSettingOption {
        switch self {
        case .userCanManager:
            return .fullAccess
        case .userCanEdit:
            return .edit
        case .userCanRead:
            return .read
        }
    }
    var clickValue: PermissionSettingPageClickAction {
        switch self {
        case .userCanManager:
            return .chooseFullAccess
        case .userCanEdit:
            return .chooseEdit
        case .userCanRead:
            return .chooseRead
        }
    }
}

public struct PublicPermissionSettingItem {
    enum ItemType {
        case checkBox
        case powerSwitch
    }
    let title: String
    let entityValue: Int
    var isSelected: Bool = false  //checkBox的样式下有效
    var accessSwitch: Bool = false //powerSwitch样式下有效
    var isGray: Bool = false
    let type: ItemType
    init(title: String, entityValue: Int, isSelected: Bool, type: ItemType, isGray: Bool) {
        self.title = title
        self.entityValue = entityValue
        self.isSelected = isSelected
        self.type = type
        self.isGray = isGray
    }
    init(title: String, entityValue: Int, accessSwitch: Bool, type: ItemType, isGray: Bool) {
        self.title = title
        self.entityValue = entityValue
        self.accessSwitch = accessSwitch
        self.type = type
        self.isGray = isGray
    }
}

public enum PublicPermissionSettingSectionType: Int {
    case shareExternal   //分享设置/谁可以邀请协作者-组织维度
    case manageCollaborator //分享设置/谁可以邀请协作者-权限维度
    case security  //安全设置
    case comment  //评论设置
    case showCollaboratorInfo  //显示协作者信息设置
    case copy   //谁可以复制内容

    public init(_ value: Int) {
        self = PublicPermissionSettingSectionType(rawValue: value) ?? .manageCollaborator
    }

    var requestJSONKey: String {
        switch self {
        case .shareExternal:
            return "share_entity"
        case .comment:
            return "comment_entity"
        case .manageCollaborator:
            return "manage_collaborator_entity"
        case .security:
            return "security_entity"
        case .showCollaboratorInfo:
            return "show_collaborator_info_entity"
        case .copy:
            return "copy_entity"
        }
    }
}


public final class PublicPermissionSettingSection {
    var type: PublicPermissionSettingSectionType
    var models: [PublicPermissionSettingItem]

    init(type: PublicPermissionSettingSectionType,
         models: [PublicPermissionSettingItem]) {
        self.type = type
        self.models = models
    }
}

/// 当前页面有3种情况
/// 1. 添加协作者设置
/// 2. 安全（创建副本、打印、导出、复制）
/// 4. 评论（哪些人可以评论文档）
public final class PublicPermissionSettingViewController: BaseViewController {
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    private var permStatistics: PermissionStatistics?
    private let fileModel: PublicPermissionFileModel
    private var publicPermissionMeta: PublicPermissionMeta
    private var publicPermissionSettingType: PublicPermissionCellModelType
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private var updateRequest: DocsRequest<JSON>?
    private var checkLockPermission: DocsRequest<JSON>?
    private var data = [PublicPermissionSettingSection]()
    private var userIsToC: Bool {
        return (User.current.info?.isToNewC == true)
    }
    private var publicPermissonUpdated: ((PublicPermissionMeta) -> Void)
    private let navTitle: String

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.ud.commonTableSeparatorColor
        tableView.register(PublicPermissionSettingCell.self,
                           forCellReuseIdentifier: PublicPermissionSettingCell.reuseIdentifier)
        tableView.register(PublicPermissionCellV2.self,
                           forCellReuseIdentifier: PublicPermissionCellV2.reuseIdentifier)
        tableView.estimatedRowHeight = 52
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UDColor.bgBase
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()

    // permStatistics report
    private var eventType: DocsTracker.EventType = .ccmPermissionAddCollaboratorSetClick
    private var permSetBefore: PermissionSettingOption = .read

    public init(fileModel: PublicPermissionFileModel,
                publicPermissionMeta: PublicPermissionMeta,
                publicPermissionSettingType: PublicPermissionCellModelType,
                publicPermissonUpdated: @escaping ((PublicPermissionMeta) -> Void),
                permStatistics: PermissionStatistics?,
                navTitle: String) {
        self.fileModel = fileModel
        self.permStatistics = permStatistics
        self.publicPermissionMeta = publicPermissionMeta
        self.publicPermissonUpdated = publicPermissonUpdated
        self.publicPermissionSettingType = publicPermissionSettingType
        self.navTitle = navTitle
        super.init(nibName: nil, bundle: nil)
        self.reloadDataSource()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    ///初始化数据 model
    private func reloadDataSource() {
        switch publicPermissionSettingType {
        case .manageCollaborator:
            reloadDataSourceForManageCollaborator()
        case .security:
            reloadDataSourceForSecurity()
        case .comment:
            reloadDataSourceForComment()
        case .showCollaboratorInfo:
            reloadDataSourceForCollaboratorInfo()
        case .copy:
            reloadDataSourceForCopy()
        default:
            break
        }
    }

    private func reloadDataSourceForManageCollaborator() {
        permSetBefore = publicPermissionMeta.woCanManageCollaboratorsByPermission.permSetOption
        var sections: [PublicPermissionSettingSection] = []
        let fullAccessItem = PublicPermissionSettingItem(title: fileModel.isV2Node ? PermissonCopywriting.fullAccessCollaboratorText : PermissonCopywriting.onlyMeText,
                                                          entityValue: WoCanManageCollaboratorsByPermission.fullAccess.rawValue,
                                                          isSelected: publicPermissionMeta.woCanManageCollaboratorsByPermission.rawValue == WoCanManageCollaboratorsByPermission.fullAccess.rawValue,
                                                          type: .checkBox,
                                                          isGray: publicPermissionMeta.blockOptions?.woCanManageCollaboratorsByPermission(with: .fullAccess) != BlockOptions.BlockType.none)
        let editItem = PublicPermissionSettingItem(title: PermissonCopywriting.editCollaboratorText,
                                                    entityValue: WoCanManageCollaboratorsByPermission.edit.rawValue,
                                                    isSelected: publicPermissionMeta.woCanManageCollaboratorsByPermission.rawValue == WoCanManageCollaboratorsByPermission.edit.rawValue,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.woCanManageCollaboratorsByPermission(with: .edit) != BlockOptions.BlockType.none)
        let readItem = PublicPermissionSettingItem(title: PermissonCopywriting.viewCollaboratorText,
                                                    entityValue: WoCanManageCollaboratorsByPermission.read.rawValue,
                                                    isSelected: publicPermissionMeta.woCanManageCollaboratorsByPermission.rawValue == WoCanManageCollaboratorsByPermission.read.rawValue,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.woCanManageCollaboratorsByPermission(with: .read) != BlockOptions.BlockType.none)
        let items: [PublicPermissionSettingItem] = [readItem, editItem, fullAccessItem]
        let firstSection = PublicPermissionSettingSection(type: .manageCollaborator, models: items)
        sections.append(firstSection)

        let onlyTenantCanInviteItem = PublicPermissionSettingItem(title: PermissonCopywriting.onlyTenatCanAddCollaboratorText,
                                                                  entityValue: publicPermissionMeta.woCanManageCollaboratorsByOrganization.rawValue,
                                                                  accessSwitch: publicPermissionMeta.woCanManageCollaboratorsByOrganization == .sameTenant,
                                                                  type: .powerSwitch,
                                                                  isGray: publicPermissionMeta.blockOptions?.woCanManageCollaboratorsByOrganization(with:
                                                                                                                                                        (publicPermissionMeta.woCanManageCollaboratorsByOrganization == .sameTenant) ? .anyone : .sameTenant) != BlockOptions.BlockType.none)
        let onlyTenantCanInviteSection = PublicPermissionSettingSection(type: .shareExternal, models: [onlyTenantCanInviteItem])

        //1.0文档协作者设置切换到只有我，隐藏仅组织内可以添加协作者
        let hideTenantCanInviteCollaborators = !fileModel.isV2Node && fullAccessItem.isSelected

        if canShowOnlyTenantCanInviteCollaborators(), !hideTenantCanInviteCollaborators {
            sections.append(onlyTenantCanInviteSection)
        }

        data = sections
    }
    
    private func reloadDataSourceForCollaboratorInfo() {
        permSetBefore = publicPermissionMeta.showCollaboratorInfoEntity.permSetOption
        let readItem = PublicPermissionSettingItem(title: PermissonCopywriting.viewUserText,
                                                         entityValue: ShowCollaboratorInfoEntity.userCanRead.rawValue,
                                                         isSelected: publicPermissionMeta.showCollaboratorInfoEntity == .userCanRead,
                                                         type: .checkBox,
                                                         isGray: publicPermissionMeta.blockOptions?.showCollabortorInfo(with: .read) != BlockOptions.BlockType.none)
        let editItem = PublicPermissionSettingItem(title: PermissonCopywriting.editUserText,
                                                    entityValue: ShowCollaboratorInfoEntity.userCanEdit.rawValue,
                                                   isSelected: publicPermissionMeta.showCollaboratorInfoEntity == .userCanEdit,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.showCollabortorInfo(with: .edit) != BlockOptions.BlockType.none)
        let fullAccessItem = PublicPermissionSettingItem(title: fileModel.isV2Node ? PermissonCopywriting.fullAccessUserText : PermissonCopywriting.onlyMeText,
                                                    entityValue: ShowCollaboratorInfoEntity.userCanManager.rawValue,
                                                         isSelected: publicPermissionMeta.showCollaboratorInfoEntity == .userCanManager,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.showCollabortorInfo(with: .fullAccess) != BlockOptions.BlockType.none)
        let items: [PublicPermissionSettingItem] = [readItem, editItem, fullAccessItem]
        let firstSection = PublicPermissionSettingSection(type: .showCollaboratorInfo, models: items)
        data = [firstSection]
    }
    
    private func reloadDataSourceForCopy() {
        permSetBefore = publicPermissionMeta.copyEntity.permSetOption
        let readItem = PublicPermissionSettingItem(title: PermissonCopywriting.viewUserText,
                                                         entityValue: CopyEntity.userCanRead.rawValue + 1,
                                                         isSelected: publicPermissionMeta.copyEntity.rawValue == CopyEntity.userCanRead.rawValue,
                                                         type: .checkBox,
                                                         isGray: publicPermissionMeta.blockOptions?.copy(with: .read) != BlockOptions.BlockType.none)
        let editItem = PublicPermissionSettingItem(title: PermissonCopywriting.editUserText,
                                                    entityValue: CopyEntity.userCanEdit.rawValue + 1,
                                                    isSelected: publicPermissionMeta.copyEntity.rawValue == CopyEntity.userCanEdit.rawValue,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.copy(with: .edit) != BlockOptions.BlockType.none)
        let fullAccessItem = PublicPermissionSettingItem(title: fileModel.isV2Node ? PermissonCopywriting.fullAccessUserText : PermissonCopywriting.onlyMeText,
                                                    entityValue: CopyEntity.onlyMe.rawValue + 1,
                                                    isSelected: publicPermissionMeta.copyEntity.rawValue == CopyEntity.onlyMe.rawValue,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.copy(with: .fullAccess) != BlockOptions.BlockType.none)
        let items: [PublicPermissionSettingItem] = [readItem, editItem, fullAccessItem]
        let firstSection = PublicPermissionSettingSection(type: .copy, models: items)
        data = [firstSection]
    }

    private func reloadDataSourceForSecurity() {
        permSetBefore = publicPermissionMeta.securityEntity.permSetOption
        let readItem = PublicPermissionSettingItem(title: PermissonCopywriting.viewUserText,
                                                         entityValue: SecurityEntity.userCanRead.rawValue + 1,
                                                         isSelected: publicPermissionMeta.securityEntity.rawValue == SecurityEntity.userCanRead.rawValue,
                                                         type: .checkBox,
                                                         isGray: publicPermissionMeta.blockOptions?.security(with: .read) != BlockOptions.BlockType.none)
        let editItem = PublicPermissionSettingItem(title: PermissonCopywriting.editUserText,
                                                    entityValue: SecurityEntity.userCanEdit.rawValue + 1,
                                                    isSelected: publicPermissionMeta.securityEntity.rawValue == SecurityEntity.userCanEdit.rawValue,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.security(with: .edit) != BlockOptions.BlockType.none)
        let fullAccessItem = PublicPermissionSettingItem(title: fileModel.isV2Node ? PermissonCopywriting.fullAccessUserText : PermissonCopywriting.onlyMeText,
                                                    entityValue: SecurityEntity.onlyMe.rawValue + 1,
                                                    isSelected: publicPermissionMeta.securityEntity.rawValue == SecurityEntity.onlyMe.rawValue,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.security(with: .fullAccess) != BlockOptions.BlockType.none)
        let items: [PublicPermissionSettingItem] = [readItem, editItem, fullAccessItem]
        let firstSection = PublicPermissionSettingSection(type: .security, models: items)
        data = [firstSection]
    }

    private func reloadDataSourceForComment() {
        permSetBefore = publicPermissionMeta.commentEntity.permSetOption
        let readItem = PublicPermissionSettingItem(title: PermissonCopywriting.viewUserText,
                                                          entityValue: CommentEntity.userCanRead.rawValue + 1,
                                                          isSelected: publicPermissionMeta.commentEntity.rawValue == CommentEntity.userCanRead.rawValue,
                                                          type: .checkBox,
                                                          isGray: publicPermissionMeta.blockOptions?.comment(with: .read) != BlockOptions.BlockType.none)
        let editItem = PublicPermissionSettingItem(title: PermissonCopywriting.editUserText,
                                                    entityValue: CommentEntity.userCanEdit.rawValue + 1,
                                                    isSelected: publicPermissionMeta.commentEntity.rawValue == CommentEntity.userCanEdit.rawValue,
                                                    type: .checkBox,
                                                    isGray: publicPermissionMeta.blockOptions?.comment(with: .edit) != BlockOptions.BlockType.none)
        let items: [PublicPermissionSettingItem] = [readItem, editItem]
        let firstSection = PublicPermissionSettingSection(type: .comment, models: items)

        data = [firstSection]
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        switch publicPermissionSettingType {
        case .manageCollaborator:
            permStatistics?.reportPermissionAddCollaboratorSetView()
            eventType = .ccmPermissionAddCollaboratorSetClick
        case .security:
            permStatistics?.reportPermissionFileSecuritySetView()
            eventType = .ccmPermissionFileSecuritySetClick
        case .comment:
            permStatistics?.reportPermissionFileCommentSetView()
            eventType = .ccmPermissionFileCommentSetClick
        case .showCollaboratorInfo:
            permStatistics?.reportPermissionCollaboratorProfileSetView()
            eventType = .ccmPermissionCollaboratorProfileListSetClick
        case .copy:
            permStatistics?.reportPermissionFileCopySetView()
            eventType = .ccmPermissionFileCopySetClick
        default: break
        }

        title = navTitle

        setupView()

        loadData()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name.Docs.RefreshPersonFile, object: nil)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    private func setupView() {
        view.backgroundColor = UDColor.bgBase
        navigationBar.customizeBarAppearance(backgroundColor: view.backgroundColor)
        statusBar.backgroundColor = view.backgroundColor
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    public override func backBarButtonItemAction() {
        permStatistics?.reportPermissionSetClick(event: eventType, click: .return, target: .permissionSetView)
        super.backBarButtonItemAction()
    }
    
    func loading(isBehindNavBar: Bool = false) {
        showLoading(isBehindNavBar: isBehindNavBar, backgroundAlpha: 0.05)
    }
    
    func startLoading() {
        UDToast.docs.showMessage(BundleI18n.SKResource.Doc_Facade_Loading, on: self.view, msgType: .loading)
    }

    func stopLoading() {
        UDToast.removeToast(on: self.view)
    }
}

// MARK: - data 相关
extension PublicPermissionSettingViewController {
    func loadData() {
        let token = fileModel.objToken
        let type = fileModel.type
        loadTenantPublicPermissionMeta(with: token, type: type)
    }

    //请求租户侧公共权限
    func loadTenantPublicPermissionMeta(with token: String, type: ShareDocsType) {
        let handler: (PublicPermissionMeta?, Error?) -> Void = { [weak self] (publicPermissionMeta, error) in
            guard let self = self else { return }
            guard let publicPermissionMeta = publicPermissionMeta else {
                self.stopLoading()
                DocsLogger.error("public permission view controller fetch public permission error", error: error, component: LogComponents.permission)
                return
            }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Normal_PermissionRequest + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                return
            }
            self.publicPermissionMeta = publicPermissionMeta
            self.publicPermissonUpdated(publicPermissionMeta)
            self.reloadDataSource()
            self.tableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                self.stopLoading()
            }
        }
        if fileModel.isFolder {
            permissionManager.requestV2FolderPublicPermissions(token: token, type: type.rawValue, complete: handler)
        } else {
            permissionManager.fetchPublicPermissions(token: token, type: type.rawValue, complete: handler)
        }
    }
}

extension PublicPermissionSettingViewController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].models.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let model = data[section].models[row]
        switch model.type {
        case .checkBox:
            return dequeueCheckBoxCell(tableView, cellForItemAt: indexPath)
        case .powerSwitch:
            return dequeuePowerSwitchCell(tableView, cellForItemAt: indexPath)
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let section = indexPath.section
        let row = indexPath.row
        guard section >= 0, section < data.count else { return }
        let sectionModel = data[section]
        let model = sectionModel.models[row]
        guard model.type == .checkBox, !model.isSelected else {
            return
        }

        /// blockOption判断
        if self.checkBlockOption(indexPath: indexPath) {
            /// Security only me 判断
            showOnlyMeAlert(indexPath: indexPath) {
                self.didChangePublicPermission(selectedSectionData: self.data[section], selectedIndex: row)
            }
        }
    }


    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 12
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        return view
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        return view
    }


    private func dequeueCheckBoxCell(_ tableView: UITableView, cellForItemAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: PublicPermissionSettingCell.reuseIdentifier, for: indexPath)
        guard let cell = reusableCell as? PublicPermissionSettingCell else {
            return reusableCell
        }
        guard section < data.count, row < data[section].models.count else {
            return reusableCell
        }
        let rows = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
        let model = data[section].models[row]
        let cellModel = PublicPermissionSettingCellModel(title: model.title,
                                                         isSelected: model.isSelected,
                                                         isGray: model.isGray)
        cell.setModel(cellModel)
        return cell
    }

    private func dequeuePowerSwitchCell(_ tableView: UITableView, cellForItemAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: PublicPermissionCellV2.reuseIdentifier, for: indexPath)
        guard let cell = reusableCell as? PublicPermissionCellV2 else {
            return reusableCell
        }
        guard section < data.count, row < data[section].models.count else {
            return reusableCell
        }
        let rows = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))

        let sectionModel = data[section]
        let model = sectionModel.models[row]
        let cellModel = PublicPermissionCellV2Model(title: model.title,
                                                    type: .powerSwitch,
                                                    accessOn: model.accessSwitch,
                                                    showSinglePageTag: false,
                                                    disableArrow: false,
                                                    disablePowerSwitch: model.isGray,
                                                    accessoryItem: nil)
        cell.setModel(cellModel)
        cell.switchTap = { [weak self] isOn in
            self?.onlySameTenantCanInviteCollaboratorAccess(isOn: isOn)
        }
        cell.disableSwitchTap = { [weak self] in
            self?.onExternalDisableAccessSwitchTap(sectionModel: sectionModel)
        }
        return cell
    }

    private func canShowOnlyTenantCanInviteCollaborators() -> Bool {
        return !userIsToC
            && publicPermissionMeta.allowInviteExternalCollaborator
            && AdminPermissionManager.adminCanExternalShare()
    }

    private func checkBlockOption(indexPath: IndexPath) -> Bool {
        guard let blockOptions = publicPermissionMeta.blockOptions else {
            return true
        }
        guard indexPath.section < data.count else {
            return true
        }
        let sectionData = data[indexPath.section]
        let model = sectionData.models[indexPath.row]

        var blockType: BlockOptions.BlockType = .none
        switch sectionData.type {
        case .manageCollaborator:
            blockType = blockOptions.woCanManageCollaboratorsByPermission(with: model.entityValue)
        case .comment:
            blockType = blockOptions.comment(with: model.entityValue)
        case .security:
            blockType = blockOptions.security(with: model.entityValue)
        case .showCollaboratorInfo:
            blockType = blockOptions.showCollabortorInfo(with: model.entityValue)
        case .copy:
            blockType = blockOptions.copy(with: model.entityValue)
        default:
            break
        }
        if blockType != .none {
            showBlockToast(type: blockType)
            return false
        }
        return true
    }

    private func showBlockToast(type: BlockOptions.BlockType) {
        showToast(text: type.title(isWiki: fileModel.wikiV2SingleContainer), type: .tips)
    }
    
    // 安全设置 - 设置为"只有我"时弹框提示
    private func showOnlyMeAlert(indexPath: IndexPath, completion: (() -> Void)?) {
        guard indexPath.section < data.count else { return }
        let sectionData = data[indexPath.section]
        let model = sectionData.models[indexPath.row]
        guard sectionData.type == .copy, model.entityValue == CopyEntity.onlyMe.rawValue + 1 else {
            completion?()
            return
        }

        let title = fileModel.isV2Node ? BundleI18n.SKResource.CreationMobile_ECM_Permission_External_FullAccess_confirm : BundleI18n.SKResource.CreationMobile_ECM_Permission_External_OnlyMe_confirm
        var content: String
        switch fileModel.type {
        case .minutes:
            content = BundleI18n.SKResource.CreationMobile_Minutes_Perm_WhoCanDownload_ConfirmMe
        case .folder:
            content = BundleI18n.SKResource.CreationMobile_Docs_Folder_NoCopyConfirm
        default:
            content = BundleI18n.SKResource.CreationMobile_ECM_Permission_Paste_off
        }
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: {
            completion?()
        })
        present(dialog, animated: true, completion: nil)
    }

}

// MARK: - 网络请求
extension PublicPermissionSettingViewController {
    private func onlySameTenantCanInviteCollaboratorAccess(isOn: Bool) {
        if case .manageCollaborator = publicPermissionSettingType {
            permStatistics?.reportPermissionSetClick(event: .ccmPermissionAddCollaboratorSetClick,
                                                     click: .onlyInsideOrganizationSwitch,
                                                     permSetBefore: isOn ? .close : .open,
                                                     permSetAfter: isOn ? .open : .close,
                                                     target: .noneTargetView)
        }
        let params: [String: Any] = [PublicPermissionSettingSectionType.shareExternal.requestJSONKey: isOn ?
                                        WoCanManageCollaboratorsByOrganization.sameTenant.rawValue :
                                        WoCanManageCollaboratorsByOrganization.anyone.rawValue]
        self.updatePublicPermissionsCore(additionalParams: params)

    }

    func onExternalDisableAccessSwitchTap(sectionModel: PublicPermissionSettingSection) {
        if sectionModel.type == .shareExternal {
            let switchType: WoCanManageCollaboratorsByOrganization = (publicPermissionMeta.woCanManageCollaboratorsByOrganization == .sameTenant) ? .anyone : .sameTenant
            if let blockType = publicPermissionMeta.blockOptions?.woCanManageCollaboratorsByOrganization(with: switchType),
               blockType != .none {
                showToast(text: blockType.title(isWiki: fileModel.wikiV2SingleContainer), type: .tips)
            }
        }
    }

    private func didChangePublicPermission(selectedSectionData: PublicPermissionSettingSection, selectedIndex: Int) {
        var params: [String: Any] = [:]
        guard selectedIndex >= 0, selectedIndex < selectedSectionData.models.count else {
            DocsLogger.error("selectedIndex is out of bounds!")
            return
        }
        let model = selectedSectionData.models[selectedIndex]
        params[selectedSectionData.type.requestJSONKey] = model.entityValue
        updatePublicPermissionsCore(additionalParams: params)


        switch selectedSectionData.type {
        case .manageCollaborator:
            if let type = WoCanManageCollaboratorsByPermission(rawValue: model.entityValue) {
                permStatistics?.reportPermissionSetClick(event: .ccmPermissionAddCollaboratorSetClick,
                                                         click: type.clickValue,
                                                         permSetBefore: permSetBefore,
                                                         permSetAfter: type.permSetOption,
                                                         target: .noneTargetView)
            }
        case .comment:
            if let type = CommentEntity(rawValue: model.entityValue - 1) {
                permStatistics?.reportPermissionSetClick(event: .ccmPermissionFileCommentSetClick,
                                                         click: type.clickValue,
                                                         permSetBefore: permSetBefore,
                                                         permSetAfter: type.permSetOption,
                                                         target: .noneTargetView)
            }
        case .security:
            if let type = SecurityEntity(rawValue: model.entityValue - 1) {
                permStatistics?.reportPermissionSetClick(event: .ccmPermissionFileSecuritySetClick,
                                                         click: type.clickValue,
                                                         permSetBefore: permSetBefore,
                                                         permSetAfter: type.permSetOption,
                                                         target: .noneTargetView)
            }
        case .showCollaboratorInfo:
            if let type = ShowCollaboratorInfoEntity(rawValue: model.entityValue) {
                permStatistics?.reportPermissionSetClick(event: .ccmPermissionCollaboratorProfileListSetClick,
                                                         click: type.clickValue,
                                                         permSetBefore: permSetBefore,
                                                         permSetAfter: type.permSetOption,
                                                         target: .noneTargetView)
            }
        case .copy:
            if let type = CopyEntity(rawValue: model.entityValue - 1) {
                permStatistics?.reportPermissionSetClick(event: .ccmPermissionFileCopySetClick,
                                                         click: type.clickValue,
                                                         permSetBefore: permSetBefore,
                                                         permSetAfter: type.permSetOption,
                                                         target: .noneTargetView)
            }
        default: ()
        }
    }

    private func updatePublicPermissionsCore(additionalParams: [String: Any]) {
        var params: [String: Any] = ["type": fileModel.type.rawValue, "token": fileModel.objToken]
        params.merge(other: additionalParams)
        self.startLoading()
        self.updatePermission(params) { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
            // 重新拉取公共权限
            self.loadData()
        }
    }

    private func updatePermission(_ params: [String: Any], callback: (() -> Void)?) {

        let complete: (JSON?, Error?) -> Void = { [weak self] (response, error) in
            guard let `self` = self else {
                return
            }
            if let err = error as? DocsNetworkError {
                self.stopLoading()
                if let message = err.code.errorMessage {
                    self.showToast(text: message, type: .failure)
                } else {
                    self.showToast(text: BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                }
                callback?()
                return
            }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Normal_PermissionModify + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                callback?()
                return
            }
            guard let response = response else {
                self.stopLoading()
                callback?()
                return
            }
            guard let code = response["code"].int else {
                self.stopLoading()
                DocsLogger.error("updatePermission failed!")
                callback?()
                return
            }
            guard code == 0 else {
                self.stopLoading()
                self.handleError(json: response, inputText: BundleI18n.SKResource.Doc_Facade_SetFailed)
                DocsLogger.error("updatePermission failed, error code is \(code)")
                callback?()
                return
            }
            callback?()
        }
        if fileModel.isFolder {
            self.updateRequest = PermissionManager.updateV2FolderPublicPermissions(token: fileModel.objToken, type: fileModel.type.rawValue, params: params, complete: { _, error, json in
                complete(json, error)
            })
        } else {
            self.updateRequest = PermissionManager.updateBizsPublicPermission(type: fileModel.type.rawValue, params: params, complete: complete)
        }
    }

    private func handleError(json: JSON?, inputText: String) {
        guard let json = json else {
            self.showToast(text: inputText, type: .failure)
            return
        }
        let code = json["code"].intValue
        if let errorCode = ExplorerErrorCode(rawValue: code) {
            let errorEntity = ErrorEntity(code: errorCode, folderName: "")
            self.showToast(text: errorEntity.wording, type: .failure)
        } else {
            self.showToast(text: inputText, type: .failure)
        }
    }
}

extension PublicPermissionSettingViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
