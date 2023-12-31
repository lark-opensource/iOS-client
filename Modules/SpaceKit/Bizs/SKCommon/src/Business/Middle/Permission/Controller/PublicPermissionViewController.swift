//
//  PublicPermissionViewController.swift
//  Collaborator
//
//  Created by Da Lei on 2018/4/10.
//
// swiftlint:disable file_length

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import UniverseDesignDialog
import SpaceInterface
import SKInfra

public struct PublicPermissionFileModel {
    let objToken: String //这个值目前还有糊，待梳理 
    let wikiToken: String? // 如果是wiki,这里为wikiToken
    let type: ShareDocsType
    let fileType: String //drive文件后缀
    let ownerID: String
    let tenantID: String
    let createTime: TimeInterval
    let createDate: String
    let createID: String
    let wikiV2SingleContainer: Bool //wiki2.0
    let wikiType: DocsType? //wiki包含的内部文档类型
    let spaceSingleContainer: Bool
    public init(objToken: String,
                wikiToken: String?,
                type: ShareDocsType,
                fileType: String,
                ownerID: String,
                tenantID: String,
                createTime: TimeInterval,
                createDate: String,
                createID: String,
                wikiV2SingleContainer: Bool,
                wikiType: DocsType?,
                spaceSingleContainer: Bool) {
        self.objToken = objToken
        self.wikiToken = wikiToken
        self.type = type
        self.fileType = fileType
        self.ownerID = ownerID
        self.tenantID = tenantID
        self.createDate = createDate
        self.createTime = createTime
        self.createID = createID
        self.wikiV2SingleContainer = wikiV2SingleContainer
        self.spaceSingleContainer = spaceSingleContainer
        self.wikiType = wikiType
    }

    public var isV2Node: Bool {
        return wikiV2SingleContainer || spaceSingleContainer
    }
    public var isFolder: Bool {
        return type == .folder
    }
    public var isV2Folder: Bool {
        return isV2Node && isFolder
    }

    public var typeSupportSecurityLevel: Bool {
        if wikiV2SingleContainer {
            if let wikiType = wikiType {
                let array: [DocsType] = [.doc, .mindnote, .file, .docX, .bitable, .sheet]
                return array.contains(wikiType)
            }
            return false
        } else if spaceSingleContainer {
            let array: [ShareDocsType] = [.doc, .mindnote, .file, .docX, .bitable, .sheet]
            return array.contains(type)
        } else {
            return false
        }
    }
}

/// 权限设置页中一共有四个 section:
/// 1. 允许文档被分享到组织外的开关
/// 2. 评论（哪些人可以评论文档）
/// 3. 管理协作者（哪些人可以邀请哪些人成为协作者）
/// 4. 安全（创建副本、打印、导出、复制）
/// 上面四个 section 的配置状态，取决于 PublicPermissionMeta
public final class PublicPermissionViewController: BaseViewController {
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    private var permStatistics: PermissionStatistics?
    private let fileModel: PublicPermissionFileModel
    private let tracker: PublicPermissionTracker
    private var publicPermissionMeta: PublicPermissionMeta?
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private var publicRequest: DocsRequest<PublicPermissionMeta>?
    private var updateRequest: DocsRequest<JSON>?
    private var checkLockPermission: DocsRequest<JSON>?
    private var data = [PublicPermissionSectionData]()
    private var userIsToC: Bool {
        return (User.current.info?.isToNewC == true)
    }
    private let needCloseBarItem: Bool
    private let disposeBag = DisposeBag()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(PublicPermissionSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PublicPermissionSectionHeaderView.reuseIdentifier)
        collectionView.register(PublicPermissionCell.self, forCellWithReuseIdentifier: PublicPermissionCell.reuseIdentifier)
        collectionView.register(PermissionSwitchView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PermissionSwitchView.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    public init(fileModel: PublicPermissionFileModel, needCloseBarItem: Bool, permStatistics: PermissionStatistics?) {
        self.fileModel = fileModel
        self.permStatistics = permStatistics
        let fileModel = PublicPermissionTracker.FileModel(objToken: fileModel.objToken,
                                                          type: fileModel.type,
                                                          ownerID: fileModel.ownerID,
                                                          tenantID: fileModel.tenantID,
                                                          createTime: fileModel.createTime,
                                                          createDate: fileModel.createDate,
                                                          createID: fileModel.createID)
        self.tracker = PublicPermissionTracker(fileModel: fileModel)
        self.needCloseBarItem = needCloseBarItem
        super.init(nibName: nil, bundle: nil)
        self.initDataSource()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    ///初始化数据 model
    private func initDataSource() {
        /// 0. 对外分享 section，方便切换按钮作为SupplementaryView添加进来
        let blankSection = PublicPermissionSectionData(type: .crossTenant, title: "", models: [], selectedIndex: nil)
        /// 1. 评论 section model
        let settingCommentAllModel = PublicPermissionModel(title: BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_viewer_option,
                                                           entityValue: CommentEntity.userCanRead.rawValue)
        let settingCommentEditModel = PublicPermissionModel(title: BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_editor_option,
                                                            entityValue: CommentEntity.userCanEdit.rawValue)
        let commentList = [settingCommentAllModel, settingCommentEditModel]

        let commentSection = PublicPermissionSectionData(type: .comment,
                                                         title: BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_comment,
                                                         models: commentList, selectedIndex: nil)
        /// 2. 管理协作者 section model
        let shareAnyoneTitle = BundleI18n.SKResource.CreationMobile_ECM_AllCollaboratorButton
        let shareTenantAccessibleTitle = BundleI18n.SKResource.CreationMobile_ECM_OrganizationButton
        var shareOnlyICanTitle = BundleI18n.SKResource.CreationMobile_ECM_OnlyMeButton
        if fileModel.spaceSingleContainer || fileModel.wikiV2SingleContainer {
            shareOnlyICanTitle = BundleI18n.SKResource.CreationMobile_ECM_AllPermissionOnlyDesc
        }
        let settingShareAnyoneModel = PublicPermissionModel(title: shareAnyoneTitle,
                                                            entityValue: ShareEntity.anyone.rawValue)
        let settingShareTenantAccessibleModel = PublicPermissionModel(title: shareTenantAccessibleTitle,
                                                                      entityValue: ShareEntity.tenant.rawValue)
        let settingShareOnlyICanModel = PublicPermissionModel(title: shareOnlyICanTitle,
                                                              entityValue: ShareEntity.onlyMe.rawValue)
        var shareList: [PublicPermissionModel] = []
        if !fileModel.wikiV2SingleContainer {
            shareList.append(settingShareAnyoneModel)
            // C端用户不显示组织内
            if !userIsToC {
                shareList.append(settingShareTenantAccessibleModel)
            }
            shareList.append(settingShareOnlyICanModel)
        }
        let shareSection = PublicPermissionSectionData(type: .share,
                                                       title: BundleI18n.SKResource.Doc_Share_SettingShareTitle,
                                                       models: shareList, selectedIndex: nil)
        
        /// 3. 安全 section model
        let anyoneCanAccessCopyModel = PublicPermissionModel(title: BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_viewer_option, entityValue: SecurityEntity.userCanRead.rawValue)
        let peopleCanEditCopyModel = PublicPermissionModel(title: BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_editor_option, entityValue: SecurityEntity.userCanEdit.rawValue)
        let onlyMeOptionTitle = (fileModel.wikiV2SingleContainer || fileModel.spaceSingleContainer) ?
            BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_FA_option :
            BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_me_option
        let onlyMeOptionModel = PublicPermissionModel(title: onlyMeOptionTitle, entityValue: SecurityEntity.onlyMe.rawValue)
        var safeAuthorityList = [anyoneCanAccessCopyModel, peopleCanEditCopyModel]
        if fileModel.type == .minutes {
            safeAuthorityList.append(onlyMeOptionModel)
        } else {
            DocsLogger.info("noting to do ")
        }
        let title = (fileModel.type == .minutes) ? BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_question : BundleI18n.SKResource.CreationMobile_common_whocan
        let copySection = PublicPermissionSectionData(type: .security,
                                                      title: title,
                                                      models: safeAuthorityList, selectedIndex: nil)
        data = [blankSection, commentSection, shareSection, copySection]
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.SKResource.LarkCCM_Docs_PermissionSettings_Menu_Mob
        setupView()
        ///根据网络回调重新过滤一遍数据
        loadData()
        tracker.reportShowPermissionPage()
        permStatistics?.reportPermissionSetView(isNewSetMenu: false)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name.Docs.RefreshPersonFile, object: nil)
    }

    public override func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    public override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupView() {
        view.backgroundColor = UDColor.bgBase
        view.addSubview(collectionView)
        navigationBar.customizeBarAppearance(backgroundColor: view.backgroundColor)
        statusBar.backgroundColor = view.backgroundColor
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        }
        addCloseBarItemIfNeed()
    }
    
    private func addCloseBarItemIfNeed() {
        guard needCloseBarItem else { return }
        let closeButton = UIButton()
        closeButton.setImage(BundleResources.SKResource.Common.Collaborator.icon_close_outlinedV2.ud.withTintColor(UDColor.iconN1), for: .normal)
        closeButton.addTarget(self, action: #selector(didClickedCloseBarItem), for: .touchUpInside)
        closeButton.docs.addHighlight(with: UIEdgeInsets(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        backgroundView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let btnItem = SKBarButtonItem(customView: backgroundView)
        btnItem.id = .close
        self.navigationBar.leadingBarButtonItem = btnItem
    }

    @objc
    func didClickedCloseBarItem() {
        permStatistics?.reportPermissionSetClick(click: .back, target: .noneTargetView)
        dismiss(animated: true, completion: nil)
    }

    ///切换是否可以分享到组织外
    @objc
    func onExternalAccessSwitchClick(sw: UISwitch) {
//        publicPermissionMeta?.externalAccess = sw.isOn
        didChangeExternalAccess(isOn: sw.isOn)
        tracker.report(sw.isOn ? .outsideVisitSwtichOpen : .outsideVisitSwtichClose)
        permStatistics?.reportPermissionSetClick(click: .switch,
                                                 canCross: sw.isOn,
                                                 target: .noneTargetView)
    }
    
    public override func backBarButtonItemAction() {
        permStatistics?.reportPermissionSetClick(click: .back, target: .noneTargetView)
        super.backBarButtonItemAction()
    }
    func loading(isBehindNavBar: Bool = false) {
        showLoading(isBehindNavBar: isBehindNavBar, backgroundAlpha: 0.05)
    }
}

// MARK: - data 相关
extension PublicPermissionViewController {
    ///首次根据 publicv2 接口请求数据
    func loadData() {
        loading(isBehindNavBar: true)
        let token = fileModel.objToken
        let type = fileModel.type
        loadTenantPublicPermissionMeta(with: token, type: type)
    }

    //请求租户侧公共权限
    func loadTenantPublicPermissionMeta(with token: String, type: ShareDocsType) {
        let handler: (PublicPermissionMeta?, Error?) -> Void = { [weak self] (publicPermissionMeta, error) in
            guard let self = self else { return }
            self.hideLoading()
            guard let publicPermissionMeta = publicPermissionMeta else {
                DocsLogger.error("public permission view controller fetch public permission error", error: error, component: LogComponents.permission)
                return
            }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.showToast(text: BundleI18n.SKResource.Doc_Normal_PermissionRequest + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                return
            }
            self.publicPermissionMeta = publicPermissionMeta
            self.setDataWithPermissions(publicPermissionMeta)
            self.collectionView.reloadData()
        }
        permissionManager.fetchPublicPermissions(token: token, type: type.rawValue, complete: handler)
    }

    ///根据请求回来的数据设置数据源
    func setDataWithPermissions(_ publicPermissionMeta: PublicPermissionMeta) {
        for sectionData in data {
            switch sectionData.type {
            case .comment:
                sectionData.selectedIndex = publicPermissionMeta.commentEntity.rawValue
            case .share:
                sectionData.selectedIndex = publicPermissionMeta.shareEntity.rawValue
                var inviteExternalShareModel1 = InviteExternalCellModel(title: BundleI18n.SKResource.Doc_Share_SettingInviteCompanny,
                                                                        isSelected: false,
                                                                        inviteExternal: false)
                var inviteExternalShareModel2 = InviteExternalCellModel(title: BundleI18n.SKResource.Doc_Share_SettingInviteDocs(),
                                                                        isSelected: false,
                                                                        inviteExternal: true)
                inviteExternalShareModel1.isSelected = !publicPermissionMeta.inviteExternal
                inviteExternalShareModel2.isSelected = publicPermissionMeta.inviteExternal
                if publicPermissionMeta.shareEntity == .onlyMe {
                    inviteExternalShareModel1.isSelected = false
                    inviteExternalShareModel2.isSelected = false
                }
                guard let index = sectionData.models.firstIndex(where: { (model) -> Bool in
                    return model.entityValue == ShareEntity.tenant.rawValue
                }), index >= 0, index < sectionData.models.count else { continue }
                if shouldShowInviteExternalItems(publicPermissionMeta: publicPermissionMeta) {
                    sectionData.models[index].submodels = [inviteExternalShareModel1, inviteExternalShareModel2]
                } else {
                    sectionData.models[index].submodels = []
                }
            case .security:
                sectionData.selectedIndex = publicPermissionMeta.securityEntity.rawValue
            case .crossTenant:
                // 是否允许跨租户分享不在这里设置数据源
                continue
            }
        }
    }

    // 是否显示设置邀请外部用户的两个子选项
    // 管理员允许跨租户邀请，文档Owner允许跨租户邀请，允许非Owner邀请协作者，并且不是C端用户
    // 只有『组织内所有...』才显示子选项，『所有可访问此文档的用户』默认可以邀请所有人
    private func shouldShowInviteExternalItems(publicPermissionMeta: PublicPermissionMeta) -> Bool {
        return publicPermissionMeta.allowInviteExternalCollaborator && publicPermissionMeta.shareEntity == .tenant && !userIsToC
    }
}

// MARK: - PublicPermissionCellDelegate
extension PublicPermissionViewController: PublicPermissionCellDelegate {
    func didClickModel(model: InviteExternalCellModel, at index: Int) {
        let inviteExternal = model.inviteExternal
        publicPermissionMeta?.inviteExternal = inviteExternal
        switch index {
        case 0: tracker.report(.publicPermissionShareInviteOnlyInside)
        case 1: tracker.report(.publicPermissionShareInviteAnyone)
        default: ()
        }
        didChangeInviteExternals()
    }
}

// MARK: - UICollectionViewDelegate/DataSource
extension PublicPermissionViewController: UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].models.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reusableCell = collectionView.dequeueReusableCell(withReuseIdentifier: PublicPermissionCell.reuseIdentifier, for: indexPath)
        let rows = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        guard let cell = reusableCell as? PublicPermissionCell else {
            return reusableCell
        }
        cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
        let section = indexPath.section
        let row = indexPath.row
        guard section < data.count, row < data[section].models.count else {
            return reusableCell
        }
        let model = data[section].models[row]
        cell.delegate = self
        cell.isLastCell = (row == data[section].models.count - 1)
        cell.setModel(model)
        let isSelected = data[section].selectedIndex == model.entityValue
        cell.setSelected(isSelected)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.section < data.count, indexPath.row < data[indexPath.section].models.count else { return .zero }
        let model = data[indexPath.section].models[indexPath.row]
        let submoduleCount = CGFloat(model.submodels?.count ?? 0)
        let height: CGFloat = (1 + submoduleCount) * PublicPermissionCell.cellHeight
        let normalSize = CGSize(width: collectionView.frame.width, height: height)
        return normalSize
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        tracker.report(tracker.getReportingAction(indexPath: indexPath))
        guard section >= 0, section < data.count else { return }
        didChangePublicPermission(selectedSectionData: data[section], selectedIndex: row)
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = indexPath.section
        if section == 0 {
            let reuseHeader = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                              withReuseIdentifier: PermissionSwitchView.reuseIdentifier,
                                                                              for: indexPath)
            guard let switchHeader = reuseHeader as? PermissionSwitchView else {
                spaceAssertionFailure("get view fail in PublicPermissionSectionController getUserHeaderView")
                return UICollectionReusableView()
            }
            switchHeader.config(publicPermissionMeta: publicPermissionMeta)
            ///允许文档分享到组织外部开关
            switchHeader.accessSwitch.addTarget(self, action: #selector(onExternalAccessSwitchClick(sw:)), for: .valueChanged)
            switchHeader.accessSwitch.isOn = publicPermissionMeta?.externalAccessEnable == true
            reuseHeader.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
            return switchHeader
        } else {
            let reuseHeader = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                              withReuseIdentifier: PublicPermissionSectionHeaderView.reuseIdentifier,
                                                                              for: indexPath)
            guard let header = reuseHeader as? PublicPermissionSectionHeaderView else {
                spaceAssertionFailure("get view fail in PublicPermissionSectionController getUserHeaderView")
                return UICollectionReusableView()
            }
            header.setTitle(data[section].title)
            header.backgroundColor = UDColor.bgBase
            return header
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section < data.count else {
            return .zero
        }
        let sectionData = data[section]
        if sectionData.type == .crossTenant && !canShowCrossTenantSection() {
            return CGSize(width: collectionView.frame.width, height: 0)
        } else if sectionData.type == .share && fileModel.wikiV2SingleContainer {
            return CGSize(width: collectionView.frame.width, height: 0)
        } else {
            let height = PublicPermissionSectionHeaderView.sectionHeaderViewHeight(section: section)
            return CGSize(width: collectionView.frame.width, height: height)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        view.layer.zPosition = 0.0
    }
    
    private func canShowCrossTenantSection() -> Bool {
        /// B端用户如果管理员禁止对外分享，则不显示分享到租户外的按钮
        let toBCrossFGClosed = (publicPermissionMeta?.canShowExternalAccessSwitch == false && User.current.info?.isToNewC == false)
        /// C端用户默认不显示分享到租户外的按钮
        let toCCrossFGClosed = (userIsToC == true)
        /// admin是否允许分享到外部
        let adminCanNotExternalShare = (!AdminPermissionManager.adminCanExternalShare())
        let wikiV2SingleContainer = fileModel.wikiV2SingleContainer
        return !(toBCrossFGClosed || toCCrossFGClosed || adminCanNotExternalShare || wikiV2SingleContainer)
    }
}

// MARK: - 网络请求
extension PublicPermissionViewController {
    public func didChangeExternalAccess(isOn: Bool) {
//        guard let publicPermissionMeta = publicPermissionMeta else {
//            spaceAssertionFailure("must have permission")
//            return
//        }
        checkLockByUpdateFilePublicPermission(isOn: isOn) { [weak self] in
            let params: [String: Any] = ["external_access": isOn]
            self?.updatePublicPermissionsCore(additionalParams: params)
        }
    }

    private func didChangePublicPermission(selectedSectionData: PublicPermissionSectionData, selectedIndex: Int) {
        var params: [String: Any] = [:]
        guard selectedIndex >= 0, selectedIndex < selectedSectionData.models.count else {
            DocsLogger.error("selectedIndex is out of bounds!")
            return
        }
        let model = selectedSectionData.models[selectedIndex]
        let isSelected = selectedSectionData.selectedIndex == model.entityValue
        guard !isSelected else { return }
        params[selectedSectionData.type.requestJSONKey] = model.entityValue
        updatePublicPermissionsCore(additionalParams: params)
        switch selectedSectionData.type {
        case .comment:
            let option: PermissionSettingOption = (model.entityValue == 0) ? .read : .edit
            permStatistics?.reportPermissionSetClick(click: .commentSet,
                                                     option: option,
                                                     target: .noneTargetView)
        case .share:
            let option: PermissionSettingOption = (model.entityValue == 0) ? .myself : ((model.entityValue == 2) ? .all : .insideOrganization)
            permStatistics?.reportPermissionSetClick(click: .shareSet,
                                                     option: option,
                                                     target: .noneTargetView)
        case .security:
            let option: PermissionSettingOption
            if model.entityValue == SecurityEntity.userCanRead.rawValue {
                option = .read
            } else if model.entityValue == SecurityEntity.userCanEdit.rawValue {
                option = .edit
            } else {
                option = .myself
            }
            permStatistics?.reportPermissionSetClick(click: .securitySet,
                                                     option: option,
                                                     target: .noneTargetView)
        default: ()
        }
    }

    private func didChangeInviteExternals() {
        guard let publicPermissionMeta = publicPermissionMeta else {
            spaceAssertionFailure("must have permission")
            return
        }
        let params: [String: Any] = ["invite_external": publicPermissionMeta.inviteExternal]
        updatePublicPermissionsCore(additionalParams: params)
        let option: PermissionSettingOption = publicPermissionMeta.inviteExternal ? .anyoneLark : .insideOrganization
        permStatistics?.reportPermissionSetClick(click: .shareSet,
                                                 option: option,
                                                 target: .noneTargetView)
    }

    private func updatePublicPermissionsCore(additionalParams: [String: Any]) {
        var params: [String: Any] = ["type": fileModel.type.rawValue, "token": fileModel.objToken]
        params.merge(other: additionalParams)
        self.loading(isBehindNavBar: true)
        self.updatePermission(params) { [weak self] in
            guard let self = self else { return }
            self.hideLoading()
            NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
            // 重新拉取公共权限
            self.loadData()
        }
    }

    private func updatePermission(_ params: [String: Any], callback: (() -> Void)?) {
        self.updateRequest = PermissionManager.updateBizsPublicPermission(type: fileModel.type.rawValue, params: params, complete: { [weak self] (response, error) in
            guard let `self` = self else {
                return
            }
            self.hideLoading()
            if let err = error as? DocsNetworkError {
                if let message = err.code.errorMessage {
                    self.showToast(text: message, type: .failure)
                } else {
                    self.showToast(text: BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                }
                callback?()
                return
            }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.showToast(text: BundleI18n.SKResource.Doc_Normal_PermissionModify + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                callback?()
                return
            }
            guard let response = response else {
                callback?()
                return
            }
            guard let code = response["code"].int else {
                DocsLogger.error("updatePermission failed!")
                callback?()
                return
            }
            guard code == 0 else {
                self.handleError(json: response, inputText: BundleI18n.SKResource.Doc_Facade_SetFailed)
                DocsLogger.error("updatePermission failed, error code is \(code)")
                callback?()
                return
            }
            callback?()
        })
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

extension PublicPermissionViewController {
    private func checkLockByUpdateFilePublicPermission(isOn: Bool, completion: (() -> Void)?) {
        let token = fileModel.objToken
        let type = fileModel.type.rawValue
        checkLockPermission = PermissionManager.checkLockByUpdateFilePublicPermission(
            token: token,
            type: type,
            externalAccess: isOn) { (success, needLock, _) in
            if success {
                if needLock {
                    self.showPermisionLockAlert(completion: completion)
                } else {
                    completion?()
                }
            } else {
                completion?()
            }
        }
    }
    
    // 是否加锁提示弹窗
    private func showPermisionLockAlert(completion: (() -> Void)?) {
        permStatistics?.reportLockAlertView(reason: .externalSwitch)
        var content: String = ""
        if fileModel.wikiV2SingleContainer {
            content = BundleI18n.SKResource.CreationMobile_Wiki_Permission_SettingsDivision_Placeholder
        } else {
            if fileModel.type == .folder {
                content = BundleI18n.SKResource.CreationMobile_ECM_InheritDesc
            } else {
                content = BundleI18n.SKResource.CreationMobile_ECM_PermissionChangedDesc
            }
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Wiki_Permission_ChangePermission_Title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: { [weak self] in
            self?.collectionView.reloadData()
            self?.permStatistics?.reportLockAlertClick(click: .cancel,
                                                       target: .noneTargetView,
                                                       reason: .externalSwitch)
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            self?.permStatistics?.reportLockAlertClick(click: .confirm,
                                                       target: .noneTargetView,
                                                       reason: .externalSwitch)
            completion?()
        })
        present(dialog, animated: true, completion: nil)
    }
}

extension PublicPermissionViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
